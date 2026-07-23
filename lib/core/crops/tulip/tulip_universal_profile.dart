import 'dart:math' as math;

import 'package:bio_g/core/agro/agro_types.dart';
import 'package:bio_g/core/crops/crop_target_models.dart';
import 'package:bio_g/widgets/seeds/tulip_models.dart';
import 'package:bio_g/widgets/seeds/tulip_profiles.dart';

/// Perfil universal agronómico del Tulipán (Documento B).
///
/// MISMAS UNIDADES REALES que el resto de BIO-G (frijol, hortalizas, granos,
/// árboles, ornamentales). No negociable: dashboard, alertas y NPK comparan
/// contra estas unidades.
///   - humedad     → % en la escala calibrada BIO-G (0..100)
///   - temperatura → °C
///   - pH          → pH
///   - EC          → mS/cm   (se evalúa internamente; NO sustituye Resistencia)
///   - resistencia → MPa
///   - N / P / K   → mg/kg   (rangos explícitos de suficiencia de suelo)
///
/// Doctrina del Tulipán (Documento B §0.1):
///   - el AGUA y la TEMPERATURA gobiernan; la nutrición acompaña, no manda;
///   - el frío es condición de habilitación floral, NO una lectura instantánea;
///   - la EC baja NO es defecto: `lowMax = -1` neutraliza falsas deficiencias;
///   - la dormancia usa targets propios (bulbo enterrado más seco), sin
///     desplomar el score por NPK bajo.
class TulipUniversalProfile {
  const TulipUniversalProfile._();

  /// Rango legacy neutralizado para nIndex/pIndex/kIndex (Documento B §9.7). El
  /// motor usa los rangos explícitos en mg/kg (`nSoilPpmRange`, …), no estos
  /// índices; nunca se muestran al usuario.
  static const AgroRange neutralLegacyNpk = AgroRange(
    lowMax: -1,
    optimalMin: 0,
    optimalMax: 100,
    highMin: 101,
  );

  // ── pH por contexto (Documento B §5.2). El pH NO cambia por etapa; solo su
  // peso. El contexto lo define el perfil. ────────────────────────────────────
  static const AgroRange phBaseGarden = AgroRange(
    lowMax: 5.5,
    optimalMin: 6.0,
    optimalMax: 7.0,
    highMin: 7.8,
  );
  static const AgroRange phPotContainer = AgroRange(
    lowMax: 5.4,
    optimalMin: 6.0,
    optimalMax: 6.8,
    highMin: 7.4,
  );
  static const AgroRange phForcedIndoor = AgroRange(
    lowMax: 5.4,
    optimalMin: 6.0,
    optimalMax: 6.8,
    highMin: 7.4,
  );
  static const AgroRange phCutFlower = AgroRange(
    lowMax: 5.5,
    optimalMin: 6.0,
    optimalMax: 7.0,
    highMin: 7.6,
  );
}

/// Datos por etapa. Mismo patrón que `RoseUniversalProfile`.
class _TulipStageProfile {
  const _TulipStageProfile({
    required this.moisture,
    required this.soilTemp,
    required this.ec,
    required this.resistance,
    required this.nPpm,
    required this.pPpm,
    required this.kPpm,
    required this.nPriority,
    required this.pPriority,
    required this.kPriority,
    required this.wMoisture,
    required this.wSoilTemp,
    required this.wResistance,
    required this.wPh,
    required this.wEc,
    required this.wN,
    required this.wP,
    required this.wK,
    required this.nWindowEs,
    required this.pWindowEs,
    required this.kWindowEs,
    required this.nGuidanceEs,
    required this.pGuidanceEs,
    required this.kGuidanceEs,
    required this.careNoteEs,
  });

  final AgroRange moisture;
  final AgroRange soilTemp;
  final AgroRange ec;
  final AgroRange resistance;
  final AgroRange nPpm;
  final AgroRange pPpm;
  final AgroRange kPpm;
  final double nPriority;
  final double pPriority;
  final double kPriority;
  final double wMoisture;
  final double wSoilTemp;
  final double wResistance;
  final double wPh;
  final double wEc;
  final double wN;
  final double wP;
  final double wK;
  final String nWindowEs;
  final String pWindowEs;
  final String kWindowEs;
  final String nGuidanceEs;
  final String pGuidanceEs;
  final String kGuidanceEs;
  final String careNoteEs;
}

