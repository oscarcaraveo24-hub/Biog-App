// lib/core/agro/nutrition/nutrition_guides.dart
//
// TABLA DE GUÍAS NUTRICIONALES CURADAS — resultado de la auditoría de guías
// (Guía v0.4, fase 2 y §34).
//
// Cada entrada declara, para un cultivo: fuentes citables, plan de temporada
// por nutriente (siempre como rango y en la forma declarada: N elemental, P₂O₅,
// K₂O), reglas por etapa con sus ventanas y su importancia agronómica, fuentes
// comerciales y reglas 3R. Nada de esto sale de la sonda.
//
// ESTATUS: TODAS las guías entran como `GuideAuditStatus.proposed` con su
// fuente. El agricultor NO ve rangos de dosis hasta que el equipo revise un
// cultivo y lo marque `audited` (Guía v0.4, §10). Mientras tanto la app sigue
// abriendo ventanas por etapa (eso sí se muestra) y explica que la cifra está
// pendiente de auditoría. Ver `docs/AUDITORIA_GUIAS_NUTRICION_2026-09.md`.
//
// CÓMO LEER UN PLAN DE TEMPORADA
// ------------------------------
// · Los rangos son para producción comercial de riego en México a rendimiento
//   medio (el rendimiento supuesto va en `notesEs`). Temporal o bajo insumo:
//   tomar el mínimo o menos. Siempre ajustar con análisis de suelo.
// · `seasonShare` reparte ese plan entre ventanas; la suma por nutriente no
//   pasa de 1.0. Con la guía auditada, `windowDoseFor` multiplica plan × share.
// · `isCritical` marca la ventana cuyo cierre SIN evidencia de fertilización
//   puede pesar en el score histórico (Guía v0.4 §6, matiz del 05-sep-2026).
//   Se reserva a las ventanas donde la literatura documenta pérdida de
//   rendimiento por omisión (p. ej. N de V6–V8 en maíz, N de amacollamiento en
//   trigo, K de llenado en solanáceas). Las ventanas de fondo/siembra no se
//   marcan: suelen ocurrir antes de instalar la sonda o durante el aprendizaje.
//
// CONVENCIÓN DE CLAVES DE ETAPA
// -----------------------------
// `StageNutritionRule.normalizeStageKey` baja a minúsculas y quita `_`, `-` y
// espacios, así que aquí se escriben tal cual las declara cada motor:
// cereales `vegEarly`, `tillering`…; solanáceas `establecimiento`, `cuajado`…;
// frutales `budbreak`, `fruit_fill`…; ornamentales `bud_formation`…
import 'package:bio_g/core/agro/agro_types.dart';
import 'package:bio_g/core/agro/nutrition/nutrition_guide.dart';
import 'package:bio_g/core/agro/nutrition/nutrition_types.dart';

// ═══════════════════════════════════════════════════════════════════════════
// FUENTES COMPARTIDAS
// ═══════════════════════════════════════════════════════════════════════════

const GuideSource _srcMapaGuia = GuideSource(
  labelEs:
      'MAPA (España), Guía práctica de la fertilización racional de los '
      'cultivos, parte II (cereales, leguminosas, hortícolas)',
  url: 'https://www.mapa.gob.es/dam/mapa/contenido/agricultura/publicaciones/01_fertilizacion-baja-.pdf',
  year: 2010,
);

const GuideSource _srcCdfaGuidelines = GuideSource(
  labelEs: 'CDFA-FREP / UC Davis, California Crop Fertilization Guidelines',
  url: 'https://www.cdfa.ca.gov/is/ffldrs/frep/FertilizationGuidelines/',
  year: 2023,
);

const GuideSource _srcIntagriFrijol = GuideSource(
  labelEs: 'Intagri, Fertilización del cultivo de frijol (extracción por tonelada)',
  url: 'https://www.intagri.com/articulos/nutricion-vegetal/fertilizacion-del-cultivo-de-frijol',
  year: 2017,
);

// Reglas 3R que aplican a casi todo cultivo de campo y se repiten poco.
const List<String> _rulesCommonField = <String>[
  'Aplica con el suelo húmedo y riega o incorpora después: el fertilizante '
      'seco sobre suelo seco no llega a la raíz y se pierde.',
  'Fracciona el nitrógeno: la parte grande va en la ventana de mayor demanda, '
      'no toda en siembra.',
  'El fósforo se coloca en banda al fondo, cerca de la raíz; en cobertera se '
      'aprovecha poco.',
];

const List<String> _rulesVegetableFertigation = <String>[
  'En fertirriego reparte la dosis semanal en varios riegos cortos; en riego '
      'rodado concentra en las escardas.',
  'Con CE de suelo alta baja la dosis y sube la lámina de lavado: más sal no '
      'es más nutrición.',
];

// ═══════════════════════════════════════════════════════════════════════════
// CEREALES
// ═══════════════════════════════════════════════════════════════════════════

const NutritionGuide _maize = NutritionGuide(
  cropKey: 'maize',
  cropLabelEs: 'Maíz',
  auditStatus: GuideAuditStatus.proposed,
  sources: <GuideSource>[
    GuideSource(
      labelEs: 'Yara México, Resumen nutricional del maíz',
      url: 'https://www.yara.com.mx/nutricion-vegetal/maiz/resumen-nutricional/',
      year: 2024,
    ),
    _srcMapaGuia,
    GuideSource(
      labelEs:
          'CIMMYT / MasAgro, Menú de tecnologías validadas: maíz de riego en '
          'Sinaloa (plataformas Ahome y Culiacán)',
      url: 'https://cgspace.cgiar.org/server/api/core/bitstreams/c75a0be7-16c5-4d16-9204-4502aecdf2ca/content',
      year: 2022,
    ),
    GuideSource(
      labelEs:
          'INIFAP CENID-RASPA, La fertilización en los cultivos de maíz '
          '(folleto técnico; referencia regional, verificar en auditoría)',
      url: 'http://cenid-raspa.inifap.gob.mx/demo/modulo/Folletos%20tecnicos/2005/La%20Fertilizaci%C3%B3n%20en%20los%20cultivos%20de%20ma%C3%ADz.pdf',
      year: 2005,
    ),
  ],
  seasonPlan: <AgroMetricKey, SeasonNutrientPlan>{
    AgroMetricKey.n: SeasonNutrientPlan(
      form: NutrientForm.n,
      minKgPerHa: 160,
      maxKgPerHa: 240,
      sourceEs: 'Yara MX, MAPA y plataformas CIMMYT-Sinaloa',
      notesEs:
          'Para 8–12 t/ha de grano en riego. Yara: >200 kg N/ha absorbidos a '
          '7 t/ha; MAPA: 259 kg N/ha para 12 t/ha; Sinaloa: 173–304 kg N/ha '
          'validados. Temporal: 80–120.',
    ),
    AgroMetricKey.p: SeasonNutrientPlan(
      form: NutrientForm.p2o5,
      minKgPerHa: 40,
      maxKgPerHa: 80,
      sourceEs: 'Yara MX (≈85 kg P₂O₅/ha absorbidos a 7 t) y Sinaloa (40)',
      notesEs: 'Todo al fondo. Con Olsen-P > 20 ppm basta el mínimo.',
    ),
    AgroMetricKey.k: SeasonNutrientPlan(
      form: NutrientForm.k2o,
      minKgPerHa: 0,
      maxKgPerHa: 60,
      sourceEs: 'Sinaloa (48 kg K₂O/ha) y análisis de suelo',
      notesEs:
          'Muchos suelos agrícolas de México son ricos en K; solo con análisis '
          'bajo (< 100 ppm) se justifica el máximo.',
    ),
  },
  stageRules: <StageNutritionRule>[
    StageNutritionRule(
      stageKeys: <String>{'germination', 'emergence'},
      windowNutrients: <AgroMetricKey>{AgroMetricKey.p, AgroMetricKey.k, AgroMetricKey.n},
      seasonShare: <AgroMetricKey, double>{
        AgroMetricKey.n: 0.33,
        AgroMetricKey.p: 1.0,
        AgroMetricKey.k: 1.0,
      },
      labelEs: 'Fertilización de fondo',
      timingEs: 'Presiembra o a la siembra, en banda a un lado y debajo de la semilla.',
      rationaleEs:
          'El fósforo pesa más al arranque: raíz, energía y uniformidad de '
          'plantas. Un tercio del N acompaña para que la planta no llegue corta '
          'a V6.',
      rulesEs: <String>[
        'No pongas urea en contacto con la semilla: quema la germinación.',
      ],
    ),
    StageNutritionRule(
      stageKeys: <String>{'vegEarly', 'vegMid'},
      windowNutrients: <AgroMetricKey>{AgroMetricKey.n},
      seasonShare: <AgroMetricKey, double>{AgroMetricKey.n: 0.67},
      isCritical: true,
      labelEs: 'Segunda fertilización (V6–V8)',
      timingEs:
          'Entre V6 y V8 (planta de 40–60 cm), antes de que cierre el surco y '
          'con riego o lluvia enseguida.',
      rationaleEs:
          'Desde V6 hacia floración el maíz captura más de la mitad del N y el '
          '80 % del K de todo el ciclo. Llegar corto aquí es lo que más '
          'rendimiento cuesta.',
      rulesEs: <String>[
        'Incorpora la urea o riega en las 24 h siguientes; en superficie y con '
            'calor se volatiliza.',
        'Si el suelo viene seco no apliques: espera al riego y aplica con él.',
      ],
    ),
    StageNutritionRule(
      stageKeys: <String>{'vegAdvanced', 'tasseling', 'flowerSet'},
      windowNutrients: <AgroMetricKey>{},
      labelEs: 'Espigamiento y floración',
      rationaleEs:
          'Todavía hay demanda, pero la utilidad de corregir cae: lo que no '
          'entró antes de V10 rinde poco.',
      rulesEs: <String>[
        'Evita N tardío en pivote o surco cerrado: no llega y retrasa la madurez.',
      ],
    ),
  ],
  sourceOptionsEs: <AgroMetricKey, List<String>>{
    AgroMetricKey.n: <String>['Urea (46-0-0)', 'Sulfato de amonio (21-0-0-24S)', 'UAN 32'],
    AgroMetricKey.p: <String>['MAP (11-52-0)', 'DAP (18-46-0)', 'Superfosfato triple'],
    AgroMetricKey.k: <String>['Cloruro de potasio (0-0-60)', 'Sulfato de potasio (0-0-50)'],
  },
  generalRulesEs: _rulesCommonField,
  notesEs:
      'Plan para grano de riego a 8–12 t/ha. En Sinaloa las plataformas '
      'validaron 173 kg N/ha con sensor frente a 304 convencionales al mismo '
      'rendimiento (19 t/ha): más N no es más grano.',
);

