# RIESGOS DEL CULTIVO / SANIDAD VEGETAL BIO-G — LECHUGA

**Versión:** v2 — Mayo 2026
**Alcance:** Campo abierto y protegido en suelo. No incluye hidroponía como sistema principal.
**Cultivo madre:** `crop_lettuce`
**Objetivo del documento:** Catálogo operativo y farmer-friendly de riesgos bióticos, abióticos y fisiológicos de lechuga, priorizado por etapa, sistema y severidad. Cada riesgo trae disparadores, claves visuales, urgencia, acción base segura y mensaje al agricultor. **No es un manual de fitopatología ni un listado de plaguicidas.**

---

## 1. Resumen ejecutivo

En lechuga, los riesgos relevantes se concentran en cinco frentes:

1. **Enfermedades favorecidas por humedad alta, mojado foliar o saturación del suelo:** mildiu velloso (*Bremia lactucae*), Botrytis, Sclerotinia (lettuce drop), Pythium, Rhizoctonia (bottom rot).
2. **Bacteriosis foliares y de tejido:** mancha bacteriana (*Xanthomonas campestris* pv. *vitians*), podredumbre bacteriana (*Pectobacterium*, *Pseudomonas marginalis*).
3. **Complejos virales transmitidos por áfidos y trips:** virus del mosaico de la lechuga (LMV), virus del bronceado del tomate (TSWV), virus de la necrosis del impatiens (INSV); además del *big vein* transmitido por *Olpidium*.
4. **Insectos y moluscos clave:** áfidos (en particular *Nasonovia ribisnigri*, que entra al cogollo), trips (vectores), minadores, babosas y caracoles.
5. **Desórdenes fisiológicos:** tipburn (interno y marginal), espigado (bolting), amargor, internal rib discoloration / pink rib, cabezas que no cierran, daño por frío, estrés osmótico por EC alta.

**La ventana más sensible es etapa 4–5 (formación de roseta y cierre de cabeza), y los 7–10 días previos a cosecha.**

**Para BIO-G, el núcleo duro del catálogo debe priorizar:** mildiu velloso, Botrytis, Sclerotinia, pudriciones radiculares y basales, bacteriosis, complejos virales (áfidos / trips), tipburn, espigado, y amargor.

| Sistema | Riesgos que más pesan | Notas BIO-G |
|---|---|---|
| Campo abierto | Mildiu velloso, Sclerotinia, bacteriosis, antracnosis, complejos virales por áfidos, Pythium tras lluvia, espigado por calor, babosas | Priorizar humedad foliar, lluvia/rocío, historial del lote, malezas y rotación. |
| Protegido en suelo | Botrytis, mildiu si HR alta, TSWV/INSV por trips, áfidos, Pythium/Rhizoctonia por mal drenaje, tipburn en cierre, espigado por calor en verano | Priorizar HR, ventilación, focos en puertas/ventilas, monitoreo con trampas. |

---

## 2. Panorama real del riesgo en lechuga

- Lechuga responde rápido al entorno. Su hoja delgada y su sistema radicular superficial hacen que el deterioro se acelere en pocos días.
- **HR alta + temperatura tibia + mojado foliar → mildiu velloso es el riesgo nº1 en hoja.**
- **Suelo saturado + temperatura 15–22 °C + restos vegetales → Sclerotinia (lettuce drop)** puede destruir un lote a días de la cosecha.
- **Calor + N alto + EC alta + transpiración alterada → tipburn**, el desorden fisiológico más castigador y más fácil de inducir si el manejo es agresivo.
- **Días largos + calor sostenido → espigado prematuro**, sobre todo en variedades sensibles y en verano.
- **Restos de lechuga + maleza hospedera + áfidos → complejo viral** que estropea el lote completo.
- **Monitoreo tardío cuesta más en lechuga que en otros cultivos**, porque la ventana comercial es corta: si el síntoma aparece en cierre, la cosecha ya está comprometida.

---

## 3. Catálogo maestro de riesgos bióticos para BIO-G

