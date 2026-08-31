-- Privacy-safe daily completion collection for signed-in and anonymous players.
-- The submission token changes every day and cannot link a player across dates.

create schema if not exists wordstake_private;
revoke all on schema wordstake_private from public;
grant usage on schema wordstake_private to anon, authenticated;

create table if not exists wordstake_private.daily_results (
  game_date date not null,
  submission_token uuid not null,
  won boolean not null,
  attempts smallint not null check (attempts between 1 and 8),
  hints_used smallint not null default 0 check (hints_used between 0 and 5),
  easy_mode_used boolean not null default false,
  active_seconds integer not null check (active_seconds between 0 and 7200),
  created_at timestamptz not null default now(),
  primary key (game_date, submission_token),
  check (won or attempts = 8)
);

alter table wordstake_private.daily_results enable row level security;
revoke all on table wordstake_private.daily_results from public, anon, authenticated;

create or replace function wordstake_private.submit_daily_result_internal(
  p_game_date date,
  p_submission_token uuid,
  p_won boolean,
  p_attempts integer,
  p_hints_used integer,
  p_easy_mode_used boolean,
  p_active_seconds integer
)
returns boolean
language plpgsql
volatile
security definer
set search_path = wordstake_private, pg_catalog, pg_temp
as $$
declare
  inserted_count integer;
begin
  if p_game_date is distinct from (now() at time zone 'utc')::date
     or p_submission_token is null
     or p_won is null
     or p_attempts not between 1 and 8
     or (not p_won and p_attempts <> 8)
     or p_hints_used not between 0 and 5
     or p_easy_mode_used is null
     or p_active_seconds not between 0 and 7200 then
    raise exception 'Invalid daily result' using errcode = '22023';
  end if;

  insert into wordstake_private.daily_results (
    game_date, submission_token, won, attempts, hints_used, easy_mode_used, active_seconds
  ) values (
    p_game_date, p_submission_token, p_won, p_attempts, p_hints_used, p_easy_mode_used, p_active_seconds
  )
  on conflict (game_date, submission_token) do nothing;

  get diagnostics inserted_count = row_count;
  return inserted_count = 1;
end;
$$;

revoke all on function wordstake_private.submit_daily_result_internal(date, uuid, boolean, integer, integer, boolean, integer) from public;
grant execute on function wordstake_private.submit_daily_result_internal(date, uuid, boolean, integer, integer, boolean, integer) to anon, authenticated;

create or replace function public.submit_daily_result(
  p_game_date date,
  p_submission_token uuid,
  p_won boolean,
  p_attempts integer,
  p_hints_used integer,
  p_easy_mode_used boolean,
  p_active_seconds integer
)
returns boolean
language sql
volatile
security invoker
set search_path = pg_catalog, pg_temp
as $$
  select wordstake_private.submit_daily_result_internal(
    p_game_date,
    p_submission_token,
    p_won,
    p_attempts,
    p_hints_used,
    p_easy_mode_used,
    p_active_seconds
  );
$$;

revoke all on function public.submit_daily_result(date, uuid, boolean, integer, integer, boolean, integer) from public;
grant execute on function public.submit_daily_result(date, uuid, boolean, integer, integer, boolean, integer) to anon, authenticated;

comment on function public.submit_daily_result(date, uuid, boolean, integer, integer, boolean, integer) is
  'Records one privacy-safe Wordstake completion per daily browser token.';
