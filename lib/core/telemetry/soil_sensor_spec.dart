// lib/core/telemetry/soil_sensor_spec.dart
//
// CONTRATO DEL SENSOR DE SUELO (Guía oficial del nuevo motor nutricional
// v0.4, §3 «Sensor contract», §24–§26 y fase 3).
//
// Un solo lugar que declara, por sonda:
//   · qué canales entrega y en qué unidad cruda (registro Modbus);
//   · cómo se convierte cada canal a la unidad interna de la app, UNA sola vez
//     y en la frontera (BLE/HTTP), nunca en pantalla;
//   · qué rango es físicamente plausible: fuera de él la lectura es «dato
//     ausente», nunca un cero ni un valor a interpretar;
//   · qué canales son DERIVADOS de otro (en la 7-en-1, N/P/K salen de la CE) y
//     por tanto no cuentan como evidencia independiente;
//   · cuánto calentamiento pide la electrónica y si la CE viene compensada por
//     temperatura.
//
// SOBRE LA SONDA DE REFERENCIA
// ----------------------------
// SN-3002-TR-ECTHNPKPH-N01: sonda RS485 «7 en 1» de humedad, temperatura,
// conductividad, pH, N, P y K. Los valores de N, P y K que entrega NO son una
// medición química: el firmware de la sonda los deriva de la conductividad y
// la temperatura con coeficientes de fábrica. Por eso la app los trata como
// señal nativa de tendencia (Guía v0.4, §2 y §8). El mapa de registros y los
// rangos de abajo siguen la hoja de datos del fabricante para esta familia;
// están marcados como «verificar contra el firmware» hasta que el banco de
// pruebas (fase 9) los confirme lectura por lectura.
//
// Este archivo no importa modelos ni servicios a propósito: lo consumen tanto
// el modelo `BioGTelemetry` (plausibilidad) como el códec BLE (conversión), y
// no puede crear ciclos.

/// Canales que una sonda de suelo puede entregar.
enum SoilChannel { moisture, temperature, ec, ph, nitrogen, phosphorus, potassium }

extension SoilChannelX on SoilChannel {
  String get labelEs => switch (this) {
    SoilChannel.moisture => 'Humedad volumétrica',
    SoilChannel.temperature => 'Temperatura de suelo',
    SoilChannel.ec => 'Conductividad eléctrica',
    SoilChannel.ph => 'pH',
    SoilChannel.nitrogen => 'Nitrógeno (señal nativa)',
    SoilChannel.phosphorus => 'Fósforo (señal nativa)',
    SoilChannel.potassium => 'Potasio (señal nativa)',
  };
}

/// Declaración de un canal: dónde vive en la sonda, cómo se convierte y qué
/// rango acepta la app.
class SoilChannelSpec {
  const SoilChannelSpec({
    required this.channel,
    required this.registerHex,
    required this.rawUnit,
    required this.appUnit,
    required this.rawToApp,
    required this.plausibleMin,
    required this.plausibleMax,
    this.isDerived = false,
    this.signedRaw = false,
    this.noteEs,
  });

  final SoilChannel channel;

  /// Dirección del registro de retención (Modbus RTU) en la sonda.
  final String registerHex;

  /// Unidad tal como sale del registro («0.1 %», «µS/cm», «0.1 pH»).
  final String rawUnit;

  /// Unidad interna de la app («%», «°C», «mS/cm», «pH», «mg/kg (nativo)»).
  final String appUnit;

  /// Factor que lleva el valor crudo del registro a la unidad de la app.
  final double rawToApp;

  /// Rango plausible EN UNIDAD DE LA APP. Fuera de él, el dato es ausente.
  final double plausibleMin;
  final double plausibleMax;

  /// El canal se deriva de otro dentro de la sonda (no es evidencia
  /// independiente).
  final bool isDerived;

  /// El registro es entero con signo (temperatura).
  final bool signedRaw;

  final String? noteEs;

