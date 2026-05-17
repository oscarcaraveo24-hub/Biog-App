# RENDIMIENTO APROXIMADO BIO-G — LECHUGA

**Versión:** v2 — Mayo 2026
**Alcance:** Campo abierto e invernadero / casa malla en suelo. **No incluye hidroponía NFT/DWC ni vertical farming** (quedan como nota futura).
**Cultivo madre:** `crop_lettuce`
**Objetivo del documento:** Documento de referencia para los motores de Seeds, Yield Projection y Estimated Harvest. Define rangos conservadores y honestos por tipo de lechuga, sin inflar con techos hidropónicos ni de alta tecnología que no representan el alcance de BIO-G v1.

> **Criterio editorial:** rangos conservadores y útiles para producto, apoyados en ensayos comerciales, manuales técnicos y guías de extensión. Evitar techos máximos de hidroponía NFT, vertical farming o invernadero de ultra alta tecnología.

---

## 1. Alcance y definición

- **Unidad base:** toneladas por hectárea (t/ha) de hoja/cabeza fresca comercializable por ciclo. Para baby leaf, también se reporta como kg/m² por ciclo.
- En lechuga, el rendimiento depende principalmente de tipo, sistema, densidad real, temperatura durante cierre, sanidad foliar y EC. Por eso este documento trabaja con **rangos**, no con un solo número.
- **Lectura BIO-G:** rendimiento aproximado debe leerse como referencia de motor y UX.
  - **Zona baja:** manejo promedio con estrés sostenido.
  - **Zona media:** manejo bueno, ciclo estable.
  - **Zona alta:** manejo bueno-muy bueno dentro del sistema correcto.
- Estos rangos **no sustituyen** fichas varietales oficiales, contratos de industria ni proyecciones financieras.

---

## 2. Variables que más mueven el rendimiento

| Variable | Impacto | Lectura BIO-G |
|---|---|---|
| Sistema de producción | Muy alto | Campo abierto y protegido en suelo no comparten benchmark. |
| Tipo comercial | Muy alto | Romana, iceberg, mantequilla, hoja suelta y baby leaf tienen patrones distintos de peso por planta y densidad. |
| Densidad real | Muy alto | Si la población queda fuera del rango útil, la proyección debe bajar. |
| Temperatura en cierre / madurez | **Muy alto** | Calor sostenido reduce peso, induce tipburn y dispara espigado. |
| Sanidad foliar | Muy alto | Mildiu, Botrytis, Sclerotinia, bacteriosis cortan rendimiento muy rápido en lechuga. |
| EC / salinidad | Alto | Cada dS/m sobre umbral (1.3) ≈ 10–13 % de pérdida. |
| Calidad del agua | Alto | Determina cuánto se puede regar sin acumular sales. |
| Disciplina de cosecha | Medio-alto | Pasarse de la ventana cae rápido la calidad. |
| Sombreo / mulch / mallas | Medio | Útiles en zonas cálidas para extender ventanas. |

---

## 3. Rendimientos base propuestos para BIO-G (rangos conservadores)

**Importante:** los rangos siguientes son una síntesis conservadora para el proyecto. Están pensados para carga de catálogo, Seeds y proyección aproximada. **No están diseñados para copiar techos máximos de hidroponía o vertical farming**, ni para usarse como contratos.

### 3.1 LE-GEN — Lechuga genérica (SKIP)

| Atributo | Valor |
|---|---|
| Sistema | No definido (campo o protegido en suelo) |
| Densidad típica | 70,000–100,000 pl/ha |
| Rango base (t/ha) | 18–35 |
| Confianza | Modelado conservador |
| Lectura BIO-G | Solo para avanzar en UX hasta que el usuario seleccione tipo y sistema. |

### 3.2 LE-01 — Romana / Cos (incluye corazones / mini)

| Atributo | Campo abierto | Protegido en suelo |
|---|---|---|
| Densidad típica (pl/ha) | 60,000–100,000 | 70,000–100,000 |
| Rango base (t/ha) | 20–40 | 30–50 |
| Confianza | Media-alta | Media |
| Lectura BIO-G | Rango comercial razonable de romana; corazones / mini suelen producir menos toneladas pero más valor unitario. |

**Mini romana / Little Gem (alias):** rendimiento por t/ha generalmente menor que la romana grande, pero con densidad mayor y peso menor por planta. La proyección puede ser similar en t/ha si se ajusta densidad.

### 3.3 LE-02 — Bola / Iceberg / Crisphead

