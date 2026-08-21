import 'package:flutter/material.dart';

abstract final class CatalogGrid {
  static const padding = EdgeInsets.all(16);

  static const _minTileWidth = 180.0;
  static const _spacing = 12.0;

  static const _titleLineHeight = 20.0;
  static const _titleToPriceGap = 6.0;
  static const _priceLineHeight = 24.0;
  static const _cardVerticalPadding = 24.0;

  static int columnsFor(double maxWidth) =>
      (maxWidth / _minTileWidth).floor().clamp(2, 5);

  static SliverGridDelegate delegateFor(BuildContext context, double maxWidth) {
    final columns = columnsFor(maxWidth);
    final tileWidth =
        (maxWidth - padding.horizontal - _spacing * (columns - 1)) / columns;
    final scaler = MediaQuery.textScalerOf(context);
    final captionHeight =
        scaler.scale(_titleLineHeight) * 2 +
        _titleToPriceGap +
        scaler.scale(_priceLineHeight) +
        _cardVerticalPadding;

    return SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: columns,
      crossAxisSpacing: _spacing,
      mainAxisSpacing: _spacing,
      mainAxisExtent: tileWidth + captionHeight,
    );
  }
}
