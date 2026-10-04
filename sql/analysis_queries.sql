CREATE TABLE satellites_raw (
    satellite_name TEXT,
    country TEXT,
    operator TEXT,
    orbit_class TEXT,
    perigee_km NUMERIC,
    apogee_km NUMERIC,
    eccentricity NUMERIC,
    inclination_deg NUMERIC,
    orbital_period_min NUMERIC,
    launch_date DATE,
    norad_number TEXT,
    cospar_number TEXT,
    status TEXT,
    active BOOLEAN,
    source TEXT
);

SELECT * FROM satellites_raw

DROP TABLE IF EXISTS satellites_raw;
CREATE TABLE satellites_raw (
    satellite_name TEXT,
    country TEXT,
    operator TEXT,
    orbit_class TEXT,
    perigee_km NUMERIC,
    apogee_km NUMERIC,
    eccentricity NUMERIC,
    inclination_deg NUMERIC,
    orbital_period_min NUMERIC,
    launch_date DATE,
    cospar_number TEXT,
    norad_number TEXT,
    object_class TEXT,
    operational_status TEXT,
    active BOOLEAN
);

SELECT COUNT(*) AS total_rows
FROM satellites_raw;

SELECT 
    COUNT(*) AS total_rows,
    COUNT(DISTINCT (
        satellite_name,
        country,
        operator,
        orbit_class,
        perigee_km,
        apogee_km,
        eccentricity,
        inclination_deg,
        orbital_period_min,
        launch_date,
        cospar_number,
        norad_number,
        object_class,
        operational_status,
        active
    )) AS unique_rows
FROM satellites_raw;

SELECT 
    norad_number,
    COUNT(*) AS occurrences
FROM satellites_raw
WHERE norad_number IS NOT NULL
GROUP BY norad_number
HAVING COUNT(*) > 1
ORDER BY occurrences DESC;

SELECT
    COUNT(*) FILTER (WHERE satellite_name IS NULL) AS satellite_name_missing,
    COUNT(*) FILTER (WHERE country IS NULL) AS country_missing,
    COUNT(*) FILTER (WHERE operator IS NULL) AS operator_missing,
    COUNT(*) FILTER (WHERE orbit_class IS NULL) AS orbit_class_missing,
    COUNT(*) FILTER (WHERE perigee_km IS NULL) AS perigee_missing,
    COUNT(*) FILTER (WHERE apogee_km IS NULL) AS apogee_missing,
    COUNT(*) FILTER (WHERE eccentricity IS NULL) AS eccentricity_missing,
    COUNT(*) FILTER (WHERE inclination_deg IS NULL) AS inclination_missing,
    COUNT(*) FILTER (WHERE orbital_period_min IS NULL) AS period_missing,
    COUNT(*) FILTER (WHERE launch_date IS NULL) AS launch_date_missing,
    COUNT(*) FILTER (WHERE cospar_number IS NULL) AS cospar_missing,
    COUNT(*) FILTER (WHERE norad_number IS NULL) AS norad_missing,
    COUNT(*) FILTER (WHERE object_class IS NULL) AS object_class_missing,
    COUNT(*) FILTER (WHERE operational_status IS NULL) AS status_missing,
    COUNT(*) FILTER (WHERE active IS NULL) AS active_missing
FROM satellites_raw;


SELECT
    satellite_name,
    country,
    operator,
    orbit_class,
    object_class,
    operational_status,
    active
FROM satellites_raw
WHERE country IS NULL
   OR operator IS NULL;

SELECT
    COUNT(*) FILTER (
        WHERE country IS NULL AND operator IS NULL
    ) AS both_missing,

    COUNT(*) FILTER (
        WHERE country IS NULL AND operator IS NOT NULL
    ) AS country_only_missing,

    COUNT(*) FILTER (
        WHERE country IS NOT NULL AND operator IS NULL
    ) AS operator_only_missing
FROM satellites_raw;

SELECT
    object_class,
    COUNT(*) AS records
FROM satellites_raw
WHERE country IS NULL
  AND operator IS NULL
GROUP BY object_class
ORDER BY records DESC;

SELECT
    COUNT(*) FILTER (WHERE launch_date IS NULL) AS launch_date_missing,
    COUNT(*) FILTER (WHERE launch_date IS NOT NULL) AS launch_date_available