  /// Convierte el valor crudo del registro a la unidad de la app, o null si
  /// no es plausible.
  double? fromRaw(num? raw) {
    if (raw == null) return null;
    final double v = raw.toDouble() * rawToApp;
    return isPlausible(v) ? v : null;
  }

  /// Acepta un valor YA en unidad de la app, o null si no es plausible.
  double? accept(num? value) {
    if (value == null) return null;
    final double v = value.toDouble();
    return isPlausible(v) ? v : null;
  }

  bool isPlausible(double v) =>
      v.isFinite && v >= plausibleMin && v <= plausibleMax;
}

/// Contrato completo de una sonda.
class SoilSensorSpec {
  const SoilSensorSpec({
    required this.probeId,
    required this.labelEs,
    required this.channels,
    required this.warmUp,
    required this.ecTemperatureCompensated,
    this.noteEs,
  });

  /// Identificador del modelo, tal como lo declara el firmware en la identidad
  /// (`probe`) o como lo fija el catálogo de hardware.
  final String probeId;
  final String labelEs;
  final List<SoilChannelSpec> channels;

  /// Tiempo que la electrónica necesita tras encender antes de que la lectura
  /// sea utilizable (§25). Lo aplica el firmware; aquí se declara para que el
  /// banco de pruebas lo verifique.
  final Duration warmUp;

  /// La CE que entrega la sonda ya viene referida a 25 °C. Si es false, el
  /// detector de firmas compensa con la temperatura de suelo.
  final bool ecTemperatureCompensated;

  final String? noteEs;

  SoilChannelSpec? channelFor(SoilChannel c) {
    for (final SoilChannelSpec s in channels) {
      if (s.channel == c) return s;
    }
    return null;
  }

  Set<SoilChannel> get derivedChannels => <SoilChannel>{
    for (final SoilChannelSpec s in channels)
      if (s.isDerived) s.channel,
  };

  /// CE en mS/cm a partir del registro en µS/cm. Es la ÚNICA conversión de
  /// unidad de CE del sistema: el resto de la app trabaja en mS/cm.
  double? ecFromMicroSiemens(num? microSiemens) =>
      channelFor(SoilChannel.ec)?.fromRaw(microSiemens);

  // ═════════════════════════════════════════════════════════════════════════
  // PLAUSIBILIDAD COMPARTIDA (modelo interno)
  // ═════════════════════════════════════════════════════════════════════════
  //
  // Límites en unidad de la app que usa `BioGTelemetry.tryFromJson` para
  // cualquier fila, venga de la nube, de BLE o de un archivo. Son de
  // plausibilidad física, no agronómicos: sirven para descartar una sonda
  // descalibrada o un payload corrupto, no para juzgar el suelo.

  static const double kSoilMoistureMinPct = 0.0;
  static const double kSoilMoistureMaxPct = 100.0;
  static const double kSoilTempMinC = -40.0;
  static const double kSoilTempMaxC = 80.0;
  static const double kPhMin = 0.0;
  static const double kPhMax = 14.0;
  static const double kEcMinMilliSiemens = 0.0;
  static const double kEcMaxMilliSiemens = 20.0;

  /// Tope de los canales nativos N/P/K. La familia SN-3002/RS-ECTHNPKPH
  /// declara 0–1999 mg/kg en P y K y hasta 2999 en N según variante; la app
  /// acepta el tope más amplio y deja al contrato de cada sonda afinar.
  static const double kNitrogenMaxNative = 2999.0;
  static const double kPhosphorusMaxNative = 1999.0;
  static const double kPotassiumMaxNative = 2999.0;

  // ═════════════════════════════════════════════════════════════════════════
  // CATÁLOGO
  // ═════════════════════════════════════════════════════════════════════════

