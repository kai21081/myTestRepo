import 'dart:math';
import 'dart:ui';

import 'package:gameplayground/components/horizontally_moving_sprite.dart';

class TargetController {
  List<HorizontallyMovingSprite> _targets;
  Random _randomNumberGenerator;
  double _velocityInScreenWidthsPerSecond;
  Size _screenSize;
  double _spawnFrequencyHertz = 100;
  double _timeSinceLastSpawn = 0.0;
  bool _isInitialized = false;

  String _targetImageName;
  Rect _targetRegionForCollision;

  double _targetWidthAsScreenWidthFraction;
  double _targetHeightAsScreenWidthFraction;

  double _spawnMinHeightAsScreenHeightFraction;
  double _spawnMaxHeightAsScreenHeightFraction;

  TargetController(
      double velocityInScreenWidthsPerSecond,
      String targetImageName,
      Rect targetRegionForCollision,
      double targetWidthAsScreenWidthFraction,
      double targetHeightAsScreenWidthFraction,
      double spawnMinHeightAsScreenHeightFraction,
      double spawnMaxHeightAsScreenHeightFraction,
      double spawnFrequencyHertz) {
    _targets = List<HorizontallyMovingSprite>();
    _velocityInScreenWidthsPerSecond = velocityInScreenWidthsPerSecond;
    _targetImageName = targetImageName;
    _targetRegionForCollision = targetRegionForCollision;
    _targetWidthAsScreenWidthFraction = targetWidthAsScreenWidthFraction;
    _targetHeightAsScreenWidthFraction = targetHeightAsScreenWidthFraction;
    _spawnMinHeightAsScreenHeightFraction =
        spawnMinHeightAsScreenHeightFraction;
    _spawnMaxHeightAsScreenHeightFraction =
        spawnMaxHeightAsScreenHeightFraction;
    _spawnFrequencyHertz = spawnFrequencyHertz;
  }

  // Removes targets with collision and returns collision count (i.e. points
  // scored).
  int removeTargetsWithCollisionAndCalculateCount(Rect birdPosition) {
    int preCollisionTargetCount = _targets.length;
    _targets.removeWhere((HorizontallyMovingSprite target) =>
        target.isCollidingWithRect(birdPosition));
    int postCollisionTargetCount = _targets.length;

    return preCollisionTargetCount - postCollisionTargetCount;
  }

  void render(Canvas canvas) {
    _targets
        .forEach((HorizontallyMovingSprite target) => target.render(canvas));
  }

  void update(double time) {
    if (!_isInitialized) {
      return;
    }

    _targets.forEach((HorizontallyMovingSprite target) => target.update(time));
    _timeSinceLastSpawn += time;

    if (_timeSinceLastSpawn > 1.0 / _spawnFrequencyHertz) {
      _spawnTarget();
      _timeSinceLastSpawn = 0.0;
    }
  }

  void _spawnTarget() {
    double targetHeight =
        _targetHeightAsScreenWidthFraction * _screenSize.width;
    double targetWidth = _targetWidthAsScreenWidthFraction * _screenSize.width;

    // Screen position calculated from top left corner.
    double yMinTopPosition =
        _spawnMinHeightAsScreenHeightFraction * _screenSize.height;
    double yMaxTopPosition =
        _spawnMaxHeightAsScreenHeightFraction * _screenSize.height -
            targetHeight;
    double yTopPositionRange = yMaxTopPosition - yMinTopPosition;

    double yTopPositionForSpawn = yMinTopPosition +
        _randomNumberGenerator.nextDouble() * yTopPositionRange;

    Rect initialPosition = Rect.fromLTWH(
        _screenSize.width, yTopPositionForSpawn, targetWidth, targetHeight);
    _targets.add(HorizontallyMovingSprite(_targetImageName, initialPosition,
        _calculateVelocityInScreenUnitsPerSecond(), _targetRegionForCollision));
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
      _targets.forEach((HorizontallyMovingSprite target) =>
          target.applyTransformToPosition(0.0, 0.0, scaleX, scaleY));
      _targets.forEach((HorizontallyMovingSprite target) =>
          target.updateHorizontalVelocity(
              _calculateVelocityInScreenUnitsPerSecond()));
    }

    _screenSize = size;
  }
}
