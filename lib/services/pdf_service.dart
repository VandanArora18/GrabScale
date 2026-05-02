import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class PdfService {
  Future<File> savePdfFromBase64(String base64Pdf, String filename) async {
    final bytes = base64Decode(base64Pdf);
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$filename');
    await file.writeAsBytes(bytes);
    return file;
  }

  Future<Uint8List> decodeBase64(String base64Str) async {
    return base64Decode(base64Str);
  }

  Future<void> sharePdf(String filePath, {String? text}) async {
    await Share.shareXFiles([XFile(filePath)], text: text ?? 'My ScaleGrab Measurement');
  }

  Future<File> saveImageFromBase64(String base64Img, String filename) async {
    final bytes = base64Decode(base64Img);
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$filename');
    await file.writeAsBytes(bytes);
    return file;
  }
}
