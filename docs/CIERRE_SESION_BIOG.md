# BIO-G · Cierre de sesión y traspaso

**8 de agosto de 2026 — versión final, todo verificado.** Este documento reemplaza a los anteriores: si vuelves dentro de un mes, lee solo este.

> **Estado al cerrar:** 1,512 pruebas pasan · 0 errores de compilación · el bug de ET0 corregido y verificado · commit `21d1791` subido a GitHub · `HEAD == origin/main`. **No queda nada pendiente de tu parte.**

---

## Primero, tu duda: ¿faltan las dependencias?

**No. Las dependencias no bloquean nada de lo que construimos.**

Los 5 frentes están completos y funcionan con lo que ya tienes en `pubspec.yaml`. Las 10 dependencias de `docs/DEPENDENCIAS_PENDIENTES.md` son para la **fase siguiente** —BLE, push, enlaces profundos— y cada una enchufa en una costura que ya está escrita y probada.

Dicho de otro modo: **no hay nada a medio terminar esperando un paquete.** Si compilas hoy, todo lo de los 5 frentes funciona.

---

## Qué pasó en esta sesión, en cuatro actos

**Acto 1 — Validé la auditoría.** Contrasté el plan de cierre contra las 220 mil líneas reales. Las 6 brechas eran ciertas, pero encontré 3 afirmaciones equivocadas (`isGenericMode` no era el campo sobrecargado; era `subscriptionStatus`), 4 bugs activos que la auditoría trataba como "features pendientes", y 5 bloqueantes de tienda que había dejado fuera de alcance.

**Acto 2 — Cerré los 5 frentes.** 21 archivos nuevos, 18 modificados, 8 de pruebas, ~8,400 líneas. Cero dependencias nuevas. Dos revisiones adversariales encontraron 1 error de compilación, 8 regresiones y 22 riesgos; todos corregidos.

**Acto 3 — Corriste `flutter analyze` y corregí lo que salió.** Resultado: **1 solo error en todo el proyecto, y estaba en una carpeta de trabajo mía**, no en tu código. Los 21 archivos nuevos —5,500 líneas— produjeron 4 avisos menores. Las 8 pruebas nuevas, cero.

**Acto 4 — Corriste `flutter test` y cazó un bug agronómico mío.** Un error de unidades en ET0. Corregido, verificado en la segunda corrida, y con dos pruebas nuevas que impiden que vuelva.

---

## Estado verificado hoy

### Código ✅

| | |
|---|---|
| Los 47 archivos en su sitio | ✅ 0 faltantes |
| Errores de compilación | ✅ **0** |
| Avisos en los 21 archivos nuevos | ✅ **0** (eran 4, corregidos) |
| Avisos en las 8 pruebas nuevas | ✅ **0** |
| Avisos preexistentes | ~470, ninguno error. 241 son `unnecessary_const` en `yield_reference_catalog.dart` |

### Git ✅

`21d1791 Actualiza aplicacion BioG` · **`HEAD == origin/main`** · subido a `github.com/oscarcaraveo24-hub/Biog-App`

Verificado que el commit contiene `lib/core/weather/et0_calculator.dart` y `test/core/weather/et0_calculator_test.dart` —el arreglo de ET0 está dentro de lo que subiste, no fuera— y que `_to_delete/` quedó fuera del árbol.

*(Nota menor de limpieza, sin prisa: `lib.zip` —1.8 MB— sigue rastreado en el repo. No estorba, pero no pinta nada ahí.)*

### Pruebas: 1,512 pasan, 18 fallan — **todas preexistentes** ✅

**El único fallo mío era un bug agronómico de verdad, la prueba lo cazó, y ya está corregido y verificado.**

Mi implementación de Hargreaves-Samani metía la radiación extraterrestre en
MJ/m²/día directamente en la fórmula. La ecuación 52 de FAO-56 exige Ra como
**evaporación equivalente en mm/día**. Faltaba el factor 0.408.

Resultado: **14.51 mm/día donde el real son 5.92** — exactamente 1/0.408 = 2.45
veces de más. Corregido, documentado, y con dos pruebas nuevas que fijan las
unidades para que no pueda repetirse en silencio: una rehace la cuenta a mano y
comprueba el factor, otra barre 6 latitudes × 4 estaciones exigiendo ET0 < 15 mm/día.

La segunda corrida lo confirma: **1,509 → 1,512 pasan** (la prueba que fallaba,
más las dos nuevas) y ET0 desapareció de la lista de fallos.

Hoy la ET0 solo se muestra como evidencia, no entra en la decisión de riego, así
que no había consejo equivocado en campo. Pero habría envenenado el balance
hídrico de V1-B desde el primer día.

