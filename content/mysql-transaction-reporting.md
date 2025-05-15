---
date: "2022-08-28T13:28:00-04:00"
title: "MySQL Transaction Reporting"
tags: ["mysql", "transactions", "performance-schema"]
menu:
  main: 
    parent: "MySQL"
summary: "How to inspect and report MySQL transactions using the Performance Schema"
aliases:
  - /trx
params:
  path: trx
---

In chapter 8 of [_Efficient MySQL Performance_](https://oreil.ly/efficient-mysql-performance), I discuss reporting MySQL transactions (among many other related topics).
In the book, I note that the state of the art is practically nonexistent: transactions are important, but we just don't monitor or report them in the world of MySQL.
Historically (in older versions of MySQL), there was basically no way to do this because neither the general log nor the slow log printed transaction IDs.
With vast improvements to the [Performance Schema](https://dev.mysql.com/doc/refman/8.0/en/performance-schema.html), MySQL transaction report is possible but there are no tools to make it easy, as far as I know.

For now, the "solution" is copy-pasting queries like the ones below to gain insight into past and present transactions.
When time allows me, I'll dig into the state of this art deeper, talk with more MySQL DBAs, and see if we can't create better solutions.

See also [Mining the MySQL Performance Schema for Transactions]({{< ref "book-8" >}}).

## Report latest query for transactions active longer than 1 second

```sql
--
-- Example 8-2. Report latest query for transactions active longer than 1 second
--

SELECT
  ROUND(trx.timer_wait/1000000000000,3) AS trx_runtime,
  trx.thread_id AS thread_id,
  trx.event_id AS trx_event_id,
  trx.isolation_level,
  trx.autocommit,
  stm.current_schema AS db,
  stm.sql_text AS query,
  stm.rows_examined AS rows_examined,
  stm.rows_affected AS rows_affected,
  stm.rows_sent AS rows_sent,
  IF(stm.end_event_id IS NULL, 'running', 'done') AS exec_state,
  ROUND(stm.timer_wait/1000000000000,3) AS exec_time
FROM
       performance_schema.events_transactions_current trx
  JOIN performance_schema.events_statements_current   stm USING (thread_id)
WHERE
      trx.state = 'ACTIVE'
  AND trx.timer_wait > 1000000000000 * 1\G
```

## Report transaction summary

```sql
--
-- Example 8-3. Report transaction summary
--

SELECT
  trx.thread_id AS thread_id,
  MAX(trx.event_id) AS trx_event_id,
  MAX(ROUND(trx.timer_wait/1000000000000,3)) AS trx_runtime,
  SUM(ROUND(stm.timer_wait/1000000000000,3)) AS exec_time,
  SUM(stm.rows_examined) AS rows_examined,
  SUM(stm.rows_affected) AS rows_affected,
  SUM(stm.rows_sent) AS rows_sent
FROM
       performance_schema.events_transactions_current trx
  JOIN performance_schema.events_statements_history   stm
    ON stm.thread_id = trx.thread_id AND stm.nesting_event_id = trx.event_id
WHERE
      stm.event_name LIKE 'statement/sql/%'
  AND trx.state = 'ACTIVE'
  AND trx.timer_wait > 1000000000000 * 1
GROUP BY trx.thread_id\G
```

## Report transaction history

```sql
--
-- Example 8-4. Report transaction history
--

SELECT
  stm.rows_examined AS rows_examined,
  stm.rows_affected AS rows_affected,
  stm.rows_sent AS rows_sent,
  ROUND(stm.timer_wait/1000000000000,3) AS exec_time,
  stm.sql_text AS query
FROM
  performance_schema.events_statements_history stm
WHERE
       stm.thread_id = 0
  AND  stm.nesting_event_id = 0
ORDER BY stm.event_id;
```

## Report basic metrics for committed transactions

```sql
--
-- Example 8-5. Report basic metrics for committed transactions
--

SELECT
  ROUND(MAX(trx.timer_wait)/1000000000,3) AS trx_time,
  ROUND(SUM(stm.timer_end-stm.timer_start)/1000000000,3) AS query_time,
  ROUND((MAX(trx.timer_wait)-SUM(stm.timer_end-stm.timer_start))/1000000000, 3)
    AS idle_time,
  COUNT(stm.event_id)-1 AS query_count,
  SUM(stm.rows_examined) AS rows_examined,
  SUM(stm.rows_affected) AS rows_affected,
  SUM(stm.rows_sent) AS rows_sent
FROM
      performance_schema.events_transactions_history trx
 JOIN performance_schema.events_statements_history   stm
   ON stm.nesting_event_id = trx.event_id
WHERE
      trx.state = 'COMMITTED'
  AND trx.nesting_event_id IS NOT NULL
GROUP BY
  trx.thread_id, trx.event_id;
```
