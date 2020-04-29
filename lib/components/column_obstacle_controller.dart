import 'dart:math';
import 'dart:ui';

import 'horizontally_moving_sprite.dart';

class ColumnObstacleController {
  List<HorizontallyMovingSprite> _obstacles;
  Random _randomNumberGenerator;
  double _velocityInScreenWidthsPerSecond;
  Size _screenSize;
  double _spawnFrequencyHertz = 0.5;
  double _timeSinceLastSpawn = 0.0;
  bool _isInitialized = false;

  String _obstacleImageName;
  Rect _objectRegionForCollision;

  double _obstacleWidthAsScreenWidthFraction;
  double _obstacleHeightAsScreenWidthFraction;

  double _spawnMinHeightAsScreenHeightFraction;
  double _spawnMaxHeightAsScreenHeightFraction;

  ColumnObstacleController(
      double velocityInScreenWidthsPerSecond,
      String targetImageName,
      Rect objectRegionForCollision,
      double obstacleWidthAsScreenWidthFraction,
      double obstacleHeightAsScreenWidthFraction,
      double spawnMinHeightAsScreenHeightFraction,
      double spawnMaxHeightAsScreenHeightFraction) {
    _obstacles = List<HorizontallyMovingSprite>();
    _velocityInScreenWidthsPerSecond = velocityInScreenWidthsPerSecond;
    _obstacleImageName = targetImageName;
    _objectRegionForCollision = objectRegionForCollision;
    _obstacleWidthAsScreenWidthFraction = obstacleWidthAsScreenWidthFraction;
    _obstacleHeightAsScreenWidthFraction = obstacleHeightAsScreenWidthFraction;
    _spawnMinHeightAsScreenHeightFraction =
        spawnMinHeightAsScreenHeightFraction;
    _spawnMaxHeightAsScreenHeightFraction =
        spawnMaxHeightAsScreenHeightFraction;
  }

  bool isCollidingWithObstacle(Rect other) {
    return _obstacles.any((HorizontallyMovingSprite obstacle) =>
        obstacle.isCollidingWithRect(other));
  }

  void render(Canvas canvas) {
    _obstacles.forEach(
        (HorizontallyMovingSprite obstacle) => obstacle.render(canvas));
  }

  void update(double time) {
    if (!_isInitialized) {
      return;
    }

    _obstacles
        .forEach((HorizontallyMovingSprite obstacle) => obstacle.update(time));
    _timeSinceLastSpawn += time;

    if (_timeSinceLastSpawn > 1.0 / _spawnFrequencyHertz) {
      _spawnObstacle();
      _timeSinceLastSpawn = 0.0;
    }
  }

  void _spawnObstacle() {
    double yMinTopPosition =
        _spawnMinHeightAsScreenHeightFraction * _screenSize.height;
    double yMaxTopPosition =
        _spawnMaxHeightAsScreenHeightFraction * _screenSize.height;
    double yRangeTopPosition = yMaxTopPosition - yMinTopPosition;

    double yTopPositionForSpawn = yMinTopPosition +
        _randomNumberGenerator.nextDouble() * yRangeTopPosition;

    double targetHeight = _obstacleHeightAsScreenWidthFraction * _screenSize.width;
    double targetWidth = _obstacleWidthAsScreenWidthFraction * _screenSize.width;

    Rect initialPosition = Rect.fromLTWH(_screenSize.width, yTopPositionForSpawn, targetWidth, targetHeight);
    _obstacles.add(HorizontallyMovingSprite(_obstacleImageName, initialPosition,
        _calculateVelocityInScreenUnitsPerSecond(), _objectRegionForCollision));
  }

  double _calculateVelocityInScreenUnitsPerSecond() {
    // Negative because the targets should move right to left and screen origin
    // is top left.
    return -_velocityInScreenWidthsPerSecond * _screenSize.width;
  }

  void initialize(Size screenSize) {
    _randomNumberGenerator = Random();
    resizeScreen(screenSize);
    _isInitialized = true;
  }

  void resizeScreen(Size size) {
    if (_isInitialized) {
      double scaleX = size.width / _screenSize.width;
      double scaleY = size.height / _screenSize.height;
      _obstacles.forEach((HorizontallyMovingSprite target) =>
          target.applyTransformToPosition(0.0, 0.0, scaleX, scaleY));
      _obstacles.forEach((HorizontallyMovingSprite target) =>
          target.updateHorizontalVelocity(
              _calculateVelocityInScreenUnitsPerSecond()));
    }

    _screenSize = size;
  }
}
