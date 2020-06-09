import 'dart:async';
import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:gameplayground/models/game_record_saving_utils.dart';
import 'package:gameplayground/models/game_settings.dart';
import 'package:gameplayground/models/gameplay_data.dart';
import 'package:gameplayground/models/mock_bluetooth_manager.dart';
import 'package:gameplayground/models/thresholded_trigger_data_processor.dart';
import 'package:path_provider/path_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  print('starting');
  MockBluetoothManager mockBluetoothManager =
      MockBluetoothManager(100, 2, 2, 2, 100);

  ThresholdedTriggerDataProcessor dataProcessor =
      ThresholdedTriggerDataProcessor(mockBluetoothManager);

  dataProcessor.startProcessing(() => print('trigger!'), true);

  Timer(Duration(milliseconds: 200), () async {
    print('closing stream');
    mockBluetoothManager.closeStream();
    GameplayData gameplayData =
        GameplayData(1, 999, 123, 456, 'v1', 'some_path');

    final supportDirectory = await getApplicationSupportDirectory();

    saveGameRecord(GameSettings(), dataProcessor.processedDataPoints,
        gameplayData, '${supportDirectory.path}/json_test.txt');
  });
}
