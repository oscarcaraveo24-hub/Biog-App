-- ─────────────────────────────────────────────────────────────────────────────
-- BIO-G · Ventanas nutricionales y épocas de instalación
-- 2026-09-06 · Guía oficial del nuevo motor nutricional v0.4 (fases 5, 7 y 8)
-- ─────────────────────────────────────────────────────────────────────────────
--
-- ESTADO: ARCHIVO PROPUESTO, NO APLICADO. La app hoy persiste estas dos tablas
-- SOLO en local (sqflite, `biog_nutrition.db`). Esta migración es el espejo en
-- la nube para cuando se decida sincronizar; no se aplica sin OK explícito.
--
-- ── Qué guarda ──────────────────────────────────────────────────────────────
--
-- `nutrition_windows`: el libro de ventanas nutricionales por temporada y
-- equipo. Una fila por ventana (etapa × nutrientes) con su resultado:
--   open              -> abierta, sin evidencia todavía (no pesa nada)
--   attendedDetected  -> el sensor vio una respuesta compatible con fertilización
--   unattended        -> cerró observable y sin evidencia (puede pesar si es crítica)
--   inconclusive      -> cerró con cobertura insuficiente o firma dudosa (no pesa)
--   notComparable     -> cerró sin poder observarse: aprendizaje, sin CE, seco (no pesa)
--
-- NADIE registra fertilizaciones a mano. El agricultor no captura nada: la
-- ventana se resuelve con lo que el sensor observa (CE normalizada por
-- humedad, N/P/K nativos, VWC, historial del sitio). Por eso NO existe una
-- tabla de «aplicaciones» y no debe crearse.
--
-- `installation_epochs`: cada instalación o reubicación del equipo abre una
-- época. Las baselines y las firmas no se comparan entre épocas distintas y los
-- primeros 7 días de cada época son de aprendizaje (`notComparable`).
--
-- ── Por qué payload jsonb + columnas indexadas ───────────────────────────────
--
-- El registro completo (`NutritionWindowRecord.toJson`) viaja en `payload` para
-- que el modelo evolucione sin migraciones; las columnas sueltas son solo las
-- que se consultan o agregan (temporada, etapa, resultado, fechas, crítica).
-- La app es la única que escribe `payload`; la nube no lo reinterpreta.

create table if not exists public.nutrition_windows (
  user_id       uuid        not null references auth.users (id) on delete cascade,
  device_id     uuid        not null references public.devices (id) on delete cascade,
  window_id     text        not null,
  season_key    text        not null,
  epoch_id      text,
  crop_key      text        not null,
  stage_key     text        not null,
  nutrients     text[]      not null default '{}',
  is_critical   boolean     not null default false,
  outcome       text        not null default 'open',
  opened_at     timestamptz not null,
  closed_at     timestamptz,
  resolved_at   timestamptz,
  observability text,
  observed_fraction double precision,
  signature_confidence double precision,
  payload       jsonb       not null,
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now(),
  primary key (user_id, device_id, window_id)
);

comment on table public.nutrition_windows is
  'Libro de ventanas nutricionales por temporada y equipo (Guía v0.4). Resultado '
  'decidido por el sensor: open | attendedDetected | unattended | inconclusive | notComparable. '
  'Sin registro manual de fertilización: no existe ni debe existir tabla de aplicaciones.';

comment on column public.nutrition_windows.window_id is
  'Identidad estable de la ventana: <season_key>|<stage_key>|<nutrientes ordenados>. '
  'Misma identidad = misma fila (upsert).';

comment on column public.nutrition_windows.season_key is
  'Anuales: <device>|<crop>|<fecha de siembra>. Perennes: <device>|<crop>|ciclo-<año>.';

comment on column public.nutrition_windows.is_critical is
  'Ventana agronómicamente importante según la guía o el perfil. Solo una ventana '
  'crítica con outcome = unattended pesa en el factor de temporada (×0.94, piso 0.85).';

comment on column public.nutrition_windows.observability is
  'Cómo se observó al cerrar: ok | noReadings | noEcChannel | tooDry | insufficientBaseline.';

comment on column public.nutrition_windows.signature_confidence is
  'Confianza 0..1 de la mejor firma compatible con fertilización detectada (NULL si ninguna).';

comment on column public.nutrition_windows.payload is
  'NutritionWindowRecord.toJson() completo. La app es la única que lo escribe.';

alter table public.nutrition_windows
  drop constraint if exists nutrition_windows_outcome_check;

alter table public.nutrition_windows
  add constraint nutrition_windows_outcome_check
  check (
    outcome in ('open', 'attendedDetected', 'unattended', 'inconclusive', 'notComparable')
  );

