import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PhotoManager {
  static const String _photoDirName = 'daily_photos';
  static const String _webPhotoPrefix = 'photo_';

  /// Save a photo for the given date
  static Future<String> savePhoto(String date, File imageFile) async {
    if (kIsWeb) {
      final bytes = await imageFile.readAsBytes();
      final base64Str = base64Encode(bytes);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('$_webPhotoPrefix$date', base64Str);
      return '$_webPhotoPrefix$date';
    } else {
      final dir = await _getPhotoDir();
      final fileName = 'photo_$date.jpg';
      final targetPath = '${dir.path}/$fileName';
      await imageFile.copy(targetPath);
      return targetPath;
    }
  }

  /// Save photo from bytes (useful for web)
  static Future<String> savePhotoBytes(String date, List<int> bytes) async {
    if (kIsWeb) {
      final base64Str = base64Encode(bytes);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('$_webPhotoPrefix$date', base64Str);
      return '$_webPhotoPrefix$date';
    } else {
      final dir = await _getPhotoDir();
      final fileName = 'photo_$date.jpg';
      final targetPath = '${dir.path}/$fileName';
      final file = File(targetPath);
      await file.writeAsBytes(bytes);
      return targetPath;
    }
  }

  /// Get photo for a specific date
  static Future<File?> getPhoto(String date) async {
    if (kIsWeb) {
      return null; // Web uses getPhotoBytes instead
    } else {
      final dir = await _getPhotoDir();
      final fileName = 'photo_$date.jpg';
      final file = File('${dir.path}/$fileName');
      if (await file.exists()) {
        return file;
      }
      return null;
    }
  }

  /// Get photo bytes for a specific date (works on all platforms)
  static Future<List<int>?> getPhotoBytes(String date) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      final base64Str = prefs.getString('$_webPhotoPrefix$date');
      if (base64Str != null) {
        return base64Decode(base64Str);
      }
      return null;
    } else {
      final file = await getPhoto(date);
      if (file != null) {
        return await file.readAsBytes();
      }
      return null;
    }
  }

  /// Get all photos sorted by date ascending
  static Future<List<MapEntry<String, File>>> getAllPhotos() async {
    if (kIsWeb) {
      return []; // Web uses getAllPhotoEntries instead
    }
    final dir = await _getPhotoDir();
    if (!await dir.exists()) {
      return [];
    }

    final files = await dir.list().toList();
    final photos = <MapEntry<String, File>>[];

    for (final entity in files) {
      if (entity is File && entity.path.endsWith('.jpg')) {
        final fileName = entity.path.split('/').last.split('\\').last;
        // Extract date from filename: photo_YYYY-MM-DD.jpg
        final dateStr = fileName.replaceFirst('photo_', '').replaceFirst('.jpg', '');
        photos.add(MapEntry(dateStr, entity));
      }
    }

    photos.sort((a, b) => a.key.compareTo(b.key));
    return photos;
  }

  /// Get all photo dates (works on all platforms)
  static Future<List<String>> getAllPhotoDates() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      final dates = <String>[];
      for (final key in keys) {
        if (key.startsWith(_webPhotoPrefix)) {
          dates.add(key.replaceFirst(_webPhotoPrefix, ''));
        }
      }
      dates.sort();
      return dates;
    } else {
      final photos = await getAllPhotos();
      return photos.map((e) => e.key).toList();
    }
  }

  /// Delete photo for a specific date
  static Future<void> deletePhoto(String date) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('$_webPhotoPrefix$date');
    } else {
      final file = await getPhoto(date);
      if (file != null && await file.exists()) {
        await file.delete();
      }
    }
  }

  /// Check if a photo exists for the given date
  static Future<bool> hasPhoto(String date) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      return prefs.containsKey('$_webPhotoPrefix$date');
    } else {
      final file = await getPhoto(date);
      return file != null;
    }
  }

  static Future<Directory> _getPhotoDir() async {
    final appDir = await getApplicationDocumentsDirectory();
    final photoDir = Directory('${appDir.path}/$_photoDirName');
    if (!await photoDir.exists()) {
      await photoDir.create(recursive: true);
    }
    return photoDir;
  }
}
