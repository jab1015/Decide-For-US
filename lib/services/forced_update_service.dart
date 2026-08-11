import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

class ForcedUpdateResult {
  const ForcedUpdateResult({
    required this.isRequired,
    required this.currentVersion,
    required this.minimumVersion,
    required this.storeUrl,
    required this.message,
  });

  final bool isRequired;
  final String currentVersion;
  final String minimumVersion;
  final String storeUrl;
  final String message;
}

class ForcedUpdateService {
  static const _collection = 'app_config';
  static const _document = 'version_requirements';
  static const _iosStoreUrl =
      'https://apps.apple.com/us/app/decide-for-us/id6760516571';
  static const _androidStoreUrl =
      'https://play.google.com/store/apps/details?id=com.decideforus.app';

  static Future<ForcedUpdateResult> check() async {
    final packageInfo = await PackageInfo.fromPlatform();
    final currentVersion = packageInfo.version;

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection(_collection)
          .doc(_document)
          .get();
      final data = snapshot.data() ?? <String, dynamic>{};

      final isIos = !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;
      final isAndroid = !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

      if (!isIos && !isAndroid) {
        return ForcedUpdateResult(
          isRequired: false,
          currentVersion: currentVersion,
          minimumVersion: '',
          storeUrl: '',
          message: 'A new version of Decide For Us is required to continue.',
        );
      }

      final minimumVersion = (isIos
                  ? data['ios_min_version']
                  : data['android_min_version'])
              ?.toString()
              .trim() ??
          '';
      final configuredStoreUrl =
          (isIos ? data['ios_store_url'] : data['android_store_url'])
                  ?.toString()
                  .trim() ??
              '';
      final storeUrl = configuredStoreUrl.isNotEmpty
          ? configuredStoreUrl
          : (isIos ? _iosStoreUrl : _androidStoreUrl);
      final message = data['message']?.toString().trim().isNotEmpty == true
          ? data['message'].toString().trim()
          : 'A new version of Decide For Us is required to continue.';

      if (minimumVersion.isEmpty) {
        return ForcedUpdateResult(
          isRequired: false,
          currentVersion: currentVersion,
          minimumVersion: minimumVersion,
          storeUrl: storeUrl,
          message: message,
        );
      }

      return ForcedUpdateResult(
        isRequired: _compareVersions(currentVersion, minimumVersion) < 0,
        currentVersion: currentVersion,
        minimumVersion: minimumVersion,
        storeUrl: storeUrl,
        message: message,
      );
    } catch (_) {
      // Fail open if the remote config cannot be reached so an outage does not
      // permanently lock every user out of the app.
      return ForcedUpdateResult(
        isRequired: false,
        currentVersion: currentVersion,
        minimumVersion: '',
        storeUrl: '',
        message: 'A new version of Decide For Us is required to continue.',
      );
    }
  }

  static int _compareVersions(String left, String right) {
    final leftParts = _normalize(left);
    final rightParts = _normalize(right);
    final maxLength =
        leftParts.length > rightParts.length ? leftParts.length : rightParts.length;

    for (var i = 0; i < maxLength; i++) {
      final l = i < leftParts.length ? leftParts[i] : 0;
      final r = i < rightParts.length ? rightParts[i] : 0;
      if (l != r) return l.compareTo(r);
    }
    return 0;
  }

  static List<int> _normalize(String version) {
    final clean = version.split('+').first.trim();
    return clean
        .split('.')
        .map((part) => int.tryParse(part.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0)
        .toList();
  }
}
