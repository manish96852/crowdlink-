import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:uuid/uuid.dart';
import '../models/models.dart';

/// Bluetooth Low Energy Service for mesh networking
/// Handles device discovery, connection, and data transfer via BLE
class BluetoothMeshService extends ChangeNotifier {
  static const String SERVICE_UUID = "91e32a50-0e6b-4c7f-b4a5-2e0c3e8d7f1a";
  static const String CHAR_MSG_UUID = "91e32a51-0e6b-4c7f-b4a5-2e0c3e8d7f1a";
  static const String CHAR_CALL_UUID = "91e32a52-0e6b-4c7f-b4a5-2e0c3e8d7f1a";
  static const String CHAR_LOC_UUID = "91e32a53-0e6b-4c7f-b4a5-2e0c3e8d7f1a";
  static const String CHAR_DISCOVERY_UUID = "91e32a54-0e6b-4c7f-b4a5-2e0c3e8d7f1a";

  final Map<String, BluetoothDevice> _connectedDevices = {};
  final Map<String, Peer> _discoveredPeers = {};
  final Uuid _uuid = const Uuid();
  
  bool _isScanning = false;
  bool _isAdvertising = false;
  StreamSubscription? _scanSubscription;
  Timer? _discoveryTimer;

  // Event streams
  final StreamController<Message> _messageController = StreamController.broadcast();
  final StreamController<Peer> _peerDiscoveredController = StreamController.broadcast();
  final StreamController<Peer> _peerLostController = StreamController.broadcast();
  final StreamController<Map<String, dynamic>> _callSignalController = StreamController.broadcast();
  final StreamController<Uint8List> _audioDataController = StreamController.broadcast();

  Stream<Message> get onMessage => _messageController.stream;
  Stream<Peer> get onPeerDiscovered => _peerDiscoveredController.stream;
  Stream<Peer> get onPeerLost => _peerLostController.stream;
  Stream<Map<String, dynamic>> get onCallSignal => _callSignalController.stream;
  Stream<Uint8List> get onAudioData => _audioDataController.stream;

  bool get isScanning => _isScanning;
  Map<String, Peer> get discoveredPeers => Map.unmodifiable(_discoveredPeers);
  Map<String, BluetoothDevice> get connectedDevices => Map.unmodifiable(_connectedDevices);

  /// Initialize Bluetooth service
  Future<void> initialize() async {
    // Check if Bluetooth is supported
    if (await FlutterBluePlus.isSupported == false) {
      debugPrint("Bluetooth not supported on this device");
      return;
    }

    // Listen for adapter state changes
    FlutterBluePlus.adapterState.listen((BluetoothAdapterState state) {
      if (state == BluetoothAdapterState.on) {
        debugPrint("Bluetooth is ON");
      } else {
        debugPrint("Bluetooth is OFF");
        stopScanning();
      }
    });
  }

  /// Start scanning for nearby mesh peers
  Future<void> startScanning() async {
    if (_isScanning) return;

    _isScanning = true;
    notifyListeners();

    try {
      // Start scanning for ALL nearby devices (no UUID filter)
      // We can't filter by our custom UUID because phones don't
      // run a GATT server advertising it.
      await FlutterBluePlus.startScan(
        timeout: const Duration(seconds: 30),
        androidUsesFineLocation: true,
      );

      _scanSubscription = FlutterBluePlus.scanResults.listen((results) {
        for (ScanResult result in results) {
          _handleDiscoveredDevice(result);
        }
      });

      // Auto-restart scanning periodically
      _discoveryTimer = Timer.periodic(const Duration(seconds: 35), (_) {
        _restartScanning();
      });
    } catch (e) {
      debugPrint("Error starting scan: $e");
      _isScanning = false;
      notifyListeners();
    }
  }

  /// Stop scanning
  Future<void> stopScanning() async {
    _isScanning = false;
    _scanSubscription?.cancel();
    _discoveryTimer?.cancel();
    await FlutterBluePlus.stopScan();
    notifyListeners();
  }

  Future<void> _restartScanning() async {
    await FlutterBluePlus.stopScan();
    await Future.delayed(const Duration(seconds: 2));
    if (_isScanning) {
      await FlutterBluePlus.startScan(
        timeout: const Duration(seconds: 30),
        androidUsesFineLocation: true,
      );
    }
  }

