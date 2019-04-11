SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: pg_trgm; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pg_trgm WITH SCHEMA public;


--
-- Name: EXTENSION pg_trgm; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION pg_trgm IS 'text similarity measurement and index searching based on trigrams';


--
-- Name: pgcrypto; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA public;


--
-- Name: EXTENSION pgcrypto; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION pgcrypto IS 'cryptographic functions';


--
-- Name: source_type; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.source_type AS ENUM (
    'manual',
    'stripe',
    'github',
    'unknown'
);


--
-- Name: agg_all_repo_counts(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.agg_all_repo_counts() RETURNS boolean
    LANGUAGE plpgsql
    AS $$
begin
  with src as (
    select cnt.repository_id
    from repo_counts cnt
    group by cnt.repository_id
    having count(1) > 1
  ),
  del as (
    delete from repo_counts cnt
    using src
    where cnt.repository_id = src.repository_id
    returning cnt.*
  ),
  agg as (
    select
      del.repository_id,
      sum(del.requests)::integer as requests,
      sum(del.commits)::integer as commits,
      sum(del.branches)::integer as branches,
      sum(del.pull_requests)::integer as pull_requests,
      sum(del.tags)::integer as tags,
      sum(del.builds)::integer as builds,
      -- sum(del.stages)::integer as stages,
      sum(del.jobs)::integer as jobs
    from del
    group by del.repository_id
  )
  insert into repo_counts(
    repository_id,
    requests,
    commits,
    branches,
    pull_requests,
    tags,
    builds,
    -- stages,
    jobs
  )
  select
    agg.repository_id,
    agg.requests,
    agg.commits,
    agg.branches,
    agg.pull_requests,
    agg.tags,
    agg.builds,
    -- agg.stages,
    agg.jobs
  from agg;

  return true;
end;
$$;


--
-- Name: agg_repo_counts(integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.agg_repo_counts(_repo_id integer) RETURNS boolean
    LANGUAGE plpgsql
    AS $$
begin
  with src as (
    select cnt.repository_id
    from repo_counts cnt
    where cnt.repository_id = _repo_id
    group by cnt.repository_id
    having count(1) > 1
  ),
  del as (
    delete from repo_counts cnt
    using src
    where cnt.repository_id = src.repository_id
    returning cnt.*
  ),
  agg as (
    select
      del.repository_id,
      sum(del.requests)::integer as requests,
      sum(del.commits)::integer as commits,
      sum(del.branches)::integer as branches,
      sum(del.pull_requests)::integer as pull_requests,
      sum(del.tags)::integer as tags,
      sum(del.builds)::integer as builds,
      -- sum(del.stages)::integer as stages,
      sum(del.jobs)::integer as jobs
    from del
    group by del.repository_id
  )
  insert into repo_counts(
    repository_id,
    requests,
    commits,
    branches,
    pull_requests,
    tags,
    builds,
    -- stages,
    jobs
  )
  select
    agg.repository_id,
    agg.requests,
    agg.commits,
    agg.branches,
    agg.pull_requests,
    agg.tags,
    agg.builds,
    -- agg.stages,
    agg.jobs
  from agg
  where agg.requests > 0 or agg.builds > 0 or agg.jobs > 0;

  return true;
end;
$$;


--
-- Name: count_all_branches(integer, integer, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.count_all_branches(_count integer, _start integer, _end integer) RETURNS boolean
    LANGUAGE plpgsql
    AS $$
declare max int;
begin
  select id + _count from branches order by id desc limit 1 into max;

  for i in _start.._end by _count loop
    if i > max then exit; end if;
    begin
      raise notice 'counting branches %', i;
      insert into repo_counts(repository_id, branches, range)
      select * from count_branches(i, i + _count - 1);
    exception when unique_violation then end;
  end loop;

  return true;
end
$$;


--
-- Name: count_all_builds(integer, integer, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.count_all_builds(_count integer, _start integer, _end integer) RETURNS boolean
    LANGUAGE plpgsql
    AS $$
declare max int;
begin
  select id + _count from builds order by id desc limit 1 into max;

  for i in _start.._end by _count loop
    if i > max then exit; end if;
    begin
      raise notice 'counting builds %', i;
      insert into repo_counts(repository_id, builds, range)
      select * from count_builds(i, i + _count - 1);
    exception when unique_violation then end;
  end loop;

  return true;
end
$$;


--
-- Name: count_all_commits(integer, integer, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.count_all_commits(_count integer, _start integer, _end integer) RETURNS boolean
    LANGUAGE plpgsql
    AS $$
declare max int;
begin
  select id + _count from commits order by id desc limit 1 into max;

  for i in _start.._end by _count loop
    if i > max then exit; end if;
    begin
      raise notice 'counting commits %', i;
      insert into repo_counts(repository_id, commits, range)
      select * from count_commits(i, i + _count - 1);
    exception when unique_violation then end;
  end loop;

  return true;
end
$$;


--
-- Name: count_all_jobs(integer, integer, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.count_all_jobs(_count integer, _start integer, _end integer) RETURNS boolean
    LANGUAGE plpgsql
    AS $$
declare max int;
begin
  select id + _count from jobs order by id desc limit 1 into max;

  for i in _start.._end by _count loop
    if i > max then exit; end if;
    begin
      raise notice 'counting jobs %', i;
      insert into repo_counts(repository_id, jobs, range)
      select * from count_jobs(i, i + _count - 1);
    exception when unique_violation then end;
  end loop;

  return true;
end
$$;


--
-- Name: count_all_pull_requests(integer, integer, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.count_all_pull_requests(_count integer, _start integer, _end integer) RETURNS boolean
    LANGUAGE plpgsql
    AS $$
declare max int;
begin
  select id + _count from pull_requests order by id desc limit 1 into max;

  for i in _start.._end by _count loop
    if i > max then exit; end if;
    begin
      raise notice 'counting pull_requests %', i;
      insert into repo_counts(repository_id, pull_requests, range)
      select * from count_pull_requests(i, i + _count - 1);
    exception when unique_violation then end;
  end loop;

  return true;
end
$$;


--
-- Name: count_all_requests(integer, integer, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.count_all_requests(_count integer, _start integer, _end integer) RETURNS boolean
    LANGUAGE plpgsql
    AS $$
declare max int;
begin
  select id + _count from requests order by id desc limit 1 into max;
  for i in _start.._end by _count loop
    if i > max then exit; end if;
    begin
      raise notice 'counting requests %', i;
      insert into repo_counts(repository_id, requests, range)
      select * from count_requests(i, i + _count - 1);
    exception when unique_violation then end;
  end loop;

  return true;
end
$$;


--
-- Name: count_all_tags(integer, integer, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.count_all_tags(_count integer, _start integer, _end integer) RETURNS boolean
    LANGUAGE plpgsql
    AS $$
declare max int;
begin
  select id + _count from tags order by id desc limit 1 into max;

  for i in _start.._end by _count loop
    if i > max then exit; end if;
    begin
      raise notice 'counting tags %', i;
      insert into repo_counts(repository_id, tags, range)
      select * from count_tags(i, i + _count - 1);
    exception when unique_violation then end;
  end loop;

  return true;
end
$$;


--
-- Name: count_branches(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.count_branches() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
declare
  c text;
  r record;
begin
  if tg_argv[0]::int > 0 then r := new; else r := old; end if;
  if r.repository_id is not null then
    insert into repo_counts(repository_id, branches)
    values(r.repository_id, tg_argv[0]::int);
  end if;
  return r;
exception when others then
  get stacked diagnostics c = pg_exception_context;
  raise warning '% context: %s', sqlerrm, c;
  return r;
end;
$$;


--
-- Name: count_branches(integer, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.count_branches(_start integer, _end integer) RETURNS TABLE(repository_id integer, branches bigint, range character varying)
    LANGUAGE plpgsql
    AS $$
begin
  return query select r.id, count(t.id) as branches, ('branches' || ':' || _start || ':' || _end)::varchar as range
  from branches as t
  join repositories as r on t.repository_id = r.id
  where t.id between _start and _end and t.created_at <= '2018-01-01 00:00:00' and t.repository_id is not null
  group by r.id;
end;
$$;


--
-- Name: count_builds(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.count_builds() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
declare
  c text;
  r record;
begin
  if tg_argv[0]::int > 0 then r := new; else r := old; end if;
  if r.repository_id is not null then
    insert into repo_counts(repository_id, builds)
    values(r.repository_id, tg_argv[0]::int);
  end if;
  return r;
exception when others then
  get stacked diagnostics c = pg_exception_context;
  raise warning '% context: %s', sqlerrm, c;
  return r;
end;
$$;


--
-- Name: count_builds(integer, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.count_builds(_start integer, _end integer) RETURNS TABLE(repository_id integer, builds bigint, range character varying)
    LANGUAGE plpgsql
    AS $$
begin
  return query select t.repository_id, count(id) as builds, ('builds' || ':' || _start || ':' || _end)::varchar as range
  from builds as t
  where t.id between _start and _end and t.created_at <= '2018-01-01 00:00:00' and t.repository_id is not null
  group by t.repository_id;
end;
$$;


--
-- Name: count_commits(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.count_commits() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
declare
  c text;
  r record;
begin
  if tg_argv[0]::int > 0 then r := new; else r := old; end if;
  if r.repository_id is not null then
    insert into repo_counts(repository_id, commits)
    values(r.repository_id, tg_argv[0]::int);
  end if;
  return r;
exception when others then
  get stacked diagnostics c = pg_exception_context;
  raise warning '% context: %s', sqlerrm, c;
  return r;
end;
$$;


--
-- Name: count_commits(integer, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.count_commits(_start integer, _end integer) RETURNS TABLE(repository_id integer, commits bigint, range character varying)
    LANGUAGE plpgsql
    AS $$
begin
  return query select r.id, count(t.id) as commits, ('commits' || ':' || _start || ':' || _end)::varchar as range
  from commits as t
  join repositories as r on t.repository_id = r.id
  where t.id between _start and _end and t.created_at <= '2018-01-01 00:00:00' and t.repository_id is not null
  group by r.id;
end;
$$;


--
-- Name: count_jobs(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.count_jobs() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
declare
  c text;
  r record;
begin
  if tg_argv[0]::int > 0 then r := new; else r := old; end if;
  if r.repository_id is not null then
    insert into repo_counts(repository_id, jobs)
    values(r.repository_id, tg_argv[0]::int);
  end if;
  return r;
exception when others then
  get stacked diagnostics c = pg_exception_context;
  raise warning '% context: %s', sqlerrm, c;
  return r;
end;
$$;


--
-- Name: count_jobs(integer, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.count_jobs(_start integer, _end integer) RETURNS TABLE(repository_id integer, jobs bigint, range character varying)
    LANGUAGE plpgsql
    AS $$
begin
  return query select t.repository_id, count(id) as jobs, ('jobs' || ':' || _start || ':' || _end)::varchar as range
  from jobs as t
  where t.id between _start and _end and t.created_at <= '2018-01-01 00:00:00' and t.repository_id is not null
  group by t.repository_id;
end;
$$;


--
-- Name: count_pull_requests(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.count_pull_requests() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
declare
  c text;
  r record;
begin
  if tg_argv[0]::int > 0 then r := new; else r := old; end if;
  if r.repository_id is not null then
    insert into repo_counts(repository_id, pull_requests)
    values(r.repository_id, tg_argv[0]::int);
  end if;
  return r;
exception when others then
  get stacked diagnostics c = pg_exception_context;
  raise warning '% context: %s', sqlerrm, c;
  return r;
end;
$$;


--
-- Name: count_pull_requests(integer, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.count_pull_requests(_start integer, _end integer) RETURNS TABLE(repository_id integer, pull_requests bigint, range character varying)
    LANGUAGE plpgsql
    AS $$
begin
  return query select r.id, count(t.id) as pull_requests, ('pull_requests' || ':' || _start || ':' || _end)::varchar as range
  from pull_requests as t
  join repositories as r on t.repository_id = r.id
  where t.id between _start and _end and t.created_at <= '2018-01-01 00:00:00' and t.repository_id is not null
  group by r.id;
end;
$$;


--
-- Name: count_requests(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.count_requests() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
declare
  c text;
  r record;
begin
  if tg_argv[0]::int > 0 then r := new; else r := old; end if;
  if r.repository_id is not null then
    insert into repo_counts(repository_id, requests)
    values(r.repository_id, tg_argv[0]::int);
  end if;
  return r;
exception when others then
  get stacked diagnostics c = pg_exception_context;
  raise warning '% context: %s', sqlerrm, c;
  return r;
end;
$$;


--
-- Name: count_requests(integer, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.count_requests(_start integer, _end integer) RETURNS TABLE(repository_id integer, requests bigint, range character varying)
    LANGUAGE plpgsql
    AS $$
begin
  return query select t.repository_id, count(id) as requests, ('requests' || ':' || _start || ':' || _end)::varchar as range
  from requests as t
  where t.id between _start and _end and t.created_at <= '2018-01-01 00:00:00' and t.repository_id is not null
  group by t.repository_id;
end;
$$;


--
-- Name: count_tags(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.count_tags() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
declare
  c text;
  r record;
begin
  if tg_argv[0]::int > 0 then r := new; else r := old; end if;
  if r.repository_id is not null is not null then
    insert into repo_counts(repository_id, tags)
    values(r.repository_id, tg_argv[0]::int);
  end if;
  return r;
exception when others then
  get stacked diagnostics c = pg_exception_context;
  raise warning '% context: %s', sqlerrm, c;
  return r;
end;
$$;


--
-- Name: count_tags(integer, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.count_tags(_start integer, _end integer) RETURNS TABLE(repository_id integer, tags bigint, range character varying)
    LANGUAGE plpgsql
    AS $$
begin
  return query select r.id, count(t.id) as tags, ('tags' || ':' || _start || ':' || _end)::varchar as range
  from tags as t
  join repositories as r on t.repository_id = r.id
  where t.id between _start and _end and t.created_at <= '2018-01-01 00:00:00' and t.repository_id is not null
  group by r.id;
end;
$$;


--
-- Name: is_json(text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.is_json(text) RETURNS boolean
    LANGUAGE plpgsql IMMUTABLE
    AS $_$
  BEGIN
    perform $1::json;
    return true;
  EXCEPTION WHEN invalid_text_representation THEN
    return false;
  END
$_$;


--
-- Name: set_unique_name(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.set_unique_name() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
  disable boolean;
BEGIN
  disable := 'f';
  IF TG_OP = 'INSERT' OR TG_OP = 'UPDATE' THEN
    BEGIN
       disable := current_setting('set_unique_name_on_branches.disable');
    EXCEPTION
    WHEN others THEN
      set set_unique_name_on_branches.disable = 'f';
    END;

    IF NOT disable THEN
      NEW.unique_name := NEW.name;
    END IF;
  END IF;
  RETURN NEW;
END;
$$;


--
-- Name: set_unique_number(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.set_unique_number() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
  disable boolean;
BEGIN
  disable := 'f';
  IF TG_OP = 'INSERT' OR TG_OP = 'UPDATE' THEN
    BEGIN
       disable := current_setting('set_unique_number_on_builds.disable');
    EXCEPTION
    WHEN others THEN
      set set_unique_number_on_builds.disable = 'f';
    END;

    IF NOT disable THEN
      NEW.unique_number := NEW.number;
    END IF;
  END IF;
  RETURN NEW;
END;
$$;


--
-- Name: set_updated_at(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.set_updated_at() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
      BEGIN
        IF TG_OP = 'INSERT' OR
             (TG_OP = 'UPDATE' AND NEW.* IS DISTINCT FROM OLD.*) THEN
          NEW.updated_at := statement_timestamp();
        END IF;
        RETURN NEW;
      END;
      $$;


SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: abuses; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.abuses (
    id integer NOT NULL,
    owner_type character varying,
    owner_id integer,
    request_id integer,
    level integer NOT NULL,
    reason character varying NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: abuses_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.abuses_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: abuses_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.abuses_id_seq OWNED BY public.abuses.id;


--
-- Name: ar_internal_metadata; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ar_internal_metadata (
    key character varying NOT NULL,
    value character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: beta_features; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.beta_features (
    id integer NOT NULL,
    name character varying,
    description text,
    feedback_url character varying,
    staff_only boolean,
    default_enabled boolean,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: beta_features_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.beta_features_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: beta_features_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.beta_features_id_seq OWNED BY public.beta_features.id;


--
-- Name: beta_migration_requests; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.beta_migration_requests (
    id integer NOT NULL,
    owner_id integer,
    owner_name character varying,
    owner_type character varying,
    created_at timestamp without time zone,
    accepted_at timestamp without time zone
);


--
-- Name: beta_migration_requests_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.beta_migration_requests_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: beta_migration_requests_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.beta_migration_requests_id_seq OWNED BY public.beta_migration_requests.id;


--
-- Name: branches; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.branches (
    id integer NOT NULL,
    repository_id integer NOT NULL,
    last_build_id integer,
    name character varying NOT NULL,
    exists_on_github boolean DEFAULT true NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    org_id integer,
    com_id integer,
    unique_name text
);


--
-- Name: branches_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.branches_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: branches_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.branches_id_seq OWNED BY public.branches.id;


--
-- Name: broadcasts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.broadcasts (
    id integer NOT NULL,
    recipient_type character varying,
    recipient_id integer,
    kind character varying,
    message character varying,
    expired boolean,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    category character varying
);


--
-- Name: broadcasts_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.broadcasts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: broadcasts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.broadcasts_id_seq OWNED BY public.broadcasts.id;


--
-- Name: build_configs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.build_configs (
    id integer NOT NULL,
    repository_id integer NOT NULL,
    key character varying NOT NULL,
    config jsonb
);


--
-- Name: build_configs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.build_configs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: build_configs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.build_configs_id_seq OWNED BY public.build_configs.id;


--
-- Name: shared_builds_tasks_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.shared_builds_tasks_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: builds; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.builds (
    id bigint DEFAULT nextval('public.shared_builds_tasks_seq'::regclass) NOT NULL,
    repository_id integer,
    number character varying,
    started_at timestamp without time zone,
    finished_at timestamp without time zone,
    log text DEFAULT ''::text,
    message text,
    committed_at timestamp without time zone,
    committer_name character varying,
    committer_email character varying,
    author_name character varying,
    author_email character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    ref character varying,
    branch character varying,
    github_payload text,
    compare_url character varying,
    token character varying,
    commit_id integer,
    request_id integer,
    state character varying,
    duration integer,
    owner_type character varying,
    owner_id integer,
    event_type character varying,
    previous_state character varying,
    pull_request_title text,
    pull_request_number integer,
    canceled_at timestamp without time zone,
    cached_matrix_ids integer[],
    received_at timestamp without time zone,
    private boolean,
    pull_request_id integer,
    branch_id integer,
    tag_id integer,
    sender_type character varying,
    sender_id integer,
    org_id integer,
    com_id integer,
    config_id integer,
    restarted_at timestamp without time zone,
    unique_number integer
);


--
-- Name: builds_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.builds_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: builds_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.builds_id_seq OWNED BY public.builds.id;


--
-- Name: cancellations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.cancellations (
    id integer NOT NULL,
    subscription_id integer NOT NULL,
    user_id integer,
    plan character varying NOT NULL,
    subscription_start_date date NOT NULL,
    cancellation_date date NOT NULL,
    reason character varying,
    reason_details text,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: cancellations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.cancellations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: cancellations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.cancellations_id_seq OWNED BY public.cancellations.id;


--
-- Name: commits; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.commits (
    id integer NOT NULL,
    repository_id integer,
    commit character varying,
    ref character varying,
    branch character varying,
    message text,
    compare_url character varying,
    committed_at timestamp without time zone,
    committer_name character varying,
    committer_email character varying,
    author_name character varying,
    author_email character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    branch_id integer,
    tag_id integer,
    org_id integer,
    com_id integer
);


--
-- Name: commits_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.commits_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: commits_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.commits_id_seq OWNED BY public.commits.id;


--
-- Name: coupons; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.coupons (
    id integer NOT NULL,
    percent_off integer,
    coupon_id character varying,
    redeem_by timestamp without time zone,
    amount_off integer,
    duration character varying,
    duration_in_months integer,
    max_redemptions integer,
    redemptions integer
);


--
-- Name: coupons_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.coupons_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: coupons_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.coupons_id_seq OWNED BY public.coupons.id;


--
-- Name: crons; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.crons (
    id integer NOT NULL,
    branch_id integer,
    "interval" character varying NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    next_run timestamp without time zone,
    last_run timestamp without time zone,
    dont_run_if_recent_build_exists boolean DEFAULT false,
    org_id integer,
    com_id integer,
    active boolean DEFAULT true
);


--
-- Name: crons_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.crons_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: crons_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.crons_id_seq OWNED BY public.crons.id;


--
-- Name: email_unsubscribes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.email_unsubscribes (
    id bigint NOT NULL,
    user_id integer,
    repository_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: email_unsubscribes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.email_unsubscribes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: email_unsubscribes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.email_unsubscribes_id_seq OWNED BY public.email_unsubscribes.id;


--
-- Name: emails; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.emails (
    id integer NOT NULL,
    user_id integer,
    email character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: emails_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.emails_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: emails_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.emails_id_seq OWNED BY public.emails.id;


--
-- Name: gatekeeper_workers; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.gatekeeper_workers (
    id bigint NOT NULL
);


--
-- Name: gatekeeper_workers_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.gatekeeper_workers_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: gatekeeper_workers_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.gatekeeper_workers_id_seq OWNED BY public.gatekeeper_workers.id;


--
-- Name: installations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.installations (
    id integer NOT NULL,
    github_id integer,
    permissions jsonb,
    owner_type character varying,
    owner_id integer,
    added_by_id integer,
    removed_by_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    removed_at timestamp without time zone
);


--
-- Name: installations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.installations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: installations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.installations_id_seq OWNED BY public.installations.id;


--
-- Name: invoices; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.invoices (
    id integer NOT NULL,
    object text,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    subscription_id integer,
    invoice_id character varying,
    stripe_id character varying,
    cc_last_digits character varying
);


--
-- Name: invoices_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.invoices_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: invoices_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.invoices_id_seq OWNED BY public.invoices.id;


--
-- Name: job_configs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.job_configs (
    id integer NOT NULL,
    repository_id integer NOT NULL,
    key character varying NOT NULL,
    config jsonb
);


--
-- Name: job_configs_gpu; Type: MATERIALIZED VIEW; Schema: public; Owner: -
--

CREATE MATERIALIZED VIEW public.job_configs_gpu AS
 SELECT job_configs.id
   FROM public.job_configs
  WHERE (public.is_json((job_configs.config ->> 'resources'::text)) AND ((((job_configs.config ->> 'resources'::text))::jsonb ->> 'gpu'::text) IS NOT NULL))
  WITH NO DATA;


--
-- Name: job_configs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.job_configs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: job_configs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.job_configs_id_seq OWNED BY public.job_configs.id;


--
-- Name: job_versions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.job_versions (
    id integer NOT NULL,
    job_id integer,
    number integer,
    state character varying,
    created_at timestamp without time zone,
    queued_at timestamp without time zone,
    received_at timestamp without time zone,
    started_at timestamp without time zone,
    finished_at timestamp without time zone,
    restarted_at timestamp without time zone
);


--
-- Name: job_versions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.job_versions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: job_versions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.job_versions_id_seq OWNED BY public.job_versions.id;


--
-- Name: jobs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.jobs (
    id bigint DEFAULT nextval('public.shared_builds_tasks_seq'::regclass) NOT NULL,
    repository_id integer,
    commit_id integer,
    source_type character varying,
    source_id integer,
    queue character varying,
    type character varying,
    state character varying,
    number character varying,
    log text DEFAULT ''::text,
    worker character varying,
    started_at timestamp without time zone,
    finished_at timestamp without time zone,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    tags text,
    allow_failure boolean DEFAULT false,
    owner_type character varying,
    owner_id integer,
    result integer,
    queued_at timestamp without time zone,
    canceled_at timestamp without time zone,
    received_at timestamp without time zone,
    debug_options text,
    private boolean,
    stage_number character varying,
    stage_id integer,
    org_id integer,
    com_id integer,
    config_id integer,
    restarted_at timestamp without time zone
);


--
-- Name: jobs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.jobs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: jobs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.jobs_id_seq OWNED BY public.jobs.id;


--
-- Name: memberships; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.memberships (
    id integer NOT NULL,
    organization_id integer,
    user_id integer,
    role character varying
);


--
-- Name: memberships_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.memberships_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: memberships_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.memberships_id_seq OWNED BY public.memberships.id;


--
-- Name: messages; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.messages (
    id integer NOT NULL,
    subject_id integer,
    subject_type character varying,
    level character varying,
    key character varying,
    code character varying,
    args json,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: messages_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.messages_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: messages_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.messages_id_seq OWNED BY public.messages.id;


--
-- Name: organizations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.organizations (
    id integer NOT NULL,
    name character varying,
    login character varying,
    github_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    avatar_url character varying,
    location character varying,
    email character varying,
    company character varying,
    homepage character varying,
    billing_admin_only boolean,
    org_id integer,
    com_id integer,
    migrating boolean,
    migrated_at timestamp without time zone,
    preferences jsonb DEFAULT '{}'::jsonb,
    beta_migration_request_id integer
);


--
-- Name: organizations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.organizations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: organizations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.organizations_id_seq OWNED BY public.organizations.id;


--
-- Name: owner_groups; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.owner_groups (
    id integer NOT NULL,
    uuid character varying,
    owner_type character varying,
    owner_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: owner_groups_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.owner_groups_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: owner_groups_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.owner_groups_id_seq OWNED BY public.owner_groups.id;


--
-- Name: permissions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.permissions (
    id integer NOT NULL,
    user_id integer,
    repository_id integer,
    admin boolean DEFAULT false,
    push boolean DEFAULT false,
    pull boolean DEFAULT false,
    org_id integer,
    com_id integer
);


--
-- Name: permissions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.permissions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: permissions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.permissions_id_seq OWNED BY public.permissions.id;


--
-- Name: pull_requests; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.pull_requests (
    id integer NOT NULL,
    repository_id integer,
    number integer,
    title character varying,
    state character varying,
    head_repo_github_id integer,
    head_repo_slug character varying,
    head_ref character varying,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    org_id integer,
    com_id integer
);


--
-- Name: pull_requests_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.pull_requests_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: pull_requests_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.pull_requests_id_seq OWNED BY public.pull_requests.id;


--
-- Name: queueable_jobs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.queueable_jobs (
    id integer NOT NULL,
    job_id integer
);


--
-- Name: queueable_jobs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.queueable_jobs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: queueable_jobs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.queueable_jobs_id_seq OWNED BY public.queueable_jobs.id;


--
-- Name: repo_counts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.repo_counts (
    repository_id integer NOT NULL,
    requests integer,
    commits integer,
    branches integer,
    pull_requests integer,
    tags integer,
    builds integer,
    stages integer,
    jobs integer,
    range character varying
);


--
-- Name: repositories; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.repositories (
    id integer NOT NULL,
    name character varying,
    url character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    last_build_id integer,
    last_build_number character varying,
    last_build_started_at timestamp without time zone,
    last_build_finished_at timestamp without time zone,
    owner_name character varying,
    owner_email text,
    active boolean,
    description text,
    last_build_duration integer,
    owner_type character varying,
    owner_id integer,
    private boolean DEFAULT false,
    last_build_state character varying,
    github_id integer,
    default_branch character varying,
    github_language character varying,
    settings json,
    next_build_number integer,
    invalidated_at timestamp without time zone,
    current_build_id bigint,
    org_id integer,
    com_id integer,
    migrating boolean,
    migrated_at timestamp without time zone,
    active_on_org boolean,
    managed_by_installation_at timestamp without time zone,
    migration_status character varying
);


--
-- Name: repositories_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.repositories_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: repositories_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.repositories_id_seq OWNED BY public.repositories.id;


--
-- Name: request_configs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.request_configs (
    id integer NOT NULL,
    repository_id integer NOT NULL,
    key character varying NOT NULL,
    config jsonb
);


--
-- Name: request_configs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.request_configs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: request_configs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.request_configs_id_seq OWNED BY public.request_configs.id;


--
-- Name: request_payloads; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.request_payloads (
    id integer NOT NULL,
    request_id integer NOT NULL,
    payload text,
    archived boolean DEFAULT false,
    created_at timestamp without time zone
);


--
-- Name: request_payloads_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.request_payloads_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: request_payloads_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.request_payloads_id_seq OWNED BY public.request_payloads.id;


--
-- Name: request_raw_configs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.request_raw_configs (
    id integer NOT NULL,
    config text,
    repository_id integer,
    key character varying NOT NULL
);


--
-- Name: request_raw_configs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.request_raw_configs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: request_raw_configs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.request_raw_configs_id_seq OWNED BY public.request_raw_configs.id;


--
-- Name: request_raw_configurations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.request_raw_configurations (
    id integer NOT NULL,
    request_id integer,
    request_raw_config_id integer,
    source character varying
);


--
-- Name: request_raw_configurations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.request_raw_configurations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: request_raw_configurations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.request_raw_configurations_id_seq OWNED BY public.request_raw_configurations.id;


--
-- Name: request_yaml_configs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.request_yaml_configs (
    id integer NOT NULL,
    yaml text,
    repository_id integer,
    key character varying NOT NULL
);


--
-- Name: request_yaml_configs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.request_yaml_configs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: request_yaml_configs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.request_yaml_configs_id_seq OWNED BY public.request_yaml_configs.id;


--
-- Name: requests; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.requests (
    id integer NOT NULL,
    repository_id integer,
    commit_id integer,
    state character varying,
    source character varying,
    token character varying,
    started_at timestamp without time zone,
    finished_at timestamp without time zone,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    event_type character varying,
    comments_url character varying,
    base_commit character varying,
    head_commit character varying,
    owner_type character varying,
    owner_id integer,
    result character varying,
    message character varying,
    private boolean,
    pull_request_id integer,
    branch_id integer,
    tag_id integer,
    sender_type character varying,
    sender_id integer,
    org_id integer,
    com_id integer,
    config_id integer,
    yaml_config_id integer,
    github_guid text
);


--
-- Name: requests_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.requests_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: requests_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.requests_id_seq OWNED BY public.requests.id;


--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.schema_migrations (
    version character varying NOT NULL
);


--
-- Name: ssl_keys; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ssl_keys (
    id integer NOT NULL,
    repository_id integer,
    public_key text,
    private_key text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    org_id integer,
    com_id integer
);


--
-- Name: ssl_keys_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.ssl_keys_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ssl_keys_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.ssl_keys_id_seq OWNED BY public.ssl_keys.id;


--
-- Name: stages; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.stages (
    id integer NOT NULL,
    build_id integer,
    number integer,
    name character varying,
    state character varying,
    started_at timestamp without time zone,
    finished_at timestamp without time zone,
    org_id integer,
    com_id integer
);


--
-- Name: stages_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.stages_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: stages_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.stages_id_seq OWNED BY public.stages.id;


--
-- Name: stars; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.stars (
    id integer NOT NULL,
    repository_id integer,
    user_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: stars_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.stars_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: stars_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.stars_id_seq OWNED BY public.stars.id;


--
-- Name: stripe_events; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.stripe_events (
    id integer NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    event_object text,
    event_type character varying,
    date timestamp without time zone,
    event_id character varying
);


--
-- Name: stripe_events_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.stripe_events_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: stripe_events_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.stripe_events_id_seq OWNED BY public.stripe_events.id;


--
-- Name: subscriptions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.subscriptions (
    id integer NOT NULL,
    cc_token character varying,
    valid_to timestamp without time zone,
    owner_type character varying NOT NULL,
    owner_id integer NOT NULL,
    first_name character varying,
    last_name character varying,
    company character varying,
    zip_code character varying,
    address character varying,
    address2 character varying,
    city character varying,
    state character varying,
    country character varying,
    vat_id character varying,
    customer_id character varying,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    cc_owner character varying,
    cc_last_digits character varying,
    cc_expiration_date character varying,
    billing_email character varying,
    selected_plan character varying,
    coupon character varying,
    contact_id integer,
    canceled_at timestamp without time zone,
    canceled_by_id integer,
    status character varying,
    source public.source_type DEFAULT 'unknown'::public.source_type NOT NULL,
    concurrency integer
);


--
-- Name: subscriptions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.subscriptions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: subscriptions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.subscriptions_id_seq OWNED BY public.subscriptions.id;


--
-- Name: tags; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tags (
    id integer NOT NULL,
    repository_id integer,
    name character varying,
    last_build_id integer,
    exists_on_github boolean,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    org_id integer,
    com_id integer
);


--
-- Name: tags_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.tags_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tags_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.tags_id_seq OWNED BY public.tags.id;


--
-- Name: tokens; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tokens (
    id integer NOT NULL,
    user_id integer,
    token character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: tokens_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.tokens_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tokens_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.tokens_id_seq OWNED BY public.tokens.id;


--
-- Name: trial_allowances; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.trial_allowances (
    id integer NOT NULL,
    trial_id integer,
    creator_id integer,
    creator_type character varying,
    builds_allowed integer,
    builds_remaining integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: trial_allowances_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.trial_allowances_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: trial_allowances_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.trial_allowances_id_seq OWNED BY public.trial_allowances.id;


--
-- Name: trials; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.trials (
    id integer NOT NULL,
    owner_type character varying,
    owner_id integer,
    chartmogul_customer_uuids text[] DEFAULT '{}'::text[],
    status character varying DEFAULT 'new'::character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: trials_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.trials_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: trials_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.trials_id_seq OWNED BY public.trials.id;


--
-- Name: urls; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.urls (
    id integer NOT NULL,
    url character varying,
    code character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: urls_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.urls_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: urls_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.urls_id_seq OWNED BY public.urls.id;


--
-- Name: user_beta_features; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.user_beta_features (
    id integer NOT NULL,
    user_id integer,
    beta_feature_id integer,
    enabled boolean,
    last_deactivated_at timestamp without time zone,
    last_activated_at timestamp without time zone
);


--
-- Name: user_beta_features_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.user_beta_features_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: user_beta_features_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.user_beta_features_id_seq OWNED BY public.user_beta_features.id;


--
-- Name: users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.users (
    id integer NOT NULL,
    name character varying,
    login character varying,
    email character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    is_admin boolean DEFAULT false,
    github_id integer,
    github_oauth_token character varying,
    gravatar_id character varying,
    locale character varying,
    is_syncing boolean,
    synced_at timestamp without time zone,
    github_scopes text,
    education boolean,
    first_logged_in_at timestamp without time zone,
    avatar_url character varying,
    suspended boolean DEFAULT false,
    suspended_at timestamp without time zone,
    org_id integer,
    com_id integer,
    migrating boolean,
    migrated_at timestamp without time zone,
    redacted_at timestamp without time zone,
    preferences jsonb DEFAULT '{}'::jsonb
);


--
-- Name: users_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.users_id_seq OWNED BY public.users.id;


--
-- Name: abuses id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.abuses ALTER COLUMN id SET DEFAULT nextval('public.abuses_id_seq'::regclass);


--
-- Name: beta_features id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.beta_features ALTER COLUMN id SET DEFAULT nextval('public.beta_features_id_seq'::regclass);


--
-- Name: beta_migration_requests id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.beta_migration_requests ALTER COLUMN id SET DEFAULT nextval('public.beta_migration_requests_id_seq'::regclass);


--
-- Name: branches id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.branches ALTER COLUMN id SET DEFAULT nextval('public.branches_id_seq'::regclass);


--
-- Name: broadcasts id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.broadcasts ALTER COLUMN id SET DEFAULT nextval('public.broadcasts_id_seq'::regclass);


--
-- Name: build_configs id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.build_configs ALTER COLUMN id SET DEFAULT nextval('public.build_configs_id_seq'::regclass);


--
-- Name: cancellations id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cancellations ALTER COLUMN id SET DEFAULT nextval('public.cancellations_id_seq'::regclass);


--
-- Name: commits id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.commits ALTER COLUMN id SET DEFAULT nextval('public.commits_id_seq'::regclass);


--
-- Name: coupons id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.coupons ALTER COLUMN id SET DEFAULT nextval('public.coupons_id_seq'::regclass);


--
-- Name: crons id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.crons ALTER COLUMN id SET DEFAULT nextval('public.crons_id_seq'::regclass);


--
-- Name: email_unsubscribes id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.email_unsubscribes ALTER COLUMN id SET DEFAULT nextval('public.email_unsubscribes_id_seq'::regclass);


--
-- Name: emails id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.emails ALTER COLUMN id SET DEFAULT nextval('public.emails_id_seq'::regclass);


--
-- Name: gatekeeper_workers id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.gatekeeper_workers ALTER COLUMN id SET DEFAULT nextval('public.gatekeeper_workers_id_seq'::regclass);


--
-- Name: installations id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.installations ALTER COLUMN id SET DEFAULT nextval('public.installations_id_seq'::regclass);


--
-- Name: invoices id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.invoices ALTER COLUMN id SET DEFAULT nextval('public.invoices_id_seq'::regclass);


--
-- Name: job_configs id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.job_configs ALTER COLUMN id SET DEFAULT nextval('public.job_configs_id_seq'::regclass);


--
-- Name: job_versions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.job_versions ALTER COLUMN id SET DEFAULT nextval('public.job_versions_id_seq'::regclass);


--
-- Name: memberships id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.memberships ALTER COLUMN id SET DEFAULT nextval('public.memberships_id_seq'::regclass);


--
-- Name: messages id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.messages ALTER COLUMN id SET DEFAULT nextval('public.messages_id_seq'::regclass);


--
-- Name: organizations id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.organizations ALTER COLUMN id SET DEFAULT nextval('public.organizations_id_seq'::regclass);


--
-- Name: owner_groups id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.owner_groups ALTER COLUMN id SET DEFAULT nextval('public.owner_groups_id_seq'::regclass);


--
-- Name: permissions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.permissions ALTER COLUMN id SET DEFAULT nextval('public.permissions_id_seq'::regclass);


--
-- Name: pull_requests id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pull_requests ALTER COLUMN id SET DEFAULT nextval('public.pull_requests_id_seq'::regclass);


--
-- Name: queueable_jobs id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.queueable_jobs ALTER COLUMN id SET DEFAULT nextval('public.queueable_jobs_id_seq'::regclass);


--
-- Name: repositories id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.repositories ALTER COLUMN id SET DEFAULT nextval('public.repositories_id_seq'::regclass);


--
-- Name: request_configs id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.request_configs ALTER COLUMN id SET DEFAULT nextval('public.request_configs_id_seq'::regclass);


--
-- Name: request_payloads id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.request_payloads ALTER COLUMN id SET DEFAULT nextval('public.request_payloads_id_seq'::regclass);


--
-- Name: request_raw_configs id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.request_raw_configs ALTER COLUMN id SET DEFAULT nextval('public.request_raw_configs_id_seq'::regclass);


--
-- Name: request_raw_configurations id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.request_raw_configurations ALTER COLUMN id SET DEFAULT nextval('public.request_raw_configurations_id_seq'::regclass);


--
-- Name: request_yaml_configs id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.request_yaml_configs ALTER COLUMN id SET DEFAULT nextval('public.request_yaml_configs_id_seq'::regclass);


--
-- Name: requests id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.requests ALTER COLUMN id SET DEFAULT nextval('public.requests_id_seq'::regclass);


--
-- Name: ssl_keys id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ssl_keys ALTER COLUMN id SET DEFAULT nextval('public.ssl_keys_id_seq'::regclass);


--
-- Name: stages id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.stages ALTER COLUMN id SET DEFAULT nextval('public.stages_id_seq'::regclass);


--
-- Name: stars id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.stars ALTER COLUMN id SET DEFAULT nextval('public.stars_id_seq'::regclass);


--
-- Name: stripe_events id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.stripe_events ALTER COLUMN id SET DEFAULT nextval('public.stripe_events_id_seq'::regclass);


--
-- Name: subscriptions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.subscriptions ALTER COLUMN id SET DEFAULT nextval('public.subscriptions_id_seq'::regclass);


--
-- Name: tags id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tags ALTER COLUMN id SET DEFAULT nextval('public.tags_id_seq'::regclass);


--
-- Name: tokens id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tokens ALTER COLUMN id SET DEFAULT nextval('public.tokens_id_seq'::regclass);


--
-- Name: trial_allowances id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.trial_allowances ALTER COLUMN id SET DEFAULT nextval('public.trial_allowances_id_seq'::regclass);


--
-- Name: trials id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.trials ALTER COLUMN id SET DEFAULT nextval('public.trials_id_seq'::regclass);


--
-- Name: urls id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.urls ALTER COLUMN id SET DEFAULT nextval('public.urls_id_seq'::regclass);


--
-- Name: user_beta_features id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_beta_features ALTER COLUMN id SET DEFAULT nextval('public.user_beta_features_id_seq'::regclass);


--
-- Name: users id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users ALTER COLUMN id SET DEFAULT nextval('public.users_id_seq'::regclass);


--
-- Name: abuses abuses_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.abuses
    ADD CONSTRAINT abuses_pkey PRIMARY KEY (id);


--
-- Name: ar_internal_metadata ar_internal_metadata_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ar_internal_metadata
    ADD CONSTRAINT ar_internal_metadata_pkey PRIMARY KEY (key);


--
-- Name: beta_features beta_features_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.beta_features
    ADD CONSTRAINT beta_features_pkey PRIMARY KEY (id);


--
-- Name: beta_migration_requests beta_migration_requests_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.beta_migration_requests
    ADD CONSTRAINT beta_migration_requests_pkey PRIMARY KEY (id);


--
-- Name: branches branches_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.branches
    ADD CONSTRAINT branches_pkey PRIMARY KEY (id);


--
-- Name: broadcasts broadcasts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.broadcasts
    ADD CONSTRAINT broadcasts_pkey PRIMARY KEY (id);


--
-- Name: build_configs build_configs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.build_configs
    ADD CONSTRAINT build_configs_pkey PRIMARY KEY (id);


--
-- Name: builds builds_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.builds
    ADD CONSTRAINT builds_pkey PRIMARY KEY (id);


--
-- Name: cancellations cancellations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cancellations
    ADD CONSTRAINT cancellations_pkey PRIMARY KEY (id);


--
-- Name: commits commits_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.commits
    ADD CONSTRAINT commits_pkey PRIMARY KEY (id);


--
-- Name: coupons coupons_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.coupons
    ADD CONSTRAINT coupons_pkey PRIMARY KEY (id);


--
-- Name: crons crons_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.crons
    ADD CONSTRAINT crons_pkey PRIMARY KEY (id);


--
-- Name: email_unsubscribes email_unsubscribes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.email_unsubscribes
    ADD CONSTRAINT email_unsubscribes_pkey PRIMARY KEY (id);


--
-- Name: emails emails_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.emails
    ADD CONSTRAINT emails_pkey PRIMARY KEY (id);


--
-- Name: gatekeeper_workers gatekeeper_workers_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.gatekeeper_workers
    ADD CONSTRAINT gatekeeper_workers_pkey PRIMARY KEY (id);


--
-- Name: installations installations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.installations
    ADD CONSTRAINT installations_pkey PRIMARY KEY (id);


--
-- Name: invoices invoices_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.invoices
    ADD CONSTRAINT invoices_pkey PRIMARY KEY (id);


--
-- Name: job_configs job_configs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.job_configs
    ADD CONSTRAINT job_configs_pkey PRIMARY KEY (id);


--
-- Name: job_versions job_versions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.job_versions
    ADD CONSTRAINT job_versions_pkey PRIMARY KEY (id);


--
-- Name: jobs jobs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.jobs
    ADD CONSTRAINT jobs_pkey PRIMARY KEY (id);


--
-- Name: memberships memberships_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.memberships
    ADD CONSTRAINT memberships_pkey PRIMARY KEY (id);


--
-- Name: messages messages_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.messages
    ADD CONSTRAINT messages_pkey PRIMARY KEY (id);


--
-- Name: organizations organizations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.organizations
    ADD CONSTRAINT organizations_pkey PRIMARY KEY (id);


--
-- Name: owner_groups owner_groups_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.owner_groups
    ADD CONSTRAINT owner_groups_pkey PRIMARY KEY (id);


--
-- Name: permissions permissions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.permissions
    ADD CONSTRAINT permissions_pkey PRIMARY KEY (id);


--
-- Name: pull_requests pull_requests_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pull_requests
    ADD CONSTRAINT pull_requests_pkey PRIMARY KEY (id);


--
-- Name: queueable_jobs queueable_jobs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.queueable_jobs
    ADD CONSTRAINT queueable_jobs_pkey PRIMARY KEY (id);


--
-- Name: repositories repositories_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.repositories
    ADD CONSTRAINT repositories_pkey PRIMARY KEY (id);


--
-- Name: request_configs request_configs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.request_configs
    ADD CONSTRAINT request_configs_pkey PRIMARY KEY (id);


--
-- Name: request_payloads request_payloads_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.request_payloads
    ADD CONSTRAINT request_payloads_pkey PRIMARY KEY (id);


--
-- Name: request_raw_configs request_raw_configs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.request_raw_configs
    ADD CONSTRAINT request_raw_configs_pkey PRIMARY KEY (id);


--
-- Name: request_raw_configurations request_raw_configurations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.request_raw_configurations
    ADD CONSTRAINT request_raw_configurations_pkey PRIMARY KEY (id);


--
-- Name: request_yaml_configs request_yaml_configs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.request_yaml_configs
    ADD CONSTRAINT request_yaml_configs_pkey PRIMARY KEY (id);


--
-- Name: requests requests_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.requests
    ADD CONSTRAINT requests_pkey PRIMARY KEY (id);


--
-- Name: schema_migrations schema_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.schema_migrations
    ADD CONSTRAINT schema_migrations_pkey PRIMARY KEY (version);


--
-- Name: ssl_keys ssl_keys_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ssl_keys
    ADD CONSTRAINT ssl_keys_pkey PRIMARY KEY (id);


--
-- Name: stages stages_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.stages
    ADD CONSTRAINT stages_pkey PRIMARY KEY (id);


--
-- Name: stars stars_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.stars
    ADD CONSTRAINT stars_pkey PRIMARY KEY (id);


--
-- Name: stripe_events stripe_events_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.stripe_events
    ADD CONSTRAINT stripe_events_pkey PRIMARY KEY (id);


--
-- Name: subscriptions subscriptions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.subscriptions
    ADD CONSTRAINT subscriptions_pkey PRIMARY KEY (id);


--
-- Name: tags tags_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tags
    ADD CONSTRAINT tags_pkey PRIMARY KEY (id);


--
-- Name: tokens tokens_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tokens
    ADD CONSTRAINT tokens_pkey PRIMARY KEY (id);


--
-- Name: trial_allowances trial_allowances_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.trial_allowances
    ADD CONSTRAINT trial_allowances_pkey PRIMARY KEY (id);


--
-- Name: trials trials_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.trials
    ADD CONSTRAINT trials_pkey PRIMARY KEY (id);


--
-- Name: urls urls_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.urls
    ADD CONSTRAINT urls_pkey PRIMARY KEY (id);


--
-- Name: user_beta_features user_beta_features_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_beta_features
    ADD CONSTRAINT user_beta_features_pkey PRIMARY KEY (id);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: github_id_installations_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX github_id_installations_idx ON public.installations USING btree (github_id);


--
-- Name: index_abuses_on_owner; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_abuses_on_owner ON public.abuses USING btree (owner_id);


--
-- Name: index_abuses_on_owner_id_and_owner_type_and_level; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_abuses_on_owner_id_and_owner_type_and_level ON public.abuses USING btree (owner_id, owner_type, level);


--
-- Name: index_active_on_org; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_active_on_org ON public.repositories USING btree (active_on_org);


--
-- Name: index_beta_migration_requests_on_owner_type_and_owner_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_beta_migration_requests_on_owner_type_and_owner_id ON public.beta_migration_requests USING btree (owner_type, owner_id);


--
-- Name: index_branches_on_com_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_branches_on_com_id ON public.branches USING btree (com_id);


--
-- Name: index_branches_on_last_build_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_branches_on_last_build_id ON public.branches USING btree (last_build_id);


--
-- Name: index_branches_on_org_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_branches_on_org_id ON public.branches USING btree (org_id);


--
-- Name: index_branches_on_repository_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_branches_on_repository_id ON public.branches USING btree (repository_id);


--
-- Name: index_branches_on_repository_id_and_name; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_branches_on_repository_id_and_name ON public.branches USING btree (repository_id, name);


--
-- Name: index_branches_on_repository_id_and_name_and_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_branches_on_repository_id_and_name_and_id ON public.branches USING btree (repository_id, name, id);


--
-- Name: index_branches_repository_id_unique_name; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_branches_repository_id_unique_name ON public.branches USING btree (repository_id, unique_name) WHERE (unique_name IS NOT NULL);


--
-- Name: index_broadcasts_on_recipient_id_and_recipient_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_broadcasts_on_recipient_id_and_recipient_type ON public.broadcasts USING btree (recipient_id, recipient_type);


--
-- Name: index_build_configs_on_repository_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_build_configs_on_repository_id ON public.build_configs USING btree (repository_id);


--
-- Name: index_build_configs_on_repository_id_and_key; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_build_configs_on_repository_id_and_key ON public.build_configs USING btree (repository_id, key);


--
-- Name: index_builds_on_branch_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_builds_on_branch_id ON public.builds USING btree (branch_id);


--
-- Name: index_builds_on_com_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_builds_on_com_id ON public.builds USING btree (com_id);


--
-- Name: index_builds_on_commit_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_builds_on_commit_id ON public.builds USING btree (commit_id);


--
-- Name: index_builds_on_config_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_builds_on_config_id ON public.builds USING btree (config_id);


--
-- Name: index_builds_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_builds_on_created_at ON public.builds USING btree (created_at);


--
-- Name: index_builds_on_org_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_builds_on_org_id ON public.builds USING btree (org_id);


--
-- Name: index_builds_on_pull_request_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_builds_on_pull_request_id ON public.builds USING btree (pull_request_id);


--
-- Name: index_builds_on_repo_branch_event_type_and_private; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_builds_on_repo_branch_event_type_and_private ON public.builds USING btree (repository_id, branch, event_type, private);


--
-- Name: index_builds_on_repository_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_builds_on_repository_id ON public.builds USING btree (repository_id);


--
-- Name: index_builds_on_repository_id_and_branch_and_event_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_builds_on_repository_id_and_branch_and_event_type ON public.builds USING btree (repository_id, branch, event_type) WHERE ((state)::text = ANY ((ARRAY['created'::character varying, 'queued'::character varying, 'received'::character varying])::text[]));


--
-- Name: index_builds_on_repository_id_and_branch_and_event_type_and_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_builds_on_repository_id_and_branch_and_event_type_and_id ON public.builds USING btree (repository_id, branch, event_type, id);


--
-- Name: index_builds_on_repository_id_and_branch_and_id_desc; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_builds_on_repository_id_and_branch_and_id_desc ON public.builds USING btree (repository_id, branch, id DESC);


--
-- Name: index_builds_on_repository_id_and_number; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_builds_on_repository_id_and_number ON public.builds USING btree (repository_id, ((number)::integer));


--
-- Name: index_builds_on_repository_id_and_number_and_event_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_builds_on_repository_id_and_number_and_event_type ON public.builds USING btree (repository_id, number, event_type);


--
-- Name: index_builds_on_repository_id_event_type_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_builds_on_repository_id_event_type_id ON public.builds USING btree (repository_id, event_type, id DESC);


--
-- Name: index_builds_on_repository_id_where_state_not_finished; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_builds_on_repository_id_where_state_not_finished ON public.builds USING btree (repository_id) WHERE ((state)::text = ANY ((ARRAY['created'::character varying, 'queued'::character varying, 'received'::character varying, 'started'::character varying])::text[]));


--
-- Name: index_builds_on_request_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_builds_on_request_id ON public.builds USING btree (request_id);


--
-- Name: index_builds_on_sender_type_and_sender_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_builds_on_sender_type_and_sender_id ON public.builds USING btree (sender_type, sender_id);


--
-- Name: index_builds_on_state; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_builds_on_state ON public.builds USING btree (state);


--
-- Name: index_builds_on_tag_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_builds_on_tag_id ON public.builds USING btree (tag_id);


--
-- Name: index_builds_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_builds_on_updated_at ON public.builds USING btree (updated_at);


--
-- Name: index_builds_repository_id_unique_number; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_builds_repository_id_unique_number ON public.builds USING btree (repository_id, unique_number) WHERE (unique_number IS NOT NULL);


--
-- Name: index_cancellations_on_subscription_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_cancellations_on_subscription_id ON public.cancellations USING btree (subscription_id);


--
-- Name: index_commits_on_author_email; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_commits_on_author_email ON public.commits USING btree (author_email);


--
-- Name: index_commits_on_branch_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_commits_on_branch_id ON public.commits USING btree (branch_id);


--
-- Name: index_commits_on_com_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_commits_on_com_id ON public.commits USING btree (com_id);


--
-- Name: index_commits_on_committer_email; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_commits_on_committer_email ON public.commits USING btree (committer_email);


--
-- Name: index_commits_on_org_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_commits_on_org_id ON public.commits USING btree (org_id);


--
-- Name: index_commits_on_repository_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_commits_on_repository_id ON public.commits USING btree (repository_id);


--
-- Name: index_commits_on_tag_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_commits_on_tag_id ON public.commits USING btree (tag_id);


--
-- Name: index_crons_on_branch_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_crons_on_branch_id ON public.crons USING btree (branch_id);


--
-- Name: index_crons_on_com_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_crons_on_com_id ON public.crons USING btree (com_id);


--
-- Name: index_crons_on_next_run; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_crons_on_next_run ON public.crons USING btree (next_run) WHERE (active IS TRUE);


--
-- Name: index_crons_on_org_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_crons_on_org_id ON public.crons USING btree (org_id);


--
-- Name: index_email_unsubscribes_on_repository_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_email_unsubscribes_on_repository_id ON public.email_unsubscribes USING btree (repository_id);


--
-- Name: index_email_unsubscribes_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_email_unsubscribes_on_user_id ON public.email_unsubscribes USING btree (user_id);


--
-- Name: index_email_unsubscribes_on_user_id_and_repository_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_email_unsubscribes_on_user_id_and_repository_id ON public.email_unsubscribes USING btree (user_id, repository_id);


--
-- Name: index_emails_on_email; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_emails_on_email ON public.emails USING btree (email);


--
-- Name: index_emails_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_emails_on_user_id ON public.emails USING btree (user_id);


--
-- Name: index_installations_on_owner_type_and_owner_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_installations_on_owner_type_and_owner_id ON public.installations USING btree (owner_type, owner_id);


--
-- Name: index_invoices_on_stripe_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_invoices_on_stripe_id ON public.invoices USING btree (stripe_id);


--
-- Name: index_job_configs_on_config_resources_gpu; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_job_configs_on_config_resources_gpu ON public.job_configs USING btree (((((config ->> 'resources'::text))::jsonb ->> 'gpu'::text))) WHERE (public.is_json((config ->> 'resources'::text)) AND ((((config ->> 'resources'::text))::jsonb ->> 'gpu'::text) IS NOT NULL));


--
-- Name: index_job_configs_on_repository_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_job_configs_on_repository_id ON public.job_configs USING btree (repository_id);


--
-- Name: index_job_configs_on_repository_id_and_key; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_job_configs_on_repository_id_and_key ON public.job_configs USING btree (repository_id, key);


--
-- Name: index_jobs_on_com_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_jobs_on_com_id ON public.jobs USING btree (com_id);


--
-- Name: index_jobs_on_commit_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_jobs_on_commit_id ON public.jobs USING btree (commit_id);


--
-- Name: index_jobs_on_config_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_jobs_on_config_id ON public.jobs USING btree (config_id);


--
-- Name: index_jobs_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_jobs_on_created_at ON public.jobs USING btree (created_at);


--
-- Name: index_jobs_on_org_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_jobs_on_org_id ON public.jobs USING btree (org_id);


--
-- Name: index_jobs_on_owner_id_and_owner_type_and_state; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_jobs_on_owner_id_and_owner_type_and_state ON public.jobs USING btree (owner_id, owner_type, state);


--
-- Name: index_jobs_on_owner_where_state_running; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_jobs_on_owner_where_state_running ON public.jobs USING btree (owner_id, owner_type) WHERE ((state)::text = ANY ((ARRAY['queued'::character varying, 'received'::character varying, 'started'::character varying])::text[]));


--
-- Name: index_jobs_on_repository_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_jobs_on_repository_id ON public.jobs USING btree (repository_id);


--
-- Name: index_jobs_on_repository_id_where_state_running; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_jobs_on_repository_id_where_state_running ON public.jobs USING btree (repository_id) WHERE ((state)::text = ANY ((ARRAY['queued'::character varying, 'received'::character varying, 'started'::character varying])::text[]));


--
-- Name: index_jobs_on_source_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_jobs_on_source_id ON public.jobs USING btree (source_id);


--
-- Name: index_jobs_on_stage_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_jobs_on_stage_id ON public.jobs USING btree (stage_id);


--
-- Name: index_jobs_on_state; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_jobs_on_state ON public.jobs USING btree (state);


--
-- Name: index_jobs_on_type_and_source_id_and_source_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_jobs_on_type_and_source_id_and_source_type ON public.jobs USING btree (type, source_id, source_type);


--
-- Name: index_jobs_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_jobs_on_updated_at ON public.jobs USING btree (updated_at);


--
-- Name: index_memberships_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_memberships_on_user_id ON public.memberships USING btree (user_id);


--
-- Name: index_messages_on_subject_type_and_subject_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_messages_on_subject_type_and_subject_id ON public.messages USING btree (subject_type, subject_id);


--
-- Name: index_organization_id_and_user_id_on_memberships; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_organization_id_and_user_id_on_memberships ON public.memberships USING btree (organization_id, user_id);


--
-- Name: index_organizations_on_com_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_organizations_on_com_id ON public.organizations USING btree (com_id);


--
-- Name: index_organizations_on_github_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_organizations_on_github_id ON public.organizations USING btree (github_id);


--
-- Name: index_organizations_on_login; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_organizations_on_login ON public.organizations USING btree (login);


--
-- Name: index_organizations_on_lower_login; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_organizations_on_lower_login ON public.organizations USING btree (lower((login)::text));


--
-- Name: index_organizations_on_org_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_organizations_on_org_id ON public.organizations USING btree (org_id);


--
-- Name: index_organizations_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_organizations_on_updated_at ON public.organizations USING btree (updated_at);


--
-- Name: index_owner_groups_on_owner_type_and_owner_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_owner_groups_on_owner_type_and_owner_id ON public.owner_groups USING btree (owner_type, owner_id);


--
-- Name: index_owner_groups_on_uuid; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_owner_groups_on_uuid ON public.owner_groups USING btree (uuid);


--
-- Name: index_permissions_on_com_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_permissions_on_com_id ON public.permissions USING btree (com_id);


--
-- Name: index_permissions_on_org_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_permissions_on_org_id ON public.permissions USING btree (org_id);


--
-- Name: index_permissions_on_repository_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_permissions_on_repository_id ON public.permissions USING btree (repository_id);


--
-- Name: index_permissions_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_permissions_on_user_id ON public.permissions USING btree (user_id);


--
-- Name: index_permissions_on_user_id_and_repository_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_permissions_on_user_id_and_repository_id ON public.permissions USING btree (user_id, repository_id);


--
-- Name: index_pull_requests_on_com_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_pull_requests_on_com_id ON public.pull_requests USING btree (com_id);


--
-- Name: index_pull_requests_on_org_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_pull_requests_on_org_id ON public.pull_requests USING btree (org_id);


--
-- Name: index_pull_requests_on_repository_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_pull_requests_on_repository_id ON public.pull_requests USING btree (repository_id);


--
-- Name: index_pull_requests_on_repository_id_and_number; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_pull_requests_on_repository_id_and_number ON public.pull_requests USING btree (repository_id, number);


--
-- Name: index_queueable_jobs_on_job_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_queueable_jobs_on_job_id ON public.queueable_jobs USING btree (job_id);


--
-- Name: index_repo_counts_on_repository_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_repo_counts_on_repository_id ON public.repo_counts USING btree (repository_id);


--
-- Name: index_repositories_on_active; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_repositories_on_active ON public.repositories USING btree (active);


--
-- Name: index_repositories_on_com_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_repositories_on_com_id ON public.repositories USING btree (com_id);


--
-- Name: index_repositories_on_current_build_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_repositories_on_current_build_id ON public.repositories USING btree (current_build_id);


--
-- Name: index_repositories_on_github_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_repositories_on_github_id ON public.repositories USING btree (github_id);


--
-- Name: index_repositories_on_last_build_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_repositories_on_last_build_id ON public.repositories USING btree (last_build_id);


--
-- Name: index_repositories_on_lower_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_repositories_on_lower_name ON public.repositories USING btree (lower((name)::text));


--
-- Name: index_repositories_on_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_repositories_on_name ON public.repositories USING btree (name);


--
-- Name: index_repositories_on_org_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_repositories_on_org_id ON public.repositories USING btree (org_id);


--
-- Name: index_repositories_on_owner_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_repositories_on_owner_id ON public.repositories USING btree (owner_id);


--
-- Name: index_repositories_on_owner_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_repositories_on_owner_name ON public.repositories USING btree (owner_name);


--
-- Name: index_repositories_on_owner_name_and_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_repositories_on_owner_name_and_name ON public.repositories USING btree (owner_name, name) WHERE (invalidated_at IS NULL);


--
-- Name: index_repositories_on_slug; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_repositories_on_slug ON public.repositories USING gin (((((owner_name)::text || '/'::text) || (name)::text)) public.gin_trgm_ops);


--
-- Name: index_repositories_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_repositories_on_updated_at ON public.repositories USING btree (updated_at);


--
-- Name: index_request_configs_on_repository_id_and_key; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_request_configs_on_repository_id_and_key ON public.request_configs USING btree (repository_id, key);


--
-- Name: index_request_payloads_on_created_at_and_archived; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_request_payloads_on_created_at_and_archived ON public.request_payloads USING btree (created_at, archived);


--
-- Name: index_request_payloads_on_request_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_request_payloads_on_request_id ON public.request_payloads USING btree (request_id);


--
-- Name: index_request_raw_configs_on_repository_id_and_key; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_request_raw_configs_on_repository_id_and_key ON public.request_raw_configs USING btree (repository_id, key);


--
-- Name: index_request_raw_configurations_on_request_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_request_raw_configurations_on_request_id ON public.request_raw_configurations USING btree (request_id);


--
-- Name: index_request_raw_configurations_on_request_raw_config_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_request_raw_configurations_on_request_raw_config_id ON public.request_raw_configurations USING btree (request_raw_config_id);


--
-- Name: index_request_yaml_configs_on_repository_id_and_key; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_request_yaml_configs_on_repository_id_and_key ON public.request_yaml_configs USING btree (repository_id, key);


--
-- Name: index_requests_on_branch_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_requests_on_branch_id ON public.requests USING btree (branch_id);


--
-- Name: index_requests_on_com_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_requests_on_com_id ON public.requests USING btree (com_id);


--
-- Name: index_requests_on_commit_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_requests_on_commit_id ON public.requests USING btree (commit_id);


--
-- Name: index_requests_on_config_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_requests_on_config_id ON public.requests USING btree (config_id);


--
-- Name: index_requests_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_requests_on_created_at ON public.requests USING btree (created_at);


--
-- Name: index_requests_on_github_guid; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_requests_on_github_guid ON public.requests USING btree (github_guid);


--
-- Name: index_requests_on_head_commit; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_requests_on_head_commit ON public.requests USING btree (head_commit);


--
-- Name: index_requests_on_org_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_requests_on_org_id ON public.requests USING btree (org_id);


--
-- Name: index_requests_on_pull_request_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_requests_on_pull_request_id ON public.requests USING btree (pull_request_id);


--
-- Name: index_requests_on_repository_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_requests_on_repository_id ON public.requests USING btree (repository_id);


--
-- Name: index_requests_on_repository_id_and_id_desc; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_requests_on_repository_id_and_id_desc ON public.requests USING btree (repository_id, id DESC);


--
-- Name: index_requests_on_tag_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_requests_on_tag_id ON public.requests USING btree (tag_id);


--
-- Name: index_ssl_key_on_repository_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_ssl_key_on_repository_id ON public.ssl_keys USING btree (repository_id);


--
-- Name: index_ssl_keys_on_com_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_ssl_keys_on_com_id ON public.ssl_keys USING btree (com_id);


--
-- Name: index_ssl_keys_on_org_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_ssl_keys_on_org_id ON public.ssl_keys USING btree (org_id);


--
-- Name: index_stages_on_build_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_stages_on_build_id ON public.stages USING btree (build_id);


--
-- Name: index_stages_on_com_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_stages_on_com_id ON public.stages USING btree (com_id);


--
-- Name: index_stages_on_org_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_stages_on_org_id ON public.stages USING btree (org_id);


--
-- Name: index_stars_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_stars_on_user_id ON public.stars USING btree (user_id);


--
-- Name: index_stars_on_user_id_and_repository_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_stars_on_user_id_and_repository_id ON public.stars USING btree (user_id, repository_id);


--
-- Name: index_stripe_events_on_date; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_stripe_events_on_date ON public.stripe_events USING btree (date);


--
-- Name: index_stripe_events_on_event_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_stripe_events_on_event_id ON public.stripe_events USING btree (event_id);


--
-- Name: index_stripe_events_on_event_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_stripe_events_on_event_type ON public.stripe_events USING btree (event_type);


--
-- Name: index_tags_on_com_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_tags_on_com_id ON public.tags USING btree (com_id);


--
-- Name: index_tags_on_last_build_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_tags_on_last_build_id ON public.tags USING btree (last_build_id);


--
-- Name: index_tags_on_org_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_tags_on_org_id ON public.tags USING btree (org_id);


--
-- Name: index_tags_on_repository_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_tags_on_repository_id ON public.tags USING btree (repository_id);


--
-- Name: index_tags_on_repository_id_and_name; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_tags_on_repository_id_and_name ON public.tags USING btree (repository_id, name);


--
-- Name: index_tokens_on_token; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_tokens_on_token ON public.tokens USING btree (token);


--
-- Name: index_tokens_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_tokens_on_user_id ON public.tokens USING btree (user_id);


--
-- Name: index_trial_allowances_on_creator_id_and_creator_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_trial_allowances_on_creator_id_and_creator_type ON public.trial_allowances USING btree (creator_id, creator_type);


--
-- Name: index_trial_allowances_on_trial_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_trial_allowances_on_trial_id ON public.trial_allowances USING btree (trial_id);


--
-- Name: index_trials_on_owner; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_trials_on_owner ON public.trials USING btree (owner_id, owner_type);


--
-- Name: index_user_beta_features_on_user_id_and_beta_feature_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_user_beta_features_on_user_id_and_beta_feature_id ON public.user_beta_features USING btree (user_id, beta_feature_id);


--
-- Name: index_users_on_com_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_users_on_com_id ON public.users USING btree (com_id);


--
-- Name: index_users_on_github_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_users_on_github_id ON public.users USING btree (github_id);


--
-- Name: index_users_on_github_oauth_token; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_users_on_github_oauth_token ON public.users USING btree (github_oauth_token);


--
-- Name: index_users_on_login; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_users_on_login ON public.users USING btree (login);


--
-- Name: index_users_on_lower_login; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_users_on_lower_login ON public.users USING btree (lower((login)::text));


--
-- Name: index_users_on_org_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_users_on_org_id ON public.users USING btree (org_id);


--
-- Name: index_users_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_users_on_updated_at ON public.users USING btree (updated_at);


--
-- Name: managed_repositories_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX managed_repositories_idx ON public.repositories USING btree (managed_by_installation_at);


--
-- Name: owner_installations_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX owner_installations_idx ON public.installations USING btree (owner_id, owner_type) WHERE (removed_by_id IS NULL);


--
-- Name: subscriptions_owner; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX subscriptions_owner ON public.subscriptions USING btree (owner_id, owner_type) WHERE ((status)::text = 'subscribed'::text);


--
-- Name: user_preferences_build_emails_false; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX user_preferences_build_emails_false ON public.users USING btree (id) WHERE ((preferences ->> 'build_emails'::text) = 'false'::text);


--
-- Name: branches set_unique_name_on_branches; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER set_unique_name_on_branches BEFORE INSERT OR UPDATE ON public.branches FOR EACH ROW EXECUTE PROCEDURE public.set_unique_name();


--
-- Name: builds set_unique_number_on_builds; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER set_unique_number_on_builds BEFORE INSERT ON public.builds FOR EACH ROW EXECUTE PROCEDURE public.set_unique_number();


--
-- Name: builds set_updated_at_on_builds; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER set_updated_at_on_builds BEFORE INSERT OR UPDATE ON public.builds FOR EACH ROW EXECUTE PROCEDURE public.set_updated_at();


--
-- Name: jobs set_updated_at_on_jobs; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER set_updated_at_on_jobs BEFORE INSERT OR UPDATE ON public.jobs FOR EACH ROW EXECUTE PROCEDURE public.set_updated_at();


--
-- Name: branches trg_count_branch_deleted; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_count_branch_deleted AFTER DELETE ON public.branches FOR EACH ROW WHEN ((now() > '2018-01-01 00:00:00+00'::timestamp with time zone)) EXECUTE PROCEDURE public.count_branches('-1');


--
-- Name: branches trg_count_branch_inserted; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_count_branch_inserted AFTER INSERT ON public.branches FOR EACH ROW WHEN ((now() > '2018-01-01 00:00:00+00'::timestamp with time zone)) EXECUTE PROCEDURE public.count_branches('1');


--
-- Name: builds trg_count_build_deleted; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_count_build_deleted AFTER DELETE ON public.builds FOR EACH ROW WHEN ((now() > '2018-01-01 00:00:00+00'::timestamp with time zone)) EXECUTE PROCEDURE public.count_builds('-1');


--
-- Name: builds trg_count_build_inserted; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_count_build_inserted AFTER INSERT ON public.builds FOR EACH ROW WHEN ((now() > '2018-01-01 00:00:00+00'::timestamp with time zone)) EXECUTE PROCEDURE public.count_builds('1');


--
-- Name: commits trg_count_commit_deleted; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_count_commit_deleted AFTER DELETE ON public.commits FOR EACH ROW WHEN ((now() > '2018-01-01 00:00:00+00'::timestamp with time zone)) EXECUTE PROCEDURE public.count_commits('-1');


--
-- Name: commits trg_count_commit_inserted; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_count_commit_inserted AFTER INSERT ON public.commits FOR EACH ROW WHEN ((now() > '2018-01-01 00:00:00+00'::timestamp with time zone)) EXECUTE PROCEDURE public.count_commits('1');


--
-- Name: jobs trg_count_job_deleted; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_count_job_deleted AFTER DELETE ON public.jobs FOR EACH ROW WHEN ((now() > '2018-01-01 00:00:00+00'::timestamp with time zone)) EXECUTE PROCEDURE public.count_jobs('-1');


--
-- Name: jobs trg_count_job_inserted; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_count_job_inserted AFTER INSERT ON public.jobs FOR EACH ROW WHEN ((now() > '2018-01-01 00:00:00+00'::timestamp with time zone)) EXECUTE PROCEDURE public.count_jobs('1');


--
-- Name: pull_requests trg_count_pull_request_deleted; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_count_pull_request_deleted AFTER DELETE ON public.pull_requests FOR EACH ROW WHEN ((now() > '2018-01-01 00:00:00+00'::timestamp with time zone)) EXECUTE PROCEDURE public.count_pull_requests('-1');


--
-- Name: pull_requests trg_count_pull_request_inserted; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_count_pull_request_inserted AFTER INSERT ON public.pull_requests FOR EACH ROW WHEN ((now() > '2018-01-01 00:00:00+00'::timestamp with time zone)) EXECUTE PROCEDURE public.count_pull_requests('1');


--
-- Name: requests trg_count_request_deleted; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_count_request_deleted AFTER DELETE ON public.requests FOR EACH ROW WHEN ((now() > '2018-01-01 00:00:00+00'::timestamp with time zone)) EXECUTE PROCEDURE public.count_requests('-1');


--
-- Name: requests trg_count_request_inserted; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_count_request_inserted AFTER INSERT ON public.requests FOR EACH ROW WHEN ((now() > '2018-01-01 00:00:00+00'::timestamp with time zone)) EXECUTE PROCEDURE public.count_requests('1');


--
-- Name: tags trg_count_tag_deleted; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_count_tag_deleted AFTER DELETE ON public.tags FOR EACH ROW WHEN ((now() > '2018-01-01 00:00:00+00'::timestamp with time zone)) EXECUTE PROCEDURE public.count_tags('-1');


--
-- Name: tags trg_count_tag_inserted; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_count_tag_inserted AFTER INSERT ON public.tags FOR EACH ROW WHEN ((now() > '2018-01-01 00:00:00+00'::timestamp with time zone)) EXECUTE PROCEDURE public.count_tags('1');


--
-- Name: branches fk_branches_on_last_build_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.branches
    ADD CONSTRAINT fk_branches_on_last_build_id FOREIGN KEY (last_build_id) REFERENCES public.builds(id) ON DELETE SET NULL;


--
-- Name: branches fk_branches_on_repository_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.branches
    ADD CONSTRAINT fk_branches_on_repository_id FOREIGN KEY (repository_id) REFERENCES public.repositories(id);


--
-- Name: build_configs fk_build_configs_on_repository_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.build_configs
    ADD CONSTRAINT fk_build_configs_on_repository_id FOREIGN KEY (repository_id) REFERENCES public.repositories(id);


--
-- Name: builds fk_builds_on_branch_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.builds
    ADD CONSTRAINT fk_builds_on_branch_id FOREIGN KEY (branch_id) REFERENCES public.branches(id);


--
-- Name: builds fk_builds_on_commit_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.builds
    ADD CONSTRAINT fk_builds_on_commit_id FOREIGN KEY (commit_id) REFERENCES public.commits(id);


--
-- Name: builds fk_builds_on_config_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.builds
    ADD CONSTRAINT fk_builds_on_config_id FOREIGN KEY (config_id) REFERENCES public.build_configs(id);


--
-- Name: builds fk_builds_on_pull_request_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.builds
    ADD CONSTRAINT fk_builds_on_pull_request_id FOREIGN KEY (pull_request_id) REFERENCES public.pull_requests(id);


--
-- Name: builds fk_builds_on_repository_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.builds
    ADD CONSTRAINT fk_builds_on_repository_id FOREIGN KEY (repository_id) REFERENCES public.repositories(id);


--
-- Name: builds fk_builds_on_request_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.builds
    ADD CONSTRAINT fk_builds_on_request_id FOREIGN KEY (request_id) REFERENCES public.requests(id);


--
-- Name: builds fk_builds_on_tag_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.builds
    ADD CONSTRAINT fk_builds_on_tag_id FOREIGN KEY (tag_id) REFERENCES public.tags(id);


--
-- Name: commits fk_commits_on_branch_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.commits
    ADD CONSTRAINT fk_commits_on_branch_id FOREIGN KEY (branch_id) REFERENCES public.branches(id);


--
-- Name: commits fk_commits_on_repository_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.commits
    ADD CONSTRAINT fk_commits_on_repository_id FOREIGN KEY (repository_id) REFERENCES public.repositories(id);


--
-- Name: commits fk_commits_on_tag_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.commits
    ADD CONSTRAINT fk_commits_on_tag_id FOREIGN KEY (tag_id) REFERENCES public.tags(id);


--
-- Name: crons fk_crons_on_branch_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.crons
    ADD CONSTRAINT fk_crons_on_branch_id FOREIGN KEY (branch_id) REFERENCES public.branches(id);


--
-- Name: job_configs fk_job_configs_on_repository_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.job_configs
    ADD CONSTRAINT fk_job_configs_on_repository_id FOREIGN KEY (repository_id) REFERENCES public.repositories(id);


--
-- Name: jobs fk_jobs_on_commit_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.jobs
    ADD CONSTRAINT fk_jobs_on_commit_id FOREIGN KEY (commit_id) REFERENCES public.commits(id);


--
-- Name: jobs fk_jobs_on_config_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.jobs
    ADD CONSTRAINT fk_jobs_on_config_id FOREIGN KEY (config_id) REFERENCES public.job_configs(id);


--
-- Name: jobs fk_jobs_on_repository_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.jobs
    ADD CONSTRAINT fk_jobs_on_repository_id FOREIGN KEY (repository_id) REFERENCES public.repositories(id);


--
-- Name: jobs fk_jobs_on_stage_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.jobs
    ADD CONSTRAINT fk_jobs_on_stage_id FOREIGN KEY (stage_id) REFERENCES public.stages(id);


--
-- Name: pull_requests fk_pull_requests_on_repository_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pull_requests
    ADD CONSTRAINT fk_pull_requests_on_repository_id FOREIGN KEY (repository_id) REFERENCES public.repositories(id);


--
-- Name: installations fk_rails_2d567d406d; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.installations
    ADD CONSTRAINT fk_rails_2d567d406d FOREIGN KEY (added_by_id) REFERENCES public.users(id);


--
-- Name: installations fk_rails_75a0a2a3b4; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.installations
    ADD CONSTRAINT fk_rails_75a0a2a3b4 FOREIGN KEY (removed_by_id) REFERENCES public.users(id);


--
-- Name: repositories fk_repositories_on_current_build_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.repositories
    ADD CONSTRAINT fk_repositories_on_current_build_id FOREIGN KEY (current_build_id) REFERENCES public.builds(id) ON DELETE SET NULL;


--
-- Name: repositories fk_repositories_on_last_build_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.repositories
    ADD CONSTRAINT fk_repositories_on_last_build_id FOREIGN KEY (last_build_id) REFERENCES public.builds(id) ON DELETE SET NULL;


--
-- Name: requests fk_requests_on_branch_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.requests
    ADD CONSTRAINT fk_requests_on_branch_id FOREIGN KEY (branch_id) REFERENCES public.branches(id);


--
-- Name: requests fk_requests_on_commit_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.requests
    ADD CONSTRAINT fk_requests_on_commit_id FOREIGN KEY (commit_id) REFERENCES public.commits(id);


--
-- Name: requests fk_requests_on_config_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.requests
    ADD CONSTRAINT fk_requests_on_config_id FOREIGN KEY (config_id) REFERENCES public.request_configs(id);


--
-- Name: requests fk_requests_on_pull_request_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.requests
    ADD CONSTRAINT fk_requests_on_pull_request_id FOREIGN KEY (pull_request_id) REFERENCES public.pull_requests(id);


--
-- Name: requests fk_requests_on_tag_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.requests
    ADD CONSTRAINT fk_requests_on_tag_id FOREIGN KEY (tag_id) REFERENCES public.tags(id);


--
-- Name: ssl_keys fk_ssl_keys_on_repository_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ssl_keys
    ADD CONSTRAINT fk_ssl_keys_on_repository_id FOREIGN KEY (repository_id) REFERENCES public.repositories(id);


--
-- Name: stages fk_stages_on_build_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.stages
    ADD CONSTRAINT fk_stages_on_build_id FOREIGN KEY (build_id) REFERENCES public.builds(id);


--
-- Name: tags fk_tags_on_last_build_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tags
    ADD CONSTRAINT fk_tags_on_last_build_id FOREIGN KEY (last_build_id) REFERENCES public.builds(id) ON DELETE SET NULL;


--
-- Name: tags fk_tags_on_repository_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tags
    ADD CONSTRAINT fk_tags_on_repository_id FOREIGN KEY (repository_id) REFERENCES public.repositories(id);


--
-- PostgreSQL database dump complete
--

SET search_path TO "$user", public;

INSERT INTO "schema_migrations" (version) VALUES
('20101126174706'),
('20101126174715'),
('20110109130532'),
('20110116155100'),
('20110130102621'),
('20110301071656'),
('20110316174721'),
('20110321075539'),
('20110411171936'),
('20110411171937'),
('20110411172518'),
('20110413101057'),
('20110414131100'),
('20110503150504'),
('20110523012243'),
('20110611203537'),
('20110613210252'),
('20110615152003'),
('20110616211744'),
('20110617114728'),
('20110619100906'),
('20110729094426'),
('20110801161819'),
('20110805030147'),
('20110819232908'),
('20110911204538'),
('20111107134436'),
('20111107134437'),
('20111107134438'),
('20111107134439'),
('20111107134440'),
('20111128235043'),
('20111129014329'),
('20111129022625'),
('20111201113500'),
('20111203002341'),
('20111203221720'),
('20111207093700'),
('20111212103859'),
('20111212112411'),
('20111214173922'),
('20120114125404'),
('20120216133223'),
('20120222082522'),
('20120301131209'),
('20120304000502'),
('20120304000503'),
('20120304000504'),
('20120304000505'),
('20120304000506'),
('20120311234933'),
('20120316123726'),
('20120319170001'),
('20120324104051'),
('20120505165100'),
('20120511171900'),
('20120521174400'),
('20120527235800'),
('20120702111126'),
('20120703114226'),
('20120713140816'),
('20120713153215'),
('20120725005300'),
('201207261749'),
('20120727151900'),
('20120731005301'),
('20120731074000'),
('20120802001001'),
('20120803164000'),
('20120803182300'),
('20120804122700'),
('20120806120400'),
('20120820164000'),
('20120905093300'),
('20120905171300'),
('20120911160000'),
('20120911230000'),
('20120911230001'),
('20120913143800'),
('20120915012000'),
('20120915012001'),
('20120915150000'),
('20121015002500'),
('20121015002501'),
('20121017040100'),
('20121017040200'),
('20121018201301'),
('20121018203728'),
('20121018210156'),
('20121125122700'),
('20121125122701'),
('20121222125200'),
('20121222125300'),
('20121222140200'),
('20121223162300'),
('20130107165057'),
('20130115125836'),
('20130115145728'),
('20130125002600'),
('20130125171100'),
('20130129142703'),
('20130208135800'),
('20130208135801'),
('20130306154311'),
('20130311211101'),
('20130327100801'),
('20130418101437'),
('20130418103306'),
('20130505023259'),
('20130521115725'),
('20130521133050'),
('20130521134224'),
('20130521134800'),
('20130521141357'),
('20130618084205'),
('20130629122945'),
('20130629133531'),
('20130629174449'),
('20130701175200'),
('20130702123456'),
('20130702144325'),
('20130705123456'),
('20130707164854'),
('20130709185200'),
('20130709233500'),
('20130710000745'),
('20130726101124'),
('20130901183019'),
('20130909203321'),
('20130910184823'),
('20130916101056'),
('20130920135744'),
('20131104101056'),
('20131109101056'),
('20140120225125'),
('20140121003026'),
('20140204220926'),
('20140210003014'),
('20140210012509'),
('20140612131826'),
('20140827121945'),
('20150121135400'),
('20150121135401'),
('20150204144312'),
('20150210170900'),
('20150223125700'),
('20150311020321'),
('20150316020321'),
('20150316080321'),
('20150316100321'),
('20150317004600'),
('20150317020321'),
('20150317080321'),
('20150414001337'),
('20150528101600'),
('20150528101601'),
('20150528101602'),
('20150528101603'),
('20150528101604'),
('20150528101605'),
('20150528101607'),
('20150528101608'),
('20150528101609'),
('20150528101610'),
('20150528101611'),
('20150609175200'),
('20150610143500'),
('20150610143501'),
('20150610143502'),
('20150610143503'),
('20150610143504'),
('20150610143505'),
('20150610143506'),
('20150610143507'),
('20150610143508'),
('20150610143509'),
('20150610143510'),
('20150615103059'),
('20150629231300'),
('20150923131400'),
('20151112153500'),
('20151113111400'),
('20151127153500'),
('20151127154200'),
('20151127154600'),
('20151202122200'),
('20160107120927'),
('20160303165750'),
('20160412113020'),
('20160412113070'),
('20160412121405'),
('20160412123900'),
('20160414214442'),
('20160422104300'),
('20160422121400'),
('20160510142700'),
('20160510144200'),
('20160510150300'),
('20160510150400'),
('20160513074300'),
('20160609163600'),
('20160623133900'),
('20160623133901'),
('20160712125400'),
('20160819103700'),
('20160920220400'),
('20161028154600'),
('20161101000000'),
('20161101000001'),
('20161201112200'),
('20161201112600'),
('20161202000000'),
('20161206155800'),
('20161221171300'),
('20170211000000'),
('20170211000001'),
('20170211000002'),
('20170211000003'),
('20170213124000'),
('20170316000000'),
('20170316000001'),
('20170318000000'),
('20170318000001'),
('20170318000002'),
('20170322000000'),
('20170331000000'),
('20170401000000'),
('20170401000001'),
('20170401000002'),
('20170405000000'),
('20170405000001'),
('20170405000002'),
('20170405000003'),
('20170408000000'),
('20170408000001'),
('20170410000000'),
('20170411000000'),
('20170419093249'),
('20170531125700'),
('20170601163700'),
('20170601164400'),
('20170609174400'),
('20170613000000'),
('20170620144500'),
('20170621142300'),
('20170713162000'),
('20170822171600'),
('20170831000000'),
('20170911172800'),
('20171017104500'),
('20171024000000'),
('20171025000000'),
('20171103000000'),
('20171211000000'),
('20180212000000'),
('20180213000000'),
('20180222000000'),
('20180222000001'),
('20180222000002'),
('20180222000003'),
('20180222000009'),
('20180222000012'),
('20180222164100'),
('20180305143800'),
('20180321102400'),
('20180330000000'),
('20180331000000'),
('20180404000001'),
('20180410000000'),
('20180413000000'),
('20180417000000'),
('20180420000000'),
('20180425000000'),
('20180425100000'),
('20180429000000'),
('20180501000000'),
('20180517000000'),
('20180517000001'),
('20180517000002'),
('20180518000000'),
('20180522000000'),
('20180531000000'),
('20180606000000'),
('20180606000001'),
('20180614000000'),
('20180614000001'),
('20180614000002'),
('20180620000000'),
('20180725000000'),
('20180726000000'),
('20180726000001'),
('20180801000001'),
('20180822000000'),
('20180823000000'),
('20180828000000'),
('20180829000000'),
('20180830000001'),
('20180830000002'),
('20180830000003'),
('20180903000000'),
('20180903000001'),
('20180904000001'),
('20180906000000'),
('20181002115306'),
('20181002115307'),
('20181018000000'),
('20181029120000'),
('20181113120000'),
('20181116800000'),
('20181116800001'),
('20181126080000'),
('20181128120000'),
('20181203075818'),
('20181203075819'),
('20181203080356'),
('20181205152712'),
('20190102000000'),
('20190102000001'),
('20190109000000'),
('20190118000000'),
('20190204000000'),
('20190313000000'),
('20190329093854'),
('20190409133118'),
('20190409133320'),
('20190409133444'),
('20190410121039');


