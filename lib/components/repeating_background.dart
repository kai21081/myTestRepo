import 'dart:math';
import 'dart:ui';

import 'package:flame/palette.dart';

class RepeatingBackground {
  Paint _paint = BasicPalette.white.paint;

  void render(Canvas canvas, Rect renderRect,
      double startPointAsFractionImageWidth, Image image) {
    double imageHeight = image.height.toDouble();
    double imageWidth = image.width.toDouble();

    // Initial render width in terms of image pixels based on height:width ratio
    // of renderRect.
    double totalImageWidthToRender =
        imageHeight * renderRect.width / renderRect.height;
    double remainingImageWidthToRender = totalImageWidthToRender;

    double imageRenderStartPoint = startPointAsFractionImageWidth * imageWidth;

    // Stores the size of the next render as loop below progressively renders
    // background until screen width is full. For the first iteration, this will
    // be based on the start point in the image. For subsequent iterations, it
    // will be the entire image (but only what fits will be added).
    double imageWidthForNextRender = imageWidth - imageRenderStartPoint;

    double nextStartPointInRenderRectAsFractionWidth = 0.0;

    while (remainingImageWidthToRender > 0.0) {
      // Determine how much of image will fit in remaining space.
      double renderableImageWidth =
          min(imageWidthForNextRender, remainingImageWidthToRender);
      double renderRectWidthFractionForCurrentRendering =
          renderableImageWidth / totalImageWidthToRender;

      Rect targetRect = Rect.fromLTWH(
          renderRect.left +
              nextStartPointInRenderRectAsFractionWidth * renderRect.width,
          renderRect.top,
          renderRectWidthFractionForCurrentRendering * renderRect.width,
          renderRect.height);

      Rect imageSourceRect = Rect.fromLTWH(
          imageRenderStartPoint, 0.0, renderableImageWidth, imageHeight);
      canvas.drawImageRect(image, imageSourceRect, targetRect, _paint);

      // Update loop parameters for next render (if space remains).
      // All remaining renders will start at the beginning of the image and
      // attempt to render full image width.
      imageRenderStartPoint = 0.0;
      imageWidthForNextRender = imageWidth;
      nextStartPointInRenderRectAsFractionWidth +=
          renderRectWidthFractionForCurrentRendering;
      remainingImageWidthToRender -= renderableImageWidth;
    }
  }
}
