import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';

class UpdateInfo {
  final String version;
  final String changelog;
  final String downloadUrl;

  UpdateInfo({
    required this.version,
    required this.changelog,
    required this.downloadUrl,
  });
}

class AppConfig {
  /// URL to fetch version.json from.
  /// Set to empty string to disable update checking.
  /// When the repo is public, use:
  /// 'https://raw.githubusercontent.com/guangyuwei853-maker/daily-goal-app/main/version.json'
  static const String updateCheckUrl = '';

  static const String currentVersion = '1.1.0';
  static const int currentBuildNumber = 2;
}

class UpdateService {
  /// Check for available updates.
  /// Returns [UpdateInfo] if a newer version is available, null otherwise.
  /// Returns null silently on any error (no internet, bad response, etc.)
  Future<UpdateInfo?> checkForUpdate({String? overrideUrl}) async {
    // Skip on web platform
    if (kIsWeb) return null;

    final url = overrideUrl ?? AppConfig.updateCheckUrl;
    if (url.isEmpty) return null;

    try {
      final response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) return null;

      final data = json.decode(response.body) as Map<String, dynamic>;
      final remoteVersion = data['version'] as String? ?? '';
      final changelog = data['changelog'] as String? ?? '';
      final downloadUrl = data['downloadUrl'] as String? ?? '';
      final remoteBuildNumber = data['buildNumber'] as int? ?? 0;

      if (remoteVersion.isEmpty || downloadUrl.isEmpty) return null;

      // Compare versions
      if (_isNewerVersion(remoteVersion, remoteBuildNumber)) {
        return UpdateInfo(
          version: remoteVersion,
          changelog: changelog,
          downloadUrl: downloadUrl,
        );
      }

      return null;
    } catch (e) {
      // Silently fail - no update check is not critical
      debugPrint('Update check failed: $e');
      return null;
    }
  }

  /// Compare remote version with current app version.
  /// Returns true if remote is newer.
  bool _isNewerVersion(String remoteVersion, int remoteBuildNumber) {
    try {
      final remote = _parseVersion(remoteVersion);
      final current = _parseVersion(AppConfig.currentVersion);

      for (int i = 0; i < 3; i++) {
        if (remote[i] > current[i]) return true;
        if (remote[i] < current[i]) return false;
      }

      // Same version string, compare build numbers
      return remoteBuildNumber > AppConfig.currentBuildNumber;
    } catch (e) {
      return false;
    }
  }

  /// Parse version string like "1.2.3" or "v1.2.3" into [major, minor, patch]
  List<int> _parseVersion(String version) {
    // Remove leading 'v' if present
    final cleaned = version.startsWith('v') ? version.substring(1) : version;
    final parts = cleaned.split('.');
    return [
      int.tryParse(parts.elementAtOrNull(0) ?? '0') ?? 0,
      int.tryParse(parts.elementAtOrNull(1) ?? '0') ?? 0,
      int.tryParse(parts.elementAtOrNull(2) ?? '0') ?? 0,
    ];
  }
}