// Cada fila de pesos suma 1.00 (Documento B §11).
const Map<String, _TulipStageProfile> _tulipStageProfiles =
    <String, _TulipStageProfile>{
      TulipStageIds.bulbPlanting: _TulipStageProfile(
        moisture: AgroRange(lowMax: 28, optimalMin: 45, optimalMax: 68, highMin: 84),
        soilTemp: AgroRange(lowMax: -1, optimalMin: 2, optimalMax: 9, highMin: 14),
        ec: AgroRange(lowMax: -1, optimalMin: 0, optimalMax: 1.0, highMin: 2.0),
        resistance: AgroRange(lowMax: -1, optimalMin: 0, optimalMax: 1.2, highMin: 1.8),
        nPpm: AgroRange(lowMax: 5, optimalMin: 10, optimalMax: 25, highMin: 45),
        pPpm: AgroRange(lowMax: 10, optimalMin: 18, optimalMax: 38, highMin: 55),
        kPpm: AgroRange(lowMax: 35, optimalMin: 60, optimalMax: 110, highMin: 160),
        nPriority: 0.12,
        pPriority: 0.42,
        kPriority: 0.25,
        wMoisture: 0.25,
        wSoilTemp: 0.23,
        wResistance: 0.14,
        wPh: 0.07,
        wEc: 0.13,
        wN: 0.05,
        wP: 0.07,
        wK: 0.06,
        nWindowEs: 'Reservas del bulbo',
        pWindowEs: 'Inicio de raíces',
        kWindowEs: 'Balance inicial',
        nGuidanceEs:
            'El bulbo ya trae nitrógeno. No empujes con fertilizante al plantar.',
        pGuidanceEs:
            'El fósforo acompaña el arranque de raíces, pero primero revisa drenaje.',
        kGuidanceEs: 'El potasio da un balance inicial mientras se instala el bulbo.',
        careNoteEs:
            'Mantén el sustrato húmedo y con salida de agua. El bulbo no debe '
            'quedar encharcado.',
      ),
      TulipStageIds.rootingChilling: _TulipStageProfile(
        moisture: AgroRange(lowMax: 32, optimalMin: 48, optimalMax: 72, highMin: 86),
        soilTemp: AgroRange(lowMax: -1, optimalMin: 2, optimalMax: 9, highMin: 12),
        ec: AgroRange(lowMax: -1, optimalMin: 0, optimalMax: 0.9, highMin: 1.8),
        resistance: AgroRange(lowMax: -1, optimalMin: 0, optimalMax: 1.2, highMin: 1.8),
        nPpm: AgroRange(lowMax: 6, optimalMin: 12, optimalMax: 28, highMin: 48),
        pPpm: AgroRange(lowMax: 12, optimalMin: 22, optimalMax: 42, highMin: 60),
        kPpm: AgroRange(lowMax: 40, optimalMin: 70, optimalMax: 120, highMin: 175),
        nPriority: 0.15,
        pPriority: 0.50,
        kPriority: 0.30,
        wMoisture: 0.24,
        wSoilTemp: 0.29,
        wResistance: 0.13,
        wPh: 0.05,
        wEc: 0.13,
        wN: 0.04,
        wP: 0.06,
        wK: 0.06,
        nWindowEs: 'Demanda baja',
        pWindowEs: 'Ventana de raíz',
        kWindowEs: 'Turgencia de raíz',
        nGuidanceEs:
            'La raíz nueva no necesita nitrógeno alto. El frío y el drenaje mandan.',
        pGuidanceEs:
            'Buena ventana para fósforo en la raíz; confirma el drenaje primero.',
        kGuidanceEs: 'El potasio ayuda a la turgencia de la raíz mientras enraíza.',
        careNoteEs:
            'Conserva humedad estable mientras completa raíz y frío. No lo '
            'calientes para acelerar.',
      ),
      TulipStageIds.shootEmergence: _TulipStageProfile(
        moisture: AgroRange(lowMax: 35, optimalMin: 50, optimalMax: 74, highMin: 88),
        soilTemp: AgroRange(lowMax: 2, optimalMin: 8, optimalMax: 15, highMin: 20),
        ec: AgroRange(lowMax: -1, optimalMin: 0, optimalMax: 1.1, highMin: 2.0),
        resistance: AgroRange(lowMax: -1, optimalMin: 0, optimalMax: 1.4, highMin: 2.0),
        nPpm: AgroRange(lowMax: 10, optimalMin: 18, optimalMax: 38, highMin: 60),
        pPpm: AgroRange(lowMax: 12, optimalMin: 20, optimalMax: 40, highMin: 58),
        kPpm: AgroRange(lowMax: 50, optimalMin: 80, optimalMax: 140, highMin: 200),
        nPriority: 0.32,
        pPriority: 0.38,
        kPriority: 0.35,
        wMoisture: 0.26,
        wSoilTemp: 0.20,
        wResistance: 0.12,
        wPh: 0.06,
        wEc: 0.12,
        wN: 0.08,
        wP: 0.08,
        wK: 0.08,
        nWindowEs: 'Inicio de hoja',
        pWindowEs: 'Arranque',
        kWindowEs: 'Activación',
        nGuidanceEs: 'El nitrógeno arranca el follaje; sin excesos todavía.',
        pGuidanceEs: 'El fósforo apoya el arranque del brote.',
        kGuidanceEs: 'El potasio activa el crecimiento inicial.',
        careNoteEs:
            'La punta ya está activa. Evita que el sustrato se seque por completo.',
      ),
      TulipStageIds.vegetativeGrowth: _TulipStageProfile(
        moisture: AgroRange(lowMax: 38, optimalMin: 52, optimalMax: 76, highMin: 88),
        soilTemp: AgroRange(lowMax: 5, optimalMin: 10, optimalMax: 18, highMin: 23),
        ec: AgroRange(lowMax: -1, optimalMin: 0, optimalMax: 1.4, highMin: 2.4),
        resistance: AgroRange(lowMax: -1, optimalMin: 0, optimalMax: 1.4, highMin: 2.0),
        nPpm: AgroRange(lowMax: 18, optimalMin: 30, optimalMax: 55, highMin: 80),
        pPpm: AgroRange(lowMax: 10, optimalMin: 18, optimalMax: 36, highMin: 52),
        kPpm: AgroRange(lowMax: 60, optimalMin: 95, optimalMax: 160, highMin: 225),
        nPriority: 0.68,
        pPriority: 0.35,
        kPriority: 0.55,
        wMoisture: 0.25,
        wSoilTemp: 0.15,
        wResistance: 0.10,
        wPh: 0.07,
        wEc: 0.10,
        wN: 0.14,
        wP: 0.08,
        wK: 0.11,
        nWindowEs: 'Expansión de hojas',
        pWindowEs: 'Demanda moderada',
        kWindowEs: 'Vigor y balance',
        nGuidanceEs:
            'El nitrógeno acompaña el crecimiento de hojas. Evita excesos.',
        pGuidanceEs: 'El fósforo se mantiene moderado durante el follaje.',
        kGuidanceEs: 'El potasio da vigor y balance a las hojas.',
        careNoteEs:
            'Las hojas están construyendo la temporada. Mantén luz y humedad sin '
            'exceso.',
      ),
      TulipStageIds.stemElongation: _TulipStageProfile(
        moisture: AgroRange(lowMax: 40, optimalMin: 55, optimalMax: 76, highMin: 88),
        soilTemp: AgroRange(lowMax: 7, optimalMin: 12, optimalMax: 18, highMin: 22),
        ec: AgroRange(lowMax: -1, optimalMin: 0, optimalMax: 1.3, highMin: 2.2),
        resistance: AgroRange(lowMax: -1, optimalMin: 0, optimalMax: 1.4, highMin: 2.0),
        nPpm: AgroRange(lowMax: 16, optimalMin: 28, optimalMax: 50, highMin: 75),
        pPpm: AgroRange(lowMax: 10, optimalMin: 18, optimalMax: 34, highMin: 50),
        kPpm: AgroRange(lowMax: 65, optimalMin: 105, optimalMax: 175, highMin: 240),
        nPriority: 0.48,
        pPriority: 0.32,
        kPriority: 0.68,
        wMoisture: 0.25,
        wSoilTemp: 0.18,
        wResistance: 0.10,
        wPh: 0.06,
        wEc: 0.11,
        wN: 0.10,
        wP: 0.07,
        wK: 0.13,
        nWindowEs: 'Evitar exceso',
        pWindowEs: 'Demanda moderada',
        kWindowEs: 'Tallo y turgencia',
        nGuidanceEs:
            'No empujes nitrógeno: más hoja no es mejor tallo.',
        pGuidanceEs: 'El fósforo se mantiene moderado.',
        kGuidanceEs:
            'El potasio tiene prioridad para el balance de tallo y tejidos.',
        careNoteEs:
            'El tallo crece rápido. El déficit y el calor pueden dejarlo corto o '
            'débil.',
      ),
      TulipStageIds.budFormation: _TulipStageProfile(
        moisture: AgroRange(lowMax: 40, optimalMin: 55, optimalMax: 75, highMin: 86),
        soilTemp: AgroRange(lowMax: 8, optimalMin: 12, optimalMax: 18, highMin: 22),
        ec: AgroRange(lowMax: -1, optimalMin: 0, optimalMax: 1.2, highMin: 2.0),
        resistance: AgroRange(lowMax: -1, optimalMin: 0, optimalMax: 1.4, highMin: 2.0),
        nPpm: AgroRange(lowMax: 12, optimalMin: 22, optimalMax: 42, highMin: 65),
        pPpm: AgroRange(lowMax: 10, optimalMin: 18, optimalMax: 36, highMin: 52),
        kPpm: AgroRange(lowMax: 65, optimalMin: 105, optimalMax: 175, highMin: 240),
        nPriority: 0.32,
        pPriority: 0.38,
        kPriority: 0.72,
        wMoisture: 0.26,
        wSoilTemp: 0.18,
        wResistance: 0.08,
        wPh: 0.06,
        wEc: 0.11,
        wN: 0.08,
        wP: 0.09,
        wK: 0.14,
        nWindowEs: 'Demanda contenida',
        pWindowEs: 'Formación floral',
        kWindowEs: 'Calidad de tallo y botón',
        nGuidanceEs: 'Mantén el nitrógeno contenido; el botón ya está cerca.',
        pGuidanceEs: 'El fósforo apoya la formación del botón.',
        kGuidanceEs: 'El potasio cuida la calidad de tallo y botón.',
        careNoteEs:
            'Evita calor, sequía y cambios bruscos. El botón todavía está cerrado.',
      ),
      TulipStageIds.flowering: _TulipStageProfile(
        moisture: AgroRange(lowMax: 38, optimalMin: 50, optimalMax: 72, highMin: 84),
        soilTemp: AgroRange(lowMax: 7, optimalMin: 10, optimalMax: 16, highMin: 20),
        ec: AgroRange(lowMax: -1, optimalMin: 0, optimalMax: 1.0, highMin: 1.8),
        resistance: AgroRange(lowMax: -1, optimalMin: 0, optimalMax: 1.4, highMin: 2.0),
        nPpm: AgroRange(lowMax: 8, optimalMin: 15, optimalMax: 32, highMin: 55),
        pPpm: AgroRange(lowMax: 8, optimalMin: 15, optimalMax: 30, highMin: 45),
        kPpm: AgroRange(lowMax: 55, optimalMin: 90, optimalMax: 150, highMin: 215),
        nPriority: 0.18,
        pPriority: 0.25,
        kPriority: 0.58,
        wMoisture: 0.27,
        wSoilTemp: 0.23,
        wResistance: 0.07,
        wPh: 0.05,
        wEc: 0.12,
        wN: 0.06,
        wP: 0.07,
        wK: 0.13,
        nWindowEs: 'Demanda baja',
        pWindowEs: 'Demanda baja',
        kWindowEs: 'Sostener calidad',
        nGuidanceEs: 'En flor el nitrógeno baja; no busques más hoja.',
        pGuidanceEs: 'El fósforo baja de prioridad durante la floración.',
        kGuidanceEs: 'El potasio sostiene la calidad de la flor.',
        careNoteEs:
            'Mantén el ambiente fresco y riega solo cuando el sustrato lo '
            'necesite.',
      ),
      TulipStageIds.bulbRecharge: _TulipStageProfile(
        moisture: AgroRange(lowMax: 34, optimalMin: 46, optimalMax: 70, highMin: 84),
        soilTemp: AgroRange(lowMax: 5, optimalMin: 10, optimalMax: 20, highMin: 25),
        ec: AgroRange(lowMax: -1, optimalMin: 0, optimalMax: 1.4, highMin: 2.4),
        resistance: AgroRange(lowMax: -1, optimalMin: 0, optimalMax: 1.4, highMin: 2.0),
        nPpm: AgroRange(lowMax: 15, optimalMin: 25, optimalMax: 50, highMin: 75),
        pPpm: AgroRange(lowMax: 12, optimalMin: 22, optimalMax: 44, highMin: 62),
        kPpm: AgroRange(lowMax: 70, optimalMin: 115, optimalMax: 190, highMin: 260),
        nPriority: 0.52,
        pPriority: 0.45,
        kPriority: 0.78,
        wMoisture: 0.26,
        wSoilTemp: 0.14,
        wResistance: 0.08,
        wPh: 0.06,
        wEc: 0.11,
        wN: 0.11,
        wP: 0.09,
        wK: 0.15,
        nWindowEs: 'Recuperación del bulbo',
        pWindowEs: 'Formación de reemplazos',
        kWindowEs: 'Máxima prioridad',
        nGuidanceEs:
            'Las hojas verdes todavía alimentan el bulbo. Revisa N solo si agua, '
            'pH y sales están bien.',
        pGuidanceEs:
            'El fósforo puede apoyar la formación de nuevos bulbos; confirma antes '
            'de actuar.',
        kGuidanceEs:
            'Es la ventana de mayor prioridad de potasio. No agregues sales si la '
            'EC está alta.',
        careNoteEs:
            'La flor terminó, pero las hojas siguen alimentando el bulbo. No las '
            'cortes verdes.',
      ),
      TulipStageIds.foliageSenescence: _TulipStageProfile(
        moisture: AgroRange(lowMax: 15, optimalMin: 25, optimalMax: 52, highMin: 76),
        soilTemp: AgroRange(lowMax: 2, optimalMin: 8, optimalMax: 22, highMin: 28),
        ec: AgroRange(lowMax: -1, optimalMin: 0, optimalMax: 0.8, highMin: 1.6),
        resistance: AgroRange(lowMax: -1, optimalMin: 0, optimalMax: 1.5, highMin: 2.2),
        nPpm: AgroRange(lowMax: 6, optimalMin: 12, optimalMax: 28, highMin: 48),
        pPpm: AgroRange(lowMax: 8, optimalMin: 14, optimalMax: 30, highMin: 46),
        kPpm: AgroRange(lowMax: 40, optimalMin: 70, optimalMax: 120, highMin: 180),
        nPriority: 0.18,
        pPriority: 0.25,
        kPriority: 0.40,
        wMoisture: 0.30,
        wSoilTemp: 0.17,
        wResistance: 0.08,
        wPh: 0.05,
        wEc: 0.12,
        wN: 0.07,
        wP: 0.08,
        wK: 0.13,
        nWindowEs: 'Movilización interna',
        pWindowEs: 'Movilización interna',
        kWindowEs: 'Movilización interna',
        nGuidanceEs:
            'No fertilices para reverdecer hojas que están terminando su ciclo.',
        pGuidanceEs: 'El fósforo baja: la planta moviliza reservas internas.',
        kGuidanceEs: 'El potasio se moviliza internamente; sin aportes forzados.',
        careNoteEs:
            'El amarillamiento puede ser normal. Reduce el agua de forma gradual.',
      ),
      TulipStageIds.dormancy: _TulipStageProfile(
        moisture: AgroRange(lowMax: 4, optimalMin: 10, optimalMax: 40, highMin: 72),
        soilTemp: AgroRange(lowMax: -5, optimalMin: 4, optimalMax: 24, highMin: 32),
        ec: AgroRange(lowMax: -1, optimalMin: 0, optimalMax: 0.6, highMin: 1.2),
        resistance: AgroRange(lowMax: -1, optimalMin: 0, optimalMax: 1.5, highMin: 2.2),
        nPpm: AgroRange(lowMax: 3, optimalMin: 6, optimalMax: 18, highMin: 35),
        pPpm: AgroRange(lowMax: 5, optimalMin: 10, optimalMax: 22, highMin: 38),
        kPpm: AgroRange(lowMax: 25, optimalMin: 45, optimalMax: 90, highMin: 145),
        nPriority: 0.05,
        pPriority: 0.08,
        kPriority: 0.10,
        wMoisture: 0.36,
        wSoilTemp: 0.24,
        wResistance: 0.10,
        wPh: 0.05,
        wEc: 0.12,
        wN: 0.04,
        wP: 0.04,
        wK: 0.05,
        nWindowEs: 'Sin acción',
        pWindowEs: 'Sin acción',
        kWindowEs: 'Sin acción',
        nGuidanceEs: 'No fertilices el bulbo en reposo por una lectura aislada.',
        pGuidanceEs: 'El fósforo no es prioridad en dormancia.',
        kGuidanceEs: 'Sin aportes de potasio durante el reposo del bulbo.',
        careNoteEs:
            'La parte aérea terminó. Conserva el bulbo más seco y evita humedad '
            'sostenida.',
      ),
      // Banda conservadora por confirmar (Documento B §2.2). Debe
      // auto-repararse cuando exista fecha y perfil.
      TulipStageIds.fallback: _TulipStageProfile(
        moisture: AgroRange(lowMax: 28, optimalMin: 45, optimalMax: 72, highMin: 86),
        soilTemp: AgroRange(lowMax: 2, optimalMin: 8, optimalMax: 20, highMin: 26),
        ec: AgroRange(lowMax: -1, optimalMin: 0, optimalMax: 1.1, highMin: 2.0),
        resistance: AgroRange(lowMax: -1, optimalMin: 0, optimalMax: 1.4, highMin: 2.0),
        nPpm: AgroRange(lowMax: 8, optimalMin: 15, optimalMax: 35, highMin: 60),
        pPpm: AgroRange(lowMax: 10, optimalMin: 18, optimalMax: 36, highMin: 54),
        kPpm: AgroRange(lowMax: 50, optimalMin: 85, optimalMax: 145, highMin: 210),
        nPriority: 0.25,
        pPriority: 0.30,
        kPriority: 0.40,
        wMoisture: 0.28,
        wSoilTemp: 0.18,
        wResistance: 0.10,
        wPh: 0.07,
        wEc: 0.12,
        wN: 0.08,
        wP: 0.07,
        wK: 0.10,
        nWindowEs: 'Revisión general',
        pWindowEs: 'Revisión general',
        kWindowEs: 'Revisión general',
        nGuidanceEs: 'Confirma la fecha o el tipo de Tulipán para afinar la lectura.',
        pGuidanceEs: 'Confirma la etapa antes de interpretar el fósforo.',
        kGuidanceEs: 'Confirma la etapa antes de interpretar el potasio.',
        careNoteEs:
            'Confirma la fecha o el tipo de Tulipán para ajustar mejor la etapa.',
      ),
    };