La tabla siguiente es operativa: combina frecuencia, severidad, velocidad de daño, facilidad de monitoreo, sistema y etapa. **No reemplaza un manual de fitopatología**; es la lista priorizada que el motor sostiene.

| Riesgo | Código sugerido | Dónde pesa más | Qué lo favorece (disparadores BIO-G) | Clave visual | Etapa principal | Prioridad |
|---|---|---|---|---|---|---|
| Mildiu velloso (*Bremia lactucae*) | `risk_downy_mildew` | Ambos, más en campo y en protegido mal ventilado | HR >90 % >12 h + T 10–17 °C + mojado foliar / rocío | Manchas amarillas en haz, esporulación blanco-gris en envés | 3–6 | **Muy alta** |
| Botrytis (*Botrytis cinerea*) | `risk_botrytis` | Protegido > campo | HR >85 % + tejido senescente/herido + T 15–22 °C + ventilación deficiente | Moho gris en hojas senescentes, en cuello, sobre heridas | 4–6 | Alta |
| Sclerotinia / lettuce drop (*S. sclerotiorum*, *S. minor*) | `risk_sclerotinia` | Ambos, especialmente en suelos con historial | Humedad suelo alta + restos vegetales + T 15–22 °C + monocultivo | Marchitez súbita, base podrida húmeda, micelio blanco algodonoso, esclerocios negros | 4–6 | **Muy alta** |
| Pythium / damping-off | `risk_damping_off` | Ambos | Semilleros húmedos, drenaje pobre, suelo contaminado, T tibia | Colapso de plántulas, cuello ennegrecido | 1–2 | Alta |
| Bottom rot (*Rhizoctonia solani*) | `risk_bottom_rot` | Ambos, suelos pesados | Humedad alta del suelo + contacto hoja-suelo + T 18–24 °C | Lesiones marrones en hojas basales, podredumbre seca | 4–5 | Alta |
| Mancha bacteriana (*Xanthomonas campestris* pv. *vitians*) | `risk_bacterial_leaf_spot` | Campo abierto > protegido | Lluvia, salpique, semilla infectada, mojado foliar | Manchas necróticas marrón-negro, angulares, en haz | 3–5 | Alta |
| Podredumbre bacteriana (*Pectobacterium*, *Pseudomonas marginalis*) | `risk_bacterial_soft_rot` | Ambos | Heridas + humedad + temperatura cálida | Tejido blando, viscoso, mal olor | 5–6 | Alta |
| Antracnosis (*Microdochium panattonianum*) | `risk_anthracnose` | Campo abierto | Lluvia, salpique, restos infectados | Manchas circulares, perforaciones tipo "shothole" | 3–5 | Media |
| Mosaico de la lechuga (LMV) | `risk_lmv` | Ambos | Semilla, áfidos, lotes viejos cerca | Mosaico, deformación, enanismo | Muy temprano | Muy alta |
| TSWV / INSV (tospovirus) | `risk_tospo` | Protegido y zonas cálidas | Trips, maleza hospedera | Anillos cloróticos, necrosis, deformación | Vegetativo–cierre | Alta |
| Big vein (asociado a *Olpidium*) | `risk_big_vein` | Suelos con historial, sobre todo zonas frescas | Suelo contaminado, T fresca, exceso de humedad | Engrosamiento y blanqueamiento de nervaduras | Vegetativo–cierre | Media |
| Áfidos (general + *Nasonovia ribisnigri*) | `risk_aphids` | Ambos | Maleza, lotes continuos, presión regional, brotes tiernos | Colonias en envés y brotes, mielecilla, hojas encrespadas | 3–6 | **Muy alta** (vector viral y daño directo) |
| Trips | `risk_thrips` | Protegido > campo | Baja HR + calor + flores en maleza | Plateado / raspado en hoja, vector TSWV/INSV | 3–6 | Alta |
| Minadores de hoja | `risk_leaf_miners` | Ambos | Presión externa, maleza, monitoreo débil | Galerías serpenteantes, punteo de alimentación | Vegetativo–cierre | Media |
| Babosas y caracoles | `risk_slugs_snails` | Campo, sobre todo húmedo | Humedad alta, restos vegetales, sombra | Bordes irregularmente comidos, rastros mucilaginosos | Establecimiento–cierre | Media |
| Gusano de la hoja (cortadores, plusias) | `risk_caterpillars` | Ambos según zona | Climas cálidos, maleza | Hojas perforadas, excrementos | Vegetativo–cierre | Media |
| Nematodos (formadores y otros) | `risk_nematodes` | Ambos, según historial | Historial del lote, rotación pobre | Bajo vigor, ralentización, raíces deterioradas | Establecimiento–cierre | Media (zona) |

