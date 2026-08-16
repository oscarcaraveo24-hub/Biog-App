-- ─────────────────────────────────────────────────────────────────────────────
-- BIO-G · Tipo de suelo de la parcela
-- 2026-08-11
-- ─────────────────────────────────────────────────────────────────────────────
--
-- El tipo de suelo pertenece al EQUIPO Y SU PARCELA, no al usuario. Quien tenga
-- tres BIO-G en tres parcelas puede tener tres tierras distintas, y
-- `device_crop_contexts` ya está namespaceada por dispositivo, así que eso sale
-- gratis: no hace falta tabla nueva.
--
-- ── Por qué nullable y SIN valor por defecto ─────────────────────────────────
--
-- Es la decisión importante de esta migración.
--
--   NULL        -> «contexto anterior a esta versión». Nunca se preguntó.
--   'unknown'   -> «el productor lo declaró y dijo que no sabe».
--
-- No son lo mismo y se miden distinto. Un DEFAULT 'unknown' los fundiría en un
-- solo valor y destruiría a la vez la métrica de adopción (¿cuánta gente
-- contesta de verdad?) y el historial auditable (¿con qué información dijimos
-- «riega» aquel martes?).
--
-- ── Por qué el sustrato de maceta NO aparece aquí ────────────────────────────
--
-- Porque jamás se pregunta: se deriva del modelo del equipo o de la escala en
-- tiempo de resolución (`SoilProfileResolver`). Guardarlo en esta columna sería
-- persistir una deducción como si fuera una declaración del productor.
--
-- El almacenamiento local no necesita migración: guarda el objeto completo y
-- añadir el campo al modelo lo persiste solo.

alter table public.device_crop_contexts
  add column if not exists soil_texture_id          text,
  add column if not exists soil_texture_source      text,
  add column if not exists soil_local_descriptors   text[],
  add column if not exists soil_local_other         text;

comment on column public.device_crop_contexts.soil_texture_id is
  'Textura mineral declarada: sandy | sandyLoam | loam | clayLoam | clay | unknown. '
  'NULL = contexto anterior a la captura de suelo. ''unknown'' = el productor dijo que no sabe. '
  'El sustrato de maceta nunca se guarda aquí: se deriva del modelo del equipo o de la escala.';

comment on column public.device_crop_contexts.soil_texture_source is
  'Procedencia del valor: declared | guided_estimate | derived_from_device | derived_from_scale | unknown. '
  'Se guarda aparte del valor para el historial auditable y para medir adopción.';

comment on column public.device_crop_contexts.soil_local_descriptors is
  'Nombres locales con los que el productor conoce su tierra (roja, blanca_caliza, negra, volcanica, otra). '
  'Contexto descriptivo: NO altera la clasificación hidráulica ni un solo número del motor.';

comment on column public.device_crop_contexts.soil_local_other is
  'Texto libre cuando el productor eligió «Otra». Nunca bloquea el avance del wizard.';

-- Guardas de dominio. Se aplican solo a filas nuevas o modificadas: `not valid`
-- deja intactas las que ya existen, que es exactamente lo que se quiere —una
-- fila vieja tiene NULL y eso es legítimo—.
alter table public.device_crop_contexts
  drop constraint if exists device_crop_contexts_soil_texture_id_check;

alter table public.device_crop_contexts
  add constraint device_crop_contexts_soil_texture_id_check
  check (
    soil_texture_id is null
    or soil_texture_id in ('sandy', 'sandyLoam', 'loam', 'clayLoam', 'clay', 'unknown')
  ) not valid;

alter table public.device_crop_contexts
  drop constraint if exists device_crop_contexts_soil_texture_source_check;

alter table public.device_crop_contexts
  add constraint device_crop_contexts_soil_texture_source_check
  check (
    soil_texture_source is null
    or soil_texture_source in (
      'declared',
      'guided_estimate',
      'derived_from_device',
      'derived_from_scale',
      'unknown'
    )
  ) not valid;

-- Adopción: cuántos contextos tienen una respuesta real del productor frente a
-- cuántos siguen sin preguntar. Es la consulta que justifica separar el valor
-- de la fuente.
--
--   select soil_texture_source, count(*)
--     from public.device_crop_contexts
--    group by 1 order by 2 desc;