const NutritionGuide _wheat = NutritionGuide(
  cropKey: 'wheat',
  cropLabelEs: 'Trigo',
  auditStatus: GuideAuditStatus.proposed,
  sources: <GuideSource>[
    GuideSource(
      labelEs:
          'Revista Fitotecnia Mexicana, Uso eficiente de N en aplicaciones '
          'fraccionadas con ¹⁵N en trigo (Bajío): 240-60-00 tradicional; mejor '
          '30 % siembra + 70 % amacollamiento',
      url: 'https://www.scielo.org.mx/scielo.php?script=sci_arttext&pid=S0187-73802022000400437',
      year: 2022,
    ),
    GuideSource(
      labelEs:
          'Terra Latinoamericana, Fertilizantes de solubilidad controlada en '
          'trigo en El Bajío (recomendación regional 280 N – 80 P₂O₅)',
      url: 'https://www.scielo.org.mx/scielo.php?script=sci_arttext&pid=S0187-57792012000200121',
      year: 2012,
    ),
    GuideSource(
      labelEs:
          'Panorama Agropecuario, Guía de manejo del trigo (valles de Sinaloa: '
          '180–220 kg N/ha, 60–100 P₂O₅, 2/3 presiembra + 1/3 primer riego)',
      url: 'https://panorama-agro.com/?page_id=872',
    ),
    _srcCdfaGuidelines,
    _srcMapaGuia,
  ],
  seasonPlan: <AgroMetricKey, SeasonNutrientPlan>{
    AgroMetricKey.n: SeasonNutrientPlan(
      form: NutrientForm.n,
      minKgPerHa: 180,
      maxKgPerHa: 240,
      sourceEs: 'Bajío 240-60-00; Sinaloa 180–220; California 168–224',
      notesEs:
          'Para 5–7 t/ha en riego. Extracción 28–40 kg N por tonelada (MAPA). '
          'Suelos barriales con alto residual: mínimo.',
    ),
    AgroMetricKey.p: SeasonNutrientPlan(
      form: NutrientForm.p2o5,
      minKgPerHa: 40,
      maxKgPerHa: 80,
      sourceEs: 'Bajío 60; Sinaloa 60–100',
      notesEs: 'Todo en presiembra; en suelos calcáreos cuida la disponibilidad.',
    ),
    AgroMetricKey.k: SeasonNutrientPlan(
      form: NutrientForm.k2o,
      minKgPerHa: 0,
      maxKgPerHa: 40,
      sourceEs: 'Análisis de suelo (respuesta improbable con K > 60 ppm, CDFA)',
    ),
  },
  stageRules: <StageNutritionRule>[
    StageNutritionRule(
      stageKeys: <String>{'germination', 'emergence', 'vegEarly'},
      windowNutrients: <AgroMetricKey>{AgroMetricKey.p, AgroMetricKey.n, AgroMetricKey.k},
      seasonShare: <AgroMetricKey, double>{
        AgroMetricKey.n: 0.35,
        AgroMetricKey.p: 1.0,
        AgroMetricKey.k: 1.0,
      },
      labelEs: 'Fertilización de siembra',
      timingEs: 'Presiembra o a la siembra, con todo el fósforo.',
      rationaleEs:
          'El P colocado desde siembra da raíz y macollos uniformes; el N de '
          'arranque no debe pasar de un tercio: el fraccionamiento 30–70 rindió '
          '8 % más que el 50–50 tradicional en El Bajío.',
    ),
    StageNutritionRule(
      stageKeys: <String>{'tillering', 'elongation'},
      windowNutrients: <AgroMetricKey>{AgroMetricKey.n},
      seasonShare: <AgroMetricKey, double>{AgroMetricKey.n: 0.65},
      isCritical: true,
      labelEs: 'Amacollamiento (primer riego de auxilio)',
      timingEs:
          'Al amacollamiento, con el primer riego de auxilio (no más de 45 días '
          'desde siembra) y antes del encañe.',
      rationaleEs:
          'El N de amacollamiento define cuántas espigas se forman; entre encañe '
          'y espigamiento el trigo toma ~60 % de su N. Es la ventana que más '
          'rendimiento decide.',
      rulesEs: <String>[
        'Aplica justo antes del riego para que el N baje a la zona de raíces.',
        'Dosis altas de N sin K suficiente aumentan el acame.',
      ],
    ),
    StageNutritionRule(
      stageKeys: <String>{'booting', 'heading', 'flowering'},
      windowNutrients: <AgroMetricKey>{},
      labelEs: 'Espigamiento y floración',
      rationaleEs:
          'N en espigamiento ya casi no sube rendimiento; solo proteína, con '
          'riesgo de acame si te pasas.',
    ),
  ],
  sourceOptionsEs: <AgroMetricKey, List<String>>{
    AgroMetricKey.n: <String>['Urea (46-0-0)', 'Sulfato de amonio (21-0-0-24S)', 'Amoniaco anhidro en riego'],
    AgroMetricKey.p: <String>['MAP (11-52-0)', 'Superfosfato triple'],
    AgroMetricKey.k: <String>['Cloruro de potasio (0-0-60)'],
  },
  generalRulesEs: _rulesCommonField,
  notesEs:
      'Plan para grano de riego a 5–7 t/ha (Bajío, Sinaloa). Las dosis '
      'regionales llegan a 200–350 kg N/ha con eficiencias por debajo del 40 %; '
      'el fraccionamiento importa más que subir la dosis.',
);

const NutritionGuide _barley = NutritionGuide(
  cropKey: 'barley',
  cropLabelEs: 'Cebada',
  auditStatus: GuideAuditStatus.proposed,
  sources: <GuideSource>[
    GuideSource(
      labelEs:
          'INIFAP / Agricultura Técnica en México, Alina: cebada maltera para '
          'riego en El Bajío (120 N – 60 P a la siembra)',
      url: 'https://www.scielo.org.mx/scielo.php?script=sci_arttext&pid=S0568-25172009000400012',
      year: 2009,
    ),
    GuideSource(
      labelEs: 'INIFAP, Cebada maltera de temporal en Valles Altos de México',
      url: 'https://www.gob.mx/inifap/articulos/cebada-maltera-de-temporal-en-valles-altos-de-mexico',
    ),
    _srcMapaGuia,
  ],
  seasonPlan: <AgroMetricKey, SeasonNutrientPlan>{
    AgroMetricKey.n: SeasonNutrientPlan(
      form: NutrientForm.n,
      minKgPerHa: 100,
      maxKgPerHa: 160,
      sourceEs: 'Alina (Bajío riego) 120; MAPA por rendimiento',
      notesEs:
          'Para 4–6 t/ha en riego; temporal Valles Altos 60–90. Cebada maltera: '
          'no pases del rango, la proteína alta se rechaza en malta.',
    ),
    AgroMetricKey.p: SeasonNutrientPlan(
      form: NutrientForm.p2o5,
      minKgPerHa: 40,
      maxKgPerHa: 60,
      sourceEs: 'Alina (Bajío) 60',
      notesEs: 'Todo a la siembra.',
    ),
    AgroMetricKey.k: SeasonNutrientPlan(
      form: NutrientForm.k2o,
      minKgPerHa: 0,
      maxKgPerHa: 40,
      sourceEs: 'Análisis de suelo',
    ),
  },
  stageRules: <StageNutritionRule>[
    StageNutritionRule(
      stageKeys: <String>{'germination', 'emergence', 'vegEarly'},
      windowNutrients: <AgroMetricKey>{AgroMetricKey.p, AgroMetricKey.n, AgroMetricKey.k},
      seasonShare: <AgroMetricKey, double>{
        AgroMetricKey.n: 0.5,
        AgroMetricKey.p: 1.0,
        AgroMetricKey.k: 1.0,
      },
      labelEs: 'Fertilización de siembra',
      timingEs: 'A la siembra, con todo el fósforo y la mitad del N.',
      rationaleEs:
          'P al arranque para enraizar y macollar parejo; en riego la '
          'recomendación regional pone la dosis completa a la siembra.',
    ),
    StageNutritionRule(
      stageKeys: <String>{'tillering', 'elongation'},
      windowNutrients: <AgroMetricKey>{AgroMetricKey.n},
      seasonShare: <AgroMetricKey, double>{AgroMetricKey.n: 0.5},
      isCritical: true,
      labelEs: 'Amacollamiento',
      timingEs: 'Entre amacollamiento e inicio de encañe, con riego.',
      rationaleEs:
          'El N de amacollamiento define macollos y espigas; después de encañe '
          'solo sube proteína.',
      rulesEs: <String>[
        'Cebada maltera: nada de N tardío, la proteína del grano se dispara y '
            'la malta se rechaza.',
      ],
    ),
    StageNutritionRule(
      stageKeys: <String>{'booting', 'heading', 'flowering', 'grainFill'},
      windowNutrients: <AgroMetricKey>{},
      labelEs: 'Espigamiento y llenado',
      rationaleEs: 'Ventana cerrada para N: en maltera es contraproducente.',
    ),
  ],
  sourceOptionsEs: <AgroMetricKey, List<String>>{
    AgroMetricKey.n: <String>['Urea (46-0-0)', 'Sulfato de amonio (21-0-0-24S)'],
    AgroMetricKey.p: <String>['MAP (11-52-0)', 'DAP (18-46-0)'],
    AgroMetricKey.k: <String>['Cloruro de potasio (0-0-60)'],
  },
  generalRulesEs: _rulesCommonField,
  notesEs: 'Plan para cebada maltera de riego (Bajío) a 4–6 t/ha.',
);

const NutritionGuide _oat = NutritionGuide(
  cropKey: 'oat',
  cropLabelEs: 'Avena',
  auditStatus: GuideAuditStatus.proposed,
  sources: <GuideSource>[
    GuideSource(
      labelEs:
          'Revista Mexicana de Ciencias Agrícolas / Redalyc, Producción y '
          'contenido nutrimental en avena forrajera con fuentes químicas y '
          'orgánicas (200 kg/ha 18-46-00 a siembra + 200 kg/ha urea a los 50 días)',
      url: 'https://www.redalyc.org/jatsRepo/610/61050549007/html/index.html',
      year: 2018,
    ),
    GuideSource(
      labelEs:
          'INIFAP Zacatecas, Componentes tecnológicos para el cultivo de avena '
          'forrajera (paquete tecnológico; verificar dosis en auditoría)',
      url: 'https://inifap-nortecentro.gob.mx/nodos/paquetes_tecnologicos/2024/zacatecas/PAQUETE_TECNOL%C3%93GICO_AVENA_FORRAJERA.pdf',
      year: 2024,
    ),
    _srcMapaGuia,
  ],
  seasonPlan: <AgroMetricKey, SeasonNutrientPlan>{
    AgroMetricKey.n: SeasonNutrientPlan(
      form: NutrientForm.n,
      minKgPerHa: 80,
      maxKgPerHa: 140,
      sourceEs: 'Estudio Redalyc (≈128 kg N/ha) y paquetes INIFAP norte',
      notesEs: 'Forraje de riego (8–12 t MS/ha). Temporal: 40–60.',
    ),
    AgroMetricKey.p: SeasonNutrientPlan(
      form: NutrientForm.p2o5,
      minKgPerHa: 40,
      maxKgPerHa: 60,
      sourceEs: 'Estudio Redalyc (≈92 kg P₂O₅/ha vía DAP) y paquetes INIFAP',
      notesEs: 'Todo a la siembra.',
    ),
    AgroMetricKey.k: SeasonNutrientPlan(
      form: NutrientForm.k2o,
      minKgPerHa: 0,
      maxKgPerHa: 40,
      sourceEs: 'Análisis de suelo',
    ),
  },
  stageRules: <StageNutritionRule>[
    StageNutritionRule(
      stageKeys: <String>{'germination', 'emergence', 'vegEarly'},
      windowNutrients: <AgroMetricKey>{AgroMetricKey.p, AgroMetricKey.n, AgroMetricKey.k},
      seasonShare: <AgroMetricKey, double>{
        AgroMetricKey.n: 0.4,
        AgroMetricKey.p: 1.0,
        AgroMetricKey.k: 1.0,
      },
      labelEs: 'Fertilización de siembra',
      timingEs: 'A la siembra, con todo el fósforo.',
      rationaleEs: 'P al arranque favorece raíz y vigor temprano, sobre todo en suelo frío.',
    ),
    StageNutritionRule(
      stageKeys: <String>{'tillering', 'elongation'},
      windowNutrients: <AgroMetricKey>{AgroMetricKey.n},
      seasonShare: <AgroMetricKey, double>{AgroMetricKey.n: 0.6},
      isCritical: true,
      labelEs: 'Amacollamiento',
      timingEs: 'Al amacollamiento, con el primer riego de auxilio.',
      rationaleEs:
          'El N de amacollamiento impulsa macollos y panículas: es donde más '
          'forraje devuelve cada kilo.',
      rulesEs: <String>[
        'N cerca de espigamiento sube proteína pero también el acame si el tallo '
            'no es fuerte.',
      ],
    ),
  ],
  sourceOptionsEs: <AgroMetricKey, List<String>>{
    AgroMetricKey.n: <String>['Urea (46-0-0)', 'Sulfato de amonio (21-0-0-24S)'],
    AgroMetricKey.p: <String>['DAP (18-46-0)', 'MAP (11-52-0)'],
    AgroMetricKey.k: <String>['Cloruro de potasio (0-0-60)'],
  },
  generalRulesEs: _rulesCommonField,
  notesEs: 'Plan para avena forrajera de riego en el norte-centro de México.',
);

