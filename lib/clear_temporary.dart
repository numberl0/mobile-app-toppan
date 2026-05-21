import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:toppan_app/app_logger.dart';

class Cleartemporary {

  Future<void> clearTemporaryDirectory() async {
    final tempDir = await getTemporaryDirectory();

    if (tempDir.existsSync()) {
      tempDir.listSync().forEach((file) {
        try {
          file.deleteSync();
        } catch (err, stack) {
          AppLogger.error('Error: $err\n$stack');
        }
      });
    }
  }

  Future<void> clearCache() async {
    try {
      final cacheDir = await getTemporaryDirectory();
      if (cacheDir.existsSync()) {
        cacheDir.deleteSync(recursive: true);
        AppLogger.debug("Cache cleared successfully!");
      } else {
        AppLogger.debug("Cache directory does not exist.");
      }
    } catch (err, stack) {
      AppLogger.error('Error: $err\n$stack');
    }
  }

  Future<void> checkFileSystemStorage() async {
    final tempDir = await getTemporaryDirectory();
    final stat = await tempDir.stat();
    AppLogger.debug("Temp Directory Size: ${stat.size} bytes");
  }

  Future<void> listCacheFiles() async {
  final cacheDir = await getTemporaryDirectory(); // Get the cache directory
  
  if (cacheDir.existsSync()) {
    List<FileSystemEntity> files = cacheDir.listSync(); // List all files

    if (files.isNotEmpty) {
      AppLogger.debug("Files in Cache Directory:");
      for (var file in files) {
        AppLogger.debug(file.path);
      }
    } else {
      AppLogger.debug("Cache is empty.");
    }
  } else {
     AppLogger.debug("Cache directory does not exist.");
  }
}
}