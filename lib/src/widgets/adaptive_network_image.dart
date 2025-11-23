import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class AdaptiveNetworkImage extends StatelessWidget {
  const AdaptiveNetworkImage({
    super.key,
    required this.imageUrl,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.width,
    this.height,
  });

  final String imageUrl;
  final BoxFit fit;
  final BorderRadiusGeometry? borderRadius;
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    Widget child = Image.network(
      imageUrl,
      fit: fit,
      width: width,
      height: height,
      loadingBuilder: (context, widget, progress) {
        if (progress == null) return widget;
        return _Placeholder(height: height, width: width, showSpinner: true);
      },
      errorBuilder: (_, __, ___) =>
          _Placeholder(height: height, width: width, showSpinner: false),
    );

    if (borderRadius != null) {
      child = ClipRRect(
        borderRadius: borderRadius!,
        child: child,
      );
    }

    return child;
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder({
    this.height,
    this.width,
    required this.showSpinner,
  });

  final double? height;
  final double? width;
  final bool showSpinner;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      color: AppColors.beige,
      child: Center(
        child: showSpinner
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              )
            : const Icon(Icons.image_not_supported, color: Colors.black38),
      ),
    );
  }
}

