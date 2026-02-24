import 'package:hive/hive.dart';

part 'call_info.g.dart';

@HiveType(typeId: 2)
class CallInfo extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String callerId;

  @HiveField(2)
  final String callerName;

  @HiveField(3)
  final String receiverId;

  @HiveField(4)
  final String receiverName;

  @HiveField(5)
  final CallState state;

  @HiveField(6)
  final CallType callType;

  @HiveField(7)
  final DateTime startTime;

  @HiveField(8)
  final DateTime? endTime;

  @HiveField(9)
  final int durationSeconds;

  @HiveField(10)
  final bool isMuted;

  @HiveField(11)
  final bool isSpeakerOn;

  CallInfo({
    required this.id,
    required this.callerId,
    required this.callerName,
    required this.receiverId,
    required this.receiverName,
    this.state = CallState.idle,
    this.callType = CallType.voice,
    required this.startTime,
    this.endTime,
    this.durationSeconds = 0,
    this.isMuted = false,
    this.isSpeakerOn = false,
  });

  CallInfo copyWith({
    String? id,
    String? callerId,
    String? callerName,
    String? receiverId,
    String? receiverName,
    CallState? state,
    CallType? callType,
    DateTime? startTime,
    DateTime? endTime,
    int? durationSeconds,
    bool? isMuted,
    bool? isSpeakerOn,
  }) {
    return CallInfo(
      id: id ?? this.id,
      callerId: callerId ?? this.callerId,
      callerName: callerName ?? this.callerName,
      receiverId: receiverId ?? this.receiverId,
      receiverName: receiverName ?? this.receiverName,
      state: state ?? this.state,
      callType: callType ?? this.callType,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      isMuted: isMuted ?? this.isMuted,
      isSpeakerOn: isSpeakerOn ?? this.isSpeakerOn,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'callerId': callerId,
        'callerName': callerName,
        'receiverId': receiverId,
        'receiverName': receiverName,
        'state': state.index,
        'callType': callType.index,
        'startTime': startTime.toIso8601String(),
        'endTime': endTime?.toIso8601String(),
        'durationSeconds': durationSeconds,
        'isMuted': isMuted,
        'isSpeakerOn': isSpeakerOn,
      };

  factory CallInfo.fromJson(Map<String, dynamic> json) => CallInfo(
        id: json['id'],
        callerId: json['callerId'],
        callerName: json['callerName'],
        receiverId: json['receiverId'],
        receiverName: json['receiverName'],
        state: CallState.values[json['state'] ?? 0],
        callType: CallType.values[json['callType'] ?? 0],
        startTime: DateTime.parse(json['startTime']),
        endTime: json['endTime'] != null
            ? DateTime.parse(json['endTime'])
            : null,
        durationSeconds: json['durationSeconds'] ?? 0,
        isMuted: json['isMuted'] ?? false,
        isSpeakerOn: json['isSpeakerOn'] ?? false,
      );
}

@HiveType(typeId: 6)
enum CallState {
  @HiveField(0)
  idle,

  @HiveField(1)
  ringing,

  @HiveField(2)
  connecting,

  @HiveField(3)
  active,

  @HiveField(4)
  ended,

  @HiveField(5)
  missed,

  @HiveField(6)
  rejected,
}

@HiveType(typeId: 7)
enum CallType {
  @HiveField(0)
  voice,

  @HiveField(1)
  walkieTalkie,
}