| Atributo | Campo abierto |
|---|---|
| Densidad típica (pl/ha) | 50,000–80,000 |
| Rango base (t/ha) | 30–55 |
| Confianza | Media-alta |
| Lectura BIO-G | Iceberg bien manejada en zonas frescas (ej. Salinas, Bajío en invierno) puede llegar al alto del rango. En verano cálido típico baja al rango medio o bajo. |

> Iceberg es el tipo con más historial de producción comercial intensiva y los datos son los más estables de la industria.

### 3.4 LE-03 — Mantequilla / Butterhead (Boston / Bibb)

| Atributo | Campo abierto | Protegido en suelo |
|---|---|---|
| Densidad típica (pl/ha) | 70,000–110,000 | 80,000–110,000 |
| Rango base (t/ha) | 15–28 | 20–35 |
| Confianza | Media | Media |
| Lectura BIO-G | Hoja blanda, peso menor por planta. Su valor está más en calidad y precio premium que en toneladas. |

### 3.5 LE-04 — Orejona / Hoja suelta (looseleaf / oak / lollo)

| Atributo | Campo abierto | Protegido en suelo |
|---|---|---|
| Densidad típica (pl/ha) | 70,000–120,000 | 80,000–120,000 |
| Rango base (t/ha) | 15–28 | 20–32 |
| Confianza | Media | Media |
| Lectura BIO-G | No cabecea. Ciclo corto. Rendimiento moderado en t/ha; se compensa con más ciclos por año. |

### 3.6 LE-05 — Baby leaf / mezclas tiernas

| Atributo | Campo abierto | Protegido en suelo |
|---|---|---|
| Densidad típica (pl/ha) | 1,500,000–3,000,000 | 1,500,000–3,500,000 |
| Rango base (kg/m²/ciclo) | 0.6–1.2 | 0.8–1.6 |
| Rango base (t/ha/ciclo) | 6–12 | 8–16 |
| Ciclos por año típicos | 5–10 según clima | 6–12 según clima |
| Confianza | Media | Media |
| Lectura BIO-G | Cosecha tierna, ciclo muy corto. La cifra realmente útil es t/ha/año, no t/ha/ciclo. |

---

## 4. Tabla resumen — propuesta de catálogo para BIO-G

Compatible con el catálogo existente (`yieldLowTonPerHa`, `yieldHighTonPerHa`, `seedsLowPerHa`, `seedsHighPerHa`, `confidence`, `sourceMethod`).

| ID sugerido | displayName | yieldLow (t/ha) | yieldHigh (t/ha) | plantsLow | plantsHigh | confidence |
|---|---|---|---|---|---|---|
| `lettuce_field_generic` | Lechuga campo abierto (genérica) | 18 | 32 | 70,000 | 100,000 | modeled |
| `lettuce_protected_soil_generic` | Lechuga protegida en suelo (genérica) | 22 | 38 | 70,000 | 100,000 | modeled |
| `lettuce_romaine_field` | Lechuga romana campo abierto | 20 | 40 | 60,000 | 100,000 | calibrated |
| `lettuce_romaine_protected_soil` | Lechuga romana protegida en suelo | 30 | 50 | 70,000 | 100,000 | calibrated |
| `lettuce_iceberg_field` | Lechuga bola / iceberg campo abierto | 30 | 55 | 50,000 | 80,000 | calibrated |
| `lettuce_butterhead_field` | Lechuga mantequilla campo abierto | 15 | 28 | 70,000 | 110,000 | calibrated |
| `lettuce_butterhead_protected_soil` | Lechuga mantequilla protegida en suelo | 20 | 35 | 80,000 | 110,000 | calibrated |
| `lettuce_looseleaf_field` | Lechuga hoja suelta / orejona campo abierto | 15 | 28 | 70,000 | 120,000 | calibrated |
| `lettuce_looseleaf_protected_soil` | Lechuga hoja suelta protegida en suelo | 20 | 32 | 80,000 | 120,000 | calibrated |
| `lettuce_babyleaf_field` | Baby leaf campo abierto (por ciclo) | 6 | 12 | 1,500,000 | 3,000,000 | modeled |
| `lettuce_babyleaf_protected_soil` | Baby leaf protegida en suelo (por ciclo) | 8 | 16 | 1,500,000 | 3,500,000 | modeled |

---

## 5. Interpretación operativa: zona baja / media / alta

Esta es la función que conecta el índice del cultivo (output del Perfil Universal, 0–100) con el rendimiento esperado.