// ═══════════════════════════════════════════════════════════════════════════
// LEGUMINOSAS
// ═══════════════════════════════════════════════════════════════════════════

const NutritionGuide _bean = NutritionGuide(
  cropKey: 'bean',
  cropLabelEs: 'Frijol',
  auditStatus: GuideAuditStatus.proposed,
  sources: <GuideSource>[
    _srcIntagriFrijol,
    GuideSource(
      labelEs:
          'Panorama Agropecuario, Guía de manejo del frijol (40–60 kg N/ha tras '
          'leguminosa u hortaliza; 80–100 tras cereal; P por análisis)',
      url: 'https://panorama-agro.com/?page_id=134',
    ),
    _srcMapaGuia,
    GuideSource(
      labelEs:
          'INIFAP, paquetes tecnológicos de frijol de riego (fórmulas 40-40-00 '
          'a 60-40-00; referencia regional, verificar en auditoría)',
    ),
  ],
  seasonPlan: <AgroMetricKey, SeasonNutrientPlan>{
    AgroMetricKey.n: SeasonNutrientPlan(
      form: NutrientForm.n,
      minKgPerHa: 30,
      maxKgPerHa: 60,
      sourceEs: 'INIFAP 40-40-00 / Panorama 40–60 tras leguminosa',
      notesEs:
          'N de arranque, antes de que la planta nodule: el frijol fija N del '
          'aire. Tras cereal con residuo o con mala nodulación sube a 80–100.',
    ),
    AgroMetricKey.p: SeasonNutrientPlan(
      form: NutrientForm.p2o5,
      minKgPerHa: 40,
      maxKgPerHa: 60,
      sourceEs: 'INIFAP 40; MAPA 40–70 para > 2 t/ha',
      notesEs: 'Todo a la siembra: sin P la nodulación arranca mal.',
    ),
    AgroMetricKey.k: SeasonNutrientPlan(
      form: NutrientForm.k2o,
      minKgPerHa: 0,
      maxKgPerHa: 40,
      sourceEs: 'Análisis de suelo (extracción 55 kg K por tonelada, Intagri)',
    ),
  },
  stageRules: <StageNutritionRule>[
    StageNutritionRule(
      stageKeys: <String>{'germination', 'emergence'},
      windowNutrients: <AgroMetricKey>{AgroMetricKey.p, AgroMetricKey.n, AgroMetricKey.k},
      seasonShare: <AgroMetricKey, double>{
        AgroMetricKey.n: 0.6,
        AgroMetricKey.p: 1.0,
        AgroMetricKey.k: 1.0,
      },
      labelEs: 'Fertilización de siembra',
      timingEs: 'A la siembra, en banda; todo el P y la mayor parte del N de arranque.',
      rationaleEs:
          'El P es vital para que el frijol nodule bien desde el arranque; el N '
          'de arranque cubre las semanas en que los nódulos aún no fijan.',
    ),
    StageNutritionRule(
      stageKeys: <String>{'vegEarly', 'vegAdvanced'},
      windowNutrients: <AgroMetricKey>{AgroMetricKey.n},
      seasonShare: <AgroMetricKey, double>{AgroMetricKey.n: 0.4},
      labelEs: 'Primera escarda (antes de floración)',
      timingEs: 'En la primera escarda, antes de que abra la primera flor.',
      rationaleEs:
          'Segunda aplicación de la práctica regional: sostiene el vigor hasta '
          'floración sin inhibir la nodulación.',
      rulesEs: <String>[
        'Con nodulación buena (nódulos rosados por dentro) esta cobertera puede '
            'reducirse: el exceso de N apaga los nódulos.',
      ],
    ),
    StageNutritionRule(
      stageKeys: <String>{'flowering', 'podSet', 'grainFill'},
      windowNutrients: <AgroMetricKey>{},
      labelEs: 'Floración y llenado de vaina',
      rationaleEs:
          'Aquí el frijol usa N para proteína y K para regular agua; lo que '
          'rinde es no estresar la planta, no fertilizar tarde.',
    ),
  ],
  sourceOptionsEs: <AgroMetricKey, List<String>>{
    AgroMetricKey.n: <String>['Urea (46-0-0)', 'Sulfato de amonio (21-0-0-24S)'],
    AgroMetricKey.p: <String>['DAP (18-46-0)', 'MAP (11-52-0)', 'Superfosfato triple'],
    AgroMetricKey.k: <String>['Sulfato de potasio (0-0-50)', 'Cloruro de potasio (0-0-60)'],
  },
  generalRulesEs: _rulesCommonField,
  notesEs:
      'Plan para frijol de riego a 1.5–2.5 t/ha. Extracción por tonelada: '
      '53.5 kg N, 7.8 kg P, 55.5 kg K (Intagri).',
);

// ═══════════════════════════════════════════════════════════════════════════
// SOLANÁCEAS Y CUCURBITÁCEAS
// (etapas: germinacion, establecimiento, vegetativo, floracion, cuajado,
//  llenado, cosechaProgresiva, finCiclo)
// ═══════════════════════════════════════════════════════════════════════════

const List<String> _rulesFruitVegetables = <String>[
  'Reduce el N cuando los primeros frutos viran de color: el N tardío ablanda '
      'fruto y retrasa la madurez.',
  'Mantén la humedad pareja durante cuajado y llenado: el K y el Ca solo '
      'llegan al fruto con agua estable.',
  ..._rulesVegetableFertigation,
];

const NutritionGuide _tomato = NutritionGuide(
  cropKey: 'tomato',
  cropLabelEs: 'Tomate',
  auditStatus: GuideAuditStatus.proposed,
  sources: <GuideSource>[
    GuideSource(
      labelEs:
          'Agroes, Abonado del tomate: extracciones y dosis (campo abierto '
          '55–65 t/ha: 200–240 N, 65–90 P₂O₅, 300–330 K₂O)',
      url: 'https://www.agroes.es/cultivos-agricultura/cultivos-huerta-horticultura/tomate/498-tomate-dosis-de-nutrientes-para-abonado-cultivo',
    ),
    GuideSource(
      labelEs:
          'CDFA-FREP, Tomato fertilization guideline (< 30 % del N antes de '
          'cuajado; 220–330 lb K₂O/acre removidos a 45 t/acre)',
      url: 'https://www.cdfa.ca.gov/is/ffldrs/frep/FertilizationGuidelines/Tomato.html',
      year: 2023,
    ),
    GuideSource(
      labelEs:
          'INIFAP, Manejo eficiente del agua y nutrición de jitomate en sistemas '
          'intensivos (referencia regional, verificar en auditoría)',
      url: 'https://www.gob.mx/inifap/es/articulos/manejo-eficiente-del-agua-y-nutricion-de-jitomate-solanum-lycopersicum-l-en-sistemas-intensivos',
    ),
  ],
  seasonPlan: <AgroMetricKey, SeasonNutrientPlan>{
    AgroMetricKey.n: SeasonNutrientPlan(
      form: NutrientForm.n,
      minKgPerHa: 180,
      maxKgPerHa: 240,
      sourceEs: 'Agroes 200–240 (riego rodado; −15 % en goteo)',
      notesEs: 'Campo abierto a 55–65 t/ha. Extracción 2.5–3.5 kg N por tonelada.',
    ),
    AgroMetricKey.p: SeasonNutrientPlan(
      form: NutrientForm.p2o5,
      minKgPerHa: 60,
      maxKgPerHa: 100,
      sourceEs: 'Agroes 65–90; CDFA 50–100 lb/acre según Olsen-P',
    ),
    AgroMetricKey.k: SeasonNutrientPlan(
      form: NutrientForm.k2o,
      minKgPerHa: 250,
      maxKgPerHa: 330,
      sourceEs: 'Agroes 300–330; CDFA remoción 220–330 lb K₂O/acre',
      notesEs: 'Extracción 5–5.5 kg K por tonelada: el tomate es un cultivo de potasio.',
    ),
  },
  stageRules: <StageNutritionRule>[
    StageNutritionRule(
      stageKeys: <String>{'germinacion', 'establecimiento'},
      windowNutrients: <AgroMetricKey>{AgroMetricKey.p, AgroMetricKey.n},
      seasonShare: <AgroMetricKey, double>{
        AgroMetricKey.n: 0.15,
        AgroMetricKey.p: 0.5,
        AgroMetricKey.k: 0.10,
      },
      labelEs: 'Trasplante y arranque',
      timingEs:
          'Fondo antes del trasplante (todo el P si es riego rodado) y arranque '
          'suave las dos primeras semanas.',
      rationaleEs:
          'Menos del 30 % del N se toma antes del cuajado: al arranque manda el '
          'P para raíz, no el N.',
      rulesEs: <String>[
        'Preplantación: no más de 30 kg N/ha; el resto se lava antes de que la '
            'planta lo use.',
      ],
    ),
    StageNutritionRule(
      stageKeys: <String>{'vegetativo'},
      windowNutrients: <AgroMetricKey>{AgroMetricKey.n},
      seasonShare: <AgroMetricKey, double>{
        AgroMetricKey.n: 0.25,
        AgroMetricKey.p: 0.2,
        AgroMetricKey.k: 0.15,
      },
      labelEs: 'Vegetativo',
      timingEs: 'Semanal en fertirriego; en rodado, en la primera escarda.',
      rationaleEs: 'Construye la planta que sostendrá los racimos; sin excesos que retrasen la flor.',
    ),
    StageNutritionRule(
      stageKeys: <String>{'floracion', 'cuajado'},
      windowNutrients: <AgroMetricKey>{AgroMetricKey.n, AgroMetricKey.k},
      seasonShare: <AgroMetricKey, double>{
        AgroMetricKey.n: 0.35,
        AgroMetricKey.p: 0.2,
        AgroMetricKey.k: 0.35,
      },
      isCritical: true,
      labelEs: 'Floración y cuajado',
      timingEs: 'Desde las primeras flores hasta el cuajado del tercer racimo.',
      rationaleEs:
          'La mayor parte del crecimiento y de la toma de N ocurre entre el '
          'cuajado temprano y el primer fruto rojo; el K empieza a mandar aquí.',
    ),
    StageNutritionRule(
      stageKeys: <String>{'llenado', 'cosechaProgresiva'},
      windowNutrients: <AgroMetricKey>{AgroMetricKey.k},
      seasonShare: <AgroMetricKey, double>{
        AgroMetricKey.n: 0.25,
        AgroMetricKey.p: 0.1,
        AgroMetricKey.k: 0.40,
      },
      isCritical: true,
      labelEs: 'Llenado y cosecha',
      timingEs: 'Fertirriego continuo hasta que los primeros frutos viran de color.',
      rationaleEs:
          'El K da tamaño, firmeza y color; el N aplicado después del primer '
          'fruto rojo se queda en el suelo y se lava.',
    ),
  ],
  sourceOptionsEs: <AgroMetricKey, List<String>>{
    AgroMetricKey.n: <String>['Nitrato de calcio', 'Nitrato de amonio', 'Urea (46-0-0)'],
    AgroMetricKey.p: <String>['MAP (11-52-0)', 'Ácido fosfórico (fertirriego)'],
    AgroMetricKey.k: <String>['Nitrato de potasio (13-0-46)', 'Sulfato de potasio (0-0-50)'],
  },
  generalRulesEs: _rulesFruitVegetables,
  notesEs: 'Plan de campo abierto a 55–65 t/ha; en protegido multiplica por rendimiento.',
);