FROM satellites_raw
WHERE country IS NULL
  AND operator IS NULL;

SELECT
    orbit_class,
    COUNT(*) AS records
FROM satellites_raw
GROUP BY orbit_class
ORDER BY records DESC;

SELECT
    object_class,
    COUNT(*) AS records
FROM satellites_raw
GROUP BY object_class
ORDER BY records DESC;

SELECT
    operational_status,
    COUNT(*) AS records
FROM satellites_raw
GROUP BY operational_status
ORDER BY records DESC;

SELECT
    MIN(perigee_km) AS minimum_perigee,
    MAX(perigee_km) AS maximum_perigee
FROM satellites_raw;

SELECT
    satellite_name,
    orbit_class,
    object_class,
    perigee_km,
    apogee_km,
    eccentricity
FROM satellites_raw
WHERE perigee_km < 0
   OR perigee_km > 100000
ORDER BY perigee_km;

SELECT COUNT(*) AS negative_perigee_records
FROM satellites_raw
WHERE perigee_km < 0;

SELECT COUNT(*) AS high_perigee_records
FROM satellites_raw
WHERE perigee_km > 100000;

SELECT
    MIN(apogee_km) AS minimum_apogee,
    MAX(apogee_km) AS maximum_apogee
FROM satellites_raw;

SELECT
    COUNT(*) AS invalid_orbit_records
FROM satellites_raw
WHERE apogee_km < perigee_km;

SELECT
    MIN(eccentricity) AS minimum_eccentricity,
    MAX(eccentricity) AS maximum_eccentricity
FROM satellites_raw;

SELECT
    MIN(inclination_deg) AS minimum_inclination,
    MAX(inclination_deg) AS maximum_inclination
FROM satellites_raw;

SELECT
    MIN(orbital_period_min) AS minimum_period,
    MAX(orbital_period_min) AS maximum_period
FROM satellites_raw;

SELECT
    MIN(launch_date) AS earliest_launch,
    MAX(launch_date) AS latest_launch
FROM satellites_raw;

SELECT
    COUNT(*) AS total_records,
    COUNT(launch_date) AS valid_dates,
    COUNT(*) FILTER (WHERE launch_date IS NULL) AS missing_dates,
    COUNT(*) FILTER (WHERE launch_date > CURRENT_DATE) AS future_dates
FROM satellites_raw;

--MAKING THE CLEAN TABLE
CREATE TABLE satellites_clean AS
SELECT
    satellite_name,
    COALESCE(country, 'Unknown') AS country,
    COALESCE(operator, 'Unknown') AS operator,
    orbit_class,
    perigee_km,
    apogee_km,
    eccentricity,
    inclination_deg,
    orbital_period_min,
    launch_date,
    cospar_number,
    norad_number,
    object_class,
    operational_status,
    active
FROM satellites_raw;

SELECT COUNT(*) AS total_records
FROM satellites_clean;

--Created launch_year for easier year-wise analysis of satellite launches.
ALTER TABLE satellites_clean
ADD COLUMN launch_year INTEGER;

UPDATE satellites_clean
SET launch_year = EXTRACT(YEAR FROM launch_date)::INTEGER;

SELECT
    COUNT(*) AS total_records,
    COUNT(launch_year) AS year_filled,
    MIN(launch_year) AS earliest_year,
    MAX(launch_year) AS latest_year
FROM satellites_clean;

ALTER TABLE satellites_clean
ADD COLUMN launch_decade INTEGER;

--Grouped satellite launches into decades to simplify long-term trend analysis.
UPDATE satellites_clean
SET launch_decade = (launch_year / 10) * 10;

SELECT
    COUNT(*) AS total_records,
    COUNT(launch_decade) AS decade_filled,
    MIN(launch_decade) AS earliest_decade,
    MAX(launch_decade) AS latest_decade
FROM satellites_clean;

--Added a flag to identify suspicious perigee values without altering the original data.
ALTER TABLE satellites_clean
ADD COLUMN perigee_flag TEXT;

UPDATE satellites_clean
SET perigee_flag =
    CASE
        WHEN perigee_km < 0
          OR perigee_km > 100000
        THEN 'Suspicious'
        ELSE 'Valid'
    END;

SELECT
    perigee_flag,
    COUNT(*) AS records
FROM satellites_clean
GROUP BY perigee_flag
ORDER BY perigee_flag;

