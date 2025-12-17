-- Week 3: CAIR-style Profile Analytics queries

-- 1) Row count
SELECT 'row_count' AS metric, COUNT(*)::text AS value
FROM profiling.sample_people;

-- 2) Null counts by column
SELECT 'null_full_name' AS metric, COUNT(*)::text AS value
FROM profiling.sample_people WHERE full_name IS NULL
UNION ALL
SELECT 'null_email', COUNT(*)::text FROM profiling.sample_people WHERE email IS NULL
UNION ALL
SELECT 'null_age', COUNT(*)::text FROM profiling.sample_people WHERE age IS NULL
UNION ALL
SELECT 'null_city', COUNT(*)::text FROM profiling.sample_people WHERE city IS NULL;

-- 3) Distinct counts (cardinality)
SELECT 'distinct_email' AS metric, COUNT(DISTINCT email)::text AS value
FROM profiling.sample_people
WHERE email IS NOT NULL;

-- 4) Simple data quality checks
SELECT 'invalid_age' AS metric, COUNT(*)::text AS value
FROM profiling.sample_people
WHERE age IS NOT NULL AND (age < 0 OR age > 120)
UNION ALL
SELECT 'invalid_email_format', COUNT(*)::text
FROM profiling.sample_people
WHERE email IS NOT NULL AND email NOT LIKE '%@%';

-- 5) City distribution
SELECT city, COUNT(*) AS n
FROM profiling.sample_people
GROUP BY city
ORDER BY n DESC NULLS LAST;
