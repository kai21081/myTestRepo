import 'dart:async';
import 'package:flutter/material.dart';

import 'models/bluetooth_manager_stable.dart';
import 'models/emg_sample.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  BluetoothManager bluetoothManager = BluetoothManager();
  bluetoothManager.connect(ConnectionSpec.fromDeviceName('Heartrate'));
  bluetoothManager.addHandleSEmgValueCallback(
      'test', (EmgSample value) => print(value.value));

  Timer(Duration(seconds: 20), () {
    print('resetting manager.');
    bluetoothManager.reset();
    bluetoothManager.connect(ConnectionSpec.fromDeviceName('Heartrate'));
  });
}
