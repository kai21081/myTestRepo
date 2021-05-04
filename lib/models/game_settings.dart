import 'dart:math';

import 'package:flame/game.dart';

class GameSettings {
  static const double defaultFlapVelocityInScreenHeightFractionPerSecond = 0.3;
  static const double
      flapVelocityInScreenHeightFractionPerSecondSettingStepSize = 0.05;

  static const double defaultTerminalVelocityInScreenHeightFractionPerSecond =
      0.3;
  static const double
      terminalVelocityInScreenHeightFractionPerSecondSettingStepSize = 0.05;

  static const double defaultScrollVelocityInScreenWidthsPerSecond = 0.5;
  static const double scrollVelocityInScreenWidthsPerSecondSettingStepSize =
      0.1;

  static const double defaultCherrySpawnRatePerSecond = 4.0;
  static const double cherrySpawnRatePerSecondSettingStepSize = 0.5;

  static const double defaultMusicVolume = 0.5;
  static const double musicVolumeSettingStepSize = 0.1;

  // Parameters controlling game physics and motion.
  double flapVelocityInScreenHeightFractionPerSecond;
  double terminalVelocityInScreenHeightFractionPerSecond;
  double scrollVelocityInScreenWidthsPerSecond;

  // Parameters controlling cherry targets.
  bool includeCherries;
  double cherrySpawnRatePerSecond;
  double cherryWidthAsScreenWidthFraction;
  double cherryHeightAsScreenWidthFraction;
  double cherryFractionWidthForCollision;
  double cherryFractionHeightForCollision;
  double cherryLocationMinBoundFromScreenTop;
  double cherryLocationMaxBoundFromScreenTop;

  // Parameters controlling column obstacles.
  bool includeColumns;
  double columnSpawnRatePerSecond;
  double columnWidthAsScreenWidthFraction;
  double columnHeightAsScreenWidthFraction;
  double columnHeightMinBoundFromScreenTop;
  double columnHeightMaxBoundFromScreenTop;
  double columnFractionWidthForCollision;
  double columnFractionHeightForCollision;

  // Parameters controlling practice mode (i.e., bird doesn't crash).
  bool practiceMode;

  // Parameters controlling music.
  bool playMusic;
  double musicVolume;

  // Parameters controlling the background and its movement.
  double skyBackgroundFractionScreenHeight;
  double groundBackgroundFractionScreenHeight;

  UserModifiableSettings get userModifiableSettings => UserModifiableSettings(
      flapVelocityInScreenHeightFractionPerSecond,
      terminalVelocityInScreenHeightFractionPerSecond,
      scrollVelocityInScreenWidthsPerSecond,
      cherrySpawnRatePerSecond,
      playMusic,
      musicVolume);

  // Constructor with default values.
  GameSettings(
      {this.flapVelocityInScreenHeightFractionPerSecond =
          defaultFlapVelocityInScreenHeightFractionPerSecond,
      this.terminalVelocityInScreenHeightFractionPerSecond =
          defaultTerminalVelocityInScreenHeightFractionPerSecond,
      this.scrollVelocityInScreenWidthsPerSecond =
          defaultScrollVelocityInScreenWidthsPerSecond,
      this.includeCherries = true,
      this.cherrySpawnRatePerSecond = defaultCherrySpawnRatePerSecond,
      this.cherryWidthAsScreenWidthFraction = 0.15,
      this.cherryHeightAsScreenWidthFraction = 0.15,
      this.cherryFractionWidthForCollision = 0.8,
      this.cherryFractionHeightForCollision = 0.8,
      this.cherryLocationMinBoundFromScreenTop = 0.1,
      this.cherryLocationMaxBoundFromScreenTop = 0.6,
      this.includeColumns = false,
      this.columnSpawnRatePerSecond = 3,
      this.columnWidthAsScreenWidthFraction = 0.4,
      this.columnHeightAsScreenWidthFraction = 0.7,
      this.columnFractionWidthForCollision = 0.3,
      this.columnFractionHeightForCollision = 0.9,
      this.columnHeightMinBoundFromScreenTop = 0.6,
      this.columnHeightMaxBoundFromScreenTop = 0.8,
      this.practiceMode = true,
      this.playMusic = true,
      this.musicVolume = defaultMusicVolume,
      this.skyBackgroundFractionScreenHeight = 1.0,
      this.groundBackgroundFractionScreenHeight = 0.1});

