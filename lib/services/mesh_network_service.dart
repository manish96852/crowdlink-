import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/models.dart';
import 'bluetooth_mesh_service.dart';
import 'wifi_direct_service.dart';
import 'encryption_service.dart';
import 'database_service.dart';

/// Main Mesh Network Controller
/// Orchestrates Bluetooth and Wi-Fi Direct for mesh networking
class MeshNetworkService extends ChangeNotifier {
  final BluetoothMeshService _bluetoothService;
  final WifiDirectService _wifiDirectService;
  final EncryptionService _encryptionService;
  final DatabaseService _databaseService;
  final Uuid _uuid = const Uuid();

  final Map<String, Peer> _allPeers = {};
  final List<Message> _messageQueue = []; // For offline/delayed delivery
  String _myDeviceId = '';
  String _myName = 'User';
  bool _isActive = false;

  // Event streams
  final StreamController<Message> _messageController =
      StreamController.broadcast();
  final StreamController<Peer> _peerController = StreamController.broadcast();
  final StreamController<Map<String, dynamic>> _callSignalController =
      StreamController.broadcast();
  final StreamController<Uint8List> _audioDataController =
      StreamController.broadcast();

  Stream<Message> get onMessage => _messageController.stream;
  Stream<Peer> get onPeerUpdate => _peerController.stream;
  Stream<Map<String, dynamic>> get onCallSignal =>
      _callSignalController.stream;
  /// Incoming raw audio PCM from the connected peer during a call
  Stream<Uint8List> get onAudioData => _audioDataController.stream;

  Map<String, Peer> get allPeers => Map.unmodifiable(_allPeers);
  List<Peer> get onlinePeers =>
      _allPeers.values.where((p) => p.isOnline).toList();
  bool get isActive => _isActive;
  String get myDeviceId => _myDeviceId;

  MeshNetworkService({
    required BluetoothMeshService bluetoothService,
    required WifiDirectService wifiDirectService,
    required EncryptionService encryptionService,
    required DatabaseService databaseService,
  })  : _bluetoothService = bluetoothService,
        _wifiDirectService = wifiDirectService,
        _encryptionService = encryptionService,
        _databaseService = databaseService;

  /// Initialize mesh network
  Future<void> initialize(String deviceId, String userName) async {
    _myDeviceId = deviceId;
    _myName = userName;

    // Initialize both transport layers
    await _bluetoothService.initialize();
    await _wifiDirectService.initialize();

    // Setup message listeners
    _setupListeners();

    // Load saved peers from database
    await _loadSavedPeers();

    debugPrint("Mesh Network initialized for: $_myName ($_myDeviceId)");
  }

  /// Start mesh networking (discovery + advertising)
  Future<void> startMesh() async {
    _isActive = true;
    notifyListeners();

    // Start both BLE and Wi-Fi Direct discovery
    await _bluetoothService.startScanning();
    await _wifiDirectService.startDiscovery();

    // Process queued messages
    _processMessageQueue();

    debugPrint("Mesh network started");
  }

  /// Stop mesh networking
  Future<void> stopMesh() async {
    _isActive = false;
    await _bluetoothService.stopScanning();
    await _wifiDirectService.stopDiscovery();
    notifyListeners();
    debugPrint("Mesh network stopped");
  }

  /// Setup listeners for both transport layers
  void _setupListeners() {
    // Bluetooth messages
    _bluetoothService.onMessage.listen((message) {
      _handleIncomingMessage(message);
    });

    _bluetoothService.onPeerDiscovered.listen((peer) {
      _handlePeerDiscovered(peer, ConnectionType.bluetooth);
    });

    _bluetoothService.onPeerLost.listen((peer) {
      _handlePeerLost(peer);
    });

    _bluetoothService.onCallSignal.listen((signal) {
      _callSignalController.add(signal);
    });

    // Wi-Fi Direct messages
    _wifiDirectService.onMessage.listen((message) {
      _handleIncomingMessage(message);
    });

    _wifiDirectService.onPeerDiscovered.listen((peer) {
      _handlePeerDiscovered(peer, ConnectionType.wifiDirect);
    });

    _wifiDirectService.onCallSignal.listen((signal) {
      _callSignalController.add(signal);
    });

    // Audio data from BLE during calls
    _bluetoothService.onAudioData.listen((audio) {
      _audioDataController.add(audio);
    });

    // Audio data from Wi-Fi Direct during calls
    _wifiDirectService.onAudioData.listen((audio) {
      _audioDataController.add(audio);
    });
  }

  /// Handle incoming message from any transport
  Future<void> _handleIncomingMessage(Message message) async {
    // Decrypt message if encrypted
    Message decryptedMessage = message;
    if (message.isEncrypted) {
      try {
        final decryptedContent =
            await _encryptionService.decrypt(message.content);
        decryptedMessage = message.copyWith(content: decryptedContent);
      } catch (e) {
        debugPrint("Error decrypting: $e");
      }
    }

    // Store in database
    await _databaseService.saveMessage(decryptedMessage);

    // Emit to listeners
    _messageController.add(decryptedMessage);

    debugPrint(
        "Received message from ${message.senderId}: ${message.type.name}");
  }

  /// Handle new peer discovered
  void _handlePeerDiscovered(Peer peer, ConnectionType type) {
    final existingPeer = _allPeers[peer.deviceId];
    if (existingPeer != null) {
      // Update with better connection type
      _allPeers[peer.deviceId] = existingPeer.copyWith(
        isOnline: true,
        connectionType: type == ConnectionType.wifiDirect
            ? ConnectionType.wifiDirect
            : existingPeer.connectionType,
        lastSeen: DateTime.now(),
      );
    } else {
      _allPeers[peer.deviceId] = peer;
      _databaseService.savePeer(peer);
    }

    _peerController.add(_allPeers[peer.deviceId]!);
    notifyListeners();
  }

