/// =========================================================================
/// EXPRESIÓN DE LA DOSIS
/// =========================================================================
///
/// EL PROBLEMA
/// -----------
/// Hasta ahora el cálculo y la unidad venían soldados: la misma función que
/// calculaba cuánto fertilizante hacía falta decidía también si eso se decía
/// en kg/ha, en g/m² o en gramos por maceta. Eso obligaba a tocar el cálculo
/// cada vez que aparecía una forma de producir distinta.
///
/// Y apareció una. Un productor de invernadero **no tiene hectáreas** en el
/// sentido operativo: fertirriega. Necesita gramos por planta, y muchas veces
/// por planta y por día, porque va inyectando en cada riego. Haifa ni siquiera
/// publica sus tablas de invernadero en totales por hectárea — las publica en
/// kg/ha/día por fase. Son dos idiomas para el mismo cálculo.
///
/// LA SEPARACIÓN
/// -------------
/// El motor calcula **una sola cosa**: cuántos kilos de nutriente puro hacen
/// falta por hectárea. Esta capa toma ese número y lo dice en la unidad en la
/// que el productor compra y aplica.
///
/// **El número no cambia. Cambia cómo se dice.** Por eso es un cambio de
/// presentación y no una cirugía del motor.
///
/// LA ARITMÉTICA, VALIDADA
/// -----------------------
/// Tomate de invernadero, 10 kg de fruto por planta, coeficiente de absorción
/// de 4.5 kg N por tonelada:
///
///   10 kg × 4.5 kg/t = 45 g de N por planta
///   45 g × 25 000 plantas/ha ÷ 1000 = 1 125 kg N/ha para 250 t/ha
///
/// Haifa publica 676 kg N/ha para 150 t/ha. Escalado a 250 t/ha da 1 127.
/// Cuadra al kilo, y por los dos caminos.
/// =========================================================================
library;

/// Cómo aplica el productor. Determina el idioma de la recomendación, no la
/// cantidad.
enum ApplicationMethod {
  /// Al voleo o en banda, sobre superficie. El idioma es por hectárea.
  broadcast,

  /// Por el agua de riego —goteo, fertirriego, hidroponía—. El idioma es por
  /// planta, y cuando se conoce la fase, por planta y por día.
  fertigation,

  /// A mano, planta por planta o maceta por maceta.
  manual,

  /// No se sabe. Se conserva el comportamiento de siempre.
  unknown,
}

ApplicationMethod applicationMethodFromId(String? id) {
  final String raw = (id ?? '').trim().toLowerCase();
  if (raw.isEmpty) return ApplicationMethod.unknown;
  return switch (raw) {
    'broadcast' || 'voleo' || 'al_voleo' || 'banda' || 'suelo' =>
      ApplicationMethod.broadcast,
    'fertigation' ||
    'fertirriego' ||
    'fertirrigacion' ||
    'fertirrigación' ||
    'goteo' ||
    'drip' ||
    'invernadero' ||
    'greenhouse' ||
    'hidroponia' ||
    'hidroponía' => ApplicationMethod.fertigation,
    'manual' || 'a_mano' || 'mano' || 'planta_por_planta' =>
      ApplicationMethod.manual,
    _ => ApplicationMethod.unknown,
  };
}

String applicationMethodLabelEs(ApplicationMethod m) => switch (m) {
  ApplicationMethod.broadcast => 'al voleo',
  ApplicationMethod.fertigation => 'por fertirriego',
  ApplicationMethod.manual => 'a mano',
  ApplicationMethod.unknown => 'sin especificar',
};

/// Todo lo que hace falta para decir la dosis en el idioma correcto.
///
/// Es deliberadamente pequeño y todo opcional: si no llega nada, el motor se
/// comporta exactamente como antes de que esta capa existiera.
class DoseContext {
  const DoseContext({
    this.method = ApplicationMethod.unknown,
    this.plantsPerHectare,
    this.phaseDays,
    this.phaseLabelEs,
  });

  final ApplicationMethod method;

  /// Plantas por hectárea. Sin este dato no se puede pasar de por hectárea a
  /// por planta, y el motor no lo inventa: se queda en kg/ha y lo dice.
  final double? plantsPerHectare;

  /// Días que dura la fase actual. Solo con esto tiene sentido un número
  /// diario, que es como se maneja realmente un fertirriego.
  final int? phaseDays;

  final String? phaseLabelEs;

  static const DoseContext none = DoseContext();

  /// ¿Se debe expresar por planta?
  ///
  /// Solo cuando el productor fertirriega **y** se conoce la densidad. Con
  /// una de las dos cosas no alcanza: sin densidad el número por planta sería
  /// inventado, y sin fertirriego el productor de campo abierto prefiere su
  /// kg/ha de siempre.
  bool get expressPerPlant =>
      method == ApplicationMethod.fertigation &&
      plantsPerHectare != null &&
      plantsPerHectare! > 0 &&
      plantsPerHectare!.isFinite;

