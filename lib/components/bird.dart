import 'dart:math';
import 'dart:ui';

import 'package:flame/sprite.dart';

class Bird {
  static const double _gravityAccelerationInScreenHeightFractionsPerSecond =
      2.0;
  static const double _wingDownTimeWithFlap = 0.15;

  final double _terminalVelocityInScreenHeightFractionPerSecond;
  final double _flapVelocityInScreenHeightFractionPerSecond;

  Rect _position;

  // Sprites to display for bird.
  Sprite _deadSprite;
  Sprite _wingDownSprite;
  Sprite _wingUpSprite;

  Size _screenSize;

  Rect get position => _position;

  double _wingDownRemainingTime = 0.0;

  double _velocity = 0.0;
  double _acceleration = 0.0;
  bool _isDead = false;

  Bird(
      Rect initialPosition,
      Size screenSize,
      double flapVelocityInScreenHeightFractionsPerSecond,
      double terminalVelocityInScreenHeightFractionsPerSecond)
      : _flapVelocityInScreenHeightFractionPerSecond =
            flapVelocityInScreenHeightFractionsPerSecond,
        _terminalVelocityInScreenHeightFractionPerSecond =
            terminalVelocityInScreenHeightFractionsPerSecond {
    _position = initialPosition;
    _screenSize = screenSize;

    _deadSprite = Sprite('birds/bird_dead.png');
    _wingDownSprite = Sprite('birds/bird_wing_down.png');
    _wingUpSprite = Sprite('birds/bird_wing_up.png');
  }



  void render(Canvas canvas) {
    if (_isDead) {
      //_deadSprite.renderRect(canvas, _position); bird looks dead
      return;
    }

    if (_wingDownRemainingTime > 0.0) {
      _wingDownSprite.renderRect(canvas, _position);
    } else {
      _wingUpSprite.renderRect(canvas, _position);
    }
  }

  double _flapVelocityInPixelsPerSecond() {
    // Needs to be negative because flap should cause upward motion and origin
    // is in top left of screen with down and to the right being positive.
    return -_flapVelocityInScreenHeightFractionPerSecond * _screenSize.height;
  }

  double _terminalVelocityInPixelsPerSecond() {
    // Will be positive because origin is in top left corner of screen with down
    // and to the right being positive.
    return _terminalVelocityInScreenHeightFractionPerSecond *
        _screenSize.height;
  }

  double _gravityAccelerationInPixelsPerSecond() {
    return _gravityAccelerationInScreenHeightFractionsPerSecond *
        _screenSize.height;
  }

  void update(double time) {
    _wingDownRemainingTime -= time;
    _applyVelocityUpdate(_acceleration * time);
    _acceleration += _gravityAccelerationInPixelsPerSecond() * time;
    _applyPositionUpdate(_velocity * time);
  }

  bool onTapDown() {
    _velocity = _flapVelocityInPixelsPerSecond();
    _acceleration = 0.0;
    _wingDownRemainingTime = _wingDownTimeWithFlap;
  }

  void _applyVelocityUpdate(double velocityChange) {
    _velocity =
        min(_velocity += velocityChange, _terminalVelocityInPixelsPerSecond());
  }

  void _applyPositionUpdate(double positionChange) {
    // Determine the max translation to not have bird fall off screen.
    double maxTranslation =
        _screenSize.height - _position.height - _position.top;

    // Translation is bounded to keep bird in bounds relative to bottom of
    // screen.
    double yTranslation = min(positionChange, maxTranslation);

    // If translation would take bird off top of screen, move bird only to top
    // of screen and set its velocity to 0.
    if (_position.top + yTranslation < 0.0) {
      yTranslation = -_position.top;
      _velocity = 0.0;
    }

    _position = _position.translate(0, yTranslation);
  }

  void resize(Size screenSize) {
    _screenSize = screenSize;
  }

  bool isOnGround() {
    return _position.top + _position.height >= _screenSize.height;
  }

  void die() {
    _isDead = true;
  }
}
