import 'dart:ui';

import 'package:flame/flame.dart';
import 'package:gameplayground/components/repeating_background.dart';

class RepeatingBackgroundController {
  Size _screenSize;
  Rect _renderRectAsCanvasFraction;
  Rect _renderRectInScreenUnits;

  bool _isInitialized = false;
  bool _isImageLoaded = false;

  String _imageName;
  Image _image;
  double _imageWidth;
  double _imageHeight;

  RepeatingBackground _background;

  double _velocityInFractionRenderRectWidthPerSecond;
  double _velocityInImageWidthsPerSecond;
  double _currentImageStartPointAsFractionImageWidth = 0.0;

  RepeatingBackgroundController(
      String imageName,
      double velocityInFractionRenderRectWidthPerSecond,
      Rect renderRectAsCanvasFraction) {
    _imageName = imageName;
    _background = RepeatingBackground();
    _renderRectAsCanvasFraction = renderRectAsCanvasFraction;
    _velocityInFractionRenderRectWidthPerSecond =
        velocityInFractionRenderRectWidthPerSecond;
  }

  void _calculateVelocityInImageWidthsPerSecond() {
    double imageWidthsPerRenderRect = (_renderRectInScreenUnits.width /
        _renderRectInScreenUnits.height) /
        (_imageWidth / _imageHeight);

    _velocityInImageWidthsPerSecond =
        _velocityInFractionRenderRectWidthPerSecond * imageWidthsPerRenderRect;
  }

  void render(Canvas canvas) {
    if (!_isInitialized || !_isImageLoaded) {
      return;
    }

    _background.render(canvas, _renderRectInScreenUnits,
        _currentImageStartPointAsFractionImageWidth, _image);
  }

  void update(double time) {
    if (!_isInitialized || !_isImageLoaded) {
      return;
    }

    _currentImageStartPointAsFractionImageWidth +=
        time * _velocityInImageWidthsPerSecond;

    if (_currentImageStartPointAsFractionImageWidth > 1.0) {
      _currentImageStartPointAsFractionImageWidth -= 1.0;
    }
  }

  void initialize(Size size) {
    resizeScreen(size);
    Flame.images.load(_imageName).then((image) {
      _imageWidth ??= image.width.toDouble();
      _imageHeight ??= image.height.toDouble();
      _calculateVelocityInImageWidthsPerSecond();
      _image = image;
      _isImageLoaded = true;
    });
    _isInitialized = true;
  }

  void resizeScreen(Size size) {
    _screenSize = size;
    _updateRenderRectInScreenUnits();
  }

  void _updateRenderRectInScreenUnits() {
    _renderRectInScreenUnits = Rect.fromLTRB(
        _renderRectAsCanvasFraction.left * _screenSize.width,
        _renderRectAsCanvasFraction.top * _screenSize.height,
        _renderRectAsCanvasFraction.right * _screenSize.width,
        _renderRectAsCanvasFraction.bottom * _screenSize.height);
  }
}
