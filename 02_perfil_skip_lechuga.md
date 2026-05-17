# PERFIL GENÉRICO / SKIP BIO-G — LECHUGA

**Identificador interno sugerido:** `LE-GEN` / `lettuce.generic`
**Versión:** v2 — Mayo 2026
**Estado:** OBLIGATORIO · CONSERVADOR · UNIVERSAL
**Cultivo madre:** `crop_lettuce`
**Objetivo del documento:** Definir el comportamiento conservador y migrable que activa BIO-G cuando el usuario no conoce el tipo de lechuga, no encuentra su variedad, tiene información incompleta o quiere arrancar rápido. Garantiza que el cultivo "nunca se rompa" en UX y que las alertas sean confiables aunque no haya tipo seleccionado.

---

## 1. Cuándo se activa LE-GEN

Se activa cuando el usuario:
- No sabe si su lechuga es romana, bola/iceberg, mantequilla, orejona o baby leaf.
- No conoce la variedad.
- No encuentra su semilla en el catálogo.
- Quiere avanzar rápido (primera carga del cultivo).
- Tiene información incompleta del lote.

> El usuario NO ve "SKIP" como etiqueta. En UX aparece simplemente como **"Lechuga genérica"**.

---

## 2. Filosofía del perfil

LE-GEN **no busca máximo rendimiento ni longitud de ciclo perfecta**. Busca:

- Estabilidad del cultivo.
- Protección de la formación de roseta y de la calidad de hoja.
- Alertas confiables y conservadoras.
- Mínima probabilidad de error.
- Migración limpia a un perfil específico cuando el usuario decida.

**Decisión de diseño:** LE-GEN prioriza **etapas 4 (formación de roseta) y 5 (cierre/expansión comercial)** porque son las que más castigan la calidad. Las ventanas críticas siempre están activas en SKIP, sin importar el tipo.

---

## 3. Identidad base — UX

| Campo | Valor |
|---|---|
| Cultivo | Lechuga |
| Tipo (UX) | Genérica |
| Variedad | No especificada |
| Perfil interno | `lettuce.generic` (oculto al usuario) |
| Especie | *Lactuca sativa* L. |
| Familia | Asteraceae |
| Órgano objetivo | Hoja / roseta (no se asume cabeceo) |
| Tipo de cosecha asumido | 1 corte (planta completa) |
| Sistema asumido | Suelo / protegido en suelo (no se asume hidroponía) |

---

## 4. Parámetros agronómicos base — CONSERVADORES

Estos son los anchors que carga el motor cuando aún no hay tipo definido. Son **promedios conservadores del comportamiento real más común de lechuga**, sin asumir ciclo corto ni largo extremos.

| Parámetro | Valor LE-GEN |
|---|---|
| Inicio de expansión foliar activa | 20–35 días |
| Inicio de formación de roseta | 30–50 días |
| Inicio de madurez comercial | 50–80 días |
| Ventana de cosecha estimada | corta (3–10 días tolerancia) |
| Ciclo total asumido | 60–80 días (intermedio) |
| Tipo de cosecha | 1 corte (planta completa) |
| Densidad típica supuesta | 70,000–100,000 plantas/ha |
| Profundidad de siembra | ≤1 cm |
| Arquitectura asumida | No se asume cabeceo ni roseta erecta específica |

> Estos rangos pueden **desplazarse por estrés acumulado**: calor lo adelanta (deteriora antes), frío lo retrasa. El estrés mueve el calendario, no la biología.

---

## 5. Comportamiento fisiológico asumido — CONSERVADOR

LE-GEN asume sensibilidades **ligeramente más altas** que el Universal, porque sin tipo confirmado no podemos descontar tolerancias específicas (p. ej., la romana tolera algo más de calor que la bola; la butterhead aguanta menos HR que el looseleaf).

| Variable | Sensibilidad asumida |
|---|---|
| Calor (>27 °C sostenido) | **Muy alta** |
| Frío (<2 °C) | Media-Alta |
| Déficit hídrico | Alta |
| Exceso de humedad / anoxia | Alta |
| Salinidad | Media-Alta |
| Compactación | Alta |
| pH fuera de 6.0–6.8 | Media |
| HR alta sostenida | Media-Alta |
| Exceso de N | Media-Alta |
| Déficit de N | Media |

