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
// fuente. Desde el 6 sep 2026 (decisión de producto) sus rangos SÍ se
// muestran, siempre como «dosis orientativa (guía curada)» con fuente y
// reparto a la vista; auditar un cultivo (`audited`) solo cambia ese
// calificativo. Ver `docs/AUDITORIA_GUIAS_NUTRICION_2026-09.md`.
//
// CÓMO LEER UN PLAN DE TEMPORADA
// ------------------------------
// · Los rangos son para producción comercial de riego en México a rendimiento
//   medio (el rendimiento supuesto va en `notesEs`). Temporal o bajo insumo:
//   tomar el mínimo o menos. Siempre ajustar con análisis de suelo.
// · `seasonShare` reparte ese plan entre etapas; la suma por nutriente no
//   pasa de 1.0. `windowDoseFor` multiplica plan × share. Un nutriente con
//   reparto en una etapa pero fuera de `windowNutrients` es un
//   ACOMPAÑAMIENTO (fertirriego de fondo: «acompaña con K₂O …»): se dosifica,
//   pero no abre ventana ni pesa en el score; `windowNutrients` marca el foco
//   de la etapa, que es lo que el sensor observa.
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
  splitRequirement: NitrogenSplitRequirement.splitRecommended,
  minNitrogenPasses: 2,
  minNitrogenPassesCoarse: 3,
  minNitrogenPassesFine: 1,
  // Prioridad para un plan concentrado (verificación del 17 sep 2026 con
  // Purdue, Nebraska EC117, Wisconsin/Bundy, Clark 2020 y Missouri/Scharf):
  // la pasada única va en V6–V8 —justo antes del arranque de absorción
  // rápida; nunca pierde frente a la siembra y gana en arenoso—; con dos
  // pasadas, siembra (1/3) + V6–V8 (2/3), que es el «siembra + primer riego
  // de auxilio» de INIFAP; con tres, el plan completo 33/40/27.
  nitrogenPassPriority: <String>['vegEarly', 'germination', 'vegAdvanced'],
  splitNotesEs:
      'Clark et al. (2020, 49 sitio-años en 8 estados): fraccionar frente a '
      'aplicar todo a la siembra cambió el rendimiento en menos del 15 % de '
      'los casos, y la única fue mejor en suelos con más arcilla. En arena la '
      'cobertera gana: Wisconsin (Hancock, riego) rindió 30 bu/ac más con el '
      'N a las 4 y 7 semanas que en presiembra y recuperó 79 % del N contra '
      '45 %. Purdue y Nebraska: la aplicación más eficiente es justo antes '
      'de V6–V8. INIFAP Chihuahua: mitad a la siembra y mitad antes del '
      'primer riego de auxilio. Con más de 35 % de arcilla y urea '
      'incorporada, una sola aplicación es defendible.',
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
      minKgPerHa: 50,
      maxKgPerHa: 80,
      sourceEs:
          'Reposición de extracción (0.37 lb P₂O₅/bu = 6.6 kg/t; Ohio State '
          'Tri-State, Iowa State PM 1688) y Yara MX',
      notesEs:
          'Todo al fondo. A 8 t/ha el grano se lleva 53 kg P₂O₅/ha y a 12 t/ha '
          '79: por eso el piso es 50 y no 40. Con Olsen-P > 20 ppm basta el mínimo.',
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
      timingEs:
          'Antes de sembrar o al sembrar, en banda a un lado y debajo de la '
          'semilla.',
      rationaleEs:
          'El fósforo pesa más al arranque: da raíz, energía y plantas '
          'parejas. Un tercio del nitrógeno va junto para que la planta no '
          'llegue corta a las 6 hojas.',
      rulesEs: <String>[
        'No pongas urea en contacto con la semilla: quema la germinación.',
      ],
    ),
    StageNutritionRule(
      stageKeys: <String>{'vegEarly', 'vegMid'},
      windowNutrients: <AgroMetricKey>{AgroMetricKey.n},
      seasonShare: <AgroMetricKey, double>{AgroMetricKey.n: 0.40},
      isCritical: true,
      labelEs: 'Segunda fertilización (V6–V8)',
      timingEs:
          'Cuando la planta tiene de 6 a 8 hojas (V6–V8, unos 40–60 cm), antes '
          'de que cierre el surco y con riego o lluvia enseguida.',
      rationaleEs:
          'De las 6 hojas a la floración el maíz toma más de la mitad del '
          'nitrógeno de todo el ciclo. Quedarse corto aquí es lo que más '
          'rendimiento cuesta.',
      rulesEs: <String>[
        'Incorpora la urea o riega en las 24 h siguientes; en superficie y con '
            'calor se volatiliza.',
        'Si el suelo viene seco no apliques: espera al riego y aplica con él.',
        'No mandes todo el nitrógeno de cobertera de una vez: el maíz todavía '
            'tiene por delante su tramo de mayor consumo.',
      ],
    ),
    StageNutritionRule(
      stageKeys: <String>{'vegAdvanced'},
      windowNutrients: <AgroMetricKey>{AgroMetricKey.n},
      seasonShare: <AgroMetricKey, double>{AgroMetricKey.n: 0.27},
      isCritical: true,
      labelEs: 'Tercera fertilización (V10–V12)',
      timingEs:
          'De las 10 a las 12 hojas, mientras todavía entre la maquinaria o '
          'con el riego si es pivote o fertirriego.',
      rationaleEs:
          'Aquí está el tramo de mayor consumo diario de nitrógeno de todo el '
          'ciclo: entre V10 y V14 el maíz toma cerca de 8 kg/ha al día. Es la '
          'ventana que el manejo tradicional se salta.',
      rulesEs: <String>[
        'Si ya no entra el tractor, aplícalo con el riego; al voleo sobre hoja '
            'seca se pierde.',
      ],
    ),
    StageNutritionRule(
      stageKeys: <String>{'tasseling', 'flowerSet'},
      windowNutrients: <AgroMetricKey>{},
      labelEs: 'Espigamiento y floración',
      rationaleEs:
          'Todavía queda cerca de un tercio del nitrógeno por absorber, pero '
          'solo lo aprovechas si puedes meterlo con el agua. En seco ya no '
          'llega y retrasa la madurez.',
      rulesEs: <String>[
        'Solo con fertirriego o pivote vale la pena un refuerzo aquí, y nunca '
            'pasando el inicio del llenado.',
        'Evita N tardío en surco cerrado: no llega y retrasa la madurez.',
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
  splitRequirement: NitrogenSplitRequirement.splitRequired,
  minNitrogenPasses: 2,
  minNitrogenPassesCoarse: 2,
  // Orden de reserva para un plan concentrado (17 sep 2026; el mínimo de 2
  // sigue mandando): en riego el encañe pesa más que la siembra (Fitotecnia
  // 2022: todo al encañe 4,850 vs todo a la siembra 4,786 kg/ha; CIMMYT
  // Yaqui: 30 % del N presiembra se pierde y el primer riego es la etapa
  // crítica; K-State: N en la raíz antes del encañe). En temporal el orden
  // se invierte (NDSU, K-State) —pendiente de la fase del sistema de riego.
  nitrogenPassPriority: <String>['tillering', 'germination'],
  splitNotesEs:
      'Bajo riego, todo el N en una sola pasada rindió cerca de 30 % menos '
      'que el reparto 30/70 entre siembra y encañe, ya fuera todo a la '
      'siembra (4,786 kg/ha) o todo al encañe (4,850) frente a 6,822 con '
      '30/70 (INIFAP Celaya, Fitotecnia Mexicana 2022, ¹⁵N). CIMMYT (Valle '
      'del Yaqui): 30 % del nitrógeno de presiembra ya se perdió al sembrar; '
      'recomienda 30 % siembra / 55 % primer riego / 15 % floración.',
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
      minKgPerHa: 150,
      maxKgPerHa: 240,
      sourceEs:
          'Extracción MAPA (30 kg N/t), algoritmo NDVI del Bajío (173 kg N/ha '
          'para 7.5 t/ha) y práctica regional 240-60-00',
      notesEs:
          'Para 5–7 t/ha en riego. Extracción 28–40 kg N por tonelada (MAPA): '
          'a 5 t/ha son 150 kg N/ha, así que el piso escala con tu meta. En '
          'Sonora se logran 7 t/ha con 120 kg N/ha bajo labranza de '
          'conservación. Suelos barriales con alto residual: mínimo.',
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
        AgroMetricKey.n: 0.30,
        AgroMetricKey.p: 1.0,
        AgroMetricKey.k: 1.0,
      },
      labelEs: 'Fertilización de siembra',
      timingEs: 'Antes de sembrar o al sembrar, con todo el fósforo.',
      rationaleEs:
          'El fósforo puesto desde la siembra da raíz y macollos parejos. El '
          'nitrógeno de arranque no debe pasar de un tercio: repartirlo 30–70 '
          'rindió 8.4 % más que el 50–50 tradicional en El Bajío.',
    ),
    StageNutritionRule(
      stageKeys: <String>{'tillering', 'elongation'},
      windowNutrients: <AgroMetricKey>{AgroMetricKey.n},
      seasonShare: <AgroMetricKey, double>{AgroMetricKey.n: 0.70},
      isCritical: true,
      labelEs: 'Fin de amacollamiento e inicio de encañe',
      timingEs:
          'Al cerrar el amacollamiento y arrancar el encañe, alrededor de los '
          '40–50 días desde la siembra, con el primer riego de auxilio.',
      rationaleEs:
          'Es la ventana que más rendimiento decide. El ensayo con nitrógeno '
          'marcado de Celaya puso aquí el 70 % de la dosis y ganó 8.4 % de '
          'rendimiento con la mejor eficiencia de uso (41 %); el algoritmo de '
          'NDVI del Bajío coloca el complemento en el mismo momento, a los 45 '
          'días.',
      rulesEs: <String>[
        'Aplica justo antes del riego para que el N baje a la zona de raíces.',
        'Adelantarlo al amacollamiento temprano rinde menos: espera a que '
            'empiece a encañar.',
        'Dosis altas de N sin K suficiente aumentan el acame.',
      ],
    ),
    StageNutritionRule(
      stageKeys: <String>{'booting', 'heading', 'flowering'},
      windowNutrients: <AgroMetricKey>{},
      labelEs: 'Espigamiento y floración',
      rationaleEs:
          'El nitrógeno en espigamiento ya casi no sube el rendimiento: solo '
          'la proteína del grano, y con riesgo de acame si te pasas.',
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
  splitRequirement: NitrogenSplitRequirement.toleratesSingle,
  minNitrogenPasses: 1,
  minNitrogenPassesCoarse: 2,
  recommendedNitrogenPasses: 1,
  // La única va a la siembra (NDSU: todo presiembra; INIFAP Alina 120-60 a
  // la siembra; CINVESTAV/INIFAP ¹⁵N todo a la siembra; MAPA): con dos
  // pasadas, la segunda antes de 5 hojas (verificación del 17 sep 2026).
  nitrogenPassPriority: <String>['germination', 'tillering'],
  splitNotesEs:
      'NDSU (2023) prescribe todo el N presiembra en cebada maltera: la '
      'cobertura después de 5 hojas sube la proteína y arriesga el rechazo '
      'maltero. Montana admite una segunda dosis antes del encañe. Nunca N '
      'después del encañe.',
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
      maxKgPerHa: 130,
      sourceEs:
          'INIFAP Bajío (Alina y Armida, 120 N), MAPA (25 kg N/t) y Montana '
          'State (1.2 lb N disponible por bushel de malta ≈ 25 kg N/t)',
      notesEs:
          'Para 4–6 t/ha en riego; temporal Valles Altos 60–90. El techo es de '
          'CALIDAD, no de rendimiento: con más nitrógeno sí rinde más grano, '
          'pero la proteína pasa del 12 % que la malta mexicana acepta y el '
          'lote se rechaza. Para cebada forrajera sí puedes subir a 160–180.',
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
      timingEs: 'Al sembrar, con todo el fósforo y la mitad del nitrógeno.',
      rationaleEs:
          'El fósforo al arranque ayuda a enraizar y macollar parejo; en '
          'riego, la recomendación regional pone la dosis completa a la '
          'siembra.',
    ),
    StageNutritionRule(
      stageKeys: <String>{'tillering', 'elongation'},
      windowNutrients: <AgroMetricKey>{AgroMetricKey.n},
      seasonShare: <AgroMetricKey, double>{AgroMetricKey.n: 0.5},
      isCritical: true,
      labelEs: 'Amacollamiento',
      timingEs: 'Entre el amacollamiento y el inicio del encañe, con riego.',
      rationaleEs:
          'El nitrógeno del amacollamiento define macollos y espigas; después '
          'del encañe solo sube la proteína.',
      rulesEs: <String>[
        'Cebada maltera: el reabono va como muy tarde a las 5 hojas y nunca '
            'después de que empiece a encañar. Lo que entre después va a '
            'proteína, no a grano, y la malta se rechaza arriba de 12 %.',
        'Descuenta el nitrato que ya trae el suelo: es lo que decide entre un '
            'lote de 11.5 % y uno de 13 % de proteína.',
      ],
    ),
    StageNutritionRule(
      stageKeys: <String>{'booting', 'heading', 'flowering', 'grainFill'},
      windowNutrients: <AgroMetricKey>{},
      labelEs: 'Espigamiento y llenado',
      rationaleEs:
          'Ventana cerrada para el nitrógeno: en cebada maltera, aplicarlo '
          'tarde sube la proteína del grano y perjudica la calidad.',
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
  splitRequirement: NitrogenSplitRequirement.toleratesSingle,
  minNitrogenPasses: 1,
  minNitrogenPassesCoarse: 2,
  recommendedNitrogenPasses: 1,
  // La única va a la siembra (INIFAP Zacatecas 100-60-00 presiembra;
  // INIFAP Chihuahua 60-40-00 a la siembra + 20–40 opcional en
  // amacollamiento; NDSU en grano pequeño), verificación del 17 sep 2026.
  nitrogenPassPriority: <String>['germination', 'tillering'],
  splitNotesEs:
      'INIFAP Chihuahua: 60-40-00 a la siembra, con segunda aplicación '
      'opcional de 20–40 kg N/ha en amacollamiento. Dosis bajas: poco N en '
      'riesgo por evento. No hay ensayo directo única-vs-fraccionada en '
      'avena.',
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
      timingEs: 'Al sembrar, con todo el fósforo.',
      rationaleEs:
          'El fósforo al arranque favorece la raíz y el vigor temprano, sobre '
          'todo en suelo frío.',
    ),
    StageNutritionRule(
      stageKeys: <String>{'tillering', 'elongation'},
      windowNutrients: <AgroMetricKey>{AgroMetricKey.n},
      seasonShare: <AgroMetricKey, double>{AgroMetricKey.n: 0.6},
      isCritical: true,
      labelEs: 'Amacollamiento',
      timingEs: 'Al amacollamiento, con el primer riego de auxilio.',
      rationaleEs:
          'El nitrógeno del amacollamiento impulsa macollos y panículas: es '
          'donde más forraje devuelve cada kilo.',
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
  generalRulesEs: <String>[
    'Si vas a dar un segundo corte, agrega 50 kg N/ha más después del primero: '
        'la avena rebrota con lo que le repongas, no con lo que quedó.',
    'En multicorte el potasio deja de ser opcional: te llevas la planta '
        'entera, no solo el grano.',
    ..._rulesCommonField,
  ],
  notesEs:
      'Plan para avena forrajera de riego en el norte-centro de México. Con un '
      'corte único tardío (grano lechoso-masoso, ~155 días) INIFAP Zacatecas '
      'reporta 10–13 t MS/ha; con cortes tempranos o multicorte, 4.5–6.5.',
);

