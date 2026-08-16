# BIO-G · Editorial de la pantalla «¿Cómo es tu tierra?» y del motor de humedad

**Fecha:** 13 de agosto de 2026 · **Repositorio:** `C:\Users\oscar\Documents\bio_g`
**Contra:** Plan de cambios en la aplicación v2 (10 ago 2026) y Especificación UX/UI de la pantalla de tipo de tierra

---

## 0 · Veredicto en una línea

**El motor de humedad está bien integrado y la pantalla lo alimenta correctamente.** Recorrí las 2 114 combinaciones de cultivo × etapa × textura y no encontré ni una banda inválida, ni una etapa sin clasificar, ni un estado inalcanzable. Lo que sí hay son **tres trampas latentes** —ninguna activa hoy— que conviene cerrar antes de que llegue el hardware. Van en §5.

---

## 1 · Qué se pudo verificar y qué no

No pude ejecutar `flutter test`: este entorno no alcanza `pub.dev` ni el almacén de SDKs de Google, así que no hay forma de resolver `supabase_flutter` ni de instalar Dart. Para no entregarte una opinión sin números hice dos cosas:

1. **Reimplementé la aritmética del motor en un banco de pruebas independiente**, parseando las tablas del propio código Dart —constantes por textura, políticas por cultivo, ventanas hídricas— en vez de copiarlas a mano. Si el código cambia, el banco cambia con él. Con eso barrí el producto cartesiano completo: **más de 2,1 millones de evaluaciones de estado**.
2. **Escribí la prueba equivalente en Dart** y la dejé en el repo. Es la que tienes que correr en tu máquina para que esto quede firmado por el compilador:

```
flutter test test/core/agro/water/
```

Archivo nuevo: `test/core/agro/water/moisture_engine_matrix_test.dart`.

---

## 2 · Cobertura: ninguna etapa se quedó sin clasificar

Recorrí **los 27 catálogos de etapa que existen en `lib/`** —17 enums `*StageKey` y 10 clases `*StageIds`— y los pasé por `StageWaterWindows.lookup`.

| Concepto | Cifra |
|---|---|
| Catálogos de etapa encontrados | 27 |
| Claves de etapa distintas revisadas | **241** |
| Sin ventana hídrica declarada | **0** |
| Pares cultivo–etapa de la matriz | **302** |
| Texturas evaluadas | 7 (5 minerales + 2 sustratos) |
| Combinaciones | **2 114** |

La prueba de cobertura que ya existía en el repo (`stage_water_window_coverage_test.dart`) es genuinamente completa: nombra los 17 enums y lee por expresión regular los ficheros donde viven las 10 clases de constantes. **Verifiqué que no se le escapa ningún catálogo**, que era mi principal sospecha al abrirla.

Y funciona la parte que motivó ese archivo: `grainFill`, `grain_fill` y `GRAIN_FILL` caen en la misma entrada, así que la dualidad camelCase/snake_case del catálogo ya no puede apagar una clasificación en silencio.

---

## 3 · Las bandas: 2 114 casos, 0 fallos

En cada combinación comprobé cinco invariantes:

| Invariante | Por qué importa | Resultado |
|---|---|---|
| `lowMax ≤ optimalMin ≤ optimalMax ≤ highMin` | Una banda invertida da un diagnóstico al azar | ✅ sin fallos |
| `optimalMax == θcc` exactamente | Si el techo del óptimo deja de ser capacidad de campo, la app pide regar por encima de lo que el suelo retiene | ✅ sin fallos |
| `highMin ≤ θsaturación` | **Era el bug original**: umbral de encharcamiento en 90 % VWC, físicamente inalcanzable en suelo mineral | ✅ sin fallos |
| `lowMax ≥ θpmp` | Por debajo del punto de marchitez no hay banda que pintar | ✅ sin fallos |
| MAD efectivo ∈ [0,20 · 0,85] | Fuera de ahí el riego se vuelve imposible de satisfacer o deja de existir | ✅ sin fallos |

### Los cinco estados

Barrí de 0 a 100 % VWC en pasos de 0,1 en cada una de las 2 114 combinaciones. En **todas**:

