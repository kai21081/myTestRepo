import 'dart:async';
import 'dart:core';
import 'dart:math';

import 'emg_sample.dart';

class MockBluetoothManager {
  final int _timestepMicroseconds;
  final int _periodBetweenSpikesMicroseconds;
  final int _baselineAmplitude;
  final int _baselineUniformNoiseAmplitude;
  final int _spikeAmplitude;

  // ignore: close_sinks
  StreamController<RawEmgSample> _controller;
  bool _streamInitialized = false;
  Random _randomNumberGenerator;
  int _microsecondsSinceLastSpike = 0;
  int _timestampCounterMicroseconds = 0;
  Timer _dataGeneratingTimer;

  MockBluetoothManager(sampleRate, spikeRate, baselineAmplitude,
      baselineUniformNoiseAmplitude, spikeAmplitude)
      : _timestepMicroseconds = (1000000.0 / sampleRate).round(),
        _periodBetweenSpikesMicroseconds = (1000000.0 / spikeRate).round(),
        _baselineAmplitude = baselineAmplitude,
        _baselineUniformNoiseAmplitude = baselineUniformNoiseAmplitude,
        _spikeAmplitude = spikeAmplitude {
    _randomNumberGenerator = Random();
  }

  void _initializeStream() {
    if (_streamInitialized) {
      return;
    }

    _controller = StreamController<RawEmgSample>();

    _dataGeneratingTimer =
        Timer.periodic(Duration(microseconds: _timestepMicroseconds), (_) {
          int dataValue;
          if (_microsecondsSinceLastSpike > _periodBetweenSpikesMicroseconds) {
            dataValue = _spikeAmplitude;
            _microsecondsSinceLastSpike -= _periodBetweenSpikesMicroseconds;
          } else {
            int randomNoiseOffset = _randomNumberGenerator
                .nextInt(2 * _baselineUniformNoiseAmplitude + 1) -
                _baselineUniformNoiseAmplitude;
            dataValue = _baselineAmplitude + randomNoiseOffset;
          }

          _controller.sink.add(RawEmgSample(
              (_timestampCounterMicroseconds / 1000.0).round(),
              dataValue.toDouble(), /*gain=*/1.0));
              _timestampCounterMicroseconds += _timestepMicroseconds;
              _microsecondsSinceLastSpike += _timestepMicroseconds;
          });
  }

  void closeStream() {
    _dataGeneratingTimer.cancel();
    _controller.close();
    _streamInitialized = false;
  }

  // Doesn't actually start adding values to stream until this is called.
  Stream<RawEmgSample> getRawDataStream() {
    _initializeStream();
    return _controller.stream;
  }
}