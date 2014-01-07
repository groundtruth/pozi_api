-- settings

SET statement_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;

-- create database

DROP DATABASE IF EXISTS restful_geof_test;
CREATE DATABASE restful_geof_test WITH TEMPLATE = template0 ENCODING = 'UTF8' LC_COLLATE = 'C' LC_CTYPE = 'C';

-- spatially enable, etc.

\connect restful_geof_test

CREATE EXTENSION IF NOT EXISTS postgis WITH SCHEMA public;
COMMENT ON EXTENSION postgis IS 'PostGIS geometry, geography, and raster spatial types and functions';
SET search_path = public, pg_catalog;
REVOKE ALL ON SCHEMA public FROM PUBLIC;
GRANT ALL ON SCHEMA public TO PUBLIC;

-- spatial

CREATE TABLE spatial (
    id integer NOT NULL,
    the_geom geometry(Point,4326),
    name varchar,
    search_text TSVECTOR
);

CREATE SEQUENCE spatial_id_seq START WITH 1 INCREMENT BY 1 NO MINVALUE NO MAXVALUE CACHE 1;
ALTER SEQUENCE spatial_id_seq OWNED BY spatial.id;
ALTER TABLE ONLY spatial ALTER COLUMN id SET DEFAULT nextval('spatial_id_seq'::regclass);



INSERT INTO spatial (the_geom, name, search_text) VALUES (ST_GeomFromText('POINT(140.584379916592 -35.3419002991608)', 4326), 'first', to_tsvector('english', 'the first one'));
INSERT INTO spatial (the_geom, name, search_text) VALUES (ST_GeomFromText('POINT(141.584379916592 -36.3419002991608)', 4326), 'second', to_tsvector('english', 'second comes right after first'));
INSERT INTO spatial (the_geom, name, search_text) VALUES (ST_GeomFromText('POINT(142.584379916592 -37.3419002991608)', 4326), 'third', to_tsvector('english', 'the last non-null one is third'));
INSERT INTO spatial (the_geom, name, search_text) VALUES (ST_GeomFromText('POINT(143.584379916592 -38.3419002991608)', 4326), '123', to_tsvector('english', 'string field with only digits in it'));
INSERT INTO spatial (the_geom, name, search_text) VALUES (NULL, 'no geometry', NULL);

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

-- unusual characters

CREATE TABLE strange_string_table (
    id integer NOT NULL,
    str varchar
);

CREATE SEQUENCE strange_string_table_id_seq START WITH 1 INCREMENT BY 1 NO MINVALUE NO MAXVALUE CACHE 1;
ALTER SEQUENCE strange_string_table_id_seq OWNED BY strange_string_table.id;
ALTER TABLE ONLY strange_string_table ALTER COLUMN id SET DEFAULT nextval('strange_string_table_id_seq'::regclass);

INSERT INTO strange_string_table (str) VALUES ('–');

-- LIKE search

CREATE TABLE string_table (
    id integer NOT NULL,
    name varchar
);

CREATE SEQUENCE string_table_id_seq START WITH 1 INCREMENT BY 1 NO MINVALUE NO MAXVALUE CACHE 1;
ALTER SEQUENCE string_table_id_seq OWNED BY string_table.id;
ALTER TABLE ONLY string_table ALTER COLUMN id SET DEFAULT nextval('string_table_id_seq'::regclass);

INSERT INTO string_table (name) VALUES ('1/22 Wills Street');
INSERT INTO string_table (name) VALUES ('22 Wills St');
INSERT INTO string_table (name) VALUES ('22 Wills Other St');
INSERT INTO string_table (name) VALUES ('666 Wrongsideofthe Tracks');

