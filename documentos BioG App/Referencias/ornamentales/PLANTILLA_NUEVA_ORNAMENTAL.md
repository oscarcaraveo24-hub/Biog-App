# Plantilla — Documentos para una ornamental nueva

**Léela junto con** `GUIA_ORNAMENTALES_BIOG.md` (el contrato).
**Aplica a:** modo `establishment_maintenance` (suculenta, sábila, maguey, nopal, helecho, palma).

---

## 0. Antes que nada: ¿los 5 documentos del cactus valieron chorizo?

**No. Pero uno sí.** Los medimos contra el código que realmente sobrevivió:

| Documento | Líneas | Qué produjo | Aprovechado |
|---|---|---|---|
| **01** Ficha universal + perfiles | 1,015 | `cactus_catalog.dart` + etapas y ventanas | **85 %** |
| **02** Perfil SKIP | 634 | `ca_skip` + etiqueta + migración | **70 %** |
| **03** Estado ornamental + microciclo | **2,128** | **nada** | **5 %** ❌ |
| **04** Riesgos y sanidad | 2,352 | `cactus_syndromes.dart` (635 líneas) | **90 %** ✅ |
| **05** NPK y targets | 1,704 | `cactus_universal_profile.dart` (582 líneas) | **50 %** |
| | **7,833** | | **~56 %** |

**Conclusiones que importan:**

1. **El doc 04 (sanidad) fue el más productivo de todos.** 90 % aprovechado. Ese formato
   funciona: conservarlo tal cual.
2. **El doc 03 fue el gran desperdicio.** Era el segundo más grande (2,128 líneas, 27 % del
   papel) y **no dejó una sola línea de código**. Especificaba el microciclo hídrico, que
   exigía una infraestructura que BIO-G no tiene. **Se elimina.**
3. **El doc 05 se usó a medias.** Su agronomía era buena; sus *unidades* eran incompatibles
   con la app (índices comparables en vez de mS/cm y MPa). **Se conserva el contenido, se
   corrige el formato.**
4. **Los docs 01 y 02 se solapaban.** El 02 gastaba 634 líneas para definir un perfil
   "no sé". **Se fusionan.**

**Lo que de verdad falló no fue el número de documentos: fue que faltaba el contrato** (qué
unidades, qué tarjetas, qué claves de alerta). Ese contrato ya existe: es la Guía.

---

## 1. Los documentos que SÍ necesitas: **3, no 5**

| # | Documento | Sale de | Alimenta a |
|---|---|---|---|
| **A** | Identidad y perfiles | fusión de 01 + 02 | `<crop>_catalog.dart`, `<crop>_lifecycle.dart` |
| **B** | Agronomía y targets | 05 corregido | `<crop>_universal_profile.dart`, `NpkCaps` |
| **C** | Riesgos y sanidad | 04 tal cual | `<crop>_syndromes.dart` |

❌ **El antiguo documento 03 (estado ornamental / microciclo) NO se hace.** La etapa
ornamental ya está definida en la Guía §4.3, es la misma para todas las plantas de este
modo, y el microciclo quedó descartado.

### Reglas de formato (esto es lo que falló antes)

1. **Tablas con números, no prosa.** El código necesita rangos; no necesita ensayos.
2. **Unidades reales, siempre:** `%`, `°C`, `pH`, `mS/cm`, `MPa`, `mg/kg`.
   **Si un número no está en estas unidades, no sirve.**
3. **Cada documento termina con una sección "Mapeo a código"** que dice, literalmente, qué
   va en qué archivo `.dart`.
4. **Si algo requiere infraestructura que no existe, va a una sección "Fuera de v1"** —
   nunca en el cuerpo como si fuera implementable. (Ese fue el pecado del doc 03.)
5. Objetivo de tamaño: **300–600 líneas por documento.** No 2,000.

---

## DOCUMENTO A — Identidad y perfiles

