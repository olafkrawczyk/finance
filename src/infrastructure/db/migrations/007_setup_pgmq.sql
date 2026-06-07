-- 002_setup_pgmq: Enable PGMQ extension and create worker queues

-- Up Migration

CREATE EXTENSION IF NOT EXISTS pgmq;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pgmq.list_queues() WHERE queue_name = 'analysis_queue') THEN
    PERFORM pgmq.create('analysis_queue');
  END IF;
END $$;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pgmq.list_queues() WHERE queue_name = 'import_queue') THEN
    PERFORM pgmq.create('import_queue');
  END IF;
END $$;

-- Down Migration

DROP EXTENSION IF EXISTS pgmq CASCADE;