  /// Sonda 7-en-1 de referencia de BIO-G.
  static const SoilSensorSpec sn3002 = SoilSensorSpec(
    probeId: 'SN-3002-TR-ECTHNPKPH-N01',
    labelEs: 'Sonda 7 en 1 (humedad, temperatura, CE, pH, N, P, K)',
    warmUp: Duration(seconds: 30),
    // La hoja de datos de esta familia declara compensación interna de CE por
    // temperatura. Verificar en banco (fase 9): si no la hubiera, poner false
    // y el detector de firmas compensa a 25 °C.
    ecTemperatureCompensated: true,
    channels: <SoilChannelSpec>[
      SoilChannelSpec(
        channel: SoilChannel.moisture,
        registerHex: '0x0000',
        rawUnit: '0.1 %',
        appUnit: '%',
        rawToApp: 0.1,
        plausibleMin: kSoilMoistureMinPct,
        plausibleMax: kSoilMoistureMaxPct,
      ),
      SoilChannelSpec(
        channel: SoilChannel.temperature,
        registerHex: '0x0001',
        rawUnit: '0.1 °C (con signo)',
        appUnit: '°C',
        rawToApp: 0.1,
        signedRaw: true,
        plausibleMin: kSoilTempMinC,
        plausibleMax: kSoilTempMaxC,
      ),
      SoilChannelSpec(
        channel: SoilChannel.ec,
        registerHex: '0x0002',
        rawUnit: 'µS/cm',
        appUnit: 'mS/cm',
        rawToApp: 0.001,
        plausibleMin: kEcMinMilliSiemens,
        plausibleMax: kEcMaxMilliSiemens,
        noteEs:
            'Única conversión de CE del sistema. La app trabaja en mS/cm; el '
            'registro entrega µS/cm.',
      ),
      SoilChannelSpec(
        channel: SoilChannel.ph,
        registerHex: '0x0003',
        rawUnit: '0.1 pH',
        appUnit: 'pH',
        rawToApp: 0.1,
        plausibleMin: kPhMin,
        plausibleMax: kPhMax,
        noteEs: 'Rango de medición declarado por el fabricante: 3–9 pH.',
      ),
      SoilChannelSpec(
        channel: SoilChannel.nitrogen,
        registerHex: '0x0004',
        rawUnit: 'mg/kg (derivado)',
        appUnit: 'mg/kg (nativo)',
        rawToApp: 1.0,
        isDerived: true,
        plausibleMin: 0.0,
        plausibleMax: kNitrogenMaxNative,
        noteEs: 'Derivado de la CE por el firmware de la sonda. Señal de tendencia.',
      ),
      SoilChannelSpec(
        channel: SoilChannel.phosphorus,
        registerHex: '0x0005',
        rawUnit: 'mg/kg (derivado)',
        appUnit: 'mg/kg (nativo)',
        rawToApp: 1.0,
        isDerived: true,
        plausibleMin: 0.0,
        plausibleMax: kPhosphorusMaxNative,
        noteEs: 'Derivado de la CE por el firmware de la sonda. Señal de tendencia.',
      ),
      SoilChannelSpec(
        channel: SoilChannel.potassium,
        registerHex: '0x0006',
        rawUnit: 'mg/kg (derivado)',
        appUnit: 'mg/kg (nativo)',
        rawToApp: 1.0,
        isDerived: true,
        plausibleMin: 0.0,
        plausibleMax: kPotassiumMaxNative,
        noteEs: 'Derivado de la CE por el firmware de la sonda. Señal de tendencia.',
      ),
    ],
    noteEs:
        'Mapa de registros y rangos según la hoja de datos de la familia '
        'SN-3002/RS-ECTHNPKPH. Verificar contra el firmware en banco antes de '
        'darlos por definitivos (fase 9).',
  );

  /// Sonda por defecto cuando el firmware no declara modelo: hoy solo existe
  /// una.
  static const SoilSensorSpec defaultSpec = sn3002;

  static const List<SoilSensorSpec> catalog = <SoilSensorSpec>[sn3002];

  /// Resuelve una sonda por su identificador (tolerante a mayúsculas y
  /// espacios). Null si no está en el catálogo.
  static SoilSensorSpec? byId(String? probeId) {
    final String key = (probeId ?? '').trim().toUpperCase();
    if (key.isEmpty) return null;
    for (final SoilSensorSpec s in catalog) {
      if (s.probeId.toUpperCase() == key) return s;
    }
    return null;
  }
}