_TulipStageProfile _profileForStage(String? stageId) {
  final id = normalizeTulipStageId(stageId);
  return _tulipStageProfiles[id] ?? _tulipStageProfiles[TulipStageIds.fallback]!;
}

// ── Contexto de cultivo por perfil (Documento B §17) ─────────────────────────
enum _TulipContext { garden, potContainer, forcedIndoor, cutFlower }

_TulipContext _contextForProfile(String? profileId) {
  switch (profileId?.trim().toLowerCase()) {
    case kTu02DecorativeContainer:
      return _TulipContext.potContainer;
    case kTu03ForcedIndoor:
      return _TulipContext.forcedIndoor;
    case kTu04CutFlower:
      return _TulipContext.cutFlower;
    // Premium hereda jardín para targets de suelo; sus modificadores son de
    // castigo/mensaje, no de físicas del sustrato (Documento B §17.5).
    case kTu01GardenExterior:
    case kTu05SpecialPremium:
    case kTuSkip:
    default:
      return _TulipContext.garden;
  }
}

// Etapas de la FASE ACTIVA (plantación → recarga): reciben los ajustes
// hídricos/EC por perfil. Senescencia y dormancia quedan fuera.
const Set<String> _activeStageIds = <String>{
  TulipStageIds.bulbPlanting,
  TulipStageIds.rootingChilling,
  TulipStageIds.shootEmergence,
  TulipStageIds.vegetativeGrowth,
  TulipStageIds.stemElongation,
  TulipStageIds.budFormation,
  TulipStageIds.flowering,
  TulipStageIds.bulbRecharge,
};
const Set<String> _earlyRootStageIds = <String>{
  TulipStageIds.bulbPlanting,
  TulipStageIds.rootingChilling,
};
const Set<String> _emergenceToBudIds = <String>{
  TulipStageIds.shootEmergence,
  TulipStageIds.vegetativeGrowth,
  TulipStageIds.stemElongation,
  TulipStageIds.budFormation,
};
const Set<String> _elongationToFlowerIds = <String>{
  TulipStageIds.stemElongation,
  TulipStageIds.budFormation,
  TulipStageIds.flowering,
};