```markdown
# <Planta> — Identidad y perfiles

## 1. Alcance
Qué SÍ cubre este perfil: ...
Qué NO cubre (y a dónde va): ...
  ej. cactus: epífitos NO; nopal → crop_nopal; pitahaya NO

## 2. Identidad
cropId:        crop_<planta>
CropKey:       <planta>
categoría:     ornamental
modo de ciclo: establishment_maintenance
prefijo:       XX

## 3. Perfiles
Entre 3 y 5 tipos, por COMPORTAMIENTO (no por catálogo comercial ni por
apariencia). Si dos variedades se cuidan igual, son el mismo perfil.

| id | Etiqueta que ve el usuario | Subtítulo | Contexto (maceta/paisaje) |
|---|---|---|---|
| xx_01_... | ... | ... | maceta |
| xx_02_... | ... | ... | ambos |
| xx_skip   | No sé / <planta> general | Perfil general y migrable | desconocido |

⚠️ `xx_skip` va SIEMPRE AL FINAL de la lista. Nunca muestres "SKIP" ni el id.

## 4. Aliases de entrada
Cómo le dice la gente. Nombres comunes, regionales, comerciales.
| Perfil | Aliases |
|---|---|
| xx_01 | ... |

## 5. Aliases que NO deben mapear aquí
Plantas parecidas que son otra cosa. (Evita que una planta caiga en el perfil
equivocado.)

## 6. Ventanas de la progresión de vida
La progresión es SIEMPRE la misma (Guía §4.3). Solo ajustas los días:

| Etapa | Días | Nota |
|---|---|---|
| Recién plantada | 0 – ?? | ¿este ejemplar establece más lento? |
| Echando raíz | ?? – ?? | |
| Creciendo | ?? – ?? | |
| Estable | > ?? | **para siempre** |

## 7. Mapeo a código
- Perfiles y aliases  → lib/core/crops/<crop>/<crop>_catalog.dart
- Ventanas y etapas   → lib/core/crops/<crop>/<crop>_lifecycle.dart
- Assets              → assets/seeds/<crop>/ (+ declarar en pubspec.yaml)
```

---

## DOCUMENTO B — Agronomía y targets

**Este es el que más cuidado necesita.** Es donde el cactus se descarriló.

```markdown
# <Planta> — Agronomía, targets y pesos

## 1. Perfil agronómico en 5 líneas
- ¿Qué la mata? (exceso de agua / sequía / frío / sales…)
- ¿Qué nutriente manda? (K, N, P…)
- ¿Es de demanda alta o baja?
- ¿Tolera compactación?
- ¿Tiene reposo estacional?

⚠️ NO copies el cactus. Un helecho con targets de cactus se muere de sed.

## 2. StageTargets — EN UNIDADES REALES

### Humedad (%)
| Etapa | lowMax | óptimo | highMin |
|---|---|---|---|
| Recién plantada | | – | |
| Echando raíz | | – | |
| Creciendo | | – | |
| Estable | | – | |
| En reposo | | – | |
| Por confirmar | | – | |

### Temperatura de sustrato (°C)   ← misma tabla
### pH                              ← misma tabla (+ variantes por contexto)
### EC (mS/cm)                      ← misma tabla. NO dS/m de otro método.
### Resistencia (MPa)               ← misma tabla. Rango típico 0.0 – 2.0
### N / P / K (mg/kg)               ← una tabla por nutriente

## 3. Caps NPK
| Nutriente | Cap (mg/kg) | Por qué |
|---|---|---|
| N | | |
| P | | |
| K | | |
→ Van en lib/core/agro/npk_caps.dart

## 4. StageWeights — CADA FILA SUMA 1.00
| Etapa | Humedad | Temp | pH | EC | Resist. | N | P | K | Σ |
|---|---|---|---|---|---|---|---|---|---|
| ... | | | | | | | | | 1.00 |

Regla: el agua domina. El NPK solo pesa de verdad en "Creciendo".

## 5. Castigos del AgroScore
¿Qué condición es la que mata a esta planta? Esa lleva el castigo más fuerte.
| Condición | Factor |
|---|---|
| Humedad crítica por exceso | × 0.?? |
| Humedad crítica por sequía | × 0.?? |
| Frío + húmedo | × 0.?? |
| ... | |

## 6. Textos de cuidado por etapa (lo que lee el agricultor)
| Etapa | Nota de cuidado | Prioridad |
|---|---|---|
| ... | "Riega poco y revisa que drene." | "Prioridad: ..." |

⚠️ Lenguaje de agricultor. Prohibido: baseline, objetivo, comparable, índice,
   microciclo, electroconductividad, no accionable. (Guía §3.7)

## 7. Fuera de v1
Todo lo que requiera infraestructura que no existe. NO lo pongas arriba como si
fuera implementable.

## 8. Mapeo a código
- Targets y pesos → lib/core/crops/<crop>/<crop>_universal_profile.dart
- Caps            → lib/core/agro/npk_caps.dart
- Castigos        → lib/core/crops/<crop>/<crop>_agro_score_engine.dart
```