const NutritionGuide _chili = NutritionGuide(
  cropKey: 'chili',
  cropLabelEs: 'Chile',
  auditStatus: GuideAuditStatus.proposed,
  sources: <GuideSource>[
    GuideSource(
      labelEs:
          'Panorama Agropecuario, Guía de manejo del chile (trasplante: 200 N – '
          '50 P – 50 K; 50-60-50 al trasplante, 50-00-00 a 30 días, 100-00-00 a '
          'inicio de floración)',
      url: 'https://panorama-agro.com/?page_id=2321',
    ),
    GuideSource(
      labelEs:
          'Revista Bio Ciencias (UAN), extracción en Capsicum annuum: 2.4–4.0 N, '
          '0.4–1.0 P₂O₅, 3.4–5.29 K₂O kg por tonelada',
      url: 'https://revistabiociencias.uan.edu.mx/index.php/BIOCIENCIAS/article/download/32/169',
    ),
    GuideSource(
      labelEs: 'Hortalizas.com, Chiles perfectos en 4 etapas (≈200 kg N/ha por temporada)',
      url: 'https://www.hortalizas.com/cultivos/chiles-pimientos/chiles-perfectos-en-4-etapas/',
    ),
  ],
  seasonPlan: <AgroMetricKey, SeasonNutrientPlan>{
    AgroMetricKey.n: SeasonNutrientPlan(
      form: NutrientForm.n,
      minKgPerHa: 180,
      maxKgPerHa: 240,
      sourceEs: 'Panorama 200–220; Hortalizas.com 200',
      notesEs: 'Campo abierto a 30–45 t/ha (jalapeño, serrano, poblano).',
    ),
    AgroMetricKey.p: SeasonNutrientPlan(
      form: NutrientForm.p2o5,
      minKgPerHa: 50,
      maxKgPerHa: 90,
      sourceEs: 'Panorama 50–80',
    ),
    AgroMetricKey.k: SeasonNutrientPlan(
      form: NutrientForm.k2o,
      minKgPerHa: 100,
      maxKgPerHa: 200,
      sourceEs: 'Extracción 3.4–5.3 kg K₂O/t (Bio Ciencias) a 30–40 t/ha',
      notesEs: 'Panorama solo pone 50 K en suelos ricos; con análisis bajo usa el máximo.',
    ),
  },
  stageRules: <StageNutritionRule>[
    StageNutritionRule(
      stageKeys: <String>{'germinacion', 'establecimiento'},
      windowNutrients: <AgroMetricKey>{AgroMetricKey.p, AgroMetricKey.n},
      seasonShare: <AgroMetricKey, double>{
        AgroMetricKey.n: 0.25,
        AgroMetricKey.p: 0.7,
        AgroMetricKey.k: 0.3,
      },
      labelEs: 'Trasplante (fórmula de arranque)',
      timingEs: 'Al trasplante, en banda (práctica regional 50-60-50).',
      rationaleEs: 'Arranque con P para raíz y una fracción de N y K.',
    ),
    StageNutritionRule(
      stageKeys: <String>{'vegetativo'},
      windowNutrients: <AgroMetricKey>{AgroMetricKey.n},
      seasonShare: <AgroMetricKey, double>{
        AgroMetricKey.n: 0.25,
        AgroMetricKey.p: 0.3,
        AgroMetricKey.k: 0.2,
      },
      labelEs: 'Vegetativo (30 días)',
      timingEs: 'Unos 30 días después del trasplante (práctica regional 50-00-00).',
      rationaleEs: 'Sostiene el crecimiento hasta el primer botón sin adelantar exceso de follaje.',
    ),
    StageNutritionRule(
      stageKeys: <String>{'floracion', 'cuajado'},
      windowNutrients: <AgroMetricKey>{AgroMetricKey.n, AgroMetricKey.k},
      seasonShare: <AgroMetricKey, double>{
        AgroMetricKey.n: 0.35,
        AgroMetricKey.k: 0.3,
      },
      isCritical: true,
      labelEs: 'Inicio de floración',
      timingEs: 'Al inicio de floración (práctica regional 100-00-00), con riego.',
      rationaleEs:
          'Es la aplicación grande del ciclo: define cuántas flores cuajan y '
          'el tamaño del primer corte.',
    ),
    StageNutritionRule(
      stageKeys: <String>{'llenado', 'cosechaProgresiva'},
      windowNutrients: <AgroMetricKey>{AgroMetricKey.k},
      seasonShare: <AgroMetricKey, double>{
        AgroMetricKey.n: 0.15,
        AgroMetricKey.k: 0.2,
      },
      labelEs: 'Llenado y cortes',
      timingEs: 'Fertirriego ligero entre cortes.',
      rationaleEs: 'El K sostiene tamaño y color entre cortes; el N alto aquí solo da hoja.',
    ),
  ],
  sourceOptionsEs: <AgroMetricKey, List<String>>{
    AgroMetricKey.n: <String>['Urea (46-0-0)', 'Nitrato de amonio', 'Nitrato de calcio'],
    AgroMetricKey.p: <String>['MAP (11-52-0)', 'DAP (18-46-0)'],
    AgroMetricKey.k: <String>['Nitrato de potasio (13-0-46)', 'Sulfato de potasio (0-0-50)'],
  },
  generalRulesEs: _rulesFruitVegetables,
  notesEs: 'Plan de campo abierto a 30–45 t/ha; dosis sujetas al análisis de suelo.',
);

const NutritionGuide _cucumber = NutritionGuide(
  cropKey: 'cucumber',
  cropLabelEs: 'Pepino',
  auditStatus: GuideAuditStatus.proposed,
  sources: <GuideSource>[
    GuideSource(
      labelEs:
          'Intagri, Producción de pepino en invernadero (extracción por ciclo: '
          '140 N, 26 P₂O₅, 180 K₂O kg/ha)',
      url: 'https://www.intagri.com/articulos/horticultura-protegida/produccion-de-pepino-en-invernadero',
    ),
    GuideSource(
      labelEs: 'Zamorano, Curvas de absorción de nutrientes en pepino',
      url: 'https://bdigital.zamorano.edu/bitstreams/c5315f92-5262-41fc-a381-bd605bd0096f/download',
    ),
    _srcMapaGuia,
  ],
  seasonPlan: <AgroMetricKey, SeasonNutrientPlan>{
    AgroMetricKey.n: SeasonNutrientPlan(
      form: NutrientForm.n,
      minKgPerHa: 120,
      maxKgPerHa: 180,
      sourceEs: 'Intagri 140 extraídos + eficiencia',
      notesEs: 'Campo abierto a 40–60 t/ha.',
    ),
    AgroMetricKey.p: SeasonNutrientPlan(
      form: NutrientForm.p2o5,
      minKgPerHa: 40,
      maxKgPerHa: 80,
      sourceEs: 'Intagri 26 extraídos; fondo por análisis',
    ),
    AgroMetricKey.k: SeasonNutrientPlan(
      form: NutrientForm.k2o,
      minKgPerHa: 150,
      maxKgPerHa: 250,
      sourceEs: 'Intagri 180 extraídos + eficiencia',
    ),
  },
  stageRules: <StageNutritionRule>[
    StageNutritionRule(
      stageKeys: <String>{'germinacion', 'establecimiento'},
      windowNutrients: <AgroMetricKey>{AgroMetricKey.p},
      seasonShare: <AgroMetricKey, double>{
        AgroMetricKey.n: 0.2,
        AgroMetricKey.p: 0.6,
        AgroMetricKey.k: 0.2,
      },
      labelEs: 'Fondo y arranque',
      timingEs: 'Fondo antes de siembra o trasplante; arranque suave.',
      rationaleEs: 'El pepino arranca rápido: P disponible desde el día uno.',
    ),
    StageNutritionRule(
      stageKeys: <String>{'vegetativo'},
      windowNutrients: <AgroMetricKey>{AgroMetricKey.n},
      seasonShare: <AgroMetricKey, double>{
        AgroMetricKey.n: 0.3,
        AgroMetricKey.p: 0.2,
        AgroMetricKey.k: 0.2,
      },
      labelEs: 'Guía y follaje',
      timingEs: 'Semanal en fertirriego hasta la primera flor.',
      rationaleEs: 'Construye la guía que cargará los frutos.',
    ),
    StageNutritionRule(
      stageKeys: <String>{'floracion', 'cuajado'},
      windowNutrients: <AgroMetricKey>{AgroMetricKey.n, AgroMetricKey.k},
      seasonShare: <AgroMetricKey, double>{
        AgroMetricKey.n: 0.3,
        AgroMetricKey.p: 0.2,
        AgroMetricKey.k: 0.3,
      },
      isCritical: true,
      labelEs: 'Floración y cuajado',
      timingEs: 'Desde la primera flor hembra, en fertirriego continuo.',
      rationaleEs: 'La absorción sube al máximo con el cuajado; aquí se decide el número de frutos.',
    ),
    StageNutritionRule(
      stageKeys: <String>{'llenado', 'cosechaProgresiva'},
      windowNutrients: <AgroMetricKey>{AgroMetricKey.k},
      seasonShare: <AgroMetricKey, double>{
        AgroMetricKey.n: 0.2,
        AgroMetricKey.k: 0.3,
      },
      labelEs: 'Cortes',
      timingEs: 'Fertirriego ligero y constante entre cortes.',
      rationaleEs: 'Los cortes sacan K cada semana; reponerlo evita frutos deformes.',
    ),
  ],
  sourceOptionsEs: <AgroMetricKey, List<String>>{
    AgroMetricKey.n: <String>['Nitrato de calcio', 'Nitrato de amonio', 'Urea (46-0-0)'],
    AgroMetricKey.p: <String>['MAP (11-52-0)', 'Ácido fosfórico (fertirriego)'],
    AgroMetricKey.k: <String>['Nitrato de potasio (13-0-46)', 'Sulfato de potasio (0-0-50)'],
  },
  generalRulesEs: _rulesFruitVegetables,
  notesEs: 'Plan de campo abierto a 40–60 t/ha.',
);