```
zona = case
  when indice_global >= 80 then "alta"
  when indice_global >= 60 then "media"
  when indice_global >= 40 then "baja"
  else "muy_baja"
end
```

| Zona | Multiplicador sobre rango base | Cuándo |
|---|---|---|
| Alta | yieldHigh (techo del rango) | Cultivo estable, sanidad buena, EC controlada, sin eventos de calor relevantes en cierre. |
| Media | (yieldLow + yieldHigh) / 2 | Cultivo con eventos de estrés pero recuperación. |
| Baja | yieldLow (piso del rango) | Cultivo con estrés sostenido en etapas críticas (calor + déficit / EC alta / sanidad activa). |
| Muy baja | 0.6 × yieldLow | Eventos críticos en cierre o problemas sanitarios mayores (Sclerotinia, mildiu severo, espigado generalizado). |

**Fórmula de proyección total del lote:**

```
rendimiento_estimado_t = factor_zona(indice_global) × superficie_ha
```

---

## 6. Ventana de cosecha estimada (estimated_harvest_window)

Para lechuga la ventana de cosecha es **estrecha**: pasarse cuesta calidad, amargor y espigado.

```
ventana_inicio  = fecha_siembra + min_dias_cosecha_perfil + ajuste_estres
ventana_fin     = fecha_siembra + max_dias_cosecha_perfil + ajuste_estres
tolerancia_dias = case
  when zona == "alta"      then ±3
  when zona == "media"     then ±5
  when zona == "baja"      then ±7
  when zona == "muy_baja"  then ±10 (con aviso de calidad comprometida)
end
```

| Perfil | min_dias_cosecha (desde siembra directa) | max_dias_cosecha |
|---|---|---|
| LE-01 Romana | 55 | 80 |
| LE-01 Mini / Corazones | 45 | 70 |
| LE-02 Iceberg | 60 | 95 |
| LE-03 Mantequilla | 45 | 75 |
| LE-04 Hoja suelta | 30 | 60 |
| LE-05 Baby leaf | 25 | 45 |
| LE-GEN | 50 | 80 |

**Ajuste por estrés:**
- Cada día con T_air >28 °C en últimas dos semanas: −0.5 día (acorta ventana).
- Cada día con T_air <8 °C en últimas dos semanas: +0.5 día (alarga ventana).
- Cada evento de anoxia o sanidad activa: −1 día (acorta y compromete calidad).
- Tope máximo de ajuste: ±14 días sobre el rango base.

---

## 7. Notas de criterio (advertencias importantes)

- **No usar como benchmark techos de 80–150+ t/ha asociados a NFT, DWC, vertical farming o invernadero de alta tecnología con luz suplementaria.** Esos sistemas no son alcance de BIO-G v1 y meterlos infla expectativas.
- **En lechuga, la diferencia entre un lote bien manejado y uno con calor + sanidad activa puede desplazar la proyección de zona alta a baja en una sola semana.** El motor debe ser sensible al deterioro reciente.
- **Iceberg en zona cálida típica suele caer al medio del rango**, no al alto. El alto se alcanza en zonas frescas y manejo intensivo.
- **Baby leaf rinde "menos por ciclo, más por año".** La cifra útil para el agricultor es t/ha/año, no t/ha/ciclo aislado.
- **La calidad pesa más que la tonelada en lechuga premium** (mantequilla, corazones, hoja suelta, baby leaf). La proyección de t/ha puede engañar si el motor no integra calidad.
- **No proyectar más allá del fin del ciclo actual.** Lechuga no es progresiva como pepino o tomate; es un corte (o pocos cortes), no una cosecha continua.

---

## 8. Reglas para Dashboard, Crop Care, Notifications, History (rendimiento)

**Dashboard**
- Tile "Cosecha estimada": muestra ventana (fecha inicio – fecha fin) + zona estimada + tonelaje estimado.
- Tooltip con explicación humana: "Su lechuga viene en zona media porque hubo eventos de calor en cierre. Si mejora la temperatura los próximos días puede recuperar."
- Se vuelve visible desde etapa 4 (formación de roseta) en adelante.

**Crop Care**
- Carta de "Próxima revisión de cosecha" 7–10 días antes de la ventana inicial.
- Carta "Su ventana se está acortando" si el ajuste por estrés supera −5 días.
- Carta "Calidad comprometida": cuando zona = muy_baja.

**Notifications**
- Push 5 días antes del inicio de la ventana de cosecha.
- Push si la zona cae de Alta/Media a Baja por evento reciente.
- Push si la ventana se acorta por más de 5 días.

