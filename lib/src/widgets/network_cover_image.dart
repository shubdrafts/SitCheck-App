import 'package:flutter/material.dart';

class NetworkCoverImage extends StatelessWidget {
  const NetworkCoverImage({
    super.key,
    required this.imageUrl,
    this.borderRadius,
    this.aspectRatio,
    this.fit = BoxFit.cover,
  });

  final String imageUrl;
  final BorderRadiusGeometry? borderRadius;
  final double? aspectRatio;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    Widget image = Image.network(
      imageUrl,
      fit: fit,
      width: double.infinity,
      height: double.infinity,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return _Placeholder(fit: fit);
      },
      errorBuilder: (context, error, stackTrace) => _Placeholder(fit: fit),
    );

    if (borderRadius != null) {
      image = ClipRRect(
        borderRadius: borderRadius!,
        child: image,
      );
    }

    if (aspectRatio != null) {
      image = AspectRatio(
        aspectRatio: aspectRatio!,
        child: image,
      );
    }

    return image;
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder({required this.fit});

  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey[200],
      alignment: Alignment.center,
      child: Icon(
        Icons.broken_image_outlined,
        color: Colors.grey[500],
      ),
    );
  }
}

