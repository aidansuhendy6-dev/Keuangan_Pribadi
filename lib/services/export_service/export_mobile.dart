import 'dart:typed_data';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:permission_handler/permission_handler.dart';

class ExportService {
  static Future<bool> saveImage(Uint8List bytes, String fileName) async {
    if (await Permission.storage.request().isGranted || await Permission.photos.request().isGranted) {
      final result = await ImageGallerySaver.saveImage(
        bytes,
        quality: 100,
        name: fileName,
      );
      return result['isSuccess'] ?? false;
    }
    return false;
  }
}
