import 'dart:collection';

import 'package:gameplayground/models/emg_sample.dart';

// Class to store an EMG recording, that consist of a series of measurements,
// where measurements are stored in some class that extends EmgSample. Contains
// convenience methods for accessing certain features of the dataset as well as
// formatting the dataset in a manner amenable to saving.
class EmgRecording<T extends EmgSample> {
  List<T> _data = List<T>();

  UnmodifiableListView<T> get data => UnmodifiableListView<T>(_data);

  int sampleCountBaseline = 0;
  double averageBaseline = 0;

  int peakFlapIndex = 0;
  bool inFlap = false;
  List<T> _peakFlap = List<T>();

  int get startMillisecondsSinceEpoch =>
      _data.isEmpty ? 0 : _data.first.timestamp;

  int get endMillisecondsSinceEpoch => _data.isEmpty ? 0 : _data.last.timestamp;

  int get numSamples => _data.length;

  int get durationMilliseconds =>
      endMillisecondsSinceEpoch - startMillisecondsSinceEpoch;

  String get filenameTimestampSuffix =>
      '_${startMillisecondsSinceEpoch}_$endMillisecondsSinceEpoch';

  double get durationSeconds {
    return durationMilliseconds.toDouble() /
        Duration.millisecondsPerSecond.toDouble();
  }

  void addSample(T sample, bool isFlap) {
    _data.add(sample);
    if(isFlap) {
      if(!inFlap) {
        _peakFlap.add(sample);
      }
      else if (_peakFlap.last.compareTo(sample) < 0) {
        _peakFlap.removeLast();
        _peakFlap.add(sample);
      }
    } else {
      if(inFlap) {
        inFlap = false;
        peakFlapIndex++;
      }
      sampleCountBaseline++;
      if(sample is RawEmgSample) {
        RawEmgSample sampleRaw = sample;
        averageBaseline += (sampleRaw.voltage - averageBaseline)/sampleCountBaseline;
      } else if(sample is ProcessedEmgSample) {
        ProcessedEmgSample sampleRaw = sample;
        averageBaseline += (sampleRaw.filteredValue - averageBaseline)/sampleCountBaseline;
      }

    }
  }

  List<Map<String, dynamic>> getDataAsListOfMaps() {
    return _data.map((T sample) => sample.asMap()).toList();
  }

  UnmodifiableListView<T> getLastNSamples(int numberOfSamples) {
    return UnmodifiableListView<T>(
        _data.sublist(_data.length - numberOfSamples));
  }
}