---

## 6. Rangos fisiológicos LE-GEN

> Regla del buffer conservador: LE-GEN aplica un factor **0.9** sobre los umbrales de estrés del Perfil Universal. Es decir, el SKIP **alerta antes** que un perfil específico. Esto evita falsos negativos por desconocer el tipo.

### 6.1 Temperatura ambiente

| Banda | LE-GEN |
|---|---|
| Óptimo general | 15–22 °C |
| Observación | 22–25 °C |
| Alerta térmica | >25 °C sostenido |
| Alerta seria | >28 °C sostenido |
| Crítico (espigado acelerado) | >30 °C o varios días >28 °C |

### 6.2 Humedad del suelo (% AW)

| Banda | LE-GEN |
|---|---|
| Óptimo | 60–95 % |
| Observación | 50–60 % |
| Alerta déficit | <50 % |
| Alerta crítica déficit | <35 % |
| Alerta saturación | >95 % por >24 h |
| Alerta crítica saturación | >95 % por >48 h |

### 6.3 pH del suelo

| Banda | LE-GEN |
|---|---|
| Rango seguro | 5.8–7.0 |
| Observación | 5.5–5.8 o 7.0–7.5 |
| Alerta | <5.5 o >7.5 |

### 6.4 Salinidad (ECe)

| Banda | LE-GEN |
|---|---|
| OK | <1.3 dS/m |
| Observación | 1.3–1.8 dS/m |
| Alerta | 1.8–2.5 dS/m |
| Alerta crítica | >2.5 dS/m |

> SKIP es ligeramente más estricto que el Universal (alerta a partir de 1.8 vs 2.0 dS/m del Universal) por el principio conservador.

### 6.5 Compactación

| Banda | LE-GEN |
|---|---|
| OK | <1.0 MPa |
| Observación | 1.0–1.5 MPa |
| Alerta | ≥1.5 MPa |
| Crítico | ≥2.0 MPa |

### 6.6 NPK — prioridad por etapa (más conservadora)

Igual matriz que Universal (sección 4.8 del documento 1), pero LE-GEN nunca empuja N en etapa 4 si hay calor pronosticado >25 °C en los siguientes 3 días.

---

## 7. Sensibilidad por etapa — LE-GEN (matriz numérica)

Aplica buffer conservador (todas las celdas suben 0.05–0.10 vs Universal en etapas críticas).

| Variable / Etapa | Germ | Estab | Veget | Roseta | Cierre/Madurez |
|---|---|---|---|---|---|
| Déficit hídrico | 0.75 | 0.75 | 0.7 | 0.9 | 0.95 |
| Exceso humedad / anoxia | 0.85 | 0.85 | 0.6 | 0.8 | 0.9 |
| Calor sostenido | 0.9 | 0.6 | 0.7 | 0.9 | **1.0** |
| Frío | 0.5 | 0.7 | 0.5 | 0.5 | 0.5 |
| Salinidad | 0.7 | 0.7 | 0.75 | 0.9 | 0.95 |
| Compactación | 0.85 | 0.85 | 0.6 | 0.6 | 0.5 |
| pH fuera de rango | 0.6 | 0.6 | 0.6 | 0.6 | 0.6 |
| HR alta sostenida | 0.4 | 0.4 | 0.6 | 0.8 | 0.95 |
| Exceso N | 0.1 | 0.3 | 0.4 | 0.7 | 0.9 |
| Déficit N | 0.1 | 0.4 | 0.65 | 0.8 | 0.55 |
| Déficit K | 0.1 | 0.3 | 0.5 | 0.7 | 0.9 |

---

## 8. Ventanas críticas activas LE-GEN

- **Ventana crítica principal:** expansión foliar → madurez comercial.
- **Ventana de cosecha:** corta y sensible a estrés (≤10 días).
- **Ventana de riesgo de espigado:** calor + estrés cerca de madurez.
- **Ventana de riego:** continua, prioridad alta desde establecimiento.
- **Ventana de revisión sanitaria:** 7–10 días antes de cosecha estimada.

