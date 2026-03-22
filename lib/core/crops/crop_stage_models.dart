class CropStageResult {
  final String stageKey;
  final String stageLabelEs;
  final int expectedDaysToEnd;
  final List<dynamic> windowsNow;
  final String heroAsset;

  const CropStageResult({
    required this.stageKey,
    required this.stageLabelEs,
    required this.expectedDaysToEnd,
    required this.windowsNow,
    required this.heroAsset,
  });
}