ALTER TABLE satellites_clean
ADD COLUMN orbit_group TEXT;

UPDATE satellites_clean
SET orbit_group =
    CASE
        WHEN orbit_class IN ('LEO', 'VLEO', 'SSO') THEN 'Low Earth Orbit'
        WHEN orbit_class = 'MEO' THEN 'Medium Earth Orbit'
        WHEN orbit_class = 'GEO' THEN 'Geostationary Orbit'
        WHEN orbit_class = 'HEO' THEN 'Highly Elliptical Orbit'
        ELSE 'Unknown'
    END;
	
SELECT
    orbit_group,
    COUNT(*) AS records
FROM satellites_clean
GROUP BY orbit_group
ORDER BY records DESC;

SELECT
    country,
    COUNT(*) AS satellite_count
FROM satellites_clean
GROUP BY country
ORDER BY satellite_count DESC
LIMIT 10;
--We have total of 94 countries in this data out of which 313 are unknown

SELECT
    operator,
    COUNT(*) AS satellite_count
FROM satellites_clean
GROUP BY operator
ORDER BY satellite_count DESC
LIMIT 10;
--We have total of 868 operators in this data out of which 313 are unknown

SELECT
    LOWER(TRIM(operator)) AS normalized_operator,
    COUNT(DISTINCT operator) AS name_variations,
    COUNT(*) AS total_records
FROM satellites_clean
GROUP BY LOWER(TRIM(operator))
HAVING COUNT(DISTINCT operator) > 1
ORDER BY name_variations DESC, total_records DESC;

SELECT
    launch_year,
    COUNT(*) AS satellites_launched
FROM satellites_clean
GROUP BY launch_year
ORDER BY launch_year;

SELECT
    SUM(satellites_launched) AS total_from_years
FROM (
    SELECT
        launch_year,
        COUNT(*) AS satellites_launched
    FROM satellites_clean
    GROUP BY launch_year
) AS yearly_data;

SELECT
    launch_decade,
    COUNT(*) AS satellite_records
FROM satellites_clean
GROUP BY launch_decade
ORDER BY launch_decade;

SELECT
    orbit_group,
    COUNT(*) AS satellite_records
FROM satellites_clean
GROUP BY orbit_group
ORDER BY satellite_records DESC;

SELECT
    operational_status,
    COUNT(*) AS satellite_records
FROM satellites_clean
GROUP BY operational_status
ORDER BY satellite_records DESC;

SELECT
    operational_status,
    active,
    COUNT(*) AS records
FROM satellites_clean
GROUP BY operational_status, active
ORDER BY operational_status, active;

SELECT
    operational_status,
    COUNT(*) AS records
FROM satellites_clean
WHERE active = true
GROUP BY operational_status
ORDER BY records DESC;

SELECT
    active,
    COUNT(*) AS records
FROM satellites_clean
GROUP BY active
ORDER BY active DESC;

SELECT
    country,
    orbit_group,
    COUNT(*) AS satellite_records
FROM satellites_clean
GROUP BY country, orbit_group
ORDER BY country, satellite_records DESC;


WITH top_countries AS (
    SELECT
        country,
        COUNT(*) AS total_records
    FROM satellites_clean
    GROUP BY country
    ORDER BY total_records DESC
    LIMIT 10
)
SELECT
    s.country,
    COUNT(*) AS total_records,
    COUNT(*) FILTER (WHERE s.orbit_group = 'Low Earth Orbit') AS leo,
    COUNT(*) FILTER (WHERE s.orbit_group = 'Geostationary Orbit') AS geo,
    COUNT(*) FILTER (WHERE s.orbit_group = 'Medium Earth Orbit') AS meo,
    COUNT(*) FILTER (WHERE s.orbit_group = 'Highly Elliptical Orbit') AS heo
FROM satellites_clean s
JOIN top_countries t
    ON s.country = t.country
GROUP BY s.country
ORDER BY total_records DESC;