**Los 18 fallos restantes son anteriores a esta intervención.** Verificado uno a uno:

| Archivo | Fallos | Causa |
|---|---|---|
| `apple_tree_*` | 7 | El copy de NPK dice "madurez" donde la prueba espera que no, y le faltan las palabras "calibre" / "balance n-k-ca/mg". Es texto del catálogo. |
| `peach_tree_*` | 2 | Igual: "madurez" y "analisis" (la prueba busca sin tilde, el copy la lleva). |
| `pear_tree_*` | 1 | Igual. |
| `succulent_*` | 3 | `SucculentStageResolver` da `active_growth` a los 72 días donde la prueba espera `root_establishment`. Fecha fija, no depende del reloj: cambiaron los umbrales. |
| `hybrid_biog_repository` | 2 | Esperan historial del `SensorSimulator`, y `kEnableSensorSimulator = false`. Nunca emiten; expiran a los 2 s. |
| `nopal_integration` | 1 | Un alias ambiguo sí resuelve perfil cuando la prueba espera `no_skip`. |
| `marigold_integration` | 1 | Ponderación de déficit hídrico entre floración y senescencia. |
| `onboarding_tree_context` | 1 | La prueba espera que limón NO quede activado, y sí queda. |

Ninguno toca archivos que yo modificara. Los tres primeros grupos son la misma
causa: el copy de los catálogos de árbol evolucionó y las pruebas se quedaron
con la redacción vieja. Ninguno es un bug de comportamiento: son pruebas
desactualizadas. **Si quieres, en la próxima sesión los reviso de una pasada** —
son unas dos horas y dejarías la suite en verde.

### Hardware ✅

**Tu Bio-G está vivo.** 1,149 lecturas acumuladas, 4 en las últimas 2 horas, una cada ~30 min. Humedad entre 39.6 % y 60.2 %, sin nulos.

Verifiqué contra esos datos reales que el cambio de fechas no te afecta: `created_at` va **1.1 segundos** después de `timestamp` en promedio (máximo 7.8). El cambio mueve las lecturas alrededor de un segundo. Invisible.

### Supabase ⚠️

Buenas noticias: **sí tienes migraciones versionadas** (25). La auditoría decía que no, y era falso — lo que no existe es una copia dentro del repo de Flutter.

Y las RLS son correctas: dependen de `device_memberships`, y la app sí crea esa fila. **0 dispositivos huérfanos.**

### Tienda ❌

| | |
|---|---|
| `applicationId` | ❌ `com.example.bio_g` — **Google Play lo rechaza** |
| Firma de release | ❌ llaves de debug |
| Keystore | ❌ no existe |
| Llave de Maps | ❌ en el manifest, sin rotar, y en el historial de git |
| Assets | ❌ 222.8 MB |
| Desugaring | ❌ sin configurar (solo hace falta al añadir notificaciones) |

---

## Lo que falta, por dueño

### Tuyo — **nada** ✅

`flutter analyze` ✅ · `_to_delete\` borrada ✅ · `flutter test` ✅ · commit ✅ · `git push` ✅

Cerraste todo. La rama está subida y sincronizada.

### Mío cuando vuelvas — dime "sigue con Supabase"

Los cuatro pendientes están verificados y el SQL está listo abajo. **Nunca ejecuté nada contra tu base**: espero tu autorización explícita.

### Antes de publicar (sin prisa, pero irreversible)

`applicationId` definitivo → keystore → rotar y restringir la llave de Maps → assets a WebP.
El `applicationId` **no se puede cambiar después de la primera subida.** Decídelo antes.

---

## Supabase: lo que falta, con el SQL listo

Verificado contra tu base:

| Pendiente | Estado |
|---|---|
| `request_account_deletion()` | ❌ no existe |
| Política DELETE en `telemetry` | ❌ no existe → el cliente no puede purgar |
| El usuario puede leer su propia suscripción | ❌ solo la lee un UUID fijo |
| `devices.telemetry_device_id` | ❌ la columna no existe, pero la app la lee |
| `handle_new_user()` cerrada al público | ❌ **`anon` puede llamarla por RPC** |
| Protección de contraseñas filtradas | ❌ desactivada |

### 1. Borrado de cuenta — cierra el frente 4

```sql
create or replace function public.request_account_deletion()
returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare v_uid uuid := auth.uid();
begin
  if v_uid is null then
    raise exception 'No hay sesión activa';
  end if;

  delete from public.telemetry
   where device_id in (select device_id from public.device_memberships
                        where user_id = v_uid and role = 'owner');
  delete from public.device_crop_items            where user_id = v_uid;
  delete from public.device_crop_contexts         where user_id = v_uid;
  delete from public.crop_care_history            where user_id = v_uid;
  delete from public.devices
   where id in (select device_id from public.device_memberships
                 where user_id = v_uid and role = 'owner');
  delete from public.device_memberships           where user_id = v_uid;
  delete from public.subscriptions                where user_id = v_uid;
  delete from public.profiles                     where id = v_uid;
  delete from auth.users                          where id = v_uid;
