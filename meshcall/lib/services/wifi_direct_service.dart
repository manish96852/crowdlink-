import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter_p2p_connection/flutter_p2p_connection.dart';
import 'package:uuid/uuid.dart';
import '../models/models.dart';

/// Wi-Fi Direct Service for high-bandwidth P2P communication
/// Used primarily for voice calls and large data transfer
class WifiDirectService extends ChangeNotifier {
  final FlutterP2pConnection _p2p = FlutterP2pConnection();
  final Uuid _uuid = const Uuid();

  bool _isHost = false;
  bool _isConnected = false;
  String? _groupOwnerAddress;
  final Map<String, Peer> _wifiPeers = {};

  // TCP socket for real-time data/audio transport
  static const int _tcpPort = 8988;
  ServerSocket? _serverSocket;
  Socket? _peerSocket;
  StreamSubscription? _socketReadSub;
  // Accumulation buffer for framed packets
  final List<int> _rxBuffer = [];

  // Event streams
  final StreamController<Message> _messageController =
      StreamController.broadcast();
  final StreamController<Peer> _peerDiscoveredController =
      StreamController.broadcast();
  final StreamController<Map<String, dynamic>> _callSignalController =
      StreamController.broadcast();
  final StreamController<Uint8List> _audioDataController =
      StreamController.broadcast();

  Stream<Message> get onMessage => _messageController.stream;
  Stream<Peer> get onPeerDiscovered => _peerDiscoveredController.stream;
  Stream<Map<String, dynamic>> get onCallSignal =>
      _callSignalController.stream;
  Stream<Uint8List> get onAudioData => _audioDataController.stream;

  bool get isConnected => _isConnected;
  bool get isHost => _isHost;
  Map<String, Peer> get wifiPeers => Map.unmodifiable(_wifiPeers);

  /// Initialize Wi-Fi Direct
  Future<bool> initialize() async {
    try {
      bool? result = await _p2p.initialize();
      if (result == true) {
        debugPrint("Wi-Fi Direct initialized successfully");

        // Track connection info (group owner IP, isGroupOwner flag)
        _p2p.streamWifiP2PInfo().listen((info) {
          _isHost = info.isGroupOwner;
          _groupOwnerAddress = info.groupOwnerAddress;
          debugPrint('[WiFiDirect] GO=${info.groupOwnerAddress} isHost=$_isHost');
        });

        // Register for discovered peer events using the correct stream method
        _p2p.streamPeers().listen((peers) {
          _handleDiscoveredPeers(peers);
        });

        return true;
      }
      return false;
    } catch (e) {
      debugPrint("Error initializing Wi-Fi Direct: $e");
      return false;
    }
  }

  /// Start discovering Wi-Fi Direct peers
  Future<void> startDiscovery() async {
    try {
      bool? started = await _p2p.discover();
      if (started == true) {
        debugPrint("Wi-Fi Direct discovery started");
      }
    } catch (e) {
      debugPrint("Error starting Wi-Fi Direct discovery: $e");
    }
  }

  /// Stop discovering
  Future<void> stopDiscovery() async {
    try {
      await _p2p.stopDiscovery();
    } catch (e) {
      debugPrint("Error stopping discovery: $e");
    }
  }

  /// Handle discovered Wi-Fi Direct peers
  void _handleDiscoveredPeers(List<DiscoveredPeers> peers) {
    for (var device in peers) {
      final deviceId = device.deviceAddress;
      if (!_wifiPeers.containsKey(deviceId)) {
        final peer = Peer(
          id: _uuid.v4(),
          name: device.deviceName,
          publicKey: "",
          deviceId: deviceId,
          lastSeen: DateTime.now(),
          isOnline: true,
          connectionType: ConnectionType.wifiDirect,
          signalStrength: -50, // Wi-Fi typically stronger
        );

        _wifiPeers[deviceId] = peer;
        _peerDiscoveredController.add(peer);
      }
    }
    notifyListeners();
  }