- los estados aparecen en **orden monótono** subiendo la humedad —marchitez → toca regar → cómodo → drenando → encharcado— y nunca retroceden;
- **«encharcado» es alcanzable** siempre (la alarma que antes no podía dispararse);
- **«cómodo» es alcanzable** siempre (si no lo fuera, la app diría «riega» para siempre, que era el síntoma del manzano);
- **«drenando» es alcanzable** siempre, que es lo que evita llamar anoxia a un riego normal.

### El caso de control del documento (§7.2)

Una sola lectura de **18 % VWC** con MAD 0,40:

| Textura | θpmp | θcc | Umbral encharc. | Estado |
|---|---|---|---|---|
| Arenosa | 5 | 12 | 34,2 | **Drenando** |
| Ligera | 8 | 18 | 38,7 | **Cómodo** (justo a capacidad de campo) |
| Media | 13 | 28 | 43,2 | **Toca regar** (67 % agotado) |
| Pesada | 19 | 34 | 45,0 | **Bajo punto de marchitez** |
| Muy pesada | 25 | 40 | 47,7 | **Bajo punto de marchitez** |

El mismo número, cinco diagnósticos distintos. Reproduce el documento al dígito.

### El sustrato drenante reproduce el catálogo de cactáceas (§7.6)

Es la comprobación que más me interesaba, porque conectarlo mal invierte el consejo justo en el grupo donde regar de más es lo que mata:

```
cactus · crecimiento activo (MAD 0,80) → 4,0 – 13,6 – 52,0 – 70,2
documento esperado                     → 4,0 – 13,6 – 52,0 – 70,2   ✅
```

Coincide exactamente. Y la sábila **no** cae en el sustrato drenante —está en `tolerant`, no en `xeric`— que es la excepción deliberada de `crop_water_policy.dart` y está bien cableada.

### La lámina sale en banda, nunca cerrada (§7.5)

```
tomate · franco · raíz 40 cm · lectura 18 %
lámina neta = (28 − 18)/100 × 400 mm = 40,0 mm        (doc: 40 mm)   ✅
±3 puntos × 0,40 m × 1000 = ±12 mm = ±30 %
banda = 28 – 52 mm                                     (doc: 28–52)   ✅
```

La incertidumbre es del 30 % **en todos los cultivos**, porque se propaga sobre la profundidad radicular y se divide por la lámina, que depende de la misma profundidad. Por eso `needsBand` es `true` en el catálogo entero y ninguna tarjeta puede sacar una cifra cerrada. Verificado de nogal (raíz 100 cm) a lechuga (25 cm).

---

## 4 · La integración con la pantalla: la cadena está completa

La pregunta de fondo era si el motor sigue huérfano, como en la auditoría anterior. **Ya no lo está.** Estos son los enganches reales:

| Punto | Archivo | Qué hace |
|---|---|---|
| **El centro** | `crop_runtime_resolver.dart:184-206` | Resuelve el perfil de suelo una vez y sobrescribe `moistureRaw` en `targets` |
| Riego | `irrigation_advisor.dart:179` | `depthFor` → lámina en banda |
| Historial | `history_presenter.dart:202` | Reinterpreta bandas pasadas |
| Simulador | `sensor_simulator.dart:367` | Emite contra la banda derivada |
| Cuenta | `soil_texture_account_screen.dart:264` · `account_screen.dart:361` | Lee el perfil resuelto |
| Tendencia | `recommendations_screen.dart:492` | `MoistureTrend` ya tiene consumidor |

**Las 11 asignaciones de `targets` del runtime pasan por `withDerivedMoisture`.** Las revisé una por una, incluidas las cinco que se asignan «en crudo» primero (cactus, rosal, tulipán, el `switch` de definiciones y el ajuste por calendario): todas se reescriben en la línea siguiente. No queda ninguna rama del catálogo comiendo de la escala vieja.

Y el enganche está en el sitio correcto: **una sola vez, en el centro**. Si el motor de riego usara la banda derivada y el anillo del Panel siguiera con la del catálogo, las dos pantallas darían lecturas distintas de la misma humedad. Eso no puede pasar hoy por construcción, no por disciplina.

---

## 5 · Hallazgos — tres trampas latentes

Ninguna causa un fallo hoy. Las tres son del tipo «funciona hasta que alguien la use».

