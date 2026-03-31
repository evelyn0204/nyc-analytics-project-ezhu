-- Seating type dimension for open restaurant seating applications

WITH seating_types AS (
    SELECT DISTINCT
        CAST(seating_interest_sidewalk AS STRING) AS seating_interest,

        CASE
            WHEN CAST(approved_for_sidewalk_seating AS STRING) IN ('YES', 'Y', 'TRUE', 'APPROVED')
                THEN TRUE
            ELSE FALSE
        END AS approved_for_sidewalk,

        CASE
            WHEN CAST(approved_for_roadway_seating AS STRING) IN ('YES', 'Y', 'TRUE', 'APPROVED')
                THEN TRUE
            ELSE FALSE
        END AS approved_for_roadway

    FROM {{ ref('stg_nyc_open_restaurant_apps') }}
    WHERE seating_interest_sidewalk IS NOT NULL
),

seating_dimension AS (
    SELECT
        CONCAT(
            COALESCE(seating_interest, 'UNKNOWN'),
            '_',
            CAST(approved_for_sidewalk AS STRING),
            '_',
            CAST(approved_for_roadway AS STRING)
        ) AS seating_type_key,

        seating_interest,
        approved_for_sidewalk,
        approved_for_roadway

    FROM seating_types
)

SELECT * FROM seating_dimension