alter table public.nutrition_windows
  drop constraint if exists nutrition_windows_observability_check;

alter table public.nutrition_windows
  add constraint nutrition_windows_observability_check
  check (
    observability is null
    or observability in ('ok', 'noReadings', 'noEcChannel', 'tooDry', 'insufficientBaseline')
  );

create index if not exists nutrition_windows_season_idx
  on public.nutrition_windows (user_id, device_id, season_key, opened_at);

create index if not exists nutrition_windows_outcome_idx
  on public.nutrition_windows (device_id, outcome)
  where outcome <> 'open';

create table if not exists public.installation_epochs (
  user_id     uuid        not null references auth.users (id) on delete cascade,
  device_id   uuid        not null references public.devices (id) on delete cascade,
  epoch_id    text        not null,
  started_at  timestamptz not null,
  reason      text,
  payload     jsonb       not null,
  created_at  timestamptz not null default now(),
  primary key (user_id, device_id, epoch_id)
);

comment on table public.installation_epochs is
  'Épocas de instalación/reubicación del equipo (Guía v0.4, fase 7). Cada época '
  'reinicia baselines y abre 7 días de aprendizaje; las firmas no se comparan entre épocas.';

comment on column public.installation_epochs.reason is
  'Instalación inicial | Reubicación | otro motivo declarado por la app.';

create index if not exists installation_epochs_device_idx
  on public.installation_epochs (user_id, device_id, started_at desc);

-- ── updated_at ───────────────────────────────────────────────────────────────

create or replace function public.set_nutrition_windows_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at := now();
  return new;
end;
$$;

drop trigger if exists nutrition_windows_set_updated_at on public.nutrition_windows;

create trigger nutrition_windows_set_updated_at
  before update on public.nutrition_windows
  for each row execute function public.set_nutrition_windows_updated_at();

-- ── RLS: mismo patrón que device_yield_projection_configs ───────────────────
-- Dueño de la fila (user_id = auth.uid()) Y miembro del equipo.

alter table public.nutrition_windows enable row level security;
alter table public.installation_epochs enable row level security;

drop policy if exists "users can view own nutrition windows" on public.nutrition_windows;
create policy "users can view own nutrition windows"
  on public.nutrition_windows for select to authenticated
  using (
    auth.uid() = user_id
    and exists (
      select 1 from public.device_memberships dm
      where dm.device_id = nutrition_windows.device_id and dm.user_id = auth.uid()
    )
  );

drop policy if exists "users can insert own nutrition windows" on public.nutrition_windows;
create policy "users can insert own nutrition windows"
  on public.nutrition_windows for insert to authenticated
  with check (
    auth.uid() = user_id
    and exists (
      select 1 from public.device_memberships dm
      where dm.device_id = nutrition_windows.device_id and dm.user_id = auth.uid()
    )
  );

drop policy if exists "users can update own nutrition windows" on public.nutrition_windows;
create policy "users can update own nutrition windows"
  on public.nutrition_windows for update to authenticated
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

drop policy if exists "users can delete own nutrition windows" on public.nutrition_windows;
create policy "users can delete own nutrition windows"
  on public.nutrition_windows for delete to authenticated
  using (auth.uid() = user_id);

drop policy if exists "users can view own installation epochs" on public.installation_epochs;
create policy "users can view own installation epochs"
  on public.installation_epochs for select to authenticated
  using (
    auth.uid() = user_id
    and exists (
      select 1 from public.device_memberships dm
      where dm.device_id = installation_epochs.device_id and dm.user_id = auth.uid()
    )
  );

drop policy if exists "users can insert own installation epochs" on public.installation_epochs;
create policy "users can insert own installation epochs"
  on public.installation_epochs for insert to authenticated
  with check (
    auth.uid() = user_id
    and exists (
      select 1 from public.device_memberships dm
      where dm.device_id = installation_epochs.device_id and dm.user_id = auth.uid()
    )
  );

drop policy if exists "users can delete own installation epochs" on public.installation_epochs;
create policy "users can delete own installation epochs"
  on public.installation_epochs for delete to authenticated
  using (auth.uid() = user_id);

-- Consultas que justifican las columnas sueltas:
--
--   -- ventanas críticas sin evidencia por temporada (lo que pesa en el score)
--   select season_key, count(*) filter (where outcome = 'unattended' and is_critical)
--     from public.nutrition_windows
--    where device_id = :device
--    group by 1;
--
--   -- magnitud típica de respuesta del sitio (mediana de firmas compatibles)
--   select percentile_cont(0.5) within group (order by signature_confidence)
--     from public.nutrition_windows
--    where device_id = :device and outcome = 'attendedDetected';