---

## 4. Riesgos abióticos y fisiológicos (deben entrar al motor)

En lechuga **no todo lo que parece enfermedad lo es**. El catálogo debe integrar ambiente, agua, sales y estado fenológico además de sanidad.

| Riesgo | Código | Disparadores BIO-G | Qué se observa | Etapa sensible | Lectura BIO-G |
|---|---|---|---|---|---|
| Tipburn (marginal o interno) | `risk_tipburn` | Calor sostenido + HR baja + transpiración alta + N alto + EC alta en cierre | Necrosis en bordes y/o ápices de hojas internas; en interno se ve solo al cortar | 4–5 | Alerta dura. Combina varios factores: motor debe usar score acumulado. |
| Espigado (bolting) | `risk_bolting` | Calor acumulado (varios días >28–30 °C) + estrés hídrico + fotoperiodo largo + edad fisiológica avanzada | Tallo central elongado, hojas duras, sabor amargo, látex | 4–7 | Alerta acumulativa; afecta ventana de cosecha. |
| Amargor / pérdida de palatabilidad | `risk_bitterness` | Calor + déficit hídrico + sobre-madurez | No se ve sin probar, pero correlaciona con condiciones | 5–7 | Riesgo derivado: si hay calor + déficit + cerca de cosecha, alertar. |
| Cabezas blandas / no cierran (LE-01 / LE-02 / LE-03) | `risk_loose_heads` | Calor en cierre + N alto + variedad sensible | Cabeza poco compacta, peso menor | 5 | Combina manejo + clima. |
| Internal rib discoloration / Pink rib | `risk_internal_rib` | Sobre-madurez + post-cosecha mal manejada + calor previo | Coloración rojiza/marrón en nervadura central | 6–7 | Alerta pre-cosecha. |
| Exceso de humedad / anoxia radicular | `risk_root_anoxia` | Suelo saturado >48 h + temperatura tibia | Marchitez con suelo húmedo, cuello comprometido | 1–6 | Alta prioridad en suelo pesado o tras lluvia. |
| Salinidad (estrés osmótico) | `risk_salinity_stress` | ECe >1.3 dS/m con AW baja | Crecimiento lento, bordes quemados, calidad menor | 3–6 | Alerta gradual según ECe. |
| Daño por frío | `risk_cold_damage` | T <2 °C continuado o helada en trasplante joven | Cese de crecimiento, manchas vidriosas, daño de cogollo | 2–3 | Alerta climática preventiva. |
| Termoinhibición de germinación | `risk_thermo_inhibition` | T suelo >27 °C en siembra | Mala emergencia, plántulas irregulares | 1 | Alerta de planificación de siembra. |
| Edema / russet (post-cosecha relacionado) | `risk_postharvest_edema_russet` | N alto + alta humedad + manejo post-cosecha deficiente | Manchas amarillas o rojizas tras almacenaje | 6 → post-cosecha | Mensaje preventivo en pre-cosecha. |

---

## 5. Priorización por sistema de producción

### Campo abierto (LE-01 romana, LE-02 iceberg, LE-04 hoja suelta, LE-05 baby leaf)

**Muy prioritarios:** mildiu velloso, Sclerotinia (lettuce drop), bacteriosis foliares, antracnosis, complejos virales (LMV + áfidos), Pythium tras lluvia, espigado por calor, babosas, tipburn en cierre con calor.

