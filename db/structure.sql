--
-- PostgreSQL database dump
--

SET statement_timeout = 0;
SET lock_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;

--
-- Name: plpgsql; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;


--
-- Name: EXTENSION plpgsql; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';


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


SET search_path = public, pg_catalog;

--
-- Name: delete_log(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION delete_log() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
        BEGIN
          DELETE FROM logs WHERE id = OLD.id;
          RETURN OLD;
        END;
      $$;


--
-- Name: delete_log_part(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION delete_log_part() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
        BEGIN
          DELETE FROM log_parts WHERE id = OLD.id;
          RETURN OLD;
        END;
      $$;


--
-- Name: insert_log(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION insert_log() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
        BEGIN
          INSERT INTO logs VALUES (NEW.id, NEW.job_id, NEW.content, NEW.created_at, NEW.updated_at,
            NEW.aggregated_at, NEW.archiving, NEW.archived_at, NEW.archive_verified);
          RETURN NEW;
        END;
      $$;


--
-- Name: insert_log_part(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION insert_log_part() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
        BEGIN
          INSERT INTO log_parts VALUES (NEW.id, NEW.artifact_id, NEW.content, NEW.number, NEW.final,
            NEW.created_at);
          RETURN NEW;
        END;
      $$;


--
-- Name: update_log(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION update_log() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
        BEGIN
          UPDATE logs
          SET job_id=NEW.job_id, content=NEW.content, created_at=NEW.created_at,
            updated_at=NEW.updated_at, aggregated_at=NEW.aggregated_at, archiving=NEW.archiving,
            archived_at=NEW.archived_at, archive_verified=NEW.archive_verified
          WHERE id = NEW.id;
          RETURN NEW;
        END;
      $$;


--
-- Name: update_log_part(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION update_log_part() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
        BEGIN
          UPDATE logs
          SET log_id=NEW.artifact_id, content=NEW.content, number=NEW.number, created_at=NEW.created_at
          WHERE id = NEW.id;
          RETURN NEW;
        END;
      $$;


SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: annotation_providers; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE annotation_providers (
    id integer NOT NULL,
    name character varying(255),
    api_username character varying(255),
    api_key character varying(255),
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: annotation_providers_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE annotation_providers_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: annotation_providers_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE annotation_providers_id_seq OWNED BY annotation_providers.id;


--
-- Name: annotations; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE annotations (
    id integer NOT NULL,
    job_id integer NOT NULL,
    url character varying(255),
    description text NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    annotation_provider_id integer NOT NULL,
    status character varying(255)
);


--
-- Name: annotations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE annotations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: annotations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE annotations_id_seq OWNED BY annotations.id;


--
-- Name: branches; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE branches (
    id integer NOT NULL,
    repository_id integer NOT NULL,
    last_build_id integer,
    name character varying(255) NOT NULL,
    exists_on_github boolean DEFAULT true NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: branches_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE branches_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: branches_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE branches_id_seq OWNED BY branches.id;


--
-- Name: broadcasts; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE broadcasts (
    id integer NOT NULL,
    recipient_id integer,
    recipient_type character varying(255),
    kind character varying(255),
    message character varying(255),
    expired boolean,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    category character varying(255)
);


--
-- Name: broadcasts_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE broadcasts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: broadcasts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE broadcasts_id_seq OWNED BY broadcasts.id;


--
-- Name: shared_builds_tasks_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE shared_builds_tasks_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: builds; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE builds (
    id bigint DEFAULT nextval('shared_builds_tasks_seq'::regclass) NOT NULL,
    repository_id integer,
    number character varying(255),
    started_at timestamp without time zone,
    finished_at timestamp without time zone,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    config text,
    commit_id integer,
    request_id integer,
    state character varying(255),
    duration integer,
    owner_id integer,
    owner_type character varying(255),
    event_type character varying(255),
    previous_state character varying(255),
    pull_request_title text,
    pull_request_number integer,
    branch character varying(255),
    canceled_at timestamp without time zone,
    cached_matrix_ids integer[],
    received_at timestamp without time zone,
    private boolean
);


--
-- Name: builds_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE builds_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: builds_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE builds_id_seq OWNED BY builds.id;


--
-- Name: commits; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE commits (
    id integer NOT NULL,
    repository_id integer,
    commit character varying(255),
    ref character varying(255),
    branch character varying(255),
    message text,
    compare_url character varying(255),
    committed_at timestamp without time zone,
    committer_name character varying(255),
    committer_email character varying(255),
    author_name character varying(255),
    author_email character varying(255),
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: commits_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE commits_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: commits_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE commits_id_seq OWNED BY commits.id;


--
-- Name: coupons; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE coupons (
    id integer NOT NULL,
    percent_off integer,
    coupon_id character varying(255),
    redeem_by timestamp without time zone,
    amount_off integer,
    duration character varying(255),
    duration_in_months integer,
    max_redemptions integer,
    redemptions integer
);


--
-- Name: coupons_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE coupons_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: coupons_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE coupons_id_seq OWNED BY coupons.id;


--
-- Name: crons; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE crons (
    id integer NOT NULL,
    branch_id integer,
    "interval" character varying(255) NOT NULL,
    disable_by_build boolean DEFAULT true NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: crons_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE crons_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: crons_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE crons_id_seq OWNED BY crons.id;


--
-- Name: emails; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE emails (
    id integer NOT NULL,
    user_id integer,
    email character varying(255),
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: emails_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE emails_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: emails_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE emails_id_seq OWNED BY emails.id;


--
-- Name: invoices; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE invoices (
    id integer NOT NULL,
    object text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    subscription_id integer,
    invoice_id character varying(255),
    stripe_id character varying(255)
);


--
-- Name: invoices_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE invoices_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: invoices_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE invoices_id_seq OWNED BY invoices.id;


--
-- Name: jobs; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE jobs (
    id bigint DEFAULT nextval('shared_builds_tasks_seq'::regclass) NOT NULL,
    repository_id integer,
    commit_id integer,
    source_id integer,
    source_type character varying(255),
    queue character varying(255),
    type character varying(255),
    state character varying(255),
    number character varying(255),
    config text,
    worker character varying(255),
    started_at timestamp without time zone,
    finished_at timestamp without time zone,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    tags text,
    allow_failure boolean DEFAULT false,
    owner_id integer,
    owner_type character varying(255),
    result integer,
    queued_at timestamp without time zone,
    canceled_at timestamp without time zone,
    received_at timestamp without time zone,
    debug_options text,
    private boolean
);


--
-- Name: jobs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE jobs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: jobs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE jobs_id_seq OWNED BY jobs.id;


--
-- Name: log_parts; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE log_parts (
    id integer NOT NULL,
    log_id integer NOT NULL,
    content text,
    number integer,
    final boolean,
    created_at timestamp without time zone
);


--
-- Name: log_parts_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE log_parts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: log_parts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE log_parts_id_seq OWNED BY log_parts.id;


--
-- Name: logs; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE logs (
    id integer NOT NULL,
    job_id integer,
    content text,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    aggregated_at timestamp without time zone,
    archiving boolean,
    archived_at timestamp without time zone,
    archive_verified boolean,
    purged_at timestamp without time zone,
    removed_at timestamp without time zone,
    removed_by integer
);


--
-- Name: logs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: logs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE logs_id_seq OWNED BY logs.id;


--
-- Name: memberships; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE memberships (
    id integer NOT NULL,
    organization_id integer,
    user_id integer
);


--
-- Name: memberships_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE memberships_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: memberships_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE memberships_id_seq OWNED BY memberships.id;


--
-- Name: organizations; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE organizations (
    id integer NOT NULL,
    name character varying(255),
    login character varying(255),
    github_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    avatar_url character varying(255),
    location character varying(255),
    email character varying(255),
    company character varying(255),
    homepage character varying(255)
);


--
-- Name: organizations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE organizations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: organizations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE organizations_id_seq OWNED BY organizations.id;


--
-- Name: permissions; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE permissions (
    id integer NOT NULL,
    user_id integer,
    repository_id integer,
    admin boolean DEFAULT false,
    push boolean DEFAULT false,
    pull boolean DEFAULT false
);


--
-- Name: permissions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE permissions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: permissions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE permissions_id_seq OWNED BY permissions.id;


--
-- Name: plans; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE plans (
    id integer NOT NULL,
    name character varying(255),
    coupon character varying(255),
    subscription_id integer,
    valid_from timestamp without time zone,
    valid_to timestamp without time zone,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    amount integer
);


--
-- Name: plans_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE plans_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: plans_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE plans_id_seq OWNED BY plans.id;


--
-- Name: repositories; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE repositories (
    id integer NOT NULL,
    name character varying(255),
    url character varying(255),
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    last_build_id integer,
    last_build_number character varying(255),
    last_build_started_at timestamp without time zone,
    last_build_finished_at timestamp without time zone,
    owner_name character varying(255),
    owner_email text,
    active boolean,
    description text,
    last_build_duration integer,
    owner_id integer,
    owner_type character varying(255),
    private boolean DEFAULT false,
    last_build_state character varying(255),
    github_id integer,
    default_branch character varying(255),
    github_language character varying(255),
    settings json,
    next_build_number integer,
    invalidated_at timestamp without time zone,
    current_build_id bigint
);


--
-- Name: repositories_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE repositories_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: repositories_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE repositories_id_seq OWNED BY repositories.id;


--
-- Name: requests; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE requests (
    id integer NOT NULL,
    repository_id integer,
    commit_id integer,
    state character varying(255),
    source character varying(255),
    payload text,
    token character varying(255),
    config text,
    started_at timestamp without time zone,
    finished_at timestamp without time zone,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    event_type character varying(255),
    comments_url character varying(255),
    base_commit character varying(255),
    head_commit character varying(255),
    owner_id integer,
    owner_type character varying(255),
    result character varying(255),
    message character varying(255),
    private boolean
);


--
-- Name: requests_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE requests_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: requests_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE requests_id_seq OWNED BY requests.id;


--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE schema_migrations (
    version character varying(255) NOT NULL
);


--
-- Name: ssl_keys; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE ssl_keys (
    id integer NOT NULL,
    repository_id integer,
    public_key text,
    private_key text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: ssl_keys_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE ssl_keys_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ssl_keys_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE ssl_keys_id_seq OWNED BY ssl_keys.id;


--
-- Name: stars; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE stars (
    id integer NOT NULL,
    repository_id integer,
    user_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: stars_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE stars_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: stars_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE stars_id_seq OWNED BY stars.id;


--
-- Name: stripe_events; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE stripe_events (
    id integer NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    event_object text,
    event_type character varying(255),
    date timestamp without time zone,
    event_id character varying(255)
);


--
-- Name: stripe_events_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE stripe_events_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: stripe_events_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE stripe_events_id_seq OWNED BY stripe_events.id;


--
-- Name: subscriptions; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE subscriptions (
    id integer NOT NULL,
    cc_token character varying(255),
    valid_to timestamp without time zone,
    owner_id integer,
    owner_type character varying(255),
    first_name character varying(255),
    last_name character varying(255),
    company character varying(255),
    zip_code character varying(255),
    address character varying(255),
    address2 character varying(255),
    city character varying(255),
    state character varying(255),
    country character varying(255),
    vat_id character varying(255),
    customer_id character varying(255),
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    cc_owner character varying(255),
    cc_last_digits character varying(255),
    cc_expiration_date character varying(255),
    billing_email character varying(255),
    selected_plan character varying(255),
    coupon character varying(255),
    contact_id integer,
    canceled_at timestamp without time zone,
    canceled_by_id integer,
    status character varying(255)
);


--
-- Name: subscriptions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE subscriptions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: subscriptions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE subscriptions_id_seq OWNED BY subscriptions.id;


--
-- Name: tokens; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE tokens (
    id integer NOT NULL,
    user_id integer,
    token character varying(255),
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: tokens_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE tokens_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tokens_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE tokens_id_seq OWNED BY tokens.id;


--
-- Name: urls; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE urls (
    id integer NOT NULL,
    url character varying(255),
    code character varying(255),
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: urls_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE urls_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: urls_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE urls_id_seq OWNED BY urls.id;


--
-- Name: users; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE users (
    id integer NOT NULL,
    name character varying(255),
    login character varying(255),
    email character varying(255),
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    is_admin boolean DEFAULT false,
    github_id integer,
    github_oauth_token character varying(255),
    gravatar_id character varying(255),
    locale character varying(255),
    is_syncing boolean,
    synced_at timestamp without time zone,
    github_scopes text,
    education boolean,
    first_logged_in_at timestamp without time zone
);


--
-- Name: users_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE users_id_seq OWNED BY users.id;


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY annotation_providers ALTER COLUMN id SET DEFAULT nextval('annotation_providers_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY annotations ALTER COLUMN id SET DEFAULT nextval('annotations_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY branches ALTER COLUMN id SET DEFAULT nextval('branches_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY broadcasts ALTER COLUMN id SET DEFAULT nextval('broadcasts_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY commits ALTER COLUMN id SET DEFAULT nextval('commits_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY coupons ALTER COLUMN id SET DEFAULT nextval('coupons_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY crons ALTER COLUMN id SET DEFAULT nextval('crons_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY emails ALTER COLUMN id SET DEFAULT nextval('emails_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY invoices ALTER COLUMN id SET DEFAULT nextval('invoices_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY log_parts ALTER COLUMN id SET DEFAULT nextval('log_parts_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY logs ALTER COLUMN id SET DEFAULT nextval('logs_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY memberships ALTER COLUMN id SET DEFAULT nextval('memberships_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY organizations ALTER COLUMN id SET DEFAULT nextval('organizations_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY permissions ALTER COLUMN id SET DEFAULT nextval('permissions_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY plans ALTER COLUMN id SET DEFAULT nextval('plans_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY repositories ALTER COLUMN id SET DEFAULT nextval('repositories_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY requests ALTER COLUMN id SET DEFAULT nextval('requests_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY ssl_keys ALTER COLUMN id SET DEFAULT nextval('ssl_keys_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY stars ALTER COLUMN id SET DEFAULT nextval('stars_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY stripe_events ALTER COLUMN id SET DEFAULT nextval('stripe_events_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY subscriptions ALTER COLUMN id SET DEFAULT nextval('subscriptions_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY tokens ALTER COLUMN id SET DEFAULT nextval('tokens_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY urls ALTER COLUMN id SET DEFAULT nextval('urls_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY users ALTER COLUMN id SET DEFAULT nextval('users_id_seq'::regclass);


--
-- Name: annotation_providers_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY annotation_providers
    ADD CONSTRAINT annotation_providers_pkey PRIMARY KEY (id);


--
-- Name: annotations_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY annotations
    ADD CONSTRAINT annotations_pkey PRIMARY KEY (id);


--
-- Name: branches_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY branches
    ADD CONSTRAINT branches_pkey PRIMARY KEY (id);


--
-- Name: broadcasts_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY broadcasts
    ADD CONSTRAINT broadcasts_pkey PRIMARY KEY (id);


--
-- Name: builds_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY builds
    ADD CONSTRAINT builds_pkey PRIMARY KEY (id);


--
-- Name: commits_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY commits
    ADD CONSTRAINT commits_pkey PRIMARY KEY (id);


--
-- Name: coupons_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY coupons
    ADD CONSTRAINT coupons_pkey PRIMARY KEY (id);


--
-- Name: crons_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY crons
    ADD CONSTRAINT crons_pkey PRIMARY KEY (id);


--
-- Name: emails_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY emails
    ADD CONSTRAINT emails_pkey PRIMARY KEY (id);


--
-- Name: invoices_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY invoices
    ADD CONSTRAINT invoices_pkey PRIMARY KEY (id);


--
-- Name: log_parts_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY log_parts
    ADD CONSTRAINT log_parts_pkey PRIMARY KEY (id);


--
-- Name: logs_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY logs
    ADD CONSTRAINT logs_pkey PRIMARY KEY (id);


--
-- Name: memberships_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY memberships
    ADD CONSTRAINT memberships_pkey PRIMARY KEY (id);


--
-- Name: organizations_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY organizations
    ADD CONSTRAINT organizations_pkey PRIMARY KEY (id);


--
-- Name: permissions_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY permissions
    ADD CONSTRAINT permissions_pkey PRIMARY KEY (id);


--
-- Name: plans_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY plans
    ADD CONSTRAINT plans_pkey PRIMARY KEY (id);


--
-- Name: repositories_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY repositories
    ADD CONSTRAINT repositories_pkey PRIMARY KEY (id);


--
-- Name: requests_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY requests
    ADD CONSTRAINT requests_pkey PRIMARY KEY (id);


--
-- Name: ssl_keys_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY ssl_keys
    ADD CONSTRAINT ssl_keys_pkey PRIMARY KEY (id);


--
-- Name: stars_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY stars
    ADD CONSTRAINT stars_pkey PRIMARY KEY (id);


--
-- Name: stripe_events_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY stripe_events
    ADD CONSTRAINT stripe_events_pkey PRIMARY KEY (id);


--
-- Name: subscriptions_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY subscriptions
    ADD CONSTRAINT subscriptions_pkey PRIMARY KEY (id);


--
-- Name: tasks_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY jobs
    ADD CONSTRAINT tasks_pkey PRIMARY KEY (id);


--
-- Name: tokens_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY tokens
    ADD CONSTRAINT tokens_pkey PRIMARY KEY (id);


--
-- Name: urls_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY urls
    ADD CONSTRAINT urls_pkey PRIMARY KEY (id);


--
-- Name: users_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: index_annotations_on_job_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_annotations_on_job_id ON annotations USING btree (job_id);


--
-- Name: index_branches_on_repository_id_and_name; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_branches_on_repository_id_and_name ON branches USING btree (repository_id, name);


--
-- Name: index_broadcasts_on_recipient_id_and_recipient_type; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_broadcasts_on_recipient_id_and_recipient_type ON broadcasts USING btree (recipient_id, recipient_type);


--
-- Name: index_builds_on_branch; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_builds_on_branch ON builds USING btree (branch);


--
-- Name: index_builds_on_event_type; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_builds_on_event_type ON builds USING btree (event_type);


--
-- Name: index_builds_on_number; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_builds_on_number ON builds USING btree (number);


--
-- Name: index_builds_on_owner_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_builds_on_owner_id ON builds USING btree (owner_id);


--
-- Name: index_builds_on_repository_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_builds_on_repository_id ON builds USING btree (repository_id);


--
-- Name: index_builds_on_repository_id_and_number_and_event_type; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_builds_on_repository_id_and_number_and_event_type ON builds USING btree (repository_id, number, event_type);


--
-- Name: index_builds_on_request_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_builds_on_request_id ON builds USING btree (request_id);


--
-- Name: index_builds_on_state; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_builds_on_state ON builds USING btree (state);


--
-- Name: index_commits_on_repository_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_commits_on_repository_id ON commits USING btree (repository_id);


--
-- Name: index_emails_on_email; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_emails_on_email ON emails USING btree (email);


--
-- Name: index_emails_on_user_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_emails_on_user_id ON emails USING btree (user_id);


--
-- Name: index_invoices_on_stripe_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_invoices_on_stripe_id ON invoices USING btree (stripe_id);


--
-- Name: index_jobs_on_created_at; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_jobs_on_created_at ON jobs USING btree (created_at);


--
-- Name: index_jobs_on_owner_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_jobs_on_owner_id ON jobs USING btree (owner_id);


--
-- Name: index_jobs_on_owner_type; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_jobs_on_owner_type ON jobs USING btree (owner_type);


--
-- Name: index_jobs_on_queue; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_jobs_on_queue ON jobs USING btree (queue);


--
-- Name: index_jobs_on_queued_at; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_jobs_on_queued_at ON jobs USING btree (queued_at);


--
-- Name: index_jobs_on_repository_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_jobs_on_repository_id ON jobs USING btree (repository_id);


--
-- Name: index_jobs_on_source_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_jobs_on_source_id ON jobs USING btree (source_id);


--
-- Name: index_jobs_on_state; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_jobs_on_state ON jobs USING btree (state);


--
-- Name: index_log_parts_on_log_id_and_number; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_log_parts_on_log_id_and_number ON log_parts USING btree (log_id, number);


--
-- Name: index_logs_on_archive_verified; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_logs_on_archive_verified ON logs USING btree (archive_verified);


--
-- Name: index_logs_on_archived_at; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_logs_on_archived_at ON logs USING btree (archived_at);


--
-- Name: index_logs_on_job_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_logs_on_job_id ON logs USING btree (job_id);


--
-- Name: index_memberships_on_user_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_memberships_on_user_id ON memberships USING btree (user_id);


--
-- Name: index_organizations_on_github_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_organizations_on_github_id ON organizations USING btree (github_id);


--
-- Name: index_organizations_on_login; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_organizations_on_login ON organizations USING btree (login);


--
-- Name: index_organizations_on_lower_login; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_organizations_on_lower_login ON organizations USING btree (lower((login)::text));


--
-- Name: index_permissions_on_repository_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_permissions_on_repository_id ON permissions USING btree (repository_id);


--
-- Name: index_permissions_on_user_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_permissions_on_user_id ON permissions USING btree (user_id);


--
-- Name: index_repositories_on_active; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_repositories_on_active ON repositories USING btree (active);


--
-- Name: index_repositories_on_github_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_repositories_on_github_id ON repositories USING btree (github_id);


--
-- Name: index_repositories_on_lower_name; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_repositories_on_lower_name ON repositories USING btree (lower((name)::text));


--
-- Name: index_repositories_on_lower_owner_name; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_repositories_on_lower_owner_name ON repositories USING btree (lower((owner_name)::text));


--
-- Name: index_repositories_on_name; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_repositories_on_name ON repositories USING btree (name);


--
-- Name: index_repositories_on_owner_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_repositories_on_owner_id ON repositories USING btree (owner_id);


--
-- Name: index_repositories_on_owner_name; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_repositories_on_owner_name ON repositories USING btree (owner_name);


--
-- Name: index_repositories_on_owner_type; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_repositories_on_owner_type ON repositories USING btree (owner_type);


--
-- Name: index_repositories_on_slug; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_repositories_on_slug ON repositories USING gin (((((owner_name)::text || '/'::text) || (name)::text)) gin_trgm_ops);


--
-- Name: index_requests_on_commit_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_requests_on_commit_id ON requests USING btree (commit_id);


--
-- Name: index_requests_on_created_at; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_requests_on_created_at ON requests USING btree (created_at);


--
-- Name: index_requests_on_head_commit; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_requests_on_head_commit ON requests USING btree (head_commit);


--
-- Name: index_requests_on_repository_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_requests_on_repository_id ON requests USING btree (repository_id);


--
-- Name: index_ssl_key_on_repository_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_ssl_key_on_repository_id ON ssl_keys USING btree (repository_id);


--
-- Name: index_stars_on_user_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_stars_on_user_id ON stars USING btree (user_id);


--
-- Name: index_stars_on_user_id_and_repository_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_stars_on_user_id_and_repository_id ON stars USING btree (user_id, repository_id);


--
-- Name: index_stripe_events_on_date; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_stripe_events_on_date ON stripe_events USING btree (date);


--
-- Name: index_stripe_events_on_event_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_stripe_events_on_event_id ON stripe_events USING btree (event_id);


--
-- Name: index_stripe_events_on_event_type; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_stripe_events_on_event_type ON stripe_events USING btree (event_type);


--
-- Name: index_tokens_on_token; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_tokens_on_token ON tokens USING btree (token);


--
-- Name: index_tokens_on_user_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_tokens_on_user_id ON tokens USING btree (user_id);


--
-- Name: index_users_on_github_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_users_on_github_id ON users USING btree (github_id);


--
-- Name: index_users_on_github_oauth_token; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_users_on_github_oauth_token ON users USING btree (github_oauth_token);


--
-- Name: index_users_on_login; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_users_on_login ON users USING btree (login);


--
-- Name: index_users_on_lower_login; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_users_on_lower_login ON users USING btree (lower((login)::text));


--
-- Name: unique_schema_migrations; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX unique_schema_migrations ON schema_migrations USING btree (version);


--
-- Name: fk_repositories_current_build_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY repositories
    ADD CONSTRAINT fk_repositories_current_build_id FOREIGN KEY (current_build_id) REFERENCES builds(id);


--
-- Name: log_parts_log_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY log_parts
    ADD CONSTRAINT log_parts_log_id_fk FOREIGN KEY (log_id) REFERENCES logs(id);


--
-- PostgreSQL database dump complete
--

SET search_path TO "$user",public;

INSERT INTO schema_migrations (version) VALUES ('20101126174706');

INSERT INTO schema_migrations (version) VALUES ('20101126174715');

INSERT INTO schema_migrations (version) VALUES ('20110109130532');

INSERT INTO schema_migrations (version) VALUES ('20110116155100');

INSERT INTO schema_migrations (version) VALUES ('20110130102621');

INSERT INTO schema_migrations (version) VALUES ('20110301071656');

INSERT INTO schema_migrations (version) VALUES ('20110316174721');

INSERT INTO schema_migrations (version) VALUES ('20110321075539');

INSERT INTO schema_migrations (version) VALUES ('20110411171936');

INSERT INTO schema_migrations (version) VALUES ('20110411171937');

INSERT INTO schema_migrations (version) VALUES ('20110411172518');

INSERT INTO schema_migrations (version) VALUES ('20110413101057');

INSERT INTO schema_migrations (version) VALUES ('20110414131100');

INSERT INTO schema_migrations (version) VALUES ('20110503150504');

INSERT INTO schema_migrations (version) VALUES ('20110523012243');

INSERT INTO schema_migrations (version) VALUES ('20110611203537');

INSERT INTO schema_migrations (version) VALUES ('20110613210252');

INSERT INTO schema_migrations (version) VALUES ('20110615152003');

INSERT INTO schema_migrations (version) VALUES ('20110616211744');

INSERT INTO schema_migrations (version) VALUES ('20110617114728');

INSERT INTO schema_migrations (version) VALUES ('20110619100906');

INSERT INTO schema_migrations (version) VALUES ('20110729094426');

INSERT INTO schema_migrations (version) VALUES ('20110801161819');

INSERT INTO schema_migrations (version) VALUES ('20110805030147');

INSERT INTO schema_migrations (version) VALUES ('20110819232908');

INSERT INTO schema_migrations (version) VALUES ('20110911204538');

INSERT INTO schema_migrations (version) VALUES ('20111107134436');

INSERT INTO schema_migrations (version) VALUES ('20111107134437');

INSERT INTO schema_migrations (version) VALUES ('20111107134438');

INSERT INTO schema_migrations (version) VALUES ('20111107134439');

INSERT INTO schema_migrations (version) VALUES ('20111107134440');

INSERT INTO schema_migrations (version) VALUES ('20111128235043');

INSERT INTO schema_migrations (version) VALUES ('20111129014329');

INSERT INTO schema_migrations (version) VALUES ('20111129022625');

INSERT INTO schema_migrations (version) VALUES ('20111201113500');

INSERT INTO schema_migrations (version) VALUES ('20111203002341');

INSERT INTO schema_migrations (version) VALUES ('20111203221720');

INSERT INTO schema_migrations (version) VALUES ('20111207093700');

INSERT INTO schema_migrations (version) VALUES ('20111212103859');

INSERT INTO schema_migrations (version) VALUES ('20111212112411');

INSERT INTO schema_migrations (version) VALUES ('20111214173922');

INSERT INTO schema_migrations (version) VALUES ('20120114125404');

INSERT INTO schema_migrations (version) VALUES ('20120216133223');

INSERT INTO schema_migrations (version) VALUES ('20120222082522');

INSERT INTO schema_migrations (version) VALUES ('20120301131209');

INSERT INTO schema_migrations (version) VALUES ('20120304000502');

INSERT INTO schema_migrations (version) VALUES ('20120304000503');

INSERT INTO schema_migrations (version) VALUES ('20120304000504');

INSERT INTO schema_migrations (version) VALUES ('20120304000505');

INSERT INTO schema_migrations (version) VALUES ('20120304000506');

INSERT INTO schema_migrations (version) VALUES ('20120311234933');

INSERT INTO schema_migrations (version) VALUES ('20120316123726');

INSERT INTO schema_migrations (version) VALUES ('20120319170001');

INSERT INTO schema_migrations (version) VALUES ('20120324104051');

INSERT INTO schema_migrations (version) VALUES ('20120505165100');

INSERT INTO schema_migrations (version) VALUES ('20120511171900');

INSERT INTO schema_migrations (version) VALUES ('20120521174400');

INSERT INTO schema_migrations (version) VALUES ('20120527235800');

INSERT INTO schema_migrations (version) VALUES ('20120702111126');

INSERT INTO schema_migrations (version) VALUES ('20120703114226');

INSERT INTO schema_migrations (version) VALUES ('20120713140816');

INSERT INTO schema_migrations (version) VALUES ('20120713153215');

INSERT INTO schema_migrations (version) VALUES ('20120725005300');

INSERT INTO schema_migrations (version) VALUES ('201207261749');

INSERT INTO schema_migrations (version) VALUES ('20120727151900');

INSERT INTO schema_migrations (version) VALUES ('20120731005301');

INSERT INTO schema_migrations (version) VALUES ('20120731074000');

INSERT INTO schema_migrations (version) VALUES ('20120802001001');

INSERT INTO schema_migrations (version) VALUES ('20120803164000');

INSERT INTO schema_migrations (version) VALUES ('20120803182300');

INSERT INTO schema_migrations (version) VALUES ('20120804122700');

INSERT INTO schema_migrations (version) VALUES ('20120806120400');

INSERT INTO schema_migrations (version) VALUES ('20120820164000');

INSERT INTO schema_migrations (version) VALUES ('20120905093300');

INSERT INTO schema_migrations (version) VALUES ('20120905171300');

INSERT INTO schema_migrations (version) VALUES ('20120911160000');

INSERT INTO schema_migrations (version) VALUES ('20120911230000');

INSERT INTO schema_migrations (version) VALUES ('20120911230001');

INSERT INTO schema_migrations (version) VALUES ('20120913143800');

INSERT INTO schema_migrations (version) VALUES ('20120915012000');

INSERT INTO schema_migrations (version) VALUES ('20120915012001');

INSERT INTO schema_migrations (version) VALUES ('20120915150000');

INSERT INTO schema_migrations (version) VALUES ('20121015002500');

INSERT INTO schema_migrations (version) VALUES ('20121015002501');

INSERT INTO schema_migrations (version) VALUES ('20121017040100');

INSERT INTO schema_migrations (version) VALUES ('20121017040200');

INSERT INTO schema_migrations (version) VALUES ('20121018201301');

INSERT INTO schema_migrations (version) VALUES ('20121018203728');

INSERT INTO schema_migrations (version) VALUES ('20121018210156');

INSERT INTO schema_migrations (version) VALUES ('20121125122700');

INSERT INTO schema_migrations (version) VALUES ('20121125122701');

INSERT INTO schema_migrations (version) VALUES ('20121222125200');

INSERT INTO schema_migrations (version) VALUES ('20121222125300');

INSERT INTO schema_migrations (version) VALUES ('20121222140200');

INSERT INTO schema_migrations (version) VALUES ('20121223162300');

INSERT INTO schema_migrations (version) VALUES ('20130107165057');

INSERT INTO schema_migrations (version) VALUES ('20130115125836');

INSERT INTO schema_migrations (version) VALUES ('20130115145728');

INSERT INTO schema_migrations (version) VALUES ('20130125002600');

INSERT INTO schema_migrations (version) VALUES ('20130125171100');

INSERT INTO schema_migrations (version) VALUES ('20130129142703');

INSERT INTO schema_migrations (version) VALUES ('20130207030700');

INSERT INTO schema_migrations (version) VALUES ('20130207030701');

INSERT INTO schema_migrations (version) VALUES ('20130208124253');

INSERT INTO schema_migrations (version) VALUES ('20130208135800');

INSERT INTO schema_migrations (version) VALUES ('20130208135801');

INSERT INTO schema_migrations (version) VALUES ('20130208215252');

INSERT INTO schema_migrations (version) VALUES ('20130306154311');

INSERT INTO schema_migrations (version) VALUES ('20130311211101');

INSERT INTO schema_migrations (version) VALUES ('20130327100801');

INSERT INTO schema_migrations (version) VALUES ('20130418101437');

INSERT INTO schema_migrations (version) VALUES ('20130418103306');

INSERT INTO schema_migrations (version) VALUES ('20130504230850');

INSERT INTO schema_migrations (version) VALUES ('20130505023259');

INSERT INTO schema_migrations (version) VALUES ('20130521115725');

INSERT INTO schema_migrations (version) VALUES ('20130521133050');

INSERT INTO schema_migrations (version) VALUES ('20130521134224');

INSERT INTO schema_migrations (version) VALUES ('20130521134800');

INSERT INTO schema_migrations (version) VALUES ('20130521141357');

INSERT INTO schema_migrations (version) VALUES ('20130618084205');

INSERT INTO schema_migrations (version) VALUES ('20130629122945');

INSERT INTO schema_migrations (version) VALUES ('20130629133531');

INSERT INTO schema_migrations (version) VALUES ('20130629174449');

INSERT INTO schema_migrations (version) VALUES ('20130701123456');

INSERT INTO schema_migrations (version) VALUES ('20130701175200');

INSERT INTO schema_migrations (version) VALUES ('20130702123456');

INSERT INTO schema_migrations (version) VALUES ('20130702144325');

INSERT INTO schema_migrations (version) VALUES ('20130705123456');

INSERT INTO schema_migrations (version) VALUES ('20130707164854');

INSERT INTO schema_migrations (version) VALUES ('20130709185200');

INSERT INTO schema_migrations (version) VALUES ('20130709233500');

INSERT INTO schema_migrations (version) VALUES ('20130710000745');

INSERT INTO schema_migrations (version) VALUES ('20130726101124');

INSERT INTO schema_migrations (version) VALUES ('20130901183019');

INSERT INTO schema_migrations (version) VALUES ('20130909203321');

INSERT INTO schema_migrations (version) VALUES ('20130910184823');

INSERT INTO schema_migrations (version) VALUES ('20130916101056');

INSERT INTO schema_migrations (version) VALUES ('20130920135744');

INSERT INTO schema_migrations (version) VALUES ('20131104101056');

INSERT INTO schema_migrations (version) VALUES ('20131109101056');

INSERT INTO schema_migrations (version) VALUES ('20140120225125');

INSERT INTO schema_migrations (version) VALUES ('20140121003026');

INSERT INTO schema_migrations (version) VALUES ('20140204220926');

INSERT INTO schema_migrations (version) VALUES ('20140210003014');

INSERT INTO schema_migrations (version) VALUES ('20140210012509');

INSERT INTO schema_migrations (version) VALUES ('20140612131826');

INSERT INTO schema_migrations (version) VALUES ('20140827121945');

INSERT INTO schema_migrations (version) VALUES ('20150121135400');

INSERT INTO schema_migrations (version) VALUES ('20150121135401');

INSERT INTO schema_migrations (version) VALUES ('20150204144312');

INSERT INTO schema_migrations (version) VALUES ('20150210170900');

INSERT INTO schema_migrations (version) VALUES ('20150223125700');

INSERT INTO schema_migrations (version) VALUES ('20150311020321');

INSERT INTO schema_migrations (version) VALUES ('20150316020321');

INSERT INTO schema_migrations (version) VALUES ('20150316080321');

INSERT INTO schema_migrations (version) VALUES ('20150316100321');

INSERT INTO schema_migrations (version) VALUES ('20150317004600');

INSERT INTO schema_migrations (version) VALUES ('20150317020321');

INSERT INTO schema_migrations (version) VALUES ('20150317080321');

INSERT INTO schema_migrations (version) VALUES ('20150414001337');

INSERT INTO schema_migrations (version) VALUES ('20150528101600');

INSERT INTO schema_migrations (version) VALUES ('20150528101601');

INSERT INTO schema_migrations (version) VALUES ('20150528101602');

INSERT INTO schema_migrations (version) VALUES ('20150528101603');

INSERT INTO schema_migrations (version) VALUES ('20150528101604');

INSERT INTO schema_migrations (version) VALUES ('20150528101605');

INSERT INTO schema_migrations (version) VALUES ('20150528101607');

INSERT INTO schema_migrations (version) VALUES ('20150528101608');

INSERT INTO schema_migrations (version) VALUES ('20150528101609');

INSERT INTO schema_migrations (version) VALUES ('20150528101610');

INSERT INTO schema_migrations (version) VALUES ('20150528101611');

INSERT INTO schema_migrations (version) VALUES ('20150609175200');

INSERT INTO schema_migrations (version) VALUES ('20150610143500');

INSERT INTO schema_migrations (version) VALUES ('20150610143501');

INSERT INTO schema_migrations (version) VALUES ('20150610143502');

INSERT INTO schema_migrations (version) VALUES ('20150610143503');

INSERT INTO schema_migrations (version) VALUES ('20150610143504');

INSERT INTO schema_migrations (version) VALUES ('20150610143505');

INSERT INTO schema_migrations (version) VALUES ('20150610143506');

INSERT INTO schema_migrations (version) VALUES ('20150610143507');

INSERT INTO schema_migrations (version) VALUES ('20150610143508');

INSERT INTO schema_migrations (version) VALUES ('20150610143509');

INSERT INTO schema_migrations (version) VALUES ('20150610143510');

INSERT INTO schema_migrations (version) VALUES ('20150615103059');

INSERT INTO schema_migrations (version) VALUES ('20150629231300');

INSERT INTO schema_migrations (version) VALUES ('20150923131400');

INSERT INTO schema_migrations (version) VALUES ('20151112153500');

INSERT INTO schema_migrations (version) VALUES ('20151113111400');

INSERT INTO schema_migrations (version) VALUES ('20151127153500');

INSERT INTO schema_migrations (version) VALUES ('20151127154200');

INSERT INTO schema_migrations (version) VALUES ('20151127154600');

INSERT INTO schema_migrations (version) VALUES ('20151202122200');

INSERT INTO schema_migrations (version) VALUES ('20160107120927');

INSERT INTO schema_migrations (version) VALUES ('20160303165750');

INSERT INTO schema_migrations (version) VALUES ('20160412113020');

INSERT INTO schema_migrations (version) VALUES ('20160412113070');

INSERT INTO schema_migrations (version) VALUES ('20160412121405');

INSERT INTO schema_migrations (version) VALUES ('20160412123900');

INSERT INTO schema_migrations (version) VALUES ('20160414214442');

INSERT INTO schema_migrations (version) VALUES ('20160422104300');

INSERT INTO schema_migrations (version) VALUES ('20160422121400');

INSERT INTO schema_migrations (version) VALUES ('20160510142700');

INSERT INTO schema_migrations (version) VALUES ('20160510144200');

INSERT INTO schema_migrations (version) VALUES ('20160510150300');

INSERT INTO schema_migrations (version) VALUES ('20160510150400');

INSERT INTO schema_migrations (version) VALUES ('20160513074300');