const NutritionGuide _eggplant = NutritionGuide(
  cropKey: 'eggplant',
  cropLabelEs: 'Berenjena',
  auditStatus: GuideAuditStatus.proposed,
  sources: <GuideSource>[
    GuideSource(
      labelEs:
          'Intagri, Fertirriego de berenjena (3.5–5.2 N, 1.5–2 P₂O₅, 5.4–6.7 '
          'K₂O kg por tonelada)',
      url: 'https://www.intagri.com/articulos/horticultura-protegida/fertirriego-de-berenjena-solanum-melongena',
    ),
    _srcMapaGuia,
  ],
  seasonPlan: <AgroMetricKey, SeasonNutrientPlan>{
    AgroMetricKey.n: SeasonNutrientPlan(
      form: NutrientForm.n,
      minKgPerHa: 180,
      maxKgPerHa: 260,
      sourceEs: 'Intagri 3.5–5.2 kg N/t a 50 t/ha',
      notesEs: 'Campo abierto a 40–60 t/ha.',
    ),
    AgroMetricKey.p: SeasonNutrientPlan(
      form: NutrientForm.p2o5,
      minKgPerHa: 75,
      maxKgPerHa: 100,
      sourceEs: 'Intagri 1.5–2 kg P₂O₅/t a 50 t/ha',
    ),
    AgroMetricKey.k: SeasonNutrientPlan(
      form: NutrientForm.k2o,
      minKgPerHa: 270,
      maxKgPerHa: 335,
      sourceEs: 'Intagri 5.4–6.7 kg K₂O/t a 50 t/ha',
    ),
  },
  stageRules: <StageNutritionRule>[
    StageNutritionRule(
      stageKeys: <String>{'germinacion', 'establecimiento'},
      windowNutrients: <AgroMetricKey>{AgroMetricKey.p, AgroMetricKey.n},
      seasonShare: <AgroMetricKey, double>{
        AgroMetricKey.n: 0.15,
        AgroMetricKey.p: 0.5,
        AgroMetricKey.k: 0.1,
      },
      labelEs: 'Trasplante y arranque',
      timingEs: 'Fondo antes del trasplante y arranque suave.',
      rationaleEs: 'P para raíz; el N excesivo al inicio da follaje y retrasa flor y cuajado.',
    ),
    StageNutritionRule(
      stageKeys: <String>{'vegetativo'},
      windowNutrients: <AgroMetricKey>{AgroMetricKey.n},
      seasonShare: <AgroMetricKey, double>{
        AgroMetricKey.n: 0.25,
        AgroMetricKey.p: 0.2,
        AgroMetricKey.k: 0.15,
      },
      labelEs: 'Vegetativo',
      timingEs: 'Semanal en fertirriego.',
      rationaleEs: 'Planta de alta demanda: construye estructura sin excesos.',
    ),
    StageNutritionRule(
      stageKeys: <String>{'floracion', 'cuajado'},
      windowNutrients: <AgroMetricKey>{AgroMetricKey.n, AgroMetricKey.k},
      seasonShare: <AgroMetricKey, double>{
        AgroMetricKey.n: 0.35,
        AgroMetricKey.p: 0.2,
        AgroMetricKey.k: 0.35,
      },
      isCritical: true,
      labelEs: 'Floración y cuajado',
      timingEs: 'Desde las primeras flores hasta el cuajado de los primeros frutos.',
      rationaleEs: 'La demanda sube con el cuajado; el K empieza a mandar.',
    ),
    StageNutritionRule(
      stageKeys: <String>{'llenado', 'cosechaProgresiva'},
      windowNutrients: <AgroMetricKey>{AgroMetricKey.k},
      seasonShare: <AgroMetricKey, double>{
        AgroMetricKey.n: 0.25,
        AgroMetricKey.p: 0.1,
        AgroMetricKey.k: 0.4,
      },
      isCritical: true,
      labelEs: 'Llenado y cortes',
      timingEs: 'Fertirriego continuo entre cortes.',
      rationaleEs: 'Los frutos acumulan la mayor parte del K del ciclo al final.',
    ),
  ],
  sourceOptionsEs: <AgroMetricKey, List<String>>{
    AgroMetricKey.n: <String>['Nitrato de calcio', 'Nitrato de amonio', 'Urea (46-0-0)'],
    AgroMetricKey.p: <String>['MAP (11-52-0)', 'Ácido fosfórico (fertirriego)'],
    AgroMetricKey.k: <String>['Nitrato de potasio (13-0-46)', 'Sulfato de potasio (0-0-50)'],
  },
  generalRulesEs: _rulesFruitVegetables,
  notesEs: 'Plan de campo abierto a 40–60 t/ha, derivado de extracción por tonelada.',
);

const NutritionGuide _squash = NutritionGuide(
  cropKey: 'squash',
  cropLabelEs: 'Calabaza',
  auditStatus: GuideAuditStatus.proposed,
  sources: <GuideSource>[
    GuideSource(
      labelEs:
          'Terra Latinoamericana, Rendimiento y calidad de calabacita con altas '
          'dosis de N y K (recomendaciones regionales 80-60-00 a 130-90-00)',
      url: 'https://www.scielo.org.mx/scielo.php?script=sci_arttext&pid=S0187-57792011000200133',
      year: 2011,
    ),
    GuideSource(
      labelEs:
          'Revista Fitotecnia Mexicana, Curvas de absorción de macronutrientes '
          'en calabacita (≈180 N, 18 P, 37 K kg/ha; absorción lineal en 80 días)',
      url: 'https://www.scielo.org.mx/scielo.php?script=sci_arttext&pid=S0187-73802012000500012',
      year: 2012,
    ),
  ],
  seasonPlan: <AgroMetricKey, SeasonNutrientPlan>{
    AgroMetricKey.n: SeasonNutrientPlan(
      form: NutrientForm.n,
      minKgPerHa: 80,
      maxKgPerHa: 150,
      sourceEs: 'Recomendaciones regionales 80–130 (Terra 2011)',
      notesEs: 'Calabacita de campo abierto a 20–30 t/ha; 330 solo en fertirriego intensivo.',
    ),
    AgroMetricKey.p: SeasonNutrientPlan(
      form: NutrientForm.p2o5,
      minKgPerHa: 60,
      maxKgPerHa: 90,
      sourceEs: 'Recomendaciones regionales 60–90 (Terra 2011)',
    ),
    AgroMetricKey.k: SeasonNutrientPlan(
      form: NutrientForm.k2o,
      minKgPerHa: 0,
      maxKgPerHa: 120,
      sourceEs: 'Análisis de suelo; 90–150 probados (Terra 2011)',
    ),
  },
  stageRules: <StageNutritionRule>[
    StageNutritionRule(
      stageKeys: <String>{'germinacion', 'establecimiento'},
      windowNutrients: <AgroMetricKey>{AgroMetricKey.p, AgroMetricKey.n},
      seasonShare: <AgroMetricKey, double>{
        AgroMetricKey.n: 0.3,
        AgroMetricKey.p: 1.0,
        AgroMetricKey.k: 0.5,
      },
      labelEs: 'Fondo y arranque',
      timingEs: 'A la siembra o trasplante, todo el P en banda.',
      rationaleEs: 'Ciclo corto (≈80 días): lo que no está al arranque llega tarde.',
    ),
    StageNutritionRule(
      stageKeys: <String>{'vegetativo'},
      windowNutrients: <AgroMetricKey>{AgroMetricKey.n},
      seasonShare: <AgroMetricKey, double>{
        AgroMetricKey.n: 0.3,
        AgroMetricKey.k: 0.25,
      },
      labelEs: 'Guía',
      timingEs: 'Segunda aplicación a las 3–4 semanas, con riego.',
      rationaleEs: 'La absorción crece de forma lineal: reparte, no concentres.',
    ),
    StageNutritionRule(
      stageKeys: <String>{'floracion', 'cuajado'},
      windowNutrients: <AgroMetricKey>{AgroMetricKey.n, AgroMetricKey.k},
      seasonShare: <AgroMetricKey, double>{
        AgroMetricKey.n: 0.4,
        AgroMetricKey.k: 0.25,
      },
      isCritical: true,
      labelEs: 'Floración y cuajado',
      timingEs: 'Con las primeras flores hembra.',
      rationaleEs: 'Sostiene los cortes que vienen: sin N aquí los frutos salen cortos y claros.',
    ),
    StageNutritionRule(
      stageKeys: <String>{'llenado', 'cosechaProgresiva'},
      windowNutrients: <AgroMetricKey>{},
      labelEs: 'Cortes',
      rationaleEs: 'Ya no conviene fertilizar al suelo; cuida agua y sanidad.',
    ),
  ],
  sourceOptionsEs: <AgroMetricKey, List<String>>{
    AgroMetricKey.n: <String>['Urea (46-0-0)', 'Sulfato de amonio (21-0-0-24S)', 'Nitrato de calcio'],
    AgroMetricKey.p: <String>['MAP (11-52-0)', 'DAP (18-46-0)'],
    AgroMetricKey.k: <String>['Nitrato de potasio (13-0-46)', 'Sulfato de potasio (0-0-50)'],
  },
  generalRulesEs: _rulesFruitVegetables,
  notesEs: 'Plan para calabacita de campo abierto a 20–30 t/ha.',
);

// ═══════════════════════════════════════════════════════════════════════════
// HOJA
// ═══════════════════════════════════════════════════════════════════════════

const List<String> _rulesLeafy = <String>[
  'Corta el N 10–14 días antes de cosecha: el N tardío ablanda la hoja, sube '
      'nitratos y acorta la vida de anaquel.',
  'Cultivo sensible a sales: potasio como sulfato o nitrato, nunca cloruro, y '
      'CE de suelo vigilada.',
  ..._rulesVegetableFertigation,
];

const NutritionGuide _lettuce = NutritionGuide(
  cropKey: 'lettuce',
  cropLabelEs: 'Lechuga',
  auditStatus: GuideAuditStatus.proposed,
  sources: <GuideSource>[
    GuideSource(
      labelEs:
          'CDFA-FREP, Lettuce fertilization guideline (100–180 lb N/acre; '
          '70–80 % del N se toma entre acogollado y cosecha)',
      url: 'https://www.cdfa.ca.gov/is/ffldrs/frep/FertilizationGuidelines/Lettuce.html',
      year: 2023,
    ),
    GuideSource(
      labelEs:
          'Cajamar, Boletín Fertilización de la lechuga (extracción a 35 t/ha: '
          '80–100 N, 30–50 P₂O₅, 160–210 K₂O)',
      url: 'https://www.cajamar.es/storage/documents/1270/boletin-huerto-90-1496059680.pdf',
    ),
  ],
  seasonPlan: <AgroMetricKey, SeasonNutrientPlan>{
    AgroMetricKey.n: SeasonNutrientPlan(
      form: NutrientForm.n,
      minKgPerHa: 100,
      maxKgPerHa: 180,
      sourceEs: 'CDFA 112–200 (invierno alto, verano bajo); Cajamar 80–100 extraídos',
      notesEs: 'Lechuga de cabeza a 30–40 t/ha. Con nitratos de suelo > 20 ppm no hace falta más N.',
    ),
    AgroMetricKey.p: SeasonNutrientPlan(
      form: NutrientForm.p2o5,
      minKgPerHa: 40,
      maxKgPerHa: 100,
      sourceEs: 'Cajamar 30–50 extraídos; CDFA hasta 100 lb/acre con Olsen-P medio',
      notesEs: 'En suelo frío (< 12 °C) el P de arranque responde más.',
    ),
    AgroMetricKey.k: SeasonNutrientPlan(
      form: NutrientForm.k2o,
      minKgPerHa: 100,
      maxKgPerHa: 200,
      sourceEs: 'Cajamar 160–210 extraídos; CDFA sin K con > 150 ppm en suelo',
    ),
  },
  stageRules: <StageNutritionRule>[
    StageNutritionRule(
      stageKeys: <String>{'germinacion', 'establecimiento'},
      windowNutrients: <AgroMetricKey>{AgroMetricKey.p},
      seasonShare: <AgroMetricKey, double>{
        AgroMetricKey.n: 0.2,
        AgroMetricKey.p: 1.0,
        AgroMetricKey.k: 0.4,
      },
      labelEs: 'Fondo y arranque',
      timingEs: 'Fondo antes del trasplante y un arranque de ~20 kg N/ha.',
      rationaleEs: 'El primer mes toma menos del 20 % del N: aquí manda el P para raíz.',
    ),
    StageNutritionRule(
      stageKeys: <String>{'desarrolloVegetativo'},
      windowNutrients: <AgroMetricKey>{AgroMetricKey.n},
      seasonShare: <AgroMetricKey, double>{
        AgroMetricKey.n: 0.35,
        AgroMetricKey.k: 0.3,
      },
      labelEs: 'Roseta (primera cobertera)',
      timingEs: 'A las 2–4 hojas verdaderas tras el aclareo, con riego.',
      rationaleEs: 'Arma la roseta que después se cierra en cabeza.',
    ),
    StageNutritionRule(
      stageKeys: <String>{'formacionCabeza'},
      windowNutrients: <AgroMetricKey>{AgroMetricKey.n, AgroMetricKey.k},
      seasonShare: <AgroMetricKey, double>{
        AgroMetricKey.n: 0.45,
        AgroMetricKey.k: 0.3,
      },
      isCritical: true,
      labelEs: 'Acogollado',
      timingEs: 'Al inicio del acogollado, un mes antes de cosecha; nada en las últimas dos semanas.',
      rationaleEs:
          'Entre acogollado y cosecha la lechuga toma 3–4 lb N/acre al día: '
          'el 70–80 % del N del ciclo cae aquí.',
      rulesEs: <String>[
        'Exceso de N retrasa el cierre de la cabeza.',
      ],
    ),
    StageNutritionRule(
      stageKeys: <String>{'ventanaCosecha', 'sobremadurez'},
      windowNutrients: <AgroMetricKey>{},
      labelEs: 'Cosecha',
      rationaleEs: 'Ventana cerrada: cualquier N ahora es nitrato en hoja.',
    ),
  ],
  sourceOptionsEs: <AgroMetricKey, List<String>>{
    AgroMetricKey.n: <String>['Nitrato de calcio', 'Sulfato de amonio (21-0-0-24S)', 'Nitrato de amonio'],
    AgroMetricKey.p: <String>['MAP (11-52-0)', 'Superfosfato triple'],
    AgroMetricKey.k: <String>['Nitrato de potasio (13-0-46)', 'Sulfato de potasio (0-0-50)'],
  },
  generalRulesEs: _rulesLeafy,
  notesEs: 'Plan para lechuga de cabeza de campo abierto a 30–40 t/ha.',
);