AgroRange _phForContext(_TulipContext ctx) {
  switch (ctx) {
    case _TulipContext.potContainer:
      return TulipUniversalProfile.phPotContainer;
    case _TulipContext.forcedIndoor:
      return TulipUniversalProfile.phForcedIndoor;
    case _TulipContext.cutFlower:
      return TulipUniversalProfile.phCutFlower;
    case _TulipContext.garden:
      return TulipUniversalProfile.phBaseGarden;
  }
}

/// Targets base de sensor por etapa, en unidades reales (sin modificadores de
/// perfil). Usa pH de jardín por defecto.
StageTargets resolveTulipTargets(String? stageId) {
  final p = _profileForStage(stageId);
  return _buildTargets(p, TulipUniversalProfile.phBaseGarden);
}

/// Targets ajustados por el contexto de cultivo que implica el perfil
/// (Documento B §17): pH por contexto + ajustes de humedad, EC, resistencia y
/// temperatura. No se duplica una tabla completa por perfil.
StageTargets resolveTulipTargetsForProfile(
  String? stageId, {
  required String? profileId,
}) {
  final id = normalizeTulipStageId(stageId);
  final p = _profileForStage(id);
  final ctx = _contextForProfile(profileId);

  AgroRange moisture = p.moisture;
  AgroRange ec = p.ec;
  AgroRange resistance = p.resistance;
  AgroRange soilTemp = p.soilTemp;

  final bool active = _activeStageIds.contains(id);

  switch (ctx) {
    case _TulipContext.garden:
      break;
    case _TulipContext.potContainer:
      if (active) {
        moisture = _shift(moisture, optMax: -2, highMin: -4);
        ec = _capUpper(ec, optMax: 1.0, highMin: 1.8);
        resistance = _capResistance(resistance, id);
      }
      break;
    case _TulipContext.forcedIndoor:
      if (active) {
        moisture = _shift(moisture, optMax: -3, highMin: -6);
        ec = _capUpper(ec, optMax: 0.8, highMin: 1.5);
        resistance = _capResistance(resistance, id);
      }
      // Floración de interior: suelo más fresco (Documento B §17.3).
      if (id == TulipStageIds.flowering) {
        soilTemp = AgroRange(
          lowMax: soilTemp.lowMax,
          optimalMin: soilTemp.optimalMin,
          optimalMax: 16,
          highMin: 20,
        );
      }
      break;
    case _TulipContext.cutFlower:
      if (active) {
        ec = _capUpper(ec, optMax: 1.2, highMin: 2.0);
        resistance = _capUpper(resistance, optMax: null, highMin: 1.8);
        moisture = _shift(moisture, highMin: -2);
      }
      // Estabilidad hídrica sin saturación en emergencia–botón.
      if (_emergenceToBudIds.contains(id)) {
        moisture = _shift(moisture, optMin: 2);
      }
      // Rango térmico estricto 12–18 en elongación–flor (Documento B §17.4).
      if (_elongationToFlowerIds.contains(id)) {
        soilTemp = AgroRange(
          lowMax: soilTemp.lowMax,
          optimalMin: 12,
          optimalMax: 18,
          highMin: 21,
        );
      }
      break;
  }

  return _buildTargets(
    p,
    _phForContext(ctx),
    moisture: moisture,
    ec: ec,
    resistance: resistance,
    soilTemp: soilTemp,
  );
}

