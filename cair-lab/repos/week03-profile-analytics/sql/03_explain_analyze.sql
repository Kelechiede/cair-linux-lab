-- Week 3: Performance evidence

EXPLAIN (ANALYZE, BUFFERS)
SELECT *
FROM profiling.sample_people
WHERE city = 'St. John''s';

EXPLAIN (ANALYZE, BUFFERS)
SELECT *
FROM profiling.sample_people
WHERE email = 'ada@example.com';