---

## 9. Alertas activadas LE-GEN (lenguaje humano)

LE-GEN usa los mismos códigos del Universal, con **prioridad intermedia** (nunca extremos):

| Código | Texto sugerido | Ponderación SKIP |
|---|---|---|
| `alert_heat_stress_critical_stage` | "Su lechuga puede estar entrando en estrés por calor. Revise turnos de riego y proteja del sol en horas pico si puede." | Media-Alta |
| `alert_bolting_risk_accumulated` | "Riesgo de espigado por calor acumulado. La cosecha podría adelantarse y la calidad bajar." | Alta |
| `alert_water_deficit_critical` | "Posible déficit hídrico en etapa crítica de la lechuga. Considere reforzar el riego." | Alta |
| `alert_water_excess_anoxia` | "Suelo muy húmedo de forma sostenida: riesgo de pudrición en raíz y base." | Alta |
| `alert_salinity_rising` | "La salinidad está subiendo y la lechuga es sensible. Revise calidad del agua y EC del suelo." | Media |
| `alert_compaction` | "El suelo parece compactado. La raíz de la lechuga es superficial y puede limitarse." | Media |
| `alert_humid_sanitary_risk` | "Humedad alta de manera sostenida. Revise foco de mildiu, Botrytis o pudrición basal en el lote." | Media |
| `alert_pH_out_of_range` | "El pH del suelo está fuera del rango ideal para lechuga (6.0–6.8). Considere muestreo." | Media |
| `alert_n_excess_in_close` | "Aviso conservador: si está aplicando mucho N cerca del cierre, hay más riesgo de tipburn y hoja blanda." | Media |

> Todas en ponderación intermedia, sin extremos. SKIP nunca eleva una alerta a "crítica" salvo en etapas 4–6 con evidencia clara de estrés combinado.

---

## 10. Comportamiento del sistema (clave para migración)

### 10.1 Migración LE-GEN → tipo específico

Cuando el usuario después selecciona un tipo (LE-01 Romana, LE-02 Iceberg, LE-03 Mantequilla, LE-04 Orejona/Hoja suelta, LE-05 Baby leaf) o ingresa una variedad reconocida:

- **BIO-G no pierde memoria.** Todos los eventos persistidos (estrés, ajuste de calendario, alertas resueltas, índice histórico) se mantienen.
- **BIO-G no reinicia el cultivo.** La fecha de siembra, la etapa actual y el contexto climático persisten.
- **BIO-G solo recalcula:** anchors de duración por etapa (`stage_duration_ranges`), umbrales de sensibilidad por tipo (`sensitivity_overrides`), densidad típica y rendimiento anchor.
- **BIO-G mantiene:** identificador único del cultivo, fecha de siembra, eventos históricos, fotos y notas del agricultor, posición geográfica, calendario.

### 10.2 Qué se preserva (lista cerrada)

| Elemento | ¿Se preserva en migración? |
|---|---|
| `crop_instance_id` | Sí |
| `sowing_date` | Sí |
| `current_stage` | Sí (se recalcula si el rango cambia) |
| Eventos de estrés históricos | Sí |
| Calendario ajustado por estrés | Sí |
| Alertas activas/resueltas | Sí |
| Notas y fotos del agricultor | Sí |
| Posición y datos del lote | Sí |
| `crop_profile_version` aplicada | Cambia (se registra el cambio en History) |

---

## 11. Cuándo usar y cuándo no usar LE-GEN

**Usar LE-GEN:**
- Usuario nuevo o primera carga.
- No sabe el tipo de lechuga.
- No encuentra su semilla.
- Datos incompletos.
- Quiere avanzar rápido y refinar después.

**No usar LE-GEN:**
- Usuario selecciona un tipo (LE-01 a LE-05).
- Usuario elige una variedad reconocida en el catálogo de aliases.
- En esos casos, el motor activa el perfil específico del tipo, no LE-GEN.

---

## 12. Estado del cultivo (output BIO-G en LE-GEN)

