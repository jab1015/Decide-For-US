import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

enum AgeSignalsStatus {
  shared,
  notShared,
  verificationRequired,
  unsupported,
  unavailable,
}

class AgeSignalsResult {
  const AgeSignalsResult({
    required this.status,
    this.ageLower,
    this.ageUpper,
  });

  final AgeSignalsStatus status;
  final int? ageLower;
  final int? ageUpper;
}

class AgeSignalsService {
  static const _channel = MethodChannel('com.decideforus.app/age_signals');

  /// Checks Google Play's current signal without storing or logging the result.
  static Future<AgeSignalsResult> check() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return const AgeSignalsResult(status: AgeSignalsStatus.unsupported);
    }

    try {
      final response = await _channel.invokeMapMethod<String, dynamic>(
        'checkAgeSignals',
      );
      final status = switch (response?['status']) {
        'shared' => AgeSignalsStatus.shared,
        'notShared' => AgeSignalsStatus.notShared,
        'verificationRequired' => AgeSignalsStatus.verificationRequired,
        'unsupported' => AgeSignalsStatus.unsupported,
        _ => AgeSignalsStatus.unavailable,
      };

      return AgeSignalsResult(
        status: status,
        ageLower: response?['ageLower'] as int?,
        ageUpper: response?['ageUpper'] as int?,
      );
    } on PlatformException {
      return const AgeSignalsResult(status: AgeSignalsStatus.unavailable);
    }
  }
}
