// test/widgets/account/wizard/wizard_crop_context_resolver_invariant_test.dart
//
// LA PRUEBA DE INVARIANTE DE IDA Y VUELTA
//
// ─────────────────────────────────────────────────────────────────────────────
// QUÉ CIERRA, Y POR QUÉ NO BASTABA CON ARREGLAR LOS CAMPOS
// ─────────────────────────────────────────────────────────────────────────────
//
// `DeviceCropContext` acepta 42 campos y el resolver de Cuenta rellenaba 31.
// Los que faltaban —etiqueta y fuente de ubicación, latitud, longitud, modo de
// establecimiento— se perdían EN SILENCIO cada vez que alguien reconfiguraba su
// cultivo desde Cuenta. Ese es el mecanismo exacto que dejó las coordenadas en
// nulo en producción.
//
// Y el mecanismo importa más que los campos: como es un constructor de
// parámetros con nombre, **omitirlos compila sin un solo aviso**. El usuario
// tampoco ve un error: ve que su respuesta no tuvo efecto.
//
// Arreglar los cinco no resuelve el patrón. Cada propiedad nueva que se añada
// al contexto vuelve a correr el mismo riesgo. Lo que lo cierra es esta prueba:
//
//     contexto original
//           |
//           v
//     reconfigurar el MISMO cultivo  ->  guardar
//           |
//           v
//     TODOS los demás campos deben ser idénticos, uno por uno
//
// Se compara con `toJson()` clave por clave, y NO con igualdad de objeto —el
// modelo no implementa `==`—. Usar el mapa serializado tiene una ventaja que
// una lista de expects escrita a mano no tiene: **cualquier campo que se añada
// al modelo en el futuro entra solo en la comparación**. La prueba falla el día
// que alguien añada una propiedad y olvide propagarla, que es precisamente el
// día en que hay que enterarse.

