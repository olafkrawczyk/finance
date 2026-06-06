-- 003_allow_category_update: Relax immutability trigger to allow category assignment
-- Changes: Allow UPDATE where only category_id changes from NULL to a non-null value
-- All other fields must remain unchanged

CREATE OR REPLACE FUNCTION block_immutable_change()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  IF OLD.category_id IS NULL 
     AND NEW.category_id IS NOT NULL 
     AND OLD.amount = NEW.amount 
     AND OLD.type = NEW.type 
     AND OLD.date = NEW.date 
     AND OLD.account_id = NEW.account_id 
     AND OLD.description IS NOT DISTINCT FROM NEW.description THEN
    RETURN NEW;
  END IF;
  RAISE EXCEPTION 'Transactions are immutable. Use a correcting entry instead.';
END;
$$;

DROP TRIGGER IF EXISTS trg_transactions_no_update ON transactions;
CREATE TRIGGER trg_transactions_no_update
  BEFORE UPDATE ON transactions FOR EACH ROW
  EXECUTE FUNCTION block_immutable_change();
