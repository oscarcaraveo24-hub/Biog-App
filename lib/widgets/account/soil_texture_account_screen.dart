// lib/widgets/account/soil_texture_account_screen.dart
//
// Corregir el tipo de suelo después del alta.
//
// ─────────────────────────────────────────────────────────────────────────────
// POR QUÉ ESTA PANTALLA TIENE QUE EXISTIR
// ─────────────────────────────────────────────────────────────────────────────
//
// «No estoy seguro» es una respuesta de primera clase: nadie se atasca por no
// saber qué tierra tiene. Pero sin un camino para corregirla después, esa
// opción honesta se convierte en una **trampa permanente**: el productor que la
// eligió y luego lo averiguó no tiene forma de decirlo, y BIO-G sigue usando
// tierra media con menos confianza para siempre.
//
// ─────────────────────────────────────────────────────────────────────────────
// POR QUÉ NO ES UN PASO DENTRO DEL WIZARD DE CULTIVO
// ─────────────────────────────────────────────────────────────────────────────
//
// Porque el tipo de suelo es atributo de la PARCELA, no del cultivo. Meterlo en
// el flujo de reconfiguración obligaría a contestarlo cada vez que alguien
// cambia de maíz a frijol, cuando la tierra no ha cambiado. El wizard de
// cultivo lo **conserva**; esta pantalla lo **edita**. Son dos verbos distintos.
//
// ─────────────────────────────────────────────────────────────────────────────
// CÓMO SE GUARDA, Y POR QUÉ ASÍ
// ─────────────────────────────────────────────────────────────────────────────
//
// Con `copyWith` sobre el contexto que ya existe, nombrando solo los tres
// campos que cambian. No se reconstruye el objeto entero.
//
// Es la forma constructivamente a prueba del bug que motivó la prueba de
// invariante: un constructor de 38 parámetros con nombre deja omitir campos sin
// un solo aviso del compilador, y así es como se perdieron las coordenadas en
// producción. Un `copyWith` no puede omitir nada, porque lo que no se nombra no
// se toca.

import 'package:flutter/material.dart';

import 'package:bio_g/core/agro/water/soil_profile_resolver.dart';
import 'package:bio_g/core/agro/water/soil_texture_source.dart';
import 'package:bio_g/core/crops/crop_registry.dart';
import 'package:bio_g/models/device_crop_context.dart';
import 'package:bio_g/services/biog/biog_store.dart';
import 'package:bio_g/widgets/account/wizard/configure_seed_wizard_pages.dart';
import 'package:bio_g/theme/bio_g_theme.dart';
import 'package:bio_g/widgets/shared/bio_g_button.dart';

class SoilTextureAccountScreen extends StatefulWidget {
  const SoilTextureAccountScreen({super.key});

  @override
  State<SoilTextureAccountScreen> createState() =>
      _SoilTextureAccountScreenState();
}

class _SoilTextureAccountScreenState extends State<SoilTextureAccountScreen> {
  String? _textureId;
  String? _textureSource;