const NutritionGuide _spinach = NutritionGuide(
  cropKey: 'spinach',
  cropLabelEs: 'Espinaca',
  auditStatus: GuideAuditStatus.proposed,
  sources: <GuideSource>[
    GuideSource(
      labelEs:
          'TecnoAgro, Fertilización de espinaca (extracción a 25 t/ha: 110–130 '
          'N, 38–45 P, 180–220 K kg/ha)',
      url: 'https://tecnoagro.com.mx/no.-111/fertilizacion-de-espinaca',
    ),
    GuideSource(
      labelEs:
          'Acta Agronómica (UNAL), Dosis y momentos de aplicación de nitrógeno '
          'en la productividad de las espinacas',
      url: 'https://revistas.unal.edu.co/index.php/acta_agronomica/article/view/100895',
    ),
  ],
  seasonPlan: <AgroMetricKey, SeasonNutrientPlan>{
    AgroMetricKey.n: SeasonNutrientPlan(
      form: NutrientForm.n,
      minKgPerHa: 100,
      maxKgPerHa: 150,
      sourceEs: 'TecnoAgro 110–130 extraídos a 25 t/ha',
      notesEs: 'Espinaca de hoja a 20–25 t/ha; en invierno modera por baja mineralización.',
    ),
    AgroMetricKey.p: SeasonNutrientPlan(
      form: NutrientForm.p2o5,
      minKgPerHa: 40,
      maxKgPerHa: 60,
      sourceEs: 'TecnoAgro 38–45 kg P/ha extraídos',
    ),
    AgroMetricKey.k: SeasonNutrientPlan(
      form: NutrientForm.k2o,
      minKgPerHa: 120,
      maxKgPerHa: 200,
      sourceEs: 'TecnoAgro 180–220 kg K/ha extraídos',
    ),
  },
  stageRules: <StageNutritionRule>[
    StageNutritionRule(
      stageKeys: <String>{'germinacion', 'establecimiento'},
      windowNutrients: <AgroMetricKey>{AgroMetricKey.p},
      seasonShare: <AgroMetricKey, double>{
        AgroMetricKey.n: 0.3,
        AgroMetricKey.p: 1.0,
        AgroMetricKey.k: 0.4,
      },
      labelEs: 'Fondo y arranque',
      timingEs: 'Fondo antes de la siembra.',
      rationaleEs: 'Ciclo corto: P y parte del K entran al fondo.',
    ),
    StageNutritionRule(
      stageKeys: <String>{'vegetativoTemprano', 'expansionFoliar'},
      windowNutrients: <AgroMetricKey>{AgroMetricKey.n, AgroMetricKey.k},
      seasonShare: <AgroMetricKey, double>{
        AgroMetricKey.n: 0.7,
        AgroMetricKey.k: 0.6,
      },
      isCritical: true,
      labelEs: 'Expansión foliar',
      timingEs: 'Cobertera(s) entre 4 y 6 hojas verdaderas, la última 2 semanas antes de cosecha.',
      rationaleEs: 'La hoja se construye aquí; después, el N solo acumula nitratos.',
    ),
    StageNutritionRule(
      stageKeys: <String>{'madurezComercial', 'ventanaCosecha', 'perdidaCalidad', 'espigadoSenescencia'},
      windowNutrients: <AgroMetricKey>{},
      labelEs: 'Cosecha',
      rationaleEs: 'Ventana cerrada: N tardío ablanda hoja, sube nitratos y adelanta el espigado.',
    ),
  ],
  sourceOptionsEs: <AgroMetricKey, List<String>>{
    AgroMetricKey.n: <String>['Nitrato de calcio', 'Nitrato de amonio', 'Sulfato de amonio (21-0-0-24S)'],
    AgroMetricKey.p: <String>['MAP (11-52-0)', 'Superfosfato triple'],
    AgroMetricKey.k: <String>['Sulfato de potasio (0-0-50)', 'Nitrato de potasio (13-0-46)'],
  },
  generalRulesEs: _rulesLeafy,
  notesEs: 'Plan para espinaca de hoja a 20–25 t/ha.',
);

// ═══════════════════════════════════════════════════════════════════════════
// ALLIUM
// ═══════════════════════════════════════════════════════════════════════════

const NutritionGuide _onion = NutritionGuide(
  cropKey: 'onion',
  cropLabelEs: 'Cebolla',
  auditStatus: GuideAuditStatus.proposed,
  sources: <GuideSource>[
    GuideSource(
      labelEs:
          'Intagri, Fertilización nitrogenada en el cultivo de cebolla (150–200 '
          'kg N/ha; no más de 1/3 a la siembra; N fuerte tardío retrasa madurez)',
      url: 'https://www.intagri.com/articulos/nutricion-vegetal/fertilizacion-nitrogenada-en-el-cultivo-de-cebolla',
    ),
    GuideSource(
      labelEs:
          'CDFA-FREP, Onion fertilization guideline (150–250 lb N/acre en goteo; '
          '65–80 % en temporada; evitar N tardío)',
      url: 'https://www.cdfa.ca.gov/is/ffldrs/frep/FertilizationGuidelines/Onion.html',
      year: 2023,
    ),
    GuideSource(
      labelEs:
          'Fertilab, Necesidades de N, P y K para cebolla considerando el análisis '
          'de suelo (Zacatecas: mitad de N y K antes del trasplante y resto a los '
          '50 días; Morelos: 70 % del N en llenado de bulbo)',
      url: 'https://www.fertilab.com.mx/Sitio/notas/Necesidades-de-N-P-y-K-para-Cebolla.pdf',
    ),
    GuideSource(
      labelEs: 'Haifa, Guía de fertilización de cebolla (25–30 % del N preplantación; parar N a 2/3 del bulbo)',
      url: 'https://www.haifa-group.com/croprecommendations/onion-ferilizer-crop-guide-nutrition-onion-crop',
    ),
  ],
  seasonPlan: <AgroMetricKey, SeasonNutrientPlan>{
    AgroMetricKey.n: SeasonNutrientPlan(
      form: NutrientForm.n,
      minKgPerHa: 150,
      maxKgPerHa: 220,
      sourceEs: 'Intagri 150–200; CDFA 168–280 (goteo); Fertilab 120–200',
      notesEs: 'Cebolla de bulbo a 50–80 t/ha.',
    ),
    AgroMetricKey.p: SeasonNutrientPlan(
      form: NutrientForm.p2o5,
      minKgPerHa: 60,
      maxKgPerHa: 120,
      sourceEs: 'Fertilab ejemplo 120; CDFA remoción 61–98 lb/acre',
      notesEs: 'Todo antes del trasplante o hasta inicio de bulbo.',
    ),
    AgroMetricKey.k: SeasonNutrientPlan(
      form: NutrientForm.k2o,
      minKgPerHa: 100,
      maxKgPerHa: 200,
      sourceEs: 'Fertilab 112–200; CDFA remoción 170–225 lb/acre',
    ),
  },
  stageRules: <StageNutritionRule>[
    StageNutritionRule(
      stageKeys: <String>{'germinacion', 'emergencia', 'establecimiento'},
      windowNutrients: <AgroMetricKey>{AgroMetricKey.p},
      seasonShare: <AgroMetricKey, double>{
        AgroMetricKey.n: 0.3,
        AgroMetricKey.p: 0.7,
        AgroMetricKey.k: 0.4,
      },
      labelEs: 'Fondo y trasplante',
      timingEs: 'Antes del trasplante: todo el P (o el 70 %), no más de 1/3 del N y mitad del K.',
      rationaleEs: 'La primera mitad del ciclo toma menos del 20 % del N; no lo adelantes.',
    ),
    StageNutritionRule(
      stageKeys: <String>{'vegetativo'},
      windowNutrients: <AgroMetricKey>{AgroMetricKey.n},
      seasonShare: <AgroMetricKey, double>{
        AgroMetricKey.n: 0.35,
        AgroMetricKey.p: 0.3,
        AgroMetricKey.k: 0.2,
      },
      isCritical: true,
      labelEs: 'Desarrollo de hoja (3–4 hojas)',
      timingEs: 'Segundo tercio del N a las 3–4 hojas, con riego; en fertirriego cada 10–14 días.',
      rationaleEs: 'Cada hoja es una capa del bulbo: el N de esta etapa fija el tamaño final.',
    ),
    StageNutritionRule(
      stageKeys: <String>{'induccionBulbificacion', 'inicioBulbo', 'llenadoBulbo'},
      windowNutrients: <AgroMetricKey>{AgroMetricKey.k, AgroMetricKey.n},
      seasonShare: <AgroMetricKey, double>{
        AgroMetricKey.n: 0.35,
        AgroMetricKey.k: 0.4,
      },
      isCritical: true,
      labelEs: 'Inicio y llenado de bulbo',
      timingEs: 'Último tercio del N y el K restante al inicio del bulbo; nada de N cuando el bulbo pase de 2/3 de su tamaño.',
      rationaleEs:
          'En llenado activo la cebolla toma 1.5–3.5 lb N/acre al día y el K '
          'engruesa el bulbo. El fotoperiodo manda la bulbificación; el N tardío '
          'solo engruesa cuello y retrasa la madurez.',
      rulesEs: <String>[
        'N fuerte tardío: cuello grueso, mala maduración y bulbos que no guardan.',
      ],
    ),
    StageNutritionRule(
      stageKeys: <String>{'maduracionCosecha', 'espigado'},
      windowNutrients: <AgroMetricKey>{},
      labelEs: 'Maduración',
      rationaleEs: 'Ventana cerrada: deja secar el cuello, no fertilices.',
    ),
  ],
  sourceOptionsEs: <AgroMetricKey, List<String>>{
    AgroMetricKey.n: <String>['Sulfato de amonio (21-0-0-24S)', 'Nitrato de amonio', 'Urea (46-0-0)'],
    AgroMetricKey.p: <String>['MAP (11-52-0)', 'DAP (18-46-0)'],
    AgroMetricKey.k: <String>['Sulfato de potasio (0-0-50)', 'Nitrato de potasio (13-0-46)'],
  },
  generalRulesEs: <String>[
    'Sensible a sales: no más de 30 kg K₂O/ha en la banda de arranque.',
    'El azufre acompaña al N en Allium (pungencia y sanidad): sulfato de amonio '
        'o de potasio cubren ambos.',
    ..._rulesVegetableFertigation,
  ],
  notesEs: 'Plan para cebolla de bulbo de riego a 50–80 t/ha.',
);