**History**
- Persistir ventana estimada y su evolución a lo largo del ciclo.
- Persistir cosecha real cuando el agricultor la declare (peso, fecha, calidad subjetiva).
- Persistir desviación entre estimado y real (alimenta calibración futura del modelo).

---

## 9. Ejemplos numéricos (para validar el cálculo)

**Ejemplo 1 — LE-01 Romana, campo abierto, superficie 2 ha, índice 85 (zona alta):**
- Rango base: 20–40 t/ha.
- Zona alta → tomar yieldHigh = 40 t/ha.
- Rendimiento estimado lote: 80 t.
- Ventana: 55–80 días desde siembra; tolerancia ±3 días.

**Ejemplo 2 — LE-02 Iceberg, campo abierto, superficie 5 ha, índice 65 (zona media):**
- Rango base: 30–55 t/ha.
- Zona media → (30+55)/2 = 42.5 t/ha.
- Rendimiento estimado lote: 212.5 t.
- Ventana: 60–95 días; tolerancia ±5 días.

**Ejemplo 3 — LE-03 Mantequilla, protegido en suelo, 1 ha, índice 50 (zona baja):**
- Rango base: 20–35 t/ha.
- Zona baja → yieldLow = 20 t/ha.
- Rendimiento estimado: 20 t.
- Ventana: 45–75 días; tolerancia ±7 días.

**Ejemplo 4 — LE-05 Baby leaf, protegido en suelo, 0.5 ha, índice 75 (zona media-alta):**
- Rango base por ciclo: 8–16 t/ha (o 0.8–1.6 kg/m²).
- Zona media-alta → 13 t/ha por ciclo.
- Rendimiento estimado por ciclo: 6.5 t.
- Si la zona permite 8 ciclos/año → ~52 t/año.

---

## 10. Supuestos y datos que requieren validación local

- Los rangos por tipo y por sistema son **síntesis conservadora** de literatura de extensión, manuales técnicos y reportes comerciales típicos. No reflejan techos de hidroponía ni vertical farming. Calibrar con datos del usuario.
- La función zona ↔ multiplicador (alta = yieldHigh, baja = yieldLow) es una primera versión simple. Puede evolucionar a interpolación lineal con `indice_global`.
- Los días de cosecha (mínimo/máximo) son banda referencial. Variedades específicas pueden estar fuera; el ajuste por estrés y el feedback real del agricultor van a calibrar.
- La densidad típica indicada es comercial común; el usuario puede declarar la suya y el motor debe usar la declarada para escalar.
- El tope de ajuste por estrés (±14 días) es prudente; revisar con telemetría.

---

## 11. Tipo de fuentes consultadas

- UC ANR (University of California Agriculture and Natural Resources) — Lettuce production manual.
- USDA NASS estadísticas históricas de rendimiento de lechuga por estado.
- UF/IFAS Florida lettuce production guides.
- Cornell Cooperative Extension — Lettuce production for the Northeast.
- Mid-Atlantic Commercial Vegetable Production Recommendations.
- University of Arizona Yuma — Salinas/Yuma desert lettuce reports.
- INIFAP México — hortalizas en casa malla.
- Manuales comerciales hortícolas universitarios sobre rendimiento de lechuga en distintos sistemas.
- Literatura clásica sobre tolerancia a salinidad de lechuga (Maas-Hoffman) para cálculo de pérdidas por dS/m.
- Datos de baby leaf de literatura europea (referencias italianas y holandesas, ajustadas a sistema en suelo).

> Todos los rangos finales en este documento son síntesis conservadora; ninguno es copia literal de un dato puntual. Los rangos están **deliberadamente por debajo de los techos máximos publicados** para evitar inflar la expectativa del usuario.

---

## 12. Cierre BIO-G — Rendimiento Lechuga

Para lechuga, el rendimiento aproximado debe anclarse a **tipo + sistema + densidad + estabilidad del ciclo + clima en cierre**. El error más común es inflar el potencial con techos hidropónicos o de vertical farming, o subestimar el costo del calor en cierre. Lechuga es cultivo de **ventana corta**: la diferencia entre zona alta y baja se decide en pocos días, y la calidad cae rápido cuando se pasa la ventana.

Con esta tabla cerrada se puede construir el motor de **Yield Projection** y **Estimated Harvest** para lechuga **sin prometer cosas falsas**, alineado al alcance de BIO-G v1 (suelo y protegido en suelo, sin hidroponía como sistema principal).

**Estado:** CERRADO para v2 BIO-G.
