import 'dart:io';
import 'package:path_provider/path_provider.dart';

class LocalStorageService {
  Future<String> get _localPath async {
    final dir = await getApplicationDocumentsDirectory();
    final measurementsDir = Directory('${dir.path}/scalegrab_measurements');
    if (!await measurementsDir.exists()) {
      await measurementsDir.create(recursive: true);
    }
    return measurementsDir.path;
  }

  Future<String> saveImage(String measurementId, String filename, File sourceFile) async {
    final basePath = await _localPath;
    final measureDir = Directory('$basePath/$measurementId');
    if (!await measureDir.exists()) {
      await measureDir.create(recursive: true);
    }
    final destPath = '${measureDir.path}/$filename';
    await sourceFile.copy(destPath);
    return destPath;
  }

  Future<String> saveBytes(String measurementId, String filename, List<int> bytes) async {
    final basePath = await _localPath;
    final measureDir = Directory('$basePath/$measurementId');
    if (!await measureDir.exists()) {
      await measureDir.create(recursive: true);
    }
    final destPath = '${measureDir.path}/$filename';
    await File(destPath).writeAsBytes(bytes);
    return destPath;
  }

  Future<void> deleteFolder(String measurementId) async {
    final basePath = await _localPath;
    final measureDir = Directory('$basePath/$measurementId');
    if (await measureDir.exists()) {
      await measureDir.delete(recursive: true);
    }
  }

  bool fileExists(String path) {
    return File(path).existsSync();
  }
}