const NutritionGuide _garlic = NutritionGuide(
  cropKey: 'garlic',
  cropLabelEs: 'Ajo',
  auditStatus: GuideAuditStatus.proposed,
  sources: <GuideSource>[
    GuideSource(
      labelEs:
          'Biotecnia (UNISON), Fertilización nitrogenada en ajo bajo riego por '
          'goteo en la Costa de Hermosillo (óptimo 180 kg N/ha, 22 t/ha)',
      url: 'https://biotecnia.unison.mx/index.php/biotecnia/article/view/101',
    ),
    GuideSource(
      labelEs:
          'InfoAgro México, Fertilización en el cultivo de ajo (120–240 N y 60–80 '
          'P₂O₅ según suelo; goteo 250-100-265-120Ca; todo el P y mitad de N y K a '
          'la plantación, resto a los 60 días, nunca tras iniciar bulbo)',
      url: 'https://mexico.infoagro.com/fertilizacion-en-el-cultivo-de-ajo/',
    ),
    GuideSource(
      labelEs: 'Intagri, El cultivo de ajo (tres momentos: plantación, primera escarda, antes de bulbo)',
      url: 'https://www.intagri.com/articulos/nutricion-vegetal/el-cultivo-de-ajo',
    ),
  ],
  seasonPlan: <AgroMetricKey, SeasonNutrientPlan>{
    AgroMetricKey.n: SeasonNutrientPlan(
      form: NutrientForm.n,
      minKgPerHa: 120,
      maxKgPerHa: 200,
      sourceEs: 'Hermosillo óptimo 180; InfoAgro 120–240',
      notesEs: 'Ajo de riego a 12–22 t/ha.',
    ),
    AgroMetricKey.p: SeasonNutrientPlan(
      form: NutrientForm.p2o5,
      minKgPerHa: 60,
      maxKgPerHa: 100,
      sourceEs: 'InfoAgro 60–80 (100 en goteo)',
      notesEs: 'Todo a la plantación.',
    ),
    AgroMetricKey.k: SeasonNutrientPlan(
      form: NutrientForm.k2o,
      minKgPerHa: 100,
      maxKgPerHa: 200,
      sourceEs: 'Extracción 70–170 kg K/ha a 10 t (InfoAgro)',
    ),
  },
  stageRules: <StageNutritionRule>[
    StageNutritionRule(
      stageKeys: <String>{'clovePlanting', 'emergenceEstablishment'},
      windowNutrients: <AgroMetricKey>{AgroMetricKey.p, AgroMetricKey.n},
      seasonShare: <AgroMetricKey, double>{
        AgroMetricKey.n: 0.5,
        AgroMetricKey.p: 1.0,
        AgroMetricKey.k: 0.5,
      },
      labelEs: 'Plantación',
      timingEs: 'A la plantación: todo el P, la mitad del N y la mitad del K.',
      rationaleEs: 'El vigor temprano define el potencial de rendimiento del bulbo.',
    ),
    StageNutritionRule(
      stageKeys: <String>{'vegetativeLeafDevelopment', 'coldInductionVernalization'},
      windowNutrients: <AgroMetricKey>{AgroMetricKey.n, AgroMetricKey.k},
      seasonShare: <AgroMetricKey, double>{
        AgroMetricKey.n: 0.5,
        AgroMetricKey.k: 0.5,
      },
      isCritical: true,
      labelEs: 'Desarrollo de hoja (primera escarda)',
      timingEs: 'Unos 60 días después de plantar, en la primera escarda, y nunca después de iniciada la formación del bulbo.',
      rationaleEs:
          'Cada hoja formada aquí es un diente después; es el último momento '
          'útil para el N.',
      rulesEs: <String>[
        'La vernalización no se corrige con fertilizante: si el ajo no recibió '
            'frío, más N no hará bulbo.',
      ],
    ),
    StageNutritionRule(
      stageKeys: <String>{'bulbDifferentiation', 'bulbFilling'},
      windowNutrients: <AgroMetricKey>{},
      labelEs: 'Diferenciación y llenado de bulbo',
      rationaleEs:
          'Ventana cerrada para N: el N tardío favorece escobeteado y canutos, '
          'mala maduración y mal curado.',
      rulesEs: <String>[
        'Si vas a apoyar el llenado, que sea K vía riego y sin N.',
      ],
    ),
    StageNutritionRule(
      stageKeys: <String>{'bulbMaturation', 'harvest', 'curingRest', 'scapeBrooming'},
      windowNutrients: <AgroMetricKey>{},
      labelEs: 'Maduración y curado',
      rationaleEs: 'No fertilices: el bulbo se cura con suelo seco.',
    ),
  ],
  sourceOptionsEs: <AgroMetricKey, List<String>>{
    AgroMetricKey.n: <String>['Sulfato de amonio (21-0-0-24S)', 'Urea (46-0-0)', 'Nitrato de amonio'],
    AgroMetricKey.p: <String>['MAP (11-52-0)', 'DAP (18-46-0)'],
    AgroMetricKey.k: <String>['Sulfato de potasio (0-0-50)', 'Nitrato de potasio (13-0-46)'],
  },
  generalRulesEs: <String>[
    'El azufre es el cuarto nutriente del ajo: sin él aparecen deficiencias de N '
        'aunque hayas aplicado.',
    ..._rulesVegetableFertigation,
  ],
  notesEs: 'Plan para ajo de riego a 12–22 t/ha (Bajío, Zacatecas, Sonora).',
);

// ═══════════════════════════════════════════════════════════════════════════
// FRUTALES (dosis por restitución: TreeRestitutionPlanner)
// (etapas: planting_transplant, root_establishment, juvenile_vegetative,
//  dormancy, budbreak, vegetative_growth, flowering, fruit_set, fruit_fill,
//  harvest_maturity, post_harvest)
// ═══════════════════════════════════════════════════════════════════════════

const List<String> _rulesTrees = <String>[
  'Aplica bajo la línea de goteo de la copa, donde están las raíces finas, y '
      'riega enseguida.',
  'N alto cerca de cosecha frena color, baja firmeza y acorta el almacenamiento.',
  'Árboles jóvenes (sin cosecha): dosis por edad y vigor, no por restitución.',
];

const GuideSource _srcTreeRestitution = GuideSource(
  labelEs:
      'Coeficientes de extracción de fruto de BIO-G (WSU Tree Fruit, Cornell, '
      'Yara, Haifa, UC ANR, IPNI; ver TreeRestitutionPlanner)',
);

/// Reglas de un frutal caducifolio (manzano, peral, durazno, nogal, pistache).
const List<StageNutritionRule> _deciduousTreeRules = <StageNutritionRule>[
  StageNutritionRule(
    stageKeys: <String>{'planting_transplant', 'root_establishment', 'juvenile_vegetative'},
    windowNutrients: <AgroMetricKey>{AgroMetricKey.p},
    labelEs: 'Establecimiento',
    timingEs: 'Al plantar: P en el fondo del cepellón; N ligero y fraccionado el primer año.',
    rationaleEs: 'El árbol joven necesita raíz, no carga; el N alto da madera blanda.',
  ),
  StageNutritionRule(
    stageKeys: <String>{'dormancy'},
    windowNutrients: <AgroMetricKey>{},
    labelEs: 'Reposo',
    rationaleEs: 'Sin hoja no hay absorción: lo que apliques en reposo se lava.',
  ),
  StageNutritionRule(
    stageKeys: <String>{'budbreak', 'vegetative_growth'},
    windowNutrients: <AgroMetricKey>{AgroMetricKey.n},
    isCritical: true,
    labelEs: 'Brotación',
    timingEs: 'De brotación a 4–6 semanas después, en fertirriego o banda bajo la copa.',
    rationaleEs:
        'El N de primavera sostiene brote, hoja y cuajado con las reservas del '
        'año pasado; es la ventana de N que decide la carga.',
    rulesEs: <String>[
      'No te pases: N alto en brotación empuja brotes tiernos y sombra de más.',
    ],
  ),
  StageNutritionRule(
    stageKeys: <String>{'flowering', 'fruit_set'},
    windowNutrients: <AgroMetricKey>{AgroMetricKey.k},
    labelEs: 'Floración y cuajado',
    timingEs: 'Tras la caída de pétalos, con el riego.',
    rationaleEs: 'El K arranca aquí para el tamaño del fruto; el N se modera para no tirar fruto.',
  ),
  StageNutritionRule(
    stageKeys: <String>{'fruit_fill'},
    windowNutrients: <AgroMetricKey>{AgroMetricKey.k},
    isCritical: true,
    labelEs: 'Llenado de fruto',
    timingEs: 'Durante el crecimiento del fruto, fraccionado en el riego.',
    rationaleEs: 'El fruto se lleva la mayor parte del K del año: tamaño, color y firmeza.',
    rulesEs: <String>[
      'K alto de más sube sales y desbalancea el calcio (firmeza).',
    ],
  ),
  StageNutritionRule(
    stageKeys: <String>{'harvest_maturity'},
    windowNutrients: <AgroMetricKey>{},
    labelEs: 'Cosecha',
    rationaleEs: 'Ventana cerrada: N cerca de cosecha retrasa color y baja firmeza.',
  ),
  StageNutritionRule(
    stageKeys: <String>{'post_harvest'},
    windowNutrients: <AgroMetricKey>{AgroMetricKey.n, AgroMetricKey.p},
    labelEs: 'Post-cosecha',
    timingEs: 'Justo después de cosechar, mientras la hoja sigue activa.',
    rationaleEs: 'Repone reservas para la brotación del siguiente ciclo.',
  ),
];

/// Reglas de un frutal perennifolio (cítricos, mango, aguacate).
const List<StageNutritionRule> _evergreenTreeRules = <StageNutritionRule>[
  StageNutritionRule(
    stageKeys: <String>{'planting_transplant', 'root_establishment', 'juvenile_vegetative'},
    windowNutrients: <AgroMetricKey>{AgroMetricKey.p},
    labelEs: 'Establecimiento',
    timingEs: 'Al plantar: P en el fondo; N ligero y fraccionado los primeros años.',
    rationaleEs: 'Raíz y estructura antes que carga.',
  ),
  StageNutritionRule(
    stageKeys: <String>{'dormancy'},
    windowNutrients: <AgroMetricKey>{},
    labelEs: 'Reposo relativo',
    rationaleEs: 'Con suelo frío o seco la raíz no absorbe: espera al siguiente flujo.',
  ),
  StageNutritionRule(
    stageKeys: <String>{'budbreak', 'vegetative_growth', 'flowering'},
    windowNutrients: <AgroMetricKey>{AgroMetricKey.n},
    isCritical: true,
    labelEs: 'Brotación y floración',
    timingEs: 'Antes y durante la floración principal, en fertirriego o banda.',
    rationaleEs: 'El N pre-floración sostiene el flujo vegetativo que carga la flor.',
  ),
  StageNutritionRule(
    stageKeys: <String>{'fruit_set'},
    windowNutrients: <AgroMetricKey>{AgroMetricKey.n, AgroMetricKey.k},
    labelEs: 'Cuajado',
    timingEs: 'Tras el cuajado, fraccionado en el riego.',
    rationaleEs: 'Modera el N para reducir caída de fruto; el K empieza a acompañar.',
  ),
  StageNutritionRule(
    stageKeys: <String>{'fruit_fill'},
    windowNutrients: <AgroMetricKey>{AgroMetricKey.k},
    isCritical: true,
    labelEs: 'Llenado de fruto',
    timingEs: 'Durante el crecimiento del fruto, fraccionado en el riego.',
    rationaleEs: 'El fruto se lleva la mayor parte del K del año: calibre y calidad.',
  ),
  StageNutritionRule(
    stageKeys: <String>{'harvest_maturity'},
    windowNutrients: <AgroMetricKey>{},
    labelEs: 'Cosecha',
    rationaleEs: 'Ventana cerrada: N cerca de cosecha retrasa color y baja calidad.',
  ),
  StageNutritionRule(
    stageKeys: <String>{'post_harvest'},
    windowNutrients: <AgroMetricKey>{AgroMetricKey.n, AgroMetricKey.p, AgroMetricKey.k},
    labelEs: 'Post-cosecha',
    timingEs: 'Después de cosechar, con el flujo vegetativo siguiente.',
    rationaleEs: 'Restitución del ciclo: repone lo que se llevó la fruta.',
  ),
];

const Map<AgroMetricKey, List<String>> _treeSources = <AgroMetricKey, List<String>>{
  AgroMetricKey.n: <String>['Nitrato de calcio', 'Sulfato de amonio (21-0-0-24S)', 'Urea (46-0-0)'],
  AgroMetricKey.p: <String>['MAP (11-52-0)', 'Ácido fosfórico (fertirriego)'],
  AgroMetricKey.k: <String>['Sulfato de potasio (0-0-50)', 'Nitrato de potasio (13-0-46)'],
};

