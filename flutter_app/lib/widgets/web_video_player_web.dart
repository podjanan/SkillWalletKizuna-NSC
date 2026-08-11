// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;
import 'package:flutter/material.dart';

Widget buildWebVideoPlayer(String videoUrl) {
  final viewId =
      'video-view-${videoUrl.hashCode}-${DateTime.now().millisecondsSinceEpoch}';
  // ignore: undefined_prefixed_name
  ui_web.platformViewRegistry.registerViewFactory(
    viewId,
    (int id) {
      final video = html.VideoElement()
        ..src = videoUrl
        ..controls = true
        ..autoplay = true
        ..setAttribute('playsinline', 'true')
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.objectFit = 'contain'
        ..style.background = 'black';
      return video;
    },
  );
  return HtmlElementView(viewType: viewId);
}
