import 'dart:io';

import 'package:path_provider/path_provider.dart';

class Cleartemporary {

  Future<void> clearTemporaryDirectory() async {
    final tempDir = await getTemporaryDirectory();

    if (tempDir.existsSync()) {
      tempDir.listSync().forEach((file) {
        try {
          file.deleteSync();
        } catch (e) {
          print("Error deleting file: $e");
        }
      });
    }
  }

  Future<void> clearCache() async {
    try {
      final cacheDir = await getTemporaryDirectory();
      if (cacheDir.existsSync()) {
        cacheDir.deleteSync(recursive: true);
        print("Cache cleared successfully!");
      } else {
        print("Cache directory does not exist.");
      }
    } catch (e) {
      print("Error clearing cache: $e");
    }
  }

  Future<void> checkFileSystemStorage() async {
    final tempDir = await getTemporaryDirectory();
    final stat = await tempDir.stat();
    print("Temp Directory Size: ${stat.size} bytes");
  }

  Future<void> listCacheFiles() async {
  final cacheDir = await getTemporaryDirectory(); // Get the cache directory
  
  if (cacheDir.existsSync()) {
    List<FileSystemEntity> files = cacheDir.listSync(); // List all files

    if (files.isNotEmpty) {
      print("Files in Cache Directory:");
      for (var file in files) {
        print(file.path); // Print file path
      }
    } else {
      print("Cache is empty.");
    }
  } else {
    print("Cache directory does not exist.");
  }
}
}