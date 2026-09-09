DROP VIEW IF EXISTS user_country_coordinates;
DROP TABLE IF EXISTS countries;

-- column order must match countries.csv for COPY
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

CREATE INDEX countries_name_lower_idx ON countries (lower(name));

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
