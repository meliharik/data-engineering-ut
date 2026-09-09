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
-- LEFT JOIN so unmatched country labels stay visible instead of vanishing
LEFT JOIN countries AS c
       ON lower(btrim(u.location_country)) = lower(c.name);