### 5.1 · `MoistureTargetResolver.resolve()` no puede devolver sustrato drenante

```dart
final effectiveTexture = isPotted ? SoilTexture.pottingMix : texture;
```

Con `isPotted: true` siempre sale **turba**, jamás la variante drenante. Un cactus en maceta que entrara por esta puerta recibiría constantes de sustrato de ornamental: θcc 62 en vez de 52, y el punto de riego se le movería de 13,6 a 23,2 % VWC. **Es exactamente la inversión de consejo que §7.6 previene**, sobreviviendo en una segunda puerta.

Hoy no hace daño porque **solo la usan las pruebas** —todo el runtime entra por `resolveForSoilProfile`—, pero es una API pública que compila y parece correcta.

> **Sugerencia:** que `resolve()` delegue en `SoilProfileResolver.resolve()` en vez de decidir la textura por su cuenta, o marcarla `@visibleForTesting`. La jerarquía de medio debe vivir en un solo sitio, que es justo lo que dice la cabecera de `soil_profile_resolver.dart`.

### 5.2 · Quedan 14 rangos de humedad de la escala vieja

`lib/crops/tomato/tomato_universal_profile.dart` (7) y `lib/crops/cucumber/cucumber_universal_profile.dart` (7) traen `moistureRaw` con `optimalMin ≥ 45 % VWC`, valores imposibles en suelo mineral —por encima de la capacidad de campo de cualquier textura de la tabla—.

No hacen daño **porque el runtime los sobrescribe**, y el plan dice explícitamente que no se borran todavía. Pero son munición cargada: el día que alguien lea `definition.resolveTargets(...)` sin pasar por el runtime —cosa que ya hacen `sensor_simulator.dart:356` y `history_presenter.dart:182`, ambos con su `copyWith` correcto justo después— vuelve el manzano pidiendo riego el 95 % del tiempo.

> **Sugerencia:** dejar una nota de una línea encima de cada uno con la fecha en que se retiran, o directamente sustituirlos por el valor derivado en cuanto el prototipo confirme las constantes en campo.

### 5.3 · La etapa `maturitySenescence` del maíz sigue siendo un empate técnico

Está declarada `normal` y el propio código lo documenta como decisión consciente: la etapa mete llenado de grano y senescencia en el mismo cajón, y ninguno de los dos ajustes sería correcto para los tres usos (grano, elote, forraje). `normal` es estrictamente mejor que lo que había —aflojaba un 40 % por contener `maturity`—, pero **la corrección de fondo sigue pendiente**: partir la etapa en `grainFill` + `maturitySenescence` en `maize_engine.dart`.

Lo dejo anotado porque es el único sitio del barrido donde el valor es un compromiso y no una respuesta.

---

## 6 · Cambios de interfaz aplicados

### 6.1 · Los PNG

Tenías razón a medias: cuando los revisé **ya estaban sin fondo** (RGBA, 82 % de píxeles transparentes). El problema no era el fondo, era el **lienzo**: 540 × 675 px con la esfera ocupando el 53 % del ancho y el 43 % del alto.

Con `BoxFit.contain` en una caja cuadrada eso significa que **una caja de 194 px dibujaba una esfera de 84**. Casi dos tercios de la caja —y del presupuesto vertical de la pantalla— eran aire transparente. Por eso se veían chiquitas y por eso la pantalla empujaba tanto.

Los recorté al contenido y los reescalé a 448 × 448:

| | Antes | Ahora |
|---|---|---|
| Esfera en la caja | 43 % del alto | 94 % |
| Esfera en pantalla (390 px) | ~84 px | **~139 px (+65 %)** |
| Altura que ocupa la caja | 252 px | **206 px (−46)** |
| Peso de los 6 assets | 1,26 MB | **776 KB** |

Es la mejor jugada disponible: la esfera se ve un 65 % más grande **ocupando menos pantalla**. Ese metro cuadrado es lo que paga que retención y drenaje quepan sin desplazar.

### 6.2 · Lo demás

