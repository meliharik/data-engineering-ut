-- Level 3: bulk load the static countries dataset with Postgres COPY.
-- COPY runs server side, so /data/countries.csv is a path inside the db
-- container (mounted read only by compose.yml).

TRUNCATE countries;

COPY countries (
    id, name, iso3, iso2, numeric_code, phonecode, capital,
    currency, currency_name, currency_symbol, tld, native,
    population, gdp, region, region_id, subregion, subregion_id,
    nationality, area_sq_km, postal_code_format, postal_code_regex,
    timezones, latitude, longitude, emoji, emoji_unicode, wikidata_id
)
FROM '/data/countries.csv'
WITH (FORMAT csv, HEADER true);

ANALYZE countries;
