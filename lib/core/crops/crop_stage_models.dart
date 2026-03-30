class CropStageResult {
  final String stageKey;
  final String stageLabelEs;
  final int expectedDaysToEnd;
  final List<dynamic> windowsNow;
  final String heroAsset;
  final String helperCaption;

  /// Día absoluto desde siembra usado por el motor para resolver la etapa.
  ///
  /// Es opcional para mantener compatibilidad con adapters legacy.
  final int? daySinceSowing;

  /// Progreso interno de la etapa actual (0..1).
  ///
  /// Es opcional porque no todos los motores legacy lo exponían.
  final double? stageProgressPct;

  const CropStageResult({
    required this.stageKey,
    required this.stageLabelEs,
    required this.expectedDaysToEnd,
    required this.windowsNow,
    required this.heroAsset,
    this.helperCaption = '',
    this.daySinceSowing,
    this.stageProgressPct,
  });
}