**Importan mucho:** historial del lote (Sclerotinia y Pythium persisten años en suelo), maleza hospedera, drenaje del lote, calidad del agua de riego, rotación.

### Protegido en suelo (LE-01 romana, LE-03 mantequilla, LE-04 hoja suelta, LE-05 baby leaf)

**Muy prioritarios:** Botrytis, mildiu velloso si HR alta, Pythium / Rhizoctonia por drenaje deficiente, TSWV/INSV por trips, áfidos (incluido *Nasonovia*), tipburn en cierre con calor + HR mal manejada, espigado en verano.

**Importan mucho:** ventilación, manejo de HR (es la palanca principal), focos en puertas y ventilas, trampas amarillas y azules, revisión frecuente del cuello y de la base de la planta.

---

## 6. Monitoreo: protocolo mínimo confiable

En lechuga, **detección temprana es lo que más vale**. La ventana de cosecha es corta y un foco visto un día tarde compromete el lote entero.

- **Frecuencia mínima:** 2 veces por semana en campo abierto. **3 veces por semana** en protegido o con presión sanitaria alta.
- **Qué revisar siempre:** envés de hojas, hojas basales en contacto con el suelo, cuello de planta, brotes tiernos, presencia de mielecilla o telarañas finas, formación de la cabeza.
- **Dónde revisar:** no solo el centro del lote. Incluir bordes, esquinas, puertas, ventilas, zonas húmedas, zonas calientes, zonas con maleza cercana.
- **En protegido:** instalar trampas amarillas (áfidos, mosca blanca) y azules (trips). Referencia común: 1 trampa por cada 90–100 m² (~1 por 1,000 ft²), colocada sobre el dosel o cerca de accesos.
- **Disciplina de diagnóstico:** Antes de decidir acción, responder tres preguntas:
  1. ¿El problema es biótico, abiótico o nutricional?
  2. ¿Está en focos o distribuido homogéneamente?
  3. ¿Apareció primero en hojas viejas, nuevas, cuello, base o cogollo?
- **Confirmación en laboratorio:** ante mosaicos, big vein, podredumbres dudosas, marchiteces vasculares o muerte radicular sin causa clara.

---

## 7. Mensajes humanos por riesgo (catálogo cerrado para app)

| Código mensaje | Texto al agricultor |
|---|---|
| `msg_downy_mildew_risk` | "Humedad alta y temperatura fresca: hay condiciones para mildiu en lechuga. Revise envés de hojas, especialmente las externas." |
| `msg_botrytis_risk` | "Humedad alta sostenida y poca ventilación: riesgo de moho gris. Considere ventilar y retirar tejido dañado." |
| `msg_sclerotinia_risk` | "El suelo está húmedo de manera sostenida: hay riesgo de pudrición por Sclerotinia. Revise plantas con marchitez súbita y base comprometida." |
| `msg_damping_off_risk` | "Hay condiciones para muerte de plántulas en establecimiento. Vigile humedad y drenaje del semillero." |
| `msg_bacterial_spot_risk` | "Llueve o hubo riego por aspersión: posible mancha bacteriana. Evite riego foliar y revise lesiones angulares." |
| `msg_aphid_risk` | "Detectamos condiciones favorables para áfidos. Revise brotes tiernos y cogollo." |
| `msg_thrips_risk` | "Condiciones favorables para trips. Revise hojas con plateado y use trampas azules." |
| `msg_tipburn_risk` | "Calor + N alto + EC alta = riesgo de tipburn. Considere pausar aplicaciones de N y estabilizar riego." |
| `msg_bolting_risk` | "Calor acumulado: la lechuga puede espigar. Considere adelantar la revisión de cosecha." |
| `msg_root_anoxia_risk` | "Suelo saturado por más de 48 horas: riesgo de pudrición en raíz. Revise drenaje." |
| `msg_cold_damage_risk` | "Pronóstico de frío fuerte: si la lechuga está en trasplante reciente, considere cobertura o riego previo." |
| `msg_salinity_rising` | "Salinidad subiendo en cultivo sensible. Considere lavar y revisar calidad del agua." |
| `msg_thermo_inhibition_risk` | "El suelo está muy caliente para sembrar lechuga. Considere posponer o sembrar más temprano." |

