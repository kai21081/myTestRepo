import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';

import 'models/bluetooth_manager.dart';
import 'models/emg_sample.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  BluetoothManager bluetoothManager = BluetoothManager();
  bluetoothManager.connect(ConnectionSpec.fromDeviceName(''));
  bluetoothManager.addHandleSEmgValueCallback(
      'test', (EmgSample value) => print(value.value));

  bool connectNext = false;
  Random randomNumberGenerator = Random();
  for (int i = 0; i < 10; i++) {
    int sleepDuration = randomNumberGenerator.nextInt(30) + 1;
    print('sleeping for $sleepDuration seconds');
//    sleep(Duration(seconds: sleepDuration));
    await new Future.delayed(Duration(seconds: sleepDuration));
    if (connectNext) {
      bluetoothManager.connect(ConnectionSpec.fromDeviceName(''));
    } else {
      bluetoothManager.reset();
    }
    connectNext = !connectNext;
  }
}
