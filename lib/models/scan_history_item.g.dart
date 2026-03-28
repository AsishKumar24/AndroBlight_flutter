// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'scan_history_item.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ScanHistoryItemAdapter extends TypeAdapter<ScanHistoryItem> {
  @override
  final int typeId = 0;

  @override
  ScanHistoryItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ScanHistoryItem(
      scanType: fields[0] as String,
      identifier: fields[1] as String,
      timestamp: fields[2] as DateTime,
      label: fields[3] as String,
      confidence: fields[4] as double,
      fileName: fields[5] as String?,
      fileSize: fields[6] as int?,
      verdictChanged: fields[7] == null ? false : fields[7] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, ScanHistoryItem obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.scanType)
      ..writeByte(1)
      ..write(obj.identifier)
      ..writeByte(2)
      ..write(obj.timestamp)
      ..writeByte(3)
      ..write(obj.label)
      ..writeByte(4)
      ..write(obj.confidence)
      ..writeByte(5)
      ..write(obj.fileName)
      ..writeByte(6)
      ..write(obj.fileSize)
      ..writeByte(7)
      ..write(obj.verdictChanged);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ScanHistoryItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
