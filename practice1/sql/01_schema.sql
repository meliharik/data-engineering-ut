-- Level 3 and level 4: target tables.
--
-- Both tables are created explicitly instead of letting a dataframe library
-- infer them, because inference turns identifiers such as postcodes into
-- integers and drops their leading zeros.

DROP VIEW IF EXISTS user_country_coordinates;

-- Mirrors the column order of the upstream countries.csv, which is required
-- by COPY. Source: github.com/dr5hn/countries-states-cities-database
DROP TABLE IF EXISTS countries;

CREATE TABLE countries (
    id                 INTEGER PRIMARY KEY,
    name               TEXT NOT NULL,
    iso3               CHAR(3),
    iso2               CHAR(2),
    numeric_code       TEXT,
    phonecode          TEXT,
    capital            TEXT,
    currency           TEXT,
    currency_name      TEXT,
    currency_symbol    TEXT,
    tld                TEXT,
    native             TEXT,
    population         BIGINT,
    gdp                BIGINT,
    region             TEXT,
    region_id          INTEGER,
    subregion          TEXT,
    subregion_id       INTEGER,
    nationality        TEXT,
    area_sq_km         NUMERIC,
    postal_code_format TEXT,
    postal_code_regex  TEXT,
    timezones          TEXT,
    latitude           NUMERIC(11, 8),
    longitude          NUMERIC(12, 8),
    emoji              TEXT,
    emoji_unicode      TEXT,
    wikidata_id        TEXT
);

-- numeric_code and phonecode stay TEXT on purpose: they are identifiers with
-- meaningful leading zeros ("004"), not quantities.

CREATE INDEX countries_name_lower_idx ON countries (lower(name));

-- Flattened subset of the randomuser.me payload. Nested objects are collapsed
-- with "_", so results[0].location.coordinates.latitude becomes
-- location_coordinates_latitude.
CREATE TABLE IF NOT EXISTS users (
    id                             BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name_title                     TEXT,
    name_first                     TEXT,
    name_last                      TEXT,
    location_street_number         INTEGER,
    location_street_name           TEXT,
    location_city                  TEXT,
    location_state                 TEXT,
    location_country               TEXT,
    location_postcode              TEXT,
    location_coordinates_latitude  NUMERIC(11, 8),
    location_coordinates_longitude NUMERIC(12, 8),
    location_timezone_offset       TEXT,
    location_timezone_description  TEXT,
    ingested_at                    TIMESTAMPTZ NOT NULL DEFAULT now()
);