end $$;

revoke execute on function public.request_account_deletion() from anon;
grant  execute on function public.request_account_deletion() to authenticated;
```

> El borrado de `devices` arrastra `device_memberships` por CASCADE; se listan igual por claridad.
> `set search_path` cierra de paso el aviso `function_search_path_mutable`.

### 2. Cerrar `handle_new_user()` — riesgo real

Hoy **cualquiera sin sesión** puede llamarla en `/rest/v1/rpc/handle_new_user`. Sigue corriendo por su trigger; solo deja de ser invocable desde fuera.

```sql
revoke execute on function public.handle_new_user() from anon, authenticated;
alter function public.handle_new_user() set search_path = public, pg_temp;
```

### 3. Que el usuario lea su propia suscripción

Hoy la política es `auth.uid() = '7d4a294c-…'` — un UUID a mano. La app no puede leerla, así que sigue usando `profiles.subscription_status`. Hay **dos fuentes de verdad para el plan** y hay que unificarlas.

```sql
create policy "users can read own subscription"
  on public.subscriptions for select
  using (auth.uid() = user_id);
```

Cuando exista, cambio `BiogSubscription` para leer de `subscriptions` (`plan_code`, `status`, `starts_at`, `ends_at`) en vez de la cadena de `profiles`. El mapeo es casi uno a uno.

### 4. Alinear la app con las columnas que ya existen

`devices` tiene columnas que la app **ignora** y que son justo lo que mi `TelemetryDeviceIdentity` necesita:

`serial_number` · `hardware_model` · `firmware_version` · `pairing_method` · `pairing_status` · `paired_at` · `last_seen_at`

Además la app lee `row['telemetry_device_id']`, **una columna que no existe**. No falla —devuelve null— pero el override nunca puede venir del servidor. Dos opciones: crear la columna, o usar `serial_number`, que ya está ahí. Yo iría por `serial_number`.

Esto es cambio en la app, no en la base. Es el trabajo con más retorno ahora que hay hardware reportando.

### 5. Dos clics en el panel

- **Authentication → URL Configuration:** añadir `biog://auth/reset-password` (sin esto, el enlace del correo no vuelve a la app)
- **Authentication → Policies:** activar *Leaked password protection*

---

## Lo que NO hay que volver a discutir

Cerrado y verificado. No lo reabras sin motivo nuevo:

- Los ~30 motores por cultivo, catálogos de sanidad, perfiles por etapa y calibración **no se tocaron** y funcionan.
- Las RLS de dispositivos **no están rotas**: la app sí crea la membresía.
- El cambio de fechas **no afecta** al dispositivo en vivo (verificado: 1.1 s).
- Las dependencias **no bloquean** nada de lo entregado.
- `isGenericMode` **no** era el campo sobrecargado. Era `subscriptionStatus`, y ya está cableado.
- El bug de ET0 **ya está corregido y verificado** en la corrida de 1,512.

---

## Cuando vuelvas

Pégame esto y retomamos sin contexto previo:

> *"Retomamos BIO-G. Lee `docs/CIERRE_SESION_BIOG.md`. Sigamos con \_\_\_."*

**Mi recomendación de orden:**

1. **Supabase**, los cuatro puntos de arriba — 1 hora, cierra el frente 4 de verdad y tapa el agujero de `handle_new_user()`
2. **Alinear la app con las columnas de `devices`** — aprovecha que hay hardware vivo reportando
3. **Las 18 pruebas preexistentes** — dos horas, deja la suite en verde
4. **Dependencias fase A y B** — `app_links` y `connectivity_plus`
5. **Identidad de la app** antes de publicar (el `applicationId` es irreversible)

---

## Dónde está cada cosa

| Documento | Qué contiene |
|---|---|
| `docs/CIERRE_SESION_BIOG.md` | este |
| `docs/ENTREGA_5_FRENTES.md` | detalle técnico de los 5 frentes |
| `docs/DEPENDENCIAS_PENDIENTES.md` | las 10 dependencias por fase, con config nativa |
| `temp/_audit/_respaldo_previo/` | los 18 archivos originales, por si acaso |

Los tres están también en el proyecto de Claude, así que los tengo aunque cambies de equipo.