  /// Handle a discovered BLE device
  void _handleDiscoveredDevice(ScanResult result) {
    final device = result.device;
    final deviceId = device.remoteId.str;

    if (!_discoveredPeers.containsKey(deviceId)) {
      // Extract peer info from advertisement data
      final peer = Peer(
        id: _uuid.v4(),
        name: result.advertisementData.advName.isNotEmpty
            ? result.advertisementData.advName
            : "Unknown Device",
        publicKey: "",
        deviceId: deviceId,
        lastSeen: DateTime.now(),
        isOnline: true,
        connectionType: ConnectionType.bluetooth,
        signalStrength: result.rssi,
      );

      _discoveredPeers[deviceId] = peer;
      _peerDiscoveredController.add(peer);
      notifyListeners();

      // Auto-connect to peer
      _connectToDevice(device);
    } else {
      // Update existing peer
      _discoveredPeers[deviceId] = _discoveredPeers[deviceId]!.copyWith(
        lastSeen: DateTime.now(),
        isOnline: true,
        signalStrength: result.rssi,
      );
      notifyListeners();
    }
  }

  /// Connect to a BLE device
  Future<void> _connectToDevice(BluetoothDevice device) async {
    try {
      await device.connect(
        timeout: const Duration(seconds: 10),
        autoConnect: true,
      );

      _connectedDevices[device.remoteId.str] = device;

      // Discover services
      List<BluetoothService> services = await device.discoverServices();
      for (BluetoothService service in services) {
        if (service.uuid.str == SERVICE_UUID) {
          _setupCharacteristicListeners(service, device.remoteId.str);
        }
      }

      // Send discovery handshake
      await _sendDiscoveryHandshake(device);

      // Listen for disconnection
      device.connectionState.listen((BluetoothConnectionState state) {
        if (state == BluetoothConnectionState.disconnected) {
          _handleDeviceDisconnected(device.remoteId.str);
        }
      });

      notifyListeners();
    } catch (e) {
      debugPrint("Error connecting to device: $e");
    }
  }

  /// Setup listeners for BLE characteristics
  void _setupCharacteristicListeners(
      BluetoothService service, String deviceId) {
    for (BluetoothCharacteristic char in service.characteristics) {
      final charUuid = char.uuid.str;

      if (charUuid == CHAR_MSG_UUID ||
          charUuid == CHAR_CALL_UUID ||
          charUuid == CHAR_LOC_UUID ||
          charUuid == CHAR_DISCOVERY_UUID) {
        // Enable notifications
        char.setNotifyValue(true);

        char.onValueReceived.listen((value) {
          _handleReceivedData(charUuid, Uint8List.fromList(value), deviceId);
        });
      }
    }
  }

  /// Handle received data from BLE characteristic
  void _handleReceivedData(
      String characteristicUuid, Uint8List data, String deviceId) {
    try {
      final jsonStr = utf8.decode(data);
      final json = jsonDecode(jsonStr) as Map<String, dynamic>;

      switch (characteristicUuid) {
        case CHAR_MSG_UUID:
          final message = Message.fromJson(json);
          _messageController.add(message);
          // Check if this message should be relayed (mesh routing)
          _relayMessageIfNeeded(message, deviceId);
          break;

        case CHAR_CALL_UUID:
          _callSignalController.add(json);
          break;

        case CHAR_LOC_UUID:
          final message = Message.fromJson(json);
          _messageController.add(message);
          break;

        case CHAR_DISCOVERY_UUID:
          _handleDiscoveryHandshake(json, deviceId);
          break;
      }
    } catch (e) {
      // Could be raw audio data for calls
      if (characteristicUuid == CHAR_CALL_UUID) {
        _audioDataController.add(data);
      }
      debugPrint("Error handling data: $e");
    }
  }

  /// Send discovery handshake to a peer
  Future<void> _sendDiscoveryHandshake(BluetoothDevice device) async {
    // This would include our device info, public key, etc.
    final handshake = {
      'type': 'discovery',
      'deviceId': device.remoteId.str,
      'timestamp': DateTime.now().toIso8601String(),
    };

    await _writeToCharacteristic(
      device.remoteId.str,
      CHAR_DISCOVERY_UUID,
      utf8.encode(jsonEncode(handshake)),
    );
  }

  /// Handle discovery handshake from a peer
  void _handleDiscoveryHandshake(
      Map<String, dynamic> data, String deviceId) {
    debugPrint("Received handshake from: $deviceId");
    // Update peer info with received data
    if (_discoveredPeers.containsKey(deviceId)) {
      final peer = _discoveredPeers[deviceId]!;
      _discoveredPeers[deviceId] = peer.copyWith(
        publicKey: data['publicKey'] ?? '',
        name: data['name'] ?? peer.name,
      );
      notifyListeners();
    }
  }