  bool _hydrated = false;
  bool _dirty = false;
  bool _saving = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_hydrated) return;
    _hydrated = true;

    final ctx = BioGScope.of(context).activeCropContext;
    if (ctx == null) return;

    // Contrato de doble uso: en Cuenta se abre DIRECTAMENTE en el valor ya
    // guardado, no en una vista inicial neutra.
    _textureId = ctx.soilTextureId;
    _textureSource = ctx.soilTextureSource;
  }

  Future<void> _save() async {
    if (_saving) return;
    final store = BioGScope.of(context);
    final DeviceCropContext? previous = store.activeCropContext;
    if (previous == null) return;

    setState(() => _saving = true);
    try {
      await store.saveCropContext(
        // Solo se nombran los campos que cambian. Todo lo demás —ubicación,
        // coordenadas, fechas, variedad, etapa, estado del alta— viaja intacto
        // por construcción, no por disciplina.
        //
        // Los nombres locales ya NO se nombran aquí. Volcarlos era una foto
        // tomada al abrir la pantalla: si el contexto cambiaba entre tanto —otra
        // pantalla, una sincronización— guardar el tipo de suelo revertía por el
        // camino lo que hubiera escrito el otro. Lo que no se nombra en un
        // `copyWith` viaja intacto, que es exactamente lo que se quiere.
        previous.copyWith(
          soilTextureId: _textureId,
          soilTextureSource: _textureSource,
          updatedAt: DateTime.now().toUtc(),
        ),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tipo de suelo actualizado.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudo guardar: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  /// El medio ya resuelto: es quien sabe que el hardware manda sobre la escala
  /// y sobre la textura declarada.
  ResolvedSoilProfile? _profileFor(DeviceCropContext ctx) =>
      SoilProfileResolver.resolve(
        deviceModelId: BioGScope.of(context).activeDevice?.deviceModelId,
        cultivationScaleId: ctx.cultivationScaleId,
        soilTextureId: ctx.soilTextureId,
        soilTextureSourceId: ctx.soilTextureSource,
        cropKey: CropRegistry.byKeyName(ctx.cropId)?.cropKey,
      );

  @override
  Widget build(BuildContext context) {
    final store = BioGScope.of(context);
    final ctx = store.activeCropContext;

    // Con un equipo de maceta el medio es sustrato y la textura mineral no
    // aplica. Dejar el selector activo sería una trampa: el usuario elegiría,
    // vería «Tipo de suelo actualizado» y el motor seguiría usando sustrato.
    // Se dice y se retira el control, en vez de decirlo y dejarlo puesto.
    final bool substrate =
        ctx != null && (_profileFor(ctx)?.texture.isSubstrate ?? false);

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8F7),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Tipo de suelo',
          style: TextStyle(
            fontSize: 16.5,
            fontWeight: FontWeight.w700,
            color: BioGTheme.charcoal,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF6D757A)),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: SafeArea(
        child: ctx == null
            ? const _NoContextNotice()
            : Column(
                children: <Widget>[
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(6, 4, 6, 20),
                      child: Column(
                        children: <Widget>[
                          // ── El selector va PRIMERO ────────────────────────
                          //
                          // El banner de estado vivía aquí arriba, y en un
                          // teléfono de 390 px sus tres renglones —«Ahora mismo
                          // BIO-G usa una tierra media y baja la confianza…»—
                          // empujaban la esfera hacia abajo lo justo para que
                          // retención y drenaje quedaran fuera del primer
                          // pantallazo. El productor entraba a esta pantalla a
                          // ELEGIR una tierra y lo primero que veía era un
                          // párrafo explicando por qué todavía no la tiene.
                          //
                          // Ahora la pregunta va arriba y el estado abajo, que
                          // es además el orden natural de lectura: primero
                          // elijo, luego confirmo qué queda guardado.
                          if (!substrate)
                            // El MISMO widget que el onboarding, montado por la
                            // página de doble uso. Un segundo selector de tierra
                            // sería un segundo sitio donde arreglar cada detalle
                            // de movimiento, accesibilidad y copy.
                            SoilTexturePage(
                              // Esta pantalla ya trae su propio scroll y su
                              // barra de título.
                              scrollable: false,
                              showBrandMark: false,
                              // Aquí ya hay barra de título: la hojita del
                              // onboarding sería el segundo encabezado seguido
                              // antes de la primera esfera.
                              showLeadingMark: false,
                              selectedTextureId: _textureId,
                              onTextureChanged: (texture, source) {
                                setState(() {
                                  _textureId = texture.id;
                                  _textureSource = source.id;
                                  _dirty = true;
                                });
                              },
                            ),
                          const SizedBox(height: 14),
                          _CurrentSourceBanner(context_: ctx),
                        ],
                      ),
                    ),
                  ),
                  if (!substrate)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                      child: BioGButton(
                        label: 'Guardar cambios',
                        height: 54,
                        radius: 18,
                        loading: _saving,
                        // En Cuenta ya hay una respuesta guardada, así que el
                        // botón no arranca deshabilitado por falta de
                        // interacción; se habilita cuando de verdad hay algo que
                        // guardar.
                        //
                        // Desde que los nombres locales salieron de la pantalla,
                        // la única fuente de `_dirty` es elegir una textura, y
                        // elegirla siempre deja `_textureId` no nulo. La segunda
                        // condición se conserva por explícita, no por necesaria.
                        onTap: (_dirty && _textureId != null) ? _save : null,
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}

class _CurrentSourceBanner extends StatelessWidget {
  // `context_` para no chocar con el `BuildContext` del `build`.
  const _CurrentSourceBanner({required this.context_});

  final DeviceCropContext context_;

  @override
  Widget build(BuildContext context) {
    final profile = SoilProfileResolver.resolve(
      deviceModelId: BioGScope.of(context).activeDevice?.deviceModelId,
      cultivationScaleId: context_.cultivationScaleId,
      soilTextureId: context_.soilTextureId,
      soilTextureSourceId: context_.soilTextureSource,
      // El cultivo decide la variante del sustrato. Ver la nota en
      // `account_screen._soilTypeSubtitle`.
      cropKey: CropRegistry.byKeyName(context_.cropId)?.cropKey,
    );

    final source = SoilTextureSource.fromId(context_.soilTextureSource);

    final String text;
    if (profile.texture.isSubstrate) {
      // Sustrato: el medio lo decidió el equipo o la escala, y la textura
      // mineral no aplica. Decirlo es más honesto que dejar al usuario elegir
      // algo que el resolver va a ignorar.
      text =
          'Tu BIO-G está configurado para maceta, así que BIO-G usa un '
          'sustrato (${profile.texture.displayNameEs.toLowerCase()}) en vez de '
          'una tierra de parcela.';
    } else if (profile.isFallback) {
      text =
          'Ahora mismo BIO-G usa una tierra media y baja la confianza de la '
          'recomendación de riego. En cuanto elijas la tuya, los umbrales se '
          'ajustan solos.';
    } else {
      text =
          'Tu tierra está registrada como ${profile.texture.displayNameEs} '
          '(${profile.texture.shortLabelEs.toLowerCase()})'
          '${source == null ? '' : ' · ${source.labelEs.toLowerCase()}'}.';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        decoration: BoxDecoration(
          color: profile.isFallback
              ? const Color(0xFFFFF6E6)
              : const Color(0xFFF1F5F2),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Icon(
              profile.isFallback
                  ? Icons.info_outline_rounded
                  : Icons.check_circle_outline_rounded,
              size: 18,
              color: profile.isFallback
                  ? const Color(0xFFB58B2B)
                  : BioGTheme.green700,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(
                  fontSize: 12.6,
                  height: 1.38,
                  color: Color(0xFF5A6B6F),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoContextNotice extends StatelessWidget {
  const _NoContextNotice();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              Icons.landscape_outlined,
              size: 44,
              color: Colors.black.withValues(alpha: 0.18),
            ),
            const SizedBox(height: 14),
            const Text(
              'Todavía no hay una parcela configurada',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: BioGTheme.charcoal,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Configura tu cultivo desde Cuenta y después podrás ajustar aquí '
              'el tipo de suelo de tu parcela.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13.2,
                height: 1.42,
                color: Colors.black.withValues(alpha: 0.45),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