/// Pesos del AgroScore por etapa (Documento B §11). Cada fila suma 1.00. Flor
/// de corte sube el peso de K en elongación y botón en +0.02, restándolo de pH
/// y resistencia sin romper Σ=1.00 (Documento B §17.4).
StageWeights resolveTulipStageWeights(String? stageId, {String? profileId}) {
  final id = normalizeTulipStageId(stageId);
  final p = _profileForStage(id);

  double wK = p.wK;
  double wPh = p.wPh;
  double wResistance = p.wResistance;

  final bool isCut = _contextForProfile(profileId) == _TulipContext.cutFlower;
  if (isCut &&
      (id == TulipStageIds.stemElongation || id == TulipStageIds.budFormation)) {
    wK += 0.02;
    wPh = math.max(0.0, wPh - 0.01);
    wResistance = math.max(0.0, wResistance - 0.01);
  }

  return StageWeights(
    moisture: p.wMoisture,
    soilTemp: p.wSoilTemp,
    resistance: wResistance,
    ph: wPh,
    ec: p.wEc,
    n: p.wN,
    p: p.wP,
    k: wK,
  );
}

/// Nota corta de cuidado por etapa (Documento B §18).
String tulipStageCareNoteEs(String? stageId) =>
    _profileForStage(stageId).careNoteEs;