  /// Handle device disconnection
  void _handleDeviceDisconnected(String deviceId) {
    _connectedDevices.remove(deviceId);
    if (_discoveredPeers.containsKey(deviceId)) {
      final peer = _discoveredPeers[deviceId]!;
      _peerLostController.add(peer);
      _discoveredPeers[deviceId] = peer.copyWith(isOnline: false);
    }
    notifyListeners();
  }

  /// Send a text message to a peer
  Future<bool> sendMessage(Message message, String targetDeviceId) async {
    try {
      final data = utf8.encode(jsonEncode(message.toJson()));
      return await _writeToCharacteristic(
          targetDeviceId, CHAR_MSG_UUID, data);
    } catch (e) {
      debugPrint("Error sending message: $e");
      return false;
    }
  }

  /// Broadcast a message to all connected peers
  Future<void> broadcastMessage(Message message) async {
    final data = utf8.encode(jsonEncode(message.toJson()));
    for (String deviceId in _connectedDevices.keys) {
      await _writeToCharacteristic(deviceId, CHAR_MSG_UUID, data);
    }
  }

  /// Send location to a peer
  Future<bool> sendLocation(Message locationMessage, String targetDeviceId) async {
    try {
      final data = utf8.encode(jsonEncode(locationMessage.toJson()));
      return await _writeToCharacteristic(
          targetDeviceId, CHAR_LOC_UUID, data);
    } catch (e) {
      debugPrint("Error sending location: $e");
      return false;
    }
  }

  /// Send call signal (ring, accept, reject, end)
  Future<bool> sendCallSignal(
      Map<String, dynamic> signal, String targetDeviceId) async {
    try {
      final data = utf8.encode(jsonEncode(signal));
      return await _writeToCharacteristic(
          targetDeviceId, CHAR_CALL_UUID, data);
    } catch (e) {
      debugPrint("Error sending call signal: $e");
      return false;
    }
  }

  /// Send audio data during a call
  Future<bool> sendAudioData(Uint8List audioData, String targetDeviceId) async {
    return await _writeToCharacteristic(
        targetDeviceId, CHAR_CALL_UUID, audioData);
  }

  /// Write data to a BLE characteristic
  Future<bool> _writeToCharacteristic(
      String deviceId, String characteristicUuid, List<int> data) async {
    try {
      final device = _connectedDevices[deviceId];
      if (device == null) return false;

      List<BluetoothService> services = await device.discoverServices();
      for (BluetoothService service in services) {
        if (service.uuid.str == SERVICE_UUID) {
          for (BluetoothCharacteristic char in service.characteristics) {
            if (char.uuid.str == characteristicUuid) {
              // Split data into chunks if too large (BLE MTU limit ~512 bytes)
              final chunks = _splitIntoChunks(data, 500);
              for (var chunk in chunks) {
                await char.write(chunk, withoutResponse: false);
              }
              return true;
            }
          }
        }
      }
      return false;
    } catch (e) {
      debugPrint("Error writing to characteristic: $e");
      return false;
    }
  }

  /// Split data into BLE-compatible chunks
  List<List<int>> _splitIntoChunks(List<int> data, int chunkSize) {
    final chunks = <List<int>>[];
    for (int i = 0; i < data.length; i += chunkSize) {
      final end = (i + chunkSize < data.length) ? i + chunkSize : data.length;
      chunks.add(data.sublist(i, end));
    }
    return chunks;
  }

  /// Mesh relay: forward message to other peers if needed
  Future<void> _relayMessageIfNeeded(
      Message message, String sourceDeviceId) async {
    // Don't relay if hop count is too high (prevent infinite loops)
    if (message.hopCount >= 5) return;

    // Create relayed message with incremented hop
    final relayedMessage = message.copyWith(
      hopCount: message.hopCount + 1,
      relayedBy: [...message.relayedBy, sourceDeviceId],
    );

    // Forward to all other connected devices (except source)
    for (String deviceId in _connectedDevices.keys) {
      if (deviceId != sourceDeviceId &&
          !message.relayedBy.contains(deviceId)) {
        await sendMessage(relayedMessage, deviceId);
      }
    }
  }

  /// Get signal strength for a device
  int getSignalStrength(String deviceId) {
    return _discoveredPeers[deviceId]?.signalStrength ?? -100;
  }

  /// Check if a specific peer is connected
  bool isPeerConnected(String deviceId) {
    return _connectedDevices.containsKey(deviceId);
  }

  /// Dispose resources
  @override
  void dispose() {
    stopScanning();
    _messageController.close();
    _peerDiscoveredController.close();
    _peerLostController.close();
    _callSignalController.close();
    _audioDataController.close();
    
    // Disconnect all devices
    for (var device in _connectedDevices.values) {
      device.disconnect();
    }
    _connectedDevices.clear();
    
    super.dispose();
  }
}
