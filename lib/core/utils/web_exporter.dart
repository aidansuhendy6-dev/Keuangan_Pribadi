import 'dart:convert';
import 'dart:typed_data';
import 'dart:html' as html;

void downloadImage(String filename, Uint8List bytes) {
  final blob = html.Blob([bytes], 'image/jpeg');
  final url = html.Url.createObjectUrlFromBlob(blob);
  html.AnchorElement(href: url)
    ..setAttribute('download', filename)
    ..click();
  html.Url.revokeObjectUrl(url);
}
