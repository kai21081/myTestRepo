class GameSettings {
  // Parameters controlling game physics.
  double flapVelocityInScreenHeightFractionPerSecond;
  double terminalVelocityInScreenHeightFractionPerSecond;

  // Parameters controlling cherry targets.
  bool includeCherries;
  double cherrySpawnRatePerSecond;
  double cherryWidthAsScreenWidthFraction;
  double cherryHeightAsScreenWidthFraction;
  double cherryFractionWidthForCollision;
  double cherryFractionHeightForCollision;
  double cherryLocationMinBoundFromScreenTop;
  double cherryLocationMaxBoundFromScreenTop;
  double cherryVelocityInScreenWidthsPerSecond;

  // Parameters controlling column obstacles.
  bool includeColumns;
  double columnSpawnRatePerSecond;
  double columnWidthAsScreenWidthFraction;
  double columnHeightAsScreenWidthFraction;
  double columnHeightMinBoundFromScreenTop;
  double columnHeightMaxBoundFromScreenTop;
  double columnFractionWidthForCollision;
  double columnFractionHeightForCollision;
  double columnVelocityInScreenWidthsPerSecond;

  // Parameters controlling practice mode (i.e., bird doesn't crash).
  bool practiceMode;

  // Parameters controlling music.
  bool playMusic;
  double musicVolume;

  // Parameters controlling the background and its movement.
  double backgroundScrollRateInScreenWidthsPerSecond;
  double skyBackgroundFractionScreenHeight;
  double groundBackgroundFractionScreenHeight;

  // Constructor with default values.
  GameSettings(
      {this.flapVelocityInScreenHeightFractionPerSecond = 0.3,
      this.terminalVelocityInScreenHeightFractionPerSecond = 0.3,
      this.includeCherries = true,
      this.cherrySpawnRatePerSecond = 4,
      this.cherryWidthAsScreenWidthFraction = 0.15,
      this.cherryHeightAsScreenWidthFraction = 0.15,
      this.cherryFractionWidthForCollision = 0.8,
      this.cherryFractionHeightForCollision = 0.8,
      this.cherryLocationMinBoundFromScreenTop = 0.1,
      this.cherryLocationMaxBoundFromScreenTop = 0.6,
      this.cherryVelocityInScreenWidthsPerSecond = 0.5,
      this.includeColumns = true,
      this.columnSpawnRatePerSecond = 3,
      this.columnWidthAsScreenWidthFraction = 0.4,
      this.columnHeightAsScreenWidthFraction = 0.7,
      this.columnFractionWidthForCollision = 0.3,
      this.columnFractionHeightForCollision = 0.9,
      this.columnHeightMinBoundFromScreenTop = 0.6,
      this.columnHeightMaxBoundFromScreenTop = 0.8,
      this.columnVelocityInScreenWidthsPerSecond = 0.5,
      this.practiceMode = false,
      this.playMusic = true,
      this.musicVolume = 0.5,
      this.backgroundScrollRateInScreenWidthsPerSecond = 0.5,
      this.skyBackgroundFractionScreenHeight = 1.0,
      this.groundBackgroundFractionScreenHeight = 0.1});
}
