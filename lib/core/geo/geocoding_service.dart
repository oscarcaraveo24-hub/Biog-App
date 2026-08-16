// lib/core/geo/geocoding_service.dart
//
// Traducir entre coordenadas y nombres de lugar. Un solo sitio.
//
// Antes esta lógica estaba duplicada en dos pantallas —la de Ubicación y el
// asistente de alta— con resultados distintos: la de Ubicación sabía arreglar
// las direcciones rurales y quitar los plus codes, y el asistente devolvía
// `formatted_address` tal cual. El mismo punto del mapa producía
// «Camino a Satevó s/n, Chihuahua, Chih., México» en una pantalla y
// «52JHG+Q8 Chihuahua, Chih., México» en la otra.
//
// ── Por qué importan los plus codes ──────────────────────────────────────────
//
// Google devuelve un plus code («52JHG+Q8 Chihuahua…») cuando el punto no cae
// sobre una dirección postal, que es EL CASO NORMAL de una parcela. Como
// etiqueta es inservible: el productor no reconoce su terreno en un código
// alfanumérico. Cuando aparece uno, se reconstruye el nombre a partir de los
// componentes administrativos, que sí son legibles.

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'package:bio_g/core/config/maps_api_key.dart';

/// Por qué falló una consulta de geocodificación.
enum GeocodingFailure {
  /// No hay llave de Google Maps en este binario ni guardada de un arranque
  /// anterior. Es un fallo de configuración, no de red.
  missingApiKey,

  /// Google respondió, pero no encontró nada para esa consulta.
  notFound,

  /// Red caída, tiempo agotado, o Google devolvió un error.
  network,
}

@immutable
class GeocodingException implements Exception {
  const GeocodingException(this.kind, [this.detail]);

  final GeocodingFailure kind;
  final String? detail;

  /// Texto listo para enseñar. Cada motivo dice qué hacer, no solo qué pasó.
  String get userMessage {
    switch (kind) {
      case GeocodingFailure.missingApiKey:
        return 'Falta la llave de Google Maps. Arranca una vez con '
            '--dart-define=GOOGLE_MAPS_API_KEY=...';
      case GeocodingFailure.notFound:
        return 'No se encontró esa ubicación.';
      case GeocodingFailure.network:
        return 'No se pudo buscar. Revisa tu conexión.';
    }
  }

  @override
  String toString() => 'GeocodingException(${kind.name}, $detail)';
}

/// Un lugar resuelto: dónde está y cómo se llama.
@immutable
class GeocodedPlace {
  const GeocodedPlace({
    required this.lat,
    required this.lng,
    required this.label,
  });

  final double lat;
  final double lng;
  final String label;
}

class GeocodingService {
  const GeocodingService({this.timeout = const Duration(seconds: 12)});

  final Duration timeout;

  static const String _base = 'https://maps.googleapis.com/maps/api/geocode/json';

  /// Etiqueta legible para unas coordenadas.
  ///
  /// Lanza [GeocodingException] en vez de devolver un texto de relleno: quien
  /// llame decide si conserva la etiqueta que ya tenía o avisa. Devolver
  /// «Ubicación seleccionada» desde aquí hacía imposible distinguir «Google no
  /// conoce este punto» de «no hubo red», y la pantalla acababa pisando un
  /// nombre bueno con uno genérico cada vez que fallaba la conexión.
  Future<String> reverseGeocode(
    double lat,
    double lng, {
    String language = 'es',
  }) async {
    final String key = await MapsApiKey.resolve();
    if (key.isEmpty) {
      throw const GeocodingException(GeocodingFailure.missingApiKey);
    }

    final Uri uri = Uri.parse(
      '$_base?latlng=$lat,$lng&key=$key&language=$language',
    );

    final Map<String, dynamic> data = await _getJson(uri);
    final String status = (data['status'] ?? '').toString();

    if (status == 'ZERO_RESULTS') {
      throw const GeocodingException(GeocodingFailure.notFound);
    }
    if (status != 'OK') {
      throw GeocodingException(GeocodingFailure.network, status);
    }

    final String label = _bestLabel(data);
    if (label.isEmpty) {
      throw const GeocodingException(GeocodingFailure.notFound);
    }
    return label;
  }