**Patrón común:** describir condición + sugerir revisar + sugerir acción base segura. Nunca nombrar producto químico, nunca prescribir dosis.

---

## 8. Reglas de scoring para el motor (por riesgo)

Cada riesgo tiene un `risk_score` 0–1 que combina:

```
risk_score = clip(
    w_predisponentes * f(condiciones_ambientales)
  + w_etapa          * f(etapa_actual)
  + w_historial      * f(eventos_previos)
  + w_observado      * f(reporte_usuario)
, 0, 1)
```

**Pesos sugeridos:**
- `w_predisponentes`: 0.45
- `w_etapa`: 0.20
- `w_historial`: 0.20
- `w_observado` (síntomas reportados por el usuario): 0.15

**Mapeo a estado de alerta:**

| risk_score | Estado |
|---|---|
| 0.0–0.3 | OK |
| 0.3–0.6 | Observación |
| 0.6–0.8 | Alerta |
| 0.8–1.0 | Alerta crítica |

---

## 9. Disparadores numéricos por riesgo (ejemplos clave para código)

| Riesgo | Disparador BIO-G v1 |
|---|---|
| `risk_downy_mildew` | HR > 90 % durante > 12 h consecutivas + T_air entre 10 y 17 °C + ventana cerrada (24 h) sin secado de dosel → score 0.7. Si además mojado foliar persistente → 0.85. |
| `risk_botrytis` | HR > 85 % durante > 12 h + T_air 15–22 °C + tejido senescente/herido visible (input usuario) → score 0.7. |
| `risk_sclerotinia` | Humedad de suelo > 90 % AW durante > 48 h + T_air 15–22 °C + historial del lote positivo → score 0.8. |
| `risk_damping_off` | AW > 90 % + T_soil 20–28 °C + etapa 1–2 → 0.7. |
| `risk_bottom_rot` | AW > 90 % + T_air 18–24 °C + etapa 4–5 + contacto hoja-suelo → 0.65. |
| `risk_bacterial_leaf_spot` | Lluvia >5 mm/día o riego por aspersión + T 18–28 °C + mojado foliar prolongado → 0.6. |
| `risk_aphids` | T_air 15–25 °C + maleza cercana + brotes tiernos visibles + etapa 3–6 → 0.6. Si confirmado por usuario, sube a 0.85. |
| `risk_thrips` | T_air > 22 °C + HR < 60 % + protegido + etapa 3–6 → 0.55. |
| `risk_tipburn` | (T_air > 25 °C en buffer 3 días) + (N_priority alto en cierre) + (ECe > 1.8 dS/m) + etapa 4–5 → 0.8. |
| `risk_bolting` | Suma de días con T_air > 28 °C en últimos 10 días ≥ 4 + etapa ≥ 4 → 0.7. Si ≥ 6 días, sube a 0.9. |
| `risk_root_anoxia` | AW > 95 % durante > 48 h → 0.7. Si > 72 h → 0.9. |
| `risk_cold_damage` | T_air < 2 °C esperada en próximas 24 h y etapa 2–3 → 0.7. |
| `risk_salinity_stress` | ECe > 2.0 dS/m → 0.6. > 2.5 → 0.85. |
| `risk_thermo_inhibition` | T_soil > 27 °C en momento de siembra programada → 0.6. > 30 °C → 0.85. |

> Los pesos y umbrales son una primera versión conservadora. Pueden calibrarse con telemetría real.

---

## 10. Acciones base seguras por riesgo (catálogo)

Estas acciones no son recetas químicas; son intervenciones agronómicas estructurales que cualquier productor puede aplicar.