- Índice general 0–100.
- Sub-índices: agua, temperatura, suelo, nutrición, sanidad.
- Estado: Óptimo / Observación / Alerta / Alerta crítica.
- Tendencia: Mejorando / Estable / Deteriorando.
- **Regla SKIP:** Las etapas 4 y 5 pesan más en el índice (igual que en Universal). Como el SKIP usa el buffer 0.9, el índice tiende a estar ligeramente más bajo que en un perfil específico bien manejado.

---

## 13. Memoria del cultivo LE-GEN

Misma estructura que Universal (sección 10 doc 1). Persiste:
- Tipo de estrés.
- Severidad y duración.
- Etapa cuando ocurrió.
- Ajuste de calendario aplicado.
- Impacto en índice.
- Estado de resolución.

**La memoria nunca se pierde, ni siquiera al migrar.**

---

## 14. Confiabilidad del dato (en LE-GEN)

- Fuente: sensor / modelo / estimación.
- Confianza: alta / media / baja.
- Última actualización (timestamp).
- En LE-GEN, la confianza máxima del **perfil agronómico** es Media — porque el tipo no está confirmado. La confianza de los **datos de sensor** sigue siendo independiente y puede ser Alta.

---

## 15. Metadatos BIO-G

| Campo | Valor |
|---|---|
| `crop_profile_version` | "lettuce.generic.v2" |
| `last_validated_at` | 2026-05-10 |
| `is_skip_profile` | true |
| `migratable_to` | `[LE-01, LE-02, LE-03, LE-04, LE-05]` |
| `conservative_buffer` | 0.9 |
| `compatible_with_universal_v` | "lettuce.universal.v2" |

---

## 16. Reglas para Dashboard, Crop Care, Notifications, History (LE-GEN)

**Dashboard (LE-GEN)**
- Tile principal igual que Universal, pero con tooltip "Perfil genérico — afina seleccionando tipo".
- Banner suave de recomendación: "Tu lechuga está en perfil genérico. Selecciona el tipo cuando puedas para alertas más finas."
- Sub-tiles igual que Universal.

**Crop Care (LE-GEN)**
- Carta extra: "Refina tu perfil" — sugiere al usuario elegir el tipo de lechuga.
- Las recomendaciones son siempre seguras y conservadoras (revisar riego, revisar sanidad, revisar EC). Nunca dosis específicas.

**Notifications (LE-GEN)**
- Mismo set de códigos que Universal, con cooldown ligeramente más amplio (menos ruido).
- Las alertas críticas se mantienen activas igual que en perfil específico.

**History (LE-GEN)**
- Persiste eventos con `profile_at_time = "lettuce.generic"`.
- Al migrar, History registra el cambio de perfil con timestamp y mantiene todos los eventos anteriores.

---

## 17. Supuestos y datos que requieren validación local

- El buffer conservador 0.9 es una elección de diseño BIO-G. Puede afinarse con telemetría real (si SKIP genera demasiado ruido, subir a 0.92 o 0.95; si genera falsos negativos, bajar a 0.85).
- Las duraciones promedio (60–80 días) son referencia general; en zonas tropicales y veranos cálidos el ciclo se acorta y aparece espigado prematuro; en zonas frescas se alarga.
- La densidad asumida (70,000–100,000 pl/ha) es típica de lechuga de cabeza/roseta; no aplica a baby leaf. Si el usuario indica baby leaf, el motor debe migrar a LE-05 antes de proyectar rendimiento.

---

## 18. Frase de cierre (producto)

> El perfil genérico no adivina, acompaña.

Con LE-GEN:
- La lechuga queda cubierta desde el primer minuto.
- La UX nunca se rompe por falta de información.
- El sistema es tolerante al error.
- BIO-G se siente humano y confiable.
- La migración a un perfil específico es limpia y sin pérdida.

---

## 19. Estado del perfil

- **LE-GEN (SKIP Lechuga):** CERRADO.
- **Obligatorio en BIO-G.**
- **Compatible con los 5 tipos UX** (LE-01 a LE-05).
- **Base segura para migración posterior.**
- **Versión:** lettuce.generic.v2.
