-- settings

SET statement_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;

-- create database

DROP DATABASE IF EXISTS pozi_api_test;
CREATE DATABASE pozi_api_test WITH TEMPLATE = template0 ENCODING = 'UTF8' LC_COLLATE = 'C' LC_CTYPE = 'C';

-- spatially enable, etc.

\connect pozi_api_test

CREATE EXTENSION IF NOT EXISTS postgis WITH SCHEMA public;
COMMENT ON EXTENSION postgis IS 'PostGIS geometry, geography, and raster spatial types and functions';
SET search_path = public, pg_catalog;
REVOKE ALL ON SCHEMA public FROM PUBLIC;
GRANT ALL ON SCHEMA public TO PUBLIC;

-- create structure

CREATE TABLE test_data (
    id integer NOT NULL,
    the_geom geometry(Point,4326),
    name varchar
);

CREATE SEQUENCE pozi_api_test_id_seq START WITH 1 INCREMENT BY 1 NO MINVALUE NO MAXVALUE CACHE 1;
ALTER SEQUENCE pozi_api_test_id_seq OWNED BY test_data.id;
ALTER TABLE ONLY test_data ALTER COLUMN id SET DEFAULT nextval('pozi_api_test_id_seq'::regclass);

-- load data

INSERT INTO test_data (the_geom, name) VALUES ('0101000020E610000074C6823DB3F26140B9B19563C32B43C0', 'first');
INSERT INTO test_data (the_geom, name) VALUES ('0101000020E610000074C6823DB3F26140B9B19563C32B43C0', 'second');
INSERT INTO test_data (the_geom, name) VALUES ('0101000020E610000074C6823DB3F26140B9B19563C32B43C0', 'third');
INSERT INTO test_data (the_geom, name) VALUES ('0101000020E610000074C6823DB3F26140B9B19563C32B43C0', 'fourth');
INSERT INTO test_data (the_geom, name) VALUES ('0101000020E610000074C6823DB3F26140B9B19563C32B43C0', 'fifth');

-- set constraints

ALTER TABLE ONLY test_data ADD CONSTRAINT pk_pozi_api_test PRIMARY KEY (id);

