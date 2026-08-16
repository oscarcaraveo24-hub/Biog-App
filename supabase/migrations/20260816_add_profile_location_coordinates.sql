-- ─────────────────────────────────────────────────────────────────────────────
-- BIO-G · Coordenadas de la ubicación del perfil
-- 2026-08-16
-- ─────────────────────────────────────────────────────────────────────────────
--
-- `profiles.location` guardaba SOLO la etiqueta legible ("Camino a Satevó s/n,
-- Chihuahua, Chih., México"). Las coordenadas vivían únicamente en
-- SharedPreferences del teléfono, así que una reinstalación —o un login en otro
-- aparato— dejaba al usuario sin ubicación aunque la nube siguiera mostrando el
-- texto. Peor: la etiqueta sobrevivía y las coordenadas no, un estado en el que
-- la app cree saber dónde está la parcela y no puede pedir el clima.
--
-- Con estas columnas la ubicación deja de depender del almacenamiento local.
--
-- ── Por qué nullable y SIN valor por defecto ─────────────────────────────────
--
-- NULL significa «este perfil nunca eligió ubicación», que no es lo mismo que
-- (0,0) ni que una ciudad de respaldo. El resto de la app ya trata (0,0) como
-- marcador de «sin ubicación» (ver `ParcelLocationResolver._build`) y sabe
-- responder honestamente cuando no hay coordenadas. Inventar un default aquí
-- reintroduciría por la puerta de atrás el bug que `parcel_location.dart`
-- existe para cerrar.

alter table public.profiles
  add column if not exists location_lat        double precision,
  add column if not exists location_lng        double precision,
  add column if not exists location_source     text,
  add column if not exists location_updated_at timestamptz;

comment on column public.profiles.location_lat is
  'Latitud de la parcela elegida por el usuario. NULL = nunca eligió ubicación. '
  'Espejo durable de profile_location_lat en SharedPreferences, que sigue siendo '
  'la lectura rápida del teléfono.';

comment on column public.profiles.location_lng is
  'Longitud de la parcela elegida por el usuario. Se escribe siempre junto a '
  'location_lat: una sin la otra no es una ubicación.';

comment on column public.profiles.location_source is
  'De dónde salieron las coordenadas: gps | map | search | onboarding. '
  'Se guarda aparte del valor porque una ubicación arrastrada a mano en el mapa '
  'y una leída del GPS no merecen la misma confianza al auditar una recomendación.';

comment on column public.profiles.location_updated_at is
  'Cuándo se eligió esta ubicación. Permite resolver conflictos entre el teléfono '
  'y la nube por recencia en lugar de por quién escribió último.';

-- Guardas de dominio. `not valid` deja intactas las filas existentes: hoy todas
-- tienen NULL y eso es legítimo.
alter table public.profiles
  drop constraint if exists profiles_location_lat_check;

alter table public.profiles
  add constraint profiles_location_lat_check
  check (location_lat is null or (location_lat >= -90 and location_lat <= 90))
  not valid;

alter table public.profiles
  drop constraint if exists profiles_location_lng_check;

alter table public.profiles
  add constraint profiles_location_lng_check
  check (location_lng is null or (location_lng >= -180 and location_lng <= 180))
  not valid;

alter table public.profiles
  drop constraint if exists profiles_location_source_check;

alter table public.profiles
  add constraint profiles_location_source_check
  check (
    location_source is null
    or location_source in ('gps', 'map', 'search', 'onboarding')
  ) not valid;

-- Una coordenada suelta no es una ubicación: o están las dos o no está ninguna.
-- Sin esta guarda, un upsert parcial podía dejar `location_lat` con valor y
-- `location_lng` en NULL, y el resolvedor descartaría la fila entera sin que
-- nada explicara por qué.
alter table public.profiles
  drop constraint if exists profiles_location_pair_check;

alter table public.profiles
  add constraint profiles_location_pair_check
  check (
    (location_lat is null and location_lng is null)
    or (location_lat is not null and location_lng is not null)
  ) not valid;