  /// Coordenadas y nombre para una búsqueda escrita a mano.
  Future<GeocodedPlace> search(String query, {String language = 'es'}) async {
    final String q = query.trim();
    if (q.isEmpty) {
      throw const GeocodingException(GeocodingFailure.notFound, 'consulta vacía');
    }

    final String key = await MapsApiKey.resolve();
    if (key.isEmpty) {
      throw const GeocodingException(GeocodingFailure.missingApiKey);
    }

    final Uri uri = Uri.parse(
      '$_base?address=${Uri.encodeComponent(q)}&key=$key&language=$language',
    );

    final Map<String, dynamic> data = await _getJson(uri);
    final String status = (data['status'] ?? '').toString();

    if (status == 'ZERO_RESULTS') {
      throw const GeocodingException(GeocodingFailure.notFound);
    }
    if (status != 'OK') {
      throw GeocodingException(GeocodingFailure.network, status);
    }

    final List<dynamic> results = (data['results'] as List?) ?? const [];
    if (results.isEmpty) {
      throw const GeocodingException(GeocodingFailure.notFound);
    }

    final dynamic loc = (results.first as Map)['geometry']?['location'];
    if (loc is! Map) {
      throw const GeocodingException(GeocodingFailure.notFound, 'sin geometry');
    }

    final num? rawLat = loc['lat'] as num?;
    final num? rawLng = loc['lng'] as num?;
    if (rawLat == null || rawLng == null) {
      throw const GeocodingException(GeocodingFailure.notFound, 'sin lat/lng');
    }

    final String label = _bestLabel(data);
    return GeocodedPlace(
      lat: rawLat.toDouble(),
      lng: rawLng.toDouble(),
      label: label.isEmpty ? q : label,
    );
  }

  Future<Map<String, dynamic>> _getJson(Uri uri) async {
    try {
      final http.Response res = await http.get(uri).timeout(timeout);
      if (res.statusCode != 200) {
        throw GeocodingException(
          GeocodingFailure.network,
          'HTTP ${res.statusCode}',
        );
      }
      final dynamic decoded = jsonDecode(res.body);
      if (decoded is! Map<String, dynamic>) {
        throw const GeocodingException(
          GeocodingFailure.network,
          'respuesta no es un objeto',
        );
      }
      return decoded;
    } on GeocodingException {
      rethrow;
    } catch (e) {
      throw GeocodingException(GeocodingFailure.network, e.toString());
    }
  }

  // ── Construcción de la etiqueta ───────────────────────────────────────────

  /// Ej: "52JHG+Q8 Chihuahua, Chih., México"
  static final RegExp _plusCode = RegExp(r'^[A-Z0-9]{4,}\+[A-Z0-9]{2,}\b');
  static final RegExp _plusCodePrefix = RegExp(
    r'^[A-Z0-9]{4,}\+[A-Z0-9]{2,}\s*,?\s*',
  );

  static bool _looksLikePlusCode(String s) => _plusCode.hasMatch(s.trim());

  static String _stripPlusCode(String s) =>
      s.trim().replaceFirst(_plusCodePrefix, '').trim();

  static String _bestLabel(Map<String, dynamic> data) {
    final List<dynamic> results = (data['results'] as List?) ?? const [];
    if (results.isEmpty) return '';

    for (final dynamic r in results) {
      if (r is! Map) continue;
      final String formatted = (r['formatted_address'] ?? '').toString().trim();
      if (formatted.isEmpty) continue;

      if (!_looksLikePlusCode(formatted)) return formatted;

      // Plus code: se reconstruye desde los componentes administrativos.
      final List<dynamic> comps =
          (r['address_components'] as List?) ?? const [];
      final String built = _fromComponents(comps);
      if (built.isNotEmpty) return built;

      final String stripped = _stripPlusCode(formatted);
      if (stripped.isNotEmpty) return stripped;
    }

    final dynamic first = results.first;
    if (first is Map) {
      return _fromComponents((first['address_components'] as List?) ?? const []);
    }
    return '';
  }

  static String _pick(List<dynamic> comps, List<String> types) {
    for (final dynamic c in comps) {
      if (c is! Map) continue;
      final List<String> t =
          (c['types'] as List?)?.map((dynamic e) => e.toString()).toList() ??
          const <String>[];
      final String name = (c['long_name'] ?? '').toString().trim();
      if (name.isEmpty) continue;
      if (types.any(t.contains)) return name;
    }
    return '';
  }

  /// Nombre legible a partir de los componentes: calle si la hay, y después la
  /// jerarquía administrativa sin repetir niveles que traen el mismo texto.
  static String _fromComponents(List<dynamic> comps) {
    final String route = _pick(comps, const ['route']);
    final String streetNo = _pick(comps, const ['street_number']);
    final String locality = _pick(comps, const ['locality']);
    final String admin2 = _pick(comps, const ['administrative_area_level_2']);
    final String admin1 = _pick(comps, const ['administrative_area_level_1']);
    final String country = _pick(comps, const ['country']);

    final List<String> parts = <String>[
      if (route.isNotEmpty) streetNo.isNotEmpty ? '$route $streetNo' : route,
      if (locality.isNotEmpty) locality,
      if (admin2.isNotEmpty && admin2 != locality) admin2,
      if (admin1.isNotEmpty && admin1 != admin2) admin1,
      if (country.isNotEmpty) country,
    ];

    return parts.join(', ');
  }
}
