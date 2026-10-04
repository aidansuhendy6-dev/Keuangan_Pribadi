import 'dart:typed_data';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

class ExportService {
  static Future<bool> saveImage(Uint8List bytes, String fileName) async {
    try {
      final blob = html.Blob([bytes], 'image/jpeg');
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: url)
        ..setAttribute("download", "$fileName.jpg")
        ..click();
      html.Url.revokeObjectUrl(url);
      return true;
    } catch (e) {
      return false;
    }
  }
}
