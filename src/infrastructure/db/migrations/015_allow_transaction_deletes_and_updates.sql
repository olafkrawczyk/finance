-- Allow all transaction updates (remove category-only restriction from 003)
CREATE OR REPLACE FUNCTION block_immutable_change()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  RETURN NEW;
END;
$$;

-- Remove delete block — hard deletes now allowed
DROP TRIGGER IF EXISTS trg_transactions_no_delete ON transactions;
DROP FUNCTION IF EXISTS block_delete();
