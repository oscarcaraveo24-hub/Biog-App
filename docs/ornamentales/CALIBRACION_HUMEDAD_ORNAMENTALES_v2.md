# Recalibración de humedad — ornamentales (cactus, suculenta, sábila)

**Fecha:** julio 2026 · **Motivo:** falsa alarma "CRÍTICO" con lecturas normales de humedad (p. ej. 60 %).

## Síntoma reportado

En la app, con Sábila (y también Suculenta y Cactus), una lectura de humedad de **60 % se marcaba CRÍTICO por exceso**. El usuario, que conoce sus plantas y su sensor, considera que 60 % es humedad sana.

## Diagnóstico (no era un bug del motor)

Se reprodujo la clasificación exacta del motor. **El motor sí cambia la lógica por cultivo** — a 40 %, 53 % y 55 % las tres plantas dan bandas distintas. El problema era de **calibración**: el techo de "crítico-húmedo" de las ornamentales estaba muy bajo respecto al resto de la app y respecto a la realidad del sensor.

Techo crítico-húmedo ANTES vs. resto de cultivos (misma escala del sensor 0–100):

| Familia | Techo crítico-húmedo (highMin) |
|---|---|
| Ornamentales (antes) | cactus 42–58 · suculenta 45–60 · **sábila 46–62** |
| Granos (frijol, avena, trigo, cebada) | 78–88 |
| Hortalizas (tomate, pepino, maíz) | 75–90 |
| Árboles frutales | 84–95 |

A 60 % de humedad: para un árbol o un tomate es humedad sana; para el frijol es "alto"; **solo las ornamentales lo marcaban crítico**. Coincidían las tres a 60 % simplemente porque 60 quedaba por encima de sus tres techos (52/55/56), no porque el motor estuviera "pegado".

## Base de la nueva calibración (investigación)

El sensor está calibrado **0 = aire seco, 100 = sumergido en agua**, así que su escala ≈ **contenido volumétrico de agua real (VWC %)**. Con esa base, la evidencia (extensión universitaria, física de suelos, un estudio revisado por pares de *Aloe vera* 2026, guías de calibración de sensores capacitivos):

- **Saturación de suelo mineral** ≈ 40–55 % VWC (tope de porosidad). **Capacidad de campo de una mezcla de maceta (turba/coco)** ≈ 55–80 % VWC. Una mezcla gritty de cactus retiene mucho menos (~25 % VWC).
- **60 en este sensor es humedad sana** ("recién regado / húmedo") en sustrato de maceta, no saturación.
- **La sábila crece MEJOR cerca de capacidad de campo** (estudio 2026: 37 % VWC = mejor crecimiento; 16 % también bien; solo ~8 % la perjudica). Es la menos extrema de las xerófitas: le gusta la humedad, con buen drenaje.
- La **pudrición depende de la DURACIÓN saturada**, no de una sola lectura alta. Marcar un 60 % puntual como "crítico" es incorrecto; debe ser "alto" (aviso) y reservar "crítico" para saturación real o sostenida.

Fuentes clave: METER Group (VWC/capacidad de campo), Oklahoma State / Minnesota Stormwater / Virginia Tech (saturación por textura), Sun Gro / UC ANR (capacidad de contenedor de mezclas), *J. Soil Sci. Plant Nutr.* 2026 (VWC de *Aloe vera*), MDPI Sensors 2025 (calibración de sensores capacitivos).

## Cambio aplicado (solo la banda de humedad; se conservó el lado seco)

Se subió `optimalMax` y `highMin` de humedad en las 6 etapas de las 3 ornamentales, manteniendo el lado seco (tolerancia a sequía intacta) y el orden: cactus (más seca) < suculenta < sábila (más húmeda), y reposo (más seca) < activo (más tolerante).

Etapa **Estable** (humedad %, `lowMax / optimalMin / optimalMax / highMin`):

| Cultivo | Antes | Después | 60 % ahora |
|---|---|---|---|
| Cactus | 4 / 10 / 34 / 52 | 4 / 10 / **54 / 72** | ALTO (aviso) |
| Suculenta | 8 / 14 / 38 / 55 | 8 / 14 / **58 / 76** | ALTO (aviso) |
| Sábila | 10 / 16 / 40 / 56 | 10 / 16 / **64 / 80** | **ÓPTIMO** |

Resultado: 60 % ya no dispara alarma roja. En sábila es óptimo; en cactus/suculenta es "alto" (un empujón de "no riegues / revisa el drenaje"), no crítico. El crítico-húmedo queda reservado para saturación real (~72–84 según planta y etapa), aún por debajo de hortalizas/árboles.

## Recomendación de producto (siguiente paso)

Lo más robusto es **calibración de sustrato de 2 puntos por dispositivo**: registrar la lectura del sensor recién regado-y-drenado (techo real de ese sustrato) y regar de nuevo a ~⅓–½ de ese valor. La app ya tiene el objeto `Calibration` (`moistureDryRaw` / `moistureWetRaw`) y el motor lo usa si está presente; conviene exponerlo en la UI para que cada maceta ajuste su propia escala. Con eso, la humedad deja de depender de supuestos de sustrato.

## Qué NO cambió

Motor de score, claves de alerta canónicas, pesos, EC, temperatura, pH, NPK y sanidad: intactos. Solo se recalibró la banda de humedad de las tres ornamentales, con sus pruebas actualizadas y una prueba de regresión que fija el caso de 60 %.
