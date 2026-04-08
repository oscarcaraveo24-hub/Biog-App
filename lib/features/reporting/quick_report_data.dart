class QuickReportData {
  final String deviceName;
  final String? lotLabel;
  final String cropLabel;
  final String profileLabel;
  final String stageLabel;
  final int? daySinceSowing;
  final DateTime generatedAt;
  final DateTime? readingAt;

  final double nValue;
  final double pValue;
  final double kValue;

  /// Porcentajes visuales para los 3 anillos / gauges.
  /// Deben venir normalizados en rango 0..1.
  final double nPercent;
  final double pPercent;
  final double kPercent;

  final String nStatus;
  final String pStatus;
  final String kStatus;

  /// Etiquetas del historial, por ejemplo:
  /// ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Hoy']
  final List<String> historyLabels;

  /// Series históricas de 7 días para NPK.
  final List<double> historyN;
  final List<double> historyP;
  final List<double> historyK;

  final String recommendationTitle;
  final String recommendationBody;

  final String? climateBannerTitle;
  final String? climateBannerBody;

  const QuickReportData({
    required this.deviceName,
    this.lotLabel,
    required this.cropLabel,
    required this.profileLabel,
    required this.stageLabel,
    required this.daySinceSowing,
    required this.generatedAt,
    this.readingAt,
    required this.nValue,
    required this.pValue,
    required this.kValue,
    required this.nPercent,
    required this.pPercent,
    required this.kPercent,
    required this.nStatus,
    required this.pStatus,
    required this.kStatus,
    required this.historyLabels,
    required this.historyN,
    required this.historyP,
    required this.historyK,
    required this.recommendationTitle,
    required this.recommendationBody,
    this.climateBannerTitle,
    this.climateBannerBody,
  });

  bool get hasClimateBanner {
    final String title = climateBannerTitle?.trim() ?? '';
    final String body = climateBannerBody?.trim() ?? '';
    return title.isNotEmpty || body.isNotEmpty;
  }

  bool get hasLotLabel => (lotLabel?.trim().isNotEmpty ?? false);

  String get displayLotOrDevice {
    if (hasLotLabel) return lotLabel!.trim();
    return deviceName;
  }

  QuickReportData copyWith({
    String? deviceName,
    String? lotLabel,
    String? cropLabel,
    String? profileLabel,
    String? stageLabel,
    int? daySinceSowing,
    DateTime? generatedAt,
    DateTime? readingAt,
    double? nValue,
    double? pValue,
    double? kValue,
    double? nPercent,
    double? pPercent,
    double? kPercent,
    String? nStatus,
    String? pStatus,
    String? kStatus,
    List<String>? historyLabels,
    List<double>? historyN,
    List<double>? historyP,
    List<double>? historyK,
    String? recommendationTitle,
    String? recommendationBody,
    String? climateBannerTitle,
    String? climateBannerBody,
  }) {
    return QuickReportData(
      deviceName: deviceName ?? this.deviceName,
      lotLabel: lotLabel ?? this.lotLabel,
      cropLabel: cropLabel ?? this.cropLabel,
      profileLabel: profileLabel ?? this.profileLabel,
      stageLabel: stageLabel ?? this.stageLabel,
      daySinceSowing: daySinceSowing ?? this.daySinceSowing,
      generatedAt: generatedAt ?? this.generatedAt,
      readingAt: readingAt ?? this.readingAt,
      nValue: nValue ?? this.nValue,
      pValue: pValue ?? this.pValue,
      kValue: kValue ?? this.kValue,
      nPercent: nPercent ?? this.nPercent,
      pPercent: pPercent ?? this.pPercent,
      kPercent: kPercent ?? this.kPercent,
      nStatus: nStatus ?? this.nStatus,
      pStatus: pStatus ?? this.pStatus,
      kStatus: kStatus ?? this.kStatus,
      historyLabels: historyLabels ?? this.historyLabels,
      historyN: historyN ?? this.historyN,
      historyP: historyP ?? this.historyP,
      historyK: historyK ?? this.historyK,
      recommendationTitle: recommendationTitle ?? this.recommendationTitle,
      recommendationBody: recommendationBody ?? this.recommendationBody,
      climateBannerTitle: climateBannerTitle ?? this.climateBannerTitle,
      climateBannerBody: climateBannerBody ?? this.climateBannerBody,
    );
  }
}
