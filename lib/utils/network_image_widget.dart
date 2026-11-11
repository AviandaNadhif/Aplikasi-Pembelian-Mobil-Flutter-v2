import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

/// Menampilkan gambar (termasuk animasi .gif) dari URL network, Base64, atau Assets.
/// Menangani CORS error & animasi GIF pada Flutter Web.
Widget buildNetworkImage(
  String url, {
  double? width,
  double? height,
  BoxFit fit = BoxFit.cover,
  Widget? errorWidget,
}) {
  final fallback = errorWidget ?? const Icon(Icons.broken_image, color: Colors.grey);
  if (url.trim().isEmpty) return fallback;

  final bool isGif = url.toLowerCase().contains('.gif');

  // 1. Tangani Base64 Image
  if (url.startsWith('data:image') || (!url.startsWith('http') && !url.startsWith('assets/'))) {
    try {
      final cleanBase64 = url.contains(',') ? url.split(',').last : url;
      final bytes = base64Decode(cleanBase64.trim());
      return Image.memory(
        bytes,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (c, e, s) => fallback,
      );
    } catch (_) {
      if (!url.startsWith('http') && !url.startsWith('assets/')) return fallback;
    }
  }

  // 2. Tangani Asset Image
  if (url.startsWith('assets/')) {
    return Image.asset(
      url,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (c, e, s) => fallback,
    );
  }

  // 3. Tangani HTTP/HTTPS Network Image
  String resolvedUrl = url;
  if (kIsWeb) {
    if (url.contains('lh3.googleusercontent.com/a/')) {
      final cleanUrl = url.split('=').first;
      resolvedUrl = 'https://images.weserv.nl/?url=${Uri.encodeComponent(cleanUrl)}';
    } else if (url.contains('drive.google.com') || url.contains('googleusercontent.com/d/')) {
      String fileId = '';
      if (url.contains('/d/')) {
        fileId = url.split('/d/').last.split('?').first.split('/').first;
      } else if (url.contains('id=')) {
        fileId = Uri.parse(url).queryParameters['id'] ?? '';
      }
      if (fileId.isNotEmpty) {
        if (isGif) {
          // Google Drive direct view link + weserv n=-1 agar animasi GIF bergerak
          final directUrl = 'https://drive.google.com/uc?export=view&id=$fileId';
          resolvedUrl = 'https://images.weserv.nl/?url=${Uri.encodeComponent(directUrl)}&n=-1';
        } else {
          final thumbUrl = 'https://drive.google.com/thumbnail?id=$fileId&sz=w800';
          resolvedUrl = 'https://images.weserv.nl/?url=${Uri.encodeComponent(thumbUrl)}';
        }
      }
    } else if (url.startsWith('http') && !url.contains('images.weserv.nl')) {
      final gifFlag = isGif ? '&n=-1' : '';
      resolvedUrl = 'https://images.weserv.nl/?url=${Uri.encodeComponent(url)}$gifFlag';
    }
  }

  return Image.network(
    resolvedUrl,
    width: width,
    height: height,
    fit: fit,
    errorBuilder: (context, error, stackTrace) {
      if (kIsWeb && resolvedUrl != url) {
        return Image.network(
          url,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (c, e, s) => fallback,
        );
      }
      return fallback;
    },
  );
}
