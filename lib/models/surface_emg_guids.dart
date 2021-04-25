// Utilities to allow Surface EMG GUIDs to be defined in a single location
// throughout the project.
//
// GUIDs:
//  In use:
//     Services:
//         - 6506f07a-e64c-11ea-adc1-0242ac120002 - Surface EMG Service.
//     Characteristics:
//         - 6506ed28-e64c-11ea-adc1-0242ac120002 - Surface EMG voltage.
//         - 6506ef80-e64c-11ea-adc1-0242ac120002 - Sample rate.
//         - 6506f156-e64c-11ea-adc1-0242ac120002 - Battery voltage.
//         - 6506f21e-e64c-11ea-adc1-0242ac120002 - Should stream values.
//
//  Available:
//     6506f516-e64c-11ea-adc1-0242ac120002
//     6506f610-e64c-11ea-adc1-0242ac120002
//     6506f6d8-e64c-11ea-adc1-0242ac120002
//     6506f804-e64c-11ea-adc1-0242ac120002
//     6506f8c2-e64c-11ea-adc1-0242ac120002

import 'package:flutter_blue/flutter_blue.dart';

const String surfaceEmgServiceGuid = '6506f07a-e64c-11ea-adc1-0242ac120002';
const String surfaceEmgVoltageCharacteristicGuid =
    '6506ed28-e64c-11ea-adc1-0242ac120002';
const String surfaceEmgSampleRateCharacteristicGuid =
    '6506ef80-e64c-11ea-adc1-0242ac120002';
const String surfaceEmgBatteryPercentageCharacteristicGuid =
    '6506f156-e64c-11ea-adc1-0242ac120002';
const String surfaceEmgShouldStreamValuesCharacteristicGuid =
    '6506f21e-e64c-11ea-adc1-0242ac120002';
const String surfaceEmgGainControlCharacteristicUuid =
    '6506f516-e64c-11ea-adc1-0242ac120002';
const String connectionModeAuthenticationCharacteristicUuid =
    '6506f610-e64c-11ea-adc1-0242ac120002';
const String testBehaviorControllerUuid =
    '6506f6d8-e64c-11ea-adc1-0242ac120002';

class SurfaceEmgGuids {
  static Guid surfaceEmgService() {
    return Guid(surfaceEmgServiceGuid);
  }

  static Guid voltageCharacteristic() {
    return Guid(surfaceEmgVoltageCharacteristicGuid);
  }

  static Guid sampleRateCharacteristic() {
    return Guid(surfaceEmgSampleRateCharacteristicGuid);
  }

  static Guid batteryPercentageCharacteristic() {
    return Guid(surfaceEmgBatteryPercentageCharacteristicGuid);
  }

  static Guid shouldStreamValuesCharacteristic() {
    return Guid(surfaceEmgShouldStreamValuesCharacteristicGuid);
  }

  static Guid emgGainControlCharacteristic() {
    return Guid(surfaceEmgGainControlCharacteristicUuid);
  }

  static Guid connectionModeAuthenticationCharacteristic() {
    return Guid(connectionModeAuthenticationCharacteristicUuid);
  }

  static Guid testBehaviorControllerCharacteristic() {
    return Guid(testBehaviorControllerUuid);
  }
}
