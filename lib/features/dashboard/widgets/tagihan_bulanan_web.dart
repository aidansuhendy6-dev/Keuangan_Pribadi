// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
// ignore: unnecessary_import
import 'dart:ui_web' as ui_web;
import 'package:flutter/widgets.dart';

bool _isViewRegistered = false;

Widget buildWebView(ValueNotifier<double> heightNotifier) {
  const String viewType = 'tagihan-bulanan-iframe-view';

  // Listen to postMessage from the iframe for dynamic height adjustment
  html.window.onMessage.listen((event) {
    try {
      final data = event.data;
      if (data is Map) {
        if (data.containsKey('height')) {
          final double h = double.tryParse(data['height'].toString()) ?? 0;
          if (h > 100) {
            heightNotifier.value = h;
          }
        }
      } else if (data is String) {
        if (data.startsWith('height:')) {
          final double h = double.tryParse(data.substring(7)) ?? 0;
          if (h > 100) {
            heightNotifier.value = h;
          }
        }
      }
    } catch (_) {}
  });

  if (!_isViewRegistered) {
    ui_web.platformViewRegistry.registerViewFactory(
      viewType,
      (int id) => html.IFrameElement()
        ..src = 'https://tagihan-bulanan-seven.vercel.app'
        ..style.border = 'none'
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.overflow = 'auto',
    );
    _isViewRegistered = true;
  }

  return const HtmlElementView(viewType: viewType);
}
