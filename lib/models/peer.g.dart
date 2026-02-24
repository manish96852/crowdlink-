// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'peer.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PeerAdapter extends TypeAdapter<Peer> {
  @override
  final int typeId = 0;

  @override
  Peer read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Peer(
      id: fields[0] as String,
      name: fields[1] as String,
      avatar: fields[2] as String?,
      publicKey: fields[3] as String,
      deviceId: fields[4] as String,
      lastSeen: fields[5] as DateTime,
      isOnline: fields[6] as bool,
      latitude: fields[7] as double?,
      longitude: fields[8] as double?,
      connectionType: fields[9] as ConnectionType,
      signalStrength: fields[10] as int,
    );
  }

  @override
  void write(BinaryWriter writer, Peer obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.avatar)
      ..writeByte(3)
      ..write(obj.publicKey)
      ..writeByte(4)
      ..write(obj.deviceId)
      ..writeByte(5)
      ..write(obj.lastSeen)
      ..writeByte(6)
      ..write(obj.isOnline)
      ..writeByte(7)
      ..write(obj.latitude)
      ..writeByte(8)
      ..write(obj.longitude)
      ..writeByte(9)
      ..write(obj.connectionType)
      ..writeByte(10)
      ..write(obj.signalStrength);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PeerAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ConnectionTypeAdapter extends TypeAdapter<ConnectionType> {
  @override
  final int typeId = 3;

  @override
  ConnectionType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return ConnectionType.bluetooth;
      case 1:
        return ConnectionType.wifiDirect;
      case 2:
        return ConnectionType.both;
      default:
        return ConnectionType.bluetooth;
    }
  }

  @override
  void write(BinaryWriter writer, ConnectionType obj) {
    switch (obj) {
      case ConnectionType.bluetooth:
        writer.writeByte(0);
        break;
      case ConnectionType.wifiDirect:
        writer.writeByte(1);
        break;
      case ConnectionType.both:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ConnectionTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
