import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bio_g/services/biog/sync/pending_sync_queue.dart';

/// Pruebas del contrato de la bandeja de salida.
///
/// Lo que se protege aquí es una sola frase: una operación pendiente NO puede
/// desaparecer sin que la nube la haya confirmado. La cola decide borrar o
/// conservar según el handler lance o no («lanza = reintenta»), así que basta
/// con un handler falso para ejercitar las cuatro situaciones que antes
/// perdían datos en silencio.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const String deviceA = 'dev-a';
  const String deviceB = 'dev-b';

  // Un backoff propio y largo: los reintentos no deben dispararse solos a
  // mitad de la prueba, y así lo que se mide es la decisión de la cola, no el
  // paso del tiempo.
  const List<Duration> backoff = <Duration>[Duration(minutes: 5)];

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  PendingSyncOp cropUpsert(String deviceId, {String label = 'v1'}) {
    return PendingSyncOp(
      entity: SyncEntity.cropContext,
      op: SyncOp.upsert,
      entityId: deviceId,
      payload: <String, dynamic>{'deviceId': deviceId, 'label': label},
    );
  }

  test(
    'un adaptador que falla conserva la operación con attempts == 1 y el '
    'reintento en el futuro',
    () async {
      final List<String> intentos = <String>[];
      final PendingSyncQueue queue = PendingSyncQueue(
        handler: (PendingSyncOp op) async {
          intentos.add(op.collapseKey);
          throw Exception('supabase no contesta');
        },
        backoff: backoff,
      );

      final int antes = DateTime.now().millisecondsSinceEpoch;
      await queue.enqueue(cropUpsert(deviceA));
      await queue.drain();

      final List<PendingSyncOp> pendientes = await queue.load();
      expect(
        pendientes,
        hasLength(1),
        reason:
            'un fallo del adaptador no puede borrar el pendiente: ese era el '
            'defecto que dejaba el backoff inalcanzable',
      );
      expect(pendientes.single.entityId, deviceA);
      expect(pendientes.single.attempts, 1);
      expect(pendientes.single.nextAttemptAtMs, greaterThan(antes));
      expect(
        intentos,
        hasLength(1),
        reason: 'el segundo drenado respeta la espera y no reintenta aún',
      );
    },
  );

  test('un adaptador que confirma borra la operación de la bandeja', () async {
    final List<String> subidas = <String>[];
    final PendingSyncQueue queue = PendingSyncQueue(
      handler: (PendingSyncOp op) async {
        subidas.add(op.collapseKey);
      },
      backoff: backoff,
    );

    await queue.enqueue(cropUpsert(deviceA));
    await queue.drain();

    expect(await queue.load(), isEmpty);
    expect(subidas, <String>['cropContext:$deviceA']);
  });

  test('una operación encolada durante un drenado en vuelo NO se pierde', () async {
    final Completer<void> handlerEntro = Completer<void>();
    final Completer<void> sueltaElHandler = Completer<void>();
    final List<String> subidas = <String>[];

    final PendingSyncQueue queue = PendingSyncQueue(
      handler: (PendingSyncOp op) async {
        subidas.add(op.collapseKey);
        if (op.entityId == deviceA) {
          if (!handlerEntro.isCompleted) handlerEntro.complete();
          await sueltaElHandler.future;
        }
      },
      backoff: backoff,
    );

    // A entra y su drenado se queda atrapado dentro del handler, imitando una
    // subida lenta a Supabase.
    await queue.enqueue(cropUpsert(deviceA));
    await handlerEntro.future;

    // B se encola con el drenado de A todavía en vuelo. Este es el instante
    // exacto en el que antes se perdía el dato: el `enqueue` escribía [A, B],
    // su petición de drenado se descartaba por el guard `_draining`, y al
    // terminar el drenado de A éste escribía su `remaining` (vacío) encima,
    // borrando B de disco sin que nadie lo hubiera subido.
    final Future<void> encolarB = queue.enqueue(cropUpsert(deviceB));

    sueltaElHandler.complete();
    await encolarB;
    await queue.drain();

    expect(
      subidas,
      containsAll(<String>['cropContext:$deviceA', 'cropContext:$deviceB']),
      reason: 'B tiene que llegar a subirse, no evaporarse',
    );
    expect(await queue.load(), isEmpty);
  });

  test('collapseKey colapsa ediciones repetidas del mismo dispositivo', () async {
    // Con un handler que siempre falla nada sale de la bandeja, así que lo
    // que quede en disco es exactamente el resultado del colapso.
    final PendingSyncQueue queue = PendingSyncQueue(
      handler: (PendingSyncOp op) async {
        throw Exception('sin red');
      },
      backoff: backoff,
    );

    await queue.enqueue(cropUpsert(deviceA, label: 'v1'));
    await queue.enqueue(cropUpsert(deviceA, label: 'v2'));
    await queue.enqueue(cropUpsert(deviceA, label: 'v3'));
    await queue.enqueue(cropUpsert(deviceB, label: 'otro'));
    await queue.drain();

    final List<PendingSyncOp> pendientes = await queue.load();
    expect(
      pendientes,
      hasLength(2),
      reason: 'una sola entrada por dispositivo, no una por edición',
    );
    expect(
      pendientes.map((PendingSyncOp o) => o.collapseKey).toSet(),
      <String>{'cropContext:$deviceA', 'cropContext:$deviceB'},
    );

    final PendingSyncOp a = pendientes.firstWhere(
      (PendingSyncOp o) => o.entityId == deviceA,
    );
    expect(
      a.payload?['label'],
      'v3',
      reason: 'de cinco ediciones sin señal sólo importa la última',
    );
  });
}
