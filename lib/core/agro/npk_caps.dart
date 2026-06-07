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
          case 'chili':
          case 'chile':
          case 'pepper':
          case 'pimiento':
            return 130.0;
          case 'eggplant':
          case 'berenjena':
          case 'aubergine':
            return 130.0;
          // Calabaza: PDF Guia v1 sugiere 84-112 kg/ha N base para
          // calabacita y 56-112 kg/ha para fruto maduro. El cap operativo
          // (lectura de mg/kg que NO se considera "exceso") queda
          // moderado a 120 mg/kg para no clasificar lecturas funcionales
          // como exceso. CA-07/pipian comparte cap.
          case 'squash':
          case 'calabaza':
          case 'pumpkin':
            return 120.0;
          // Lechuga: hortaliza de hoja de ciclo corto y raiz superficial.
          // Demanda foliar moderada; cap operativo de 110 mg/kg evita
          // clasificar como exceso una lectura funcional de N en E3.
          case 'lettuce':
          case 'lechuga':
            return 110.0;
          case 'spinach':
          case 'crop_spinach':
          case 'espinaca':
            return 120.0;
          // Cebolla: hortaliza de bulbo con demanda alta de N temprano,
          // pero peligrosa tarde. Cap operativo de 130 mg/kg cubre la
          // demanda vegetativa sin marcar como exceso una lectura util.
          case 'onion':
          case 'crop_onion':
          case 'cebolla':
          case 'garlic':
          case 'crop_garlic':
          case 'ajo':
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
          case 'chili':
          case 'chile':
          case 'pepper':
          case 'pimiento':
            return 90.0;
          case 'eggplant':
          case 'berenjena':
          case 'aubergine':
            return 90.0;
          case 'squash':
          case 'calabaza':
          case 'pumpkin':
            return 90.0;
          // Lechuga: P pesa en establecimiento (raiz superficial joven).
          case 'lettuce':
          case 'lechuga':
            return 85.0;
          case 'spinach':
          case 'crop_spinach':
          case 'espinaca':
            return 90.0;
          // Cebolla: P pesa en arranque/raiz superficial y suelos frios o
          // alcalinos. Cap operativo de 90 mg/kg.
          case 'onion':
          case 'crop_onion':
          case 'cebolla':
          case 'garlic':
          case 'crop_garlic':
          case 'ajo':
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
          case 'chili':
          case 'chile':
          case 'pepper':
          case 'pimiento':
            return 220.0;
          case 'eggplant':
          case 'berenjena':
          case 'aubergine':
            return 220.0;
          // Calabaza demanda K alto desde cuajado hasta llenado/cosecha;
          // 220 mg/kg como cap operativo evita clasificar como exceso una
          // lectura productiva. Pipian/pepita comparte cap.
          case 'squash':
          case 'calabaza':
          case 'pumpkin':
            return 220.0;
          // Lechuga: K apoya turgencia y calidad de cabeza/hoja; cap
          // operativo de 180 mg/kg cubre la demanda sin marcar exceso.
          case 'lettuce':
          case 'lechuga':
            return 180.0;
          case 'spinach':
          case 'crop_spinach':
          case 'espinaca':
            return 190.0;
          // Cebolla: K es el nutriente del bulbo (agua, turgencia, calibre,
          // firmeza y calidad). Cap operativo de 200 mg/kg cubre la demanda
          // de llenado sin marcar como exceso una lectura productiva.
          case 'onion':
          case 'crop_onion':
          case 'cebolla':
            return 200.0;
          // Ajo: K pesa en diferenciacion, llenado, firmeza y calidad de bulbo.
          case 'garlic':
          case 'crop_garlic':
          case 'ajo':
            return 210.0;
          default:
            return 140.0;
        }
      default:
        return 100.0;
    }
  }
}
