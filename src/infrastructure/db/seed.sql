-- Seed 25 categories (D-07)
INSERT INTO categories (name, is_fixed_cost) VALUES
  ('biedronka',   false),
  ('żabka',       false),
  ('paliwo',      false),
  ('taxi',        false),
  ('fun',         false),
  ('VAT',         true),
  ('PIT36',       true),
  ('ZUS',         true),
  ('arval',       true),
  ('biuro',       false),
  ('mieszkanie',  true),
  ('przejazdy',   false),
  ('kawa',        false),
  ('kredyt',      true),
  ('lidl',        false),
  ('ubrania',     false),
  ('rossman',     false),
  ('apteka',      false),
  ('lekarz',      false),
  ('kluska',      false),
  ('krypto',      false),
  ('inwestycje',  false),
  ('prezenty',    false),
  ('restauracje', false),
  ('foto',        false)
ON CONFLICT (name) DO NOTHING;

-- Seed Accounts (REQ-1.3)
INSERT INTO accounts (name, type, currency)
SELECT 'Konto Direct dla Firmy', 'business', 'PLN'
WHERE NOT EXISTS (SELECT 1 FROM accounts WHERE name = 'Konto Direct dla Firmy');

INSERT INTO accounts (name, type, currency)
SELECT 'IPKO', 'personal', 'PLN'
WHERE NOT EXISTS (SELECT 1 FROM accounts WHERE name = 'IPKO');

-- Idempotent PGMQ queue initialization
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pgmq.list_queues() WHERE queue_name = 'analysis_queue') THEN
    PERFORM pgmq.create('analysis_queue');
  END IF;
END $$;

-- Idempotent PGMQ queue initialization for import
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pgmq.list_queues() WHERE queue_name = 'import_queue') THEN
    PERFORM pgmq.create('import_queue');
  END IF;
END $$;