---

## DOCUMENTO C — Riesgos y sanidad

**Este formato funcionó (90 % aprovechado). Cópialo tal cual del cactus.**

```markdown
# <Planta> — Riesgos, sanidad y estrés

## 1. Contrato de seguridad
BIO-G NO diagnostica patógenos. NO receta plaguicidas ni dosis.
El sensor por sí solo NUNCA genera una alerta sanitaria alta.
Lenguaje: "condición compatible con...", "revisa...", "confirma...".

## 2. Síndromes
Por cada uno:
- id + etiqueta que ve el usuario ("Base o raíz con deterioro por confirmar")
- síntomas observables (lo que el usuario VE y TOCA)
- señales confirmatorias (preguntas de sí/no)
- diagnósticos posibles (en lenguaje de "posible", nunca definitivo)
- severidad + urgencia
- acciones base (qué revisar, no qué comprar)
- disclaimer

## 3. Mapeo a código
- lib/core/plant_health/catalog/<crop>_syndromes.dart
- Alta en PlantHealthRegistry y PlantHealthStageAdapter
```

---

## 2. Prompt de investigación (para quien haga los documentos)

Cópialo tal cual. Sirve para un investigador o para un LLM con búsqueda.

```
Necesito la ficha técnica de <PLANTA> para integrarla a una app de sensores de
suelo (BIO-G). La app mide, con una sonda enterrada:

  humedad (%), temperatura de suelo (°C), pH, EC (mS/cm),
  resistencia a la penetración (MPa) y N-P-K (mg/kg)

Necesito, EN ESAS UNIDADES Y SOLO EN ESAS:

1. Rangos de humedad (%): crítico bajo, óptimo, crítico alto — por cada etapa:
   recién plantada, echando raíz, creciendo, estable, en reposo.
2. Lo mismo para temperatura de sustrato (°C) y pH.
3. Rango de EC en mS/cm. Si la fuente da dS/m por otro método (PourThru, 1:2,
   SME), dilo explícitamente y da la equivalencia.
4. Resistencia/compactación tolerable en MPa (rango típico 0–2).
5. Rangos de suficiencia de N, P y K en mg/kg de suelo. Si la planta es de baja
   demanda, dilo con números.
6. ¿Qué la mata más rápido: el exceso de agua o la sequía?
7. ¿Qué nutriente manda y cuál es peligroso en exceso?
8. Síntomas visibles de sus 5-8 problemas más comunes, con las preguntas que un
   usuario no experto podría responder mirando la planta.
9. Cuánto tarda en: arraigar tras el trasplante, y en considerarse establecida.
10. ¿Tiene reposo estacional? ¿Cuándo?

REGLAS:
- Si un dato no existe con evidencia, dilo. NO inventes un número.
- No me des recetas de fertilizante ni dosis en ml/g.
- Distingue lo medido en LABORATORIO de lo que ve una sonda barata enterrada.
- Cita las fuentes.
```

---

## 3. Checklist antes de empezar a programar

- [ ] Doc A, B y C escritos y coherentes entre sí.
- [ ] **Todos los números están en unidades reales** (%, °C, pH, mS/cm, MPa, mg/kg).
- [ ] Los `StageWeights` de cada etapa **suman 1.00** (súmalos a mano).
- [ ] **Ninguna etapa declarada queda sin forma de llegar a ella.**
      *(Le pasó a `active_growth` del cactus: existía con targets, pesos e imagen, pero la
      progresión saltaba por encima. Etapa muerta durante toda la integración.)*
- [ ] Ningún texto de UI usa la jerga prohibida (Guía §3.7).
- [ ] Nada del documento depende de infraestructura que no existe.
- [ ] Leíste la Guía §5 (la receta de 13 pasos).

---

## 4. La siguiente planta

Según el orden de la Guía §11: **Suculenta** (`crop_succulent`, prefijo `SU`).

Es la que más se parece al cactus — mismo modo, misma familia xerófita — así que **debería
salir casi copiar-pegar**. Pero ojo con la trampa que la propia guía advierte:

> **Compartir esqueleto NO es compartir biología.** La suculenta tiene más masa foliar y
> distinta respuesta hídrica. **Necesita sus propios targets**, no los del cactus.

**Si la suculenta no sale casi copiar-pegar, el problema está en el contrato, no en la
planta.** Avísame y lo arreglamos ahí.