NutritionGuide _treeGuide({
  required String cropKey,
  required String labelEs,
  required bool deciduous,
  String? notesEs,
}) => NutritionGuide(
  cropKey: cropKey,
  cropLabelEs: labelEs,
  auditStatus: GuideAuditStatus.proposed,
  sources: const <GuideSource>[_srcTreeRestitution],
  stageRules: deciduous ? _deciduousTreeRules : _evergreenTreeRules,
  sourceOptionsEs: _treeSources,
  generalRulesEs: _rulesTrees,
  usesTreeRestitution: true,
  notesEs: notesEs,
);

// ═══════════════════════════════════════════════════════════════════════════
// ORNAMENTALES Y PLANTAS DE BAJA DEMANDA (sin plan en kg/ha)
// ═══════════════════════════════════════════════════════════════════════════

const NutritionGuide _rose = NutritionGuide(
  cropKey: 'rose',
  cropLabelEs: 'Rosal',
  auditStatus: GuideAuditStatus.proposed,
  stageRules: <StageNutritionRule>[
    StageNutritionRule(
      stageKeys: <String>{'installation_establishment', 'root_establishment'},
      windowNutrients: <AgroMetricKey>{AgroMetricKey.p},
      labelEs: 'Establecimiento',
      rationaleEs: 'P para raíz; sin N fuerte hasta que arraigue.',
    ),
    StageNutritionRule(
      stageKeys: <String>{'vegetative_flush'},
      windowNutrients: <AgroMetricKey>{AgroMetricKey.n},
      labelEs: 'Brotación',
      timingEs: 'Al inicio de cada brotación, dosis ligera y con riego.',
      rationaleEs: 'El N sostiene el brote que traerá el botón.',
      rulesEs: <String>['N alto con brotación muy vigorosa da tallo blando y menos flor.'],
    ),
    StageNutritionRule(
      stageKeys: <String>{'bud_formation'},
      windowNutrients: <AgroMetricKey>{AgroMetricKey.k, AgroMetricKey.p},
      labelEs: 'Botón',
      rationaleEs: 'P y K para tamaño y color de la flor.',
    ),
    StageNutritionRule(
      stageKeys: <String>{'flowering'},
      windowNutrients: <AgroMetricKey>{},
      labelEs: 'Floración',
      rationaleEs: 'Disfruta la flor; el fertilizante espera a después del corte.',
    ),
    StageNutritionRule(
      stageKeys: <String>{'post_bloom_recovery'},
      windowNutrients: <AgroMetricKey>{AgroMetricKey.n, AgroMetricKey.k},
      labelEs: 'Recuperación tras la floración',
      timingEs: 'Tras la poda de flores marchitas.',
      rationaleEs: 'Repone lo que gastó la floración y prepara la siguiente.',
    ),
    StageNutritionRule(
      stageKeys: <String>{'rest'},
      windowNutrients: <AgroMetricKey>{},
      labelEs: 'Reposo',
      rationaleEs: 'Sin fertilizar en reposo.',
    ),
  ],
  generalRulesEs: <String>[
    'Dosis ligeras y frecuentes; con maceta o suelo salino, riega de más para lavar.',
  ],
  notesEs: 'Sin plan en kg/ha: la dosis va por etiqueta del producto y tamaño de planta.',
);

const List<StageNutritionRule> _annualOrnamentalRules = <StageNutritionRule>[
  StageNutritionRule(
    stageKeys: <String>{'sowing', 'germination', 'emergence'},
    windowNutrients: <AgroMetricKey>{AgroMetricKey.p},
    labelEs: 'Siembra',
    rationaleEs: 'P en el fondo para raíz; nada de N sobre la semilla.',
  ),
  StageNutritionRule(
    stageKeys: <String>{'early_vegetative_growth', 'active_vegetative_growth'},
    windowNutrients: <AgroMetricKey>{AgroMetricKey.n},
    labelEs: 'Crecimiento vegetativo',
    timingEs: 'Fraccionado, con riego.',
    rationaleEs: 'El N construye la planta antes del botón.',
  ),
  StageNutritionRule(
    stageKeys: <String>{'stem_elongation', 'bud_formation'},
    windowNutrients: <AgroMetricKey>{AgroMetricKey.k, AgroMetricKey.p},
    labelEs: 'Alargamiento y botón',
    rationaleEs: 'K para tallo firme y color; el N alto aquí acuesta la planta y retrasa la flor.',
    rulesEs: <String>['Corta el N al ver el botón.'],
  ),
  StageNutritionRule(
    stageKeys: <String>{'flowering', 'post_bloom', 'senescence', 'cycle_complete'},
    windowNutrients: <AgroMetricKey>{},
    labelEs: 'Floración',
    rationaleEs: 'Ventana cerrada.',
  ),
];

const NutritionGuide _sunflower = NutritionGuide(
  cropKey: 'sunflower',
  cropLabelEs: 'Girasol',
  auditStatus: GuideAuditStatus.proposed,
  stageRules: _annualOrnamentalRules,
  generalRulesEs: <String>['Perfiles altos o de corte: menos N en alargamiento para que no se acueste.'],
  notesEs: 'Girasol ornamental: sin plan en kg/ha.',
);

const NutritionGuide _marigold = NutritionGuide(
  cropKey: 'marigold',
  cropLabelEs: 'Cempasúchil',
  auditStatus: GuideAuditStatus.proposed,
  stageRules: _annualOrnamentalRules,
  generalRulesEs: <String>['Compacto o de corte: el N de más en alargamiento y botón castiga la flor.'],
  notesEs: 'Sin plan en kg/ha.',
);

const NutritionGuide _tulip = NutritionGuide(
  cropKey: 'tulip',
  cropLabelEs: 'Tulipán',
  auditStatus: GuideAuditStatus.proposed,
  stageRules: <StageNutritionRule>[
    StageNutritionRule(
      stageKeys: <String>{'bulb_planting', 'rooting_chilling'},
      windowNutrients: <AgroMetricKey>{AgroMetricKey.p},
      labelEs: 'Plantación del bulbo',
      rationaleEs: 'Un poco de P bajo el bulbo; el bulbo trae sus reservas.',
    ),
    StageNutritionRule(
      stageKeys: <String>{'shoot_emergence', 'vegetative_growth', 'stem_elongation', 'bud_formation', 'flowering'},
      windowNutrients: <AgroMetricKey>{},
      labelEs: 'Brote y flor',
      rationaleEs: 'La flor de este año viene del bulbo: fertilizar ahora aporta poco.',
    ),
    StageNutritionRule(
      stageKeys: <String>{'bulb_recharge'},
      windowNutrients: <AgroMetricKey>{AgroMetricKey.n, AgroMetricKey.k, AgroMetricKey.p},
      labelEs: 'Recarga del bulbo',
      timingEs: 'Justo tras la floración, mientras la hoja sigue verde.',
      rationaleEs: 'Lo que absorba ahora es la flor del año que viene.',
    ),
    StageNutritionRule(
      stageKeys: <String>{'foliage_senescence', 'dormancy'},
      windowNutrients: <AgroMetricKey>{},
      labelEs: 'Reposo',
      rationaleEs: 'Sin fertilizar.',
    ),
  ],
  notesEs: 'Sin plan en kg/ha.',
);

const List<StageNutritionRule> _lowDemandRules = <StageNutritionRule>[
  StageNutritionRule(
    stageKeys: <String>{'installation_establishment', 'root_establishment'},
    windowNutrients: <AgroMetricKey>{},
    labelEs: 'Establecimiento',
    rationaleEs: 'Sin fertilizar hasta que arraigue; el exceso pudre raíz.',
  ),
  StageNutritionRule(
    stageKeys: <String>{'active_growth'},
    windowNutrients: <AgroMetricKey>{AgroMetricKey.n},
    labelEs: 'Crecimiento activo',
    timingEs: 'Una o dos dosis ligeras en la temporada de crecimiento.',
    rationaleEs: 'Planta de baja demanda: poco y diluido es suficiente.',
  ),
  StageNutritionRule(
    stageKeys: <String>{'maintenance', 'rest'},
    windowNutrients: <AgroMetricKey>{},
    labelEs: 'Mantenimiento y reposo',
    rationaleEs: 'Sin fertilizar.',
  ),
];

const List<String> _rulesLowDemand = <String>[
  'Menos es más: dosis a la mitad de la etiqueta y solo con la planta creciendo.',
  'Nunca con el sustrato seco ni en reposo.',
];

NutritionGuide _lowDemandGuide({
  required String cropKey,
  required String labelEs,
  String? notesEs,
}) => NutritionGuide(
  cropKey: cropKey,
  cropLabelEs: labelEs,
  auditStatus: GuideAuditStatus.proposed,
  stageRules: _lowDemandRules,
  generalRulesEs: _rulesLowDemand,
  notesEs: notesEs ?? 'Planta de baja demanda: sin plan en kg/ha.',
);

// ═══════════════════════════════════════════════════════════════════════════
// TABLA
// ═══════════════════════════════════════════════════════════════════════════

/// Guías registradas por clave de cultivo canónica (sin el prefijo `crop_`).
///
/// No es `const` porque los frutales y las plantas de baja demanda se arman
/// con una función; el mapa es inmutable de todos modos.
final Map<String, NutritionGuide> kNutritionGuides = Map<String, NutritionGuide>.unmodifiable(
  <String, NutritionGuide>{
    // Cereales y leguminosas.
    'maize': _maize,
    'wheat': _wheat,
    'barley': _barley,
    'oat': _oat,
    'bean': _bean,
    // Solanáceas y cucurbitáceas.
    'tomato': _tomato,
    'chili': _chili,
    'cucumber': _cucumber,
    'eggplant': _eggplant,
    'squash': _squash,
    // Hoja y Allium.
    'lettuce': _lettuce,
    'spinach': _spinach,
    'onion': _onion,
    'garlic': _garlic,
    // Frutales (restitución).
    'apple_tree': _treeGuide(cropKey: 'apple_tree', labelEs: 'Manzano', deciduous: true),
    'pear_tree': _treeGuide(cropKey: 'pear_tree', labelEs: 'Peral', deciduous: true),
    'peach_tree': _treeGuide(cropKey: 'peach_tree', labelEs: 'Durazno', deciduous: true),
    'walnut_tree': _treeGuide(cropKey: 'walnut_tree', labelEs: 'Nogal', deciduous: true),
    'pistachio_tree': _treeGuide(
      cropKey: 'pistachio_tree',
      labelEs: 'Pistache',
      deciduous: true,
      notesEs: 'Alternancia marcada: en año de carga alta sube la restitución de K.',
    ),
    'orange_tree': _treeGuide(cropKey: 'orange_tree', labelEs: 'Naranjo', deciduous: false),
    'lemon_tree': _treeGuide(cropKey: 'lemon_tree', labelEs: 'Limonero', deciduous: false),
    'mango_tree': _treeGuide(
      cropKey: 'mango_tree',
      labelEs: 'Mango',
      deciduous: false,
      notesEs: 'N alto antes de floración favorece flujo vegetativo y menos flor.',
    ),
    'avocado_tree': _treeGuide(
      cropKey: 'avocado_tree',
      labelEs: 'Aguacate',
      deciduous: false,
      notesEs: 'Raíz superficial y sensible a sales: dosis pequeñas y frecuentes.',
    ),
    // Ornamentales y baja demanda.
    'rose': _rose,
    'sunflower': _sunflower,
    'marigold': _marigold,
    'tulip': _tulip,
    'cactus': _lowDemandGuide(cropKey: 'cactus', labelEs: 'Cactus'),
    'succulent': _lowDemandGuide(cropKey: 'succulent', labelEs: 'Suculenta'),
    'aloe': _lowDemandGuide(cropKey: 'aloe', labelEs: 'Sábila'),
    'agave': _lowDemandGuide(cropKey: 'agave', labelEs: 'Agave'),
    'nopal': _lowDemandGuide(
      cropKey: 'nopal',
      labelEs: 'Nopal',
      notesEs:
          'Nopal verdura: responde a estiércol o composta en crecimiento activo; '
          'sin plan mineral en kg/ha hasta auditar.',
    ),
  },
);
