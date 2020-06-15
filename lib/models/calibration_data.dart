class UserCalibrationData {
  final bool hasValue;
  final int value;
  final int timestamp;

  UserCalibrationData(this.hasValue, this.value, this.timestamp);

  static UserCalibrationData buildNoValue() {
    return UserCalibrationData(false, null, null);
  }

  static UserCalibrationData buildWithValue(int value, int timestamp) {
    return UserCalibrationData(true, value, timestamp);
  }

  String toString() {
    if (hasValue) {
      return 'Calibration Data - value: $value, timestamp: $timestamp';
    }
    return 'Calibration Data -  no value';
  }
}
