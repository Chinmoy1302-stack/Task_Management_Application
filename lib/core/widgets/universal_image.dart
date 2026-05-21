import 'dart:io';
import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

enum ImageType { network, asset, file, memory, svg }

class UniversalImage extends StatelessWidget {
  final String path;
  final ImageType imageType;
  final BoxFit fit;
  final double? width;
  final double? height;
  final Color? color;
  final BlendMode? blendMode;
  final Widget? placeholder;
  final Widget? errorWidget;
  final Uint8List? memoryData; // For ImageType.memory

  const UniversalImage({
    super.key,
    required this.path,
    required this.imageType,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.color,
    this.blendMode,
    this.placeholder,
    this.errorWidget,
    this.memoryData,
  });

  factory UniversalImage.network(
    String url, {
    BoxFit fit = BoxFit.cover,
    double? width,
    double? height,
    Color? color,
    BlendMode? blendMode,
    Widget? placeholder,
    Widget? errorWidget,
  }) {
    return UniversalImage(
      path: url,
      imageType: ImageType.network,
      fit: fit,
      width: width,
      height: height,
      color: color,
      blendMode: blendMode,
      placeholder: placeholder,
      errorWidget: errorWidget,
    );
  }

  factory UniversalImage.asset(
    String path, {
    BoxFit fit = BoxFit.cover,
    double? width,
    double? height,
    Color? color,
    BlendMode? blendMode,
  }) {
    return UniversalImage(
      path: path,
      imageType: ImageType.asset,
      fit: fit,
      width: width,
      height: height,
      color: color,
      blendMode: blendMode,
    );
  }

  factory UniversalImage.file(
    String path, {
    BoxFit fit = BoxFit.cover,
    double? width,
    double? height,
    Color? color,
    BlendMode? blendMode,
  }) {
    return UniversalImage(
      path: path,
      imageType: ImageType.file,
      fit: fit,
      width: width,
      height: height,
      color: color,
      blendMode: blendMode,
    );
  }

  factory UniversalImage.svg(
    String path, {
    BoxFit fit = BoxFit.contain,
    double? width,
    double? height,
    Color? color,
    BlendMode? blendMode,
  }) {
    return UniversalImage(
      path: path,
      imageType: ImageType.svg,
      fit: fit,
      width: width,
      height: height,
      color: color,
      blendMode: blendMode,
    );
  }

  factory UniversalImage.memory(
    Uint8List data, {
    BoxFit fit = BoxFit.cover,
    double? width,
    double? height,
    Color? color,
    BlendMode? blendMode,
  }) {
    return UniversalImage(
      path: '', // Not used for memory
      memoryData: data,
      imageType: ImageType.memory,
      fit: fit,
      width: width,
      height: height,
      color: color,
      blendMode: blendMode,
    );
  }

  @override
  Widget build(BuildContext context) {
    switch (imageType) {
      case ImageType.network:
        return CachedNetworkImage(
          imageUrl: path,
          fit: fit,
          width: width,
          height: height,
          color: color,
          colorBlendMode: blendMode,
          placeholder: (context, url) =>
              placeholder ??
              Container(
                width: width,
                height: height,
                color: Colors.grey.shade200,
                child: const Center(child: CircularProgressIndicator()),
              ),
          errorWidget: (context, url, error) =>
              errorWidget ??
              Container(
                width: width,
                height: height,
                color: Colors.grey.shade200,
                child: const Icon(Icons.error),
              ),
        );

      case ImageType.asset:
        return Image.asset(
          path,
          fit: fit,
          width: width,
          height: height,
          color: color,
          colorBlendMode: blendMode,
          errorBuilder: (context, error, stackTrace) =>
              errorWidget ?? const Icon(Icons.error),
        );

      case ImageType.file:
        return Image.file(
          File(path),
          fit: fit,
          width: width,
          height: height,
          color: color,
          colorBlendMode: blendMode,
          errorBuilder: (context, error, stackTrace) =>
              errorWidget ?? const Icon(Icons.error),
        );

      case ImageType.svg:
        return SvgPicture.asset(
          path,
          fit: fit,
          width: width,
          height: height,
          colorFilter: color != null
              ? ColorFilter.mode(color!, blendMode ?? BlendMode.srcIn)
              : null,
          placeholderBuilder: (BuildContext context) =>
              placeholder ??
              Container(
                width: width,
                height: height,
                color: Colors.transparent,
              ),
        );

      case ImageType.memory:
        if (memoryData == null) {
          return errorWidget ?? const Icon(Icons.error);
        }
        return Image.memory(
          memoryData!,
          fit: fit,
          width: width,
          height: height,
          color: color,
          colorBlendMode: blendMode,
          errorBuilder: (context, error, stackTrace) =>
              errorWidget ?? const Icon(Icons.error),
        );
    }
  }
}