  /// ¿Se puede además dar un número diario?
  bool get expressPerDay =>
      expressPerPlant &&
      phaseDays != null &&
      phaseDays! > 0 &&
      phaseDays! <= 400;

  DoseContext copyWith({
    ApplicationMethod? method,
    double? plantsPerHectare,
    int? phaseDays,
    String? phaseLabelEs,
  }) {
    return DoseContext(
      method: method ?? this.method,
      plantsPerHectare: plantsPerHectare ?? this.plantsPerHectare,
      phaseDays: phaseDays ?? this.phaseDays,
      phaseLabelEs: phaseLabelEs ?? this.phaseLabelEs,
    );
  }
}

/// Convierte kg/ha a la unidad que toca y lo escribe.
class DoseExpression {
  const DoseExpression._();

  /// Plantas por hectárea a partir del marco de plantación.
  ///
  ///     plantas/ha = 10 000 ÷ (distancia entre hileras × distancia entre plantas)
  ///
  /// La misma fórmula aparece literal en las guías de nogal y de durazno de
  /// BIO-G. Se expone aquí para que exista un solo lugar donde vive.
  static double? plantsPerHectareFromSpacing({
    double? rowSpacingM,
    double? plantSpacingM,
  }) {
    if (rowSpacingM == null || plantSpacingM == null) return null;
    if (rowSpacingM <= 0 || plantSpacingM <= 0) return null;
    if (!rowSpacingM.isFinite || !plantSpacingM.isFinite) return null;
    final double d = 10000.0 / (rowSpacingM * plantSpacingM);
    return d.isFinite && d > 0 ? d : null;
  }

  /// Gramos de nutriente por planta a partir de kg/ha.
  ///
  ///     g/planta = kg/ha × 1000 ÷ plantas/ha
  static double? gramsPerPlant({
    required double kgPerHectare,
    required double? plantsPerHectare,
  }) {
    if (plantsPerHectare == null ||
        plantsPerHectare <= 0 ||
        !plantsPerHectare.isFinite) {
      return null;
    }
    final double g = (kgPerHectare * 1000.0) / plantsPerHectare;
    return g.isFinite && g > 0 ? g : null;
  }

  /// Gramos por metro cuadrado. 1 kg/ha = 0.1 g/m².
  static double gramsPerSquareMeter(double kgPerHectare) =>
      kgPerHectare * 0.1;

  /// Redondeo de presentación: la precisión mostrada no debe superar la que
  /// el número realmente tiene.
  ///
  /// Nadie dosifica 3.847 g por planta ni compra 104.3 kg de urea.
  static String formatGrams(double g) {
    if (g < 1) return g.toStringAsFixed(2);
    if (g < 10) return g.toStringAsFixed(1);
    if (g < 100) return ((g / 5).round() * 5).toString();
    return ((g / 10).round() * 10).toString();
  }

  /// Texto principal de la dosis, en el idioma del productor.
  ///
  /// Devuelve `null` cuando no aplica esta capa —campo abierto al voleo, o
  /// fertirriego sin densidad conocida— para que el llamador conserve su
  /// comportamiento de siempre. Nunca inventa un número.
  static String? renderPerPlant({
    required double kgPerHectarePure,
    required String nutrientOrSourceName,
    required DoseContext ctx,
  }) {
    if (!ctx.expressPerPlant) return null;

    final double? g = gramsPerPlant(
      kgPerHectare: kgPerHectarePure,
      plantsPerHectare: ctx.plantsPerHectare,
    );
    if (g == null || g < 0.01) return null;

    final String base = '${formatGrams(g)} g de $nutrientOrSourceName por planta';
    if (!ctx.expressPerDay) return base;

    final double perDay = g / ctx.phaseDays!;
    if (perDay < 0.005) return base;

    final String fase =
        ctx.phaseLabelEs == null ? '' : ' de ${ctx.phaseLabelEs}';
    return '$base — o ${formatGrams(perDay)} g por planta al día durante los '
        '${ctx.phaseDays} días$fase';
  }

  /// Nota que deja a la vista de dónde salió la conversión.
  ///
  /// Sin esto, un número por planta parece medido cuando en realidad se
  /// derivó de una densidad supuesta.
  static String? transparencyEs({
    required double kgPerHectarePure,
    required DoseContext ctx,
  }) {
    if (!ctx.expressPerPlant) return null;
    final double d = ctx.plantsPerHectare!;
    return 'Equivale a ${kgPerHectarePure.round()} kg/ha de nutriente puro, '
        'repartidos entre ${d.round()} plantas por hectárea.';
  }
}
