import 'dart:ui';

import 'package:flame/sprite.dart';

class HorizontallyMovingSprite {
  Rect _position;
  Sprite _sprite;
  double _horizontalVelocity;
  Rect _spriteRegionForCollision;

  HorizontallyMovingSprite(String imageName, Rect initialPosition,
      double horizontalVelocity, Rect spriteRegionForCollision) {
    _position = initialPosition;
    _horizontalVelocity = horizontalVelocity;
    _sprite = Sprite(imageName);
    _spriteRegionForCollision = spriteRegionForCollision;
  }

  void render(Canvas canvas) {
    _sprite.renderRect(canvas, _position);
  }

  void update(double time) {
    _position = _position.translate(_horizontalVelocity * time, 0);
  }

  bool isCollidingWithRect(Rect other) {
    Rect collisionRect = Rect.fromLTWH(
        _position.left + _spriteRegionForCollision.left * _position.width,
        _position.top + _spriteRegionForCollision.top * _position.height,
        _position.width * _spriteRegionForCollision.width,
        _position.height * _spriteRegionForCollision.height);
    return collisionRect.overlaps(other);
  }

  void applyTransformToPosition(
      double offsetX, double offsetY, double scaleX, double scaleY) {
    _position = Rect.fromLTWH(
        _position.left * scaleX + offsetX,
        _position.top * scaleY + offsetY,
        _position.width * scaleX,
        _position.height * scaleY);
  }

  void updateHorizontalVelocity(double velocity) {
    _horizontalVelocity = velocity;
  }
}