WITH top_countries AS (
    SELECT
        country,
        COUNT(*) AS total_records
    FROM satellites_clean
    GROUP BY country
    ORDER BY total_records DESC
    LIMIT 10
)
SELECT
    s.country,
    COUNT(*) AS total_records,
    ROUND(
        100.0 * COUNT(*) FILTER (WHERE s.orbit_group = 'Low Earth Orbit') / COUNT(*),
        2
    ) AS leo_pct,
    ROUND(
        100.0 * COUNT(*) FILTER (WHERE s.orbit_group = 'Geostationary Orbit') / COUNT(*),
        2
    ) AS geo_pct,
    ROUND(
        100.0 * COUNT(*) FILTER (WHERE s.orbit_group = 'Medium Earth Orbit') / COUNT(*),
        2
    ) AS meo_pct,
    ROUND(
        100.0 * COUNT(*) FILTER (WHERE s.orbit_group = 'Highly Elliptical Orbit') / COUNT(*),
        2
    ) AS heo_pct
FROM satellites_clean s
JOIN top_countries t
    ON s.country = t.country
GROUP BY s.country
ORDER BY total_records DESC;

SELECT
    operator,
    COUNT(*) AS satellite_records
FROM satellites_clean
GROUP BY operator
ORDER BY satellite_records DESC
LIMIT 20;

WITH top_5 AS (
    SELECT
        operator,
        COUNT(*) AS records
    FROM satellites_clean
    WHERE operator <> 'Unknown'
    GROUP BY operator
    ORDER BY records DESC
    LIMIT 5
)
SELECT
    SUM(records) AS top_5_records,
    ROUND(
        100.0 * SUM(records) / (SELECT COUNT(*) FROM satellites_clean),
        2
    ) AS top_5_share_pct
FROM top_5;

WITH top_5 AS (
    SELECT
        operator
    FROM satellites_clean
    WHERE operator <> 'Unknown'
    GROUP BY operator
    ORDER BY COUNT(*) DESC
    LIMIT 5
)
SELECT
    s.operator,
    COUNT(*) AS total_records,
    COUNT(*) FILTER (
        WHERE s.orbit_group = 'Low Earth Orbit'
    ) AS leo,
    COUNT(*) FILTER (
        WHERE s.orbit_group = 'Geostationary Orbit'
    ) AS geo,
    COUNT(*) FILTER (
        WHERE s.orbit_group = 'Medium Earth Orbit'
    ) AS meo,
    COUNT(*) FILTER (
        WHERE s.orbit_group = 'Highly Elliptical Orbit'
    ) AS heo
FROM satellites_clean s
JOIN top_5 t
    ON s.operator = t.operator
GROUP BY s.operator
ORDER BY total_records DESC;

SELECT
    operator,
    COUNT(*) AS records_since_2020
FROM satellites_clean
WHERE launch_year >= 2020
  AND operator <> 'Unknown'
GROUP BY operator
ORDER BY records_since_2020 DESC
LIMIT 10;

SELECT
    country,
    COUNT(*) AS total_records,
    COUNT(*) FILTER (
        WHERE orbit_group = 'Geostationary Orbit'
    ) AS geo_records,
    ROUND(
        100.0 * COUNT(*) FILTER (
            WHERE orbit_group = 'Geostationary Orbit'
        ) / COUNT(*),
        2
    ) AS geo_pct
FROM satellites_clean
WHERE country <> 'Unknown'
GROUP BY country
HAVING COUNT(*) >= 20
ORDER BY geo_pct DESC;

SELECT
    orbit_group,
    operational_status,
    COUNT(*) AS satellite_records
FROM satellites_clean
GROUP BY orbit_group, operational_status
ORDER BY orbit_group, satellite_records DESC;

SELECT
    orbit_group,
    COUNT(*) AS total_records,
    COUNT(*) FILTER (
        WHERE operational_status = 'OPERATIONAL'
    ) AS operational_records,
    ROUND(
        100.0 * COUNT(*) FILTER (
            WHERE operational_status = 'OPERATIONAL'
        ) / COUNT(*),
        2
    ) AS operational_pct
FROM satellites_clean
GROUP BY orbit_group
ORDER BY total_records DESC;


SELECT
    (SELECT COUNT(*) FROM satellites_raw) AS raw_records,
    (SELECT COUNT(*) FROM satellites_clean) AS clean_records;

SELECT
    COUNT(*) AS total_records,
    COUNT(DISTINCT norad_number) AS unique_norad_numbers
FROM satellites_clean
WHERE norad_number IS NOT NULL;

SELECT 
satellite_name
FROM satellites_clean
ORDER BY satellite_name ASC 




SELECT current_user;