| Riesgo | Acción base segura |
|---|---|
| Mildiu velloso | Mejorar ventilación, evitar riego foliar nocturno, retirar tejido afectado, separar lotes con presión alta del resto del invernadero. |
| Botrytis | Ventilar, retirar tejido senescente, evitar exceso de N en cierre, no regar de noche. |
| Sclerotinia | Drenaje, rotación de 3+ años con no-hospedantes (cereales, maíz), evitar suelos saturados sostenidos, retirar restos del lote anterior. |
| Damping-off | Mejorar drenaje del semillero, riego controlado, plántulas sanas, sustrato bien aireado. |
| Bottom rot | Cama elevada, evitar contacto hoja-suelo, drenaje, plástico mulch. |
| Bacteriosis | Semilla certificada, evitar trabajar con hojas mojadas, evitar aspersión, rotación. |
| Áfidos | Trampas amarillas, control de maleza, monitoreo del envés y del cogollo, conservar enemigos naturales. |
| Trips | Trampas azules, control de maleza, mallas anti-insectos en aberturas (protegido). |
| Tipburn | Estabilizar riego, reducir N en cierre, ventilar (protegido), evitar EC alta, sombrear si hay olas de calor extremas. |
| Espigado | Programar siembras evitando ventanas cálidas, elegir variedades tolerantes para temporada cálida, adelantar cosecha si hay calor. |
| Anoxia radicular | Mejorar drenaje, suspender riego hasta normalizar, surcos elevados. |
| Daño por frío | Riego pre-helada en suelo, cobertores, mallas térmicas. |
| Salinidad | Lavado controlado, mejorar calidad del agua, fraccionar riego. |
| Termoinhibición | Sembrar más temprano, profundizar siembra ligeramente, sombrear semillero, usar variedades menos sensibles. |

---

## 11. Cooldowns y manejo de notificaciones

Para evitar spam en Notifications, cada riesgo tiene un cooldown propio.

| Riesgo | Cooldown sugerido | Lógica |
|---|---|---|
| Mildiu / Botrytis / Sclerotinia | 24 h por evento; reabre si las condiciones persisten 48 h después | Sanitarias dinámicas |
| Tipburn / Espigado | 48 h | Acumulativas |
| Anoxia radicular | 12 h | Cambian rápido tras drenaje |
| Daño por frío | 6 h durante ventana de pronóstico | Preventiva inmediata |
| Salinidad | 72 h | Lento de mover |
| Termoinhibición | Una sola alerta antes de siembra | Planeación |
| Áfidos / Trips | 48 h por foco confirmado | Activo |
| Damping-off | 24 h | Establecimiento crítico |

**Regla:** una alerta crítica (score ≥0.8) siempre rompe el cooldown y vuelve a notificar; las de Observación/Alerta respetan el cooldown.

---

## 12. Reglas para Dashboard, Crop Care, Notifications, History

**Dashboard**
- Tile sanidad muestra el riesgo activo más alto (nombre simple + score categórico).
- Si hay >1 riesgo Alerta, mostrar contador "+N más".
- Banner si hay riesgo crítico (score ≥0.8).

**Crop Care**
- Una carta por riesgo activo, ordenadas por severidad.
- Cada carta tiene: nombre del riesgo, mensaje al agricultor (catálogo §7), acción base segura (catálogo §10), botón "Marcar resuelto".
- Si el usuario marca resuelto y los disparadores siguen activos, el motor mantiene el riesgo en seguimiento y vuelve a alertar tras 24 h si persisten condiciones.

**Notifications**
- Push obligatorio para Alerta crítica.
- Push opcional configurable para Alerta y Observación.
- Cooldown según §11.

**History**
- Persistir cada vez que un riesgo cambia de estado (OK → Observación → Alerta → Crítica → Resuelto).
- Persistir cuándo el usuario marca resuelto.
- Persistir notas y fotos asociadas al evento.

---

## 13. Riesgos que SÍ deben quedar dados de alta en BIO-G (recomendación operativa)

Catálogo mínimo recomendado para alimentar el motor:

