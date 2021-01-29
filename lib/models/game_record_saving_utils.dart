import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import 'package:gameplayground/models/emg_sample.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

import 'emg_recording.dart';
import 'game_settings.dart';
import 'gameplay_data.dart';

const String recordingsDirectoryName = 'recordings';
const String _jsonExtension = '.json';

Future<String> getRecordingsDirectoryPath() async {
  return getApplicationSupportDirectory().then((Directory supportDirectory) {
    return path.join(supportDirectory.path, recordingsDirectoryName);
  });
}

Future<void> createRecordingsDirectory() async {
  return getRecordingsDirectoryPath().then((String directoryPath) {
    return Directory(directoryPath).create(recursive: true);
  });
}

Future<String> buildSavePathInRecordingsDirectoryFromFilename(String filename,
    [String extension = _jsonExtension]) async {
  return getRecordingsDirectoryPath().then((String supportDirectoryPath) {
    return path.join(supportDirectoryPath, filename + extension);
  });
}

Future<bool> recordingFilenameAlreadyExists(String filename,
    [String extension = _jsonExtension]) async {
  return buildSavePathInRecordingsDirectoryFromFilename(filename, extension)
      .then((String savePath) {
    return File(savePath).exists();
  });
}

void saveRecordingWithMetadata(
    EmgRecording recording, String savePath, String dataJsonIdentifier,
    [Map<String, dynamic> metadata]) {
  Map<String, dynamic> jsonData = Map<String, dynamic>();
  if (metadata != null) {
    jsonData.addAll(metadata);
  }
  jsonData[dataJsonIdentifier] = recording.getDataAsListOfMaps();

  File saveFile = File(savePath);
  saveFile.create();
  saveFile.writeAsString(jsonEncode(jsonData));
}

void saveGameRecord(String userId, GameSettings gameSettings,
    EmgRecording recording, GameplayData gameplayData, String savePath) {
  // Convert to JSON.
  Map<String, dynamic> metadata = Map<String, dynamic>();

  metadata['userId'] = userId;

  // Add data about game settings.
  metadata['scrollVelocityInScreenWidthsPerSecond'] =
      gameSettings.scrollVelocityInScreenWidthsPerSecond;
  metadata['flapVelocityInScreenHeightFractionPerSecond'] =
      gameSettings.flapVelocityInScreenHeightFractionPerSecond;
  metadata['terminalVelocityInScreenHeightFractionPerSecond'] =
      gameSettings.terminalVelocityInScreenHeightFractionPerSecond;
  metadata['cherrySpawnRatePerSecond'] = gameSettings.cherrySpawnRatePerSecond;
  metadata['playMusic'] = gameSettings.playMusic;
  metadata['musicVolume'] = gameSettings.musicVolume;
  // Add gameplay data.
  metadata['gameplayData'] = gameplayData.asMap();

  saveRecordingWithMetadata(recording, savePath, 'processedData', metadata);
}
