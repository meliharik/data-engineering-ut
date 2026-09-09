-- Level 5: join the ingested users to the reference countries dataset.
--
-- The API returns a plausible looking but unusable coordinate pair for each
-- user, so the view keeps the reported values next to the reference centroid
-- of the matching country and exposes the corrected pair for downstream use.

CREATE OR REPLACE VIEW user_country_coordinates AS
SELECT
    u.id                             AS user_id,
    u.name_title,
    u.name_first,
    u.name_last,
    u.location_country               AS reported_country,
    c.name                           AS matched_country,
    c.iso2                           AS matched_country_iso2,
    u.location_coordinates_latitude  AS reported_latitude,
    u.location_coordinates_longitude AS reported_longitude,
    c.latitude                       AS country_latitude,
    c.longitude                      AS country_longitude,
    COALESCE(c.latitude,  u.location_coordinates_latitude)  AS corrected_latitude,
    COALESCE(c.longitude, u.location_coordinates_longitude) AS corrected_longitude,
    (c.id IS NOT NULL)               AS country_matched
FROM users AS u
-- LEFT JOIN keeps users whose country label has no counterpart in the
-- reference data, which makes the mismatches visible instead of silently
-- dropping rows.
LEFT JOIN countries AS c
       ON lower(btrim(u.location_country)) = lower(c.name);
