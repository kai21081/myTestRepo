import 'dart:typed_data';

abstract class EmgSample  implements Comparable<EmgSample>{
  final int timestamp;

  EmgSample(this.timestamp);

  Map<String, dynamic> asMap();

  int compareTo(EmgSample other);
}

class RawEmgSample extends EmgSample{
  final double voltage;
  final double gain;

  RawEmgSample(int timestamp, this.voltage, this.gain) : super(timestamp);

  factory RawEmgSample.fromRawIntList(List<int> rawData) {
    final int timestamp = DateTime.now().millisecondsSinceEpoch;
    ByteData data = ByteData.view(Int8List.fromList(rawData).buffer);
    final double voltage = data.getFloat32(0, Endian.little);
    final double gain = data.getFloat32(4, Endian.little);

    print('RawEmgSample constructed from $rawData:');
    print('    voltage: $voltage, gain: $gain');

    return RawEmgSample(timestamp, voltage, gain);
  }

  String toString() {
    return 'timestamp: $timestamp, voltage: $voltage, gain: $gain}';
  }

  Map<String, dynamic> asMap() {
    return {'timestamp': timestamp, 'rawValue': voltage, 'gain': gain};
  }

  int compareTo(EmgSample other) {
    RawEmgSample otherRaw = other;
    return voltage.compareTo(otherRaw.voltage);
  }
}

class ProcessedEmgSample extends EmgSample{
  double gain;
  double rawValue;
  double filteredValue;
  bool trigger;
  bool triggerSignalPassedToGame;

  ProcessedEmgSample(int timestamp, this.rawValue, this.gain)
      : super(timestamp);

  ProcessedEmgSample.fromRawEmgSample(RawEmgSample sample)
      : this.rawValue = sample.voltage,
        this.gain = sample.gain,
        super(sample.timestamp);

  Map<String, dynamic> asMap() {
    return {
      'timestamp': timestamp,
      'rawValue': rawValue,
      'gain': gain,
      'filteredValue': filteredValue,
      'trigger': trigger,
      'triggerSignalPassedToGame': triggerSignalPassedToGame
    };
  }

  int compareTo(EmgSample other) {
    ProcessedEmgSample otherProcessed = other;
    return filteredValue.compareTo(otherProcessed.filteredValue);
  }
}