1. `risk_downy_mildew`
2. `risk_botrytis`
3. `risk_sclerotinia`
4. `risk_damping_off`
5. `risk_bottom_rot`
6. `risk_bacterial_leaf_spot`
7. `risk_bacterial_soft_rot`
8. `risk_anthracnose`
9. `risk_lmv`
10. `risk_tospo` (TSWV/INSV)
11. `risk_big_vein`
12. `risk_aphids`
13. `risk_thrips`
14. `risk_leaf_miners`
15. `risk_slugs_snails`
16. `risk_caterpillars`
17. `risk_nematodes` (condicional por zona)
18. `risk_tipburn`
19. `risk_bolting`
20. `risk_bitterness` (derivado, baja prioridad de notificación)
21. `risk_loose_heads`
22. `risk_internal_rib`
23. `risk_root_anoxia`
24. `risk_salinity_stress`
25. `risk_cold_damage`
26. `risk_thermo_inhibition`

---

## 14. Salidas en lenguaje humano (UX farmer-friendly)

BIO-G no debe mostrar nombres de patógenos como única capa al agricultor. Cada riesgo debe tener su capa humana:

- `risk_downy_mildew` → "Riesgo de mildiu por humedad alta"
- `risk_sclerotinia` → "Riesgo de pudrición de base / lettuce drop"
- `risk_aphids` → "Foco de chupadores en cogollo"
- `risk_tipburn` → "Riesgo de quemado de bordes (tipburn) por calor y nitrógeno alto"
- `risk_bolting` → "Riesgo de espigado por calor acumulado"
- `risk_root_anoxia` → "Riesgo radicular por exceso de humedad"
- `risk_thermo_inhibition` → "El suelo está muy caliente para sembrar lechuga"

---

## 15. Supuestos y datos que requieren validación local

- Los umbrales de HR y de temperatura para mildiu y Botrytis están en bandas conservadoras de literatura clásica. Pueden afinarse en zonas tropicales donde el comportamiento del patógeno difiere.
- El catálogo de riesgos zonales (cortadores, nematodos, perforadores) depende de la región. Algunos solo aplicarán en ciertas zonas de operación.
- Los cooldowns son una primera versión; deben calibrarse con telemetría real para evitar fatiga de alerta.
- La lista de variedades sensibles a espigado en LE-01 a LE-05 debe validarse contra el portafolio comercial real del usuario.

---

## 16. Tipo de fuentes consultadas

- UC IPM (University of California, Pest Management Guidelines for Lettuce).
- Cornell Cooperative Extension — Lettuce production guides.
- UF/IFAS — Florida lettuce production.
- USDA / ARS literature on *Bremia lactucae* y manejo IPM.
- Universidad de Arizona / Yuma Center of Excellence for Desert Agriculture (tipburn y desórdenes fisiológicos).
- INIFAP (México) — manuales de hortalizas de hoja en casa malla.
- Literatura clásica sobre tolerancia a salinidad en lechuga (Maas-Hoffman).
- Manuales técnicos hortícolas universitarios y de extensión sobre Sclerotinia, Botrytis, Pythium y mancha bacteriana en cucurbitáceas y asteráceas, adaptados al cultivo de lechuga.

---

## 17. Cierre BIO-G — Riesgos Lechuga

Lechuga **sí merece un módulo de riesgos completo**, porque la sanidad, los desórdenes fisiológicos y el ambiente cambian al cultivo muy rápido. La ventana comercial es corta y el costo de llegar tarde es alto. La investigación coincide en que las enfermedades de humedad, los chupadores con sus complejos virales, las pudriciones radiculares/basales, el tipburn y el espigado son el centro del riesgo. En protegido manda HR y ventilación; en campo abierto mandan lluvia, salpique, maleza, drenaje y continuidad de cultivo.

Con esta tabla cerrada se puede construir el catálogo BIO-G de Lechuga **fuerte, útil y escalable**, sin meter hidroponía ni complejidad química innecesaria. El catálogo es **farmer-friendly por diseño**, las acciones son seguras, los mensajes son humanos.

**Estado:** CERRADO para v2 BIO-G.
