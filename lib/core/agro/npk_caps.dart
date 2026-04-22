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
          // Tomate demanda alta pero es sensible a exceso vegetativo.
          // Cap ligeramente más alto para no clasificar como "exceso" una
          // lectura que en hortaliza sigue siendo operativa.
          case 'tomato':
          case 'tomate':
          case 'jitomate':
            return 130.0;
          case 'cucumber':
          case 'pepino':
            return 130.0;
          default:
            return 120.0;
        }
      case AgroMetricKey.p:
        switch (normalizedCropKey) {
          // Tomate requiere P starter alto en establecimiento (anclaje
          // de trasplante) y sostenido hasta cuajado.
          case 'tomato':
          case 'tomate':
          case 'jitomate':
            return 90.0;
          case 'cucumber':
          case 'pepino':
            return 90.0;
          default:
            return 80.0;
        }
      case AgroMetricKey.k:
        switch (normalizedCropKey) {
          // Tomate tolera y responde a K muy alto (Brix, firmeza, color).
          // Lecturas de 200+ mg/kg son productivas, no tóxicas.
          case 'tomato':
          case 'tomate':
          case 'jitomate':
            return 200.0;
          case 'cucumber':
          case 'pepino':
            return 210.0;
          default:
            return 140.0;
        }
      default:
        return 100.0;
    }
  }
}
