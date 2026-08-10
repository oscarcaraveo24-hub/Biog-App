// test/core/agro/traceability/recommendation_store_test.dart
//
// Fiabilidad del registro auditable, no su forma.
//
// El fallo que cubren estas pruebas: `RecommendationStore.save()` puede
// devolver false, y `RecommendationRecorder` lo ignoraba. La secuencia era
// BIO-G emite recomendación → SQLite falla → la fila nunca se escribe → el
// recorder marca el id como registrado → no reintenta jamás. Resultado: una
// recomendación que consta como auditada sin estarlo, que es exactamente lo que
// el Fundacional 2.1 prohíbe.
//
// Se usa la costura `RecommendationStore({Database Function()? testDatabase})`
// para inyectar una base falsa, y una subclase que cuenta invocaciones para
// observar la deduplicación del recorder sin tocar su estado privado.

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite/sqflite.dart';

import 'package:bio_g/core/agro/agro_types.dart';
import 'package:bio_g/core/agro/irrigation/irrigation_engine.dart';
import 'package:bio_g/core/agro/irrigation/irrigation_inputs.dart';
import 'package:bio_g/core/agro/irrigation/irrigation_types.dart';
import 'package:bio_g/core/agro/traceability/recommendation_record.dart';
import 'package:bio_g/core/agro/traceability/recommendation_recorder.dart';
import 'package:bio_g/core/agro/traceability/recommendation_store.dart';
import 'package:bio_g/core/crops/crop_runtime_snapshot.dart';
import 'package:bio_g/core/weather/agronomic_weather_snapshot.dart';
import 'package:bio_g/models/biog_telemetry.dart';
import 'package:bio_g/models/seed_install.dart';

/// Base de datos falsa.
///
/// Solo se implementan los dos métodos que `save` usa; el resto lo resuelve el
/// reenvío por `noSuchMethod`, que evita tener que arrastrar toda la superficie
/// de `Database` para probar una sola ruta.
class _FakeDatabase implements Database {
  _FakeDatabase({
    this.insertResult = 1,
    this.insertThrows = false,
    this.existingRows = const <Map<String, Object?>>[],
  });

  /// Lo que devuelve `rawInsert`. Cero simula el `INSERT OR IGNORE` que no
  /// escribió nada, sea por duplicado o por fallo silencioso.
  int insertResult;

  bool insertThrows;

  /// Filas que devuelve la consulta de comprobación por id.
  List<Map<String, Object?>> existingRows;

  int rawInsertCalls = 0;
  int queryCalls = 0;

  @override
  Future<int> rawInsert(String sql, [List<Object?>? arguments]) async {
    rawInsertCalls++;
    if (insertThrows) {
      throw Exception('disco lleno');
    }
    return insertResult;
  }

  @override
  Future<List<Map<String, Object?>>> query(
    String table, {
    bool? distinct,
    List<String>? columns,
    String? where,
    List<Object?>? whereArgs,
    String? groupBy,
    String? having,
    String? orderBy,
    int? limit,
    int? offset,
  }) async {
    queryCalls++;
    return existingRows;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      super.noSuchMethod(invocation);
}

/// Almacén que cuenta cuántas veces se le pidió guardar y qué contestó.
///
/// Es la única forma de observar la deduplicación del recorder: `_lastRecordedId`
/// es privado, así que lo que se comprueba es el comportamiento visible —que
/// vuelva a intentar el guardado, o que no lo haga—.
class _CountingStore extends RecommendationStore {
  _CountingStore({this.result = true});

  bool result;
  int saveCalls = 0;
  final List<String> savedIds = <String>[];

