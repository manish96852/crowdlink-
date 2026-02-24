import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/models.dart';

/// Local Database Service using Hive (No-SQL, offline-first)
class DatabaseService {
  static const String _peersBox = 'peers';
  static const String _messagesBox = 'messages';
  static const String _callHistoryBox = 'call_history';
  static const String _settingsBox = 'settings';

  late Box<Map> _peersBoxInstance;
  late Box<Map> _messagesBoxInstance;
  late Box<Map> _callHistoryBoxInstance;
  late Box _settingsBoxInstance;

  /// Initialize Hive database
  Future<void> initialize() async {
    await Hive.initFlutter();

    _peersBoxInstance = await Hive.openBox<Map>(_peersBox);
    _messagesBoxInstance = await Hive.openBox<Map>(_messagesBox);
    _callHistoryBoxInstance = await Hive.openBox<Map>(_callHistoryBox);
    _settingsBoxInstance = await Hive.openBox(_settingsBox);

    debugPrint("Database initialized");
  }

  // ==================== PEERS ====================

  /// Save a peer
  Future<void> savePeer(Peer peer) async {
    await _peersBoxInstance.put(peer.id, peer.toJson());
  }

  /// Get all saved peers
  Future<List<Peer>> getAllPeers() async {
    return _peersBoxInstance.values
        .map((json) => Peer.fromJson(Map<String, dynamic>.from(json)))
        .toList();
  }

  /// Get a specific peer
  Future<Peer?> getPeer(String peerId) async {
    final json = _peersBoxInstance.get(peerId);
    if (json != null) {
      return Peer.fromJson(Map<String, dynamic>.from(json));
    }
    return null;
  }

  /// Delete a peer
  Future<void> deletePeer(String peerId) async {
    await _peersBoxInstance.delete(peerId);
  }

  /// Update peer online status
  Future<void> updatePeerStatus(String peerId, bool isOnline) async {
    final json = _peersBoxInstance.get(peerId);
    if (json != null) {
      final peer = Peer.fromJson(Map<String, dynamic>.from(json));
      await savePeer(peer.copyWith(
        isOnline: isOnline,
        lastSeen: DateTime.now(),
      ));
    }
  }

  // ==================== MESSAGES ====================

  /// Save a message
  Future<void> saveMessage(Message message) async {
    await _messagesBoxInstance.put(message.id, message.toJson());
  }

  /// Get messages for a conversation (between me and a peer)
  Future<List<Message>> getMessages(String peerId) async {
    final allMessages = _messagesBoxInstance.values
        .map((json) => Message.fromJson(Map<String, dynamic>.from(json)))
        .where((msg) =>
            msg.senderId == peerId ||
            msg.receiverId == peerId)
        .toList();

    allMessages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return allMessages;
  }

  /// Get all broadcast messages
  Future<List<Message>> getBroadcastMessages() async {
    return _messagesBoxInstance.values
        .map((json) => Message.fromJson(Map<String, dynamic>.from(json)))
        .where((msg) => msg.isBroadcast)
        .toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
  }

  /// Get last message for each conversation
  Future<Map<String, Message>> getLastMessages(String myId) async {
    final lastMessages = <String, Message>{};
    
    final allMessages = _messagesBoxInstance.values
        .map((json) => Message.fromJson(Map<String, dynamic>.from(json)))
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    for (var msg in allMessages) {
      final peerId =
          msg.senderId == myId ? msg.receiverId : msg.senderId;
      if (!lastMessages.containsKey(peerId)) {
        lastMessages[peerId] = msg;
      }
    }

    return lastMessages;
  }

  /// Delete a message
  Future<void> deleteMessage(String messageId) async {
    await _messagesBoxInstance.delete(messageId);
  }

  /// Clear all messages for a conversation
  Future<void> clearConversation(String peerId) async {
    final messagesToDelete = _messagesBoxInstance.values
        .map((json) => Message.fromJson(Map<String, dynamic>.from(json)))
        .where((msg) =>
            msg.senderId == peerId || msg.receiverId == peerId)
        .map((msg) => msg.id)
        .toList();

    for (var id in messagesToDelete) {
      await _messagesBoxInstance.delete(id);
    }
  }

  // ==================== CALL HISTORY ====================

  /// Save call record
  Future<void> saveCallRecord(CallInfo callInfo) async {
    await _callHistoryBoxInstance.put(callInfo.id, callInfo.toJson());
  }

  /// Get all call history
  Future<List<CallInfo>> getCallHistory() async {
    return _callHistoryBoxInstance.values
        .map((json) => CallInfo.fromJson(Map<String, dynamic>.from(json)))
        .toList()
      ..sort((a, b) => b.startTime.compareTo(a.startTime));
  }

  /// Get calls for a specific peer
  Future<List<CallInfo>> getCallsForPeer(String peerId) async {
    return _callHistoryBoxInstance.values
        .map((json) => CallInfo.fromJson(Map<String, dynamic>.from(json)))
        .where((call) =>
            call.callerId == peerId || call.receiverId == peerId)
        .toList()
      ..sort((a, b) => b.startTime.compareTo(a.startTime));
  }

  // ==================== SETTINGS ====================

  /// Save a setting
  Future<void> saveSetting(String key, dynamic value) async {
    await _settingsBoxInstance.put(key, value);
  }

  /// Get a setting
  T? getSetting<T>(String key, {T? defaultValue}) {
    return _settingsBoxInstance.get(key, defaultValue: defaultValue) as T?;
  }

  /// Save user profile
  Future<void> saveUserProfile({
    required String name,
    required String deviceId,
    String? avatar,
  }) async {
    await saveSetting('user_name', name);
    await saveSetting('device_id', deviceId);
    if (avatar != null) await saveSetting('user_avatar', avatar);
  }

  /// Get user profile
  Map<String, String?> getUserProfile() {
    return {
      'name': getSetting<String>('user_name'),
      'deviceId': getSetting<String>('device_id'),
      'avatar': getSetting<String>('user_avatar'),
    };
  }

  /// Clear all data (factory reset)
  Future<void> clearAllData() async {
    await _peersBoxInstance.clear();
    await _messagesBoxInstance.clear();
    await _callHistoryBoxInstance.clear();
    await _settingsBoxInstance.clear();
  }

  /// Close all boxes
  Future<void> close() async {
    await Hive.close();
  }
}
