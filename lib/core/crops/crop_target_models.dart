import 'package:bio_g/core/agro/agro_types.dart';

class StageTargets {
  const StageTargets({
    required this.moistureRaw,
    required this.soilTemp,
    required this.ph,
    required this.ec,
    required this.resistance,
    required this.nIndex,
    required this.pIndex,
    required this.kIndex,
  });

  final AgroRange moistureRaw;
  final AgroRange soilTemp;
  final AgroRange ph;
  final AgroRange ec;
  final AgroRange resistance;
  final AgroRange nIndex;
  final AgroRange pIndex;
  final AgroRange kIndex;
}

class StageWeights {
  const StageWeights({
    required this.moisture,
    required this.soilTemp,
    required this.resistance,
    required this.ph,
    required this.ec,
    required this.npk,
  });

  final double moisture;
  final double soilTemp;
  final double resistance;
  final double ph;
  final double ec;
  final double npk;

  double get sum => moisture + soilTemp + resistance + ph + ec + npk;
}
