import 'package:bio_g/widgets/seeds/bean_models.dart';
import 'package:bio_g/widgets/seeds/maize_models.dart';

const String kFj01 = 'fj_01';
const String kFj02 = 'fj_02';
const String kFj03 = 'fj_03';
const String kFj04 = 'fj_04';
const String kFjGen = 'fj_gen';

const Map<String, BeanProfile> beanProfiles = {
  kFj01: BeanProfile(
    id: kFj01,
    label: 'FJ-01 · Precoz',
    useType: 'Grano',
    beanUseType: BeanUseType.grain,
    floweringDays: RangeInt(38, 45),
    endWindowDays: RangeInt(70, 90),
    endActionLabel: 'Cosecha',
    plantHeightM: RangeDouble(0.35, 0.50),
    lowerPodHeightM: RangeDouble(0.10, 0.18),
    germinationDays: RangeInt(4, 7),
    emergenceDays: RangeInt(7, 11),
    vegEarlyDays: RangeInt(11, 24),
  ),
  kFj02: BeanProfile(
    id: kFj02,
    label: 'FJ-02 · Intermedio',
    useType: 'Grano',
    beanUseType: BeanUseType.grain,
    floweringDays: RangeInt(45, 52),
    endWindowDays: RangeInt(90, 105),
    endActionLabel: 'Cosecha',
    plantHeightM: RangeDouble(0.45, 0.70),
    lowerPodHeightM: RangeDouble(0.15, 0.25),
    germinationDays: RangeInt(4, 7),
    emergenceDays: RangeInt(7, 12),
    vegEarlyDays: RangeInt(12, 28),
  ),
  kFj03: BeanProfile(
    id: kFj03,
    label: 'FJ-03 · Intermedio largo',
    useType: 'Grano',
    beanUseType: BeanUseType.grain,
    floweringDays: RangeInt(50, 58),
    endWindowDays: RangeInt(105, 115),
    endActionLabel: 'Cosecha',
    plantHeightM: RangeDouble(0.60, 0.90),
    lowerPodHeightM: RangeDouble(0.20, 0.35),
    germinationDays: RangeInt(4, 7),
    emergenceDays: RangeInt(7, 12),
    vegEarlyDays: RangeInt(12, 30),
  ),
  kFj04: BeanProfile(
    id: kFj04,
    label: 'FJ-04 · Temporal largo',
    useType: 'Grano',
    beanUseType: BeanUseType.grain,
    floweringDays: RangeInt(58, 68),
    endWindowDays: RangeInt(115, 135),
    endActionLabel: 'Cosecha',
    plantHeightM: RangeDouble(0.70, 1.10),
    lowerPodHeightM: RangeDouble(0.25, 0.40),
    germinationDays: RangeInt(5, 8),
    emergenceDays: RangeInt(8, 13),
    vegEarlyDays: RangeInt(13, 34),
  ),
  kFjGen: BeanProfile(
    id: kFjGen,
    label: 'FJ-GEN · Intermedio conservador',
    useType: 'Grano',
    beanUseType: BeanUseType.grain,
    floweringDays: RangeInt(45, 50),
    endWindowDays: RangeInt(95, 105),
    endActionLabel: 'Cosecha',
    plantHeightM: RangeDouble(0.50, 0.65),
    lowerPodHeightM: RangeDouble(0.15, 0.25),
    germinationDays: RangeInt(4, 7),
    emergenceDays: RangeInt(7, 12),
    vegEarlyDays: RangeInt(12, 28),
  ),
};

const Map<String, String> _beanProfileAliasToCanonical = {
  'fj-01': kFj01,
  'fj01': kFj01,
  'precoz': kFj01,
  'negro temprano': kFj01,
  'frijol negro temprano': kFj01,

  'fj-02': kFj02,
  'fj02': kFj02,
  'intermedio': kFj02,
  'negro': kFj02,
  'frijol negro': kFj02,
  'bayo': kFj02,
  'azufrado': kFj02,
  'blanco': kFj02,

  'fj-03': kFj03,
  'fj03': kFj03,
  'intermedio largo': kFj03,
  'pinto': kFj03,
  'frijol pinto': kFj03,
  'flor de mayo': kFj03,
  'flor de junio': kFj03,
  'flor de mayo / flor de junio': kFj03,

  'fj-04': kFj04,
  'fj04': kFj04,
  'temporal largo': kFj04,
  'frijol temporal largo': kFj04,
  'peruano': kFj04,
  'frijol peruano': kFj04,
  'canario': kFj04,
  'frijol canario': kFj04,

  'fj-gen': kFjGen,
  'fjgen': kFjGen,
  'fj_gen': kFjGen,
  'generico': kFjGen,
  'genérico': kFjGen,
  'frijol generico': kFjGen,
  'frijol genérico': kFjGen,
  'intermedio conservador': kFjGen,
};

String? resolveCanonicalBeanProfileId(String raw) {
  final normalized = raw.trim().toLowerCase();
  if (normalized.isEmpty) return null;
  if (beanProfiles.containsKey(normalized)) return normalized;
  return _beanProfileAliasToCanonical[normalized];
}
