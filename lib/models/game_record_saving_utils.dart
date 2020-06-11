import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import 'game_settings.dart';
import 'gameplay_data.dart';
import 'thresholded_trigger_data_processor.dart';

void saveGameRecord(
    String userId,
    GameSettings gameSettings,
    UnmodifiableListView<ProcessedDataPoint> processedData,
    GameplayData gameplayData,
    String savePath) {
  // Convert to JSON.
  Map<String, dynamic> jsonData = Map<String, dynamic>();

  jsonData['userId'] = userId;

  // Add data about game settings.
  jsonData['scrollVelocityInScreenWidthsPerSecond'] =
      gameSettings.scrollVelocityInScreenWidthsPerSecond;
  jsonData['flapVelocityInScreenHeightFractionPerSecond'] =
      gameSettings.flapVelocityInScreenHeightFractionPerSecond;
  jsonData['terminalVelocityInScreenHeightFractionPerSecond'] =
      gameSettings.terminalVelocityInScreenHeightFractionPerSecond;
  jsonData['cherrySpawnRatePerSecond'] = gameSettings.cherrySpawnRatePerSecond;
  jsonData['playMusic'] = gameSettings.playMusic;
  jsonData['musicVolume'] = gameSettings.musicVolume;

  // Add processed data.
  jsonData['processedData'] = List<Map<String, dynamic>>.from(
      processedData.map((sample) => sample.asMap()));

  // Add gameplay data.
  jsonData['gameplayData'] = gameplayData.asMap();

  File saveFile = File(savePath);
  saveFile.create();
  saveFile.writeAsString(jsonEncode(jsonData));
}
