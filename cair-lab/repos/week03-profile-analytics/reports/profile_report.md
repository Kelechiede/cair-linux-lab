# Profile Analytics Report

**Generated (UTC):** Wed Dec 17 10:25:36 UTC 2025

## Dataset
`profiling.sample_people`

## Summary Metrics
```
  metric   | value 
-----------+-------
 row_count | 5
(1 row)

     metric     | value 
----------------+-------
 null_full_name | 1
 null_email     | 1
 null_age       | 1
 null_city      | 1
(4 rows)

     metric     | value 
----------------+-------
 distinct_email | 4
(1 row)

        metric        | value 
----------------------+-------
 invalid_age          | 1
 invalid_email_format | 1
(2 rows)

    city     | n 
-------------+---
 St. John's  | 3
             | 1
 Mount Pearl | 1
(3 rows)

```

## Performance Evidence (EXPLAIN ANALYZE)
```
                                               QUERY PLAN                                                
---------------------------------------------------------------------------------------------------------
 Seq Scan on sample_people  (cost=0.00..1.06 rows=1 width=116) (actual time=0.004..0.005 rows=3 loops=1)
   Filter: (city = 'St. John''s'::text)
   Rows Removed by Filter: 2
   Buffers: shared hit=1
 Planning:
   Buffers: shared hit=108
 Planning Time: 0.252 ms
 Execution Time: 0.024 ms
(8 rows)

                                               QUERY PLAN                                                
---------------------------------------------------------------------------------------------------------
 Seq Scan on sample_people  (cost=0.00..1.06 rows=1 width=116) (actual time=0.004..0.005 rows=1 loops=1)
   Filter: (email = 'ada@example.com'::text)
   Rows Removed by Filter: 4
   Buffers: shared hit=1
 Planning Time: 0.025 ms
 Execution Time: 0.010 ms
(6 rows)

```
