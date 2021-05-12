import 'dart:ui';

import 'package:gameplayground/components/bird.dart';
import 'package:gameplayground/models/game_settings.dart';

class BirdController {
  static const double _birdSizeAsFractionScreenWidth = 0.2;
  static const double _birdLeftPositionAsFractionScreenWidth = 0.2;

  final GameSettings _gameSettings;

  Bird _bird;
  bool _isInitialized = false;
  Size _screenSize;
  int _numFlaps;

  int get numFlaps => _numFlaps;

  BirdController(GameSettings gameSettings) : _gameSettings = gameSettings;

  void initialize(Size screenSize) {
    resizeScreen(screenSize);
    double birdSideLength = _birdSizeAsFractionScreenWidth * _screenSize.width;
    Rect initialBirdPosition = Rect.fromLTWH(
        _birdLeftPositionAsFractionScreenWidth * _screenSize.width,
        (_screenSize.height + birdSideLength) / 2.0,
        birdSideLength,
        birdSideLength);
    _bird = Bird(
        initialBirdPosition,
        screenSize,
        _gameSettings.flapVelocityInScreenHeightFractionPerSecond,
        _gameSettings.terminalVelocityInScreenHeightFractionPerSecond);
    _isInitialized = true;
  }

  void render(Canvas canvas) {
    if (_isInitialized) {
      _bird.render(canvas);
    }
  }

  void update(double time) {
    if (_isInitialized) {
      _bird.update(time);
    }
  }

  void onTapDown() {
    if (_isInitialized) {
      _numFlaps++;
      _bird.onTapDown();
    }
  }

  Rect getBirdPosition() {
    return _bird.position;
  }

  void resizeScreen(Size screenSize) {
    _screenSize = screenSize;
  }

  bool isBirdOnGround() {
    if (!_isInitialized) {
      return false;
    }

    return _bird.isOnGround();
  }

  void killBird() {
    _bird.die();
  }
}
