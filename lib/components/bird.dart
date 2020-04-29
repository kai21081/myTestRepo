import 'dart:math';
import 'dart:ui';

import 'package:flame/sprite.dart';

class Bird {
  static const double _gravityAccelerationPerSecond = 1000.0;
  static const double _maxDownwardVelocity = 250.0;

  Rect _position;

  Sprite _deadSprite;
  Sprite _wingDownSprite;
  Sprite _wingUpSprite;

  double _wingDownTimeWithFlap = 0.15;

  Size _screenSize;
  double _tileSize;

  Rect get position => _position;

  double _wingDownRemainingTime = 0.0;

  double _velocity = 0.0;
  double _acceleration = 0.0;

  bool _isDead = false;

  Bird(Rect initialPosition, Size screenSize, double tileSize) {
    _position = initialPosition;
    _screenSize = screenSize;
    _tileSize = tileSize;

    _deadSprite = Sprite('birds/bird_dead.png');
    _wingDownSprite = Sprite('birds/bird_wing_down.png');
    _wingUpSprite = Sprite('birds/bird_wing_up.png');
  }

  void render(Canvas canvas) {
    if (_isDead) {
      _deadSprite.renderRect(canvas, _position);
      return;
    }

    if (_wingDownRemainingTime > 0.0) {
      _wingDownSprite.renderRect(canvas, _position);
    } else {
      _wingUpSprite.renderRect(canvas, _position);
    }
  }

  void update(double time) {
    _wingDownRemainingTime -= time;
    _applyVelocityUpdate(_acceleration * time);
    _acceleration += _gravityAccelerationPerSecond * time;
    _applyPositionUpdate(_velocity * time);
  }

  bool onTapDown() {
    _velocity = -250.0;
    _acceleration = 0.0;
    _wingDownRemainingTime = _wingDownTimeWithFlap;
  }


  void _applyVelocityUpdate(double velocityChange) {
    _velocity = min(_velocity += velocityChange, _maxDownwardVelocity);
  }

  void _applyPositionUpdate(double positionChange) {
    double maxTranslation = _screenSize.height - _tileSize - _position.top;
    _position = _position.translate(0, min(positionChange, maxTranslation));
  }

  void resize(Size screenSize, double tileSize) {
    _screenSize = screenSize;
    _tileSize = tileSize;
  }

  bool isOnGround() {
    return _position.top + _position.height >= _screenSize.height;
  }

  void die() {
    _isDead = true;
  }
}