  /// Connect to a Wi-Fi Direct peer
  Future<bool> connectToPeer(String deviceAddress) async {
    try {
      bool? connected = await _p2p.connect(deviceAddress);
      if (connected == true) {
        _isConnected = true;
        notifyListeners();
        // _groupOwnerAddress and _isHost are set by streamWifiP2PInfo listener
        // Give stream a moment to deliver the info, then open socket
        await Future.delayed(const Duration(milliseconds: 600));
        _setupSocketCommunication();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint("Error connecting via Wi-Fi Direct: $e");
      return false;
    }
  }

  /// Create a Wi-Fi Direct group (become host)
  Future<bool> createGroup() async {
    try {
      bool? created = await _p2p.createGroup();
      if (created == true) {
        _isHost = true;
        _isConnected = true;
        notifyListeners();
        
        _setupSocketCommunication();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint("Error creating group: $e");
      return false;
    }
  }

  /// Remove/leave group
  Future<void> removeGroup() async {
    try {
      await _p2p.removeGroup();
      _isHost = false;
      _isConnected = false;
      notifyListeners();
    } catch (e) {
      debugPrint("Error removing group: $e");
    }
  }

  /// Setup socket communication for data transfer
  void _setupSocketCommunication() {
    if (_isHost) {
      _startTcpServer();
    } else if (_groupOwnerAddress != null) {
      _connectTcpClient(_groupOwnerAddress!);
    }
  }

  /// Group owner: start TCP server, accept first client
  Future<void> _startTcpServer() async {
    try {
      _serverSocket = await ServerSocket.bind(InternetAddress.anyIPv4, _tcpPort);
      debugPrint('[WiFiDirect] TCP server listening on port $_tcpPort');

      _serverSocket!.listen((Socket client) {
        debugPrint('[WiFiDirect] Client connected: ${client.remoteAddress.address}');
        _peerSocket = client;
        _listenTcpSocket(client);
      });
    } catch (e) {
      debugPrint('[WiFiDirect] TCP server error: $e');
    }
  }

  /// Client: connect to group owner
  Future<void> _connectTcpClient(String hostAddress) async {
    // Give the server a moment to start
    await Future.delayed(const Duration(milliseconds: 800));
    try {
      _peerSocket = await Socket.connect(hostAddress, _tcpPort,
          timeout: const Duration(seconds: 10));
      debugPrint('[WiFiDirect] Connected to server $hostAddress:$_tcpPort');
      _listenTcpSocket(_peerSocket!);
    } catch (e) {
      debugPrint('[WiFiDirect] TCP client connect error: $e');
    }
  }

  /// Read framed packets from socket: [4-byte big-endian length][1-byte type][payload]
  void _listenTcpSocket(Socket socket) {
    _rxBuffer.clear();
    _socketReadSub?.cancel();
    _socketReadSub = socket.listen(
      (data) {
        _rxBuffer.addAll(data);
        _processSocketBuffer();
      },
      onError: (e) => debugPrint('[WiFiDirect] Socket error: $e'),
      onDone: () {
        debugPrint('[WiFiDirect] Socket closed');
        _isConnected = false;
        notifyListeners();
      },
      cancelOnError: false,
    );
  }

  /// Decode length-prefixed frames from _rxBuffer
  void _processSocketBuffer() {
    while (_rxBuffer.length >= 5) {
      // 4-byte length header (big-endian)
      final length = (_rxBuffer[0] << 24) |
          (_rxBuffer[1] << 16) |
          (_rxBuffer[2] << 8) |
          _rxBuffer[3];
      if (_rxBuffer.length < 4 + length) break; // incomplete frame

      final typeByte = _rxBuffer[4];
      final payload = Uint8List.fromList(_rxBuffer.sublist(5, 4 + length));
      _rxBuffer.removeRange(0, 4 + length);

      _dispatchPacket(DataType.values[typeByte], payload);
    }
  }

  /// Route a decoded packet to the right stream
  void _dispatchPacket(DataType type, Uint8List payload) {
    switch (type) {
      case DataType.audio:
        _audioDataController.add(payload);
        break;
      case DataType.message:
      case DataType.location:
        try {
          final json = jsonDecode(utf8.decode(payload)) as Map<String, dynamic>;
          _messageController.add(Message.fromJson(json));
        } catch (e) {
          debugPrint('[WiFiDirect] Message decode error: $e');
        }
        break;
      case DataType.callSignal:
        try {
          final json = jsonDecode(utf8.decode(payload)) as Map<String, dynamic>;
          _callSignalController.add(json);
        } catch (e) {
          debugPrint('[WiFiDirect] Call signal decode error: $e');
        }
        break;
      default:
        break;
    }
  }

  /// Send text message via Wi-Fi Direct
  Future<bool> sendMessage(Message message) async {
    try {
      final jsonStr = jsonEncode(message.toJson());
      final data = utf8.encode(jsonStr);
      
      // Send via Wi-Fi Direct socket
      await _sendData(data, DataType.message);
      return true;
    } catch (e) {
      debugPrint("Error sending message via Wi-Fi Direct: $e");
      return false;
    }
  }

  /// Send location via Wi-Fi Direct
  Future<bool> sendLocation(Message locationMessage) async {
    try {
      final jsonStr = jsonEncode(locationMessage.toJson());
      final data = utf8.encode(jsonStr);
      
      await _sendData(data, DataType.location);
      return true;
    } catch (e) {
      debugPrint("Error sending location: $e");
      return false;
    }
  }

  /// Send call signal
  Future<bool> sendCallSignal(Map<String, dynamic> signal) async {
    try {
      final data = utf8.encode(jsonEncode(signal));
      await _sendData(data, DataType.callSignal);
      return true;
    } catch (e) {
      debugPrint("Error sending call signal: $e");
      return false;
    }
  }

  /// Send audio data (for voice calls)
  Future<bool> sendAudioData(Uint8List audioData) async {
    try {
      await _sendData(audioData, DataType.audio);
      return true;
    } catch (e) {
      debugPrint("Error sending audio data: $e");
      return false;
    }
  }

  /// Internal data sending with type header (length-prefixed framing)
  Future<void> _sendData(List<int> payload, DataType type) async {
    final socket = _peerSocket;
    if (socket == null) {
      debugPrint('[WiFiDirect] No socket, dropping ${type.name} packet');
      return;
    }
    // Frame: [4-byte length (type+payload)][1-byte type][payload]
    final frameLength = 1 + payload.length;
    final frame = BytesBuilder();
    frame.addByte((frameLength >> 24) & 0xFF);
    frame.addByte((frameLength >> 16) & 0xFF);
    frame.addByte((frameLength >> 8) & 0xFF);
    frame.addByte(frameLength & 0xFF);
    frame.addByte(type.index);
    frame.add(payload);
    socket.add(frame.toBytes());
  }

  /// Disconnect from current peer
  Future<void> disconnect() async {
    try {
      _socketReadSub?.cancel();
      await _peerSocket?.close();
      await _serverSocket?.close();
      _peerSocket = null;
      _serverSocket = null;
      _rxBuffer.clear();

      if (_isHost) {
        await removeGroup();
      }
      _isConnected = false;
      _wifiPeers.clear();
      notifyListeners();
    } catch (e) {
      debugPrint("Error disconnecting: $e");
    }
  }

  @override
  void dispose() {
    disconnect();
    _messageController.close();
    _peerDiscoveredController.close();
    _callSignalController.close();
    _audioDataController.close();
    super.dispose();
  }
}

enum DataType {
  message,
  location,
  callSignal,
  audio,
  file,
}
