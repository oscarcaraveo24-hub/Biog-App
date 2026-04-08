/// Escala operativa de cultivo.
///
/// Determina unidades, factores de conversión, terminología y la UX que
/// el usuario ve en toda la app.
enum CultivationScale {
  /// Parcela agrícola (hectáreas). Modelo BIO-G Campo.
  field,

  /// Huerto / cama de cultivo (metros cuadrados). Modelo BIO-G Huerto.
  bed,

  /// Maceta / contenedor individual. Modelo BIO-G Maceta.
  pot,
}

// ──────────────────────────────────────────────────────────
//  Modelo comercial BIO-G
// ──────────────────────────────────────────────────────────

/// Modelo de hardware comercial del dispositivo BIO-G.
enum BioGDeviceModel {
  campo,
  huerto,
  maceta,
}

// ──────────────────────────────────────────────────────────
//  Resolvers
// ──────────────────────────────────────────────────────────

/// Resuelve la escala operativa por defecto a partir del modelo de dispositivo.
CultivationScale defaultScaleForModel(BioGDeviceModel model) {
  return switch (model) {
    BioGDeviceModel.campo => CultivationScale.field,
    BioGDeviceModel.huerto => CultivationScale.bed,
    BioGDeviceModel.maceta => CultivationScale.pot,
  };
}

/// Intenta parsear un [CultivationScale] desde un string serializado.
///
/// Acepta tanto los nombres canónicos del enum (`field`, `bed`, `pot`)
/// como alias legacy que puedan venir de onboarding o imports.
CultivationScale? cultivationScaleFromId(String? id) {
  if (id == null || id.trim().isEmpty) return null;
  final normalized = id.trim().toLowerCase();
  return switch (normalized) {
    'field' || 'campo' => CultivationScale.field,
    'bed' || 'orchard' || 'huerto' || 'cama' || 'm2' => CultivationScale.bed,
    'pot' || 'maceta' || 'plant' || 'planta' => CultivationScale.pot,
    _ => null,
  };
}

/// Intenta parsear un [BioGDeviceModel] desde un string serializado.
BioGDeviceModel? deviceModelFromId(String? id) {
  if (id == null || id.trim().isEmpty) return null;
  final normalized = id.trim().toLowerCase();
  return switch (normalized) {
    'campo' || 'field' => BioGDeviceModel.campo,
    'huerto' || 'orchard' || 'bed' => BioGDeviceModel.huerto,
    'maceta' || 'pot' => BioGDeviceModel.maceta,
    _ => null,
  };
}

// ──────────────────────────────────────────────────────────
//  Copy / terminología por escala
// ──────────────────────────────────────────────────────────

/// Texto y terminología localizada (ES) para cada escala.
///
/// Ejemplo: `CultivationScaleCopy.of(CultivationScale.field).doseUnit`
/// → `'kg/ha'`.
class CultivationScaleCopy {
  const CultivationScaleCopy._({
    required this.labelEs,
    required this.shortLabelEs,
    required this.doseUnit,
    required this.areaUnit,
    required this.locationTermEs,
    required this.actionVerbEs,
    required this.surfaceContextEs,
  });

  /// Nombre completo visible al usuario.
  final String labelEs;

  /// Nombre corto para badges / chips.
  final String shortLabelEs;

  /// Unidad de dosis (ej. `kg/ha`, `g/m²`, `g/maceta`).
  final String doseUnit;

  /// Unidad de área (ej. `ha`, `m²`, `maceta`).
  final String areaUnit;

  /// Término para la ubicación del cultivo.
  final String locationTermEs;

  /// Verbo de acción principal (ej. `fertilizar`, `aplicar`).
  final String actionVerbEs;

  /// Contexto de superficie para textos descriptivos.
  final String surfaceContextEs;

  static const CultivationScaleCopy _field = CultivationScaleCopy._(
    labelEs: 'Campo abierto',
    shortLabelEs: 'Campo',
    doseUnit: 'kg/ha',
    areaUnit: 'ha',
    locationTermEs: 'parcela',
    actionVerbEs: 'fertilizar',
    surfaceContextEs: 'por hectárea',
  );

  static const CultivationScaleCopy _bed = CultivationScaleCopy._(
    labelEs: 'Huerto / cama',
    shortLabelEs: 'Huerto',
    doseUnit: 'g/m²',
    areaUnit: 'm²',
    locationTermEs: 'cama',
    actionVerbEs: 'aplicar',
    surfaceContextEs: 'por metro cuadrado',
  );

  static const CultivationScaleCopy _pot = CultivationScaleCopy._(
    labelEs: 'Maceta',
    shortLabelEs: 'Maceta',
    doseUnit: 'g/maceta',
    areaUnit: 'maceta',
    locationTermEs: 'maceta',
    actionVerbEs: 'aplicar',
    surfaceContextEs: 'por maceta',
  );

  /// Obtiene la capa de texto para la [scale] dada.
  static CultivationScaleCopy of(CultivationScale scale) {
    return switch (scale) {
      CultivationScale.field => _field,
      CultivationScale.bed => _bed,
      CultivationScale.pot => _pot,
    };
  }
}
