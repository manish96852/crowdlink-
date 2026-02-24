// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'call_info.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CallInfoAdapter extends TypeAdapter<CallInfo> {
  @override
  final int typeId = 2;

  @override
  CallInfo read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CallInfo(
      id: fields[0] as String,
      callerId: fields[1] as String,
      callerName: fields[2] as String,
      receiverId: fields[3] as String,
      receiverName: fields[4] as String,
      state: fields[5] as CallState,
      callType: fields[6] as CallType,
      startTime: fields[7] as DateTime,
      endTime: fields[8] as DateTime?,
      durationSeconds: fields[9] as int,
      isMuted: fields[10] as bool,
      isSpeakerOn: fields[11] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, CallInfo obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.callerId)
      ..writeByte(2)
      ..write(obj.callerName)
      ..writeByte(3)
      ..write(obj.receiverId)
      ..writeByte(4)
      ..write(obj.receiverName)
      ..writeByte(5)
      ..write(obj.state)
      ..writeByte(6)
      ..write(obj.callType)
      ..writeByte(7)
      ..write(obj.startTime)
      ..writeByte(8)
      ..write(obj.endTime)
      ..writeByte(9)
      ..write(obj.durationSeconds)
      ..writeByte(10)
      ..write(obj.isMuted)
      ..writeByte(11)
      ..write(obj.isSpeakerOn);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CallInfoAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class CallStateAdapter extends TypeAdapter<CallState> {
  @override
  final int typeId = 6;

  @override
  CallState read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return CallState.idle;
      case 1:
        return CallState.ringing;
      case 2:
        return CallState.connecting;
      case 3:
        return CallState.active;
      case 4:
        return CallState.ended;
      case 5:
        return CallState.missed;
      case 6:
        return CallState.rejected;
      default:
        return CallState.idle;
    }
  }

  @override
  void write(BinaryWriter writer, CallState obj) {
    switch (obj) {
      case CallState.idle:
        writer.writeByte(0);
        break;
      case CallState.ringing:
        writer.writeByte(1);
        break;
      case CallState.connecting:
        writer.writeByte(2);
        break;
      case CallState.active:
        writer.writeByte(3);
        break;
      case CallState.ended:
        writer.writeByte(4);
        break;
      case CallState.missed:
        writer.writeByte(5);
        break;
      case CallState.rejected:
        writer.writeByte(6);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CallStateAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class CallTypeAdapter extends TypeAdapter<CallType> {
  @override
  final int typeId = 7;

  @override
  CallType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return CallType.voice;
      case 1:
        return CallType.walkieTalkie;
      default:
        return CallType.voice;
    }
  }

  @override
  void write(BinaryWriter writer, CallType obj) {
    switch (obj) {
      case CallType.voice:
        writer.writeByte(0);
        break;
      case CallType.walkieTalkie:
        writer.writeByte(1);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CallTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