  @override
  Future<bool> save(RecommendationRecord record) async {
    saveCalls++;
    savedIds.add(record.id);
    return result;
  }
}

void main() {
  final DateTime now = DateTime.utc(2026, 8, 3, 12);
  const String deviceId = '3f2504e0-4f89-11d3-9a0c-0305e82c3301';

  final weather = AgronomicWeatherSnapshot(
    lat: 19.4,
    lon: -99.1,
    fetchedAt: now.subtract(const Duration(minutes: 20)),
    source: WeatherSnapshotSource.forecast,
    airTempC: 27,
    airHumidityPct: 44,
    rain: const RainOutlook(probNext24hPct: 10, expectedNext24hMm: 0),
    et0TodayMm: 5.4,
    et0Source: Et0Source.openMeteoFao56,
  );

  /// Déficit real, lectura vigente y sin lluvia: una recomendación registrable.
  IrrigationDecision realDecision() {
    return const IrrigationEngine().decide(
      IrrigationEngineInput(
        now: now,
        moisture: MoistureReading(
          percent: 18,
          isPresent: true,
          measuredAt: now.subtract(const Duration(minutes: 12)),
        ),
        weather: weather,
        deviceId: deviceId,
        cropId: 'maize',
        stageKey: 'vegetative',
        stageLabel: 'Crecimiento vegetativo',
        moistureTarget: const AgroRange(
          lowMax: 20,
          optimalMin: 30,
          optimalMax: 55,
          highMin: 65,
        ),
      ),
    );
  }

  RecommendationRecord realRecord() {
    return RecommendationRecord.fromIrrigationDecision(
      decision: realDecision(),
      deviceId: deviceId,
      readingTimestamp: now,
      userId: 'user-1',
    );
  }

  /// Runtime mínimo con dispositivo y lectura vivos, que es lo único que el
  /// recorder exige para no salirse por la puerta de atrás.
  CropRuntimeSnapshot runtimeSnapshot() {
    return CropRuntimeSnapshot(
      device: const BioGDevice(
        id: deviceId,
        name: 'Sensor norte',
        locationName: 'Lote norte',
        seedId: '',
        profileId: '',
      ),
      live: BioGTelemetry(
        deviceId: deviceId,
        timestamp: now,
        airTempC: 27,
        airHumidityPct: 44,
        soilMoisturePct: 18,
        soilTempC: 22,
        ph: 6.5,
        ec: 1.2,
        resistance: 0.4,
        n: 40,
        p: 20,
        k: 30,
        batteryPct: 80,
        signalRssi: -60,
      ),
      seed: null,
      definition: null,
      profile: null,
      stageResult: null,
      targets: null,
      eval: null,
      nextAlertsState: const AlertsState(),
      cropKeyName: 'maize',
      cropLabel: 'Maíz',
      cropIconAsset: '',
      stageLabel: 'Crecimiento vegetativo',
      sowingStatus: SowingStatus.planted,
      engineSowingDate: null,
      hasSeed: true,
      isPlanted: true,
      isPlanned: false,
      isGenericMode: false,
    );
  }

  group('save() significa "la fila está persistida"', () {
    test('inserción nueva devuelve true sin comprobar nada más', () async {
      final db = _FakeDatabase(insertResult: 1);
      final store = RecommendationStore(testDatabase: () => db);

      expect(await store.save(realRecord()), isTrue);
      expect(db.rawInsertCalls, 1);
      // Si el insert escribió, sobra la consulta de comprobación.
      expect(db.queryCalls, 0);
    });

    test('duplicado legítimo devuelve true, no false', () async {
      // `INSERT OR IGNORE` no escribe porque el id ya estaba: la recomendación
      // SÍ está auditada y no hay nada que reintentar.
      final db = _FakeDatabase(
        insertResult: 0,
        existingRows: const <Map<String, Object?>>[
          <String, Object?>{'id': 'ya-estaba'},
        ],
      );
      final store = RecommendationStore(testDatabase: () => db);

      expect(await store.save(realRecord()), isTrue);
      expect(db.queryCalls, 1);
    });

    test('cero insertados y fila ausente devuelve false', () async {
      final db = _FakeDatabase(
        insertResult: 0,
        existingRows: const <Map<String, Object?>>[],
      );
      final store = RecommendationStore(testDatabase: () => db);

      expect(await store.save(realRecord()), isFalse);
      expect(db.queryCalls, 1);
    });

    test('devuelve false cuando rawInsert lanza, sin propagar', () async {
      final db = _FakeDatabase(insertThrows: true);
      final store = RecommendationStore(testDatabase: () => db);

      // No se relanza: registrar la trazabilidad nunca puede tumbar al Panel.
      expect(await store.save(realRecord()), isFalse);
    });

    test('un fallo transitorio no inutiliza el almacén', () async {
      // La base rechazada no puede dejar el almacén muerto para el resto del
      // proceso: en cuanto la escritura vuelve a ser posible, save funciona.
      final db = _FakeDatabase(insertThrows: true);
      final store = RecommendationStore(testDatabase: () => db);

      expect(await store.save(realRecord()), isFalse);

      db.insertThrows = false;
      db.insertResult = 1;

      expect(await store.save(realRecord()), isTrue);
    });
  });

  group('el recorder solo se fía de lo que se persistió', () {
    test('no marca como registrado si save falló, y reintenta', () async {
      final store = _CountingStore(result: false);
      final recorder = RecommendationRecorder(store: store, clock: () => now);
      final runtime = runtimeSnapshot();
      final decision = realDecision();

      final first = await recorder.recordIrrigation(
        decision: decision,
        runtime: runtime,
      );
      expect(first, isNotNull, reason: 'la interfaz no cambia por el fallo');
      expect(store.saveCalls, 1);

      // Aquí estaba el bug: la deduplicación daba la decisión por auditada y
      // este segundo intento no llegaba nunca al almacén.
      await recorder.recordIrrigation(decision: decision, runtime: runtime);
      expect(store.saveCalls, 2);
      expect(store.savedIds.toSet().length, 1, reason: 'el id es estable');
    });

    test('deduplica cuando save confirmó la persistencia', () async {
      final store = _CountingStore(result: true);
      final recorder = RecommendationRecorder(store: store, clock: () => now);
      final runtime = runtimeSnapshot();
      final decision = realDecision();

      await recorder.recordIrrigation(decision: decision, runtime: runtime);
      await recorder.recordIrrigation(decision: decision, runtime: runtime);
      await recorder.recordIrrigation(decision: decision, runtime: runtime);

      expect(store.saveCalls, 1);
    });

    test('deja de reintentar en cuanto un intento se persiste', () async {
      final store = _CountingStore(result: false);
      final recorder = RecommendationRecorder(store: store, clock: () => now);
      final runtime = runtimeSnapshot();
      final decision = realDecision();

      await recorder.recordIrrigation(decision: decision, runtime: runtime);
      expect(store.saveCalls, 1);

      store.result = true;
      await recorder.recordIrrigation(decision: decision, runtime: runtime);
      expect(store.saveCalls, 2);

      // Ya está auditada: no se vuelve a escribir en cada sincronización.
      await recorder.recordIrrigation(decision: decision, runtime: runtime);
      expect(store.saveCalls, 2);
    });

    test('reset() borra la marca y permite volver a intentarlo', () async {
      final store = _CountingStore(result: true);
      final recorder = RecommendationRecorder(store: store, clock: () => now);
      final runtime = runtimeSnapshot();
      final decision = realDecision();

      await recorder.recordIrrigation(decision: decision, runtime: runtime);
      expect(store.saveCalls, 1);

      recorder.reset();
      await recorder.recordIrrigation(decision: decision, runtime: runtime);
      expect(store.saveCalls, 2);
    });
  });
}