// ── Helpers de construcción/ajuste ───────────────────────────────────────────

StageTargets _buildTargets(
  _TulipStageProfile p,
  AgroRange ph, {
  AgroRange? moisture,
  AgroRange? ec,
  AgroRange? resistance,
  AgroRange? soilTemp,
}) {
  return StageTargets(
    moistureRaw: moisture ?? p.moisture,
    soilTemp: soilTemp ?? p.soilTemp,
    ph: ph,
    ec: ec ?? p.ec,
    resistance: resistance ?? p.resistance,
    // Índices legacy neutralizados (Documento B §9.7): el motor usa los rangos
    // explícitos en mg/kg. Nunca se muestran al usuario.
    nIndex: TulipUniversalProfile.neutralLegacyNpk,
    pIndex: TulipUniversalProfile.neutralLegacyNpk,
    kIndex: TulipUniversalProfile.neutralLegacyNpk,
    nSoilPpmRange: p.nPpm,
    pSoilPpmRange: p.pPpm,
    kSoilPpmRange: p.kPpm,
    nPriority: p.nPriority,
    pPriority: p.pPriority,
    kPriority: p.kPriority,
    nWindowLabelEs: p.nWindowEs,
    pWindowLabelEs: p.pWindowEs,
    kWindowLabelEs: p.kWindowEs,
    nShortGuidanceEs: p.nGuidanceEs,
    pShortGuidanceEs: p.pGuidanceEs,
    kShortGuidanceEs: p.kGuidanceEs,
  );
}

