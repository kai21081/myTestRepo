import 'dart:collection';
import 'dart:math';

import 'package:gameplayground/models/emg_sample.dart';

// Class to store an EMG recording, that consist of a series of measurements,
// where measurements are stored in some class that extends EmgSample. Contains
// convenience methods for accessing certain features of the dataset as well as
// formatting the dataset in a manner amenable to saving.
class EmgRecording<T extends EmgSample> {
  List<T> _data = List<T>();

  UnmodifiableListView<T> get data => UnmodifiableListView<T>(_data);

  bool isInitial = true;
  Average initialBaseline = new Average();
  Average inGameBaseline = new Average();

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

  void addSample(T sample, bool isFlap, int refractoryPeriod) {
    _data.add(sample);
    if(isFlap && (isInitial || (sample.timestamp - _peakFlap.last.timestamp) > refractoryPeriod)) {
      _peakFlap.add(sample);
      inFlap = true;
    }
    if(inFlap) {
      isInitial = false;
      if (_peakFlap.last.compareTo(sample) <= 0) {
        _peakFlap.removeLast();
        _peakFlap.add(sample);
      }
      else {
        inFlap = false;
      }
    } else {
      if(isInitial) {
        if(initialBaseline.shouldAddSample(sample))
          initialBaseline.addSample(sample);
      } else {
        if(inGameBaseline.shouldAddSample(sample))
          initialBaseline.addSample(sample);
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

class Average {
  double mean;
  int numSamples;
  double stdDev;
  final double zScoreLimit = 2;//Number of standard deviations away from the mean to discard samples

  Average() {
    mean = 0;
    numSamples = 0;
    stdDev = 0;
  }

  bool shouldAddSample(EmgSample e) {
    double sample = emgToSample(e);
    return stdDev == 0 || mean == 0 || sample <= mean + zScoreLimit * stdDev;
  }

  void addSample(EmgSample e) {
    double sample = emgToSample(e);
    double variance = stdDev*stdDev;
    numSamples++;
    double newMean = mean + (sample-mean)/numSamples;

    //https://math.stackexchange.com/questions/775391/can-i-calculate-the-new-standard-deviation-when-adding-a-value-without-knowing-t
    variance = ((numSamples - 2)*variance + (sample - newMean)*(sample - mean))/(numSamples - 1);
    stdDev = sqrt(variance);
    mean = newMean;
  }

  double emgToSample(EmgSample e) {
    if(e is RawEmgSample) {
      RawEmgSample sampleRaw = e;
      return sampleRaw.voltage;
    } else if(e is ProcessedEmgSample) {
      ProcessedEmgSample sampleProcessed = e;
      return sampleProcessed.filteredValue  ;
    }
  }

  double getMean() {return mean;}

  double getStdDev() {return stdDev;}


}