// ═══════════════════════════════════════════════════════════════════════════
// LEGUMINOSAS
// ═══════════════════════════════════════════════════════════════════════════

const NutritionGuide _bean = NutritionGuide(
  cropKey: 'bean',
  cropLabelEs: 'Frijol',
  splitRequirement: NitrogenSplitRequirement.toleratesSingle,
  minNitrogenPasses: 1,
  minNitrogenPassesCoarse: 2,
  recommendedNitrogenPasses: 1,
  singlePassStageKey: 'vegEarly',
  // Riego: la única en la primera escarda (Henson & Bliss 1991; Frontiers
  // 2020: el N a la siembra apaga la fijación, Ndfa 45 → 20 %). En temporal
  // INIFAP fertiliza a la siembra con el fósforo (30-50-00); el orden
  // invertido queda pendiente de la fase del sistema de riego (17 sep 2026).
  nitrogenPassPriority: <String>['vegEarly', 'germination'],
  splitNotesEs:
      'Henson & Bliss (1991, 3 años): una sola aplicación en vegetativo '
      'temprano superó tanto a la de siembra como al fraccionamiento. '
      'Nebraska G1713: el frijol sí necesita 112–140 kg N/ha además del que '
      'fija.',
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
      minKgPerHa: 40,
      maxKgPerHa: 100,
      sourceEs:
          'INIFAP Sinaloa: 40–60 tras leguminosa u hortaliza, 80–100 tras maíz '
          'o sorgo; paquete de riego de Chihuahua 40-60-00',
      notesEs:
          'N de arranque, antes de que la planta nodule: el frijol fija N del '
          'aire. La mitad del rango depende de qué sembraste antes: tras '
          'leguminosa u hortaliza quédate en 40–60; tras maíz o sorgo necesitas '
          '80–100 porque el residuo se lleva el nitrógeno. Si a los 30 días '
          'abres un nódulo y sale blanco por dentro, la fijación falló: repón '
          '80–100 con el primer riego de auxilio.',
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
      timingEs:
          'Al sembrar, en banda: todo el fósforo y la mayor parte del '
          'nitrógeno de arranque.',
      rationaleEs:
          'El fósforo es clave para que el frijol forme bien sus nódulos desde '
          'el arranque; el nitrógeno de arranque cubre las semanas en que los '
          'nódulos todavía no fijan.',
    ),
    StageNutritionRule(
      stageKeys: <String>{'vegEarly', 'vegAdvanced'},
      windowNutrients: <AgroMetricKey>{AgroMetricKey.n},
      seasonShare: <AgroMetricKey, double>{AgroMetricKey.n: 0.4},
      labelEs: 'Primera escarda (antes de floración)',
      timingEs: 'En la primera escarda, antes de que abra la primera flor.',
      rationaleEs:
          'Es la segunda aplicación de la práctica regional: sostiene el vigor '
          'hasta la floración sin frenar la nodulación.',
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
          'Aquí el frijol usa el nitrógeno para proteína y el potasio para '
          'regular el agua; lo que rinde es no estresar la planta, no '
          'fertilizar tarde.',
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
  splitRequirement: NitrogenSplitRequirement.splitRequired,
  minNitrogenPasses: 2,
  minNitrogenPassesCoarse: 3,
  // Mínimo 2 desde el 17 sep 2026 (antes 3): en riego rodado y suelo pesado
  // dos pasadas son la práctica documentada —UC IPM tomate: arranque + «una
  // sola cobertera de 100–120 lb N/ac normalmente basta»; UC ANR pimiento:
  // «presiembra y una o más coberteras»; UF/IFAS pepino, calabacita y
  // berenjena: 2–3 aplicaciones—; en arena siguen siendo 3. La única sigue
  // prohibida. La pasada grande va a floración-cuajado (CDFA: menos del
  // 30 % del N se absorbe antes del cuaje; NMSU: la ventana óptima arranca
  // con la primera flor).
  nitrogenPassPriority: <String>['floracion', 'vegetativo', 'llenado', 'germinacion'],
  splitNotesEs:
      'CDFA / UC Davis: menos del 30 % del N se absorbe antes del cuaje; '
      'presiembra ≤ 34 kg N/ha por lixiviación. El nitrógeno solo al inicio '
      'es ineficiente. UC IPM (riego rodado): arranque más una sola cobertera '
      'de 112–134 kg N/ha «normalmente basta para terminar el cultivo»; en '
      'arena o goteo, tres o más.',
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
      minKgPerHa: 120,
      maxKgPerHa: 180,
      sourceEs:
          'UC IPM / CDFA-FREP (100–200 lb K₂O/acre según análisis de suelo)',
      notesEs:
          'El tomate es un cultivo de potasio, pero el suelo suele traerlo: UC '
          'Davis no encontró más rendimiento arriba de 235 kg K₂O/ha ni '
          'siquiera a 112 t/ha. Sube a 220 solo si tu análisis sale abajo de '
          '130 ppm de potasio intercambiable; con más de 200 ppm bastan 60.',
    ),
  },
  stageRules: <StageNutritionRule>[
    StageNutritionRule(
      stageKeys: <String>{'germinacion', 'establecimiento'},
      windowNutrients: <AgroMetricKey>{AgroMetricKey.p, AgroMetricKey.n},
      seasonShare: <AgroMetricKey, double>{
        AgroMetricKey.n: 0.13,
        AgroMetricKey.p: 0.5,
        AgroMetricKey.k: 0.10,
      },
      labelEs: 'Trasplante y arranque',
      timingEs:
          'Fondo antes del trasplante (todo el fósforo si el riego es rodado) '
          'y arranque suave las dos primeras semanas.',
      rationaleEs:
          'Antes del cuajado la planta toma menos del 30 % del nitrógeno: al '
          'arranque manda el fósforo, para la raíz.',
      rulesEs: <String>[
        'Preplantación: no más de 33 kg N/ha (tope de CDFA-FREP); el resto se '
            'lava antes de que la planta lo use.',
      ],
    ),
    StageNutritionRule(
      stageKeys: <String>{'vegetativo'},
      windowNutrients: <AgroMetricKey>{AgroMetricKey.n},
      seasonShare: <AgroMetricKey, double>{
        AgroMetricKey.n: 0.27,
        AgroMetricKey.p: 0.2,
        AgroMetricKey.k: 0.15,
      },
      labelEs: 'Vegetativo',
      timingEs:
          'Cada semana en fertirriego; en riego rodado, en la primera escarda.',
      rationaleEs:
          'Construye la planta que va a sostener los racimos, sin excesos que '
          'retrasen la flor.',
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
          'La mayor parte del crecimiento y de la toma de nitrógeno ocurre '
          'entre el cuajado temprano y el primer fruto rojo; el potasio '
          'empieza a mandar aquí.',
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
      timingEs:
          'Fertirriego continuo hasta que los primeros frutos cambian de '
          'color.',
      rationaleEs:
          'El potasio da tamaño, firmeza y color; el nitrógeno aplicado '
          'después del primer fruto rojo se queda en el suelo y se lava.',
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
  splitRequirement: NitrogenSplitRequirement.splitRequired,
  minNitrogenPasses: 2,
  minNitrogenPassesCoarse: 3,
  // Mínimo 2 desde el 17 sep 2026 (UC ANR pimiento: «N y K en presiembra y
  // en una o más coberteras»); la pasada grande a inicio de floración (NMSU
  // H-257; Panorama: 100-00-00 a inicio de floración).
  nitrogenPassPriority: <String>['floracion', 'vegetativo', 'llenado', 'germinacion'],
  splitNotesEs:
      'NMSU H-257: la demanda se concentra de la fase reproductiva a la '
      'maduración temprana; suspender a mediados de agosto para que madure. '
      'UC ANR: en riego convencional el N va en presiembra y en una o más '
      'coberteras. Sin ensayo directo única-vs-fraccionada.',
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
        AgroMetricKey.n: 0.15,
        AgroMetricKey.p: 0.7,
        AgroMetricKey.k: 0.3,
      },
      labelEs: 'Trasplante (fórmula de arranque)',
      timingEs: 'Al trasplante, en banda (práctica regional 50-60-50).',
      rationaleEs:
          'Arranque con fósforo para la raíz, más una parte del nitrógeno y '
          'del potasio. El nitrógeno va corto a propósito: en zona árida la '
          'referencia de preplante son 11–45 kg/ha, y de más adelanta follaje '
          'y tira botón.',
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
      timingEs:
          'Unos 30 días después del trasplante (práctica regional 50-00-00).',
      rationaleEs:
          'Sostiene el crecimiento hasta el primer botón sin adelantar un '
          'exceso de follaje.',
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
      timingEs:
          'Al inicio de la floración (práctica regional 100-00-00), con riego.',
      rationaleEs:
          'Es la aplicación grande del ciclo: define cuántas flores cuajan y '
          'el tamaño del primer corte.',
    ),
    StageNutritionRule(
      stageKeys: <String>{'llenado', 'cosechaProgresiva'},
      windowNutrients: <AgroMetricKey>{AgroMetricKey.k},
      seasonShare: <AgroMetricKey, double>{
        AgroMetricKey.n: 0.25,
        AgroMetricKey.k: 0.2,
      },
      labelEs: 'Llenado y cortes',
      timingEs:
          'Fertirriego ligero entre cortes; en suelo desnudo, unos 33 kg N/ha '
          'por cada corte extra.',
      rationaleEs:
          'Un jalapeño da de 4 a 8 cortes en 8 a 12 semanas y las vainas se '
          'llevan cerca de 180 kg N/ha del ciclo: si aquí escatimas, el '
          'tercer corte sale chico y amarillo. El potasio sostiene tamaño y '
          'color; lo que no conviene es un golpe fuerte de nitrógeno de una '
          'vez, que solo da hoja.',
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
  splitRequirement: NitrogenSplitRequirement.splitRequired,
  minNitrogenPasses: 2,
  minNitrogenPassesCoarse: 3,
  // Mínimo 2 desde el 17 sep 2026 (UF/IFAS 1963: 80 % fondo + 20 %
  // cobertera rindió más que todo a la siembra); la pasada grande en
  // floración-cuajado.
  nitrogenPassPriority: <String>['floracion', 'vegetativo', 'llenado', 'germinacion'],
  splitNotesEs:
      'UF/IFAS: el pepino rindió más con el N repartido (80 % fondo + 20 % '
      'cobertera) que con todo a la siembra; por analogía con calabaza, en '
      'arena todo presiembra rindió 335 vs 785 bu/ac con dos aplicaciones. '
      'Cucurbitácea de raíz somera y cosecha escalonada.',
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
      minKgPerHa: 120,
      maxKgPerHa: 180,
      sourceEs: 'UF/IFAS por nivel de suelo; extracción en fruto 1.35–2.25 kg K₂O/t',
      notesEs:
          'A 40–60 t/ha el fruto se lleva 54–135 kg K₂O/ha. El extremo alto '
          'solo con análisis bajo de potasio.',
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
      timingEs: 'Fondo antes de la siembra o del trasplante, y arranque suave.',
      rationaleEs:
          'El pepino arranca rápido: necesita el fósforo disponible desde el '
          'primer día.',
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
      timingEs: 'Cada semana en fertirriego, hasta la primera flor.',
      rationaleEs: 'Construye la guía que va a cargar los frutos.',
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
      rationaleEs:
          'La absorción sube al máximo con el cuajado; aquí se decide el '
          'número de frutos.',
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
      rationaleEs:
          'Cada corte se lleva potasio; reponerlo cada semana evita frutos '
          'deformes.',
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
  splitRequirement: NitrogenSplitRequirement.splitRequired,
  minNitrogenPasses: 2,
  minNitrogenPassesCoarse: 3,
  // Mínimo 2 desde el 17 sep 2026 (UF/IFAS: «dos o tres aplicaciones
  // iguales»); la pasada grande en floración-cuajado, como tomate.
  nitrogenPassPriority: <String>['floracion', 'vegetativo', 'llenado', 'germinacion'],
  splitNotesEs:
      'UF/IFAS: cosecha escalonada de varios meses; práctica documentada de '
      '2–5 aplicaciones («dos o tres aplicaciones iguales»), con refuerzo de '
      '30 lb N/ac por cosecha extendida. Sin ensayo directo.',
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
      maxKgPerHa: 220,
      sourceEs: 'UF/IFAS (meseta de rendimiento en 200 lb N/acre)',
      notesEs:
          'Campo abierto a 40–60 t/ha. Arriba de 220 el rendimiento deja de '
          'subir y con 280 empieza a bajar.',
    ),
    AgroMetricKey.p: SeasonNutrientPlan(
      form: NutrientForm.p2o5,
      minKgPerHa: 75,
      maxKgPerHa: 100,
      sourceEs: 'Intagri 1.5–2 kg P₂O₅/t a 50 t/ha',
    ),
    AgroMetricKey.k: SeasonNutrientPlan(
      form: NutrientForm.k2o,
      minKgPerHa: 120,
      maxKgPerHa: 180,
      sourceEs: 'UF/IFAS (óptimo en 160 lb K₂O/acre con análisis bajo)',
      notesEs:
          'Los 270–335 que circulan son la EXTRACCIÓN de un cultivo de '
          'invernadero de 8–11 meses, no una dosis de campo abierto. Con '
          'análisis alto de potasio, cero.',
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
      rationaleEs:
          'Fósforo para la raíz; el nitrógeno en exceso al inicio da follaje y '
          'retrasa la flor y el cuajado.',
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
      timingEs: 'Cada semana en fertirriego.',
      rationaleEs:
          'Es una planta de alta demanda: construye su estructura sin excesos.',
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
      timingEs:
          'Desde las primeras flores hasta el cuajado de los primeros frutos.',
      rationaleEs:
          'La demanda sube con el cuajado; el potasio empieza a mandar.',
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
      rationaleEs:
          'Los frutos acumulan la mayor parte del potasio del ciclo al final.',
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

const NutritionGuide _squash = NutritionGuide(
  cropKey: 'squash',
  cropLabelEs: 'Calabaza',
  splitRequirement: NitrogenSplitRequirement.splitRequired,
  minNitrogenPasses: 2,
  minNitrogenPassesCoarse: 3,
  // Mínimo 2 desde el 17 sep 2026: el propio ensayo de Csizinszky ganó con
  // DOS aplicaciones (50 % fondo + 50 % a mitad de ciclo). La pasada única
  // va a la guía (3–4 semanas, «mid-growth»), justo antes de la flor.
  nitrogenPassPriority: <String>['vegetativo', 'floracion', 'germinacion', 'llenado'],
  splitNotesEs:
      'UF/IFAS (Csizinszky 1985, arena): 100 % presiembra rindió 335 bu/ac '
      'frente a 785 con DOS aplicaciones (50 % al fondo y 50 % a mitad de '
      'ciclo): −57 %. En suelo franco-arcilloso con goteo la brecha es '
      'menor, pero ninguna fuente la cuantifica.',
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
      timingEs: 'Al sembrar o trasplantar, todo el fósforo en banda.',
      rationaleEs:
          'Es un ciclo corto (unos 80 días): lo que no está al arranque llega '
          'tarde.',
    ),
    StageNutritionRule(
      stageKeys: <String>{'vegetativo'},
      windowNutrients: <AgroMetricKey>{AgroMetricKey.n},
      seasonShare: <AgroMetricKey, double>{
        AgroMetricKey.n: 0.25,
        AgroMetricKey.k: 0.25,
      },
      labelEs: 'Guía',
      timingEs: 'Segunda aplicación a las 3–4 semanas, con riego.',
      rationaleEs:
          'La absorción crece de forma pareja durante el ciclo: reparte, no '
          'concentres.',
    ),
    StageNutritionRule(
      stageKeys: <String>{'floracion', 'cuajado'},
      windowNutrients: <AgroMetricKey>{AgroMetricKey.n, AgroMetricKey.k},
      seasonShare: <AgroMetricKey, double>{
        AgroMetricKey.n: 0.25,
        AgroMetricKey.k: 0.25,
      },
      isCritical: true,
      labelEs: 'Floración y cuajado',
      timingEs: 'Con las primeras flores hembra.',
      rationaleEs:
          'Sostiene los cortes que vienen: sin nitrógeno aquí los frutos salen '
          'cortos y claros.',
    ),
    StageNutritionRule(
      stageKeys: <String>{'llenado', 'cosechaProgresiva'},
      windowNutrients: <AgroMetricKey>{AgroMetricKey.n},
      seasonShare: <AgroMetricKey, double>{AgroMetricKey.n: 0.20},
      labelEs: 'Cortes',
      timingEs:
          'Repartido cada 7–10 días mientras estés cortando; en suelo desnudo, '
          'unos 33 kg N/ha por cada corte extra, y en goteo 1.7–2.2 kg/ha al día.',
      rationaleEs:
          'La calabacita se corta seis a diez semanas seguidas y cada corte se '
          'lleva nutrientes. En Florida, cargar todo el fertilizante al frente '
          'costó más de la mitad del rendimiento frente a repartirlo: 335 '
          'contra 785 bushels por acre.',
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
  splitRequirement: NitrogenSplitRequirement.splitRecommended,
  minNitrogenPasses: 2,
  minNitrogenPassesCoarse: 3,
  maxSinglePassKgN: 45,
  // Con dos pasadas: post-aclareo (incondicional, CDFA/UC Davis) y
  // acogollado (la segunda, si el nitrato residual baja de 20 ppm); el
  // fondo queda como arranque con el fósforo (17 sep 2026).
  nitrogenPassPriority: <String>['desarrolloVegetativo', 'formacionCabeza', 'germinacion'],
  splitNotesEs:
      'Arizona / YCEDA: presiembra de 10–40 lb N/ac (11–45 kg/ha) y el '
      'grueso en banda tras el aclareo. Con fertirriego el costo de '
      'fraccionar es casi cero; una dosis única alta acumula nitrato en la '
      'hoja.',
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
      minKgPerHa: 80,
      maxKgPerHa: 120,
      sourceEs: 'CDFA-FREP (remoción con la cosecha, 70–110 lb K₂O/acre)',
      notesEs:
          'Es lo que se va con la lechuga cortada. Con más de 150 ppm de '
          'potasio intercambiable no hace falta aplicar nada.',
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
      timingEs:
          'Fondo antes del trasplante y un arranque de unos 20 kg/ha de '
          'nitrógeno.',
      rationaleEs:
          'El primer mes la lechuga toma menos del 20 % del nitrógeno: aquí '
          'manda el fósforo, para la raíz.',
    ),
    StageNutritionRule(
      stageKeys: <String>{'desarrolloVegetativo'},
      windowNutrients: <AgroMetricKey>{AgroMetricKey.n},
      seasonShare: <AgroMetricKey, double>{
        AgroMetricKey.n: 0.35,
        AgroMetricKey.k: 0.3,
      },
      labelEs: 'Roseta (primera cobertera)',
      timingEs: 'A las 2–4 hojas verdaderas, después del aclareo, con riego.',
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
      timingEs:
          'Al inicio del acogollado, un mes antes de la cosecha; nada en las '
          'últimas dos semanas.',
      rationaleEs:
          'Entre el acogollado y la cosecha la lechuga ABSORBE de 3 a 4.5 '
          'kg/ha de nitrógeno al día, y en ese último mes se lleva el 70–80 % '
          'de todo el ciclo. Por eso el fertilizante se pone ANTES, aquí: si '
          'lo aplicas cuando ya está absorbiendo, llega tarde y se queda como '
          'nitrato en la hoja.',
      rulesEs: <String>[
        'Exceso de N retrasa el cierre de la cabeza.',
      ],
    ),
    StageNutritionRule(
      stageKeys: <String>{'ventanaCosecha', 'sobremadurez'},
      windowNutrients: <AgroMetricKey>{},
      labelEs: 'Cosecha',
      rationaleEs:
          'Ventana cerrada: cualquier nitrógeno ahora se queda como nitrato en '
          'la hoja.',
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
  splitRequirement: NitrogenSplitRequirement.splitRecommended,
  minNitrogenPasses: 2,
  minNitrogenPassesCoarse: 3,
  maxSinglePassKgN: 45,
  // Con dos pasadas: primeras hojas (Acta Agronómica UNAL: el mejor
  // tratamiento fue 90 kg N/ha a los 15 días) y expansión foliar (pico de
  // absorción, UC ANR VRIC 5–7 lb N/ac/día); el fondo solo si el suelo
  // sale bajo (17 sep 2026).
  nitrogenPassPriority: <String>['vegetativoTemprano', 'expansionFoliar', 'germinacion'],
  splitNotesEs:
      'Arizona / YCEDA: ≤ 150 lb N/ac en 4–5 eventos de fertirriego; '
      'presiembra ~15 lb N/ac solo si el suelo sale bajo. Riesgo de nitrato '
      'en hoja con dosis únicas altas.',
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
      minKgPerHa: 80,
      maxKgPerHa: 110,
      sourceEs: 'UF/IFAS por nivel de suelo (100 lb K₂O/acre con análisis bajo)',
      notesEs:
          'En zona árida no hay respuesta documentada al potasio en hoja '
          'mientras el suelo pase de 150 ppm; con análisis alto, cero.',
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
      rationaleEs:
          'Es un ciclo corto: el fósforo y parte del potasio entran en el '
          'fondo.',
    ),
    StageNutritionRule(
      stageKeys: <String>{'vegetativoTemprano'},
      windowNutrients: <AgroMetricKey>{AgroMetricKey.n},
      seasonShare: <AgroMetricKey, double>{
        AgroMetricKey.n: 0.3,
        AgroMetricKey.k: 0.3,
      },
      labelEs: 'Primeras hojas',
      timingEs: 'Con el riego, a las 2–3 hojas verdaderas.',
      rationaleEs:
          'La espinaca es de ciclo corto y raíz chica: conviene darle poco y '
          'seguido, no un golpe grande.',
    ),
    StageNutritionRule(
      stageKeys: <String>{'expansionFoliar'},
      windowNutrients: <AgroMetricKey>{AgroMetricKey.n, AgroMetricKey.k},
      seasonShare: <AgroMetricKey, double>{
        AgroMetricKey.n: 0.4,
        AgroMetricKey.k: 0.3,
      },
      isCritical: true,
      labelEs: 'Expansión foliar',
      timingEs:
          'Repartido en dos o tres riegos entre las 4 y 6 hojas verdaderas.',
      rationaleEs:
          'La hoja se construye aquí. Repartirlo entre los riegos del ciclo, '
          'en vez de meterlo todo de una vez, es lo que evita que el nitrato '
          'se acumule en la hoja.',
      rulesEs: <String>[
        'Ojo si vas a exportar a Europa: la espinaca fresca tiene límite legal '
            'de 3 500 mg de nitrato por kilo, y en invierno con poca luz la '
            'planta lo acumula más.',
      ],
    ),
    StageNutritionRule(
      stageKeys: <String>{'madurezComercial', 'ventanaCosecha', 'perdidaCalidad', 'espigadoSenescencia'},
      windowNutrients: <AgroMetricKey>{},
      labelEs: 'Cosecha',
      rationaleEs:
          'Ventana cerrada: el nitrógeno tardío ablanda la hoja, sube los '
          'nitratos y adelanta el espigado.',
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
  splitRequirement: NitrogenSplitRequirement.splitRequired,
  minNitrogenPasses: 2,
  minNitrogenPassesCoarse: 3,
  maxSinglePassKgN: 112,
  capEveryPass: true,
  // Mínimo 2 desde el 17 sep 2026 (PNW 546: donde la lixiviación es baja,
  // una sola cobertera basta; Fertilab/INIFAP Zacatecas: mitad antes del
  // trasplante y resto a 50 días); en arena, las 3 ventanas del plan. La
  // pasada grande al inicio del bulbo (CDFA: menos del 20 % del N se
  // absorbe en la primera mitad; PNW: aplicar en la iniciación del bulbo).
  nitrogenPassPriority: <String>['induccionBulbificacion', 'vegetativo', 'germinacion'],
  splitNotesEs:
      'PNW 546: ninguna aplicación debe pasar de 100 lb N/ac (112 kg/ha) y '
      'la cebolla absorbe menos del 20 % del N en la primera mitad del '
      'ciclo; donde la lixiviación es baja una sola cobertera basta, y '
      'donde es alta conviene fraccionar. INIFAP Chihuahua prescribe 4 '
      'fracciones. Omitir el N de bulbificación costó −47 % de peso de '
      'bulbo (Machado & Bryla 2016).',
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
      labelEs:
          'NC State Extension, Bulb Onions (120–150 lb N/acre; reducir o '
          'suspender el N al iniciar la bulbificación)',
      url: 'https://content.ces.ncsu.edu/bulb-onions',
    ),
    GuideSource(
      labelEs:
          'PNW 546 (OSU/UI/WSU), Nutrient Management for Onions in the Pacific '
          'Northwest: K₂O = 0 con más de 100 ppm; azufre 30–40 lb/acre solo si '
          'el sulfato del suelo y del agua están por debajo de 5 ppm',
      url: 'https://extension.oregonstate.edu/sites/extd8/files/documents/pnw546.pdf',
    ),
  ],
  seasonPlan: <AgroMetricKey, SeasonNutrientPlan>{
    AgroMetricKey.n: SeasonNutrientPlan(
      form: NutrientForm.n,
      minKgPerHa: 150,
      maxKgPerHa: 200,
      sourceEs: 'INIFAP Zacatecas (200 N); NC State 134–168; CDFA 168–224',
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
      minKgPerHa: 0,
      maxKgPerHa: 150,
      sourceEs: 'PNW 546 y CDFA-FREP, por análisis de suelo',
      notesEs:
          'La tabla del noroeste del Pacífico es tajante: con más de 100 ppm '
          'de potasio intercambiable, cero. Entre 0 y 50 ppm sí van los 150.',
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
      timingEs:
          'Antes del trasplante: todo el fósforo (o el 70 %), no más de un '
          'tercio del nitrógeno y la mitad del potasio.',
      rationaleEs:
          'En la primera mitad del ciclo la cebolla toma menos del 20 % del '
          'nitrógeno: no lo adelantes.',
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
      timingEs:
          'Segundo tercio del nitrógeno a las 3–4 hojas, con riego; en '
          'fertirriego, cada 10–14 días.',
      rationaleEs:
          'Cada hoja es una capa del bulbo: el nitrógeno de esta etapa fija el '
          'tamaño final.',
    ),
    StageNutritionRule(
      stageKeys: <String>{'induccionBulbificacion', 'inicioBulbo'},
      windowNutrients: <AgroMetricKey>{AgroMetricKey.k, AgroMetricKey.n},
      seasonShare: <AgroMetricKey, double>{
        AgroMetricKey.n: 0.35,
        AgroMetricKey.k: 0.4,
      },
      isCritical: true,
      labelEs: 'Inicio de bulbo',
      timingEs:
          'Último tercio del nitrógeno y el potasio restante justo cuando '
          'arranca el bulbo, no después.',
      rationaleEs:
          'Aquí empieza la absorción rápida: la cebolla toma de 1.5 a 4 kg/ha '
          'de nitrógeno al día. Es el último momento en que el nitrógeno se '
          'convierte en bulbo y no en cuello.',
      rulesEs: <String>[
        'Corta el nitrógeno al menos 4 semanas antes de cosechar.',
      ],
    ),
    StageNutritionRule(
      stageKeys: <String>{'llenadoBulbo'},
      windowNutrients: <AgroMetricKey>{},
      labelEs: 'Engrosamiento del bulbo',
      rationaleEs:
          'Ventana cerrada para el nitrógeno. El bulbo lo manda la duración '
          'del día, no el fertilizante: lo que apliques ahora engruesa el '
          'cuello, retrasa la madurez y arruina el guardado.',
      rulesEs: <String>[
        'N fuerte tardío: cuello grueso, mala maduración y bulbos que no guardan.',
      ],
    ),
    StageNutritionRule(
      stageKeys: <String>{'maduracionCosecha', 'espigado'},
      windowNutrients: <AgroMetricKey>{},
      labelEs: 'Maduración',
      rationaleEs: 'Ventana cerrada: deja que seque el cuello y no fertilices.',
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
        'o de potasio cubren ambos. Si tu suelo y tu agua traen menos de 5 ppm '
        'de sulfato, agrega 34–45 kg S/ha; si riegas con agua sulfatada, ya lo '
        'tienes cubierto.',
    'El zinc entra en la fórmula de INIFAP para cebolla: 15 kg Zn/ha.',
    ..._rulesVegetableFertigation,
  ],
  notesEs: 'Plan para cebolla de bulbo de riego a 50–80 t/ha.',
);

