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

-- spatial

CREATE TABLE spatial (
    id integer NOT NULL,
    the_geom geometry(Point,4326),
    name varchar
);

CREATE SEQUENCE spatial_id_seq START WITH 1 INCREMENT BY 1 NO MINVALUE NO MAXVALUE CACHE 1;
ALTER SEQUENCE spatial_id_seq OWNED BY spatial.id;
ALTER TABLE ONLY spatial ALTER COLUMN id SET DEFAULT nextval('spatial_id_seq'::regclass);

INSERT INTO spatial (the_geom, name) VALUES ('0101000020E610000074C6823DB3F26140B9B19563C32B43C0', 'first');
INSERT INTO spatial (the_geom, name) VALUES ('0101000020E610000074C6823DB3F26140B9B19563C32B43C0', 'second');
INSERT INTO spatial (the_geom, name) VALUES ('0101000020E610000074C6823DB3F26140B9B19563C32B43C0', 'third');
INSERT INTO spatial (the_geom, name) VALUES (NULL, 'no geometry');

ALTER TABLE ONLY spatial ADD CONSTRAINT pk_spatial PRIMARY KEY (id);

-- other SRID

CREATE TABLE other_srid (
    id integer NOT NULL,
    the_geom geometry(Point,3857),
    name varchar
);

CREATE SEQUENCE other_srid_id_seq START WITH 1 INCREMENT BY 1 NO MINVALUE NO MAXVALUE CACHE 1;
ALTER SEQUENCE other_srid_id_seq OWNED BY other_srid.id;
ALTER TABLE ONLY other_srid ALTER COLUMN id SET DEFAULT nextval('other_srid_id_seq'::regclass);

INSERT INTO other_srid (the_geom, name) VALUES ('0101000020110F0000000000808F7C6E41000000805FA751C1', 'first');

ALTER TABLE ONLY other_srid ADD CONSTRAINT pk_other_srid PRIMARY KEY (id);

-- empty table

CREATE TABLE empty (
    id integer NOT NULL,
    the_geom geometry(Point,4326),
    name varchar
);

-- non-spatial

CREATE TABLE non_spatial (
    id integer NOT NULL,
    name varchar
);

CREATE SEQUENCE non_spatial_id_seq START WITH 1 INCREMENT BY 1 NO MINVALUE NO MAXVALUE CACHE 1;
ALTER SEQUENCE non_spatial_id_seq OWNED BY non_spatial.id;
ALTER TABLE ONLY non_spatial ALTER COLUMN id SET DEFAULT nextval('non_spatial_id_seq'::regclass);

INSERT INTO non_spatial (name) VALUES ('first');
INSERT INTO non_spatial (name) VALUES ('second');
