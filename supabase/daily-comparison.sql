-- Privacy-preserving aggregate used by the post-game comparison card.
-- Run this once in the Wordstake Supabase SQL editor.
-- It returns only today's totals and never exposes individual game rows.

create schema if not exists wordstake_private;
revoke all on schema wordstake_private from public;
grant usage on schema wordstake_private to anon, authenticated;

create or replace function wordstake_private.get_daily_comparison_internal(
  p_game_date date,
  p_attempts integer default null
)
returns table (
  sample_size bigint,
  average_attempts numeric,
  solve_rate numeric,
  beat_percent numeric
)
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  with todays_games as (
    select won, attempts as num_guesses
    from wordstake_private.daily_results
    where game_date = p_game_date
      and p_game_date = (now() at time zone 'utc')::date
  )
  select
    count(*) as sample_size,
    round(avg(num_guesses) filter (where won), 1) as average_attempts,
    round(100.0 * count(*) filter (where won) / nullif(count(*), 0)) as solve_rate,
    case
      when p_attempts is null then 0
      else round(100.0 * count(*) filter (where not won or num_guesses > p_attempts) / nullif(count(*), 0))
    end as beat_percent
  from todays_games;
$$;

revoke all on function wordstake_private.get_daily_comparison_internal(date, integer) from public;
grant execute on function wordstake_private.get_daily_comparison_internal(date, integer) to anon, authenticated;

create or replace function public.get_daily_comparison(
  p_game_date date,
  p_attempts integer default null
)
returns table (
  sample_size bigint,
  average_attempts numeric,
  solve_rate numeric,
  beat_percent numeric
)
language sql
stable
security invoker
set search_path = pg_catalog, pg_temp
as $$
  select *
  from wordstake_private.get_daily_comparison_internal(p_game_date, p_attempts);
$$;

revoke all on function public.get_daily_comparison(date, integer) from public;
grant execute on function public.get_daily_comparison(date, integer) to anon, authenticated;

comment on function public.get_daily_comparison(date, integer) is
  'Returns privacy-safe aggregate results for the current UTC Wordstake day.';