  /// Handle peer lost
  void _handlePeerLost(Peer peer) {
    if (_allPeers.containsKey(peer.deviceId)) {
      _allPeers[peer.deviceId] =
          _allPeers[peer.deviceId]!.copyWith(isOnline: false);
      _peerController.add(_allPeers[peer.deviceId]!);
      notifyListeners();
    }
  }

  /// Send a text message
  Future<bool> sendTextMessage(
      String content, String receiverId, String receiverDeviceId) async {
    // Encrypt content
    final encrypted = await _encryptionService.encrypt(content);

    final message = Message(
      id: _uuid.v4(),
      senderId: _myDeviceId,
      receiverId: receiverId,
      content: encrypted,
      type: MessageType.text,
      timestamp: DateTime.now(),
      isEncrypted: true,
    );

    // Try Wi-Fi Direct first (faster), then Bluetooth
    bool sent = false;
    if (_wifiDirectService.isConnected) {
      sent = await _wifiDirectService.sendMessage(message);
    }

    if (!sent) {
      sent = await _bluetoothService.sendMessage(message, receiverDeviceId);
    }

    if (sent) {
      // Save locally
      final localMsg = message.copyWith(
        content: content, // Save unencrypted locally
        status: MessageStatus.sent,
      );
      await _databaseService.saveMessage(localMsg);
    } else {
      // Queue for later delivery
      _messageQueue.add(message);
      await _databaseService.saveMessage(
          message.copyWith(status: MessageStatus.sending));
    }

    return sent;
  }

  /// Broadcast a message to all peers
  Future<void> broadcastMessage(String content) async {
    final encrypted = await _encryptionService.encrypt(content);

    final message = Message(
      id: _uuid.v4(),
      senderId: _myDeviceId,
      receiverId: 'broadcast',
      content: encrypted,
      type: MessageType.text,
      timestamp: DateTime.now(),
      isBroadcast: true,
      isEncrypted: true,
    );

    await _bluetoothService.broadcastMessage(message);
    if (_wifiDirectService.isConnected) {
      await _wifiDirectService.sendMessage(message);
    }

    // Save locally
    await _databaseService.saveMessage(message.copyWith(
      content: content,
      status: MessageStatus.sent,
    ));
  }

  /// Send location to a peer
  Future<bool> sendLocation(
    double latitude,
    double longitude,
    String? locationName,
    String receiverId,
    String receiverDeviceId,
  ) async {
    final message = Message(
      id: _uuid.v4(),
      senderId: _myDeviceId,
      receiverId: receiverId,
      content: 'Location shared',
      type: MessageType.location,
      timestamp: DateTime.now(),
      latitude: latitude,
      longitude: longitude,
      locationName: locationName,
    );

    bool sent = false;
    if (_wifiDirectService.isConnected) {
      sent = await _wifiDirectService.sendLocation(message);
    }
    if (!sent) {
      sent =
          await _bluetoothService.sendLocation(message, receiverDeviceId);
    }

    await _databaseService.saveMessage(message);
    return sent;
  }

  /// Send call signal to a peer
  Future<bool> sendCallSignal(
    String type,
    String peerId,
    String peerDeviceId, {
    String? callId,
  }) async {
    final signal = {
      'type': type,
      'callId': callId ?? _uuid.v4(),
      'senderId': _myDeviceId,
      'senderName': _myName,
      'receiverId': peerId,
      'timestamp': DateTime.now().toIso8601String(),
    };

    // Prefer Wi-Fi Direct for calls (higher bandwidth)
    if (_wifiDirectService.isConnected) {
      return await _wifiDirectService.sendCallSignal(signal);
    }
    return await _bluetoothService.sendCallSignal(signal, peerDeviceId);
  }

  /// Send audio data during a call
  Future<bool> sendAudioData(
      Uint8List audioData, String peerDeviceId) async {
    if (_wifiDirectService.isConnected) {
      return await _wifiDirectService.sendAudioData(audioData);
    }
    return await _bluetoothService.sendAudioData(audioData, peerDeviceId);
  }

  /// Process queued messages
  Future<void> _processMessageQueue() async {
    final queue = List<Message>.from(_messageQueue);
    for (final message in queue) {
      final peer = _allPeers.values.firstWhere(
        (p) => p.id == message.receiverId && p.isOnline,
        orElse: () => Peer(
          id: '',
          name: '',
          publicKey: '',
          deviceId: '',
          lastSeen: DateTime.now(),
        ),
      );

      if (peer.id.isNotEmpty) {
        bool sent = false;
        if (_wifiDirectService.isConnected) {
          sent = await _wifiDirectService.sendMessage(message);
        }
        if (!sent) {
          sent = await _bluetoothService.sendMessage(
              message, peer.deviceId);
        }
        if (sent) {
          _messageQueue.remove(message);
          await _databaseService.saveMessage(
              message.copyWith(status: MessageStatus.sent));
        }
      }
    }
  }

  /// Load saved peers from database
  Future<void> _loadSavedPeers() async {
    final peers = await _databaseService.getAllPeers();
    for (var peer in peers) {
      _allPeers[peer.deviceId] = peer.copyWith(isOnline: false);
    }
    notifyListeners();
  }

  /// Get messages for a conversation
  Future<List<Message>> getMessages(String peerId) async {
    return await _databaseService.getMessages(peerId);
  }

  @override
  void dispose() {
    stopMesh();
    _messageController.close();
    _peerController.close();
    _callSignalController.close();
    _audioDataController.close();
    super.dispose();
  }
}