| Petición | Qué hice |
|---|---|
| Quitar el aviso «Ahora mismo BIO-G usa una tierra media…» de arriba | Movido al **final** de la pantalla de Cuenta, debajo del selector. Ahora lo primero que ves al entrar es la pregunta, no el párrafo que explica por qué todavía no la has contestado |
| «¿Cómo es tu tierra?» hasta arriba, con retención y drenaje a la vista | El selector es el primer elemento; retención y drenaje entran en el primer pantallazo de un teléfono de 390 px |
| Eliminar «¿La conoces por otro nombre?» | Bloque borrado entero, con sus clases. **Los campos siguen en el modelo y en Supabase**, y lo que ya estuviera guardado se conserva: se retiró la captura, no el dato |
| Los iconos sin recuadro y más grandes | Retención, drenaje y «¿no sabes cuál elegir?» dibujan el glifo **solo**, a 28 px — el mismo tamaño que `OnboardingAssetBadge` rinde en el resto del wizard (44 × 0,476 × 2,6 ≈ 28) |
| Icono de interrogación de assets | `ic_help.png` recortado a su contenido → **`assets/icons/metrics/ic_soil_help.png`** (nuevo). El reloj de arena hablaba del tiempo que cuesta, no de la duda que se resuelve |
| Bolitas de abajo sin texto | Fuera el nombre técnico (8,4 px) y la etiqueta (7,8 px). Nadie lee 8 px en el campo, y repetían lo que el bloque de arriba dice a 24 px. **El nombre sigue íntegro para el lector de pantalla** |
| Menos scroll | −120 px del bloque de nombres locales, −35 px de las etiquetas del mini carrusel, −46 px de la caja del hero, −21 px de los puntos de paginación. **Unos 222 px menos**, más de un cuarto de la pantalla de un teléfono |
| Icono de «Tipo de suelo» en Cuenta | Ahora usa `ic_soil_type.png` a escala **2,45**, que rinde exactamente los mismos ~42 px de glifo que «Configurar cultivo» (la cifra no es 2,6 porque los dos PNG no traen la misma proporción de aire transparente) |

### 6.3 · Y una cosa que no pediste pero era un fallo real

**La pantalla saltaba al deslizar.** «Arenosa» no lleva píldora —nombre técnico y cotidiano son la misma palabra— y su frase cabe en una línea; «Franco-arenosa» lleva píldora y ocupa dos. Con las cajas ajustadas al contenido, cada swipe cambiaba la altura del bloque y **el botón de confirmar se movía bajo el dedo del productor**.

Ahora el bloque de nombre reserva altura fija calculada desde la escala de texto del sistema, y la tarjeta de propiedades reserva un mínimo. Las seis esferas miden exactamente lo mismo, a cualquier tamaño de letra.

---

## 7 · Qué hacer al recibir esto

```bash
flutter analyze
flutter test test/core/agro/water/
flutter run
```

Lo que hay que mirar con el ojo, que es lo que yo no puedo hacer desde aquí:

1. **Deslizar las seis esferas** y confirmar que nada se mueve verticalmente.
2. Que la esfera grande **no se vea pixelada** — el asset ahora se dibuja al doble de tamaño real.
3. Que retención y drenaje **entren sin scroll** en tu teléfono de prueba.
4. Ajustes → Accesibilidad → **tamaño de letra al máximo**: es donde la tarjeta se parte en dos mitades apiladas y donde antes desbordaba.
5. La fila **«Tipo de suelo»** en Cuenta, junto a «Configurar cultivo»: los dos iconos deben verse del mismo tamaño.

---

### Archivos tocados

**Código**
- `lib/screens/onboarding/steps/soil_texture_step.dart`
- `lib/widgets/account/soil_texture_account_screen.dart`
- `lib/widgets/account/wizard/configure_seed_wizard_pages.dart`
- `lib/screens/onboarding/onboarding_wizard_screen.dart`
- `lib/screens/account_screen.dart`
- `lib/screens/account/account_screen_sections.dart`

**Prueba nueva**
- `test/core/agro/water/moisture_engine_matrix_test.dart`

**Assets**
- `assets/soil_textures/soil_texture_{sandy,sandy_loam,loam,clay_loam,clay,unknown}.png` (recortados)
- `assets/icons/metrics/ic_soil_help.png` (nuevo)

**Sin tocar:** el motor de humedad, las políticas hídricas, las ventanas por etapa, los 32 perfiles de cultivo, el modelo de datos y la migración. Esta entrega no cambia una sola constante agronómica.
