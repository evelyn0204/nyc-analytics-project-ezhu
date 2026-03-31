-- Clean and standardize restaurant seating application data
-- One row per restaurant application record

WITH source AS (
    SELECT * FROM {{ source('raw', 'source_dot_restaurant_requests_history') }}
), -- Easier to refer to the dbt reference to a long name table this way

cleaned AS (
    SELECT
        -- Get all columns from source, except ones we're transforming below
        * EXCEPT (
            objectid,
            globalid,
            time_of_submission,
            restaurant_name,
            legal_business_name,
            doing_business_as_dba,
            food_service_establishment,
            building_number,
            street,
            borough,
            zip,
            business_address,
            seating_interest_sidewalk,
            approved_for_sidewalk_seating,
            approved_for_roadway_seating,
            sidewalk_dimensions_area,
            roadway_dimensions_area,
            latitude,
            longitude,
            bbl,
            bin,
            census_tract,
            community_board,
            council_district,
            healthcompliance_terms,
            landmark_district_or_building,
            landmarkdistrict_terms,
            nta,
            qualify_alcohol,
            roadway_dimensions_length,
            roadway_dimensions_width,
            sidewalk_dimensions_length,
            sidewalk_dimensions_width,
            sla_license_type,
            sla_serial_number
        ),

        -- Identifiers
        CAST(objectid AS STRING) AS application_id,
        CAST(globalid AS STRING) AS global_id,

        -- Date/Time
        CAST(time_of_submission AS TIMESTAMP) AS submitted_at,

        -- Business details
        CAST(restaurant_name AS STRING) AS restaurant_name,
        CAST(legal_business_name AS STRING) AS legal_business_name,
        CAST(doing_business_as_dba AS STRING) AS doing_business_as_dba,
        CAST(food_service_establishment AS STRING) AS food_service_establishment,

        -- Address details
        CAST(building_number AS STRING) AS building_number,
        CAST(street AS STRING) AS street,
        CAST(business_address AS STRING) AS business_address,

        -- Clean zip code
        CASE
            WHEN UPPER(TRIM(CAST(zip AS STRING))) IN ('N/A', 'NA', '') THEN NULL
            WHEN LENGTH(TRIM(CAST(zip AS STRING))) = 5
                AND REGEXP_CONTAINS(TRIM(CAST(zip AS STRING)), r'^\d{5}$')
            THEN TRIM(CAST(zip AS STRING))
            WHEN LENGTH(TRIM(CAST(zip AS STRING))) = 10
                AND REGEXP_CONTAINS(TRIM(CAST(zip AS STRING)), r'^\d{5}-\d{4}$')
            THEN TRIM(CAST(zip AS STRING))
            ELSE NULL
        END AS zip,

        -- Standardized borough
        CASE
            WHEN UPPER(TRIM(CAST(borough AS STRING))) IN ('MANHATTAN', 'NEW YORK COUNTY') THEN 'Manhattan'
            WHEN UPPER(TRIM(CAST(borough AS STRING))) IN ('BRONX', 'THE BRONX') THEN 'Bronx'
            WHEN UPPER(TRIM(CAST(borough AS STRING))) IN ('BROOKLYN', 'KINGS COUNTY') THEN 'Brooklyn'
            WHEN UPPER(TRIM(CAST(borough AS STRING))) IN ('QUEENS', 'QUEEN', 'QUEENS COUNTY') THEN 'Queens'
            WHEN UPPER(TRIM(CAST(borough AS STRING))) IN ('STATEN ISLAND', 'RICHMOND COUNTY') THEN 'Staten Island'
            ELSE 'UNKNOWN'
        END AS borough,

        -- Seating / approval details
        UPPER(TRIM(CAST(seating_interest_sidewalk AS STRING))) AS seating_interest_sidewalk,
        UPPER(TRIM(CAST(approved_for_sidewalk_seating AS STRING))) AS approved_for_sidewalk_seating,
        UPPER(TRIM(CAST(approved_for_roadway_seating AS STRING))) AS approved_for_roadway_seating,

        -- Measurements
        SAFE_CAST(sidewalk_dimensions_area AS NUMERIC) AS sidewalk_dimensions_area,
        SAFE_CAST(roadway_dimensions_area AS NUMERIC) AS roadway_dimensions_area,
        CAST(roadway_dimensions_length AS STRING) AS roadway_dimensions_length,
        CAST(roadway_dimensions_width AS STRING) AS roadway_dimensions_width,
        CAST(sidewalk_dimensions_length AS STRING) AS sidewalk_dimensions_length,
        CAST(sidewalk_dimensions_width AS STRING) AS sidewalk_dimensions_width,

        -- Coordinates
        SAFE_CAST(latitude AS NUMERIC) AS latitude,
        SAFE_CAST(longitude AS NUMERIC) AS longitude,

        -- Geography / admin
        CAST(bbl AS STRING) AS bbl,
        CAST(bin AS STRING) AS bin,
        CAST(census_tract AS STRING) AS census_tract,
        CAST(community_board AS STRING) AS community_board,
        CAST(council_district AS STRING) AS council_district,
        CAST(nta AS STRING) AS nta,

        -- Other attributes
        CAST(healthcompliance_terms AS STRING) AS healthcompliance_terms,
        CAST(landmark_district_or_building AS STRING) AS landmark_district_or_building,
        CAST(landmarkdistrict_terms AS STRING) AS landmarkdistrict_terms,
        CAST(qualify_alcohol AS STRING) AS qualify_alcohol,
        CAST(sla_license_type AS STRING) AS sla_license_type,
        CAST(sla_serial_number AS STRING) AS sla_serial_number,

        -- Metadata
        CURRENT_TIMESTAMP() AS _stg_loaded_at

    FROM source

    -- Filters
    WHERE objectid IS NOT NULL
      AND time_of_submission IS NOT NULL
      AND (
            restaurant_name IS NOT NULL
            OR legal_business_name IS NOT NULL
            OR doing_business_as_dba IS NOT NULL
          )

    -- Deduplicate
    QUALIFY ROW_NUMBER() OVER (
        PARTITION BY objectid
        ORDER BY time_of_submission DESC
    ) = 1
)

SELECT * FROM cleaned
-- All should be part of this table: stg_nyc_restaurant_requests