/// Desplaza una banda por deltas (mantiene el orden interno consistente).
AgroRange _shift(
  AgroRange r, {
  double optMin = 0,
  double optMax = 0,
  double highMin = 0,
}) {
  final newOptMin = r.optimalMin + optMin;
  final newOptMax = math.max(newOptMin, r.optimalMax + optMax);
  final newHighMin = math.max(newOptMax, r.highMin + highMin);
  return AgroRange(
    lowMax: r.lowMax,
    optimalMin: newOptMin,
    optimalMax: newOptMax,
    highMin: newHighMin,
  );
}

/// Aplica topes superiores (min con el cap) sin subir los valores base.
AgroRange _capUpper(AgroRange r, {double? optMax, double? highMin}) {
  final newOptMax = optMax == null ? r.optimalMax : math.min(r.optimalMax, optMax);
  final cappedHighMin = highMin == null ? r.highMin : math.min(r.highMin, highMin);
  final newHighMin = math.max(newOptMax, cappedHighMin);
  return AgroRange(
    lowMax: r.lowMax,
    optimalMin: math.min(r.optimalMin, newOptMax),
    optimalMax: newOptMax,
    highMin: newHighMin,
  );
}

/// Resistencia en maceta/forzado: highMin 1.6 en plantación/enraizado, 1.8 en
/// fase activa (Documento B §7.3).
AgroRange _capResistance(AgroRange r, String stageId) {
  final cap = _earlyRootStageIds.contains(stageId) ? 1.6 : 1.8;
  return _capUpper(r, highMin: cap);
}