  static GameSettings withUserModifiableSettings(
      UserModifiableSettings userModifiableSettings) {
    return GameSettings(
        flapVelocityInScreenHeightFractionPerSecond:
            userModifiableSettings.flapVelocityInScreenHeightFractionPerSecond,
        terminalVelocityInScreenHeightFractionPerSecond: userModifiableSettings
            .terminalVelocityInScreenHeightFractionPerSecond,
        scrollVelocityInScreenWidthsPerSecond:
            userModifiableSettings.scrollVelocityInScreenWidthsPerSecond,
        cherrySpawnRatePerSecond:
            userModifiableSettings.cherrySpawnRatePerSecond,
        playMusic: userModifiableSettings.playMusic,
        musicVolume: userModifiableSettings.musicVolume);
  }

  static double mapFlapVelocityInScreenHeightFractionPerSecondToSliderValue(
      double value) {
    return mapValueToOneToTenSliderValueWithDefaultOfFive(
        value,
        defaultFlapVelocityInScreenHeightFractionPerSecond,
        flapVelocityInScreenHeightFractionPerSecondSettingStepSize);
  }

  static double mapSliderValueToFlapVelocityInScreenHeightFractionPerSecond(
      double value) {
    return mapOneToTenSliderValueWithDefaultOfFiveToSettingValue(
        value,
        defaultFlapVelocityInScreenHeightFractionPerSecond,
        flapVelocityInScreenHeightFractionPerSecondSettingStepSize);
  }

  static double mapTerminalVelocityInScreenHeightFractionPerSecondToSliderValue(
      double value) {
    return mapValueToOneToTenSliderValueWithDefaultOfFive(
        value,
        defaultTerminalVelocityInScreenHeightFractionPerSecond,
        terminalVelocityInScreenHeightFractionPerSecondSettingStepSize);
  }

  static double mapSliderValueToTerminalVelocityInScreenHeightFractionPerSecond(
      double value) {
    return mapOneToTenSliderValueWithDefaultOfFiveToSettingValue(
        value,
        defaultTerminalVelocityInScreenHeightFractionPerSecond,
        terminalVelocityInScreenHeightFractionPerSecondSettingStepSize);
  }

  static double mapScrollVelocityInScreenWidthsPerSecondToSliderValue(
      double value) {
    return mapValueToOneToTenSliderValueWithDefaultOfFive(
        value,
        defaultScrollVelocityInScreenWidthsPerSecond,
        scrollVelocityInScreenWidthsPerSecondSettingStepSize);
  }

  static double mapSliderValueToScrollVelocityInScreenWidthsPerSecond(
      double value) {
    return mapOneToTenSliderValueWithDefaultOfFiveToSettingValue(
        value,
        defaultScrollVelocityInScreenWidthsPerSecond,
        scrollVelocityInScreenWidthsPerSecondSettingStepSize);
  }

  static double mapCherrySpawnRatePerSecondToSliderValue(double value) {
    return mapValueToOneToTenSliderValueWithDefaultOfFive(
        value,
        defaultCherrySpawnRatePerSecond,
        cherrySpawnRatePerSecondSettingStepSize);
  }

  static double mapSliderValueToCherrySpawnRatePerSecond(double value) {
    return mapOneToTenSliderValueWithDefaultOfFiveToSettingValue(
        value,
        defaultCherrySpawnRatePerSecond,
        cherrySpawnRatePerSecondSettingStepSize);
  }

  static double mapMusicVolumeToSliderValue(double value) {
    return mapValueToOneToTenSliderValueWithDefaultOfFive(
        value, defaultMusicVolume, musicVolumeSettingStepSize);
  }

  static double mapSliderValueToMusicVolume(double value) {
    return mapOneToTenSliderValueWithDefaultOfFiveToSettingValue(
        value, defaultMusicVolume, musicVolumeSettingStepSize);
  }

  static double mapValueToOneToTenSliderValueWithDefaultOfFive(
      double value, double defaultValue, double stepSize) {
    return max(1.0, min(10.0, 5.0 + (value - defaultValue) / stepSize));
  }

  static double mapOneToTenSliderValueWithDefaultOfFiveToSettingValue(
      double value, double defaultValue, double stepSize) {
    return defaultValue + (value - 5.0) * stepSize;
  }
}

class UserModifiableSettings {
  double flapVelocityInScreenHeightFractionPerSecond;
  double terminalVelocityInScreenHeightFractionPerSecond;
  double scrollVelocityInScreenWidthsPerSecond;
  double cherrySpawnRatePerSecond;
  bool playMusic;
  double musicVolume;

  UserModifiableSettings(
      this.flapVelocityInScreenHeightFractionPerSecond,
      this.terminalVelocityInScreenHeightFractionPerSecond,
      this.scrollVelocityInScreenWidthsPerSecond,
      this.cherrySpawnRatePerSecond,
      this.playMusic,
      this.musicVolume);
}