const NutritionGuide _garlic = NutritionGuide(
  cropKey: 'garlic',
  cropLabelEs: 'Ajo',
  splitRequirement: NitrogenSplitRequirement.splitRequired,
  minNitrogenPasses: 2,
  minNitrogenPassesCoarse: 3,
  maxSinglePassKgN: 112,
  capEveryPass: true,
  // Mínimo 2 desde el 17 sep 2026 (InfoAgro: plantación + 60 días;
  // Hermosillo usó 5 fracciones en goteo). La pasada grande en desarrollo
  // de hoja (4 de las 5 fracciones de Hermosillo caen ahí).
  nitrogenPassPriority: <String>['vegetativeLeafDevelopment', 'bulbDifferentiation', 'clovePlanting'],
  splitNotesEs:
      'Por extensión desde cebolla: raíz aún más limitada y ciclo de 6–8 '
      'meses. La práctica experimental en México usa 3 fracciones a 30, 60 '
      'y 90 días (Cárdenas et al. 2019) o 5 en goteo (Hermosillo, 1 oct–15 '
      'feb). Sin ensayo directo única-vs-fraccionada en ajo.',
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
      // Mínimo 0 desde el 17 sep 2026 (antes 100): California Agriculture
      // 1988 (10 ensayos de ajo): «el potasio tuvo poco o ningún efecto en
      // el rendimiento» con más de 100 ppm de K intercambiable; PNW 546 y
      // CDFA (Allium) no aplican K₂O con más de 100 ppm. Igual criterio que
      // la cebolla: el máximo solo con análisis bajo.
      minKgPerHa: 0,
      maxKgPerHa: 200,
      sourceEs:
          'Extracción 70–170 kg K/ha a 10 t (InfoAgro); sin respuesta con '
          'K > 100 ppm (Cal Ag 1988, PNW 546, CDFA)',
      notesEs:
          'Solo con análisis de suelo bajo en potasio (menos de 100 ppm); en '
          'diez ensayos de California el ajo no respondió al potasio.',
    ),
  },
  stageRules: <StageNutritionRule>[
    StageNutritionRule(
      stageKeys: <String>{'clovePlanting', 'emergenceEstablishment'},
      windowNutrients: <AgroMetricKey>{AgroMetricKey.p, AgroMetricKey.n},
      seasonShare: <AgroMetricKey, double>{
        AgroMetricKey.n: 0.25,
        AgroMetricKey.p: 1.0,
        AgroMetricKey.k: 0.4,
      },
      labelEs: 'Plantación',
      timingEs:
          'Al plantar: todo el fósforo, una cuarta parte del nitrógeno y parte '
          'del potasio.',
      rationaleEs:
          'El ajo tarda más de 200 días y arranca con una raíz muy chica: el '
          'nitrógeno que le pongas en octubre se lava antes de que lo use. '
          'INIFAP Zacatecas deja solo el 20 % a la plantación, y los ensayos '
          'de Texcoco y Hermosillo no ponen nada.',
    ),
    StageNutritionRule(
      stageKeys: <String>{'vegetativeLeafDevelopment', 'coldInductionVernalization'},
      windowNutrients: <AgroMetricKey>{AgroMetricKey.n, AgroMetricKey.k},
      seasonShare: <AgroMetricKey, double>{
        AgroMetricKey.n: 0.40,
        AgroMetricKey.k: 0.3,
      },
      isCritical: true,
      labelEs: 'Desarrollo de hoja (primera escarda)',
      timingEs:
          'Repartido entre la primera escarda (unos 60 días) y las semanas '
          'siguientes, mientras siga echando hoja.',
      rationaleEs:
          'Cada hoja que se forma aquí es un diente después. Es la etapa que '
          'más define el tamaño del bulbo.',
      rulesEs: <String>[
        'La vernalización no se corrige con fertilizante: si el ajo no recibió '
            'frío, más N no hará bulbo.',
      ],
    ),
    StageNutritionRule(
      stageKeys: <String>{'bulbDifferentiation'},
      windowNutrients: <AgroMetricKey>{AgroMetricKey.n, AgroMetricKey.k},
      seasonShare: <AgroMetricKey, double>{
        AgroMetricKey.n: 0.35,
        AgroMetricKey.k: 0.3,
      },
      isCritical: true,
      labelEs: 'Diferenciación del bulbo',
      timingEs:
          'Mientras el bulbo se está formando; corta el nitrógeno 4–6 semanas '
          'antes de cosechar.',
      rationaleEs:
          'Aquí está el pico de consumo del ciclo: en el calendario de INIFAP '
          'Zacatecas las decenas de mayor absorción de nitrógeno caen '
          'justamente durante la formación del bulbo. Cerrar la llave antes de '
          'este punto deja el bulbo corto.',
      rulesEs: <String>[
        'Lo que no se vale es llegar con nitrógeno al final: tarde favorece el '
            'escobeteado y los canutos, y arruina el curado.',
      ],
    ),
    StageNutritionRule(
      stageKeys: <String>{'bulbFilling'},
      windowNutrients: <AgroMetricKey>{},
      labelEs: 'Llenado de bulbo',
      rationaleEs:
          'Ventana cerrada: estás dentro de las últimas semanas y el nitrógeno '
          'ahora da canuto, no diente.',
      rulesEs: <String>[
        'Si vas a apoyar el llenado, que sea K vía riego y sin N.',
      ],
    ),
    StageNutritionRule(
      stageKeys: <String>{'bulbMaturation', 'harvest', 'curingRest', 'scapeBrooming'},
      windowNutrients: <AgroMetricKey>{},
      labelEs: 'Maduración y curado',
      rationaleEs: 'No fertilices: el bulbo se cura con el suelo seco.',
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
// FRUTALES (plan anual en kg/ha por huerta en producción)
// (etapas: planting_transplant, root_establishment, juvenile_vegetative,
//  dormancy, budbreak, vegetative_growth, flowering, fruit_set, fruit_fill,
//  harvest_maturity, post_harvest)
//
// DECISIÓN DE PRODUCTO (Oscar, 6 sep 2026): la dosis de un frutal sale de la
// guía de fertilización del cultivo —plan anual de huerta en producción ×
// fracción de la ventana—, igual que en los demás cultivos, y NO de la cosecha
// esperada por árbol que el productor captura en la proyección de
// rendimiento. Las dos cosas no van correlacionadas. `TreeRestitutionPlanner`
// deja de alimentar al motor de nutrición.
// ═══════════════════════════════════════════════════════════════════════════

const List<String> _rulesTrees = <String>[
  'Aplica bajo la línea de goteo de la copa, donde están las raíces finas, y '
      'riega enseguida.',
  'N alto cerca de cosecha frena color, baja firmeza y acorta el almacenamiento.',
  'Árbol joven (sin cosecha): dosis ligera por edad y vigor, en varias tandas.',
];

const GuideSource _srcWsuTreeFruit = GuideSource(
  labelEs: 'WSU Tree Fruit, Soil fertility and plant nutrition in cropping '
      'orchards (el N se calcula por demanda y eficiencia: 67–118 lb/acre en '
      'su ejemplo de manzano a 37 t/acre; K por análisis foliar)',
  url: 'https://treefruit.wsu.edu/orchard-management/soils-nutrition/fruit-tree-nutrition/',
);

const GuideSource _srcUcanrFruitNut = GuideSource(
  labelEs: 'UC ANR Fruit & Nut Research and Information Center, Nutrients & '
      'Fertilization (durazno, pistache, nogal)',
  url: 'https://fruitsandnuts.ucdavis.edu/nutrients-fertilization',
);

/// Ventanas de un frutal de hueso o pepita (manzano, peral, durazno).
///
/// `seasonShare` es la fracción del plan ANUAL que toca en cada ventana del
/// ciclo de carga (suma 1.0 por nutriente; el establecimiento —año de
/// plantación— queda fuera). El nitrógeno va por mitades: la mitad después de
/// floración y la mitad tras la cosecha, mientras la hoja siga verde, que es
/// como lo plantea NMSU H-319 para huerta de clima seco y alcalino. El potasio
/// acompaña al crecimiento del fruto. El fósforo va condicionado al análisis:
/// NMSU es explícito en que los frutales de pepita «no han respondido a la
/// fertilización fosfatada, sin importar el análisis de suelo o foliar».
const List<StageNutritionRule> _pomeStoneTreeRules = <StageNutritionRule>[
  StageNutritionRule(
    stageKeys: <String>{'planting_transplant', 'root_establishment', 'juvenile_vegetative'},
    windowNutrients: <AgroMetricKey>{AgroMetricKey.p},
    // Año de plantación: la mitad del P anual de la huerta va al fondo del
    // cepellón; queda fuera de la suma del ciclo de carga.
    seasonShare: <AgroMetricKey, double>{AgroMetricKey.p: 0.5},
    labelEs: 'Establecimiento',
    timingEs:
        'Al plantar: el fósforo en el fondo del cepellón; el nitrógeno ligero '
        'y repartido el primer año.',
    rationaleEs:
        'El árbol joven necesita raíz, no carga: el fósforo casi no se mueve '
        'en el suelo, por eso va al fondo desde el principio, y el nitrógeno '
        'alto solo da madera blanda.',
  ),
  StageNutritionRule(
    stageKeys: <String>{'dormancy'},
    windowNutrients: <AgroMetricKey>{},
    labelEs: 'Reposo',
    rationaleEs:
        'Sin hoja no hay absorción: lo que apliques en reposo se lava.',
  ),
  StageNutritionRule(
    stageKeys: <String>{'budbreak', 'vegetative_growth'},
    windowNutrients: <AgroMetricKey>{AgroMetricKey.n},
    seasonShare: <AgroMetricKey, double>{AgroMetricKey.n: 0.50},
    isCritical: true,
    labelEs: 'Después de floración',
    timingEs:
        'Desde que cae el pétalo y hasta 4–6 semanas después, en fertirriego o '
        'en banda bajo la copa.',
    rationaleEs:
        'El arranque del año corre con las reservas que el árbol guardó el '
        'otoño pasado; este nitrógeno es el que sostiene el brote, la hoja y '
        'el cuajado de la carga que ya está puesta.',
    rulesEs: <String>[
      'No te pases: N alto empuja brotes tiernos y sombra de más.',
      'Antes de que abra la flor no hace falta: en suelo todavía frío la raíz '
          'casi no absorbe y se lava.',
    ],
  ),
  StageNutritionRule(
    stageKeys: <String>{'flowering', 'fruit_set'},
    windowNutrients: <AgroMetricKey>{AgroMetricKey.k},
    seasonShare: <AgroMetricKey, double>{AgroMetricKey.k: 0.30},
    labelEs: 'Floración y cuajado',
    timingEs: 'Después de la caída de pétalos, con el riego.',
    rationaleEs:
        'El potasio arranca aquí para el tamaño del fruto; el nitrógeno se '
        'modera para no tirar fruto.',
  ),
  StageNutritionRule(
    stageKeys: <String>{'fruit_fill'},
    windowNutrients: <AgroMetricKey>{AgroMetricKey.k},
    seasonShare: <AgroMetricKey, double>{AgroMetricKey.k: 0.70},
    isCritical: true,
    labelEs: 'Llenado de fruto',
    timingEs: 'Durante el crecimiento del fruto, repartido en el riego.',
    rationaleEs:
        'El fruto se lleva la mayor parte del potasio del año: tamaño, color y '
        'firmeza.',
    rulesEs: <String>[
      'K alto de más sube sales y desbalancea el calcio (firmeza).',
    ],
  ),
  StageNutritionRule(
    stageKeys: <String>{'harvest_maturity'},
    windowNutrients: <AgroMetricKey>{},
    labelEs: 'Cosecha',
    rationaleEs:
        'Ventana cerrada: el nitrógeno cerca de la cosecha retrasa el color y '
        'baja la firmeza.',
  ),
  StageNutritionRule(
    stageKeys: <String>{'post_harvest'},
    windowNutrients: <AgroMetricKey>{AgroMetricKey.n, AgroMetricKey.p},
    seasonShare: <AgroMetricKey, double>{AgroMetricKey.n: 0.50, AgroMetricKey.p: 1.0},
    labelEs: 'Post-cosecha',
    timingEs:
        'Justo después de cosechar y SIEMPRE antes de que la hoja empiece a '
        'amarillear: en Chihuahua eso es octubre y los primeros días de '
        'noviembre, no diciembre.',
    rationaleEs:
        'Es la mitad del nitrógeno del año y la que más rinde: el árbol la '
        'guarda en raíz y tronco y arranca con ella la primavera siguiente. '
        'Sin hoja verde no hay absorción, así que la fecha manda más que la '
        'dosis.',
    rulesEs: <String>[
      'Si lo das foliar en lugar de al suelo, no pases de 22 kg N/ha por '
          'aplicación: el foliar es un complemento, no el plan completo.',
      'No lo estires hasta el invierno. Con la hoja amarilla ya no entra.',
    ],
  ),
];

/// Ventanas del NOGAL PECANERO.
///
/// Se separó del pistache el 13 sep 2026: los dos son nuez, pero su calendario
/// no se parece. Tres decisiones, cada una con su porqué:
///
/// 1. NO HAY VENTANA POST-COSECHA. En Chihuahua el nogal se cosecha de la
///    segunda decena de octubre a diciembre, y para cuando termina la vibrada
///    la hoja ya se fue. NMSU H-651 lo midió con nitrógeno marcado: entre
///    noviembre y marzo se perdió el 13 % del N aplicado, lixiviado fuera del
///    perfil. «Aplicar N sin hoja en el árbol resulta en poca absorción». Lo
///    que manda es el estado de la hoja, no la fecha de cosecha.
/// 2. EL NITRÓGENO VA EN PRIMAVERA. NMSU H-602: «la mitad en marzo y la otra
///    mitad a mediados de junio». El ensayo de Jiménez, Chihuahua, obtuvo su
///    mejor rendimiento con 100 kg N/ha —sin diferencia estadística frente a
///    150 y 200— aplicados en una sola vez en marzo.
/// 3. EL POTASIO VA EN REPOSO. UGA lo aplica en febrero, «antes de que entren
///    las lluvias de invierno». Con la ventana de reposo cerrada, la app no
///    podía recomendarlo cuando toca.
///
/// P y K van CONDICIONADOS al análisis (mínimo 0 en el plan): NMSU H-602 dice
/// que «salvo en suelos arenosos, las aplicaciones anuales normalmente no son
/// necesarias ni recomendables», y UGA pide fósforo solo con foliar < 0.12 %.
const List<StageNutritionRule> _pecanTreeRules = <StageNutritionRule>[
  StageNutritionRule(
    stageKeys: <String>{'planting_transplant', 'root_establishment', 'juvenile_vegetative'},
    windowNutrients: <AgroMetricKey>{AgroMetricKey.p},
    seasonShare: <AgroMetricKey, double>{AgroMetricKey.p: 0.5},
    labelEs: 'Establecimiento',
    timingEs:
        'Al plantar: el fósforo en el fondo de la cepa; el nitrógeno ligero y '
        'repartido los primeros años, y nunca después de junio.',
    rationaleEs:
        'El árbol joven necesita raíz y estructura, no carga: el fósforo casi '
        'no se mueve en el suelo, por eso va al fondo desde el principio.',
    rulesEs: <String>[
      'En árbol joven, nada de nitrógeno después de junio: alarga el brote, no '
          'lo deja endurecer y el invierno se lo lleva.',
    ],
  ),
  StageNutritionRule(
    stageKeys: <String>{'dormancy'},
    windowNutrients: <AgroMetricKey>{AgroMetricKey.k, AgroMetricKey.p},
    seasonShare: <AgroMetricKey, double>{AgroMetricKey.k: 0.60, AgroMetricKey.p: 1.0},
    labelEs: 'Reposo (febrero)',
    timingEs:
        'En febrero, antes de que arranque la brotación y antes de las lluvias '
        'o el primer riego fuerte del año.',
    rationaleEs:
        'El potasio y el fósforo son lentos: puestos en reposo llegan a la '
        'raíz a tiempo para el ciclo. El nitrógeno no, porque sin hoja no hay '
        'absorción.',
    rulesEs: <String>[
      'Los dos van solo si el análisis los pide. En la zona nogalera de '
          'Chihuahua el potasio foliar suele salir corto (1.06–1.16 % contra '
          'un mínimo de 1.2 %), así que vale la pena medirlo.',
      'Nada de nitrógeno en esta ventana: sin hoja se lava al acuífero.',
    ],
  ),
  StageNutritionRule(
    stageKeys: <String>{'budbreak', 'vegetative_growth'},
    windowNutrients: <AgroMetricKey>{AgroMetricKey.n},
    seasonShare: <AgroMetricKey, double>{AgroMetricKey.n: 0.55},
    isCritical: true,
    labelEs: 'Brotación (marzo)',
    timingEs:
        'A mediados de marzo, con el brote saliendo: fertirriego o banda bajo '
        'la copa.',
    rationaleEs:
        'Es la aplicación más importante del año. El nitrógeno de marzo arma '
        'el brote y la hoja que después van a llenar la nuez.',
    rulesEs: <String>[
      'En riego rodado y suelo pesado puede ir hasta la mitad de la temporada '
          'aquí; en suelo arenoso, no más de un tercio y reparte el resto.',
      'Acompáñalo con el zinc foliar: en suelo calcáreo el zinc al suelo se '
          'bloquea. Primera aspersión con la hoja a 2.5 cm, luego a los 7 '
          'días, luego a los 14 y otra a los 14–21. Si el foliar sale por '
          'debajo de 50 ppm, súbele a cinco.',
    ],
  ),
  StageNutritionRule(
    stageKeys: <String>{'flowering', 'fruit_set'},
    windowNutrients: <AgroMetricKey>{AgroMetricKey.n},
    seasonShare: <AgroMetricKey, double>{AgroMetricKey.n: 0.25},
    labelEs: 'Cuajado (junio)',
    timingEs: 'A mediados de junio, con el riego.',
    rationaleEs:
        'La segunda mitad del calendario clásico de NMSU: sostiene el brote y '
        'el amarre mientras la nuez empieza a formarse.',
  ),
  StageNutritionRule(
    stageKeys: <String>{'fruit_fill'},
    windowNutrients: <AgroMetricKey>{AgroMetricKey.n, AgroMetricKey.k},
    seasonShare: <AgroMetricKey, double>{AgroMetricKey.n: 0.20, AgroMetricKey.k: 0.40},
    isCritical: true,
    labelEs: 'Llenado de la almendra',
    timingEs:
        'Durante el llenado, en agosto, y con corte duro a fin de mes.',
    rationaleEs:
        'La almendra se llena aquí. Es el último refuerzo útil del año, y '
        'conviene sobre todo en año de carga alta.',
    rulesEs: <String>[
      'Corte duro el 31 de agosto: después de esa fecha el nitrógeno ya no '
          'llega a la nuez y retrasa la apertura del ruezno.',
    ],
  ),
  StageNutritionRule(
    stageKeys: <String>{'harvest_maturity'},
    windowNutrients: <AgroMetricKey>{},
    labelEs: 'Cosecha',
    rationaleEs:
        'Ventana cerrada: el nitrógeno tardío retrasa la apertura del ruezno.',
  ),
  StageNutritionRule(
    stageKeys: <String>{'post_harvest'},
    windowNutrients: <AgroMetricKey>{},
    labelEs: 'Post-cosecha',
    rationaleEs:
        'Ventana cerrada. Para cuando terminas de vibrar, el árbol ya soltó la '
        'hoja: lo que apliques ahora no lo absorbe y se va al acuífero. Se '
        'midió: 13 % del nitrógeno perdido entre noviembre y marzo.',
    rulesEs: <String>[
      'Si tu huerta todavía tiene hoja verde y cosechaste temprano, esa '
          'aplicación pertenece a la ventana de llenado, no a esta.',
    ],
  ),
];

/// Ventanas del PISTACHE.
///
/// Sigue la recomendación de APLICACIÓN de CDFA-FREP —20 % tras la foliación,
/// 30 % en crecimiento de fruto, 30 % en llenado de almendra y 20 % en madurez
/// o post-cosecha temprana, «mientras la hoja siga sana»—, que es distinta de
/// su curva de ABSORCIÓN (30 % primavera / 70 % llenado), la cifra que se
/// citaba antes como si fuera el reparto.
///
/// El fósforo va en noviembre, tras la caída de hoja: CDFA lo dice explícito, y
/// el 95 % de la absorción de P ocurre durante el llenado, no en primavera.
const List<StageNutritionRule> _pistachioTreeRules = <StageNutritionRule>[
  StageNutritionRule(
    stageKeys: <String>{'planting_transplant', 'root_establishment', 'juvenile_vegetative'},
    windowNutrients: <AgroMetricKey>{AgroMetricKey.p},
    seasonShare: <AgroMetricKey, double>{AgroMetricKey.p: 0.5},
    labelEs: 'Establecimiento',
    timingEs:
        'Al plantar: el fósforo en el fondo de la cepa; el nitrógeno ligero y '
        'repartido los primeros años.',
    rationaleEs:
        'El árbol joven necesita raíz y estructura, no carga: el fósforo casi '
        'no se mueve en el suelo, por eso va al fondo desde el principio.',
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
    seasonShare: <AgroMetricKey, double>{AgroMetricKey.n: 0.20},
    labelEs: 'Foliación',
    timingEs: 'Cuando la hoja ya está desplegada, con el riego.',
    rationaleEs:
        'Arranque moderado: el pistache toma poco nitrógeno en primavera y el '
        'grueso lo pide más adelante.',
  ),
  StageNutritionRule(
    stageKeys: <String>{'flowering', 'fruit_set'},
    windowNutrients: <AgroMetricKey>{AgroMetricKey.n, AgroMetricKey.k},
    seasonShare: <AgroMetricKey, double>{AgroMetricKey.n: 0.30, AgroMetricKey.k: 0.40},
    labelEs: 'Crecimiento del fruto',
    timingEs: 'De mayo a junio, repartido en el riego.',
    rationaleEs:
        'Empieza el tramo de mayor demanda: el fruto crece y el potasio entra '
        'con él.',
  ),
  StageNutritionRule(
    stageKeys: <String>{'fruit_fill'},
    windowNutrients: <AgroMetricKey>{AgroMetricKey.n, AgroMetricKey.k},
    seasonShare: <AgroMetricKey, double>{AgroMetricKey.n: 0.30, AgroMetricKey.k: 0.60},
    isCritical: true,
    labelEs: 'Llenado de la almendra',
    timingEs: 'Durante el llenado, repartido en el riego.',
    rationaleEs:
        'Aquí se define el peso y el llenado de la almendra: es donde el '
        'pistache toma la mayor parte de su nitrógeno y su potasio del año.',
  ),
  StageNutritionRule(
    stageKeys: <String>{'harvest_maturity'},
    windowNutrients: <AgroMetricKey>{AgroMetricKey.n},
    seasonShare: <AgroMetricKey, double>{AgroMetricKey.n: 0.20},
    labelEs: 'Madurez',
    timingEs:
        'En madurez de fruto o justo después de cosechar, siempre que la hoja '
        'siga sana.',
    rationaleEs:
        'El último 20 % del calendario de CDFA. Repone al árbol antes de que '
        'entre a reposo.',
    rulesEs: <String>[
      'Si la hoja ya está dañada o cayendo, sáltate esta aplicación: no la '
          'absorbe.',
    ],
  ),
  StageNutritionRule(
    stageKeys: <String>{'post_harvest'},
    windowNutrients: <AgroMetricKey>{AgroMetricKey.p},
    seasonShare: <AgroMetricKey, double>{AgroMetricKey.p: 1.0},
    labelEs: 'Post-cosecha (noviembre)',
    timingEs: 'En noviembre, cuando empieza la caída de hoja.',
    rationaleEs:
        'El fósforo del pistache va aquí, no en primavera: casi toda su '
        'absorción ocurre durante el llenado, y puesto en noviembre llega a '
        'tiempo para el ciclo siguiente.',
    rulesEs: <String>[
      'Solo si el análisis lo pide.',
    ],
  ),
];

/// Ventanas del AGUACATE.
///
/// El grueso del nitrógeno va en el bloque brotación-floración-cuajado, a
/// diferencia del mango. Corrección del 17 sep 2026 (verificación con CDFA-FREP,
/// Lovatt/UC Riverside y UC ANR): la frase «dos tercios de 4 a 6 semanas ANTES
/// de la floración» que aquí se atribuía a UC ANR no aparece en esas fuentes;
/// lo que dicen es lo contrario en el detalle: CDFA-FREP pide «la mayor parte
/// del N en primavera JUSTO DESPUÉS de plena floración y a mediados-fines de
/// verano», y Lovatt encontró que el N extra que rinde es el de ABRIL (antesis
/// → cuajado temprano, y además reduce la alternancia) y el de NOVIEMBRE (fin
/// del crecimiento vegetativo, carga PRE-FLORAL del ciclo siguiente), mientras
/// que el de enero-febrero es el más lixiviable y el de junio se va a hoja. Por
/// eso la ventana sigue siendo el bloque de floración, pero su momento es
/// plena flor → cuajado, no semanas antes. Trasladar aquí la lógica de
/// post-cosecha del mango sería un error.
///
/// `seasonShare`: fracción del plan anual en cada ventana del ciclo de carga
/// (suma 1.0 por nutriente; el establecimiento queda fuera).
const List<StageNutritionRule> _evergreenTreeRules = <StageNutritionRule>[
  StageNutritionRule(
    stageKeys: <String>{'planting_transplant', 'root_establishment', 'juvenile_vegetative'},
    windowNutrients: <AgroMetricKey>{AgroMetricKey.p},
    seasonShare: <AgroMetricKey, double>{AgroMetricKey.p: 0.5},
    labelEs: 'Establecimiento',
    timingEs:
        'Al plantar: el fósforo en el fondo del hoyo; el nitrógeno ligero y '
        'repartido los primeros años.',
    rationaleEs:
        'El árbol joven necesita echar raíz y armar su estructura antes de '
        'cargar fruta: el fósforo casi no se mueve en el suelo, por eso va al '
        'fondo desde el principio.',
  ),
  StageNutritionRule(
    stageKeys: <String>{'dormancy'},
    windowNutrients: <AgroMetricKey>{},
    labelEs: 'Reposo relativo',
    rationaleEs:
        'Con el suelo frío o seco la raíz no absorbe: espera al siguiente '
        'flujo de brotación.',
  ),
  StageNutritionRule(
    stageKeys: <String>{'budbreak', 'vegetative_growth', 'flowering'},
    windowNutrients: <AgroMetricKey>{AgroMetricKey.n},
    seasonShare: <AgroMetricKey, double>{AgroMetricKey.n: 0.50},
    isCritical: true,
    labelEs: 'Brotación y floración',
    timingEs:
        'De la plena floración al cuajado temprano, en fertirriego o en '
        'banda; no lo adelantes a enero-febrero, que es cuando más se lava.',
    rationaleEs:
        'El nitrógeno justo después de plena floración sostiene el cuajado y '
        'el brote que carga la flor siguiente; aplicado ahí subió el '
        'rendimiento y redujo la alternancia (Lovatt, UC Riverside).',
  ),
  StageNutritionRule(
    stageKeys: <String>{'fruit_set'},
    windowNutrients: <AgroMetricKey>{AgroMetricKey.n, AgroMetricKey.k},
    seasonShare: <AgroMetricKey, double>{AgroMetricKey.n: 0.20, AgroMetricKey.k: 0.30},
    labelEs: 'Cuajado',
    timingEs: 'Después del cuajado, repartido en el riego.',
    rationaleEs:
        'Modera el nitrógeno para reducir la caída de fruto; el potasio '
        'empieza a acompañar.',
  ),
  StageNutritionRule(
    stageKeys: <String>{'fruit_fill'},
    windowNutrients: <AgroMetricKey>{AgroMetricKey.k},
    seasonShare: <AgroMetricKey, double>{AgroMetricKey.k: 0.50},
    isCritical: true,
    labelEs: 'Llenado de fruto',
    timingEs: 'Durante el crecimiento del fruto, repartido en el riego.',
    rationaleEs:
        'El fruto se lleva la mayor parte del potasio del año: calibre y '
        'calidad.',
  ),
  StageNutritionRule(
    stageKeys: <String>{'harvest_maturity'},
    windowNutrients: <AgroMetricKey>{},
    labelEs: 'Cosecha',
    rationaleEs:
        'Ventana cerrada: el nitrógeno cerca de la cosecha retrasa el color y '
        'baja la calidad.',
  ),
  StageNutritionRule(
    stageKeys: <String>{'post_harvest'},
    windowNutrients: <AgroMetricKey>{AgroMetricKey.n, AgroMetricKey.p, AgroMetricKey.k},
    seasonShare: <AgroMetricKey, double>{
      AgroMetricKey.n: 0.30,
      AgroMetricKey.p: 1.0,
      AgroMetricKey.k: 0.20,
    },
    labelEs: 'Post-cosecha',
    timingEs: 'Después de cosechar, con el siguiente flujo de brotación.',
    rationaleEs:
        'Repone lo que se llevó la fruta y arma el flujo de brotes que cargará '
        'la siguiente.',
  ),
];

/// Ventanas de un CÍTRICO (naranjo, limonero).
///
/// Se separó del aguacate el 13 sep 2026 por una razón concreta: en limón
/// persa la cosecha es casi continua. Hay varias floraciones al año y el corte
/// va todo el tiempo, con un pico del 70 % entre mayo y septiembre y el 30 %
/// restante de octubre a abril. Con la ventana de cosecha CERRADA, BIO-G
/// dejaba de recomendar durante meses justo en el momento de mayor extracción
/// (hasta 4.5 kg de N por tonelada de fruta en Veracruz). Ahora la cosecha es
/// una ventana de BAJA DEMANDA, no una ventana muda.
///
/// El grueso del N sigue yendo entre el brote de primavera y el amarre —dos
/// tercios del año, según CDFA-FREP— y el fósforo va condicionado al análisis:
/// la extracción real ronda 8–15 kg P₂O₅/ha y UF/IFAS solo lo aplica cuando el
/// foliar Y el suelo salen bajos.
const List<StageNutritionRule> _citrusTreeRules = <StageNutritionRule>[
  StageNutritionRule(
    stageKeys: <String>{'planting_transplant', 'root_establishment', 'juvenile_vegetative'},
    windowNutrients: <AgroMetricKey>{AgroMetricKey.p},
    seasonShare: <AgroMetricKey, double>{AgroMetricKey.p: 0.5},
    labelEs: 'Establecimiento',
    timingEs:
        'Al plantar: el fósforo en el fondo del hoyo; el nitrógeno ligero y '
        'repartido los primeros años.',
    rationaleEs:
        'El árbol joven necesita echar raíz y armar su estructura antes de '
        'cargar fruta: el fósforo casi no se mueve en el suelo, por eso va al '
        'fondo desde el principio.',
  ),
  StageNutritionRule(
    stageKeys: <String>{'dormancy'},
    windowNutrients: <AgroMetricKey>{},
    labelEs: 'Reposo relativo',
    rationaleEs:
        'Con el suelo frío o seco la raíz no absorbe: espera al siguiente '
        'flujo de brotación.',
  ),
  StageNutritionRule(
    stageKeys: <String>{'budbreak', 'vegetative_growth', 'flowering'},
    windowNutrients: <AgroMetricKey>{AgroMetricKey.n},
    seasonShare: <AgroMetricKey, double>{AgroMetricKey.n: 0.50},
    isCritical: true,
    labelEs: 'Brotación y floración',
    timingEs:
        'Antes y durante la floración principal, en fertirriego o en banda.',
    rationaleEs:
        'Dos tercios del nitrógeno del año deben entrar entre el brote de '
        'primavera y el amarre: es el flujo de brotes que carga la flor.',
  ),
  StageNutritionRule(
    stageKeys: <String>{'fruit_set'},
    windowNutrients: <AgroMetricKey>{AgroMetricKey.n, AgroMetricKey.k},
    seasonShare: <AgroMetricKey, double>{AgroMetricKey.n: 0.20, AgroMetricKey.k: 0.30},
    labelEs: 'Cuajado',
    timingEs: 'Después del cuajado, repartido en el riego.',
    rationaleEs:
        'Modera el nitrógeno para reducir la caída de fruto; el potasio '
        'empieza a acompañar.',
  ),
  StageNutritionRule(
    stageKeys: <String>{'fruit_fill'},
    windowNutrients: <AgroMetricKey>{AgroMetricKey.k},
    seasonShare: <AgroMetricKey, double>{AgroMetricKey.k: 0.50},
    isCritical: true,
    labelEs: 'Llenado de fruto',
    timingEs: 'Durante el crecimiento del fruto, repartido en el riego.',
    rationaleEs:
        'El fruto se lleva la mayor parte del potasio del año: calibre, jugo y '
        'calidad de corteza.',
  ),
  StageNutritionRule(
    stageKeys: <String>{'harvest_maturity'},
    windowNutrients: <AgroMetricKey>{AgroMetricKey.k},
    seasonShare: <AgroMetricKey, double>{AgroMetricKey.n: 0.10, AgroMetricKey.k: 0.10},
    labelEs: 'Cosecha',
    timingEs: 'Dosis ligeras con el riego, entre cortes.',
    rationaleEs:
        'En limón la cosecha dura meses y cada corte se lleva nutrientes; en '
        'naranja el corte también se estira. No es momento de empujar, pero '
        'tampoco de callar: una dosis ligera mantiene el árbol mientras '
        'produce.',
    rulesEs: <String>[
      'Si vas a cosechar en las próximas dos semanas, deja el nitrógeno fuera: '
          'retrasa el color de la cáscara.',
    ],
  ),
  StageNutritionRule(
    stageKeys: <String>{'post_harvest'},
    windowNutrients: <AgroMetricKey>{AgroMetricKey.n, AgroMetricKey.p, AgroMetricKey.k},
    seasonShare: <AgroMetricKey, double>{
      AgroMetricKey.n: 0.20,
      AgroMetricKey.p: 1.0,
      AgroMetricKey.k: 0.10,
    },
    labelEs: 'Post-cosecha',
    timingEs: 'Después de cosechar, con el siguiente flujo de brotación.',
    rationaleEs:
        'Repone lo que se llevó la fruta y arma el flujo de brotes que cargará '
        'la siguiente.',
    rulesEs: <String>[
      'El fósforo solo si el análisis foliar y el de suelo salen bajos: una '
          'huerta establecida suele traer suficiente del año pasado.',
    ],
  ),
];

/// Ventanas del MANGO.
///
/// Se separó de los cítricos y del aguacate el 13 sep 2026 porque el mango
/// tiene el calendario INVERTIDO respecto a ellos, y la guía anterior lo tenía
/// al revés: ponía el 50 % del nitrógeno antes de la floración, justo lo que
/// su propia nota advertía que no había que hacer.
///
/// UF/IFAS es tajante para árbol adulto sano: «poco o nada de nitrógeno hace
/// falta; en cambio, enfatice el potasio y los micronutrientes». El nitrógeno
/// alto antes de floración empuja flujo vegetativo y quita flor. El mejor
/// ensayo mexicano disponible —'Ataulfo' en Nayarit, +38 % de rendimiento—
/// aplicó en julio y septiembre, es decir, DESPUÉS de la cosecha.
///
/// El reposo se queda cerrado a propósito: ahí ocurre la inducción floral, y
/// el estrés controlado es parte del manejo. Si vas a intervenir en esa
/// ventana, es con nitrato de potasio foliar al 2–4 % para inducir, no con
/// nitrógeno al suelo.
const List<StageNutritionRule> _mangoTreeRules = <StageNutritionRule>[
  StageNutritionRule(
    stageKeys: <String>{'planting_transplant', 'root_establishment', 'juvenile_vegetative'},
    windowNutrients: <AgroMetricKey>{AgroMetricKey.p},
    seasonShare: <AgroMetricKey, double>{AgroMetricKey.p: 0.5},
    labelEs: 'Establecimiento',
    timingEs:
        'Al plantar: el fósforo en el fondo del hoyo; el nitrógeno ligero y '
        'repartido los primeros años.',
    rationaleEs:
        'El árbol joven sí necesita nitrógeno para crecer: la regla de «poco o '
        'nada» es para el árbol adulto en producción, no para este.',
  ),
  StageNutritionRule(
    stageKeys: <String>{'dormancy'},
    windowNutrients: <AgroMetricKey>{},
    labelEs: 'Reposo (inducción floral)',
    rationaleEs:
        'Ventana cerrada a propósito. Aquí el mango decide si va a flor o a '
        'brote, y el nitrógeno al suelo lo empuja a brote. El estrés de esta '
        'etapa es parte del manejo, no un problema que haya que corregir.',
    rulesEs: <String>[
      'Si vas a intervenir, que sea nitrato de potasio foliar al 2–4 % para '
          'inducir floración, no fertilizante al suelo.',
    ],
  ),
  StageNutritionRule(
    stageKeys: <String>{'budbreak', 'vegetative_growth', 'flowering'},
    windowNutrients: <AgroMetricKey>{AgroMetricKey.n},
    seasonShare: <AgroMetricKey, double>{AgroMetricKey.n: 0.10},
    labelEs: 'Brotación y floración',
    timingEs: 'Dosis ligera, solo si el árbol viene débil.',
    rationaleEs:
        'Aquí va muy poco a propósito. El nitrógeno alto antes y durante la '
        'floración favorece el flujo vegetativo y te deja con menos flor: es '
        'la forma más común de perder cosecha en mango.',
  ),
  StageNutritionRule(
    stageKeys: <String>{'fruit_set'},
    windowNutrients: <AgroMetricKey>{AgroMetricKey.n, AgroMetricKey.k},
    seasonShare: <AgroMetricKey, double>{AgroMetricKey.n: 0.25, AgroMetricKey.k: 0.30},
    labelEs: 'Cuajado',
    timingEs: 'Una vez que el fruto amarró, repartido en el riego.',
    rationaleEs:
        'Con la flor ya cuajada el nitrógeno deja de competir con ella y '
        'empieza a sostener el fruto. El potasio arranca aquí.',
  ),
  StageNutritionRule(
    stageKeys: <String>{'fruit_fill'},
    windowNutrients: <AgroMetricKey>{AgroMetricKey.k},
    seasonShare: <AgroMetricKey, double>{AgroMetricKey.k: 0.45},
    isCritical: true,
    labelEs: 'Llenado de fruto',
    timingEs: 'Durante el crecimiento del fruto, repartido en el riego.',
    rationaleEs:
        'El fruto se lleva la mayor parte del potasio del año: calibre, color '
        'y sólidos.',
  ),
  StageNutritionRule(
    stageKeys: <String>{'harvest_maturity'},
    windowNutrients: <AgroMetricKey>{},
    labelEs: 'Cosecha',
    rationaleEs:
        'Ventana cerrada: el nitrógeno cerca de la cosecha retrasa el color y '
        'baja la calidad.',
  ),
  StageNutritionRule(
    stageKeys: <String>{'post_harvest'},
    windowNutrients: <AgroMetricKey>{AgroMetricKey.n, AgroMetricKey.p, AgroMetricKey.k},
    seasonShare: <AgroMetricKey, double>{
      AgroMetricKey.n: 0.65,
      AgroMetricKey.p: 1.0,
      AgroMetricKey.k: 0.25,
    },
    isCritical: true,
    labelEs: 'Post-cosecha',
    timingEs:
        'Inmediatamente después de cosechar, y una segunda pasada unas semanas '
        'después, mientras la raíz está en su flujo de crecimiento.',
    rationaleEs:
        'Esta es la aplicación grande del año en mango, y es la que estaba '
        'mal colocada. Recupera al árbol de la carga y arma los flujos '
        'vegetativos que van a madurar para cargar la floración siguiente. El '
        'ensayo de Nayarit que ganó 38 % de rendimiento aplicó en julio y '
        'septiembre, no en floración.',
  ),
];

const Map<AgroMetricKey, List<String>> _treeSources = <AgroMetricKey, List<String>>{
  AgroMetricKey.n: <String>['Urea (46-0-0)', 'Sulfato de amonio (21-0-0-24S)', 'Nitrato de calcio'],
  AgroMetricKey.p: <String>['MAP (11-52-0)', 'Ácido fosfórico (fertirriego)'],
  AgroMetricKey.k: <String>['Sulfato de potasio (0-0-50)', 'Nitrato de potasio (13-0-46)'],
};

/// Plan anual de un frutal en producción. [n], [p] y [k] van en kg/ha de N,
/// P₂O₅ y K₂O (mínimo, máximo).
NutritionGuide _treeGuide({
  required String cropKey,
  required String labelEs,
  required List<StageNutritionRule> rules,
  required List<GuideSource> sources,
  required (double, double) n,
  required (double, double) p,
  required (double, double) k,
  required String planSourceEs,
  String? planNotesEs,
  String? pNotesEs,
  String? kNotesEs,
  String? notesEs,
  NitrogenSplitRequirement split = NitrogenSplitRequirement.unclassified,
  int minPasses = 1,
  int? minPassesCoarse,
  int? minPassesFine,
  int? recommendedPasses,
  double? maxSinglePassKgN,
  List<String> nitrogenPassPriority = const <String>[],
  String? splitNotesEs,
}) => NutritionGuide(
  cropKey: cropKey,
  cropLabelEs: labelEs,
  auditStatus: GuideAuditStatus.proposed,
  splitRequirement: split,
  minNitrogenPasses: minPasses,
  minNitrogenPassesCoarse: minPassesCoarse,
  minNitrogenPassesFine: minPassesFine,
  recommendedNitrogenPasses: recommendedPasses,
  maxSinglePassKgN: maxSinglePassKgN,
  nitrogenPassPriority: nitrogenPassPriority,
  splitNotesEs: splitNotesEs,
  sources: sources,
  seasonPlan: <AgroMetricKey, SeasonNutrientPlan>{
    AgroMetricKey.n: SeasonNutrientPlan(
      form: NutrientForm.n,
      minKgPerHa: n.$1,
      maxKgPerHa: n.$2,
      sourceEs: planSourceEs,
      notesEs: planNotesEs,
    ),
    AgroMetricKey.p: SeasonNutrientPlan(
      form: NutrientForm.p2o5,
      minKgPerHa: p.$1,
      maxKgPerHa: p.$2,
      sourceEs: planSourceEs,
      notesEs: pNotesEs,
    ),
    AgroMetricKey.k: SeasonNutrientPlan(
      form: NutrientForm.k2o,
      minKgPerHa: k.$1,
      maxKgPerHa: k.$2,
      sourceEs: planSourceEs,
      notesEs: kNotesEs,
    ),
  },
  stageRules: rules,
  sourceOptionsEs: _treeSources,
  generalRulesEs: _rulesTrees,
  notesEs: notesEs,
);

final NutritionGuide _appleTree = _treeGuide(
  cropKey: 'apple_tree',
  labelEs: 'Manzano',
  split: NitrogenSplitRequirement.splitRecommended,
  minPasses: 2,
  minPassesCoarse: 2,
  // La única iría después de floración (Wisconsin: «antes de la caída de
  // pétalo, cuando la demanda del brote es máxima»; Cornell: entre
  // brotación y caída de pétalo; NMSU; Havis 1956: otoño solo es lo que
  // peor rinde), verificación del 17 sep 2026.
  nitrogenPassPriority: <String>['budbreak', 'post_harvest'],
  splitNotesEs:
      'NMSU H-319: mitad en post-cosecha y mitad después de floración. En '
      'suelo arenoso la dosis de otoño se lixivia: reprogramar, no '
      'concentrar. Havis (1956): solo otoño rindió menos que solo primavera '
      'o que el reparto.',
  rules: _pomeStoneTreeRules,
  sources: const <GuideSource>[
    GuideSource(
      labelEs:
          'Nova Scientia 8(16) / SciELO, Fertirrigación con macronutrientes en '
          'manzano Golden Delicious (UACH, Chihuahua, 3×3 m ≈ 1 111 '
          'árboles/ha): dosis general 138 N – 45 P – 40 K – 110 Ca – 20 Mg. '
          'OJO: el artículo expresa P y K ELEMENTALES (sus fuentes son «ácido '
          'fosfórico 21.4 % P» y «tiosulfito de potasio 10.5 % K»), así que '
          'esos 45 P equivalen a 103 kg P₂O₅/ha y los 40 K a 48 kg K₂O/ha',
      url: 'https://www.scielo.org.mx/scielo.php?script=sci_arttext&pid=S2007-07052016000100162',
      year: 2016,
    ),
    _srcWsuTreeFruit,
  ],
  // Mínimo 70 desde el 17 sep 2026 (antes 100): WSU calcula por demanda
  // 75–132 kg N/ha según eficiencia; Wisconsin mantiene con 45–67 kg/ha
  // (56–90 si el foliar sale bajo); Cornell arranca con 22–56 kg/ha al
  // suelo con foliar bajo. El techo 140 lo sostienen UACH (138) y NMSU
  // (168–224 en carga alta).
  n: (70.0, 140.0),
  p: (0.0, 60.0),
  k: (40.0, 80.0),
  planSourceEs:
      'UACH Chihuahua (138 N en fertirriego), NMSU H-319, WSU Tree Fruit '
      '(por demanda: 75–132), Wisconsin (45–90) y Cornell (22–56)',
  planNotesEs:
      'Huerta adulta de riego en Chihuahua a 40–60 t/ha: 100–140. Con '
      'huerta de 30–40 t/ha, suelo con materia orgánica o foliar de '
      'nitrógeno en rango (2.2–2.4 %), quédate en 70–100 (Wisconsin, '
      'Cornell, WSU). NMSU maneja 168–224 kg N/ha en huerta adulta de carga '
      'alta. En fertirriego el calcio va 1:1 con el N (bitter pit).',
  pNotesEs:
      'NMSU es categórico: «los frutales, incluido el manzano, no han '
      'respondido a la fertilización fosfatada, sin importar el análisis de '
      'suelo o el foliar». Aplícalo solo si tu foliar sale por debajo de '
      '0.15 % de fósforo.',
  kNotesEs: 'Solo si el análisis foliar sale bajo (por debajo de 1.2 %).',
  notesEs: 'Plan de huerta en producción; el año de plantación no lleva plan.',
);

final NutritionGuide _pearTree = _treeGuide(
  cropKey: 'pear_tree',
  labelEs: 'Peral',
  split: NitrogenSplitRequirement.splitRecommended,
  minPasses: 2,
  minPassesCoarse: 2,
  // Hereda la evidencia del manzano (17 sep 2026).
  nitrogenPassPriority: <String>['budbreak', 'post_harvest'],
  splitNotesEs:
      'Mismo esquema que manzano (post-cosecha + post-floración) con la '
      'mitad de la dosis por vigor y fuego bacteriano (Univ. de Arizona '
      '2024). Sin fuente específica de fraccionamiento en peral.',
  rules: _pomeStoneTreeRules,
  sources: const <GuideSource>[_srcWsuTreeFruit, _srcUcanrFruitNut],
  n: (60.0, 110.0),
  p: (0.0, 60.0),
  k: (60.0, 120.0),
  planSourceEs: 'WSU Tree Fruit (calcula por demanda), Oregon State FG-59 y UC ANR',
  planNotesEs: 'Huerta adulta a 30–45 t/ha; el peral pide menos N que el manzano.',
  pNotesEs: 'Solo si el foliar de agosto sale por debajo de 0.14 % de fósforo.',
  kNotesEs:
      'Oregon State escalona el potasio del peral de 0 a más de 400 kg/ha '
      'según el análisis de suelo: sin análisis, quédate en el mínimo.',
);

final NutritionGuide _peachTree = _treeGuide(
  cropKey: 'peach_tree',
  labelEs: 'Durazno',
  split: NitrogenSplitRequirement.toleratesSingle,
  minPasses: 1,
  minPassesCoarse: 2,
  recommendedPasses: 1,
  // La única va en primavera (Havis 1956 vía Penn State: 15.3 otoño /
  // 17.2 primavera / 18.3 partido bushels por árbol; CDFA-FREP: «más
  // eficiente a mediados de primavera»; Carolina del Sur: 4–6 semanas
  // antes de floración), verificación del 17 sep 2026.
  nitrogenPassPriority: <String>['budbreak', 'post_harvest'],
  splitNotesEs:
      'Penn State (Marini 2023): «la fertilización de primavera o el '
      'reparto entre primavera y post-cosecha parecen igual de buenos»; '
      'Havis (1956) ya lo había encontrado. Único frutal con equivalencia '
      'explícita.',
  rules: _pomeStoneTreeRules,
  sources: const <GuideSource>[_srcUcanrFruitNut, _srcWsuTreeFruit],
  // Mínimo 60 desde el 17 sep 2026 (antes 90): CDFA-FREP «25 a 75 lb
  // N/acre suele bastar en durazno de fresco» (28–84 kg/ha; 6 t/acre → 71
  // kg/ha); Penn State «50 a 100 lb N/acre/año» (56–112) y el propio
  // autor aplica 67 en suelo fértil; INIFAP Zacatecas 55-55-55. El techo
  // 112 se sostiene.
  n: (60.0, 112.0),
  p: (0.0, 60.0),
  k: (0.0, 120.0),
  planSourceEs:
      'Penn State (50–100 lb N/acre/año en durazno adulto), CDFA-FREP '
      '(25–100 lb N/acre) e INIFAP Zacatecas (55-55-55 a 20 t/ha)',
  planNotesEs:
      'Huerta adulta a 20–30 t/ha: el mínimo (60) es lo que CDFA y Penn '
      'State dan para durazno de fresco en suelo fértil; el techo 112 (= 100 '
      'lb/acre) porque ninguna de las tres fuentes pasa de ahí: en durazno '
      'el exceso de nitrógeno cuesta color, firmeza y vida de anaquel. '
      'INIFAP Zacatecas es todavía más corto y avisa que «cantidades '
      'superiores no incrementan el rendimiento ni la calidad del fruto».',
  pNotesEs: 'Solo si el foliar sale bajo; el durazno adulto rara vez responde.',
  kNotesEs:
      'La fruta se lleva 4–5 lb de K₂O por tonelada: a 20–30 t/ha son 45–68 '
      'kg/ha. Aplica por encima de eso solo si el foliar de julio sale por '
      'debajo de 1.2 %.',
);

final NutritionGuide _walnutTree = _treeGuide(
  cropKey: 'walnut_tree',
  labelEs: 'Nogal',
  split: NitrogenSplitRequirement.splitRecommended,
  minPasses: 2,
  minPassesCoarse: 3,
  minPassesFine: 1,
  maxSinglePassKgN: 120,
  // La única en marzo (Cruz-Álvarez 2020; INIFAP PT-0008: 110 kg/ha a
  // mediados de marzo; NMSU H-602; UGA B1304); con dos, marzo + mayo-junio
  // ≈ 55/45; con tres se suma agosto (Tarango-INIFAP: al menos un tercio
  // de lo de primavera). Verificación del 17 sep 2026.
  nitrogenPassPriority: <String>['budbreak', 'fruit_set', 'fruit_fill'],
  splitNotesEs:
      'Cruz-Alvarez et al. (2020, Jiménez, Chih., 5 años, 41 % arcilla, '
      'microaspersión): 100 kg N/ha en una sola aplicación de marzo igualó '
      'estadísticamente a la fraccionada marzo+junio (44.6 vs 43.1 '
      'kg/árbol). NMSU H-602: mitad en marzo y resto en junio; en arena, '
      'tercios (marzo, abril, junio).',
  rules: _pecanTreeRules,
  sources: const <GuideSource>[
    GuideSource(
      labelEs:
          'Revista Chapingo Serie Horticultura 26(3) / SciELO, Fertilización '
          'nitrogenada en nogal pecanero (Cruz-Álvarez et al., Jiménez, '
          'Chihuahua, Western Schley a 12×12 m): 100 kg N/ha en una sola '
          'aplicación de marzo rindió 44.6 kg/árbol, sin diferencia '
          'estadística frente a 150 y 200',
      url: 'https://www.scielo.org.mx/scielo.php?pid=S1027-152X2020000300163&script=sci_arttext&tlng=es',
      year: 2020,
    ),
    GuideSource(
      labelEs: 'Intagri, Fenología y nutrición del nogal pecanero (reparto del N '
          'por etapa en fertirriego)',
      url: 'https://www.intagri.com/articulos/frutales/fenologia-y-nutricion-del-nogal-pecanero',
    ),
  ],
  // Techo 200 desde el 17 sep 2026 (antes 150): NMSU H-602 «150–200 lb N
  // real por acre al año» (168–224); INIFAP PT-0008 110 en marzo + 110 en
  // mayo con buena cosecha (220); Tarango-INIFAP Delicias 220–240 en 7
  // fracciones; Sánchez et al. 2009 (Aldama, Terra) óptimo 160; UGA/TAMU
  // 10 lb N por cada 100 lb de nuez (2 t/ha ≈ 200). El mínimo 100 lo
  // sostiene Cruz-Álvarez (Jiménez, 41 % arcilla).
  n: (100.0, 200.0),
  p: (0.0, 80.0),
  k: (0.0, 120.0),
  planSourceEs:
      'Nogal pecanero en Chihuahua (SciELO 2020; INIFAP PT-0008; '
      'Tarango-INIFAP Delicias; Sánchez 2009, Terra), NMSU H-602 y UGA',
  planNotesEs:
      'Huerta pecanera adulta de riego a 1.5–2.5 t/ha de nuez. En suelo '
      'arcilloso con reservas (Jiménez) 100 kg N/ha rindió igual que 150 y '
      '200: quédate en 100–150. Con carga alta, suelo ligero o riego rodado '
      'sube hacia 200 (INIFAP: 110 en marzo + 110 en mayo si se espera '
      'buena cosecha; NMSU 168–224; UGA 10 kg de N por cada 100 kg de '
      'nuez esperada).',
  pNotesEs:
      'NMSU: «salvo en suelos arenosos, las aplicaciones anuales normalmente '
      'no son necesarias ni recomendables». UGA lo aplica solo con foliar por '
      'debajo de 0.12 %.',
  kNotesEs:
      'Por análisis, no por calendario. Pero mídelo: en el huerto de Jiménez '
      'el potasio foliar salió en 1.06–1.16 %, por debajo del mínimo de 1.2 % '
      'de NMSU. En la zona nogalera de Chihuahua el potasio sí está saliendo '
      'corto.',
  notesEs:
      'Nogal pecanero (Chihuahua); el año de plantación no lleva plan. El zinc '
      'foliar va aparte y es el nutriente que más suele faltar: en Jiménez el '
      'foliar dio 33–40 ppm contra una suficiencia de 50–100.',
);

final NutritionGuide _pistachioTree = _treeGuide(
  cropKey: 'pistachio_tree',
  labelEs: 'Pistache',
  split: NitrogenSplitRequirement.splitRequired,
  minPasses: 2,
  // Con dos pasadas: crecimiento del fruto (antes del endurecimiento de la
  // cáscara) y llenado, 50/50 (CDFA «año off»: la mitad antes del
  // endurecimiento y el resto en julio-agosto; Siddiqui & Brown: al menos
  // 80 % entre foliación y apertura de ruezno). Verificación del 17 sep 2026.
  nitrogenPassPriority: <String>['fruit_set', 'fruit_fill', 'budbreak', 'harvest_maturity'],
  splitNotesEs:
      'Amaral & Brown (UC): absorción bimodal, ~30 % en el flujo de '
      'primavera y ~70 % en el llenado de nuez, con absorción despreciable '
      'post-cosecha. Una sola aplicación no cubre las dos ventanas.',
  rules: _pistachioTreeRules,
  sources: const <GuideSource>[
    GuideSource(
      labelEs:
          'CDFA-FREP, Pistachio nitrogen uptake: 56.1 lb N por tonelada seca '
          'removida. El «30 % en primavera / 70 % en llenado» de esta página '
          'es la curva de ABSORCIÓN del árbol, no un calendario de aplicación',
      url: 'https://www.cdfa.ca.gov/is/ffldrs/frep/FertilizationGuidelines/N_Pistachio.html',
    ),
    GuideSource(
      labelEs:
          'CDFA-FREP, Pistachio fertilization guideline (Brown y Siddiqui): la '
          'recomendación de APLICACIÓN es 20 % tras la foliación, 30 % en '
          'crecimiento de fruto, 30 % en llenado y 20 % en madurez; el fósforo '
          'en noviembre tras la caída de hoja; el potasio 40/40/20 en mayo, '
          'junio y julio',
      url: 'https://www.cdfa.ca.gov/is/ffldrs/frep/FertilizationGuidelines/Pistachio.html',
    ),
    _srcUcanrFruitNut,
  ],
  n: (120.0, 200.0),
  p: (0.0, 70.0),
  k: (120.0, 200.0),
  planSourceEs: 'CDFA-FREP y UC ANR (huerta adulta en año de carga)',
  planNotesEs:
      'Huerta adulta en año de carga (2–3 t/ha en seco); en año de descarga '
      'usa el mínimo. Alternancia marcada. La cuenta de CDFA es: kilos de nuez '
      'seca × 28 kg N por tonelada, más unos 24 kg/ha de crecimiento del '
      'árbol, dividido entre la eficiencia del riego (0.70 en goteo, 0.50 en '
      'rodado). En riego rodado la misma meta pide bastante más nitrógeno.',
  pNotesEs: 'Solo si el análisis lo pide, y en noviembre tras la caída de hoja.',
  notesEs: 'Alternancia marcada: en año de carga alta sube el K.',
);

const GuideSource _srcCitrusUf = GuideSource(
  labelEs:
      'UF/IFAS CMG13, Nutrition Management for Citrus Trees: 125–240 lb N/acre '
      'en naranja (120–160 en toronja), K₂O = 1.25 × la dosis de N, y fósforo solo '
      'cuando el análisis foliar Y el de suelo salen bajos (8 lb P₂O₅/acre por '
      'cada 100 cajas)',
  url: 'https://ask.ifas.ufl.edu/publication/CG091',
);

const GuideSource _srcCitrusCdfa = GuideSource(
  labelEs:
      'CDFA-FREP, Citrus: dos tercios del nitrógeno anual entre el brote de '
      'primavera y el amarre; remoción de 0.39–0.44 lb P₂O₅ y 1.78–2.36 lb '
      'K₂O por cada 1 000 lb de naranja cosechada',
  url: 'https://www.cdfa.ca.gov/is/ffldrs/frep/FertilizationGuidelines/Citrus.html',
);

/// Referencia mexicana, con su contexto a la vista: es un ensayo de rescate
/// nutricional en huerta ENFERMA (47 % de tristeza y 64.7 % de huanglongbing)
/// y en sequía atípica, con árboles de 6 años rindiendo 5–12 kg cada uno. Su
/// fórmula sirve para ver el balance N:K que se maneja en el trópico mexicano,
/// no como referencia de una huerta sana de 20–35 t/ha.
const GuideSource _srcCitrusVeracruz = GuideSource(
  labelEs:
      'Revista Fitotecnia Mexicana 44(1), Fertilización integral en naranjo '
      'Marrs CON SÍNTOMAS DE TRISTEZA Y HUANGLONGBING (Cazones, Veracruz; '
      'árboles de 6 años a 400 árboles/ha, 5–12 kg por árbol en sequía '
      'atípica): fórmula 100 N – 22 P₂O₅ – 195 K₂O – 30 MgO',
  url: 'https://www.scielo.org.mx/scielo.php?script=sci_arttext&pid=S0187-73802021000100059',
  year: 2021,
);

const GuideSource _srcIntagriCitrus = GuideSource(
  labelEs: 'Intagri, Nutrición de cítricos de alto rendimiento',
  url: 'https://www.intagri.com/articulos/frutales/nutricion-citricos-alto-rendimiento',
);

final NutritionGuide _orangeTree = _treeGuide(
  cropKey: 'orange_tree',
  labelEs: 'Naranjo',
  // Desde el 17 sep 2026: conviene fraccionar, mínimo 2 (3 en arena) y la
  // guía recomienda 3. El «mínimo 3» anterior no era defendible: CDFA-FREP
  // cita el ensayo de Tulare (dos aplicaciones, fines de invierno y fines
  // de mayo, mismo rendimiento que una y menos lixiviación); el ensayo de
  // Veracruz (Fitotecnia 2021) usó dos aplicaciones al suelo; el «3–4» de
  // UF/IFAS es para fertilizante seco en la arena de Florida.
  split: NitrogenSplitRequirement.splitRecommended,
  minPasses: 2,
  minPassesCoarse: 3,
  recommendedPasses: 3,
  // La única entre el brote de primavera y la floración (CDFA: dos tercios
  // del N entre el brote de primavera y el amarre; UF/IFAS: pico de
  // demanda de floración al fin de la fase 1; UC ANR: absorción de abril a
  // noviembre, ninguna de diciembre a febrero); con dos, se suma fin de
  // mayo (cuajado).
  nitrogenPassPriority: <String>['budbreak', 'fruit_set', 'post_harvest', 'harvest_maturity'],
  splitNotesEs:
      'CDFA-FREP: cerca de dos tercios del nitrógeno anual entre el brote de '
      'primavera y el amarre; en Tulare, dos aplicaciones (fines de '
      'invierno y fines de mayo) redujeron la lixiviación frente a una sola '
      'con el mismo rendimiento. UF/IFAS: 3–4 aplicaciones de fertilizante '
      'seco en arena profunda, o liberación controlada. De fines de febrero '
      'a mediados de agosto como límite.',
  rules: _citrusTreeRules,
  sources: const <GuideSource>[
    _srcCitrusUf,
    _srcCitrusCdfa,
    _srcCitrusVeracruz,
    _srcIntagriCitrus,
  ],
  n: (100.0, 180.0),
  p: (0.0, 30.0),
  k: (100.0, 200.0),
  planSourceEs: 'UF/IFAS (120–200 lb N/acre; K₂O = 1.25 × N) y CDFA-FREP',
  planNotesEs: 'Huerta adulta a 20–35 t/ha; el N se ajusta con análisis foliar (≈2.5–2.8 %).',
  pNotesEs:
      'La naranja se lleva apenas 8–15 kg de P₂O₅/ha al año y una huerta '
      'establecida suele traer de sobra del año pasado. Aplícalo solo si el '
      'foliar sale por debajo de 0.12 % Y el análisis de suelo también sale '
      'bajo.',
);

final NutritionGuide _lemonTree = _treeGuide(
  cropKey: 'lemon_tree',
  labelEs: 'Limonero',
  // Mismo criterio que el naranjo (17 sep 2026): conviene fraccionar,
  // mínimo 2 (3 en arena), recomendado 3.
  split: NitrogenSplitRequirement.splitRecommended,
  minPasses: 2,
  minPassesCoarse: 3,
  recommendedPasses: 3,
  nitrogenPassPriority: <String>['budbreak', 'fruit_set', 'post_harvest', 'harvest_maturity'],
  splitNotesEs:
      'CDFA-FREP: cerca de dos tercios del nitrógeno anual entre el brote de '
      'primavera y el amarre; dos aplicaciones (fines de invierno y fines '
      'de mayo) rindieron igual que una sola con menos lixiviación. El '
      'limonero, con cortes repetidos, reparte igual o más: de fines de '
      'febrero a mediados de agosto como límite, y en arena tres o más.',
  rules: _citrusTreeRules,
  sources: const <GuideSource>[
    _srcCitrusUf,
    GuideSource(
      labelEs:
          'Revista Mexicana de Ciencias Agrícolas 8(19) / SciELO, Remoción de '
          'nutrimentos por la cosecha de limón persa (Nayarit y Veracruz): '
          '1.4–2.2 kg de N y 1.2–2.2 kg de K por tonelada de fruta según el '
          'flujo de floración',
      url: 'https://www.scielo.org.mx/scielo.php?script=sci_arttext&pid=S2007-09342017001103939',
      year: 2017,
    ),
    _srcCitrusCdfa,
    _srcIntagriCitrus,
  ],
  n: (100.0, 180.0),
  p: (0.0, 30.0),
  k: (100.0, 180.0),
  planSourceEs: 'UF/IFAS, CDFA-FREP y remoción medida en limón persa mexicano',
  planNotesEs:
      'Limón persa/mexicano adulto a 20–30 t/ha. Tiene varias floraciones al '
      'año y corta casi todo el tiempo: el 70 % de la fruta sale entre mayo y '
      'septiembre y el 30 % restante de octubre a abril. Por eso la ventana de '
      'cosecha no calla, solo baja.',
  pNotesEs:
      'La fruta se lleva unos 0.2 kg de fósforo por tonelada. Solo con foliar '
      'y suelo bajos.',
);

final NutritionGuide _mangoTree = _treeGuide(
  cropKey: 'mango_tree',
  labelEs: 'Mango',
  split: NitrogenSplitRequirement.splitRecommended,
  minPasses: 2,
  // La única DESPUÉS de la cosecha (AMIA: 60–70 % del N anual
  // post-cosecha; National Mango Board: «en particular el nitrógeno,
  // inmediatamente después de la cosecha»; INIFAP Ataulfo: julio y
  // septiembre; UF/IFAS: poco o nada en árbol adulto); con dos, se suma el
  // cuajado. Verificación del 17 sep 2026.
  nitrogenPassPriority: <String>['post_harvest', 'fruit_set', 'budbreak'],
  splitNotesEs:
      'National Mango Board: 2 a 4 aplicaciones al suelo (cuaje/crecimiento '
      'rápido, post-cosecha y otoño); evitar N en pre-cosecha por colapso '
      'interno del fruto.',
  rules: _mangoTreeRules,
  sources: const <GuideSource>[
    GuideSource(
      labelEs:
          'Revista Mexicana de Ciencias Agrícolas / SciELO (INIFAP), '
          'Fertilización de sitio específico en mango Kent y Tommy Atkins '
          '(Nayarit, 10×10 m = 100 árboles/ha, temporal): la dosis óptima fue '
          '548–794 g N, 219–328 g P₂O₅ y 259–572 g K₂O por árbol, es decir '
          '55–79 kg N, 22–33 kg P₂O₅ y 26–57 kg K₂O por hectárea, a 13.8–18.7 '
          't/ha',
      url: 'https://www.scielo.org.mx/scielo.php?script=sci_arttext&pid=S2007-09342014000400009',
      year: 2014,
    ),
    GuideSource(
      labelEs:
          'Terra Latinoamericana 37(4) / SciELO (INIFAP), Fertilización de '
          'sitio específico en mango Ataulfo (Nayarit, 8×8 m = 156 '
          'árboles/ha): 509–608 g N por árbol aplicados en JULIO y SEPTIEMBRE '
          '—después de la cosecha—, +38 % de rendimiento',
      url: 'https://www.scielo.org.mx/scielo.php?script=sci_arttext&pid=S0187-57792019000400415',
      year: 2019,
    ),
    GuideSource(
      labelEs:
          'UF/IFAS HS2/MG216, Mango: en árbol adulto y sano «poco o nada de '
          'nitrógeno hace falta; en cambio, enfatice el potasio y los '
          'micronutrientes»',
      url: 'https://ask.ifas.ufl.edu/publication/MG216',
    ),
    GuideSource(
      labelEs: 'Intagri, El cultivo de mango y su fertilización',
      url: 'https://www.intagri.com/articulos/nutricion-vegetal/el-cultivo-de-mango-y-su-fertilizacion',
    ),
  ],
  n: (60.0, 90.0),
  p: (0.0, 40.0),
  k: (40.0, 70.0),
  planSourceEs: 'INIFAP Nayarit (sitio específico, Kent y Tommy Atkins) y UF/IFAS',
  planNotesEs:
      'Huerta adulta a 100 árboles/ha y 12–19 t/ha. Los techos bajaron para no '
      'rebasar la propia fuente: el ensayo de INIFAP llega a 79 kg N/ha en su '
      'dosis óptima. Si tu huerta está más densa (150 árboles/ha o más), sube '
      'proporcionalmente.',
  pNotesEs:
      'El mango se lleva 0.1–0.2 kg de fósforo por tonelada. Solo si el '
      'análisis lo pide.',
  notesEs:
      'El grueso del nitrógeno va DESPUÉS de la cosecha, no antes de la flor: '
      'nitrógeno alto antes de floración favorece flujo vegetativo y te deja '
      'con menos flor.',
);

final NutritionGuide _avocadoTree = _treeGuide(
  cropKey: 'avocado_tree',
  labelEs: 'Aguacate',
  split: NitrogenSplitRequirement.splitRecommended,
  minPasses: 2,
  // La única en el bloque floración → cuajado temprano («abril» de Lovatt:
  // el N extra ahí subió el rendimiento y redujo la alternancia; CDFA:
  // «la mayor parte del N en primavera justo después de plena floración»;
  // INIFAP Nayarit: 70 % entre febrero y mayo); con dos, se suma la
  // post-cosecha (el «noviembre» de Lovatt, fin del crecimiento
  // vegetativo, la de mayor efecto). Verificación del 17 sep 2026.
  nitrogenPassPriority: <String>['budbreak', 'post_harvest', 'fruit_set'],
  splitNotesEs:
      'Lovatt (UC Riverside 2013): sobre una base de 125 lb N/acre en cinco '
      'aplicaciones, 25 lb extra en abril (antesis a cuajado temprano) o en '
      'noviembre (fin del crecimiento vegetativo) subieron el rendimiento; '
      'cuatro aplicaciones de 25 lb (abril, julio, agosto y noviembre) '
      'igualaron al programa con dosis doble. El momento pesa más que el '
      'número; el N de enero-febrero es el más lixiviable.',
  rules: _evergreenTreeRules,
  sources: const <GuideSource>[
    GuideSource(
      labelEs:
          'Agricultura Técnica en México / SciELO, Fertilización de sitio '
          'específico en aguacate Hass: referencia Michoacán 200 N – 200 P₂O₅ – '
          '100 K₂O (100 árboles/ha, 16.7 t/ha); Nayarit 334 N – 116 P₂O₅ – '
          '393 K₂O a 28 t/ha',
      url: 'https://www.scielo.org.mx/scielo.php?script=sci_arttext&pid=S0568-25172009000400009',
      year: 2009,
    ),
    GuideSource(
      labelEs: 'Intagri, Concentración de nutrientes en plantas de aguacate',
      url: 'https://www.intagri.com/articulos/frutales/concentracion-de-nutrientes-en-plantas-de-aguacate',
    ),
  ],
  n: (150.0, 220.0),
  p: (0.0, 60.0),
  k: (120.0, 200.0),
  planSourceEs:
      'UC ANR (150–200 lb N/acre en huerta Hass adulta) e INIFAP Michoacán',
  planNotesEs:
      'Huerta Hass adulta a 12–20 t/ha. Aquí hay dos escuelas y conviene '
      'saberlo: UC ANR maneja 168–224 kg N/ha y CDFA-FREP, que parte del '
      'balance de extracción, se queda en 81–100. Este plan sigue a UC ANR, '
      'que es la referencia de la que salió el manejo comercial de Hass. Si '
      'vas a ajustar, hazlo con el foliar: 2.0–2.2 % de nitrógeno es el rango '
      'bueno.',
  pNotesEs:
      'La fruta se lleva unos 29–48 kg de P₂O₅/ha al año. Aplícalo solo si el '
      'foliar sale por debajo de 0.10 %, y ten en cuenta que un fósforo foliar '
      'alto estorba la absorción de zinc.',
  kNotesEs:
      'La fruta se lleva 86–168 kg de K₂O/ha. NUNCA lo cubras con cloruro de '
      'potasio: el aguacate está clasificado como sensible a sales y el cloro '
      'foliar es tóxico a partir de 0.25 %. Usa sulfato o nitrato de potasio.',
  notesEs:
      'Raíz superficial y sensible a sales: dosis pequeñas y frecuentes. El '
      'grueso del nitrógeno va antes de la floración, no después de la '
      'cosecha: es lo contrario del mango.',
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
      rationaleEs:
          'Fósforo para la raíz; nada de nitrógeno fuerte hasta que arraigue.',
    ),
    StageNutritionRule(
      stageKeys: <String>{'vegetative_flush'},
      windowNutrients: <AgroMetricKey>{AgroMetricKey.n},
      labelEs: 'Brotación',
      timingEs: 'Al inicio de cada brotación, en dosis ligera y con riego.',
      rationaleEs: 'El nitrógeno sostiene el brote que va a traer el botón.',
      rulesEs: <String>['N alto con brotación muy vigorosa da tallo blando y menos flor.'],
    ),
    StageNutritionRule(
      stageKeys: <String>{'bud_formation'},
      windowNutrients: <AgroMetricKey>{AgroMetricKey.k, AgroMetricKey.p},
      labelEs: 'Botón',
      rationaleEs: 'Fósforo y potasio para el tamaño y el color de la flor.',
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
      timingEs: 'Después de podar las flores marchitas.',
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
    rationaleEs:
        'Fósforo en el fondo para la raíz; nada de nitrógeno sobre la semilla.',
  ),
  StageNutritionRule(
    stageKeys: <String>{'early_vegetative_growth', 'active_vegetative_growth'},
    windowNutrients: <AgroMetricKey>{AgroMetricKey.n},
    labelEs: 'Crecimiento vegetativo',
    timingEs: 'Repartido, con riego.',
    rationaleEs: 'El nitrógeno construye la planta antes del botón.',
  ),
  StageNutritionRule(
    stageKeys: <String>{'stem_elongation', 'bud_formation'},
    windowNutrients: <AgroMetricKey>{AgroMetricKey.k, AgroMetricKey.p},
    labelEs: 'Alargamiento y botón',
    rationaleEs:
        'Potasio para un tallo firme y buen color; el nitrógeno alto aquí '
        'acuesta la planta y retrasa la flor.',
    rulesEs: <String>['Corta el N al ver el botón.'],
  ),
  StageNutritionRule(
    stageKeys: <String>{'flowering', 'post_bloom', 'senescence', 'cycle_complete'},
    windowNutrients: <AgroMetricKey>{},
    labelEs: 'Floración',
    rationaleEs: 'Ventana cerrada: en flor ya no conviene fertilizar.',
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
      rationaleEs:
          'Un poco de fósforo bajo el bulbo; el bulbo ya trae sus reservas.',
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
      timingEs: 'Justo después de la floración, mientras la hoja sigue verde.',
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
    rationaleEs: 'Sin fertilizar hasta que arraigue; el exceso pudre la raíz.',
  ),
  StageNutritionRule(
    stageKeys: <String>{'active_growth'},
    windowNutrients: <AgroMetricKey>{AgroMetricKey.n},
    labelEs: 'Crecimiento activo',
    timingEs: 'Una o dos dosis ligeras en la temporada de crecimiento.',
    rationaleEs: 'Es una planta de baja demanda: poco y diluido es suficiente.',
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
    // Frutales (plan anual de huerta en producción).
    'apple_tree': _appleTree,
    'pear_tree': _pearTree,
    'peach_tree': _peachTree,
    'walnut_tree': _walnutTree,
    'pistachio_tree': _pistachioTree,
    'orange_tree': _orangeTree,
    'lemon_tree': _lemonTree,
    'mango_tree': _mangoTree,
    'avocado_tree': _avocadoTree,
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
