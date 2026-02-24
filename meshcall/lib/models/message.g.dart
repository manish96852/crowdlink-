// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'message.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MessageAdapter extends TypeAdapter<Message> {
  @override
  final int typeId = 1;

  @override
  Message read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Message(
      id: fields[0] as String,
      senderId: fields[1] as String,
      receiverId: fields[2] as String,
      content: fields[3] as String,
      type: fields[4] as MessageType,
      timestamp: fields[5] as DateTime,
      status: fields[6] as MessageStatus,
      isBroadcast: fields[7] as bool,
      latitude: fields[8] as double?,
      longitude: fields[9] as double?,
      locationName: fields[10] as String?,
      hopCount: fields[11] as int,
      relayedBy: (fields[12] as List).cast<String>(),
      isEncrypted: fields[13] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, Message obj) {
    writer
      ..writeByte(14)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.senderId)
      ..writeByte(2)
      ..write(obj.receiverId)
      ..writeByte(3)
      ..write(obj.content)
      ..writeByte(4)
      ..write(obj.type)
      ..writeByte(5)
      ..write(obj.timestamp)
      ..writeByte(6)
      ..write(obj.status)
      ..writeByte(7)
      ..write(obj.isBroadcast)
      ..writeByte(8)
      ..write(obj.latitude)
      ..writeByte(9)
      ..write(obj.longitude)
      ..writeByte(10)
      ..write(obj.locationName)
      ..writeByte(11)
      ..write(obj.hopCount)
      ..writeByte(12)
      ..write(obj.relayedBy)
      ..writeByte(13)
      ..write(obj.isEncrypted);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MessageAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class MessageTypeAdapter extends TypeAdapter<MessageType> {
  @override
  final int typeId = 4;

  @override
  MessageType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return MessageType.text;
      case 1:
        return MessageType.location;
      case 2:
        return MessageType.voice;
      case 3:
        return MessageType.image;
      case 4:
        return MessageType.callRequest;
      case 5:
        return MessageType.callAccept;
      case 6:
        return MessageType.callReject;
      case 7:
        return MessageType.callEnd;
      case 8:
        return MessageType.peerDiscovery;
      case 9:
        return MessageType.peerAck;
      case 10:
        return MessageType.meshRelay;
      default:
        return MessageType.text;
    }
  }

  @override
  void write(BinaryWriter writer, MessageType obj) {
    switch (obj) {
      case MessageType.text:
        writer.writeByte(0);
        break;
      case MessageType.location:
        writer.writeByte(1);
        break;
      case MessageType.voice:
        writer.writeByte(2);
        break;
      case MessageType.image:
        writer.writeByte(3);
        break;
      case MessageType.callRequest:
        writer.writeByte(4);
        break;
      case MessageType.callAccept:
        writer.writeByte(5);
        break;
      case MessageType.callReject:
        writer.writeByte(6);
        break;
      case MessageType.callEnd:
        writer.writeByte(7);
        break;
      case MessageType.peerDiscovery:
        writer.writeByte(8);
        break;
      case MessageType.peerAck:
        writer.writeByte(9);
        break;
      case MessageType.meshRelay:
        writer.writeByte(10);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MessageTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class MessageStatusAdapter extends TypeAdapter<MessageStatus> {
  @override
  final int typeId = 5;

  @override
  MessageStatus read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return MessageStatus.sending;
      case 1:
        return MessageStatus.sent;
      case 2:
        return MessageStatus.delivered;
      case 3:
        return MessageStatus.read;
      case 4:
        return MessageStatus.failed;
      default:
        return MessageStatus.sending;
    }
  }

  @override
  void write(BinaryWriter writer, MessageStatus obj) {
    switch (obj) {
      case MessageStatus.sending:
        writer.writeByte(0);
        break;
      case MessageStatus.sent:
        writer.writeByte(1);
        break;
      case MessageStatus.delivered:
        writer.writeByte(2);
        break;
      case MessageStatus.read:
        writer.writeByte(3);
        break;
      case MessageStatus.failed:
        writer.writeByte(4);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MessageStatusAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
