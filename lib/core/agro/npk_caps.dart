import 'package:bio_g/core/agro/agro_types.dart';

class NpkCaps {
  const NpkCaps._();

  static String _normalizeCropKey(String? cropKey) =>
      (cropKey ?? '').trim().toLowerCase();

  static double forCropMetric({
    required String? cropKey,
    required AgroMetricKey metricKey,
  }) {
    final normalizedCropKey = _normalizeCropKey(cropKey);

    switch (metricKey) {
      case AgroMetricKey.n:
        switch (normalizedCropKey) {
          case 'bean':
            return 80.0;
          case 'barley':
            return 100.0;
          default:
            return 120.0;
        }
      case AgroMetricKey.p:
        return 80.0;
      case AgroMetricKey.k:
        return 140.0;
      default:
        return 100.0;
    }
  }
}
