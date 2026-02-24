import 'package:hive/hive.dart';

part 'message.g.dart';

@HiveType(typeId: 1)
class Message extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String senderId;

  @HiveField(2)
  final String receiverId;

  @HiveField(3)
  final String content;

  @HiveField(4)
  final MessageType type;

  @HiveField(5)
  final DateTime timestamp;

  @HiveField(6)
  final MessageStatus status;

  @HiveField(7)
  final bool isBroadcast;

  @HiveField(8)
  final double? latitude;

  @HiveField(9)
  final double? longitude;

  @HiveField(10)
  final String? locationName;

  @HiveField(11)
  final int hopCount;

  @HiveField(12)
  final List<String> relayedBy;

  @HiveField(13)
  final bool isEncrypted;

  Message({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.content,
    required this.type,
    required this.timestamp,
    this.status = MessageStatus.sending,
    this.isBroadcast = false,
    this.latitude,
    this.longitude,
    this.locationName,
    this.hopCount = 0,
    this.relayedBy = const [],
    this.isEncrypted = true,
  });

  Message copyWith({
    String? id,
    String? senderId,
    String? receiverId,
    String? content,
    MessageType? type,
    DateTime? timestamp,
    MessageStatus? status,
    bool? isBroadcast,
    double? latitude,
    double? longitude,
    String? locationName,
    int? hopCount,
    List<String>? relayedBy,
    bool? isEncrypted,
  }) {
    return Message(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      receiverId: receiverId ?? this.receiverId,
      content: content ?? this.content,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      status: status ?? this.status,
      isBroadcast: isBroadcast ?? this.isBroadcast,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      locationName: locationName ?? this.locationName,
      hopCount: hopCount ?? this.hopCount,
      relayedBy: relayedBy ?? this.relayedBy,
      isEncrypted: isEncrypted ?? this.isEncrypted,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'senderId': senderId,
        'receiverId': receiverId,
        'content': content,
        'type': type.index,
        'timestamp': timestamp.toIso8601String(),
        'status': status.index,
        'isBroadcast': isBroadcast,
        'latitude': latitude,
        'longitude': longitude,
        'locationName': locationName,
        'hopCount': hopCount,
        'relayedBy': relayedBy,
        'isEncrypted': isEncrypted,
      };

  factory Message.fromJson(Map<String, dynamic> json) => Message(
        id: json['id'],
        senderId: json['senderId'],
        receiverId: json['receiverId'],
        content: json['content'],
        type: MessageType.values[json['type']],
        timestamp: DateTime.parse(json['timestamp']),
        status: MessageStatus.values[json['status'] ?? 0],
        isBroadcast: json['isBroadcast'] ?? false,
        latitude: json['latitude']?.toDouble(),
        longitude: json['longitude']?.toDouble(),
        locationName: json['locationName'],
        hopCount: json['hopCount'] ?? 0,
        relayedBy: List<String>.from(json['relayedBy'] ?? []),
        isEncrypted: json['isEncrypted'] ?? true,
      );
}

@HiveType(typeId: 4)
enum MessageType {
  @HiveField(0)
  text,

  @HiveField(1)
  location,

  @HiveField(2)
  voice,

  @HiveField(3)
  image,

  @HiveField(4)
  callRequest,

  @HiveField(5)
  callAccept,

  @HiveField(6)
  callReject,

  @HiveField(7)
  callEnd,

  @HiveField(8)
  peerDiscovery,

  @HiveField(9)
  peerAck,

  @HiveField(10)
  meshRelay,
}

@HiveType(typeId: 5)
enum MessageStatus {
  @HiveField(0)
  sending,

  @HiveField(1)
  sent,

  @HiveField(2)
  delivered,

  @HiveField(3)
  read,

  @HiveField(4)
  failed,
}
