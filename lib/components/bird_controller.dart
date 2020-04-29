import 'dart:ui';

import 'package:gameplayground/components/bird.dart';

class BirdController {
  Bird _bird;
  bool _isInitialized = false;
  Size _screenSize;
  double _tileSize;

  void initialize(Size screenSize, double tileSize) {
    resizeScreen(screenSize, tileSize);
    Rect initialBirdPosition = Rect.fromLTWH(_tileSize,
        (_screenSize.height + _tileSize) / 2.0, 2 * _tileSize, 2 * _tileSize);
    _bird = Bird(initialBirdPosition, screenSize, tileSize);
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
      _bird.onTapDown();
    }
  }

  Rect getBirdPosition() {
    return _bird.position;
  }

  void resizeScreen(Size screenSize, double tileSize) {
    _screenSize = screenSize;
    _tileSize = tileSize;
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
