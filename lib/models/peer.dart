import 'package:hive/hive.dart';

part 'peer.g.dart';

@HiveType(typeId: 0)
class Peer extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String? avatar;

  @HiveField(3)
  final String publicKey;

  @HiveField(4)
  final String deviceId;

  @HiveField(5)
  final DateTime lastSeen;

  @HiveField(6)
  final bool isOnline;

  @HiveField(7)
  final double? latitude;

  @HiveField(8)
  final double? longitude;

  @HiveField(9)
  final ConnectionType connectionType;

  @HiveField(10)
  final int signalStrength;

  Peer({
    required this.id,
    required this.name,
    this.avatar,
    required this.publicKey,
    required this.deviceId,
    required this.lastSeen,
    this.isOnline = false,
    this.latitude,
    this.longitude,
    this.connectionType = ConnectionType.bluetooth,
    this.signalStrength = 0,
  });

  Peer copyWith({
    String? id,
    String? name,
    String? avatar,
    String? publicKey,
    String? deviceId,
    DateTime? lastSeen,
    bool? isOnline,
    double? latitude,
    double? longitude,
    ConnectionType? connectionType,
    int? signalStrength,
  }) {
    return Peer(
      id: id ?? this.id,
      name: name ?? this.name,
      avatar: avatar ?? this.avatar,
      publicKey: publicKey ?? this.publicKey,
      deviceId: deviceId ?? this.deviceId,
      lastSeen: lastSeen ?? this.lastSeen,
      isOnline: isOnline ?? this.isOnline,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      connectionType: connectionType ?? this.connectionType,
      signalStrength: signalStrength ?? this.signalStrength,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'avatar': avatar,
        'publicKey': publicKey,
        'deviceId': deviceId,
        'lastSeen': lastSeen.toIso8601String(),
        'isOnline': isOnline,
        'latitude': latitude,
        'longitude': longitude,
        'connectionType': connectionType.index,
        'signalStrength': signalStrength,
      };

  factory Peer.fromJson(Map<String, dynamic> json) => Peer(
        id: json['id'],
        name: json['name'],
        avatar: json['avatar'],
        publicKey: json['publicKey'],
        deviceId: json['deviceId'],
        lastSeen: DateTime.parse(json['lastSeen']),
        isOnline: json['isOnline'] ?? false,
        latitude: json['latitude']?.toDouble(),
        longitude: json['longitude']?.toDouble(),
        connectionType: ConnectionType.values[json['connectionType'] ?? 0],
        signalStrength: json['signalStrength'] ?? 0,
      );
}

@HiveType(typeId: 3)
enum ConnectionType {
  @HiveField(0)
  bluetooth,

  @HiveField(1)
  wifiDirect,

  @HiveField(2)
  both,
}