import 'package:bio_g/models/device_crop_context.dart';
import 'package:bio_g/widgets/account/wizard/wizard_crop_context_resolver.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const resolver = WizardCropContextResolver();

  final DateTime configuredAt = DateTime.utc(2026, 3, 1, 10);
  final DateTime now = DateTime.utc(2026, 8, 11, 12);
  final DateTime sowingDate = DateTime.utc(2026, 4, 15);

  /// Un contexto con TODO relleno. Si un campo se queda en su valor por
  /// omisión, la prueba no puede detectar que se pierde, así que aquí no hay
  /// nulos por comodidad.
  DeviceCropContext original() => DeviceCropContext(
    deviceId: 'dev-1',
    cropCategoryId: 'grain',
    cropId: 'maize',
    profileId: 'maize_generic',
    brandId: 'brand_x',
    varietyId: 'var_y',
    varietyAlias: 'Amarillo',
    calendarTypeId: 'temporal',
    lifecycleStatus: CropLifecycleStatus.planted,
    sowingDate: sowingDate,
    sowingDateConfidence: DateConfidence.exact,
    cultivationScaleId: 'field',
    sowingModeId: 'siembra_directa',
    timezone: 'America/Mexico_City',
    regionCode: 'MX',
    cycleLabel: 'PV 2026',
    establishmentModeId: 'siembra_directa',
    locationLabel: 'Lote norte',
    locationSource: 'gps',
    geoLat: 19.4326,
    geoLng: -99.1332,
    soilTextureId: 'clayLoam',
    soilTextureSource: 'declared',
    soilLocalDescriptors: const <String>['roja', 'volcanica'],
    soilLocalOther: 'tierra colorada',
    setupStatus: kCropSetupCompleted,
    setupCompletedAt: configuredAt,
    catalogVersion: 'v1',
    source: CropConfigSource.wizard,
    configuredAt: configuredAt,
    updatedAt: configuredAt,
  );

  /// Compara los dos contextos campo por campo, ignorando solo los que la
  /// operación bajo prueba tenía permitido cambiar.
  void expectOnlyTheseChanged(
    DeviceCropContext before,
    DeviceCropContext after,
    Set<String> allowedToChange,
  ) {
    final a = before.toJson();
    final b = after.toJson();

    expect(
      b.keys.toSet(),
      a.keys.toSet(),
      reason: 'La serialización cambió de forma: hay un campo nuevo o menos.',
    );

    for (final key in a.keys) {
      if (allowedToChange.contains(key)) continue;
      expect(
        b[key],
        a[key],
        reason:
            'El campo «$key» cambió sin que nadie se lo pidiera. Es el patrón '
            'que esta prueba existe para atrapar: una propiedad nueva en '
            'DeviceCropContext que el resolver no propaga. Añádela al '
            'constructor de WizardCropContextResolver.resolve.',
      );
    }
  }

  group('WizardCropContextResolver · invariante de ida y vuelta', () {
    test(
      'reconfigurar el MISMO cultivo no toca ubicación, suelo ni alta',
      () {
        final before = original();

        // El caso real: el usuario abre Cuenta, vuelve a pasar por el wizard y
        // confirma lo mismo. Nada de la parcela debería moverse.
        final after = resolver.resolve(
          deviceId: before.deviceId,
          cropCategoryId: before.cropCategoryId,
          cropId: before.cropId,
          lifecycleStatus: before.lifecycleStatus,
          dateConfidence: before.sowingDateConfidence,
          now: now,
          previous: before,
          brandId: before.brandId,
          varietyId: before.varietyId,
          varietyAlias: before.varietyAlias,
          selectedDate: before.sowingDate,
          timezone: before.timezone,
          cultivationScaleId: before.cultivationScaleId,
        );

        expectOnlyTheseChanged(before, after, <String>{
          // `updatedAt` DEBE moverse: es la marca de última escritura.
          'updatedAt',
          // El wizard no captura estos dos; los sella el almacén con
          // `markSetupCompleted`, así que aquí llegan en su valor por omisión.
          // Duplicar esa decisión en dos sitios es como nacen las
          // contradicciones.
          'setupStatus',
          'setupCompletedAt',
          // ── Campos DERIVADOS, no arrastrados ──────────────────────────────
          //
          // Estos seis los RESUELVE el resolver contra el catálogo cada vez: el
          // perfil sale del cultivo y la variedad, el alias visible de si la
          // variedad existe en el catálogo, el modo de siembra del estado del
          // ciclo. No son datos del usuario que haya que conservar, y por eso
          // están fuera de la comprobación estricta.
          //
          // Lo que la prueba sí vigila —y donde estaba el defecto— es todo lo
          // demás: ubicación, coordenadas, suelo, escala, zona horaria, región,
          // etiqueta de ciclo y modo de establecimiento.
          'profileId',
          'brandId',
          'varietyId',
          'varietyAlias',
          'calendarTypeId',
          'sowingModeId',
        });
      },
    );

    test('cambiar de cultivo tampoco borra la tierra ni la ubicación', () {
      final before = original();

      // La textura no cambia si mañana se siembra frijol en vez de maíz. Es la
      // razón por la que el tipo de suelo vive con la parcela y no con el
      // cultivo, y por la que no entra en las cascadas de limpieza.
      final after = resolver.resolve(
        deviceId: before.deviceId,
        cropCategoryId: 'grain',
        cropId: 'bean',
        lifecycleStatus: CropLifecycleStatus.planted,
        dateConfidence: DateConfidence.exact,
        now: now,
        previous: before,
        selectedDate: sowingDate,
      );

      expect(after.soilTextureId, 'clayLoam');
      expect(after.soilTextureSource, 'declared');
      expect(after.soilLocalDescriptors, <String>['roja', 'volcanica']);
      expect(after.soilLocalOther, 'tierra colorada');
      expect(after.locationLabel, 'Lote norte');
      expect(after.locationSource, 'gps');
      expect(after.geoLat, 19.4326);
      expect(after.geoLng, -99.1332);
      expect(after.establishmentModeId, 'siembra_directa');
    });

    test('la escala de cultivo YA NO se nulifica en ornamentales', () {
      final before = original().copyWith(
        cropCategoryId: 'ornamental',
        cropId: 'cactus',
        cultivationScaleId: 'pot',
      );

      final after = resolver.resolve(
        deviceId: before.deviceId,
        cropCategoryId: 'ornamental',
        cropId: 'cactus',
        lifecycleStatus: CropLifecycleStatus.planted,
        dateConfidence: DateConfidence.estimated,
        now: now,
        previous: before,
        cultivationScaleId: 'pot',
      );

      // Una rosa en maceta y una rosa en cama son riegos distintos. Y los
      // ornamentales son exactamente los cultivos que necesitan el perfil de
      // sustrato: nulificar la escala les borraba el dato justo a ellos.
      expect(after.cultivationScaleId, 'pot');
    });
  });

  group('Edición de suelo desde Cuenta · invariante', () {
    test('cambiar SOLO el tipo de suelo no toca ningún otro campo', () {
      final before = original();

      // Es exactamente lo que hace `SoilTextureAccountScreen`: `copyWith` con
      // los cuatro campos de suelo. Un `copyWith` no puede omitir nada, porque
      // lo que no se nombra no se toca; esta prueba lo deja escrito como
      // contrato en vez de como costumbre.
      final after = before.copyWith(
        soilTextureId: 'sandy',
        soilTextureSource: 'guided_estimate',
        soilLocalDescriptors: const <String>['negra'],
        soilLocalOther: null,
        updatedAt: now,
      );

      expectOnlyTheseChanged(before, after, <String>{
        'soilTextureId',
        'soilTextureSource',
        'soilLocalDescriptors',
        'soilLocalOther',
        'updatedAt',
      });

      expect(after.soilTextureId, 'sandy');
      expect(after.soilTextureSource, 'guided_estimate');
      expect(after.soilLocalOther, isNull);
    });

    test('los campos de suelo sobreviven a una vuelta por JSON', () {
      // `fromJson` no es el inverso exacto de `toJson`: aplica canonicalización
      // de ornamentales y migración de contextos legacy, así que comparar el
      // mapa entero mezclaría dos cosas. Aquí se comprueba lo que este trabajo
      // añadió, incluida la distinción que más importa: `null` («no había
      // campo») frente a `'unknown'` («el productor dijo que no sabe»).
      final before = original();
      final after = DeviceCropContext.decode(before.encode());

      expect(after.soilTextureId, before.soilTextureId);
      expect(after.soilTextureSource, before.soilTextureSource);
      expect(after.soilLocalDescriptors, before.soilLocalDescriptors);
      expect(after.soilLocalOther, before.soilLocalOther);

      final declaredUnknown = before.copyWith(
        soilTextureId: 'unknown',
        soilTextureSource: 'unknown',
      );
      final neverAsked = before.copyWith(
        soilTextureId: null,
        soilTextureSource: null,
      );

      expect(
        DeviceCropContext.decode(declaredUnknown.encode()).soilTextureId,
        'unknown',
      );
      expect(
        DeviceCropContext.decode(neverAsked.encode()).soilTextureId,
        isNull,
        reason:
            'Nulo y «unknown» tienen que seguir siendo distinguibles: uno mide '
            'adopción y el otro es una respuesta del productor.',
      );
    });
  });
}
