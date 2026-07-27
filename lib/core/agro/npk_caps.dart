import 'package:bio_g/core/agro/agro_types.dart';

class NpkCaps {
  const NpkCaps._();

  static String _normalizeCropKey(String? cropKey) =>
      (cropKey ?? '').trim().toLowerCase();

  static double forCropMetric({
    required String? cropKey,
    required AgroMetricKey metricKey,
  }) {
    final normalizedCropKey = _normalizeCropKey(cropKey);

    switch (metricKey) {
      case AgroMetricKey.n:
        switch (normalizedCropKey) {
          case 'bean':
            return 80.0;
          case 'barley':
            return 100.0;
          // Tomate demanda alta pero es sensible a exceso vegetativo.
          // Cap ligeramente más alto para no clasificar como "exceso" una
          // lectura que en hortaliza sigue siendo operativa.
          case 'tomato':
          case 'tomate':
          case 'jitomate':
            return 130.0;
          case 'cucumber':
          case 'pepino':
            return 130.0;
          case 'chili':
          case 'chile':
          case 'pepper':
          case 'pimiento':
            return 130.0;
          case 'eggplant':
          case 'berenjena':
          case 'aubergine':
            return 130.0;
          // Calabaza: PDF Guia v1 sugiere 84-112 kg/ha N base para
          // calabacita y 56-112 kg/ha para fruto maduro. El cap operativo
          // (lectura de mg/kg que NO se considera "exceso") queda
          // moderado a 120 mg/kg para no clasificar lecturas funcionales
          // como exceso. CA-07/pipian comparte cap.
          case 'squash':
          case 'calabaza':
          case 'pumpkin':
            return 120.0;
          // Lechuga: hortaliza de hoja de ciclo corto y raiz superficial.
          // Demanda foliar moderada; cap operativo de 110 mg/kg evita
          // clasificar como exceso una lectura funcional de N en E3.
          case 'lettuce':
          case 'lechuga':
            return 110.0;
          case 'spinach':
          case 'crop_spinach':
          case 'espinaca':
            return 120.0;
          // Cebolla: hortaliza de bulbo con demanda alta de N temprano,
          // pero peligrosa tarde. Cap operativo de 130 mg/kg cubre la
          // demanda vegetativa sin marcar como exceso una lectura util.
          case 'onion':
          case 'crop_onion':
          case 'cebolla':
          case 'garlic':
          case 'crop_garlic':
          case 'ajo':
            return 130.0;
          // Manzano (perenne). El N de suficiencia de suelo del doc 05 ronda
          // 18-45 mg/kg en etapas de fruto y hasta 55-75 en juvenil/vegetativo.
          // Cap 90 deja el optimo de fruto en ~0.3-0.5 del gauge y deja
          // cabecera para visualizar "alto util" y "exceso" por encima.
          case 'apple_tree':
          case 'crop_apple_tree':
          case 'manzano':
            return 90.0;
          // Pera (perenne, pepita). Doc 05 expresa N/P/K en escala RELATIVA
          // 0..1; el cap convierte ese rango a mg/kg comparable. N suficiencia
          // de fruto ronda 18-45 mg/kg y hasta 55-75 en juvenil; cap 90 deja el
          // óptimo de fruto en ~0.3-0.5 del gauge con cabecera para alto/exceso.
          case 'pear_tree':
          case 'crop_pear_tree':
          case 'pera':
          case 'peral':
            return 90.0;
          // Durazno (perenne, hueso/carozo). Doc 05 §5/§17 fija cap N=110: el
          // durazno demanda más N vegetativo que pepita, pero el exceso es
          // peligroso. El cap más alto evita marcar como "exceso" una lectura de
          // N que en durazno aún es funcional para hoja/madera.
          case 'peach_tree':
          case 'crop_peach_tree':
          case 'peach':
          case 'peachtree':
          case 'durazno':
          case 'duraznero':
          case 'melocoton':
          case 'melocotón':
          case 'melocotonero':
            return 110.0;
          // Nogal pecanero (perenne, nuez). Doc 05 §0.2/§5 fija cap N=120: el N
          // es protagonista del nogal (hoja, area foliar, reservas, llenado de
          // almendra), pero el exceso es peligroso (vigor, sombra, sales,
          // desbalance con Zn). Cap NO es dosis; solo normaliza la lectura cruda.
          case 'walnut_tree':
          case 'crop_walnut_tree':
          case 'walnut':
          case 'walnuttree':
          case 'nogal':
          case 'pecan':
          case 'nuez':
            return 120.0;
          // Pistache (perenne, nuez, dioico). Doc 05 §0.12/§5 fija cap N=130: N
          // es protagonista (hoja, area foliar, reservas, llenado), pero el
          // exceso da puro vigor, sales y desbalance. Cap NO es dosis; solo
          // normaliza la lectura cruda.
          case 'pistachio_tree':
          case 'crop_pistachio_tree':
          case 'pistache':
          case 'pistacho':
          case 'pistachio':
          case 'pistachero':
            return 130.0;
          // Naranjo (perenne, cítrico siempreverde). Doc 05 §0.3 fija cap N=120:
          // N es protagonista en cítricos (hoja, brote, floración, soporte),
          // pero el exceso da follaje, cáscara gruesa, retraso de color y
          // desbalance con K. Cap NO es dosis; solo normaliza la lectura cruda.
          case 'orange_tree':
          case 'crop_orange_tree':
          case 'orange':
          case 'naranjo':
          case 'naranja':
            return 120.0;
          // Limón (perenne, cítrico siempreverde). Doc 05 §0.0.1/§2 fija cap
          // N=130: producción frecuente (brotación/floración/corte) exige N para
          // hoja, brote y recuperación; se sube sobre naranjo, pero se evita
          // inflar (N alto empuja brote tierno, baja calidad y desbalance con
          // K). Cap NO es dosis; solo normaliza la lectura cruda.
          case 'lemon_tree':
          case 'crop_lemon_tree':
          case 'lime_tree':
          case 'crop_lime_tree':
          case 'lemon':
          case 'lime':
          case 'limon':
          case 'limón':
          case 'limonero':
          case 'lima':
            return 130.0;
          // Mango (perenne, tropical/subtropical siempreverde). Doc 05 §0.0.2/§2
          // fija cap N=115: el mango necesita N para hoja, brote, floración
          // funcional, cuajado y recuperación postcosecha, pero el exceso o mala
          // sincronización favorece flush vegetativo e inhibe floración (queda
          // por debajo de cítricos y apenas arriba de durazno). Cap NO es dosis;
          // solo normaliza la lectura cruda.
          case 'mango_tree':
          case 'crop_mango_tree':
          case 'crop_mango':
          case 'mango':
          case 'mangos':
          case 'mangifera':
          case 'mangifera_indica':
          case 'arbol_mango':
          case 'árbol_mango':
            return 115.0;
          // Aguacate (perenne, subtropical/tropical siempreverde). Doc 05 §0.2/
          // §2 fija cap N=120: el aguacate necesita N para hoja, brote, clorofila,
          // floración funcional, retención inicial y recuperación postcosecha,
          // pero el exceso o mala sincronización empuja vegetativo, compite con
          // flor/fruto, baja calidad y desbalancea Ca/K/Mg. Cap NO es dosis; solo
          // normaliza la lectura cruda. EC/cloruros/sodio/boro y raíz pueden
          // bloquear cualquier NPK.
          case 'avocado_tree':
          case 'crop_avocado_tree':
          case 'crop_avocado':
          case 'avocado':
          case 'avocados':
          case 'aguacate':
          case 'aguacates':
          case 'palta':
          case 'palto':
          case 'persea':
          case 'persea_americana':
          case 'arbol_aguacate':
          case 'árbol_aguacate':
          case 'arbol de aguacate':
          case 'árbol de aguacate':
            return 120.0;
          // Cactus (ornamental xerófito). Planta de BAJA demanda: cap N=60. El
          // exceso de N es activamente dañino (tejido blando, propenso a
          // pudrición), no solo "desperdicio". Cap bajo para que una lectura de
          // 40-50 mg/kg ya se lea como alta, no como normal.
          case 'cactus':
          case 'crop_cactus':
          case 'cacto':
          case 'cactos':
            return 60.0;
          // Suculenta (ornamental no cactácea). Demanda baja-moderada: cap N=70,
          // algo mayor que cactus porque su crecimiento activo sí usa N, pero
          // muy por debajo de un cultivo de rendimiento. El exceso de N alarga y
          // ablanda el tejido (Doc B §5). El cap NO es una dosis.
          case 'succulent':
          case 'crop_succulent':
          case 'suculenta':
          case 'suculentas':
            return 70.0;
          // Sábila / Aloe. La ornamental de mayor demanda de las tres: cap N=85
          // (cactus 60 · suculenta 70 · sábila 85), porque es la única con una
          // respuesta a N medida (150 kg N/ha maximizó rendimiento, Doc B §4.6,
          // §5). Sigue muy por debajo de un cultivo de rendimiento. NO es dosis.
          case 'aloe':
          case 'crop_aloe':
          case 'sabila':
          case 'sábila':
          case 'zabila':
          case 'zábila':
            return 85.0;
          // Maguey / Agave: cap N=90 (cactus 60 · suculenta 70 · sábila 85 ·
          // maguey 90). Es la ornamental con la respuesta a N mejor documentada
          // (fertigación en A. tequilana/potatorum, Doc B §4.6, §5). Muy por
          // debajo de un cultivo de rendimiento. NO es dosis.
          case 'agave':
          case 'crop_agave':
          case 'maguey':
            return 90.0;
          // Nopal: cap N=90 (cactus 60 - suculenta 70 - sabila 85 - maguey 90 -
          // nopal 90). El nopal tiene una respuesta de crecimiento a N mejor
          // documentada que el cactus: la ausencia completa de N limita la
          // emision de cladodios. Sigue muy por debajo de un cultivo de
          // rendimiento (Doc B section 10.4, 10.5). NO es dosis.
          case 'nopal':
          case 'crop_nopal':
          case 'nopales':
          case 'opuntia':
          case 'orn_nopal':
          case 'prickly pear':
          case 'cactus pear':
            return 90.0;
          // Rosal: cap N=120 (Doc B §0). Arbusto ornamental de flor con demanda
          // real de N en brotación; muy por encima de las ornamentales
          // xerófitas. El cap normaliza el gauge, NO es una dosis.
          case 'rose':
          case 'crop_rose':
          case 'rosal':
            return 120.0;
          // Tulipán: cap N=100 (Documento B §9.6). Demanda baja-moderada; el
          // bulbo ya trae reservas de N y el exceso no debe dominar. El cap
          // normaliza el gauge, NO es una dosis.
          case 'tulip':
          case 'crop_tulip':
          case 'tulipan':
          case 'tulipán':
            return 100.0;
          // Girasol: cap N=130 (Documento B §0.3, §11). Demanda anual
          // moderada-alta, con techo prudente por vuelco y enfermedad. El cap
          // normaliza el gauge, NO es una dosis.
          case 'sunflower':
          case 'crop_sunflower':
          case 'girasol':
            return 130.0;
          // Cempasúchil: cap N=110 (Documento B §0, §10.4, §10.5). Menor que el
          // Girasol: es un cultivo de baja demanda en jardín y el exceso de N
          // favorece follaje, retrasa la floración y ablanda el tallo. El cap
          // normaliza el gauge, NO es una dosis.
          case 'marigold':
          case 'crop_marigold':
          case 'cempasuchil':
          case 'cempasúchil':
          case 'cempoalxochitl':
          case 'cempoalxóchitl':
          case 'flor de muerto':
          case 'orn_cempasuchil':
          case 'tagetes erecta':
            return 110.0;
          default:
            return 120.0;
        }
      case AgroMetricKey.p:
        switch (normalizedCropKey) {
          // Tomate requiere P starter alto en establecimiento (anclaje
          // de trasplante) y sostenido hasta cuajado.
          case 'tomato':
          case 'tomate':
          case 'jitomate':
            return 90.0;
          case 'cucumber':
          case 'pepino':
            return 90.0;
          case 'chili':
          case 'chile':
          case 'pepper':
          case 'pimiento':
            return 90.0;
          case 'eggplant':
          case 'berenjena':
          case 'aubergine':
            return 90.0;
          case 'squash':
          case 'calabaza':
          case 'pumpkin':
            return 90.0;
          // Lechuga: P pesa en establecimiento (raiz superficial joven).
          case 'lettuce':
          case 'lechuga':
            return 85.0;
          case 'spinach':
          case 'crop_spinach':
          case 'espinaca':
            return 90.0;
          // Cebolla: P pesa en arranque/raiz superficial y suelos frios o
          // alcalinos. Cap operativo de 90 mg/kg.
          case 'onion':
          case 'crop_onion':
          case 'cebolla':
          case 'garlic':
          case 'crop_garlic':
          case 'ajo':
            return 90.0;
          // Manzano: P de suelo del doc 05 pesa fuerte en establecimiento/raiz
          // (optimo 60-80 mg/kg) y baja a 35-55 en fruto. Cap 110 centra el
          // rango de raiz (~0.6) y mantiene el de fruto (~0.4) en el gauge.
          case 'apple_tree':
          case 'crop_apple_tree':
          case 'manzano':
            return 110.0;
          // Pera: P pesa fuerte en establecimiento/raíz (óptimo relativo alto) y
          // baja en fruto adulto. Cap 110 centra el rango de raíz en el gauge.
          case 'pear_tree':
          case 'crop_pear_tree':
          case 'pera':
          case 'peral':
            return 110.0;
          // Durazno: P pesa en raíz/establecimiento/floración pero rara vez es
          // protagonista en árbol adulto. Doc 05 §5/§17 fija cap P=95.
          case 'peach_tree':
          case 'crop_peach_tree':
          case 'peach':
          case 'peachtree':
          case 'durazno':
          case 'duraznero':
          case 'melocoton':
          case 'melocotón':
          case 'melocotonero':
            return 95.0;
          // Nogal: P pesa en raíz/establecimiento/floración pero rara vez domina
          // en árbol adulto; en suelo calizo el problema suele ser disponibilidad
          // por pH, no falta total. Doc 05 §0.2/§5 fija cap P=95.
          case 'walnut_tree':
          case 'crop_walnut_tree':
          case 'walnut':
          case 'walnuttree':
          case 'nogal':
          case 'pecan':
          case 'nuez':
            return 95.0;
          // Pistache: P no es protagonista adulto; deficiencias son menos
          // comunes y su disponibilidad depende de pH/caliza. Doc 05 §0.12/§5
          // fija cap P=95 (P moderado, no inflado).
          case 'pistachio_tree':
          case 'crop_pistachio_tree':
          case 'pistache':
          case 'pistacho':
          case 'pistachio':
          case 'pistachero':
            return 95.0;
          // Naranjo: P pesa en raíz/establecimiento/floración, pero en árbol
          // adulto no domina el ciclo; en suelo calizo el problema suele ser
          // disponibilidad por pH, no falta total. Doc 05 §0.3 fija cap P=95.
          case 'orange_tree':
          case 'crop_orange_tree':
          case 'orange':
          case 'naranjo':
          case 'naranja':
            return 95.0;
          // Limón: P pesa en raíz/establecimiento/floración, pero en árbol
          // adulto no domina; en suelo calizo el problema suele ser
          // disponibilidad por pH. Doc 05 §0.0.1/§2 fija cap P=95.
          case 'lemon_tree':
          case 'crop_lemon_tree':
          case 'lime_tree':
          case 'crop_lime_tree':
          case 'lemon':
          case 'lime':
          case 'limon':
          case 'limón':
          case 'limonero':
          case 'lima':
            return 95.0;
          // Mango: P pesa en raíz/establecimiento/energía e inducción/floración,
          // pero en árbol adulto no domina (menor que N/K/Ca en extracción); en
          // suelo calizo el problema suele ser disponibilidad por pH. Doc 05
          // §0.0.2/§2 fija cap P=95 (coherente con los demás árboles).
          case 'mango_tree':
          case 'crop_mango_tree':
          case 'crop_mango':
          case 'mango':
          case 'mangos':
          case 'mangifera':
          case 'mangifera_indica':
          case 'arbol_mango':
          case 'árbol_mango':
            return 95.0;
          // Aguacate: P pesa en raíz/establecimiento/energía y prefloración/
          // floración, pero en árbol adulto NO domina; en suelo calizo el
          // problema suele ser disponibilidad por pH. Doc 05 §0.2/§2 fija cap
          // P=95 (coherente con los demás árboles).
          case 'avocado_tree':
          case 'crop_avocado_tree':
          case 'crop_avocado':
          case 'avocado':
          case 'avocados':
          case 'aguacate':
          case 'aguacates':
          case 'palta':
          case 'palto':
          case 'persea':
          case 'persea_americana':
          case 'arbol_aguacate':
          case 'árbol_aguacate':
          case 'arbol de aguacate':
          case 'árbol de aguacate':
            return 95.0;
          // Cactus: demanda baja de P (raíz, espinas). Cap 55 mg/kg.
          case 'cactus':
          case 'crop_cactus':
          case 'cacto':
          case 'cactos':
            return 55.0;
          // Suculenta: demanda baja-moderada de P (raíz y arraigo). Cap 60 mg/kg
          // (Doc B §5). La sonda económica tiene baja confianza en P: pesos
          // bajos y nunca una dosis.
          case 'succulent':
          case 'crop_succulent':
          case 'suculenta':
          case 'suculentas':
            return 60.0;
          // Sábila / Aloe: cap P=65 (cactus 55 · suculenta 60 · sábila 65).
          // Demanda moderada; la sonda económica tiene baja confianza en P, así
          // que pesos bajos y nunca una dosis (Doc B §4.7, §5).
          case 'aloe':
          case 'crop_aloe':
          case 'sabila':
          case 'sábila':
          case 'zabila':
          case 'zábila':
            return 65.0;
          // Maguey / Agave: cap P=55 (cactus 55 · suculenta 60 · sábila 65 ·
          // maguey 55). Demanda moderada; la sonda económica tiene baja
          // confianza en P, así que pesos bajos y nunca una dosis (Doc B §4.7,
          // §5).
          case 'agave':
          case 'crop_agave':
          case 'maguey':
            return 55.0;
          // Nopal: cap P=60 (cactus 55 - suculenta 60 - sabila 65 - maguey 55 -
          // nopal 60). Demanda moderada; el P acompana raiz y crecimiento pero
          // NUNCA domina el score, y la sonda economica tiene baja confianza en
          // P (Doc B section 10.4, 12). NO es dosis.
          case 'nopal':
          case 'crop_nopal':
          case 'nopales':
          case 'opuntia':
          case 'orn_nopal':
          case 'prickly pear':
          case 'cactus pear':
            return 60.0;
          // Rosal: cap P=90 (Doc B §0). Demanda de P en raíz y botón mayor que
          // las ornamentales xerófitas. El cap normaliza el gauge, NO es dosis.
          case 'rose':
          case 'crop_rose':
          case 'rosal':
            return 90.0;
          // Tulipán: cap P=80 (Documento B §9.6). El P importa en enraizado y
          // recarga, pero la sonda económica tiene baja confianza en P: cap
          // moderado y nunca una dosis.
          case 'tulip':
          case 'crop_tulip':
          case 'tulipan':
          case 'tulipán':
            return 80.0;
          // Girasol: cap P=90 (Documento B §0.3, §11). Prioridad temprana, pero
          // respuesta regional variable y riesgo de acumulación en maceta. El
          // cap normaliza el gauge, NO es una dosis.
          case 'sunflower':
          case 'crop_sunflower':
          case 'girasol':
            return 90.0;
          // Cempasúchil: cap P=75 (Documento B §0, §10.4, §10.5). Deliberadamente
          // bajo para que el fósforo NO se lea como un "flor booster" capaz de
          // corregir fotoperiodo, calor, sequía o exceso de N. El cap normaliza
          // el gauge, NO es una dosis.
          case 'marigold':
          case 'crop_marigold':
          case 'cempasuchil':
          case 'cempasúchil':
          case 'cempoalxochitl':
          case 'cempoalxóchitl':
          case 'flor de muerto':
          case 'orn_cempasuchil':
          case 'tagetes erecta':
            return 75.0;
          default:
            return 80.0;
        }
      case AgroMetricKey.k:
        switch (normalizedCropKey) {
          // Tomate tolera y responde a K muy alto (Brix, firmeza, color).
          // Lecturas de 200+ mg/kg son productivas, no tóxicas.
          case 'tomato':
          case 'tomate':
          case 'jitomate':
            return 200.0;
          case 'cucumber':
          case 'pepino':
            return 210.0;
          case 'chili':
          case 'chile':
          case 'pepper':
          case 'pimiento':
            return 220.0;
          case 'eggplant':
          case 'berenjena':
          case 'aubergine':
            return 220.0;
          // Calabaza demanda K alto desde cuajado hasta llenado/cosecha;
          // 220 mg/kg como cap operativo evita clasificar como exceso una
          // lectura productiva. Pipian/pepita comparte cap.
          case 'squash':
          case 'calabaza':
          case 'pumpkin':
            return 220.0;
          // Lechuga: K apoya turgencia y calidad de cabeza/hoja; cap
          // operativo de 180 mg/kg cubre la demanda sin marcar exceso.
          case 'lettuce':
          case 'lechuga':
            return 180.0;
          case 'spinach':
          case 'crop_spinach':
          case 'espinaca':
            return 190.0;
          // Cebolla: K es el nutriente del bulbo (agua, turgencia, calibre,
          // firmeza y calidad). Cap operativo de 200 mg/kg cubre la demanda
          // de llenado sin marcar como exceso una lectura productiva.
          case 'onion':
          case 'crop_onion':
          case 'cebolla':
            return 200.0;
          // Ajo: K pesa en diferenciacion, llenado, firmeza y calidad de bulbo.
          case 'garlic':
          case 'crop_garlic':
          case 'ajo':
            return 210.0;
          // Manzano: K sube tarde (cuajado/llenado/cosecha). El optimo de suelo
          // del doc 05 llega a 70-90 mg/kg en llenado. Cap 140 deja ese pico en
          // ~0.5-0.65 del gauge con cabecera para "alto util"/"exceso" arriba.
          case 'apple_tree':
          case 'crop_apple_tree':
          case 'manzano':
            return 140.0;
          // Pera: K es protagonista de fruto (calibre/llenado). Doc 05 fija el
          // óptimo relativo de K en llenado en 0.70-0.90; cap 140 lo deja en
          // ~98-126 mg/kg con cabecera para alto útil/exceso por encima.
          case 'pear_tree':
          case 'crop_pear_tree':
          case 'pera':
          case 'peral':
            return 140.0;
          // Durazno: K es el protagonista del fruto de hueso (calibre, turgencia,
          // firmeza, azúcares, calidad). Alta sensibilidad a deficiencia de K.
          // Doc 05 §5/§17 fija cap K=180 (más alto que pepita).
          case 'peach_tree':
          case 'crop_peach_tree':
          case 'peach':
          case 'peachtree':
          case 'durazno':
          case 'duraznero':
          case 'melocoton':
          case 'melocotón':
          case 'melocotonero':
            return 180.0;
          // Nogal: K es protagonista del crecimiento de nuez y el llenado de
          // almendra (calibre, % almendra, calidad, tolerancia a estrés). Doc 05
          // §0.2/§5 fija cap K=180 (alto, como durazno).
          case 'walnut_tree':
          case 'crop_walnut_tree':
          case 'walnut':
          case 'walnuttree':
          case 'nogal':
          case 'pecan':
          case 'nuez':
            return 180.0;
          // Pistache: K es el protagonista (kernel, llenado, split/open,
          // calidad, agua y alternancia). Estudios UC reportan alta demanda y
          // respuesta a K. Doc 05 §0.12/§5 fija cap K=220 (mas alto del paquete
          // de arboles) para no penalizar lecturas funcionales en fruit_fill.
          case 'pistachio_tree':
          case 'crop_pistachio_tree':
          case 'pistache':
          case 'pistacho':
          case 'pistachio':
          case 'pistachero':
            return 220.0;
          // Naranjo: K es protagonista del fruto cítrico (calibre, jugo,
          // calidad, agua, madurez). El K se concentra fuerte en la fruta
          // (relación de extracción N:P2O5:K2O ≈ 2:1:4). Doc 05 §0.3 fija cap
          // K=200: alto (como tomate/cebolla), pero menor que pistache.
          case 'orange_tree':
          case 'crop_orange_tree':
          case 'orange':
          case 'naranjo':
          case 'naranja':
            return 200.0;
          // Limón: K es protagonista del fruto cítrico (amarre, calibre, jugo,
          // calidad, agua, madurez) y la producción continua/remoción por
          // cosecha justifican cap mayor que naranjo. Doc 05 §0.0.1/§2 fija cap
          // K=210 (más alto que naranjo, sin llegar a pistache).
          case 'lemon_tree':
          case 'crop_lemon_tree':
          case 'lime_tree':
          case 'crop_lime_tree':
          case 'lemon':
          case 'lime':
          case 'limon':
          case 'limón':
          case 'limonero':
          case 'lima':
            return 210.0;
          // Mango: K es protagonista de cuajado, llenado, tamaño, sabor, color y
          // calidad. Doc 05 §0.0.2/§2 fija cap K=190: alto (más que durazno/nogal
          // 180), pero menor que cítricos porque el mango NO tiene corte continuo;
          // evita marcar como exceso lecturas funcionales de fruit_fill.
          case 'mango_tree':
          case 'crop_mango_tree':
          case 'crop_mango':
          case 'mango':
          case 'mangos':
          case 'mangifera':
          case 'mangifera_indica':
          case 'arbol_mango':
          case 'árbol_mango':
            return 190.0;
          // Aguacate: K es protagonista de cuajado, llenado, calibre, materia
          // seca, calidad y balance hídrico; el fruto puede permanecer meses en
          // árbol. Doc 05 §0.2/§2 fija cap K=200 (como naranjo, por debajo de
          // limón 210): NO se sube más porque el aguacate es muy sensible a
          // sales y K puede competir con Ca/Mg. Evita marcar como exceso lecturas
          // funcionales de fruit_fill.
          case 'avocado_tree':
          case 'crop_avocado_tree':
          case 'crop_avocado':
          case 'avocado':
          case 'avocados':
          case 'aguacate':
          case 'aguacates':
          case 'palta':
          case 'palto':
          case 'persea':
          case 'persea_americana':
          case 'arbol_aguacate':
          case 'árbol_aguacate':
          case 'arbol de aguacate':
          case 'árbol de aguacate':
            return 200.0;
          // Cactus: el K es el nutriente que SÍ importa (turgencia, pared
          // celular, espinas, aguante al calor y al frío). Cap 220 mg/kg, más
          // alto que N y P, de modo que el óptimo (65-150) caiga a media escala.
          case 'cactus':
          case 'crop_cactus':
          case 'cacto':
          case 'cactos':
            return 220.0;
          // Suculenta: el K conserva relevancia moderada (regulación del agua y
          // firmeza de la hoja). Cap 240 mg/kg (Doc B §5): mayor que N y P, para
          // que el óptimo (70-150) caiga a media escala. NO es una dosis.
          case 'succulent':
          case 'crop_succulent':
          case 'suculenta':
          case 'suculentas':
            return 240.0;
          // Sábila / Aloe: cap K=270 (cactus 220 · suculenta 240 · sábila 270).
          // El K conserva relevancia por la regulación hídrica y la firmeza de
          // hoja, y por la selectividad K/Na bajo estrés salino (Doc B §4.8,
          // §5). Mayor que N y P; el óptimo (88-180) cae a media escala.
          case 'aloe':
          case 'crop_aloe':
          case 'sabila':
          case 'sábila':
          case 'zabila':
          case 'zábila':
            return 270.0;
          // Maguey / Agave: cap K=280 (cactus 220 · suculenta 240 · sábila 270
          // · maguey 280). El K conserva relevancia por la regulación hídrica y
          // la firmeza de hoja; es el cap más alto del maguey (Doc B §4.8, §5).
          case 'agave':
          case 'crop_agave':
          case 'maguey':
            return 280.0;
          // Nopal: cap K=280 (cactus 220 - suculenta 240 - sabila 270 - maguey
          // 280 - nopal 280). El K conserva el cap mas alto por su papel
          // osmotico y de turgencia y por la alta concentracion observada en
          // cladodios (Doc B section 3.8, 13). NO es dosis.
          case 'nopal':
          case 'crop_nopal':
          case 'nopales':
          case 'opuntia':
          case 'orn_nopal':
          case 'prickly pear':
          case 'cactus pear':
            return 280.0;
          // Rosal: cap K=280 (Doc B §0). El K es el nutriente clave en
          // floración; cap alto. El cap normaliza el gauge, NO es una dosis.
          case 'rose':
          case 'crop_rose':
          case 'rosal':
            return 280.0;
          // Tulipán: cap K=260 (Documento B §9.6). El K es el nutriente clave
          // en tallo, botón, flor y recarga; cap alto para que su óptimo caiga a
          // media escala. El cap normaliza el gauge, NO es una dosis.
          case 'tulip':
          case 'crop_tulip':
          case 'tulipan':
          case 'tulipán':
            return 260.0;
          // Girasol: cap K=300 (Documento B §0.3, §11). Suficiencia ~150 ppm en
          // referencias de suelo y alta absorción antes de floración; cap alto
          // para que su óptimo caiga a media escala. El cap normaliza el gauge,
          // NO es una dosis.
          case 'sunflower':
          case 'crop_sunflower':
          case 'girasol':
            return 300.0;
          // Cempasúchil: cap K=280 (Documento B §0, §10.4, §10.5). El potasio
          // conserva el cap más alto del cultivo porque gana prioridad relativa
          // en porte, botón y floración, pero queda por debajo del Girasol. El
          // cap normaliza el gauge, NO es una dosis.
          case 'marigold':
          case 'crop_marigold':
          case 'cempasuchil':
          case 'cempasúchil':
          case 'cempoalxochitl':
          case 'cempoalxóchitl':
          case 'flor de muerto':
          case 'orn_cempasuchil':
          case 'tagetes erecta':
            return 280.0;
          default:
            return 140.0;
        }
      default:
        return 100.0;
    }
  }
}
