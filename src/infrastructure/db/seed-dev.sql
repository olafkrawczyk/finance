-- Dev seed: real transaction data from budget.xlsx (2024-2025)
-- Generated automatically. DO NOT COMMIT sensitive data.

-- Opening balances
INSERT INTO monthly_opening_balances (year, month, opening_balance)
  VALUES (2024, 1, 135305)
  ON CONFLICT (year, month) DO UPDATE SET opening_balance = EXCLUDED.opening_balance;
INSERT INTO monthly_opening_balances (year, month, opening_balance)
  VALUES (2024, 2, 135439)
  ON CONFLICT (year, month) DO UPDATE SET opening_balance = EXCLUDED.opening_balance;
INSERT INTO monthly_opening_balances (year, month, opening_balance)
  VALUES (2024, 3, 141285)
  ON CONFLICT (year, month) DO UPDATE SET opening_balance = EXCLUDED.opening_balance;
INSERT INTO monthly_opening_balances (year, month, opening_balance)
  VALUES (2024, 4, 151444)
  ON CONFLICT (year, month) DO UPDATE SET opening_balance = EXCLUDED.opening_balance;
INSERT INTO monthly_opening_balances (year, month, opening_balance)
  VALUES (2024, 5, 154950)
  ON CONFLICT (year, month) DO UPDATE SET opening_balance = EXCLUDED.opening_balance;
INSERT INTO monthly_opening_balances (year, month, opening_balance)
  VALUES (2024, 6, 144744)
  ON CONFLICT (year, month) DO UPDATE SET opening_balance = EXCLUDED.opening_balance;
INSERT INTO monthly_opening_balances (year, month, opening_balance)
  VALUES (2024, 7, 157232)
  ON CONFLICT (year, month) DO UPDATE SET opening_balance = EXCLUDED.opening_balance;
INSERT INTO monthly_opening_balances (year, month, opening_balance)
  VALUES (2024, 8, 160477.97)
  ON CONFLICT (year, month) DO UPDATE SET opening_balance = EXCLUDED.opening_balance;
INSERT INTO monthly_opening_balances (year, month, opening_balance)
  VALUES (2024, 9, 167588.64)
  ON CONFLICT (year, month) DO UPDATE SET opening_balance = EXCLUDED.opening_balance;
INSERT INTO monthly_opening_balances (year, month, opening_balance)
  VALUES (2024, 10, 176449.09)
  ON CONFLICT (year, month) DO UPDATE SET opening_balance = EXCLUDED.opening_balance;
INSERT INTO monthly_opening_balances (year, month, opening_balance)
  VALUES (2024, 11, 184586.09)
  ON CONFLICT (year, month) DO UPDATE SET opening_balance = EXCLUDED.opening_balance;
INSERT INTO monthly_opening_balances (year, month, opening_balance)
  VALUES (2024, 12, 182516.7)
  ON CONFLICT (year, month) DO UPDATE SET opening_balance = EXCLUDED.opening_balance;
INSERT INTO monthly_opening_balances (year, month, opening_balance)
  VALUES (2025, 1, 172804.36)
  ON CONFLICT (year, month) DO UPDATE SET opening_balance = EXCLUDED.opening_balance;
INSERT INTO monthly_opening_balances (year, month, opening_balance)
  VALUES (2025, 2, 173772.21)
  ON CONFLICT (year, month) DO UPDATE SET opening_balance = EXCLUDED.opening_balance;
INSERT INTO monthly_opening_balances (year, month, opening_balance)
  VALUES (2025, 3, 174000.01)
  ON CONFLICT (year, month) DO UPDATE SET opening_balance = EXCLUDED.opening_balance;
INSERT INTO monthly_opening_balances (year, month, opening_balance)
  VALUES (2025, 4, 169145.63)
  ON CONFLICT (year, month) DO UPDATE SET opening_balance = EXCLUDED.opening_balance;
INSERT INTO monthly_opening_balances (year, month, opening_balance)
  VALUES (2025, 5, 140997.94)
  ON CONFLICT (year, month) DO UPDATE SET opening_balance = EXCLUDED.opening_balance;
INSERT INTO monthly_opening_balances (year, month, opening_balance)
  VALUES (2025, 6, 151881.83)
  ON CONFLICT (year, month) DO UPDATE SET opening_balance = EXCLUDED.opening_balance;
INSERT INTO monthly_opening_balances (year, month, opening_balance)
  VALUES (2025, 7, 160100.21)
  ON CONFLICT (year, month) DO UPDATE SET opening_balance = EXCLUDED.opening_balance;
INSERT INTO monthly_opening_balances (year, month, opening_balance)
  VALUES (2025, 8, 158908.08)
  ON CONFLICT (year, month) DO UPDATE SET opening_balance = EXCLUDED.opening_balance;
INSERT INTO monthly_opening_balances (year, month, opening_balance)
  VALUES (2025, 9, 158860.84)
  ON CONFLICT (year, month) DO UPDATE SET opening_balance = EXCLUDED.opening_balance;
INSERT INTO monthly_opening_balances (year, month, opening_balance)
  VALUES (2025, 10, 164457.22)
  ON CONFLICT (year, month) DO UPDATE SET opening_balance = EXCLUDED.opening_balance;

-- Expense transactions (all assigned to IPKO personal account)
DO $$
DECLARE
  v_account_id UUID;
BEGIN
  SELECT id INTO v_account_id FROM accounts WHERE name = 'IPKO' LIMIT 1;
  IF v_account_id IS NULL THEN RAISE EXCEPTION 'IPKO account not found'; END IF;

  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 5.0, 'Nazwa odbiorcy: MOBILE-TRAFFIC-DATA SP. Z O. O. Adres odbiorcy: UL. DRUŻBICKIEGO 11 61-693 POZNAŃ Tytuł: ZAKUP BILETU KOMUNIKACYJNEGO W APLI KACJI IKO  Referencje własne zleceniodawcy: 176171147909 (5', '2025-10-13', 'seed-cefdd3fdb1edeef5'
  FROM categories c WHERE c.name = 'przejazdy'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 5.0, 'Nazwa odbiorcy: MOBILE-TRAFFIC-DATA SP. Z O. O. Adres odbiorcy: UL. DRUŻBICKIEGO 11 61-693 POZNAŃ Tytuł: ZAKUP BILETU KOMUNIKACYJNEGO W APLI KACJI IKO  Referencje własne zleceniodawcy: 176170813393 (5', '2025-10-13', 'seed-40c1fe9192086e25'
  FROM categories c WHERE c.name = 'przejazdy'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 15.48, 'Tytuł: 000498849 74230785285177549416712  Lokalizacja: Adres: NETTO 5304 SCO K.3 Miasto: POZNAN Kraj: POLSKA Data wykonania operacji: 2025-10-11 02:00 Oryginalna kwota operacji: 15.48 Numer karty: 425', '2025-10-13', 'seed-04ccaeb3e8cefb27'
  FROM categories c WHERE c.name = 'biedronka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 26.0, 'Tytuł: 000498849 74230785285177534219758  Lokalizacja: Adres: STRONA Miasto: POZNAN Kraj: POLSKA Data wykonania operacji: 2025-10-11 02:00 Oryginalna kwota operacji: 26.00 Numer karty: 425125******026', '2025-10-13', 'seed-28e814be8461bfca'
  FROM categories c WHERE c.name = 'biedronka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 18.9, 'Tytuł: 010061097 74169505284622844453512  Lokalizacja: Adres: FHU OFFICE ART SCHOOL SC Miasto: POZNAN Kraj: POLSKA Data wykonania operacji: 2025-10-11 02:00 Oryginalna kwota operacji: 18.90 Numer kart', '2025-10-13', 'seed-7225e97a95bb671c'
  FROM categories c WHERE c.name = 'biuro'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 129.99, 'Tytuł: 010066928 74056285284109308718312  Lokalizacja: Adres: APPLE.COM/BILL Miasto: APPLE.COM/BIL Kraj: IRLANDIA Data wykonania operacji: 2025-10-11 02:00 Oryginalna kwota operacji: 129.99 Numer kart', '2025-10-13', 'seed-9997b2ad51d1c94a'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 4.5, 'Tytuł: 010061097 74169505283652832785030  Lokalizacja: Adres: FABRYKA FORMY POZNAN BALT Miasto: POZNAN Kraj: POLSKA Data wykonania operacji: 2025-10-10 02:00 Oryginalna kwota operacji: 4.50 Numer kart', '2025-10-12', 'seed-fd887ba048f56d5a'
  FROM categories c WHERE c.name = 'biedronka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 25.0, 'Tytuł: 010061097 74169505283652832784975  Lokalizacja: Adres: FABRYKA FORMY POZNAN BALT Miasto: POZNAN Kraj: POLSKA Data wykonania operacji: 2025-10-10 02:00 Oryginalna kwota operacji: 25.00 Numer kar', '2025-10-12', 'seed-169d14a93970187d'
  FROM categories c WHERE c.name = 'biedronka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 75.0, 'Tytuł:  74810315283172414272346  Lokalizacja: Adres: Mowish Mash Miasto: Poznan Kraj: POLSKA Data wykonania operacji: 2025-10-10 02:00 Oryginalna kwota operacji: 75.00 Numer karty: 425125******0264 (7', '2025-10-12', 'seed-127ec98da85b386a'
  FROM categories c WHERE c.name = 'kawa'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 18.0, 'Tytuł:  74810315283172414782427  Lokalizacja: Adres: Maselko Miasto: Poznan Kraj: POLSKA Data wykonania operacji: 2025-10-10 02:00 Oryginalna kwota operacji: 18.00 Numer karty: 425125******0264 (18.00', '2025-10-12', 'seed-ccf3b9adb15cf8f0'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 20.99, 'Tytuł: 010059127 74062945282143299379290  Lokalizacja: Adres: www.inpost.pl Miasto: KRAKOW Kraj: POLSKA Data wykonania operacji: 2025-10-09 02:00 Oryginalna kwota operacji: 20.99 Numer karty: 425125**', '2025-10-11', 'seed-f87d664d4a3885df'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 25.0, 'Tytuł: 000498849 74230785282177354256305  Lokalizacja: Adres: STRONA Miasto: POZNAN Kraj: POLSKA Data wykonania operacji: 2025-10-09 02:00 Oryginalna kwota operacji: 25.00 Numer karty: 425125******026', '2025-10-11', 'seed-640cfcc7d44b213b'
  FROM categories c WHERE c.name = 'biedronka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 6.0, 'Tytuł: 000498849 74230785282177375805239  Lokalizacja: Adres: ZABKA Z0685 K.1 Miasto: POZNAN Kraj: POLSKA Data wykonania operacji: 2025-10-09 02:00 Oryginalna kwota operacji: 6.00 Numer karty: 425125*', '2025-10-11', 'seed-c87f22310de956bb'
  FROM categories c WHERE c.name = 'żabka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 54.85, 'Tytuł: 000498849 74230785283177400441306  Lokalizacja: Adres: NETTO 5304 SCO K.3 Miasto: POZNAN Kraj: POLSKA Data wykonania operacji: 2025-10-09 02:00 Oryginalna kwota operacji: 54.85 Numer karty: 425', '2025-10-11', 'seed-948105697c19317c'
  FROM categories c WHERE c.name = 'biedronka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 23.18, 'Tytuł: 000498849 74230785283177398596624  Lokalizacja: Adres: NETTO 5304 SCO K.2 Miasto: POZNAN Kraj: POLSKA Data wykonania operacji: 2025-10-09 02:00 Oryginalna kwota operacji: 23.18 Numer karty: 425', '2025-10-11', 'seed-2a32a2e8dd8b93c2'
  FROM categories c WHERE c.name = 'biedronka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 73.67, 'Tytuł:  74988855281401316671161  Lokalizacja: Adres: JMIDF SP.Z.O.O.HEBE R052 Miasto: POZNAN Kraj: POLSKA Data wykonania operacji: 2025-10-08 02:00 Oryginalna kwota operacji: 73.67 Numer karty: 425125', '2025-10-10', 'seed-67f6fe666de6e4c5'
  FROM categories c WHERE c.name = 'arval'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 16.97, 'Tytuł:  74838495282332376331253  Lokalizacja: Adres: ROSSMANN 11 Miasto: Poznan Kraj: POLSKA Data wykonania operacji: 2025-10-08 02:00 Oryginalna kwota operacji: 16.97 Numer karty: 425125******0264 (1', '2025-10-10', 'seed-c3f72ac5a12e5027'
  FROM categories c WHERE c.name = 'rossman'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 238.0, 'Tytuł: 000498707 74987075281033824464296  Lokalizacja: Adres: oleole.pl Miasto: Warszawa Kraj: POLSKA Data wykonania operacji: 2025-10-07 02:00 Oryginalna kwota operacji: 238.00 Numer karty: 425125***', '2025-10-09', 'seed-2c701a12ed586955'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 53.86, 'Tytuł: 010072805 24871155280135442499367  Lokalizacja: Adres: ALIEXPRESS.COM Miasto: Luxembourg Kraj: LUKSEMBURG Data wykonania operacji: 2025-10-07 02:00 Oryginalna kwota operacji: 53.86 Numer karty:', '2025-10-09', 'seed-f82ae164cecb46c3'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 4.5, 'Tytuł: 000498849 74230785280177237349006  Lokalizacja: Adres: ZABKA Z0685 K.1 Miasto: POZNAN Kraj: POLSKA Data wykonania operacji: 2025-10-07 02:00 Oryginalna kwota operacji: 4.50 Numer karty: 425125*', '2025-10-09', 'seed-eb1cd9308e089e26'
  FROM categories c WHERE c.name = 'żabka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 88.8, 'Tytuł: 010082965 74987075280033778333753  Lokalizacja: Adres: Allegro Miasto: Poznan Kraj: POLSKA Data wykonania operacji: 2025-10-06 02:00 Oryginalna kwota operacji: 88.80 Numer karty: 425125******02', '2025-10-08', 'seed-b2467efb5b28bcef'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 250.0, 'Tytuł: 010061097 74169505279612791496124  Lokalizacja: Adres: PRACOWNIA PSYCHOLOGICZNA Miasto: POZNAN Kraj: POLSKA Data wykonania operacji: 2025-10-06 02:00 Oryginalna kwota operacji: 250.00 Numer kar', '2025-10-08', 'seed-0292a021e5b1e380'
  FROM categories c WHERE c.name = 'lekarz'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 500.0, 'Tytuł: S1PO2028 1709 00000091170430632   Numer telefonu: 48796555364 Lokalizacja: Adres: UL. ROOSEVELTA 11 Miasto: POZNAN Kraj: POLSKA Bankomat: S1PO2028 ''Operacja: 1709 00000091170430632 Numer refer', '2025-10-08', 'seed-d4ff6c2d6b5969a5'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 224.0, 'Tytuł: 010082965 74987075279033766092885  Lokalizacja: Adres: Allegro Miasto: Poznan Kraj: POLSKA Data wykonania operacji: 2025-10-05 02:00 Oryginalna kwota operacji: 224.00 Numer karty: 425125******0', '2025-10-07', 'seed-44ab9ac63d35c814'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 43.0, 'Tytuł: 000498849 74230785278177123011169  Lokalizacja: Adres: STRONA Miasto: POZNAN Kraj: POLSKA Data wykonania operacji: 2025-10-05 02:00 Oryginalna kwota operacji: 43.00 Numer karty: 425125******026', '2025-10-07', 'seed-a53eb27045dabff3'
  FROM categories c WHERE c.name = 'arval'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 400.0, 'Tytuł: S1WR3335 6617 00000091097049233   Numer telefonu: 48796555364 Lokalizacja: Adres: PL. GRUNWALDZKI 22 Miasto: WROCLAW Kraj: POLSKA Bankomat: S1WR3335 ''Operacja: 6617 00000091097049233 Numer ref', '2025-10-06', 'seed-99c862f56044c674'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 5.0, 'Nazwa odbiorcy: MOBILE-TRAFFIC-DATA SP. Z O. O. Adres odbiorcy: UL. DRUŻBICKIEGO 11 61-693 POZNAŃ Tytuł: ZAKUP BILETU KOMUNIKACYJNEGO W APLI KACJI IKO  Referencje własne zleceniodawcy: 176143454089 (5', '2025-10-06', 'seed-c07d6730790d7604'
  FROM categories c WHERE c.name = 'przejazdy'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 5.0, 'Nazwa odbiorcy: MOBILE-TRAFFIC-DATA SP. Z O. O. Adres odbiorcy: UL. DRUŻBICKIEGO 11 61-693 POZNAŃ Tytuł: ZAKUP BILETU KOMUNIKACYJNEGO W APLI KACJI IKO  Referencje własne zleceniodawcy: 176143109081 (5', '2025-10-06', 'seed-d41a559333f9bd76'
  FROM categories c WHERE c.name = 'przejazdy'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 88.0, 'Tytuł: 010046551 74230105277060857298966  Lokalizacja: Adres: ZIOMAL DARIA JEZEWSKA Miasto: POZNAN Kraj: POLSKA Data wykonania operacji: 2025-10-04 02:00 Oryginalna kwota operacji: 88.00 Numer karty: ', '2025-10-06', 'seed-1fc12b36a1848cc5'
  FROM categories c WHERE c.name = 'arval'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 301.66, 'Tytuł: 000498849 74230785278177102282468  Lokalizacja: Adres: TRANSGOURMET Miasto: POZNAN Kraj: POLSKA Data wykonania operacji: 2025-10-04 02:00 Oryginalna kwota operacji: 301.66 Numer karty: 425125**', '2025-10-06', 'seed-674ca07d58e618d9'
  FROM categories c WHERE c.name = 'arval'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 800.0, 'Tytuł: 010085232 74350275276011830721604  Lokalizacja: Adres: Revolut**7108* Miasto: Dublin Kraj: IRLANDIA Data wykonania operacji: 2025-10-03 02:00 Oryginalna kwota operacji: 800.00 Numer karty: 4251', '2025-10-04', 'seed-16186e05d12c542a'
  FROM categories c WHERE c.name = 'mieszkanie'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 59.99, 'Tytuł: 010066928 74056285275101067579002  Lokalizacja: Adres: APPLE.COM/BILL Miasto: APPLE.COM/BIL Kraj: IRLANDIA Data wykonania operacji: 2025-10-02 02:00 Oryginalna kwota operacji: 59.99 Numer karty', '2025-10-04', 'seed-ba20809f8a1dfaec'
  FROM categories c WHERE c.name = 'biuro'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 43.0, 'Tytuł: 000498849 74230785275176914537856  Lokalizacja: Adres: STRONA Miasto: POZNAN Kraj: POLSKA Data wykonania operacji: 2025-10-02 02:00 Oryginalna kwota operacji: 43.00 Numer karty: 425125******026', '2025-10-04', 'seed-80cb9af19403712c'
  FROM categories c WHERE c.name = 'biedronka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 65.34, 'Tytuł: 000498849 74230785276176960343125  Lokalizacja: Adres: NETTO 5304 SCO K.3 Miasto: POZNAN Kraj: POLSKA Data wykonania operacji: 2025-10-02 02:00 Oryginalna kwota operacji: 65.34 Numer karty: 425', '2025-10-04', 'seed-ca733d0a74de2839'
  FROM categories c WHERE c.name = 'biedronka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 1280.0, 'Rachunek odbiorcy: 73 1090 2372 0000 0001 1332 9442 Nazwa odbiorcy: MARTA SZCZYGIEŁ Tytuł: PRZELEW NA TELEFON  OD: 48796555364 DO: 486*****967 (1280.00 PLN)', '2025-10-02', 'seed-c2786ae557de620c'
  FROM categories c WHERE c.name = 'mieszkanie'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 363.0, 'Rachunek odbiorcy: 21 1940 1076 6256 6800 0000 0000 Nazwa odbiorcy: ADAM TYŻYK Tytuł: 12 MP/10/2025   Referencje własne zleceniodawcy: 176132872905 (363.00 PLN)', '2025-10-02', 'seed-bf74f931ba536d40'
  FROM categories c WHERE c.name = 'mieszkanie'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 124.92, 'Tytuł: 000498849 74230785274176825525413  Lokalizacja: Adres: NETTO 5304 SCO K.3 Miasto: POZNAN Kraj: POLSKA Data wykonania operacji: 2025-09-30 02:00 Oryginalna kwota operacji: 124.92 Numer karty: 42', '2025-10-02', 'seed-28c5004c833a7f65'
  FROM categories c WHERE c.name = 'biedronka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 9.0, 'Tytuł: 010061097 74169505273642731200357  Lokalizacja: Adres: FABRYKA FORMY POZNAN BALT Miasto: POZNAN Kraj: POLSKA Data wykonania operacji: 2025-09-30 02:00 Oryginalna kwota operacji: 9.00 Numer kart', '2025-10-02', 'seed-c0f312f117b8763e'
  FROM categories c WHERE c.name = 'biedronka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 250.0, 'Tytuł: 010061097 74169505273602737570849  Lokalizacja: Adres: PRACOWNIA PSYCHOLOGICZNA Miasto: POZNAN Kraj: POLSKA Data wykonania operacji: 2025-09-29 02:00 Oryginalna kwota operacji: 250.00 Numer kar', '2025-10-02', 'seed-739ce0648e0127fd'
  FROM categories c WHERE c.name = 'lekarz'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 59.4, 'Tytuł: 010079564 74609055272100084318933  Lokalizacja: Adres: WOLT Miasto: WARSAW Kraj: POLSKA Data wykonania operacji: 2025-09-29 02:00 Oryginalna kwota operacji: 59.40 Numer karty: 425125******0264 ', '2025-10-01', 'seed-bfa57f8109cb6feb'
  FROM categories c WHERE c.name = 'arval'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 82.29, 'Orange Polska S.A. Aleje Jerozolims kie 160 02-326 Warszawa NIP 526-025 -09-95   F0083222849/010/25', '2025-10-09', 'seed-a585e8618c2e3a30'
  FROM categories c WHERE c.name = 'biuro'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 253.5, 'P4 Sp. z o.o. ul. Wynalazek 1 02-67 7 Warszawa   F/10170471/10/25', '2025-10-09', 'seed-a5855d90122b69b4'
  FROM categories c WHERE c.name = 'biuro'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 2239.72, 'BNP Paribas Leasing Services Sp. z o.o. 00-844 Warszawa, ul.Grzybowska 78   40050/10/2025/RL/L', '2025-10-02', 'seed-15213ecedc4e4663'
  FROM categories c WHERE c.name = 'arval'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 23.9, 'Tytuł:  74838495271331029792336  Lokalizacja: Adres: PL SBX POZNAN KAPONIERA Miasto: POZNAN Kraj: POLSKA Data wykonania operacji: 2025-09-28 02:00 Oryginalna kwota operacji: 23.90 Numer karty: 425125*', '2025-09-30', 'seed-23e28dce2e2bc910'
  FROM categories c WHERE c.name = 'kawa'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 36.0, 'Tytuł:  74838495271330989542053  Lokalizacja: Adres: AGRAWKA Miasto: POZNAN Kraj: POLSKA Data wykonania operacji: 2025-09-28 02:00 Oryginalna kwota operacji: 36.00 Numer karty: 425125******0264 (36.00', '2025-09-30', 'seed-b91df7e99b81798b'
  FROM categories c WHERE c.name = 'kawa'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 320.0, 'Rachunek odbiorcy: 73 1090 2372 0000 0001 1332 9442 Nazwa odbiorcy: MARTA SZCZYGIEŁ Tytuł: PRZELEW NA TELEFON  OD: 48796555364 DO: 486*****967 (320.00 PLN)', '2025-09-29', 'seed-0ccf19d0f0ee6563'
  FROM categories c WHERE c.name = 'mieszkanie'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 5.0, 'Nazwa odbiorcy: MOBILE-TRAFFIC-DATA SP. Z O. O. Adres odbiorcy: UL. DRUŻBICKIEGO 11 61-693 POZNAŃ Tytuł: ZAKUP BILETU KOMUNIKACYJNEGO W APLI KACJI IKO  Referencje własne zleceniodawcy: 176117332131 (5', '2025-09-29', 'seed-986b9624b2b45efc'
  FROM categories c WHERE c.name = 'przejazdy'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 5.0, 'Nazwa odbiorcy: MOBILE-TRAFFIC-DATA SP. Z O. O. Adres odbiorcy: UL. DRUŻBICKIEGO 11 61-693 POZNAŃ Tytuł: ZAKUP BILETU KOMUNIKACYJNEGO W APLI KACJI IKO  Referencje własne zleceniodawcy: 176117028129 (5', '2025-09-29', 'seed-d2d1ae64d069b9ba'
  FROM categories c WHERE c.name = 'przejazdy'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 33.0, 'Tytuł: 010046551 74230105270060695629718  Lokalizacja: Adres: PATILA DONER KEBAP Miasto: WARSZAWA Kraj: POLSKA Data wykonania operacji: 2025-09-27 02:00 Oryginalna kwota operacji: 33.00 Numer karty: 4', '2025-09-29', 'seed-afc63da86c163d46'
  FROM categories c WHERE c.name = 'restauracje'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 22.0, 'Tytuł:  74838495270330831227797  Lokalizacja: Adres: ALL GOOD S.A. KAWIARNIA Miasto: WARSZAWA Kraj: POLSKA Data wykonania operacji: 2025-09-27 02:00 Oryginalna kwota operacji: 22.00 Numer karty: 42512', '2025-09-29', 'seed-487bf0b1253b303d'
  FROM categories c WHERE c.name = 'kawa'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 59.98, 'Tytuł:  74838495270330948540132  Lokalizacja: Adres: ME M03 02 Miasto: POZNAN Kraj: POLSKA Data wykonania operacji: 2025-09-27 02:00 Oryginalna kwota operacji: 59.98 Numer karty: 425125******0264 (59.', '2025-09-29', 'seed-dd05f976098b095e'
  FROM categories c WHERE c.name = 'biedronka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 376.72, 'Tytuł:  74838495271330946294426  Lokalizacja: Adres: LIDL GLOGOWSKA Miasto: Poznan Kraj: POLSKA Data wykonania operacji: 2025-09-27 02:00 Oryginalna kwota operacji: 376.72 Numer karty: 425125******026', '2025-09-29', 'seed-c9f2eb3c07c02157'
  FROM categories c WHERE c.name = 'biedronka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 51.0, 'Tytuł:  74838495270330817887705  Lokalizacja: Adres: ALL GOOD S.A. KAWIARNIA Miasto: WARSZAWA Kraj: POLSKA Data wykonania operacji: 2025-09-27 02:00 Oryginalna kwota operacji: 51.00 Numer karty: 42512', '2025-09-29', 'seed-5eb8bdae1648d183'
  FROM categories c WHERE c.name = 'kawa'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 4.5, 'Tytuł:  74810315270171203357685  Lokalizacja: Adres: WARS Automat vendingowy Miasto: Warszawa Kraj: POLSKA Data wykonania operacji: 2025-09-27 02:00 Oryginalna kwota operacji: 4.50 Numer karty: 425125', '2025-09-29', 'seed-48074ed20299b573'
  FROM categories c WHERE c.name = 'arval'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 4.5, 'Tytuł:  74810315270171203487599  Lokalizacja: Adres: WARS Automat vendingowy Miasto: Warszawa Kraj: POLSKA Data wykonania operacji: 2025-09-27 02:00 Oryginalna kwota operacji: 4.50 Numer karty: 425125', '2025-09-29', 'seed-fffa6646f37217db'
  FROM categories c WHERE c.name = 'arval'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 129.0, 'Tytuł:  74838495269330672967710  Lokalizacja: Adres: ALL GOOD S.A. KAWIARNIA Miasto: WARSZAWA Kraj: POLSKA Data wykonania operacji: 2025-09-26 02:00 Oryginalna kwota operacji: 129.00 Numer karty: 4251', '2025-09-28', 'seed-22e6ada2f2416f9c'
  FROM categories c WHERE c.name = 'kawa'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 7.49, 'Tytuł: 000498849 74230785269176550658733  Lokalizacja: Adres: ZABKA ZE578 K.2 Miasto: WARSZAWA Kraj: POLSKA Data wykonania operacji: 2025-09-26 02:00 Oryginalna kwota operacji: 7.49 Numer karty: 42512', '2025-09-28', 'seed-c2fd9fb23a63fa5a'
  FROM categories c WHERE c.name = 'żabka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 18.0, 'Tytuł:  74838495269330664839331  Lokalizacja: Adres: ALL GOOD S.A. KAWIARNIA Miasto: WARSZAWA Kraj: POLSKA Data wykonania operacji: 2025-09-26 02:00 Oryginalna kwota operacji: 18.00 Numer karty: 42512', '2025-09-28', 'seed-fa6e9bc7e177efdb'
  FROM categories c WHERE c.name = 'kawa'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 24.0, 'Tytuł:  74838495269330751459829  Lokalizacja: Adres: LOUVRE HOTELS GROUP 01 Miasto: Warszawa Kraj: POLSKA Data wykonania operacji: 2025-09-26 02:00 Oryginalna kwota operacji: 24.00 Numer karty: 425125', '2025-09-28', 'seed-c711339fadb0f430'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 32.0, 'Tytuł: 000498849 74230785269176569428417  Lokalizacja: Adres: TADIM DONER GRILL Miasto: WARSZAWA Kraj: POLSKA Data wykonania operacji: 2025-09-26 02:00 Oryginalna kwota operacji: 32.00 Numer karty: 42', '2025-09-28', 'seed-692b34cd3e57f82b'
  FROM categories c WHERE c.name = 'restauracje'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 36.0, 'Tytuł:  74838495269330652892482  Lokalizacja: Adres: ALL GOOD S.A. KAWIARNIA Miasto: WARSZAWA Kraj: POLSKA Data wykonania operacji: 2025-09-26 02:00 Oryginalna kwota operacji: 36.00 Numer karty: 42512', '2025-09-28', 'seed-aa649cf185a4787a'
  FROM categories c WHERE c.name = 'kawa'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 17.48, 'Tytuł:  74838495270330724922751  Lokalizacja: Adres: ROSSMANN 134 Miasto: WARSZAWA Kraj: POLSKA Data wykonania operacji: 2025-09-26 02:00 Oryginalna kwota operacji: 17.48 Numer karty: 425125******0264', '2025-09-28', 'seed-e379c6ed67e40e78'
  FROM categories c WHERE c.name = 'rossman'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 3.4, 'Tytuł: 000498849 74230785269176548066429  Lokalizacja: Adres: ZABKA Z7579 K.1 Miasto: POZNAN Kraj: POLSKA Data wykonania operacji: 2025-09-26 02:00 Oryginalna kwota operacji: 3.40 Numer karty: 425125*', '2025-09-28', 'seed-de224cb3e5162c3c'
  FROM categories c WHERE c.name = 'żabka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 192.36, 'Tytuł: 010075642 74987505267002215223060  Lokalizacja: Adres: aliexpress Miasto: Luxembourg Kraj: LUKSEMBURG Data wykonania operacji: 2025-09-24 02:00 Oryginalna kwota operacji: 192.36 Numer karty: 42', '2025-09-26', 'seed-dfda29e905c1411e'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 35.0, 'Tytuł: 000498849 74230785267176406506559  Lokalizacja: Adres: STRONA Miasto: POZNAN Kraj: POLSKA Data wykonania operacji: 2025-09-24 02:00 Oryginalna kwota operacji: 35.00 Numer karty: 425125******026', '2025-09-26', 'seed-c65fe9b48dc5a8bb'
  FROM categories c WHERE c.name = 'mieszkanie'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 5.0, 'Nazwa odbiorcy: MOBILE-TRAFFIC-DATA SP. Z O. O. Adres odbiorcy: UL. DRUŻBICKIEGO 11 61-693 POZNAŃ Tytuł: ZAKUP BILETU KOMUNIKACYJNEGO W APLI KACJI IKO  Referencje własne zleceniodawcy: 176107766843 (5', '2025-09-26', 'seed-96514cd487eb5ad8'
  FROM categories c WHERE c.name = 'przejazdy'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 69.0, 'Tytuł: 010061097 74463675266502673499677  Lokalizacja: Adres: WWW BILKOM PL Miasto: WARSZAWA Kraj: POLSKA Data wykonania operacji: 2025-09-23 02:00 Oryginalna kwota operacji: 69.00 Numer karty: 425125', '2025-09-25', 'seed-a3e03dc8a886ff32'
  FROM categories c WHERE c.name = 'przejazdy'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 154.99, 'Tytuł: 010082965 74987075267033369924975  Lokalizacja: Adres: Allegro Miasto: Poznan Kraj: POLSKA Data wykonania operacji: 2025-09-23 02:00 Oryginalna kwota operacji: 154.99 Numer karty: 425125******0', '2025-09-25', 'seed-9db746fa9138081d'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 69.0, 'Tytuł: 010061097 74463675266502673498729  Lokalizacja: Adres: WWW BILKOM PL Miasto: WARSZAWA Kraj: POLSKA Data wykonania operacji: 2025-09-23 02:00 Oryginalna kwota operacji: 69.00 Numer karty: 425125', '2025-09-25', 'seed-7bd73b2b5390792c'
  FROM categories c WHERE c.name = 'przejazdy'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 6.7, 'Tytuł: 000498849 74230785266176356630012  Lokalizacja: Adres: ZABKA Z0685 K.1 Miasto: POZNAN Kraj: POLSKA Data wykonania operacji: 2025-09-23 02:00 Oryginalna kwota operacji: 6.70 Numer karty: 425125*', '2025-09-25', 'seed-ce4b09e8cdfcb7c7'
  FROM categories c WHERE c.name = 'żabka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 39.98, 'Tytuł:  74838495266330165208153  Lokalizacja: Adres: PL KFC MOP MORZECINO S5 Miasto: MORZECINO Kraj: POLSKA Data wykonania operacji: 2025-09-22 02:00 Oryginalna kwota operacji: 39.98 Numer karty: 4251', '2025-09-25', 'seed-2d2fa8d6e774e423'
  FROM categories c WHERE c.name = 'restauracje'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 4.0, 'Tytuł:  74810315264170598641404  Lokalizacja: Adres: MYJNIA HENRYK DLUGOSZ Miasto: Kuznia Racibo Kraj: POLSKA Data wykonania operacji: 2025-09-21 02:00 Oryginalna kwota operacji: 4.00 Numer karty: 425', '2025-09-23', 'seed-3a6945a6f78ebfca'
  FROM categories c WHERE c.name = 'arval'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 40.0, 'Tytuł: 000498849 74230785264176192575225  Lokalizacja: Adres: STRONA Miasto: POZNAN Kraj: POLSKA Data wykonania operacji: 2025-09-20 02:00 Oryginalna kwota operacji: 40.00 Numer karty: 425125******026', '2025-09-22', 'seed-d717693871079a44'
  FROM categories c WHERE c.name = 'biuro'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 27.49, 'Tytuł:  74838495264329911833043  Lokalizacja: Adres: PL BK FOLWARK S5 MOP Miasto: DEBNO POLSKIE Kraj: POLSKA Data wykonania operacji: 2025-09-20 02:00 Oryginalna kwota operacji: 27.49 Numer karty: 425', '2025-09-22', 'seed-dde37385c5fe84b2'
  FROM categories c WHERE c.name = 'arval'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 4.0, 'Tytuł:  74810315263170545453789  Lokalizacja: Adres: MYJNIA HENRYK DLUGOSZ Miasto: Kuznia Racibo Kraj: POLSKA Data wykonania operacji: 2025-09-20 02:00 Oryginalna kwota operacji: 4.00 Numer karty: 425', '2025-09-22', 'seed-1e1892e53335d46d'
  FROM categories c WHERE c.name = 'arval'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 35.0, 'Tytuł: 000498849 74230785262176108661616  Lokalizacja: Adres: STRONA Miasto: POZNAN Kraj: POLSKA Data wykonania operacji: 2025-09-19 02:00 Oryginalna kwota operacji: 35.00 Numer karty: 425125******026', '2025-09-21', 'seed-e400755906c2f3a2'
  FROM categories c WHERE c.name = 'biedronka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 250.0, 'Tytuł: 010061097 74169505261632617078674  Lokalizacja: Adres: PRACOWNIA PSYCHOLOGICZNA Miasto: POZNAN Kraj: POLSKA Data wykonania operacji: 2025-09-18 02:00 Oryginalna kwota operacji: 250.00 Numer kar', '2025-09-20', 'seed-450bfda9c439d640'
  FROM categories c WHERE c.name = 'lekarz'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 149.99, 'Tytuł:  74838495262329586955693  Lokalizacja: Adres: AUCHAN POLSKA SP. Z  02 Miasto: POZNAN Kraj: POLSKA Data wykonania operacji: 2025-09-18 02:00 Oryginalna kwota operacji: 149.99 Numer karty: 425125', '2025-09-20', 'seed-47f884c8e7558c86'
  FROM categories c WHERE c.name = 'biedronka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 6.98, 'Tytuł: 000498849 74230785261176013694869  Lokalizacja: Adres: ZABKA Z0685 K.1 Miasto: POZNAN Kraj: POLSKA Data wykonania operacji: 2025-09-18 02:00 Oryginalna kwota operacji: 6.98 Numer karty: 425125*', '2025-09-20', 'seed-a2db2da2ca2c11df'
  FROM categories c WHERE c.name = 'żabka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 26.0, 'Tytuł:  74838495260329422575699  Lokalizacja: Adres: BRO. FOOD. BEER. CHILL. Miasto: POZNAN Kraj: POLSKA Data wykonania operacji: 2025-09-17 02:00 Oryginalna kwota operacji: 26.00 Numer karty: 425125*', '2025-09-19', 'seed-bad130ba9d6e2f48'
  FROM categories c WHERE c.name = 'restauracje'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 5.0, 'Nazwa odbiorcy: MOBILE-TRAFFIC-DATA SP. Z O. O. Adres odbiorcy: UL. DRUŻBICKIEGO 11 61-693 POZNAŃ Tytuł: ZAKUP BILETU KOMUNIKACYJNEGO W APLI KACJI IKO  Referencje własne zleceniodawcy: 176081731819 (5', '2025-09-18', 'seed-439761d024c93eec'
  FROM categories c WHERE c.name = 'przejazdy'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 5.0, 'Nazwa odbiorcy: MOBILE-TRAFFIC-DATA SP. Z O. O. Adres odbiorcy: UL. DRUŻBICKIEGO 11 61-693 POZNAŃ Tytuł: ZAKUP BILETU KOMUNIKACYJNEGO W APLI KACJI IKO  Referencje własne zleceniodawcy: 176081449130 (5', '2025-09-18', 'seed-7c7f7e82dfe5eaa5'
  FROM categories c WHERE c.name = 'przejazdy'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 14.99, 'Tytuł: 010066928 74056285259109272831134  Lokalizacja: Adres: APPLE.COM/BILL Miasto: APPLE.COM/BIL Kraj: IRLANDIA Data wykonania operacji: 2025-09-16 02:00 Oryginalna kwota operacji: 14.99 Numer karty', '2025-09-18', 'seed-75a831fd18b54c72'
  FROM categories c WHERE c.name = 'biuro'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 10.99, 'Tytuł: 000498849 74230785259175887298157  Lokalizacja: Adres: ZABKA Z0685 K.1 Miasto: POZNAN Kraj: POLSKA Data wykonania operacji: 2025-09-16 02:00 Oryginalna kwota operacji: 10.99 Numer karty: 425125', '2025-09-18', 'seed-1d375f81db7d8591'
  FROM categories c WHERE c.name = 'żabka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 5.0, 'Nazwa odbiorcy: MOBILE-TRAFFIC-DATA SP. Z O. O. Adres odbiorcy: UL. DRUŻBICKIEGO 11 61-693 POZNAŃ Tytuł: ZAKUP BILETU KOMUNIKACYJNEGO W APLI KACJI IKO  Referencje własne zleceniodawcy: 176080204077 (5', '2025-09-17', 'seed-70de91970470699c'
  FROM categories c WHERE c.name = 'przejazdy'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 94.0, 'Rachunek odbiorcy: 42 1090 1854 0000 0001 3287 4539 Nazwa odbiorcy: ODBIORCA PRZELEWU NA TELEFON Tytuł: PRZELEW NA TELEFON  OD: 48796555364 DO: 487*****756 (94.00 PLN)', '2025-09-17', 'seed-d9683b4dcbe86530'
  FROM categories c WHERE c.name = 'restauracje'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 5.0, 'Nazwa odbiorcy: MOBILE-TRAFFIC-DATA SP. Z O. O. Adres odbiorcy: UL. DRUŻBICKIEGO 11 61-693 POZNAŃ Tytuł: ZAKUP BILETU KOMUNIKACYJNEGO W APLI KACJI IKO  Referencje własne zleceniodawcy: 176079130729 (5', '2025-09-17', 'seed-c5023e5e23d9eb51'
  FROM categories c WHERE c.name = 'przejazdy'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 10.99, 'Tytuł: 000498849 74230785258175820246603  Lokalizacja: Adres: ZABKA Z0685 K.1 Miasto: POZNAN Kraj: POLSKA Data wykonania operacji: 2025-09-15 02:00 Oryginalna kwota operacji: 10.99 Numer karty: 425125', '2025-09-17', 'seed-247627a37cc3bf93'
  FROM categories c WHERE c.name = 'żabka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 73.0, 'Tytuł: 000498849 74230785257175765228195  Lokalizacja: Adres: STRONA Miasto: POZNAN Kraj: POLSKA Data wykonania operacji: 2025-09-14 02:00 Oryginalna kwota operacji: 73.00 Numer karty: 425125******026', '2025-09-16', 'seed-49cfb46308f9e4a1'
  FROM categories c WHERE c.name = 'biedronka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 5.5, 'Tytuł: 010061097 74169505257652570547420  Lokalizacja: Adres: FABRYKA FORMY POZNAN BALT Miasto: POZNAN Kraj: POLSKA Data wykonania operacji: 2025-09-14 02:00 Oryginalna kwota operacji: 5.50 Numer kart', '2025-09-16', 'seed-dc70b9958338be11'
  FROM categories c WHERE c.name = 'biedronka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 25.0, 'Tytuł: 00000090722718578   Numer telefonu: 48796555364 Lokalizacja: Adres: doladowania.t-mobile.pl ''Operacja: 00000090722718578 Numer referencyjny: 00000090722718578 (25.00 PLN)', '2025-09-15', 'seed-f6eadeaa10433e24'
  FROM categories c WHERE c.name = 'biuro'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 41.0, 'Tytuł: 010046551 74230105256060365187268  Lokalizacja: Adres: ZIOMAL DARIA JEZEWSKA Miasto: POZNAN Kraj: POLSKA Data wykonania operacji: 2025-09-13 02:00 Oryginalna kwota operacji: 41.00 Numer karty: ', '2025-09-15', 'seed-2cdc3ee92c049c11'
  FROM categories c WHERE c.name = 'kawa'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 14.1, 'Tytuł: 000498849 74230785256175687558019  Lokalizacja: Adres: EKO LAND Miasto: POZNAN Kraj: POLSKA Data wykonania operacji: 2025-09-13 02:00 Oryginalna kwota operacji: 14.10 Numer karty: 425125******0', '2025-09-15', 'seed-225ba0d4f6dcfc87'
  FROM categories c WHERE c.name = 'arval'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 43.98, 'Tytuł: 010061097 74169505256632566853538  Lokalizacja: Adres: APTEKA Miasto: POZNAN Kraj: POLSKA Data wykonania operacji: 2025-09-13 02:00 Oryginalna kwota operacji: 43.98 Numer karty: 425125******026', '2025-09-15', 'seed-966068aa181e0fbb'
  FROM categories c WHERE c.name = 'apteka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 38.0, 'Tytuł:  74838495256328822897972  Lokalizacja: Adres: MARIETTA Miasto: POZNAN Kraj: POLSKA Data wykonania operacji: 2025-09-13 02:00 Oryginalna kwota operacji: 38.00 Numer karty: 425125******0264 (38.0', '2025-09-15', 'seed-dac22235ef17d2d1'
  FROM categories c WHERE c.name = 'arval'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 220.99, 'Tytuł: 010087885 74987505256000707494044  Lokalizacja: Adres: BsCaffe Grzegorz Bienko Miasto: Stalowa Wola Kraj: POLSKA Data wykonania operacji: 2025-09-13 02:00 Oryginalna kwota operacji: 220.99 Nume', '2025-09-15', 'seed-08436333322db9ee'
  FROM categories c WHERE c.name = 'kawa'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 13.5, 'Tytuł: 010061097 74463675256622560965085  Lokalizacja: Adres: OKRUSZKI EWA PLANK Miasto: POZNAN Kraj: POLSKA Data wykonania operacji: 2025-09-13 02:00 Oryginalna kwota operacji: 13.50 Numer karty: 425', '2025-09-15', 'seed-c37ae40a7c0b417d'
  FROM categories c WHERE c.name = 'arval'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 13.98, 'Tytuł: 000498849 74230785255175648069719  Lokalizacja: Adres: ZABKA Z0685 K.1 Miasto: POZNAN Kraj: POLSKA Data wykonania operacji: 2025-09-12 02:00 Oryginalna kwota operacji: 13.98 Numer karty: 425125', '2025-09-14', 'seed-037a1e91dad43c73'
  FROM categories c WHERE c.name = 'żabka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 7.3, 'Tytuł: 000498849 74230785255175648061302  Lokalizacja: Adres: ZABKA Z0685 K.1 Miasto: POZNAN Kraj: POLSKA Data wykonania operacji: 2025-09-12 02:00 Oryginalna kwota operacji: 7.30 Numer karty: 425125*', '2025-09-14', 'seed-980a505c266494c7'
  FROM categories c WHERE c.name = 'żabka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 32.95, 'Tytuł: 000498849 74230785256175672143512  Lokalizacja: Adres: NETTO 5304 SCO K.1 Miasto: POZNAN Kraj: POLSKA Data wykonania operacji: 2025-09-12 02:00 Oryginalna kwota operacji: 32.95 Numer karty: 425', '2025-09-14', 'seed-634b206811b5311c'
  FROM categories c WHERE c.name = 'biedronka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 103.5, 'Rachunek odbiorcy: 21 1020 4027 3011 0000 3014 3739 Nazwa odbiorcy: INEA SP. Z O.O. Tytuł: RACHUNEK INTERNET (103.50 PLN)', '2025-09-14', 'seed-7c957016a9ee018f'
  FROM categories c WHERE c.name = 'mieszkanie'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 4.5, 'Tytuł: 010061097 74169505252642523388464  Lokalizacja: Adres: FABRYKA FORMY POZNAN BALT Miasto: POZNAN Kraj: POLSKA Data wykonania operacji: 2025-09-09 02:00 Oryginalna kwota operacji: 4.50 Numer kart', '2025-09-11', 'seed-4dac444055674a37'
  FROM categories c WHERE c.name = 'biedronka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 668.0, 'Tytuł:  74838495252328072926665  Lokalizacja: Adres: AUCHAN POLSKA SP. Z  02 Miasto: POZNAN Kraj: POLSKA Data wykonania operacji: 2025-09-08 02:00 Oryginalna kwota operacji: 668.00 Numer karty: 425125', '2025-09-10', 'seed-1380c56e5714a232'
  FROM categories c WHERE c.name = 'arval'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 250.0, 'Tytuł: 010061097 74169505251612515283115  Lokalizacja: Adres: PRACOWNIA PSYCHOLOGICZNA Miasto: POZNAN Kraj: POLSKA Data wykonania operacji: 2025-09-08 02:00 Oryginalna kwota operacji: 250.00 Numer kar', '2025-09-10', 'seed-01324c2279fa463e'
  FROM categories c WHERE c.name = 'lekarz'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 36.0, 'Tytuł: 010059127 74043215250139959469942  Lokalizacja: Adres: PPO Ladek East Miasto: Ladek Kraj: POLSKA Data wykonania operacji: 2025-09-07 02:00 Oryginalna kwota operacji: 36.00 Numer karty: 425125**', '2025-09-09', 'seed-535538be047039c4'
  FROM categories c WHERE c.name = 'arval'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 36.0, 'Tytuł: 010059127 74043215250139958594955  Lokalizacja: Adres: PPO Nagradowice East Miasto: Krerewo Kraj: POLSKA Data wykonania operacji: 2025-09-07 02:00 Oryginalna kwota operacji: 36.00 Numer karty: ', '2025-09-09', 'seed-6eff9408500ff3ec'
  FROM categories c WHERE c.name = 'arval'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 10.0, 'Tytuł: 00000090553699136   Numer telefonu: 48796555364 Lokalizacja: Adres: doladowania.t-mobile.pl ''Operacja: 00000090553699136 Numer referencyjny: 00000090553699136 (10.00 PLN)', '2025-09-08', 'seed-7f487009c502d5a5'
  FROM categories c WHERE c.name = 'biuro'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 10.0, 'Tytuł: 00000090551791198   Numer telefonu: 48796555364 Lokalizacja: Adres: doladuj.plus.pl ''Operacja: 00000090551791198 Numer referencyjny: 00000090551791198 (10.00 PLN)', '2025-09-08', 'seed-9d1aaf72e6e8e5ae'
  FROM categories c WHERE c.name = 'biuro'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 275.0, 'Rachunek odbiorcy: 73 1090 2372 0000 0001 1332 9442 Nazwa odbiorcy: MARTA SZCZYGIEŁ Tytuł: PRZELEW NA TELEFON  OD: 48796555364 DO: 486*****967 (275.00 PLN)', '2025-09-08', 'seed-2be142efa1f43ef3'
  FROM categories c WHERE c.name = 'mieszkanie'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 5.0, 'Nazwa odbiorcy: MOBILE-TRAFFIC-DATA SP. Z O. O. Adres odbiorcy: UL. DRUŻBICKIEGO 11 61-693 POZNAŃ Tytuł: ZAKUP BILETU KOMUNIKACYJNEGO W APLI KACJI IKO  Referencje własne zleceniodawcy: 176042656400 (5', '2025-09-08', 'seed-ff38ee7c2e7bc77a'
  FROM categories c WHERE c.name = 'przejazdy'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 5.0, 'Nazwa odbiorcy: MOBILE-TRAFFIC-DATA SP. Z O. O. Adres odbiorcy: UL. DRUŻBICKIEGO 11 61-693 POZNAŃ Tytuł: ZAKUP BILETU KOMUNIKACYJNEGO W APLI KACJI IKO  Referencje własne zleceniodawcy: 176042314377 (5', '2025-09-08', 'seed-c22b85f648601b5b'
  FROM categories c WHERE c.name = 'przejazdy'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 51.99, 'Tytuł: 000498849 74230785249175263651444  Lokalizacja: Adres: DINO DZIERZGOWO 1 K.1 Miasto: DZIERZGOWO Kraj: POLSKA Data wykonania operacji: 2025-09-06 02:00 Oryginalna kwota operacji: 51.99 Numer kar', '2025-09-08', 'seed-923d6bc706c3822c'
  FROM categories c WHERE c.name = 'biedronka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 98.0, 'Rachunek odbiorcy: 07 1140 2004 0000 3702 8112 2772 Nazwa odbiorcy: ODBIORCA PRZELEWU NA TELEFON Tytuł: PRZELEW NA TELEFON  OD: 48796555364 DO: 486*****680 (98.00 PLN)', '2025-09-07', 'seed-2aa5ee9bb5fb2a01'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 88.39, 'Tytuł: 000498849 74230785248175193049074  Lokalizacja: Adres: DINO DZIERZGOWO 1 K.1 Miasto: DZIERZGOWO Kraj: POLSKA Data wykonania operacji: 2025-09-05 02:00 Oryginalna kwota operacji: 88.39 Numer kar', '2025-09-07', 'seed-48f40a11fe930c89'
  FROM categories c WHERE c.name = 'biedronka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 15.5, 'Tytuł: 000498849 74230785248175185821290  Lokalizacja: Adres: ZABKA ZC500 K.1 Miasto: CHORZELE Kraj: POLSKA Data wykonania operacji: 2025-09-05 02:00 Oryginalna kwota operacji: 15.50 Numer karty: 4251', '2025-09-07', 'seed-c66f678d7383638a'
  FROM categories c WHERE c.name = 'żabka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 33.97, 'Tytuł:  74810315248168979236928  Lokalizacja: Adres: MARKET PRIM Miasto: Dzierzgowo Kraj: POLSKA Data wykonania operacji: 2025-09-05 02:00 Oryginalna kwota operacji: 33.97 Numer karty: 425125******026', '2025-09-07', 'seed-be2bc727d0fe669a'
  FROM categories c WHERE c.name = 'biedronka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 22.97, 'Tytuł:  74838495248327493836740  Lokalizacja: Adres: ORLEN STACJA NR 4075 Miasto: KLODAWA Kraj: POLSKA Data wykonania operacji: 2025-09-04 02:00 Oryginalna kwota operacji: 22.97 Numer karty: 425125***', '2025-09-06', 'seed-ea8cff25ec7ab87c'
  FROM categories c WHERE c.name = 'paliwo'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 36.0, 'Tytuł: 010059127 74043215247139666847337  Lokalizacja: Adres: PPO Ladek West Miasto: Ladek Kraj: POLSKA Data wykonania operacji: 2025-09-04 02:00 Oryginalna kwota operacji: 36.00 Numer karty: 425125**', '2025-09-06', 'seed-b9fe2dfc3e518e0a'
  FROM categories c WHERE c.name = 'arval'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 4.49, 'Tytuł:  74838495248327480366800  Lokalizacja: Adres: ORLEN STACJA NR 422 Miasto: POZNAN Kraj: POLSKA Data wykonania operacji: 2025-09-04 02:00 Oryginalna kwota operacji: 4.49 Numer karty: 425125******', '2025-09-06', 'seed-7da7f13b262538a2'
  FROM categories c WHERE c.name = 'paliwo'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 90.0, 'Tytuł:  74810315247168888203309  Lokalizacja: Adres: POLEWSKI CONCEPT Miasto: Poznan Kraj: POLSKA Data wykonania operacji: 2025-09-04 02:00 Oryginalna kwota operacji: 90.00 Numer karty: 425125******02', '2025-09-06', 'seed-521ee59e7f5d4338'
  FROM categories c WHERE c.name = 'biedronka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 21.49, 'Tytuł: 000498849 74230785247175101019533  Lokalizacja: Adres: ZABKA Z0685 K.1 Miasto: POZNAN Kraj: POLSKA Data wykonania operacji: 2025-09-04 02:00 Oryginalna kwota operacji: 21.49 Numer karty: 425125', '2025-09-06', 'seed-6381c3ef73c8c6c5'
  FROM categories c WHERE c.name = 'żabka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 36.0, 'Tytuł: 010059127 74043215247139657600307  Lokalizacja: Adres: PPO Nagradowice West Miasto: Krerewo Kraj: POLSKA Data wykonania operacji: 2025-09-04 02:00 Oryginalna kwota operacji: 36.00 Numer karty: ', '2025-09-06', 'seed-be597210d081aa76'
  FROM categories c WHERE c.name = 'arval'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 59.99, 'Tytuł:  74198745246535644463552  Lokalizacja: Adres: APPLE.COM/BILL Miasto: CORK Kraj: IRLANDIA Data wykonania operacji: 2025-09-02 02:00 Oryginalna kwota operacji: 59.99 Numer karty: 425125******0264', '2025-09-05', 'seed-f519f88ac85b338b'
  FROM categories c WHERE c.name = 'biuro'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 24.0, 'Tytuł: 010072511 74987505245001664671057  Lokalizacja: Adres: Zakwitanie Kwiaciarnia Miasto: Miedzylesie Kraj: POLSKA Data wykonania operacji: 2025-09-02 02:00 Oryginalna kwota operacji: 24.00 Numer k', '2025-09-04', 'seed-a09fdb7212316b20'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 250.0, 'Tytuł: 010061097 74169505244622444275934  Lokalizacja: Adres: PRACOWNIA PSYCHOLOGICZNA Miasto: POZNAN Kraj: POLSKA Data wykonania operacji: 2025-09-01 02:00 Oryginalna kwota operacji: 250.00 Numer kar', '2025-09-03', 'seed-7e7332a405e14401'
  FROM categories c WHERE c.name = 'lekarz'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 35.24, 'Tytuł: 010079564 74609055244100155769266  Lokalizacja: Adres: TIMELEFT Miasto: PARIS Kraj: FRANCJA Data wykonania operacji: 2025-09-01 02:00 Oryginalna kwota operacji: 35.24 Numer karty: 425125******0', '2025-09-03', 'seed-3e3cafdca2c1197e'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 375.0, 'Tytuł: 010085232 74350275244011364952517  Lokalizacja: Adres: Revolut**7108* Miasto: Dublin Kraj: IRLANDIA Data wykonania operacji: 2025-09-01 02:00 Oryginalna kwota operacji: 375.00 Numer karty: 4251', '2025-09-03', 'seed-36693423ccda54eb'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 1280.0, 'Rachunek odbiorcy: 73 1090 2372 0000 0001 1332 9442 Nazwa odbiorcy: MARTA SZCZYGIEŁ Tytuł: PRZELEW NA TELEFON  OD: 48796555364 DO: 486*****967 (1280.00 PLN)', '2025-09-03', 'seed-10e8ff3d2db4d6de'
  FROM categories c WHERE c.name = 'mieszkanie'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 363.0, 'Rachunek odbiorcy: 21 1940 1076 6256 6800 0000 0000 Nazwa odbiorcy: ADAM TYŻYK Tytuł: 12 MP/09/2025 (363.00 PLN)', '2025-09-02', 'seed-42674fcfeac0aa3e'
  FROM categories c WHERE c.name = 'mieszkanie'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 9.45, 'Tytuł: 010046551 74810255243060028934053  Lokalizacja: Adres: PAYMOVE SP. Z O.O. Miasto: Sopot Kraj: POLSKA Data wykonania operacji: 2025-08-31 02:00 Oryginalna kwota operacji: 9.45 Numer karty: 42512', '2025-09-02', 'seed-7b39c71974d0bd5f'
  FROM categories c WHERE c.name = 'arval'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 99.58, 'Tytuł: 010062941 74987505243000217363065  Lokalizacja: Adres: Pyszne.pl Miasto: Wroclaw Kraj: POLSKA Data wykonania operacji: 2025-08-31 02:00 Oryginalna kwota operacji: 99.58 Numer karty: 425125*****', '2025-09-02', 'seed-8802d1d84ac705b1'
  FROM categories c WHERE c.name = 'restauracje'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 5.0, 'Nazwa odbiorcy: MOBILE-TRAFFIC-DATA SP. Z O. O. Adres odbiorcy: UL. DRUŻBICKIEGO 11 61-693 POZNAŃ Tytuł: ZAKUP BILETU KOMUNIKACYJNEGO W APLI KACJI IKO  Referencje własne zleceniodawcy: 176017174323 (5', '2025-09-01', 'seed-c048bb13ebe64f7e'
  FROM categories c WHERE c.name = 'przejazdy'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 30.0, 'Tytuł: 00000090417713896   Numer telefonu: 48796555364 Lokalizacja: Adres: www.mobilet.pl ''Operacja: 00000090417713896 Numer referencyjny: 00000090417713896 (30.00 PLN)', '2025-09-01', 'seed-42b0c24d99801183'
  FROM categories c WHERE c.name = 'przejazdy'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 10.99, 'Tytuł: 000498849 74230785242174746083678  Lokalizacja: Adres: ZABKA ZB103 K.2 Miasto: SOPOT Kraj: POLSKA Data wykonania operacji: 2025-08-30 02:00 Oryginalna kwota operacji: 10.99 Numer karty: 425125*', '2025-09-01', 'seed-bfedc7cb88cc5c4c'
  FROM categories c WHERE c.name = 'żabka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 159.0, 'Tytuł:  24037345242112655301205  Lokalizacja: Adres: ESPRESSO BROTHERS S C Miasto: Gdynia Kraj: POLSKA Data wykonania operacji: 2025-08-30 02:00 Oryginalna kwota operacji: 159.00 Numer karty: 425125**', '2025-09-01', 'seed-751d0c56988308da'
  FROM categories c WHERE c.name = 'kawa'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 18.59, 'Tytuł: 010059127 74043215242139136646819  Lokalizacja: Adres: Cosmedica Sp. z o.o. Miasto: Sopot Kraj: POLSKA Data wykonania operacji: 2025-08-30 02:00 Oryginalna kwota operacji: 18.59 Numer karty: 42', '2025-09-01', 'seed-9fd949ac36eaab19'
  FROM categories c WHERE c.name = 'arval'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 20.0, 'Tytuł:  74838495243326603758336  Lokalizacja: Adres: MOLO NR 4 03 Miasto: SOPOT Kraj: POLSKA Data wykonania operacji: 2025-08-30 02:00 Oryginalna kwota operacji: 20.00 Numer karty: 425125******0264 (2', '2025-09-01', 'seed-02ade0e26c960272'
  FROM categories c WHERE c.name = 'paliwo'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 204.0, 'Tytuł:  24037345242112422848876  Lokalizacja: Adres: ESPRESSO BROTHERS S C Miasto: Gdynia Kraj: POLSKA Data wykonania operacji: 2025-08-30 02:00 Oryginalna kwota operacji: 204.00 Numer karty: 425125**', '2025-09-01', 'seed-3c6f5a6a22b4baef'
  FROM categories c WHERE c.name = 'kawa'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 1592.0, 'BRAVE Courses sp. z o.o. Głogowska 216 60-104 Poznań, Polska NIP 7822914959   Faktura Proforma numer recMgnw9iqNyWPIXm', '2025-09-29', 'seed-c604ee16d9b329c4'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 229.58, 'Softwaremill S.A. ul. Na Uboczu 8/87 02-791 Warszawa   FV MS/005/09/2025', '2025-09-29', 'seed-c9eec6aab9b26259'
  FROM categories c WHERE c.name = 'biuro'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 360.0, 'LOUVRE HOTELS GROUP  Warszawa  POL   Płatność kartą 26.09.2025 Nr karty 4598xx4778', '2025-09-26', 'seed-a664f141ab60c568'
  FROM categories c WHERE c.name = 'biuro'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 381.87, 'KANCELARIA PODATKOWO-GOSPODARCZA SP ÓŁKA Z OGRANICZONĄ ODPOWIEDZIALNOŚC IĄ ul. Radomska 7 44-164 Gliwice NI P: PL 631-264-51-93   FA/69/09/2025', '2025-09-26', 'seed-b4600e5015cb118f'
  FROM categories c WHERE c.name = 'biuro'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 209.28, 'ORLEN STACJA NR 199  KUZNIA RACIBO   Płatność kartą 22.09.2025 Nr karty 4598xx4778', '2025-09-22', 'seed-b44c010dd8d12fc7'
  FROM categories c WHERE c.name = 'paliwo'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 152.27, 'ORLEN STACJA NR 404  POZNAN  POL   Płatność kartą 20.09.2025 Nr karty 4598xx4778', '2025-09-20', 'seed-9005dab22400f30b'
  FROM categories c WHERE c.name = 'paliwo'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 260.0, 'STREFA PIELEGNACJI  POZNAN  POL   Płatność kartą 17.09.2025 Nr karty 4598xx4778', '2025-09-17', 'seed-56489e9aa528f487'
  FROM categories c WHERE c.name = 'arval'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 1099.0, 'TERG SPÓŁKA AKCYJNA Za Dworcem 1D Złotów   Płatność BLIK 15.09.2025 Nr transakcji 90749360119 www.mediaexpert.pl', '2025-09-15', 'seed-3b534b3a29c55639'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 3213.25, 'Zakład Ubezpieczeń Społecznych 47-400 Racibórz   Ubezpieczenie zdrowotne 08.2025', '2025-09-15', 'seed-3eb52aa7ca10d71f'
  FROM categories c WHERE c.name = 'zus'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 12.0, 'Urząd Skarbowy Centrum Rozliczeniowe   /TI/N6392015837/OKR/25M08/SFP/PIT4R', '2025-09-15', 'seed-7d677cc13fd9863c'
  FROM categories c WHERE c.name = 'pit36'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 3268.0, 'Urząd Skarbowy Centrum Rozliczeniowe   /TI/N6392015837/OKR/25M08/SFP/PPE', '2025-09-15', 'seed-2b7fc2665685b14d'
  FROM categories c WHERE c.name = 'pit36'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 5619.0, 'Urząd Skarbowy Centrum Rozliczeniowe   /TI/N6392015837/OKR/25M08/SFP/VAT7', '2025-09-15', 'seed-fe26eb276e6966bf'
  FROM categories c WHERE c.name = 'vat'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 224.51, 'ORLEN STACJA NR 403  GOSTYNIN  POL   Płatność kartą 07.09.2025 Nr karty 4598xx4778', '2025-09-07', 'seed-f226ccb558e5c624'
  FROM categories c WHERE c.name = 'paliwo'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 264.39, 'ORLEN STACJA NR 422  POZNAN  POL   Płatność kartą 04.09.2025 Nr karty 4598xx4778', '2025-09-04', 'seed-40aff2ef7c0a0093'
  FROM categories c WHERE c.name = 'paliwo'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 2252.71, 'BNP Paribas Leasing Services Sp. z o.o. 00-844 Warszawa, ul.Grzybowska 78   40229/09/2025/RL/LS', '2025-09-04', 'seed-18b90b79305c9057'
  FROM categories c WHERE c.name = 'arval'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 82.29, 'Orange Polska S.A. Aleje Jerozolimskie 160 02-326 Warszawa NIP 526-025-09-95   F0083222849/009/25', '2025-09-04', 'seed-6345ef55a37b2d86'
  FROM categories c WHERE c.name = 'biuro'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 247.1, 'P4 Sp. z o.o. ul. Wynalazek 1 02-677 Warszawa   F/10176247/09/25', '2025-09-04', 'seed-21f22778a3c91c53'
  FROM categories c WHERE c.name = 'biuro'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 17.6, 'Nazwa odbiorcy: PKO BP FINAT SP. Z O.O. Adres odbiorcy: UL. CHMIELNA 89 00-805 WARSZAWA Tytuł: OPŁ. ZA PRZEJAZD A1, PPO RUSOCIN - SPO NOWE MARZY, NR TRANS. 7247481, 2025-08-31 (17.60 PLN)', '2025-08-31', 'seed-50dc9714164729ea'
  FROM categories c WHERE c.name = 'arval'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 33.3, 'Tytuł:  74838495242326520637648  Lokalizacja: Adres: MCDONALDS Miasto: ZNIN Kraj: POLSKA Data wykonania operacji: 2025-08-29 02:00 Oryginalna kwota operacji: 33.30 Numer karty: 425125******0264 (33.30', '2025-08-31', 'seed-5d39f7fb703421dd'
  FROM categories c WHERE c.name = 'restauracje'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 4.5, 'Tytuł: 010061097 74169505240642405692236  Lokalizacja: Adres: FABRYKA FORMY POZNAN BALT Miasto: POZNAN Kraj: POLSKA Data wykonania operacji: 2025-08-28 02:00 Oryginalna kwota operacji: 4.50 Numer kart', '2025-08-30', 'seed-e8dd9fbe17a08a6c'
  FROM categories c WHERE c.name = 'biedronka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 17.6, 'Nazwa odbiorcy: PKO BP FINAT SP. Z O.O. Adres odbiorcy: UL. CHMIELNA 89 00-805 WARSZAWA Tytuł: OPŁ. ZA PRZEJAZD A1, SPO NOWE MARZY - PPO RUSOCIN, NR TRANS. 7234794, 2025-08-29 (17.60 PLN)', '2025-08-29', 'seed-019eb4a97a9ed049'
  FROM categories c WHERE c.name = 'paliwo'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 1330.0, 'Tytuł: 010085232 74350275240011302158361  Lokalizacja: Adres: Revolut**7108* Miasto: Dublin Kraj: IRLANDIA Data wykonania operacji: 2025-08-28 02:00 Oryginalna kwota operacji: 1330.00 Numer karty: 425', '2025-08-29', 'seed-a6533ad04247cb3b'
  FROM categories c WHERE c.name = 'mieszkanie'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 2.99, 'Tytuł: 000498849 74230785238174464778646  Lokalizacja: Adres: ZABKA Z0685 K.1 Miasto: POZNAN Kraj: POLSKA Data wykonania operacji: 2025-08-26 02:00 Oryginalna kwota operacji: 2.99 Numer karty: 425125*', '2025-08-28', 'seed-b49b3551326fbf57'
  FROM categories c WHERE c.name = 'żabka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 43.93, 'Tytuł: 000498849 74230785239174504801431  Lokalizacja: Adres: NETTO 5304 SCO K.3 Miasto: POZNAN Kraj: POLSKA Data wykonania operacji: 2025-08-26 02:00 Oryginalna kwota operacji: 43.93 Numer karty: 425', '2025-08-28', 'seed-c31757c487cf1779'
  FROM categories c WHERE c.name = 'biedronka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 25.49, 'Tytuł:  74838495237325811450841  Lokalizacja: Adres: ZIKO APTEKA 05 Miasto: Poznan Kraj: POLSKA Data wykonania operacji: 2025-08-25 02:00 Oryginalna kwota operacji: 25.49 Numer karty: 425125******0264', '2025-08-27', 'seed-9e6b012228a3c9da'
  FROM categories c WHERE c.name = 'apteka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 250.0, 'Tytuł: 010061097 74169505237622371858909  Lokalizacja: Adres: PRACOWNIA PSYCHOLOGICZNA Miasto: POZNAN Kraj: POLSKA Data wykonania operacji: 2025-08-25 02:00 Oryginalna kwota operacji: 250.00 Numer kar', '2025-08-27', 'seed-df7fc389846b6f29'
  FROM categories c WHERE c.name = 'lekarz'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 450.0, 'Rachunek odbiorcy: 73 1090 2372 0000 0001 1332 9442 Nazwa odbiorcy: MARTA SZCZYGIEŁ Tytuł: PRZELEW NA TELEFON  OD: 48796555364 DO: 486*****967 (450.00 PLN)', '2025-08-26', 'seed-ed460659f9828766'
  FROM categories c WHERE c.name = 'mieszkanie'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 19.98, 'Tytuł: 000498849 74230785236174338351234  Lokalizacja: Adres: ZABKA ZA319 K.1 Miasto: ZABKOWICE SLA Kraj: POLSKA Data wykonania operacji: 2025-08-24 02:00 Oryginalna kwota operacji: 19.98 Numer karty:', '2025-08-26', 'seed-fad6dc80189a58f8'
  FROM categories c WHERE c.name = 'żabka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 12.0, 'Tytuł:  74838495237325767042980  Lokalizacja: Adres: ORLEN STACJA NR 4497 Miasto: WISZNIA MALA Kraj: POLSKA Data wykonania operacji: 2025-08-24 02:00 Oryginalna kwota operacji: 12.00 Numer karty: 4251', '2025-08-26', 'seed-9690842aef481d17'
  FROM categories c WHERE c.name = 'paliwo'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 257.0, 'Tytuł: 010085232 74350275236011256854938  Lokalizacja: Adres: Revolut**7108* Miasto: Dublin Kraj: IRLANDIA Data wykonania operacji: 2025-08-24 02:00 Oryginalna kwota operacji: 257.00 Numer karty: 4251', '2025-08-26', 'seed-4686598ad431fb28'
  FROM categories c WHERE c.name = 'krypto'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 4.0, 'Nazwa odbiorcy: MOBILE-TRAFFIC-DATA SP. Z O. O. Adres odbiorcy: UL. DRUŻBICKIEGO 11 61-693 POZNAŃ Tytuł: ZAKUP BILETU KOMUNIKACYJNEGO W APLI KACJI IKO  Referencje własne zleceniodawcy: 175993463979 (4', '2025-08-25', 'seed-eb9d7cf351535978'
  FROM categories c WHERE c.name = 'przejazdy'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 4.0, 'Nazwa odbiorcy: MOBILE-TRAFFIC-DATA SP. Z O. O. Adres odbiorcy: UL. DRUŻBICKIEGO 11 61-693 POZNAŃ Tytuł: ZAKUP BILETU KOMUNIKACYJNEGO W APLI KACJI IKO  Referencje własne zleceniodawcy: 175993238556 (4', '2025-08-25', 'seed-13e831c665af2300'
  FROM categories c WHERE c.name = 'przejazdy'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 38.0, 'Tytuł:  74410495235026071281722  Lokalizacja: Adres: Klubokawiarnia Kl33384 Miasto: Gliwice Kraj: POLSKA Data wykonania operacji: 2025-08-23 02:00 Oryginalna kwota operacji: 38.00 Numer karty: 425125*', '2025-08-25', 'seed-7922c4cc56ca2582'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 5.0, 'Tytuł: 010061097 74463675235592353807396  Lokalizacja: Adres: MYJNIA SZPITALNA KNUROW Miasto: KNUROW Kraj: POLSKA Data wykonania operacji: 2025-08-22 02:00 Oryginalna kwota operacji: 5.00 Numer karty:', '2025-08-25', 'seed-226171e7bb35fb50'
  FROM categories c WHERE c.name = 'pit36'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 5.0, 'Tytuł: 010061097 74463675235592353804807  Lokalizacja: Adres: MYJNIA SZPITALNA KNUROW Miasto: KNUROW Kraj: POLSKA Data wykonania operacji: 2025-08-22 02:00 Oryginalna kwota operacji: 5.00 Numer karty:', '2025-08-25', 'seed-51e4312ca57f8042'
  FROM categories c WHERE c.name = 'pit36'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 5.0, 'Tytuł: 010061097 74463675235592353805432  Lokalizacja: Adres: MYJNIA SZPITALNA KNUROW Miasto: KNUROW Kraj: POLSKA Data wykonania operacji: 2025-08-22 02:00 Oryginalna kwota operacji: 5.00 Numer karty:', '2025-08-25', 'seed-fbad2e6d12e18bb0'
  FROM categories c WHERE c.name = 'pit36'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 5.0, 'Tytuł: 010061097 74463675235592353804310  Lokalizacja: Adres: MYJNIA SZPITALNA KNUROW Miasto: KNUROW Kraj: POLSKA Data wykonania operacji: 2025-08-22 02:00 Oryginalna kwota operacji: 5.00 Numer karty:', '2025-08-25', 'seed-39c9b28e143b354a'
  FROM categories c WHERE c.name = 'pit36'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 32.0, 'Tytuł:  74410495234026059057525  Lokalizacja: Adres: Klubokawiarnia Kl33384 Miasto: Gliwice Kraj: POLSKA Data wykonania operacji: 2025-08-22 02:00 Oryginalna kwota operacji: 32.00 Numer karty: 425125*', '2025-08-24', 'seed-46b4d6c4cd089c72'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 2.5, 'Tytuł: 010059127 74043215234138270482650  Lokalizacja: Adres: SPP w Gliwicach, Strefa B Miasto: GLIWICE Kraj: POLSKA Data wykonania operacji: 2025-08-22 02:00 Oryginalna kwota operacji: 2.50 Numer kar', '2025-08-24', 'seed-57bb81c390d9cc51'
  FROM categories c WHERE c.name = 'arval'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 50.0, 'Tytuł:  74810315234167636480404  Lokalizacja: Adres: ORANGE POT Miasto: Gliwice Kraj: POLSKA Data wykonania operacji: 2025-08-22 02:00 Oryginalna kwota operacji: 50.00 Numer karty: 425125******0264 (5', '2025-08-24', 'seed-e31b3b846bd00839'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 24.0, 'Tytuł:  74410495234026058668967  Lokalizacja: Adres: Klubokawiarnia Kl33384 Miasto: Gliwice Kraj: POLSKA Data wykonania operacji: 2025-08-22 02:00 Oryginalna kwota operacji: 24.00 Numer karty: 425125*', '2025-08-24', 'seed-97938d904fc4e4d1'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 9.99, 'Tytuł: 000498849 74230785233174134633481  Lokalizacja: Adres: ZABKA Z1521 K.1 Miasto: POZNAN Kraj: POLSKA Data wykonania operacji: 2025-08-21 02:00 Oryginalna kwota operacji: 9.99 Numer karty: 425125*', '2025-08-23', 'seed-c14b7ff114dc32a3'
  FROM categories c WHERE c.name = 'żabka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 123.96, 'Tytuł:  74838495234325321362836  Lokalizacja: Adres: LIDL 1884 Miasto: POZNAN Kraj: POLSKA Data wykonania operacji: 2025-08-21 02:00 Oryginalna kwota operacji: 123.96 Numer karty: 425125******0264 (12', '2025-08-23', 'seed-c5073af59dca0887'
  FROM categories c WHERE c.name = 'biedronka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 32.78, 'Tytuł: 000498707 74987075234032245599605  Lokalizacja: Adres: ebookpoint.pl Miasto: Gliwice Kraj: POLSKA Data wykonania operacji: 2025-08-21 02:00 Oryginalna kwota operacji: 32.78 Numer karty: 425125*', '2025-08-23', 'seed-32406dbbbf796bc1'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 49.0, 'Tytuł: 010062941 74987505233002779419022  Lokalizacja: Adres: Amazon Prime*3NFtz5YXPxqt Miasto: Warsaw Kraj: POLSKA Data wykonania operacji: 2025-08-21 02:00 Oryginalna kwota operacji: 49.00 Numer kar', '2025-08-23', 'seed-9012dba5d0fd1493'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 250.0, 'Tytuł: 010061097 74169505230622302048619  Lokalizacja: Adres: PRACOWNIA PSYCHOLOGICZNA Miasto: POZNAN Kraj: POLSKA Data wykonania operacji: 2025-08-18 02:00 Oryginalna kwota operacji: 250.00 Numer kar', '2025-08-20', 'seed-2e45eb05c92ae3fa'
  FROM categories c WHERE c.name = 'lekarz'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 326.27, 'Tytuł:  74838495230324727478530  Lokalizacja: Adres: ZIKO APTEKA 05 Miasto: Poznan Kraj: POLSKA Data wykonania operacji: 2025-08-18 02:00 Oryginalna kwota operacji: 326.27 Numer karty: 425125******026', '2025-08-20', 'seed-0b6821b2735811e2'
  FROM categories c WHERE c.name = 'apteka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 293.0, 'Tytuł: 000498849 74230785229173845830275  Lokalizacja: Adres: WINNOW Miasto: POZNAN Kraj: POLSKA Data wykonania operacji: 2025-08-17 02:00 Oryginalna kwota operacji: 293.00 Numer karty: 425125******02', '2025-08-19', 'seed-332761f5c41d082d'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 4.0, 'Nazwa odbiorcy: MOBILE-TRAFFIC-DATA SP. Z O. O. Adres odbiorcy: UL. DRUŻBICKIEGO 11 61-693 POZNAŃ Tytuł: ZAKUP BILETU KOMUNIKACYJNEGO W APLI KACJI IKO  Referencje własne zleceniodawcy: 175970525518 (4', '2025-08-18', 'seed-d2d9aac4558b6286'
  FROM categories c WHERE c.name = 'przejazdy'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 4.0, 'Nazwa odbiorcy: MOBILE-TRAFFIC-DATA SP. Z O. O. Adres odbiorcy: UL. DRUŻBICKIEGO 11 61-693 POZNAŃ Tytuł: ZAKUP BILETU KOMUNIKACYJNEGO W APLI KACJI IKO  Referencje własne zleceniodawcy: 175970249651 (4', '2025-08-18', 'seed-4fa91be509632443'
  FROM categories c WHERE c.name = 'przejazdy'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 10.99, 'Tytuł: 000498849 74230785228173796106759  Lokalizacja: Adres: ZABKA Z0685 K.1 Miasto: POZNAN Kraj: POLSKA Data wykonania operacji: 2025-08-16 02:00 Oryginalna kwota operacji: 10.99 Numer karty: 425125', '2025-08-18', 'seed-9c44c446291af2c2'
  FROM categories c WHERE c.name = 'żabka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 14.99, 'Tytuł: 010066928 74056285228101059241965  Lokalizacja: Adres: APPLE.COM/BILL Miasto: APPLE.COM/BIL Kraj: IRLANDIA Data wykonania operacji: 2025-08-16 02:00 Oryginalna kwota operacji: 14.99 Numer karty', '2025-08-18', 'seed-0cba4121ba94b295'
  FROM categories c WHERE c.name = 'biuro'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 44.0, 'Tytuł: 010059127 74043215227137522367890  Lokalizacja: Adres: SPO Jordanowo Miasto: Swiebodzin Kraj: POLSKA Data wykonania operacji: 2025-08-15 02:00 Oryginalna kwota operacji: 44.00 Numer karty: 4251', '2025-08-17', 'seed-cebac8c5d025188e'
  FROM categories c WHERE c.name = 'arval'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 111.0, 'Tytuł:  74838495228324368762758  Lokalizacja: Adres: RYORI Miasto: BOLESLAWIEC Kraj: POLSKA Data wykonania operacji: 2025-08-15 02:00 Oryginalna kwota operacji: 111.00 Numer karty: 425125******0264 (1', '2025-08-17', 'seed-30a0f72bdb8cdb33'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 1.0, 'Tytuł: 010061097 74463675227612279476249  Lokalizacja: Adres: GMINA M BOLESLAWIEC WEW Miasto: BOLESLAWIEC Kraj: POLSKA Data wykonania operacji: 2025-08-15 02:00 Oryginalna kwota operacji: 1.00 Numer k', '2025-08-17', 'seed-5abd182d873f650b'
  FROM categories c WHERE c.name = 'arval'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 132.78, 'Tytuł: 010075642 74987505225002425125064  Lokalizacja: Adres: aliexpress Miasto: Luxembourg Kraj: LUKSEMBURG Data wykonania operacji: 2025-08-13 02:00 Oryginalna kwota operacji: 132.78 Numer karty: 42', '2025-08-15', 'seed-3def5b0bfea19996'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 64.0, 'Tytuł: 010046551 74796055224059576588795  Lokalizacja: Adres: MIELS SP. Z O.O. Miasto: POZNAN Kraj: POLSKA Data wykonania operacji: 2025-08-12 02:00 Oryginalna kwota operacji: 64.00 Numer karty: 42512', '2025-08-14', 'seed-4fc64def5a0b1139'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 9.2, 'Tytuł: 000498849 74230785224173489193878  Lokalizacja: Adres: ZABKA Z3341 K.2 Miasto: POZNAN Kraj: POLSKA Data wykonania operacji: 2025-08-12 02:00 Oryginalna kwota operacji: 9.20 Numer karty: 425125*', '2025-08-14', 'seed-0f781a6f29aa2cc9'
  FROM categories c WHERE c.name = 'żabka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 220.0, 'Tytuł:  74838495224323793485534  Lokalizacja: Adres: MITTE Miasto: POZNAN Kraj: POLSKA Data wykonania operacji: 2025-08-12 02:00 Oryginalna kwota operacji: 220.00 Numer karty: 425125******0264 (220.00', '2025-08-14', 'seed-27c511494f5e9584'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 103.5, 'Rachunek odbiorcy: 21 1020 4027 3011 0000 3014 3739 Nazwa odbiorcy: INEA SP. Z O.O. Tytuł: RACHUNEK INTERNET (103.50 PLN)', '2025-08-14', 'seed-4b774ba65272c758'
  FROM categories c WHERE c.name = 'mieszkanie'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 250.0, 'Tytuł: 010061097 74169505223612239538922  Lokalizacja: Adres: PRACOWNIA PSYCHOLOGICZNA Miasto: POZNAN Kraj: POLSKA Data wykonania operacji: 2025-08-11 02:00 Oryginalna kwota operacji: 250.00 Numer kar', '2025-08-13', 'seed-c88a3bdff8530396'
  FROM categories c WHERE c.name = 'lekarz'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 2450.0, 'Rachunek odbiorcy: 48 1540 1157 8129 0000 0084 2846 Nazwa odbiorcy: DM BOŚ Tytuł: PRZELEW   Referencje własne zleceniodawcy: 175954191198 (2450.00 PLN)', '2025-08-12', 'seed-0bfa7df7329085df'
  FROM categories c WHERE c.name = 'inwestycje'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 15.18, 'Tytuł:  74838495223323556561613  Lokalizacja: Adres: ORLEN STACJA NR 1363 Miasto: NOWE MIASTO N Kraj: POLSKA Data wykonania operacji: 2025-08-10 02:00 Oryginalna kwota operacji: 15.18 Numer karty: 425', '2025-08-12', 'seed-813611357d70741c'
  FROM categories c WHERE c.name = 'paliwo'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 4.0, 'Nazwa odbiorcy: MOBILE-TRAFFIC-DATA SP. Z O. O. Adres odbiorcy: UL. DRUŻBICKIEGO 11 61-693 POZNAŃ Tytuł: ZAKUP BILETU KOMUNIKACYJNEGO W APLI KACJI IKO  Referencje własne zleceniodawcy: 175947325457 (4', '2025-08-11', 'seed-ca2be771c19dfec1'
  FROM categories c WHERE c.name = 'przejazdy'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 4.5, 'Tytuł: 000498849 74230785221173285893138  Lokalizacja: Adres: ZABKA Z0685 K.1 Miasto: POZNAN Kraj: POLSKA Data wykonania operacji: 2025-08-09 02:00 Oryginalna kwota operacji: 4.50 Numer karty: 425125*', '2025-08-11', 'seed-ae847912d432f878'
  FROM categories c WHERE c.name = 'żabka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 4.0, 'Nazwa odbiorcy: MOBILE-TRAFFIC-DATA SP. Z O. O. Adres odbiorcy: UL. DRUŻBICKIEGO 11 61-693 POZNAŃ Tytuł: ZAKUP BILETU KOMUNIKACYJNEGO W APLI KACJI IKO  Referencje własne zleceniodawcy: 175946976142 (4', '2025-08-11', 'seed-319ee43fb98fd6b2'
  FROM categories c WHERE c.name = 'przejazdy'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 55.59, 'Tytuł: 010062941 74987505220002634025084  Lokalizacja: Adres: Wolt Miasto: Warszawa Kraj: POLSKA Data wykonania operacji: 2025-08-08 02:00 Oryginalna kwota operacji: 55.59 Numer karty: 425125******026', '2025-08-10', 'seed-25e41a9e0bc15ad8'
  FROM categories c WHERE c.name = 'arval'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 2200.0, 'Tytuł: S1PO2028 4278 00000089967639762   Numer telefonu: 48796555364 Lokalizacja: Adres: UL. ROOSEVELTA 11 Miasto: POZNAN Kraj: POLSKA Bankomat: S1PO2028 ''Operacja: 4278 00000089967639762 Numer refer', '2025-08-08', 'seed-7ba97f0f59674a24'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 104.0, 'Tytuł: 00000089957715620   Numer telefonu: 48796555364 Lokalizacja: Adres: allegro.pl ''Operacja: 00000089957715620 Numer referencyjny: 00000089957715620 (104.00 PLN)', '2025-08-08', 'seed-144ed6e6323d5613'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 4.0, 'Nazwa odbiorcy: MOBILE-TRAFFIC-DATA SP. Z O. O. Adres odbiorcy: UL. DRUŻBICKIEGO 11 61-693 POZNAŃ Tytuł: ZAKUP BILETU KOMUNIKACYJNEGO W APLI KACJI IKO  Referencje własne zleceniodawcy: 175933493239 (4', '2025-08-07', 'seed-59e3cb46185c7c73'
  FROM categories c WHERE c.name = 'przejazdy'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 151.47, 'Tytuł: 010072805 24871155217110634490886  Lokalizacja: Adres: ALIEXPRESS.COM Miasto: Luxembourg Kraj: LUKSEMBURG Data wykonania operacji: 2025-08-05 02:00 Oryginalna kwota operacji: 151.47 Numer karty', '2025-08-07', 'seed-499bc3f0709d22d1'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 200.0, 'Tytuł: 010085232 74350275217010981313684  Lokalizacja: Adres: Revolut**7108* Miasto: Dublin Kraj: IRLANDIA Data wykonania operacji: 2025-08-05 02:00 Oryginalna kwota operacji: 200.00 Numer karty: 4251', '2025-08-07', 'seed-494b580d31338b9b'
  FROM categories c WHERE c.name = 'krypto'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 87.04, 'Tytuł:  74838495218322801426967  Lokalizacja: Adres: LIDL SZWEDZKA Miasto: POZNAN Kraj: POLSKA Data wykonania operacji: 2025-08-05 02:00 Oryginalna kwota operacji: 87.04 Numer karty: 425125******0264 ', '2025-08-07', 'seed-d22597f4497d4921'
  FROM categories c WHERE c.name = 'arval'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 409.08, 'Tytuł: 00000089943034627   Numer telefonu: 48796555364 Lokalizacja: Adres: allegro.pl ''Operacja: 00000089943034627 Numer referencyjny: 00000089943034627 (409.08 PLN)', '2025-08-07', 'seed-cbb9b67796e879fe'
  FROM categories c WHERE c.name = 'rossman'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 125.0, 'Tytuł: 010061097 74169505216612166740227  Lokalizacja: Adres: PRACOWNIA PSYCHOLOGICZNA Miasto: POZNAN Kraj: POLSKA Data wykonania operacji: 2025-08-04 02:00 Oryginalna kwota operacji: 125.00 Numer kar', '2025-08-06', 'seed-2b2a22633ffd5731'
  FROM categories c WHERE c.name = 'lekarz'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 22.0, 'Tytuł: 000498849 74230785216172902461383  Lokalizacja: Adres: SOUP CULTURE ROSWELL Miasto: POZNAN Kraj: POLSKA Data wykonania operacji: 2025-08-04 02:00 Oryginalna kwota operacji: 22.00 Numer karty: 4', '2025-08-06', 'seed-f1afc8c8c01bb59b'
  FROM categories c WHERE c.name = 'restauracje'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 9.99, 'Tytuł: 000498849 74230785216172909118911  Lokalizacja: Adres: ZABKA Z0685 K.1 Miasto: POZNAN Kraj: POLSKA Data wykonania operacji: 2025-08-04 02:00 Oryginalna kwota operacji: 9.99 Numer karty: 425125*', '2025-08-06', 'seed-d74d59f89f228459'
  FROM categories c WHERE c.name = 'żabka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 99.99, 'Tytuł: 00000089909266239   Numer telefonu: 48796555364 Lokalizacja: Adres: www.zalando.pl ''Operacja: 00000089909266239 Numer referencyjny: 00000089909266239 (99.99 PLN)', '2025-08-05', 'seed-9f38f1139624a89e'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 1280.0, 'Rachunek odbiorcy: 73 1090 2372 0000 0001 1332 9442 Nazwa odbiorcy: MARTA SZCZYGIEŁ Tytuł: PRZELEW NA TELEFON  OD: 48796555364 DO: 486*****967 (1280.00 PLN)', '2025-08-04', 'seed-0c13dc62392c90d0'
  FROM categories c WHERE c.name = 'mieszkanie'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 4.0, 'Nazwa odbiorcy: MOBILE-TRAFFIC-DATA SP. Z O. O. Adres odbiorcy: UL. DRUŻBICKIEGO 11 61-693 POZNAŃ Tytuł: ZAKUP BILETU KOMUNIKACYJNEGO W APLI KACJI IKO  Referencje własne zleceniodawcy: 175921056820 (4', '2025-08-04', 'seed-e1128a8cf1d57230'
  FROM categories c WHERE c.name = 'przejazdy'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 4.0, 'Nazwa odbiorcy: MOBILE-TRAFFIC-DATA SP. Z O. O. Adres odbiorcy: UL. DRUŻBICKIEGO 11 61-693 POZNAŃ Tytuł: ZAKUP BILETU KOMUNIKACYJNEGO W APLI KACJI IKO  Referencje własne zleceniodawcy: 175920788334 (4', '2025-08-04', 'seed-3dd83e44b7304101'
  FROM categories c WHERE c.name = 'przejazdy'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 59.99, 'Tytuł: 010066928 74056285214101166876451  Lokalizacja: Adres: APPLE.COM/BILL Miasto: APPLE.COM/BIL Kraj: IRLANDIA Data wykonania operacji: 2025-08-02 02:00 Oryginalna kwota operacji: 59.99 Numer karty', '2025-08-04', 'seed-d1b9a5e154afcf56'
  FROM categories c WHERE c.name = 'biuro'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 180.99, 'Tytuł:  74838495214322377953406  Lokalizacja: Adres: LIDL OSTROWSKA Miasto: Poznan Kraj: POLSKA Data wykonania operacji: 2025-08-02 02:00 Oryginalna kwota operacji: 180.99 Numer karty: 425125******026', '2025-08-04', 'seed-8c6554eb44920784'
  FROM categories c WHERE c.name = 'arval'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 21.98, 'Tytuł:  74838495215322272756143  Lokalizacja: Adres: ORLEN STACJA NR 422 Miasto: POZNAN Kraj: POLSKA Data wykonania operacji: 2025-08-02 02:00 Oryginalna kwota operacji: 21.98 Numer karty: 425125*****', '2025-08-04', 'seed-e15ddd776019a4b5'
  FROM categories c WHERE c.name = 'paliwo'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 32.0, 'Tytuł:  74810315214165532427218  Lokalizacja: Adres: Parking wielopoziomowy Miasto: Bydgoszcz Kraj: POLSKA Data wykonania operacji: 2025-08-02 02:00 Oryginalna kwota operacji: 32.00 Numer karty: 42512', '2025-08-04', 'seed-afcec40422815df3'
  FROM categories c WHERE c.name = 'arval'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 46.0, 'Tytuł:  74810315214165505962936  Lokalizacja: Adres: PARZYMY TUTAJ Miasto: Bydgoszcz Kraj: POLSKA Data wykonania operacji: 2025-08-02 02:00 Oryginalna kwota operacji: 46.00 Numer karty: 425125******02', '2025-08-04', 'seed-24c078b6f76200b2'
  FROM categories c WHERE c.name = 'arval'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 363.0, 'Rachunek odbiorcy: 21 1940 1076 6256 6800 0000 0000 Nazwa odbiorcy: ADAM TYŻYK Tytuł: 12 MP/08/2025   Referencje własne zleceniodawcy: 175915617025 (363.00 PLN)', '2025-08-04', 'seed-00291372d4949ba2'
  FROM categories c WHERE c.name = 'mieszkanie'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 106.22, 'Tytuł:  74988855213496361111694  Lokalizacja: Adres: JMP S.A. BIEDRONKA 3950 Miasto: POZNAN Kraj: POLSKA Data wykonania operacji: 2025-08-01 02:00 Oryginalna kwota operacji: 106.22 Numer karty: 425125', '2025-08-03', 'seed-64ee413276a6bfb5'
  FROM categories c WHERE c.name = 'biedronka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 222.5, 'Tytuł: 010087885 74987505213000506056046  Lokalizacja: Adres: BsCaffe Grzegorz Bienko Miasto: Stalowa Wola Kraj: POLSKA Data wykonania operacji: 2025-08-01 02:00 Oryginalna kwota operacji: 222.50 Nume', '2025-08-03', 'seed-b7f1ea4bf5a08eaf'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 35.97, 'Tytuł:  74838495213321891561795  Lokalizacja: Adres: ROSSMANN 21 Miasto: POZNAN Kraj: POLSKA Data wykonania operacji: 2025-07-31 02:00 Oryginalna kwota operacji: 35.97 Numer karty: 425125******0264 (3', '2025-08-02', 'seed-a8d479060eac5383'
  FROM categories c WHERE c.name = 'rossman'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 550.0, 'Tytuł: 010085232 74350275212010920238922  Lokalizacja: Adres: Revolut**7108* Miasto: Dublin Kraj: IRLANDIA Data wykonania operacji: 2025-07-31 02:00 Oryginalna kwota operacji: 550.00 Numer karty: 4251', '2025-08-02', 'seed-e9c391e40206a7d8'
  FROM categories c WHERE c.name = 'krypto'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 500.0, 'Tytuł: OBCY 00000089818786020   Numer telefonu: 48796555364 Lokalizacja: Adres: UL  RYCHTALSKA 8 Miasto: WROCLAW Kraj: POLSKA Bankomat: OBCY ''Operacja: 00000089818786020 Numer referencyjny: 000000898', '2025-08-01', 'seed-0beece2418b65960'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 260.46, 'ORLEN STACJA NR 839  SWIECIE  POL   Płatność kartą 29.08.2025 Nr karty 4598xx4778', '2025-08-29', 'seed-dbd21c4d2f814ad3'
  FROM categories c WHERE c.name = 'paliwo'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 381.87, 'KANCELARIA PODATKOWO-GOSPODARCZA SP ÓŁKA Z OGRANICZONĄ ODPOWIEDZIALNOŚC IĄ ul. Radomska 7 44-164 Gliwice NI P: PL 631-264-51-93   FA/69/08/2025', '2025-08-28', 'seed-76e6f588c8ba4cb4'
  FROM categories c WHERE c.name = 'biuro'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 229.58, 'Softwaremill S.A. ul. Na Uboczu 8/87 02-791 Warszawa   FV 013/08/2025', '2025-08-27', 'seed-fce3daf1d71c48de'
  FROM categories c WHERE c.name = 'biuro'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 206.78, 'ORLEN STACJA NR 199  KUZNIA RACIBO   Płatność kartą 24.08.2025 Nr karty 4598xx4778', '2025-08-24', 'seed-7f136a2a38c43401'
  FROM categories c WHERE c.name = 'paliwo'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 350.01, 'KELLER SP Z O.O.- SALON H  GLIWICE   Płatność kartą 22.08.2025 Nr karty 4598xx4778', '2025-08-22', 'seed-a2d7b823b89137a9'
  FROM categories c WHERE c.name = 'arval'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 177.02, 'SHELL 11  Wroclaw  POL   Płatność kartą 22.08.2025 Nr karty 4598xx4778', '2025-08-22', 'seed-2011e952664c2541'
  FROM categories c WHERE c.name = 'paliwo'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 5176.0, 'Urząd Skarbowy Centrum Rozliczeniowe   /TI/N6392015837/OKR/25M07/SFP/VAT7', '2025-08-19', 'seed-b4b55683d1adbcb4'
  FROM categories c WHERE c.name = 'vat'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 3153.0, 'Urząd Skarbowy Centrum Rozliczeniowe   /TI/N6392015837/OKR/25M07/SFP/PPE', '2025-08-19', 'seed-691df98dc06fbc54'
  FROM categories c WHERE c.name = 'pit36'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 99.52, 'ORLEN STACJA NR 455  SIERAKOWO  POL   Płatność kartą 15.08.2025 Nr karty 4598xx4778', '2025-08-15', 'seed-87c543b9fc4eeedb'
  FROM categories c WHERE c.name = 'paliwo'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 170.1, 'STACJA PALIW NR 702  KROTOSZYN  POL   Płatność kartą 09.08.2025 Nr karty 4598xx4778', '2025-08-09', 'seed-c39a61acd22d9be4'
  FROM categories c WHERE c.name = 'paliwo'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 229.58, 'Softwaremill S.A. ul. Na Uboczu 8/87 02-791 Warszawa   FV 013/07/2025', '2025-08-04', 'seed-5c225777a2a4564d'
  FROM categories c WHERE c.name = 'biuro'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 2274.5, 'BNP Paribas Leasing Services Sp. z o.o. 00-844 Warszawa, ul.Grzybowska 78   39120/08/2025/RL/LS', '2025-08-04', 'seed-75c6279cb0511be1'
  FROM categories c WHERE c.name = 'arval'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 246.0, 'P4 Sp. z o.o. ul. Wynalazek 1 02-677 Warszawa   F/10161865/08/25', '2025-08-04', 'seed-7be75e5eeed37888'
  FROM categories c WHERE c.name = 'biuro'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 12.0, 'Urząd Skarbowy Centrum Rozliczeniowe   /TI/N6392015837/OKR/25M07/SFP/PIT4R', '2025-08-04', 'seed-f699384c6d484185'
  FROM categories c WHERE c.name = 'pit36'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 3213.25, 'Zakład Ubezpieczeń Społecznych 47-400 Racibórz   Ubezpieczenie zdrowotne 07.2025', '2025-08-04', 'seed-511c409f7f4bbc3f'
  FROM categories c WHERE c.name = 'zus'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 82.29, 'Orange Polska S.A. Aleje Jerozolimskie 160 02-326 Warszawa NIP 526-025-09-95   F0083222849/008/25', '2025-08-04', 'seed-99fd150d68e35e9b'
  FROM categories c WHERE c.name = 'biuro'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 206.44, 'ORLEN STACJA NR 422  POZNAN  POL   Płatność kartą 02.08.2025 Nr karty 4598xx4778', '2025-08-02', 'seed-827342d9e8fd0c41'
  FROM categories c WHERE c.name = 'paliwo'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 35.08, 'Tytuł: 000498849 74230785207172297666647  Lokalizacja: Adres: NETTO 5304 SCO K.2 Miasto: POZNAN Kraj: POLSKA Data wykonania operacji: 2025-07-25 02:00 Oryginalna kwota operacji: 35.08 Numer karty: 425', '2025-07-27', 'seed-8c253140a77b7495'
  FROM categories c WHERE c.name = 'biedronka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 4.5, 'Tytuł: 010061097 74169505206652065173361  Lokalizacja: Adres: FABRYKA FORMY POZNAN BALT Miasto: POZNAN Kraj: POLSKA Data wykonania operacji: 2025-07-25 02:00 Oryginalna kwota operacji: 4.50 Numer kart', '2025-07-27', 'seed-491eed3ab078e1fb'
  FROM categories c WHERE c.name = 'biedronka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 500.0, 'Tytuł: 010085232 74350275205010817772842  Lokalizacja: Adres: Revolut**7108* Miasto: Dublin Kraj: IRLANDIA Data wykonania operacji: 2025-07-24 02:00 Oryginalna kwota operacji: 500.00 Numer karty: 4251', '2025-07-26', 'seed-28e4ee4235daa02e'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 22.0, 'Tytuł: 000498849 74230785204172102030230  Lokalizacja: Adres: SOUP CULTURE ROSWELL Miasto: POZNAN Kraj: POLSKA Data wykonania operacji: 2025-07-23 02:00 Oryginalna kwota operacji: 22.00 Numer karty: 4', '2025-07-25', 'seed-5f8ea456ce14d063'
  FROM categories c WHERE c.name = 'restauracje'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 1199.98, 'Tytuł: 00000089650281362   Numer telefonu: 48796555364 Lokalizacja: Adres: www.zalando.pl ''Operacja: 00000089650281362 Numer referencyjny: 00000089650281362 (1199.98 PLN)', '2025-07-24', 'seed-651ab4612b17857a'
  FROM categories c WHERE c.name = 'ubrania'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 77.86, 'Tytuł: 010072805 24871155203106473917290  Lokalizacja: Adres: ALIEXPRESS.COM Miasto: Luxembourg Kraj: LUKSEMBURG Data wykonania operacji: 2025-07-22 02:00 Oryginalna kwota operacji: 77.86 Numer karty:', '2025-07-24', 'seed-f0f8fce18a237927'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 4.5, 'Tytuł: 010061097 74169505203642030729077  Lokalizacja: Adres: FABRYKA FORMY POZNAN BALT Miasto: POZNAN Kraj: POLSKA Data wykonania operacji: 2025-07-22 02:00 Oryginalna kwota operacji: 4.50 Numer kart', '2025-07-24', 'seed-f9b02bcd6e73b231'
  FROM categories c WHERE c.name = 'biedronka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 20.0, 'Tytuł: 000498849 74230785203172053212739  Lokalizacja: Adres: STRONA Miasto: POZNAN Kraj: POLSKA Data wykonania operacji: 2025-07-22 02:00 Oryginalna kwota operacji: 20.00 Numer karty: 425125******026', '2025-07-24', 'seed-e2431a11fd9be398'
  FROM categories c WHERE c.name = 'restauracje'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 39.99, 'Tytuł: 010066928 74056285203100586281006  Lokalizacja: Adres: APPLE.COM/BILL Miasto: APPLE.COM/BIL Kraj: IRLANDIA Data wykonania operacji: 2025-07-22 02:00 Oryginalna kwota operacji: 39.99 Numer karty', '2025-07-24', 'seed-5f9476acee3d0219'
  FROM categories c WHERE c.name = 'biuro'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 235.0, 'Rachunek odbiorcy: 73 1090 2372 0000 0001 1332 9442 Nazwa odbiorcy: MARTA SZCZYGIEŁ Tytuł: PRZELEW NA TELEFON  OD: 48796555364 DO: 486*****967 (235.00 PLN)', '2025-07-22', 'seed-28d83fa50c9203e0'
  FROM categories c WHERE c.name = 'mieszkanie'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 250.0, 'Rachunek odbiorcy: 25 1140 2004 0000 3102 7803 3777 Nazwa odbiorcy: KAMIL WIETESKA Tytuł: OLAF KRZWCZYK 21.07.2025   Referencje własne zleceniodawcy: 175875884623 (250.00 PLN)', '2025-07-21', 'seed-06eee7b4bc4b90ed'
  FROM categories c WHERE c.name = 'lekarz'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 19.49, 'Tytuł: 000498849 74230785200171847484920  Lokalizacja: Adres: ZABKA Z4067 K.2 Miasto: WROCLAW Kraj: POLSKA Data wykonania operacji: 2025-07-19 02:00 Oryginalna kwota operacji: 19.49 Numer karty: 42512', '2025-07-21', 'seed-09c41c4df8998310'
  FROM categories c WHERE c.name = 'żabka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 15.3, 'Tytuł:  74838495200320058215273  Lokalizacja: Adres: LARKS Miasto: WROCLAW Kraj: POLSKA Data wykonania operacji: 2025-07-19 02:00 Oryginalna kwota operacji: 15.30 Numer karty: 425125******0264 (15.30 ', '2025-07-21', 'seed-aa0fc30adaf62751'
  FROM categories c WHERE c.name = 'kawa'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 15.3, 'Tytuł:  74838495199319881980171  Lokalizacja: Adres: LARKS Miasto: WROCLAW Kraj: POLSKA Data wykonania operacji: 2025-07-18 02:00 Oryginalna kwota operacji: 15.30 Numer karty: 425125******0264 (15.30 ', '2025-07-20', 'seed-22d22175f1cf301b'
  FROM categories c WHERE c.name = 'kawa'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 59.98, 'Tytuł:  74838495199319887804557  Lokalizacja: Adres: Ziko Apteka Miasto: Wroclaw Kraj: POLSKA Data wykonania operacji: 2025-07-18 02:00 Oryginalna kwota operacji: 59.98 Numer karty: 425125******0264 (', '2025-07-20', 'seed-9de3b9cdd3d160d6'
  FROM categories c WHERE c.name = 'apteka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 15.25, 'Tytuł:  74810315199163967373238  Lokalizacja: Adres: CAFE ROZRUSZNIK Miasto: WROCLAW Kraj: POLSKA Data wykonania operacji: 2025-07-18 02:00 Oryginalna kwota operacji: 15.25 Numer karty: 425125******02', '2025-07-20', 'seed-00540e75b78ab3b4'
  FROM categories c WHERE c.name = 'kawa'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 10.1, 'Tytuł: 000498849 74230785199171751038186  Lokalizacja: Adres: ZABKA ZC250 K.2 Miasto: WROCLAW Kraj: POLSKA Data wykonania operacji: 2025-07-18 02:00 Oryginalna kwota operacji: 10.10 Numer karty: 42512', '2025-07-20', 'seed-cce5054cba89afae'
  FROM categories c WHERE c.name = 'żabka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 5.0, 'Tytuł:  74810315199163929109423  Lokalizacja: Adres: KWATERA GLOWNA Miasto: WROCLAW Kraj: POLSKA Data wykonania operacji: 2025-07-18 02:00 Oryginalna kwota operacji: 5.00 Numer karty: 425125******0264', '2025-07-20', 'seed-c02890dcdacd42c5'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 87.49, 'Tytuł:  74988855199401249230383  Lokalizacja: Adres: JMIDF SP.Z.O.O.HEBE R147 Miasto: WROCLAW Kraj: POLSKA Data wykonania operacji: 2025-07-18 02:00 Oryginalna kwota operacji: 87.49 Numer karty: 42512', '2025-07-20', 'seed-04acf71896086ee6'
  FROM categories c WHERE c.name = 'rossman'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 14.99, 'Tytuł:  74198745198528431953891  Lokalizacja: Adres: APPLE.COM/BILL Miasto: CORK Kraj: IRLANDIA Data wykonania operacji: 2025-07-16 02:00 Oryginalna kwota operacji: 14.99 Numer karty: 425125******0264', '2025-07-20', 'seed-65f33f9a1d07f464'
  FROM categories c WHERE c.name = 'biuro'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 18.99, 'Tytuł: 010059127 74062945198134528817823  Lokalizacja: Adres: www.inpost.pl Miasto: KRAKOW Kraj: POLSKA Data wykonania operacji: 2025-07-17 02:00 Oryginalna kwota operacji: 18.99 Numer karty: 425125**', '2025-07-19', 'seed-3a67e33295f0e629'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 10.0, 'Rachunek odbiorcy: 05 1050 1575 1000 0097 9776 6731 Nazwa odbiorcy: ODBIORCA PRZELEWU NA TELEFON Tytuł: PRZELEW NA TELEFON  OD: 48796555364 DO: 485*****629 (10.00 PLN)', '2025-07-18', 'seed-3c50b92d6c886169'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 99.99, 'Tytuł: 000498849 74230785197171597947931  Lokalizacja: Adres: MEDIA MARKT P519 K.104 Miasto: POZNAN Kraj: POLSKA Data wykonania operacji: 2025-07-16 02:00 Oryginalna kwota operacji: 99.99 Numer karty:', '2025-07-18', 'seed-e493132d8c75b86d'
  FROM categories c WHERE c.name = 'mieszkanie'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 15.54, 'Tytuł:  74570005197719731596591  Lokalizacja: Adres: 7-ELEVEN B108 Miasto: KASTRUP Kraj: DANIA Data wykonania operacji: 2025-07-15 02:00 Oryginalna kwota operacji: 26.00 Data przetworzenia: 2025-07-16', '2025-07-17', 'seed-791d2637327be818'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 44.0, 'Tytuł:  74810315196163636339019  Lokalizacja: Adres: Pawel Holowacz Miasto: Wroclaw Kraj: POLSKA Data wykonania operacji: 2025-07-15 02:00 Oryginalna kwota operacji: 44.00 Numer karty: 425125******026', '2025-07-17', 'seed-b1e4c96e169c000c'
  FROM categories c WHERE c.name = 'restauracje'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 48.93, 'Tytuł: 000414361 74143615197000081395676  Lokalizacja: Adres: UBR* PENDING.UBER.COM Miasto: AMSTERDAM Kraj: HOLANDIA Data wykonania operacji: 2025-07-15 02:00 Oryginalna kwota operacji: 48.93 Numer ka', '2025-07-17', 'seed-9293ba86895988be'
  FROM categories c WHERE c.name = 'przejazdy'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 22.9, 'Tytuł:  74838495196319455775828  Lokalizacja: Adres: PL SBX GDANSK RAJSKA Miasto: GDANSK Kraj: POLSKA Data wykonania operacji: 2025-07-15 02:00 Oryginalna kwota operacji: 22.90 Numer karty: 425125****', '2025-07-17', 'seed-54e3fd7767dcf0f9'
  FROM categories c WHERE c.name = 'kawa'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 1786.83, 'Rachunek odbiorcy: 91 1020 0029 9000 2023 2777 2284 Nazwa odbiorcy: OLAF KRAWCZYK Tytuł: SPŁATA AKTUALNEGO ZADŁUŻENIA KARTY KREDYTOWEJ * 8853 OD: 48796555364 Referencje własne zleceniodawcy: 175861701', '2025-07-16', 'seed-0660b254d809b13f'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 10.25, 'Tytuł: 000498707 74987075196030898507988  Lokalizacja: Adres: jakdojade.pl Miasto: Poznan Kraj: POLSKA Data wykonania operacji: 2025-07-14 02:00 Oryginalna kwota operacji: 10.25 Numer karty: 425125***', '2025-07-16', 'seed-d48cc625af19e772'
  FROM categories c WHERE c.name = 'arval'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 500.0, 'Tytuł: 010085232 74350275195010676030078  Lokalizacja: Adres: Revolut**7108* Miasto: Dublin Kraj: IRLANDIA Data wykonania operacji: 2025-07-14 02:00 Oryginalna kwota operacji: 500.00 Numer karty: 4251', '2025-07-16', 'seed-b3e46b838daa0890'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 7.0, 'Tytuł:  74810315195163463933687  Lokalizacja: Adres: Relay 53605 Miasto: Gdansk Kraj: POLSKA Data wykonania operacji: 2025-07-14 02:00 Oryginalna kwota operacji: 7.00 Numer karty: 425125******0264 (7.', '2025-07-16', 'seed-fa7268290146d0fd'
  FROM categories c WHERE c.name = 'żabka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 20.0, 'Tytuł: 00000089471837810   Numer telefonu: 48796555364 Lokalizacja: Adres: doladowania.t-mobile.pl ''Operacja: 00000089471837810 Numer referencyjny: 00000089471837810 (20.00 PLN)', '2025-07-15', 'seed-6feb3ec879f58845'
  FROM categories c WHERE c.name = 'biuro'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 56.0, 'Tytuł:  74810315194163426789037  Lokalizacja: Adres: MATA Indyjska Restaurac Miasto: Poznan Kraj: POLSKA Data wykonania operacji: 2025-07-13 02:00 Oryginalna kwota operacji: 56.00 Numer karty: 425125*', '2025-07-15', 'seed-7e854301d28dcccc'
  FROM categories c WHERE c.name = 'restauracje'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 70.0, 'Tytuł: 010061097 74463675194501951221875  Lokalizacja: Adres: WWW BILKOM PL Miasto: WARSZAWA Kraj: POLSKA Data wykonania operacji: 2025-07-13 02:00 Oryginalna kwota operacji: 70.00 Numer karty: 425125', '2025-07-15', 'seed-e03597b1c300468f'
  FROM categories c WHERE c.name = 'przejazdy'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 9.98, 'Tytuł: 000498849 74230785194171428962433  Lokalizacja: Adres: ZABKA Z5606 K.2 Miasto: POZNAN Kraj: POLSKA Data wykonania operacji: 2025-07-13 02:00 Oryginalna kwota operacji: 9.98 Numer karty: 425125*', '2025-07-15', 'seed-baad548fb0d40097'
  FROM categories c WHERE c.name = 'żabka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 54.0, 'Tytuł:  74810315194163405729236  Lokalizacja: Adres: Berlin Ecke Miasto: Poznan Kraj: POLSKA Data wykonania operacji: 2025-07-13 02:00 Oryginalna kwota operacji: 54.00 Numer karty: 425125******0264 (5', '2025-07-15', 'seed-bdbca8bf1d00c6ec'
  FROM categories c WHERE c.name = 'restauracje'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 66.0, 'Tytuł:  74838495194319033911913  Lokalizacja: Adres: BRO. FOOD. BEER. CHILL. Miasto: POZNAN Kraj: POLSKA Data wykonania operacji: 2025-07-12 02:00 Oryginalna kwota operacji: 66.00 Numer karty: 425125*', '2025-07-15', 'seed-d734dcadc3ae3151'
  FROM categories c WHERE c.name = 'restauracje'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 700.0, 'Tytuł: 010085232 74350275193010658633040  Lokalizacja: Adres: Revolut**7108* Miasto: Dublin Kraj: IRLANDIA Data wykonania operacji: 2025-07-12 02:00 Oryginalna kwota operacji: 700.00 Numer karty: 4251', '2025-07-14', 'seed-0b39f826d35b5014'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 56.0, 'Tytuł: 000498849 74230785194171388663609  Lokalizacja: Adres: POZNAN SNOOKER BILLIA Miasto: POZNAN Kraj: POLSKA Data wykonania operacji: 2025-07-12 02:00 Oryginalna kwota operacji: 56.00 Numer karty: ', '2025-07-14', 'seed-5c7ec3863c87f301'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 137.1, 'Tytuł: 010062941 74987505193000606110028  Lokalizacja: Adres: notino.pl Miasto: Brno Kraj: REPUBLIKA CZESKA Data wykonania operacji: 2025-07-12 02:00 Oryginalna kwota operacji: 137.10 Numer karty: 425', '2025-07-14', 'seed-e876f4654c37f6c8'
  FROM categories c WHERE c.name = 'apteka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 76.93, 'Tytuł: 010072805 24871155193103841312025  Lokalizacja: Adres: ALIEXPRESS.COM Miasto: Luxembourg Kraj: LUKSEMBURG Data wykonania operacji: 2025-07-12 02:00 Oryginalna kwota operacji: 76.93 Numer karty:', '2025-07-14', 'seed-ee6d05d006d169a0'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 10.0, 'Tytuł:  74598425193000185606398 (10.00 PLN)', '2025-07-14', 'seed-963172e3a69b5a06'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 50.0, 'Tytuł:  74598425193000185606398  Lokalizacja: Adres: ul  Andersa 1 Miasto: POZNAN Kraj: POLSKA Data wykonania operacji: 2025-07-12 02:00 Oryginalna kwota operacji: 50.00 Numer karty: 425125******0264 ', '2025-07-14', 'seed-a406d010e404de92'
  FROM categories c WHERE c.name = 'arval'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 79.0, 'Tytuł: 010046551 74230105193058830445390  Lokalizacja: Adres: NOODLE STREET Miasto: POZNAN Kraj: POLSKA Data wykonania operacji: 2025-07-12 02:00 Oryginalna kwota operacji: 79.00 Numer karty: 425125**', '2025-07-14', 'seed-2249970e1170585d'
  FROM categories c WHERE c.name = 'restauracje'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 8.4, 'Tytuł: 000498849 74230785193171363426023  Lokalizacja: Adres: ZABKA Z1521 K.2 Miasto: POZNAN Kraj: POLSKA Data wykonania operacji: 2025-07-12 02:00 Oryginalna kwota operacji: 8.40 Numer karty: 425125*', '2025-07-14', 'seed-5afd3f22de9fad15'
  FROM categories c WHERE c.name = 'żabka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 50.0, 'Rachunek odbiorcy: 76 1020 2368 0000 2102 0521 6967 Nazwa odbiorcy: SWIADOM Tytuł: PRZELEW NA TELEFON  OD: 48796555364 DO: 48790896787 Referencje własne zleceniodawcy: 175850319634 (50.00 PLN)', '2025-07-13', 'seed-49c4d24a6c3ca418'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 350.0, 'Tytuł:  74810315192163273293523  Lokalizacja: Adres: Nare Sushi Miasto: Skorzewo Kraj: POLSKA Data wykonania operacji: 2025-07-11 02:00 Oryginalna kwota operacji: 350.00 Numer karty: 425125******0264 ', '2025-07-13', 'seed-916d228cee7348a0'
  FROM categories c WHERE c.name = 'restauracje'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 34.9, 'Tytuł: 000414361 74143615193000080186997  Lokalizacja: Adres: UBR* PENDING.UBER.COM Miasto: AMSTERDAM Kraj: HOLANDIA Data wykonania operacji: 2025-07-11 02:00 Oryginalna kwota operacji: 34.90 Numer ka', '2025-07-13', 'seed-4b63b2554d2f5c53'
  FROM categories c WHERE c.name = 'przejazdy'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 9.99, 'Tytuł:  74838495192318590831052  Lokalizacja: Adres: ROSSMANN 21 Miasto: POZNAN Kraj: POLSKA Data wykonania operacji: 2025-07-10 02:00 Oryginalna kwota operacji: 9.99 Numer karty: 425125******0264 (9.', '2025-07-12', 'seed-8bf7c6db95ca672b'
  FROM categories c WHERE c.name = 'rossman'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 22.0, 'Tytuł: 000498849 74230785191171199253585  Lokalizacja: Adres: SOUP CULTURE ROSWELL Miasto: POZNAN Kraj: POLSKA Data wykonania operacji: 2025-07-10 02:00 Oryginalna kwota operacji: 22.00 Numer karty: 4', '2025-07-12', 'seed-384938e66693af23'
  FROM categories c WHERE c.name = 'restauracje'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 18.99, 'Tytuł: 010059127 74062945191133770068678  Lokalizacja: Adres: www.inpost.pl Miasto: KRAKOW Kraj: POLSKA Data wykonania operacji: 2025-07-09 02:00 Oryginalna kwota operacji: 18.99 Numer karty: 425125**', '2025-07-12', 'seed-b314f17bf3e9c70a'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 731.2, 'Tytuł: 000414361 74143615192000081324739  Lokalizacja: Adres: RYANAIR     GWUHHF0 Miasto: K67X452 Kraj: IRLANDIA Data wykonania operacji: 2025-07-09 02:00 Oryginalna kwota operacji: 731.20 Numer karty', '2025-07-12', 'seed-a97649462c7cabc3'
  FROM categories c WHERE c.name = 'przejazdy'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 24.99, 'Tytuł: 010066928 74056285190108549783633  Lokalizacja: Adres: Dodatek do P*RC06Y8754 Miasto: primevideo.pl Kraj: LUKSEMBURG Data wykonania operacji: 2025-07-09 02:00 Oryginalna kwota operacji: 24.99 N', '2025-07-11', 'seed-f5a981c10fd58e4c'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 1000.0, 'Tytuł: 010085232 74350275189010593613004  Lokalizacja: Adres: Revolut**7108* Miasto: Dublin Kraj: IRLANDIA Data wykonania operacji: 2025-07-08 02:00 Oryginalna kwota operacji: 1000.00 Numer karty: 425', '2025-07-10', 'seed-367f67687ce3e9d5'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 103.5, 'Rachunek odbiorcy: 21 1020 4027 3011 0000 3014 3739 Nazwa odbiorcy: INEA SP. Z O.O.WYSOGOTOWO,UL.WIERZB OWA 8462-081 PRZEŹMIEROWO Tytuł: 96680/2025/07/IS/DS   Referencje własne zleceniodawcy: 17583772', '2025-07-10', 'seed-b415461e3ae1409a'
  FROM categories c WHERE c.name = 'mieszkanie'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 17.3, 'Tytuł: 000498849 74230785188171006333674  Lokalizacja: Adres: ZABKA Z0685 K.1 Miasto: POZNAN Kraj: POLSKA Data wykonania operacji: 2025-07-07 02:00 Oryginalna kwota operacji: 17.30 Numer karty: 425125', '2025-07-09', 'seed-752a7e674c2e953e'
  FROM categories c WHERE c.name = 'żabka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 29.99, 'Tytuł: 010066928 74056285188106669067591  Lokalizacja: Adres: APPLE.COM/BILL Miasto: APPLE.COM/BIL Kraj: IRLANDIA Data wykonania operacji: 2025-07-07 02:00 Oryginalna kwota operacji: 29.99 Numer karty', '2025-07-09', 'seed-a77e73a5b74fd61d'
  FROM categories c WHERE c.name = 'biuro'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 250.0, 'Tytuł: 010061097 74169505188621882723908  Lokalizacja: Adres: PRACOWNIA PSYCHOLOGICZNA Miasto: POZNAN Kraj: POLSKA Data wykonania operacji: 2025-07-07 02:00 Oryginalna kwota operacji: 250.00 Numer kar', '2025-07-09', 'seed-d2d7fad457b80c4c'
  FROM categories c WHERE c.name = 'lekarz'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 71.12, 'Tytuł: 000498849 74230785189171036905409  Lokalizacja: Adres: NETTO 5304 SCO K.3 Miasto: POZNAN Kraj: POLSKA Data wykonania operacji: 2025-07-07 02:00 Oryginalna kwota operacji: 71.12 Numer karty: 425', '2025-07-09', 'seed-1f7ba50e8a511c18'
  FROM categories c WHERE c.name = 'biedronka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 400.0, 'Rachunek odbiorcy: 73 1090 2372 0000 0001 1332 9442 Nazwa odbiorcy: MARTA SZCZYGIEŁ Tytuł: PRZELEW NA TELEFON  OD: 48796555364 DO: 486*****967 (400.00 PLN)', '2025-07-08', 'seed-bec317843b05f14c'
  FROM categories c WHERE c.name = 'mieszkanie'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 400.0, 'Tytuł: OBCY 00000089333213865   Numer telefonu: 48796555364 Lokalizacja: Adres: UL  RYCHTALSKA 8 Miasto: WROCLAW Kraj: POLSKA Bankomat: OBCY ''Operacja: 00000089333213865 Numer referencyjny: 000000893', '2025-07-08', 'seed-157631c32616791f'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 22.92, 'Tytuł: 010062941 74987505187003679565092  Lokalizacja: Adres: BOLT.EU/O/2507061949 Miasto: Warsaw Kraj: POLSKA Data wykonania operacji: 2025-07-06 02:00 Oryginalna kwota operacji: 22.92 Numer karty: 4', '2025-07-08', 'seed-5aca673c4fe33e8d'
  FROM categories c WHERE c.name = 'przejazdy'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 31.9, 'Tytuł:  74838495188318078301657  Lokalizacja: Adres: Sklep McDonalds Warszaw Miasto: WARSZAWA Kraj: POLSKA Data wykonania operacji: 2025-07-06 02:00 Oryginalna kwota operacji: 31.90 Numer karty: 42512', '2025-07-08', 'seed-faa9909429c1bb72'
  FROM categories c WHERE c.name = 'restauracje'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 72.09, 'Tytuł: 000916920 74987075188030643088268  Lokalizacja: Adres: olx.pl Miasto: POZNAN Kraj: POLSKA Data wykonania operacji: 2025-07-06 02:00 Oryginalna kwota operacji: 72.09 Numer karty: 425125******026', '2025-07-08', 'seed-66834c2d11a56b5c'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 2117.0, 'Rachunek odbiorcy: 32 1140 2004 0000 3102 7400 2816 Nazwa odbiorcy: ODBIORCA PRZELEWU NA TELEFON Tytuł: KAWALERSKI BOGUSZA  OD: 48796555364 DO: 485*****464 (2117.00 PLN)', '2025-07-07', 'seed-bb2c6b11d13554f6'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 4.0, 'Nazwa odbiorcy: MOBILE-TRAFFIC-DATA SP. Z O. O. Adres odbiorcy: UL. DRUŻBICKIEGO 11 61-693 POZNAŃ Tytuł: ZAKUP BILETU KOMUNIKACYJNEGO W APLI KACJI IKO  Referencje własne zleceniodawcy: 175825976908 (4', '2025-07-07', 'seed-36ad9be989056d59'
  FROM categories c WHERE c.name = 'przejazdy'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 1925.82, 'Rachunek odbiorcy: 24 1020 5226 0000 6302 0653 2255 Nazwa odbiorcy: OLAF RADOSŁAW KRAWCZYK Adres odbiorcy: UL. DĘBOWA 7 47-420 KUŹNIA RACIBORSKA Tytuł: FX77540298 EUR/PLN 4.2796  450,00 EUR -1 925,82 ', '2025-07-05', 'seed-74f0f721c44bbbc9'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 34.8, 'Tytuł:  74838495185317494666068  Lokalizacja: Adres: Sklep McDonalds Warszaw Miasto: WARSZAWA Kraj: POLSKA Data wykonania operacji: 2025-07-03 02:00 Oryginalna kwota operacji: 34.80 Numer karty: 42512', '2025-07-05', 'seed-5a4d2614e685bd25'
  FROM categories c WHERE c.name = 'restauracje'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 6.9, 'Tytuł: 010061097 74169505184641844438324  Lokalizacja: Adres: PHZ BALTONA B39 Miasto: POZNAN Kraj: POLSKA Data wykonania operacji: 2025-07-03 02:00 Oryginalna kwota operacji: 6.90 Numer karty: 425125*', '2025-07-05', 'seed-5181eb3800a8fda6'
  FROM categories c WHERE c.name = 'arval'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 31.0, 'Tytuł:  74810315184162348764690  Lokalizacja: Adres: Costa Coffee Miasto: Warszawa Kraj: POLSKA Data wykonania operacji: 2025-07-03 02:00 Oryginalna kwota operacji: 31.00 Numer karty: 425125******0264', '2025-07-05', 'seed-fb9fecc128808da4'
  FROM categories c WHERE c.name = 'kawa'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 59.99, 'Tytuł: 010066928 74056285184102794327962  Lokalizacja: Adres: APPLE.COM/BILL Miasto: APPLE.COM/BIL Kraj: IRLANDIA Data wykonania operacji: 2025-07-03 02:00 Oryginalna kwota operacji: 59.99 Numer karty', '2025-07-05', 'seed-db254ddc33970c97'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 639.57, 'Rachunek odbiorcy: 24 1020 5226 0000 6302 0653 2255 Nazwa odbiorcy: OLAF RADOSŁAW KRAWCZYK Adres odbiorcy: UL. DĘBOWA 7 47-420 KUŹNIA RACIBORSKA Tytuł: FX77491583 EUR/PLN 4.2638  150,00 EUR -639,57 PL', '2025-07-04', 'seed-2ed655e20d601d57'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 22.0, 'Tytuł: 000498849 74230785183170648087925  Lokalizacja: Adres: SOUP CULTURE ROSWELL Miasto: POZNAN Kraj: POLSKA Data wykonania operacji: 2025-07-02 02:00 Oryginalna kwota operacji: 22.00 Numer karty: 4', '2025-07-04', 'seed-d45377384530beae'
  FROM categories c WHERE c.name = 'restauracje'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 28.53, 'Rachunek odbiorcy: 41 1020 1026 3476 0003 1783 2524 Nazwa odbiorcy: PKO TOWARZYSTWO UBEZPIECZEŃ SPÓŁKA AKCYJNA Tytuł: UT/0317832524 (28.53 PLN)', '2025-07-02', 'seed-0f39bf45f3445813'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 1000.0, 'Tytuł: 010085232 74350275181010474292694  Lokalizacja: Adres: Revolut**7108* Miasto: Dublin Kraj: IRLANDIA Data wykonania operacji: 2025-06-30 02:00 Oryginalna kwota operacji: 1000.00 Numer karty: 425', '2025-07-02', 'seed-167a4c7158977a01'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 363.0, 'Rachunek odbiorcy: 21 1940 1076 6256 6800 0000 0000 Nazwa odbiorcy: ADAM TYŻYK Tytuł: 12 MP/07/2025   Referencje własne zleceniodawcy: 175806839607 (363.00 PLN)', '2025-07-01', 'seed-a308d3bc1927fadc'
  FROM categories c WHERE c.name = 'mieszkanie'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 8.79, 'Tytuł:  74838495181316913729840  Lokalizacja: Adres: ORLEN STACJA NR 600 Miasto: POZNAN Kraj: POLSKA Data wykonania operacji: 2025-06-29 02:00 Oryginalna kwota operacji: 8.79 Numer karty: 425125******', '2025-07-01', 'seed-6d3cf782619e0282'
  FROM categories c WHERE c.name = 'paliwo'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 5730.0, 'Urząd Skarbowy Centrum Rozliczeniowe   /TI/N6392015837/OKR/25M06/SFP/VAT7', '2025-07-20', 'seed-92f0aa6509779951'
  FROM categories c WHERE c.name = 'vat'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 3769.0, 'Urząd Skarbowy Centrum Rozliczeniowe   /TI/N6392015837/OKR/25M06/SFP/PPE', '2025-07-20', 'seed-fb02b3cfee118283'
  FROM categories c WHERE c.name = 'pit36'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 230.33, 'ORLEN STACJA NR 199  KUZNIA RACIBO   Płatność kartą 19.07.2025 Nr karty 4598xx4778', '2025-07-19', 'seed-9323c4f4ee4f52ba'
  FROM categories c WHERE c.name = 'paliwo'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 2194.0, 'SERWIS HYUNDAI BARANOW  BARANOWO 62   Płatność kartą 16.07.2025 Nr karty 4598xx4778', '2025-07-16', 'seed-869088c932d912b7'
  FROM categories c WHERE c.name = 'arval'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 132.9, 'Allegro  Poznan 60166 POL   Płatność kartą 16.07.2025 Nr karty 4598xx4778', '2025-07-16', 'seed-2313d8cee1155320'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 82.29, 'Orange Polska S.A. Aleje Jerozolimskie 160 02-326 Warszawa NIP 526-025-09-95   F0083222849/007/25', '2025-07-13', 'seed-fc7b9386f20183fe'
  FROM categories c WHERE c.name = 'biuro'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 247.24, 'P4 Sp. z o.o. ul. Wynalazek 1 02-677 Warszawa   F/10163894/07/25', '2025-07-13', 'seed-a879b54c696ecb0b'
  FROM categories c WHERE c.name = 'biuro'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 12.0, 'Urząd Skarbowy Centrum Rozliczeniowe   /TI/N6392015837/OKR/25M06/SFP/PIT4R', '2025-07-13', 'seed-afe12c551e9a039e'
  FROM categories c WHERE c.name = 'pit36'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 92.0, 'WWW BILKOM PL  WARSZAWA  POL   Płatność kartą 13.07.2025 Nr karty 4598xx4778', '2025-07-13', 'seed-6b86ab9c7b7095d1'
  FROM categories c WHERE c.name = 'przejazdy'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 50.0, 'STARY BROWAR POLWIEJSKA 3  POZNAN 6   Wypłata gotówki 12.07.2025 Nr karty 4598xx4778', '2025-07-12', 'seed-f353900f4c096f65'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 230.0, 'SERWIS HYUNDAI BARANOW  BARANOWO 62   Płatność kartą 10.07.2025 Nr karty 4598xx4778', '2025-07-10', 'seed-0ccdaa75ed4a6893'
  FROM categories c WHERE c.name = 'arval'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 3213.25, 'Zakład Ubezpieczeń Społecznych 47-400 Racibórz   Ubezpieczenie zdrowotne 06.2025', '2025-07-10', 'seed-8f968680d0500537'
  FROM categories c WHERE c.name = 'zus'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 2286.78, 'BNP Paribas Leasing Services Sp. z o.o. 00-844 Warszawa, ul.Grzybowska 78   11059/07/2025/RL/LS', '2025-07-03', 'seed-56b490256b6c46b8'
  FROM categories c WHERE c.name = 'arval'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 381.0, 'ksiegowa', '2025-08-04', 'seed-57b100bb6ea3dd8d'
  FROM categories c WHERE c.name = 'biuro'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 47.0, 'Tytuł:  74838495210321572945823  Lokalizacja: Adres: MITTE Miasto: POZNAN Kraj: POLSKA Data wykonania operacji: 2025-07-29 02:00 Oryginalna kwota operacji: 47.00 Numer karty: 425125******0264 (47.00 P', '2025-07-31', 'seed-e82c2f1673cd84af'
  FROM categories c WHERE c.name = 'biedronka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 4.5, 'Tytuł: 010061097 74169505210642103051244  Lokalizacja: Adres: FABRYKA FORMY POZNAN BALT Miasto: POZNAN Kraj: POLSKA Data wykonania operacji: 2025-07-29 02:00 Oryginalna kwota operacji: 4.50 Numer kart', '2025-07-31', 'seed-e0b3276897d3e72d'
  FROM categories c WHERE c.name = 'biedronka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 8.5, 'Tytuł: 000498849 74230785209172457498615  Lokalizacja: Adres: ZABKA Z1521 K.2 Miasto: POZNAN Kraj: POLSKA Data wykonania operacji: 2025-07-28 02:00 Oryginalna kwota operacji: 8.50 Numer karty: 425125*', '2025-07-30', 'seed-42f044a17e6fc942'
  FROM categories c WHERE c.name = 'żabka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 250.0, 'Tytuł: 010061097 74169505209612092094441  Lokalizacja: Adres: PRACOWNIA PSYCHOLOGICZNA Miasto: POZNAN Kraj: POLSKA Data wykonania operacji: 2025-07-28 02:00 Oryginalna kwota operacji: 250.00 Numer kar', '2025-07-30', 'seed-15903eaf1c2697ca'
  FROM categories c WHERE c.name = 'lekarz'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 22.0, 'Tytuł: 000498849 74230785209172437760753  Lokalizacja: Adres: SOUP CULTURE ROSWELL Miasto: POZNAN Kraj: POLSKA Data wykonania operacji: 2025-07-28 02:00 Oryginalna kwota operacji: 22.00 Numer karty: 4', '2025-07-30', 'seed-438ea4ad946409da'
  FROM categories c WHERE c.name = 'restauracje'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 4.0, 'Nazwa odbiorcy: MOBILE-TRAFFIC-DATA SP. Z O. O. Adres odbiorcy: UL. DRUŻBICKIEGO 11 61-693 POZNAŃ Tytuł: ZAKUP BILETU KOMUNIKACYJNEGO W APLI KACJI IKO  Referencje własne zleceniodawcy: 175897676416 (4', '2025-07-28', 'seed-27c0e43356e1a89a'
  FROM categories c WHERE c.name = 'przejazdy'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 4.0, 'Nazwa odbiorcy: MOBILE-TRAFFIC-DATA SP. Z O. O. Adres odbiorcy: UL. DRUŻBICKIEGO 11 61-693 POZNAŃ Tytuł: ZAKUP BILETU KOMUNIKACYJNEGO W APLI KACJI IKO  Referencje własne zleceniodawcy: 175897485870 (4', '2025-07-28', 'seed-08942b471c916085'
  FROM categories c WHERE c.name = 'przejazdy'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 64.82, 'Tytuł: 010062941 74987505207003315716089  Lokalizacja: Adres: Wolt Miasto: Warszawa Kraj: POLSKA Data wykonania operacji: 2025-07-26 02:00 Oryginalna kwota operacji: 64.82 Numer karty: 425125******026', '2025-07-28', 'seed-562c6365c0d4ef15'
  FROM categories c WHERE c.name = 'restauracje'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 35.08, 'Tytuł: 000498849 74230785207172297666647  Lokalizacja: Adres: NETTO 5304 SCO K.2 Miasto: POZNAN Kraj: POLSKA Data wykonania operacji: 2025-07-25 02:00 Oryginalna kwota operacji: 35.08 Numer karty: 425', '2025-07-27', 'seed-25e469adab6c56f8'
  FROM categories c WHERE c.name = 'biedronka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 4.5, 'Tytuł: 010061097 74169505206652065173361  Lokalizacja: Adres: FABRYKA FORMY POZNAN BALT Miasto: POZNAN Kraj: POLSKA Data wykonania operacji: 2025-07-25 02:00 Oryginalna kwota operacji: 4.50 Numer kart', '2025-07-27', 'seed-00a87acc8b083359'
  FROM categories c WHERE c.name = 'biedronka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 5.0, 'Tytuł: 00000089135103356   Numer telefonu: 48796555364 Lokalizacja: Adres: doladuj.plus.pl ''Operacja: 00000089135103356 Numer referencyjny: 00000089135103356 (5.00 PLN)', '2025-06-30', 'seed-cc667fe21807d5f8'
  FROM categories c WHERE c.name = 'biuro'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 6.0, 'Tytuł:  74838495179316725552566  Lokalizacja: Adres: STARE TBILISI YANA OLIU Miasto: POZNAN Kraj: POLSKA Data wykonania operacji: 2025-06-28 02:00 Oryginalna kwota operacji: 6.00 Numer karty: 425125**', '2025-06-30', 'seed-804d3f89e1444127'
  FROM categories c WHERE c.name = 'biedronka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 91.09, 'Tytuł:  74838495180316723024821  Lokalizacja: Adres: LIDL MATYI Miasto: POZNAN Kraj: POLSKA Data wykonania operacji: 2025-06-28 02:00 Oryginalna kwota operacji: 91.09 Numer karty: 425125******0264 (91', '2025-06-30', 'seed-fedea62a69d2b1f3'
  FROM categories c WHERE c.name = 'biedronka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 41.31, 'Tytuł: 000498849 74230785180170428022871  Lokalizacja: Adres: NETTO 5304 SCO K.2 Miasto: POZNAN Kraj: POLSKA Data wykonania operacji: 2025-06-28 02:00 Oryginalna kwota operacji: 41.31 Numer karty: 425', '2025-06-30', 'seed-a5f0dfad072a818a'
  FROM categories c WHERE c.name = 'biedronka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 70.0, 'Tytuł:  74838495178316629756108  Lokalizacja: Adres: UKI UKI Miasto: WARSZAWA Kraj: POLSKA Data wykonania operacji: 2025-06-27 02:00 Oryginalna kwota operacji: 70.00 Numer karty: 425125******0264 (70.', '2025-06-29', 'seed-cbd75a007b0d3ee2'
  FROM categories c WHERE c.name = 'restauracje'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 19.0, 'Tytuł:  74410495178025297766952  Lokalizacja: Adres: Foka Mochi       56748 Miasto: WARSZAWA Kraj: POLSKA Data wykonania operacji: 2025-06-27 02:00 Oryginalna kwota operacji: 19.00 Numer karty: 425125', '2025-06-29', 'seed-43545603a3c2f238'
  FROM categories c WHERE c.name = 'restauracje'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 149.0, 'Tytuł: 010061097 74463675178501791766337  Lokalizacja: Adres: WWW BILKOM PL Miasto: WARSZAWA Kraj: POLSKA Data wykonania operacji: 2025-06-27 02:00 Oryginalna kwota operacji: 149.00 Numer karty: 42512', '2025-06-29', 'seed-083b7da9002b8c12'
  FROM categories c WHERE c.name = 'przejazdy'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 4.5, 'Tytuł: 000498849 74230785178170314281692  Lokalizacja: Adres: ZABKA Z0685 K.1 Miasto: POZNAN Kraj: POLSKA Data wykonania operacji: 2025-06-27 02:00 Oryginalna kwota operacji: 4.50 Numer karty: 425125*', '2025-06-29', 'seed-8f4348de457b6758'
  FROM categories c WHERE c.name = 'żabka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 20.0, 'Tytuł:  74838495178316559138442  Lokalizacja: Adres: ALL GOOD S.A. KAWIAR 02 Miasto: WARSZAWA Kraj: POLSKA Data wykonania operacji: 2025-06-27 02:00 Oryginalna kwota operacji: 20.00 Numer karty: 42512', '2025-06-29', 'seed-4cf36236e2ff3851'
  FROM categories c WHERE c.name = 'kawa'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 170.0, 'Tytuł:  74810315178161829276198  Lokalizacja: Adres: MUR Miasto: Krakow Kraj: POLSKA Data wykonania operacji: 2025-06-27 02:00 Oryginalna kwota operacji: 170.00 Numer karty: 425125******0264 (170.00 P', '2025-06-29', 'seed-8c59857d0cc52c88'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 24.3, 'Tytuł:  74810315178161776884390  Lokalizacja: Adres: SANDRAS MATCHA Miasto: WARSZAWA Kraj: POLSKA Data wykonania operacji: 2025-06-27 02:00 Oryginalna kwota operacji: 24.30 Numer karty: 425125******02', '2025-06-29', 'seed-38907ebe11807ef9'
  FROM categories c WHERE c.name = 'restauracje'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 149.0, 'Tytuł: 010061097 74463675178501791767764  Lokalizacja: Adres: WWW BILKOM PL Miasto: WARSZAWA Kraj: POLSKA Data wykonania operacji: 2025-06-27 02:00 Oryginalna kwota operacji: 149.00 Numer karty: 42512', '2025-06-29', 'seed-9ba79ff7428ab3c6'
  FROM categories c WHERE c.name = 'przejazdy'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 17.49, 'Tytuł: 000498849 74230785178170322850918  Lokalizacja: Adres: ZABKA Z8683 K.1 Miasto: WARSZAWA Kraj: POLSKA Data wykonania operacji: 2025-06-27 02:00 Oryginalna kwota operacji: 17.49 Numer karty: 4251', '2025-06-29', 'seed-0a4dd4bec2fc744f'
  FROM categories c WHERE c.name = 'żabka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 48.0, 'Tytuł: 010061097 74169505178651783676816  Lokalizacja: Adres: HAPPA TO MAME Miasto: POZNAN Kraj: POLSKA Data wykonania operacji: 2025-06-27 02:00 Oryginalna kwota operacji: 48.00 Numer karty: 425125**', '2025-06-29', 'seed-c403423d7f93dd65'
  FROM categories c WHERE c.name = 'restauracje'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 50.0, 'Tytuł:  74838495178316589744615  Lokalizacja: Adres: ALL GOOD S.A. KAWIAR 02 Miasto: WARSZAWA Kraj: POLSKA Data wykonania operacji: 2025-06-27 02:00 Oryginalna kwota operacji: 50.00 Numer karty: 42512', '2025-06-29', 'seed-ee61f74ab3de00cc'
  FROM categories c WHERE c.name = 'kawa'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 50.49, 'Tytuł:  74838495177316390018200  Lokalizacja: Adres: ZIKO APTEKA 05 Miasto: Poznan Kraj: POLSKA Data wykonania operacji: 2025-06-26 02:00 Oryginalna kwota operacji: 50.49 Numer karty: 425125******0264', '2025-06-28', 'seed-d7feff41382e9d3a'
  FROM categories c WHERE c.name = 'apteka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 9.99, 'Tytuł: 000498849 74230785177170227140259  Lokalizacja: Adres: ZABKA Z5606 K.2 Miasto: POZNAN Kraj: POLSKA Data wykonania operacji: 2025-06-26 02:00 Oryginalna kwota operacji: 9.99 Numer karty: 425125*', '2025-06-28', 'seed-4d750ec5cb581515'
  FROM categories c WHERE c.name = 'żabka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 32.0, 'Tytuł:  74810315177161695044358  Lokalizacja: Adres: RESTAURACJA LORO Miasto: POZNAN Kraj: POLSKA Data wykonania operacji: 2025-06-26 02:00 Oryginalna kwota operacji: 32.00 Numer karty: 425125******02', '2025-06-28', 'seed-7ec05f53e5783e2e'
  FROM categories c WHERE c.name = 'restauracje'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 25.28, 'Tytuł: 000498849 74230785177170201527877  Lokalizacja: Adres: NETTO 5304 SCO K.3 Miasto: POZNAN Kraj: POLSKA Data wykonania operacji: 2025-06-25 02:00 Oryginalna kwota operacji: 25.28 Numer karty: 425', '2025-06-27', 'seed-6db6f45bbe36ec12'
  FROM categories c WHERE c.name = 'biedronka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 45.0, 'Tytuł: 010082965 74987075177030255396325  Lokalizacja: Adres: Allegro Miasto: Poznan Kraj: POLSKA Data wykonania operacji: 2025-06-25 02:00 Oryginalna kwota operacji: 45.00 Numer karty: 425125******02', '2025-06-27', 'seed-e8acce332de5e011'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 25.97, 'Tytuł: 000498849 74230785176170131358139  Lokalizacja: Adres: NETTO 5304 SCO K.3 Miasto: POZNAN Kraj: POLSKA Data wykonania operacji: 2025-06-24 02:00 Oryginalna kwota operacji: 25.97 Numer karty: 425', '2025-06-26', 'seed-07a2c87f2603a8e2'
  FROM categories c WHERE c.name = 'biedronka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 23.8, 'Tytuł:  74410495174025237102783  Lokalizacja: Adres: Gospodarstwo Roln74291 Miasto: Poznan Kraj: POLSKA Data wykonania operacji: 2025-06-23 02:00 Oryginalna kwota operacji: 23.80 Numer karty: 425125**', '2025-06-25', 'seed-8116c800c55598ab'
  FROM categories c WHERE c.name = 'biedronka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 338.55, 'Tytuł:  74838495174315953382493  Lokalizacja: Adres: ZIKO APTEKA 05 Miasto: Poznan Kraj: POLSKA Data wykonania operacji: 2025-06-23 02:00 Oryginalna kwota operacji: 338.55 Numer karty: 425125******026', '2025-06-25', 'seed-84a337571e6d7603'
  FROM categories c WHERE c.name = 'apteka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 250.0, 'Tytuł: 010061097 74169505174611746798366  Lokalizacja: Adres: PRACOWNIA PSYCHOLOGICZNA Miasto: POZNAN Kraj: POLSKA Data wykonania operacji: 2025-06-23 02:00 Oryginalna kwota operacji: 250.00 Numer kar', '2025-06-25', 'seed-d148b0b98684de94'
  FROM categories c WHERE c.name = 'lekarz'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 280.0, 'Tytuł: 000498849 74230785175170053494251  Lokalizacja: Adres: SYNAPSIS MED Miasto: POZNAN Kraj: POLSKA Data wykonania operacji: 2025-06-23 02:00 Oryginalna kwota operacji: 280.00 Numer karty: 425125**', '2025-06-25', 'seed-8368a8523805dff9'
  FROM categories c WHERE c.name = 'lekarz'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 5.0, 'Tytuł: 010061097 74463675173591735843016  Lokalizacja: Adres: MYJNIA ADEX Miasto: RYBNIK Kraj: POLSKA Data wykonania operacji: 2025-06-21 02:00 Oryginalna kwota operacji: 5.00 Numer karty: 425125*****', '2025-06-24', 'seed-b78e8b82837918d0'
  FROM categories c WHERE c.name = 'arval'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 2.0, 'Tytuł: 010061097 74463675173591735843032  Lokalizacja: Adres: MYJNIA ADEX Miasto: RYBNIK Kraj: POLSKA Data wykonania operacji: 2025-06-21 02:00 Oryginalna kwota operacji: 2.00 Numer karty: 425125*****', '2025-06-24', 'seed-28f8bca88ef03b87'
  FROM categories c WHERE c.name = 'arval'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 2.0, 'Tytuł: 010061097 74463675173591735842513  Lokalizacja: Adres: MYJNIA ADEX Miasto: RYBNIK Kraj: POLSKA Data wykonania operacji: 2025-06-21 02:00 Oryginalna kwota operacji: 2.00 Numer karty: 425125*****', '2025-06-24', 'seed-6e34013a51fcc0ee'
  FROM categories c WHERE c.name = 'arval'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 5.0, 'Tytuł: 010061097 74463675173591735842760  Lokalizacja: Adres: MYJNIA ADEX Miasto: RYBNIK Kraj: POLSKA Data wykonania operacji: 2025-06-21 02:00 Oryginalna kwota operacji: 5.00 Numer karty: 425125*****', '2025-06-24', 'seed-202e3e41867947a6'
  FROM categories c WHERE c.name = 'arval'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 5.0, 'Tytuł: 00000089029348003   Numer telefonu: 48796555364 Lokalizacja: Adres: doladuj.plus.pl ''Operacja: 00000089029348003 Numer referencyjny: 00000089029348003 (5.00 PLN)', '2025-06-23', 'seed-a246678e5c02e383'
  FROM categories c WHERE c.name = 'biuro'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 54.45, 'Tytuł:  74988855172496403120561  Lokalizacja: Adres: JMP S.A. BIEDRONKA 3352 Miasto: KUZNIA RACIBO Kraj: POLSKA Data wykonania operacji: 2025-06-21 02:00 Oryginalna kwota operacji: 54.45 Numer karty: ', '2025-06-23', 'seed-a714fa9b8ca024f6'
  FROM categories c WHERE c.name = 'biedronka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 4.0, 'Tytuł:  74810315172161129651708  Lokalizacja: Adres: MYJNIA HENRYK DLUGOSZ Miasto: Kuznia Racibo Kraj: POLSKA Data wykonania operacji: 2025-06-21 02:00 Oryginalna kwota operacji: 4.00 Numer karty: 425', '2025-06-23', 'seed-8a6d9f54f6f844ba'
  FROM categories c WHERE c.name = 'arval'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 4.0, 'Tytuł:  74810315172161130150310  Lokalizacja: Adres: MYJNIA HENRYK DLUGOSZ Miasto: Kuznia Racibo Kraj: POLSKA Data wykonania operacji: 2025-06-21 02:00 Oryginalna kwota operacji: 4.00 Numer karty: 425', '2025-06-23', 'seed-554691e3651ce5eb'
  FROM categories c WHERE c.name = 'arval'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 115.0, 'Rachunek odbiorcy: 18 1140 2004 0000 3202 7583 1760 Nazwa odbiorcy: WOJCIECH BOGUSZ Tytuł: PRZELEW NA TELEFON  OD: 48796555364 DO: 486*****503 (115.00 PLN)', '2025-06-22', 'seed-d10de145763887fe'
  FROM categories c WHERE c.name = 'restauracje'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 149.56, 'Tytuł:  74837975172499851109861  Lokalizacja: Adres: IKEA Katowice Miasto: Katowice Kraj: POLSKA Data wykonania operacji: 2025-06-20 02:00 Oryginalna kwota operacji: 149.56 Numer karty: 425125******02', '2025-06-22', 'seed-943f4c9b9f9a2f9d'
  FROM categories c WHERE c.name = 'mieszkanie'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 49.77, 'Tytuł:  74988855171496530041467  Lokalizacja: Adres: JMP S.A. BIEDRONKA 6374 Miasto: KATOWICE Kraj: POLSKA Data wykonania operacji: 2025-06-20 02:00 Oryginalna kwota operacji: 49.77 Numer karty: 42512', '2025-06-22', 'seed-58d59085123ad547'
  FROM categories c WHERE c.name = 'biedronka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 65.0, 'Tytuł: 010082965 74987075172030109942618  Lokalizacja: Adres: Allegro Miasto: Poznan Kraj: POLSKA Data wykonania operacji: 2025-06-20 02:00 Oryginalna kwota operacji: 65.00 Numer karty: 425125******02', '2025-06-22', 'seed-2bdd1a5312ec1df4'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 5.0, 'Tytuł: 010061097 74463675171581712433909  Lokalizacja: Adres: PROCAR WOJCIECH MEDRALA Miasto: NYSA Kraj: POLSKA Data wykonania operacji: 2025-06-19 02:00 Oryginalna kwota operacji: 5.00 Numer karty: 4', '2025-06-22', 'seed-86a8d2cc16410eac'
  FROM categories c WHERE c.name = 'arval'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 2.0, 'Tytuł: 010061097 74463675171581712433610  Lokalizacja: Adres: PROCAR WOJCIECH MEDRALA Miasto: NYSA Kraj: POLSKA Data wykonania operacji: 2025-06-19 02:00 Oryginalna kwota operacji: 2.00 Numer karty: 4', '2025-06-22', 'seed-51ac4c78bf0644a1'
  FROM categories c WHERE c.name = 'arval'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 24.99, 'Tytuł:  74838495170315385519666  Lokalizacja: Adres: PL KFC RZEDZIWOJOWICE A Miasto: RZEDZIWOJOWIC Kraj: POLSKA Data wykonania operacji: 2025-06-19 02:00 Oryginalna kwota operacji: 24.99 Numer karty: ', '2025-06-21', 'seed-05429f9de4cabeaa'
  FROM categories c WHERE c.name = 'restauracje'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 27.22, 'Tytuł:  74838495169315105882819  Lokalizacja: Adres: LIDL 1884 Miasto: POZNAN Kraj: POLSKA Data wykonania operacji: 2025-06-17 02:00 Oryginalna kwota operacji: 27.22 Numer karty: 425125******0264 (27.', '2025-06-19', 'seed-2cf4246918d1e1cf'
  FROM categories c WHERE c.name = 'arval'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 32.0, 'Tytuł:  74810315168160755174684  Lokalizacja: Adres: POLEWSKI CONCEPT Miasto: Poznan Kraj: POLSKA Data wykonania operacji: 2025-06-17 02:00 Oryginalna kwota operacji: 32.00 Numer karty: 425125******02', '2025-06-19', 'seed-2359f799702aae26'
  FROM categories c WHERE c.name = 'biedronka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 14.99, 'Tytuł: 010066928 74056285167100884754740  Lokalizacja: Adres: APPLE.COM/BILL Miasto: APPLE.COM/BIL Kraj: IRLANDIA Data wykonania operacji: 2025-06-16 02:00 Oryginalna kwota operacji: 14.99 Numer karty', '2025-06-18', 'seed-44ddead1df2979f3'
  FROM categories c WHERE c.name = 'biuro'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 53.55, 'Tytuł: 010071549 74043215167131128414380  Lokalizacja: Adres: PayPro SA   *ALLEGRO SP. Miasto: Poznan Kraj: POLSKA Data wykonania operacji: 2025-06-16 02:00 Oryginalna kwota operacji: 53.55 Numer kart', '2025-06-18', 'seed-f78da46755f9045a'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 44.0, 'Tytuł: 000498849 74230785167169531950983  Lokalizacja: Adres: SOUP CULTURE ROSWELL Miasto: POZNAN Kraj: POLSKA Data wykonania operacji: 2025-06-16 02:00 Oryginalna kwota operacji: 44.00 Numer karty: 4', '2025-06-18', 'seed-5344f68e8c8d744f'
  FROM categories c WHERE c.name = 'restauracje'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 250.0, 'Tytuł: 010061097 74169505167611679237795  Lokalizacja: Adres: PRACOWNIA PSYCHOLOGICZNA Miasto: POZNAN Kraj: POLSKA Data wykonania operacji: 2025-06-16 02:00 Oryginalna kwota operacji: 250.00 Numer kar', '2025-06-18', 'seed-2fd56f93201f794b'
  FROM categories c WHERE c.name = 'lekarz'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 109.99, 'Tytuł: 010061097 74463675166501671103019  Lokalizacja: Adres: MEDIAEXPERT PL Miasto: ZLOTOW Kraj: POLSKA Data wykonania operacji: 2025-06-15 02:00 Oryginalna kwota operacji: 109.99 Numer karty: 425125', '2025-06-17', 'seed-fb36cbad3a25cee8'
  FROM categories c WHERE c.name = 'mieszkanie'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 24.9, 'Tytuł:  74838495166314728188426  Lokalizacja: Adres: PL SBX POZNAN KAPONIERA Miasto: POZNAN Kraj: POLSKA Data wykonania operacji: 2025-06-15 02:00 Oryginalna kwota operacji: 24.90 Numer karty: 425125*', '2025-06-17', 'seed-84b2262ab7d9b90d'
  FROM categories c WHERE c.name = 'kawa'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 103.5, 'Rachunek odbiorcy: 21 1020 4027 3011 0000 3014 3739 Nazwa odbiorcy: INEA SP. Z O.O.WYSOGOTOWO,UL.WIERZB OWA 8462-081 PRZEŹMIEROWO Tytuł: 90784/2025/06/IS/DS   Referencje własne zleceniodawcy: 17575484', '2025-06-16', 'seed-dfa00673bd829c98'
  FROM categories c WHERE c.name = 'mieszkanie'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 268.43, 'Tytuł: 00000088889128149   Numer telefonu: 48796555364 Lokalizacja: Adres: IKEA POZNAN Miasto: POZNAN Kraj: POLSKA ''Operacja: 00000088889128149 Numer referencyjny: 00000088889128149 (268.43 PLN)', '2025-06-16', 'seed-8c92d48c129be2be'
  FROM categories c WHERE c.name = 'mieszkanie'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 4.0, 'Tytuł:  74810315165160503262131  Lokalizacja: Adres: Myjnia bezdotykowa Miasto: Poznan Kraj: POLSKA Data wykonania operacji: 2025-06-14 02:00 Oryginalna kwota operacji: 4.00 Numer karty: 425125******0', '2025-06-16', 'seed-d6ac466dfd3d3857'
  FROM categories c WHERE c.name = 'arval'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 4.0, 'Tytuł:  74810315165160503157877  Lokalizacja: Adres: Myjnia bezdotykowa Miasto: Poznan Kraj: POLSKA Data wykonania operacji: 2025-06-14 02:00 Oryginalna kwota operacji: 4.00 Numer karty: 425125******0', '2025-06-16', 'seed-12fbbc6658a6bd46'
  FROM categories c WHERE c.name = 'arval'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 4.0, 'Tytuł:  74810315165160502939655  Lokalizacja: Adres: Myjnia bezdotykowa Miasto: Poznan Kraj: POLSKA Data wykonania operacji: 2025-06-14 02:00 Oryginalna kwota operacji: 4.00 Numer karty: 425125******0', '2025-06-16', 'seed-4768a4ddcca09ede'
  FROM categories c WHERE c.name = 'arval'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 4.0, 'Tytuł:  74810315165160502835994  Lokalizacja: Adres: Myjnia bezdotykowa Miasto: Poznan Kraj: POLSKA Data wykonania operacji: 2025-06-14 02:00 Oryginalna kwota operacji: 4.00 Numer karty: 425125******0', '2025-06-16', 'seed-1a1f7d14b0d30d0f'
  FROM categories c WHERE c.name = 'arval'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 4.0, 'Tytuł:  74810315165160502733611  Lokalizacja: Adres: Myjnia bezdotykowa Miasto: Poznan Kraj: POLSKA Data wykonania operacji: 2025-06-14 02:00 Oryginalna kwota operacji: 4.00 Numer karty: 425125******0', '2025-06-16', 'seed-3986f3f1984efe6a'
  FROM categories c WHERE c.name = 'arval'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 4.0, 'Tytuł:  74810315165160502612815  Lokalizacja: Adres: Myjnia bezdotykowa Miasto: Poznan Kraj: POLSKA Data wykonania operacji: 2025-06-14 02:00 Oryginalna kwota operacji: 4.00 Numer karty: 425125******0', '2025-06-16', 'seed-e3f1fdb65eb24c3c'
  FROM categories c WHERE c.name = 'arval'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 202.5, 'Tytuł: 010087885 74987505165000708587044  Lokalizacja: Adres: BsCaffe Grzegorz Bienko Miasto: Stalowa Wola Kraj: POLSKA Data wykonania operacji: 2025-06-14 02:00 Oryginalna kwota operacji: 202.50 Nume', '2025-06-16', 'seed-95e002480907f8a4'
  FROM categories c WHERE c.name = 'kawa'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 4.0, 'Tytuł:  74810315165160502495856  Lokalizacja: Adres: Myjnia bezdotykowa Miasto: Poznan Kraj: POLSKA Data wykonania operacji: 2025-06-14 02:00 Oryginalna kwota operacji: 4.00 Numer karty: 425125******0', '2025-06-16', 'seed-5243783dc7896048'
  FROM categories c WHERE c.name = 'arval'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 9.99, 'Tytuł: 010066928 74056285164107855297255  Lokalizacja: Adres: Sklep Prime Video Miasto: primevideo.pl Kraj: LUKSEMBURG Data wykonania operacji: 2025-06-13 02:00 Oryginalna kwota operacji: 9.99 Numer k', '2025-06-15', 'seed-8d86071f0ac0042c'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 37.0, 'Tytuł: 000498849 74230785163169236568175  Lokalizacja: Adres: SOUP CULTURE ROSWELL Miasto: POZNAN Kraj: POLSKA Data wykonania operacji: 2025-06-12 02:00 Oryginalna kwota operacji: 37.00 Numer karty: 4', '2025-06-14', 'seed-338fd3b9a77eedaa'
  FROM categories c WHERE c.name = 'restauracje'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 4.2, 'Tytuł: 000498849 74230785162169181758202  Lokalizacja: Adres: ZABKA Z6210 K.1 Miasto: POZNAN Kraj: POLSKA Data wykonania operacji: 2025-06-11 02:00 Oryginalna kwota operacji: 4.20 Numer karty: 425125*', '2025-06-13', 'seed-6c7def80e3aed55b'
  FROM categories c WHERE c.name = 'żabka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 9.99, 'Tytuł: 000498849 74230785162169181457623  Lokalizacja: Adres: ZABKA Z0685 K.1 Miasto: POZNAN Kraj: POLSKA Data wykonania operacji: 2025-06-11 02:00 Oryginalna kwota operacji: 9.99 Numer karty: 425125*', '2025-06-13', 'seed-f4c77ebdf9f923bb'
  FROM categories c WHERE c.name = 'żabka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 19.0, 'Tytuł:  74838495162314092097595  Lokalizacja: Adres: AGRAWKA Miasto: POZNAN Kraj: POLSKA Data wykonania operacji: 2025-06-11 02:00 Oryginalna kwota operacji: 19.00 Numer karty: 425125******0264 (19.00', '2025-06-13', 'seed-7cff2f15ca5fa303'
  FROM categories c WHERE c.name = 'kawa'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 75.0, 'Tytuł:  74810315162160106516464  Lokalizacja: Adres: Mowish Mash Miasto: Poznan Kraj: POLSKA Data wykonania operacji: 2025-06-11 02:00 Oryginalna kwota operacji: 75.00 Numer karty: 425125******0264 (7', '2025-06-13', 'seed-932dfed00da11785'
  FROM categories c WHERE c.name = 'restauracje'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 42.0, 'Tytuł: 00000088846293495   Numer telefonu: 48796555364 Lokalizacja: Adres: www.upmenu.com ''Operacja: 00000088846293495 Numer referencyjny: 00000088846293495 (42.00 PLN)', '2025-06-13', 'seed-cdf15ec047c4a4af'
  FROM categories c WHERE c.name = 'restauracje'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 63.0, 'Tytuł: 00000088836652854   Numer telefonu: 48796555364 Lokalizacja: Adres: www.paperconcept.pl ''Operacja: 00000088836652854 Numer referencyjny: 00000088836652854 (63.00 PLN)', '2025-06-13', 'seed-d4e758d89ff45a76'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 8.99, 'Tytuł: 000498849 74230785162169136656311  Lokalizacja: Adres: NETTO 5304 SCO K.1 Miasto: POZNAN Kraj: POLSKA Data wykonania operacji: 2025-06-10 02:00 Oryginalna kwota operacji: 8.99 Numer karty: 4251', '2025-06-12', 'seed-b4f882dc3b4271d7'
  FROM categories c WHERE c.name = 'biedronka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 250.0, 'Tytuł: 010061097 74169505160611600623086  Lokalizacja: Adres: PRACOWNIA PSYCHOLOGICZNA Miasto: POZNAN Kraj: POLSKA Data wykonania operacji: 2025-06-09 02:00 Oryginalna kwota operacji: 250.00 Numer kar', '2025-06-11', 'seed-c4dd474fbf064224'
  FROM categories c WHERE c.name = 'lekarz'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 21.63, 'Tytuł: 000498849 74230785161169061680303  Lokalizacja: Adres: NETTO 5304 SCO K.3 Miasto: POZNAN Kraj: POLSKA Data wykonania operacji: 2025-06-09 02:00 Oryginalna kwota operacji: 21.63 Numer karty: 425', '2025-06-11', 'seed-3acd15fa1b2f8611'
  FROM categories c WHERE c.name = 'biedronka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 300.0, 'Tytuł: S1PO2028 6600 00000088794027761   Numer telefonu: 48796555364 Lokalizacja: Adres: UL. ROOSEVELTA 11 Miasto: POZNAN Kraj: POLSKA Bankomat: S1PO2028 ''Operacja: 6600 00000088794027761 Numer refer', '2025-06-11', 'seed-895eef3b1e8d4824'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 45.0, 'Tytuł: 010082965 74987075159029656735240  Lokalizacja: Adres: Allegro Miasto: Poznan Kraj: POLSKA Data wykonania operacji: 2025-06-07 02:00 Oryginalna kwota operacji: 45.00 Numer karty: 425125******02', '2025-06-09', 'seed-88fed1645fcdb299'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 206.0, 'Tytuł: 010061097 74463675158501591607503  Lokalizacja: Adres: ZJEDZ MY Miasto: SZCZECIN Kraj: POLSKA Data wykonania operacji: 2025-06-07 02:00 Oryginalna kwota operacji: 206.00 Numer karty: 425125****', '2025-06-09', 'seed-65a6423dc96b2789'
  FROM categories c WHERE c.name = 'restauracje'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 16.08, 'Tytuł: 000498849 74230785159168953370662  Lokalizacja: Adres: NETTO 5304 SCO K.1 Miasto: POZNAN Kraj: POLSKA Data wykonania operacji: 2025-06-07 02:00 Oryginalna kwota operacji: 16.08 Numer karty: 425', '2025-06-09', 'seed-19e9b4da7ae9e015'
  FROM categories c WHERE c.name = 'biedronka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 19.49, 'Tytuł: 000498849 74230785156168770837391  Lokalizacja: Adres: ZABKA Z0685 K.1 Miasto: POZNAN Kraj: POLSKA Data wykonania operacji: 2025-06-05 02:00 Oryginalna kwota operacji: 19.49 Numer karty: 425125', '2025-06-07', 'seed-cefea7e142edbcc3'
  FROM categories c WHERE c.name = 'żabka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 1100.0, 'Tytuł: 010085232 74350275155010119906114  Lokalizacja: Adres: Revolut**7108* Miasto: Dublin Kraj: IRLANDIA Data wykonania operacji: 2025-06-04 02:00 Oryginalna kwota operacji: 1100.00 Numer karty: 425', '2025-06-06', 'seed-d7730edb75e4c67e'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 19.0, 'Tytuł:  74838495155312985454252  Lokalizacja: Adres: STRAG. Miasto: POZNAN Kraj: POLSKA Data wykonania operacji: 2025-06-04 02:00 Oryginalna kwota operacji: 19.00 Numer karty: 425125******0264 (19.00 ', '2025-06-06', 'seed-8a4a65ddcec4af72'
  FROM categories c WHERE c.name = 'kawa'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 42.0, 'Tytuł: 00000088691867892   Numer telefonu: 48796555364 Lokalizacja: Adres: www.upmenu.com ''Operacja: 00000088691867892 Numer referencyjny: 00000088691867892 (42.00 PLN)', '2025-06-06', 'seed-5be313798c18d5ca'
  FROM categories c WHERE c.name = 'restauracje'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 12.99, 'Tytuł:  74838495155312861189956  Lokalizacja: Adres: LIDL MATYI Miasto: POZNAN Kraj: POLSKA Data wykonania operacji: 2025-06-03 02:00 Oryginalna kwota operacji: 12.99 Numer karty: 425125******0264 (12', '2025-06-05', 'seed-490c82cc4c532d6c'
  FROM categories c WHERE c.name = 'biedronka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 133.98, 'Tytuł: 000498849 74230785154168599982966  Lokalizacja: Adres: MEDIA MARKT P519 K.102 Miasto: POZNAN Kraj: POLSKA Data wykonania operacji: 2025-06-03 02:00 Oryginalna kwota operacji: 133.98 Numer karty', '2025-06-05', 'seed-625915104168e68d'
  FROM categories c WHERE c.name = 'mieszkanie'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 158.12, 'Tytuł: 000498849 74230785154168587916349  Lokalizacja: Adres: NETTO 5304 SCO K.2 Miasto: POZNAN Kraj: POLSKA Data wykonania operacji: 2025-06-02 02:00 Oryginalna kwota operacji: 158.12 Numer karty: 42', '2025-06-04', 'seed-876940724f0609fa'
  FROM categories c WHERE c.name = 'biedronka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 363.0, 'Rachunek odbiorcy: 21 1940 1076 6256 6800 0000 0000 Nazwa odbiorcy: ADAM TYŻYK Tytuł: 12 MP/06/2025   Referencje własne zleceniodawcy: 175709436231 (363.00 PLN)', '2025-06-04', 'seed-dd3d6352e9b99633'
  FROM categories c WHERE c.name = 'mieszkanie'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 350.0, 'Tytuł: OBCY 00000088634580725   Numer telefonu: 48796555364 Lokalizacja: Adres: LEGNICKA 58 Miasto: WROCLAW Kraj: POLSKA Bankomat: OBCY ''Operacja: 00000088634580725 Numer referencyjny: 00000088634580', '2025-06-03', 'seed-d6b982bb2dbccb99'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 14.0, 'Tytuł: 000498849 74230785152168507134744  Lokalizacja: Adres: ZABKA Z5606 K.2 Miasto: POZNAN Kraj: POLSKA Data wykonania operacji: 2025-06-01 02:00 Oryginalna kwota operacji: 14.00 Numer karty: 425125', '2025-06-03', 'seed-0be6c9a88b6c2204'
  FROM categories c WHERE c.name = 'żabka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 1400.0, 'Rachunek odbiorcy: 73 1090 2372 0000 0001 1332 9442 Nazwa odbiorcy: MARTA SZCZYGIEŁ Tytuł: PRZELEW NA TELEFON  OD: 48796555364 DO: 486*****967 (1400.00 PLN)', '2025-06-03', 'seed-6dc9e750717615d6'
  FROM categories c WHERE c.name = 'mieszkanie'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 30.0, 'Tytuł: 00000088594870957   Numer telefonu: 48796555364 Lokalizacja: Adres: www.mobilet.pl ''Operacja: 00000088594870957 Numer referencyjny: 00000088594870957 (30.00 PLN)', '2025-06-02', 'seed-af5e162464449c9b'
  FROM categories c WHERE c.name = 'przejazdy'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 4.0, 'Nazwa odbiorcy: MOBILE-TRAFFIC-DATA SP. Z O. O. Adres odbiorcy: UL. DRUŻBICKIEGO 11 61-693 POZNAŃ Tytuł: ZAKUP BILETU KOMUNIKACYJNEGO W APLI KACJI IKO  Referencje własne zleceniodawcy: 175701604284 (4', '2025-06-02', 'seed-a673b1b37b15bbee'
  FROM categories c WHERE c.name = 'przejazdy'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 109.5, 'Tytuł: 000498849 74230785151168401661132  Lokalizacja: Adres: PLON1 Miasto: WROCLAW Kraj: POLSKA Data wykonania operacji: 2025-05-31 02:00 Oryginalna kwota operacji: 109.50 Numer karty: 425125******02', '2025-06-02', 'seed-8b1132cbf9ead00a'
  FROM categories c WHERE c.name = 'biedronka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 54.0, 'Tytuł:  74810315151158971186119  Lokalizacja: Adres: good good Miasto: Wroclaw Kraj: POLSKA Data wykonania operacji: 2025-05-31 02:00 Oryginalna kwota operacji: 54.00 Numer karty: 425125******0264 (54', '2025-06-02', 'seed-ca703df99cdce380'
  FROM categories c WHERE c.name = 'kawa'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 40.0, 'Tytuł: 010059127 74043215151129320183710  Lokalizacja: Adres: NFM APM Miasto: Wroclaw Kraj: POLSKA Data wykonania operacji: 2025-05-31 02:00 Oryginalna kwota operacji: 40.00 Numer karty: 425125******0', '2025-06-02', 'seed-c372bf4f246ebe09'
  FROM categories c WHERE c.name = 'arval'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 118.91, 'Tytuł: 010072805 24871155151094205976317  Lokalizacja: Adres: ALIEXPRESS.COM Miasto: Luxembourg Kraj: LUKSEMBURG Data wykonania operacji: 2025-05-31 02:00 Oryginalna kwota operacji: 118.91 Numer karty', '2025-06-02', 'seed-1afd35d1d1370a8e'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 301.17, 'Tytuł:  74838495152312458714961  Lokalizacja: Adres: SKLEP LIDL 1221 WROCLAW Miasto: WROCLAW Kraj: POLSKA Data wykonania operacji: 2025-05-31 02:00 Oryginalna kwota operacji: 301.17 Numer karty: 42512', '2025-06-02', 'seed-d96feccadc22d872'
  FROM categories c WHERE c.name = 'biedronka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 11.9, 'Tytuł:  74810315151158971410725  Lokalizacja: Adres: good good Miasto: Wroclaw Kraj: POLSKA Data wykonania operacji: 2025-05-31 02:00 Oryginalna kwota operacji: 11.90 Numer karty: 425125******0264 (11', '2025-06-02', 'seed-853f01319b22247b'
  FROM categories c WHERE c.name = 'kawa'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 4.0, 'Nazwa odbiorcy: MOBILE-TRAFFIC-DATA SP. Z O. O. Adres odbiorcy: UL. DRUŻBICKIEGO 11 61-693 POZNAŃ Tytuł: ZAKUP BILETU KOMUNIKACYJNEGO W APLI KACJI IKO  Referencje własne zleceniodawcy: 175701561075 (4', '2025-06-02', 'seed-b46e04e10f590bdb'
  FROM categories c WHERE c.name = 'przejazdy'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 82.0, 'Rachunek odbiorcy: 64 1090 2372 0000 0001 1966 4092 Nazwa odbiorcy: AGATA SZCZYGIEŁ Tytuł: WOOSIABI  OD: 48796555364 DO: 486*****559 (82.00 PLN)', '2025-06-01', 'seed-69ab485b4fe243b8'
  FROM categories c WHERE c.name = 'restauracje'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 15.1, 'Tytuł: 010061097 74463675150571501174413  Lokalizacja: Adres: GREEN CAFFE NERO Miasto: WROCLAW Kraj: POLSKA Data wykonania operacji: 2025-05-29 02:00 Oryginalna kwota operacji: 15.10 Numer karty: 4251', '2025-06-01', 'seed-c55ab2a98195dcb9'
  FROM categories c WHERE c.name = 'kawa'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 32.9, 'Tytuł: 010061097 74463675150571501174041  Lokalizacja: Adres: GREEN CAFFE NERO Miasto: WROCLAW Kraj: POLSKA Data wykonania operacji: 2025-05-29 02:00 Oryginalna kwota operacji: 32.90 Numer karty: 4251', '2025-06-01', 'seed-e77c2bdc6c13f8ff'
  FROM categories c WHERE c.name = 'kawa'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 381.87, 'KANCELARIA PODATKOWO-GOSPODARCZA SP ÓŁKA Z OGRANICZONĄ ODPOWIEDZIALNOŚC IĄ ul. Radomska 7 44-164 Gliwice NI P: PL 631-264-51-93   FA/41/06/2025', '2025-06-30', 'seed-fb9376aa98bdc6eb'
  FROM categories c WHERE c.name = 'biuro'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 212.11, 'BP-JAGLOWICE 289 TAAS  TRZEBIEL  PO   Płatność kartą 29.06.2025 Nr karty 4598xx4778', '2025-06-29', 'seed-929305f372c00ffe'
  FROM categories c WHERE c.name = 'paliwo'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 203.3, 'ORLEN STACJA NR 600  POZNAN  POL   Płatność kartą 29.06.2025 Nr karty 4598xx4778', '2025-06-29', 'seed-4d48ddf8dbb1f9cf'
  FROM categories c WHERE c.name = 'paliwo'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 450.0, 'LOUVRE HOTELS GROUP  Warszawa  POL   Płatność kartą 27.06.2025 Nr karty 4598xx4778', '2025-06-27', 'seed-df6faa47f12d1b9c'
  FROM categories c WHERE c.name = 'biuro'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 148.0, 'RESTAURACJA LORO  POZNAN  POL   Płatność kartą 26.06.2025 Nr karty 4598xx4778', '2025-06-26', 'seed-d0acb87bdace9ced'
  FROM categories c WHERE c.name = 'restauracje'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 164.16, 'ORLEN STACJA NR 199  KUZNIA RACIBO   Płatność kartą 21.06.2025 Nr karty 4598xx4778', '2025-06-21', 'seed-0bdde671249365e9'
  FROM categories c WHERE c.name = 'paliwo'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 260.25, 'STACJA PALIW NR 727  ZABKOWICE SLA   Płatność kartą 19.06.2025 Nr karty 4598xx4778', '2025-06-19', 'seed-e6c233d48c000f22'
  FROM categories c WHERE c.name = 'paliwo'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 3213.25, 'Zakład Ubezpieczeń Społecznych 47-400 Racibórz   Ubezpieczenie zdrowotne 05.2025', '2025-06-16', 'seed-89424e259040e6ee'
  FROM categories c WHERE c.name = 'zus'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 12.0, 'Urząd Skarbowy Centrum Rozliczeniowe   /TI/N6392015837/OKR/25M05/SFP/PIT4R', '2025-06-16', 'seed-02969280818fdfb0'
  FROM categories c WHERE c.name = 'pit36'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 6306.0, 'Urząd Skarbowy Centrum Rozliczeniowe   /TI/N6392015837/OKR/25M05/SFP/VAT7', '2025-06-16', 'seed-986b07c22fddc123'
  FROM categories c WHERE c.name = 'vat'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 3881.0, 'Urząd Skarbowy Centrum Rozliczeniowe   /TI/N6392015837/OKR/25M05/SFP/PPE', '2025-06-16', 'seed-d1739322dd854d1b'
  FROM categories c WHERE c.name = 'pit36'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 68.69, 'Inwestor Group Sp. z o. o. Spółka Komandytowa NIP: 6751577855 Sołtysowska 12B/LU4 31-589 Kraków   17/6/2025/PRO', '2025-06-06', 'seed-5598b60a7fe07afa'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 2298.27, 'BNP Paribas Leasing Services Sp. z o.o. 00-844 Warszawa, ul.Grzybowska 78   37629/06/2025/RL/LS', '2025-06-04', 'seed-fc305b6146611572'
  FROM categories c WHERE c.name = 'arval'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 82.29, 'Orange Polska S.A. Aleje Jerozolimskie 160 02-326 Warszawa NIP 526-025-09-95   F0083222849/006/25', '2025-06-04', 'seed-1a72f45d4707b669'
  FROM categories c WHERE c.name = 'biuro'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 246.0, 'P4 Sp. z o.o. ul. Wynalazek 1 02-677 Warszawa   F/10084492/06/25', '2025-06-04', 'seed-436a4faa9d830116'
  FROM categories c WHERE c.name = 'biuro'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 381.87, 'KANCELARIA PODATKOWO-GOSPODARCZA SP ÓŁKA Z OGRANICZONĄ ODPOWIEDZIALNOŚC IĄ ul. Radomska 7 44-164 Gliwice NI P: PL 631-264-51-93   FA/19/05/2025', '2025-06-03', 'seed-876c9d606208de53'
  FROM categories c WHERE c.name = 'biuro'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 1560.0, 'Tytuł:  74810315149158741023563  Lokalizacja: Adres: DENTA Miasto: Wroclaw Kraj: POLSKA Data wykonania operacji: 2025-05-29 02:00 Oryginalna kwota operacji: 1560.00 Numer karty: 425125******0264 (1560', '2025-05-31', 'seed-0b18c0746c38fb64'
  FROM categories c WHERE c.name = 'lekarz'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 3.5, 'Tytuł: 010061097 74463675149611497725242  Lokalizacja: Adres: KBU SPOLKA Z OGRANICZONA Miasto: STARE MIASTO Kraj: POLSKA Data wykonania operacji: 2025-05-29 02:00 Oryginalna kwota operacji: 3.50 Numer', '2025-05-31', 'seed-08cbeed27625a89b'
  FROM categories c WHERE c.name = 'arval'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 31.0, 'Tytuł: 000498849 74230785149168259758373  Lokalizacja: Adres: HUMMUS Miasto: WROCLAW Kraj: POLSKA Data wykonania operacji: 2025-05-29 02:00 Oryginalna kwota operacji: 31.00 Numer karty: 425125******02', '2025-05-31', 'seed-200d3ef4abe49e6b'
  FROM categories c WHERE c.name = 'restauracje'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 22.99, 'Tytuł:  74838495150312056561667  Lokalizacja: Adres: ROSSMANN 47 Miasto: WROCLAW Kraj: POLSKA Data wykonania operacji: 2025-05-29 02:00 Oryginalna kwota operacji: 22.99 Numer karty: 425125******0264 (', '2025-05-31', 'seed-04039da2c938d614'
  FROM categories c WHERE c.name = 'rossman'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 19.0, 'Tytuł: 010061097 74463675149591493450021  Lokalizacja: Adres: KBU SP Z O O  SPP WROCLAW Miasto: KRAKOW Kraj: POLSKA Data wykonania operacji: 2025-05-29 02:00 Oryginalna kwota operacji: 19.00 Numer kar', '2025-05-31', 'seed-3107346bd0bbf98e'
  FROM categories c WHERE c.name = 'arval'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 2.0, 'Tytuł: 010061097 74463675149611497729855  Lokalizacja: Adres: KBU SPOLKA Z OGRANICZONA Miasto: STARE MIASTO Kraj: POLSKA Data wykonania operacji: 2025-05-29 02:00 Oryginalna kwota operacji: 2.00 Numer', '2025-05-31', 'seed-faa875d046edbd9f'
  FROM categories c WHERE c.name = 'arval'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 5.5, 'Tytuł: 000498849 74230785148168229752903  Lokalizacja: Adres: ZABKA Z1048 K.2 Miasto: POZNAN Kraj: POLSKA Data wykonania operacji: 2025-05-28 02:00 Oryginalna kwota operacji: 5.50 Numer karty: 425125*', '2025-05-30', 'seed-bb4104c8afae4a6a'
  FROM categories c WHERE c.name = 'żabka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 28.58, 'Tytuł: 000498849 74230785149168246628283  Lokalizacja: Adres: NETTO 5304 SCO K.3 Miasto: POZNAN Kraj: POLSKA Data wykonania operacji: 2025-05-28 02:00 Oryginalna kwota operacji: 28.58 Numer karty: 425', '2025-05-30', 'seed-86bc2602da8f5541'
  FROM categories c WHERE c.name = 'biedronka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 2.99, 'Tytuł: 000498849 74230785148168214632060  Lokalizacja: Adres: ZABKA Z5606 K.2 Miasto: POZNAN Kraj: POLSKA Data wykonania operacji: 2025-05-28 02:00 Oryginalna kwota operacji: 2.99 Numer karty: 425125*', '2025-05-30', 'seed-d85307bcbf870e1f'
  FROM categories c WHERE c.name = 'żabka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 24.99, 'Tytuł:  74838495148311902336618  Lokalizacja: Adres: ZIKO APTEKA 05 Miasto: Poznan Kraj: POLSKA Data wykonania operacji: 2025-05-28 02:00 Oryginalna kwota operacji: 24.99 Numer karty: 425125******0264', '2025-05-30', 'seed-f97e445e6ff394a8'
  FROM categories c WHERE c.name = 'apteka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 49.22, 'Tytuł: 000498849 74230785148168179870747  Lokalizacja: Adres: NETTO 5304 SCO K.3 Miasto: POZNAN Kraj: POLSKA Data wykonania operacji: 2025-05-27 02:00 Oryginalna kwota operacji: 49.22 Numer karty: 425', '2025-05-29', 'seed-5969506a1b27ae4d'
  FROM categories c WHERE c.name = 'biedronka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 250.0, 'Tytuł: 010061097 74169505146621463413532  Lokalizacja: Adres: PRACOWNIA PSYCHOLOGICZNA Miasto: POZNAN Kraj: POLSKA Data wykonania operacji: 2025-05-26 02:00 Oryginalna kwota operacji: 250.00 Numer kar', '2025-05-28', 'seed-481cd578227255bf'
  FROM categories c WHERE c.name = 'lekarz'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 28.0, 'Tytuł: 000498849 74230785144167937006119  Lokalizacja: Adres: TEDI 7184 Miasto: ZABKOWICE SLA Kraj: POLSKA Data wykonania operacji: 2025-05-24 02:00 Oryginalna kwota operacji: 28.00 Numer karty: 42512', '2025-05-27', 'seed-af6164c2aab6aa4a'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 12.37, 'Tytuł: 010062941 74987505144003341679075  Lokalizacja: Adres: Action A123 Miasto: Zabkowice Sla Kraj: POLSKA Data wykonania operacji: 2025-05-24 02:00 Oryginalna kwota operacji: 12.37 Numer karty: 425', '2025-05-27', 'seed-5159d3d2677fbef4'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 2.0, 'Tytuł: 010061097 74463675145591452083023  Lokalizacja: Adres: PROCAR WOJCIECH MEDRALA Miasto: NYSA Kraj: POLSKA Data wykonania operacji: 2025-05-24 02:00 Oryginalna kwota operacji: 2.00 Numer karty: 4', '2025-05-27', 'seed-76696fabc9879ad3'
  FROM categories c WHERE c.name = 'arval'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 2.0, 'Tytuł: 010061097 74463675145591452083619  Lokalizacja: Adres: PROCAR WOJCIECH MEDRALA Miasto: NYSA Kraj: POLSKA Data wykonania operacji: 2025-05-24 02:00 Oryginalna kwota operacji: 2.00 Numer karty: 4', '2025-05-27', 'seed-1f65c647fff5852d'
  FROM categories c WHERE c.name = 'arval'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 5.0, 'Tytuł: 010061097 74463675145591452083551  Lokalizacja: Adres: PROCAR WOJCIECH MEDRALA Miasto: NYSA Kraj: POLSKA Data wykonania operacji: 2025-05-24 02:00 Oryginalna kwota operacji: 5.00 Numer karty: 4', '2025-05-27', 'seed-e76112e7f60735f2'
  FROM categories c WHERE c.name = 'arval'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 5.0, 'Tytuł: 010061097 74463675145591452083221  Lokalizacja: Adres: PROCAR WOJCIECH MEDRALA Miasto: NYSA Kraj: POLSKA Data wykonania operacji: 2025-05-24 02:00 Oryginalna kwota operacji: 5.00 Numer karty: 4', '2025-05-27', 'seed-364e966f049a8dd8'
  FROM categories c WHERE c.name = 'arval'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 5.0, 'Tytuł: 010061097 74463675145591452083213  Lokalizacja: Adres: PROCAR WOJCIECH MEDRALA Miasto: NYSA Kraj: POLSKA Data wykonania operacji: 2025-05-24 02:00 Oryginalna kwota operacji: 5.00 Numer karty: 4', '2025-05-27', 'seed-20792cc4143f432d'
  FROM categories c WHERE c.name = 'arval'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 255.99, 'Tytuł: 010082965 74987075144029141259226  Lokalizacja: Adres: Allegro Miasto: Poznan Kraj: POLSKA Data wykonania operacji: 2025-05-23 02:00 Oryginalna kwota operacji: 255.99 Numer karty: 425125******0', '2025-05-26', 'seed-ddf130b05b18ac4d'
  FROM categories c WHERE c.name = 'prezenty'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 4.0, 'Nazwa odbiorcy: MOBILE-TRAFFIC-DATA SP. Z O. O. Adres odbiorcy: UL. DRUŻBICKIEGO 11 61-693 POZNAŃ Tytuł: ZAKUP BILETU KOMUNIKACYJNEGO W APLI KACJI IKO  Referencje własne zleceniodawcy: 175677835271 (4', '2025-05-26', 'seed-ba67b5da70a3d93f'
  FROM categories c WHERE c.name = 'przejazdy'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 4.0, 'Nazwa odbiorcy: MOBILE-TRAFFIC-DATA SP. Z O. O. Adres odbiorcy: UL. DRUŻBICKIEGO 11 61-693 POZNAŃ Tytuł: ZAKUP BILETU KOMUNIKACYJNEGO W APLI KACJI IKO  Referencje własne zleceniodawcy: 175677547321 (4', '2025-05-26', 'seed-3e60627bc9696696'
  FROM categories c WHERE c.name = 'przejazdy'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 60.0, 'Tytuł: 000498849 74230785143167843959584  Lokalizacja: Adres: OKWIAT Miasto: POZNAN Kraj: POLSKA Data wykonania operacji: 2025-05-22 02:00 Oryginalna kwota operacji: 60.00 Numer karty: 425125******026', '2025-05-24', 'seed-43a683db40754cf4'
  FROM categories c WHERE c.name = 'prezenty'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 200.0, 'Tytuł: 010061097 74169505142641421696501  Lokalizacja: Adres: YUBA Miasto: POZNAN Kraj: POLSKA Data wykonania operacji: 2025-05-22 02:00 Oryginalna kwota operacji: 200.00 Numer karty: 425125******0264', '2025-05-24', 'seed-09e653f10e9c5e32'
  FROM categories c WHERE c.name = 'restauracje'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 27.01, 'Tytuł: 010062941 74987505142003550931060  Lokalizacja: Adres: Lindt Sklep PL13 Miasto: Poznan Kraj: POLSKA Data wykonania operacji: 2025-05-22 02:00 Oryginalna kwota operacji: 27.01 Numer karty: 42512', '2025-05-24', 'seed-e16524bf0d2d99b2'
  FROM categories c WHERE c.name = 'prezenty'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 15.0, 'Tytuł:  74410495141024812107390  Lokalizacja: Adres: ROCK GARAZ       38255 Miasto: Poznan Kraj: POLSKA Data wykonania operacji: 2025-05-21 02:00 Oryginalna kwota operacji: 15.00 Numer karty: 425125**', '2025-05-23', 'seed-17dfabda96b5fabd'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 72.6, 'Tytuł:  74810315141157942250528  Lokalizacja: Adres: Balans Miasto: POZNAN Kraj: POLSKA Data wykonania operacji: 2025-05-21 02:00 Oryginalna kwota operacji: 72.60 Numer karty: 425125******0264 (72.60 ', '2025-05-23', 'seed-de9eaae90a343ace'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 28.06, 'Tytuł:  74838495142310731275027  Lokalizacja: Adres: ROSSMANN 11 Miasto: Poznan Kraj: POLSKA Data wykonania operacji: 2025-05-21 02:00 Oryginalna kwota operacji: 28.06 Numer karty: 425125******0264 (2', '2025-05-23', 'seed-859a04b5b1fd55b7'
  FROM categories c WHERE c.name = 'rossman'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 59.55, 'Tytuł: 010072805 24871155139092033579672  Lokalizacja: Adres: ALIEXPRESS.COM Miasto: Luxembourg Kraj: LUKSEMBURG Data wykonania operacji: 2025-05-19 02:00 Oryginalna kwota operacji: 59.55 Numer karty:', '2025-05-21', 'seed-c2ad07a5dd083730'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 46.99, 'Tytuł: 010079564 74609055139100017438801  Lokalizacja: Adres: TIMELEFT Miasto: PARIS Kraj: FRANCJA Data wykonania operacji: 2025-05-19 02:00 Oryginalna kwota operacji: 46.99 Numer karty: 425125******0', '2025-05-21', 'seed-8a03cb82c262e84a'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 250.0, 'Tytuł: 010061097 74169505139591391542885  Lokalizacja: Adres: PRACOWNIA PSYCHOLOGICZNA Miasto: POZNAN Kraj: POLSKA Data wykonania operacji: 2025-05-19 02:00 Oryginalna kwota operacji: 250.00 Numer kar', '2025-05-21', 'seed-54caa2363e56a5fe'
  FROM categories c WHERE c.name = 'lekarz'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 200.0, 'Rachunek odbiorcy: 73 1090 2372 0000 0001 1332 9442 Nazwa odbiorcy: MARTA SZCZYGIEŁ Tytuł: DLA AGATKI  OD: 48796555364 DO: 486*****967 (200.00 PLN)', '2025-05-19', 'seed-b6a5b09c01b43f81'
  FROM categories c WHERE c.name = 'prezenty'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 65.0, 'Rachunek odbiorcy: 18 1140 2004 0000 3202 7583 1760 Nazwa odbiorcy: WOJCIECH BOGUSZ Tytuł: PRZELEW NA TELEFON  OD: 48796555364 DO: 486*****503 (65.00 PLN)', '2025-05-19', 'seed-f60318309800f02e'
  FROM categories c WHERE c.name = 'prezenty'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 4.0, 'Nazwa odbiorcy: MOBILE-TRAFFIC-DATA SP. Z O. O. Adres odbiorcy: UL. DRUŻBICKIEGO 11 61-693 POZNAŃ Tytuł: ZAKUP BILETU KOMUNIKACYJNEGO W APLI KACJI IKO  Referencje własne zleceniodawcy: 175655000157 (4', '2025-05-19', 'seed-71c7aff0da91a2c1'
  FROM categories c WHERE c.name = 'przejazdy'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 4.0, 'Nazwa odbiorcy: MOBILE-TRAFFIC-DATA SP. Z O. O. Adres odbiorcy: UL. DRUŻBICKIEGO 11 61-693 POZNAŃ Tytuł: ZAKUP BILETU KOMUNIKACYJNEGO W APLI KACJI IKO  Referencje własne zleceniodawcy: 175654752064 (4', '2025-05-19', 'seed-fa91915177cc3100'
  FROM categories c WHERE c.name = 'przejazdy'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 119.11, 'Tytuł: 010082965 74987075138028946076403  Lokalizacja: Adres: Allegro Miasto: Poznan Kraj: POLSKA Data wykonania operacji: 2025-05-17 02:00 Oryginalna kwota operacji: 119.11 Numer karty: 425125******0', '2025-05-19', 'seed-0ba12ad1061f681c'
  FROM categories c WHERE c.name = 'arval'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 15.0, 'Tytuł: 010061097 74169505137611371694209  Lokalizacja: Adres: CZARTORYSKI PIEKARNIA Miasto: POZNAN Kraj: POLSKA Data wykonania operacji: 2025-05-17 02:00 Oryginalna kwota operacji: 15.00 Numer karty: ', '2025-05-19', 'seed-e575b6480313ab87'
  FROM categories c WHERE c.name = 'biedronka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 14.99, 'Tytuł: 010066928 74056285136102720704705  Lokalizacja: Adres: APPLE.COM/BILL Miasto: APPLE.COM/BIL Kraj: IRLANDIA Data wykonania operacji: 2025-05-16 02:00 Oryginalna kwota operacji: 14.99 Numer karty', '2025-05-18', 'seed-6327d3e02433ab0a'
  FROM categories c WHERE c.name = 'biuro'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 76.95, 'Tytuł: 000498849 74230785135167327988208  Lokalizacja: Adres: NETTO 5304 SCO K.3 Miasto: POZNAN Kraj: POLSKA Data wykonania operacji: 2025-05-14 02:00 Oryginalna kwota operacji: 76.95 Numer karty: 425', '2025-05-16', 'seed-e0ce4f156d6ebc27'
  FROM categories c WHERE c.name = 'biedronka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 7.49, 'Tytuł: 000498849 74230785134167297657792  Lokalizacja: Adres: ZABKA Z0685 K.1 Miasto: POZNAN Kraj: POLSKA Data wykonania operacji: 2025-05-14 02:00 Oryginalna kwota operacji: 7.49 Numer karty: 425125*', '2025-05-16', 'seed-8f80699a3545233b'
  FROM categories c WHERE c.name = 'żabka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 45.24, 'Tytuł: 010082965 74987075135028754182882  Lokalizacja: Adres: Allegro Miasto: Poznan Kraj: POLSKA Data wykonania operacji: 2025-05-12 02:00 Oryginalna kwota operacji: 45.24 Numer karty: 425125******02', '2025-05-16', 'seed-1e14f7e7b0289eaf'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 25.0, 'Tytuł: 00000088258941871   Numer telefonu: 48796555364 Lokalizacja: Adres: doladowania.t-mobile.pl ''Operacja: 00000088258941871 Numer referencyjny: 00000088258941871 (25.00 PLN)', '2025-05-15', 'seed-6c9fcad12f71ffad'
  FROM categories c WHERE c.name = 'biuro'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 57.81, 'Tytuł: 010062941 74987505133002787828066  Lokalizacja: Adres: Lindt Sklep PL13 Miasto: Poznan Kraj: POLSKA Data wykonania operacji: 2025-05-13 02:00 Oryginalna kwota operacji: 57.81 Numer karty: 42512', '2025-05-15', 'seed-743d099482013bbc'
  FROM categories c WHERE c.name = 'prezenty'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 379.0, 'Tytuł: 000498849 74230785133167202257390  Lokalizacja: Adres: BROWAR POZNAN Miasto: POZNAN Kraj: POLSKA Data wykonania operacji: 2025-05-13 02:00 Oryginalna kwota operacji: 379.00 Numer karty: 425125*', '2025-05-15', 'seed-66e8325420e423e7'
  FROM categories c WHERE c.name = 'prezenty'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 22.0, 'Tytuł: 000498849 74230785133167213855794  Lokalizacja: Adres: SOUP CULTURE ROSWELL Miasto: POZNAN Kraj: POLSKA Data wykonania operacji: 2025-05-13 02:00 Oryginalna kwota operacji: 22.00 Numer karty: 4', '2025-05-15', 'seed-c00e015aa1b0bd88'
  FROM categories c WHERE c.name = 'restauracje'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 250.0, 'Tytuł: 010061097 74169505132611329784388  Lokalizacja: Adres: PRACOWNIA PSYCHOLOGICZNA Miasto: POZNAN Kraj: POLSKA Data wykonania operacji: 2025-05-12 02:00 Oryginalna kwota operacji: 250.00 Numer kar', '2025-05-14', 'seed-a71c7a4a9db33912'
  FROM categories c WHERE c.name = 'lekarz'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 17.98, 'Tytuł: 000498849 74230785132167156465297  Lokalizacja: Adres: ZABKA Z0685 K.1 Miasto: POZNAN Kraj: POLSKA Data wykonania operacji: 2025-05-12 02:00 Oryginalna kwota operacji: 17.98 Numer karty: 425125', '2025-05-14', 'seed-83676a7e164f5c90'
  FROM categories c WHERE c.name = 'żabka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 4.0, 'Nazwa odbiorcy: MOBILE-TRAFFIC-DATA SP. Z O. O. Adres odbiorcy: UL. DRUŻBICKIEGO 11 61-693 POZNAŃ Tytuł: ZAKUP BILETU KOMUNIKACYJNEGO W APLI KACJI IKO  Referencje własne zleceniodawcy: 175636058146 (4', '2025-05-13', 'seed-f9b8c475e3bedb82'
  FROM categories c WHERE c.name = 'przejazdy'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 99.9, 'Rachunek odbiorcy: 21 1020 4027 3011 0000 3014 3739 Nazwa odbiorcy: INEA SP. Z O.O.WYSOGOTOWO,UL.WIERZB OWA 8462-081 PRZEŹMIEROWO Tytuł: 92550/2025/05/IS/DS   Referencje własne zleceniodawcy: 17563581', '2025-05-13', 'seed-b748832c386f4c1f'
  FROM categories c WHERE c.name = 'mieszkanie'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 344.0, 'Tytuł: 00000088173044668   Numer telefonu: 48796555364 Lokalizacja: Adres: www.lightworks-studio.pl ''Operacja: 00000088173044668 Numer referencyjny: 00000088173044668 (344.00 PLN)', '2025-05-12', 'seed-c954eae70b3ce5fe'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 186.98, 'Tytuł: 00000088164126426   Numer telefonu: 48796555364 Lokalizacja: Adres: pyszne.pl ''Operacja: 00000088164126426 Numer referencyjny: 00000088164126426 (186.98 PLN)', '2025-05-12', 'seed-82fdc21af7208f76'
  FROM categories c WHERE c.name = 'restauracje'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 10.0, 'Tytuł: 00000088153096581   Numer telefonu: 48796555364 Lokalizacja: Adres: www.mobilet.pl ''Operacja: 00000088153096581 Numer referencyjny: 00000088153096581 (10.00 PLN)', '2025-05-12', 'seed-ae6f73ff397d75ac'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 19.9, 'Tytuł: 00000088150762721   Numer telefonu: 48796555364 Lokalizacja: Adres: www.nexto.pl ''Operacja: 00000088150762721 Numer referencyjny: 00000088150762721 (19.90 PLN)', '2025-05-12', 'seed-0ca78ca18fff6a8a'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 4.0, 'Nazwa odbiorcy: MOBILE-TRAFFIC-DATA SP. Z O. O. Adres odbiorcy: UL. DRUŻBICKIEGO 11 61-693 POZNAŃ Tytuł: ZAKUP BILETU KOMUNIKACYJNEGO W APLI KACJI IKO  Referencje własne zleceniodawcy: 175630636021 (4', '2025-05-12', 'seed-69e82e5df4219847'
  FROM categories c WHERE c.name = 'przejazdy'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 4.0, 'Nazwa odbiorcy: MOBILE-TRAFFIC-DATA SP. Z O. O. Adres odbiorcy: UL. DRUŻBICKIEGO 11 61-693 POZNAŃ Tytuł: ZAKUP BILETU KOMUNIKACYJNEGO W APLI KACJI IKO  Referencje własne zleceniodawcy: 175630276949 (4', '2025-05-12', 'seed-6d9d76a76c8a97ff'
  FROM categories c WHERE c.name = 'przejazdy'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 3.7, 'Tytuł: 000498849 74230785128166892072819  Lokalizacja: Adres: ZABKA Z0685 K.1 Miasto: POZNAN Kraj: POLSKA Data wykonania operacji: 2025-05-08 02:00 Oryginalna kwota operacji: 3.70 Numer karty: 425125*', '2025-05-10', 'seed-4f16e95526080f02'
  FROM categories c WHERE c.name = 'żabka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 168.58, 'Tytuł: 010082965 74987075129028645841595  Lokalizacja: Adres: Allegro Miasto: Poznan Kraj: POLSKA Data wykonania operacji: 2025-05-08 02:00 Oryginalna kwota operacji: 168.58 Numer karty: 425125******0', '2025-05-10', 'seed-e6251c758cf22bf0'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 800.0, 'Tytuł: 010085232 74350275128009764365216  Lokalizacja: Adres: Revolut**7108* Miasto: Dublin Kraj: IRLANDIA Data wykonania operacji: 2025-05-08 02:00 Oryginalna kwota operacji: 800.00 Numer karty: 4251', '2025-05-10', 'seed-34406a17b9170362'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 10.0, 'Tytuł: 00000088133698287   Numer telefonu: 48796555364 Lokalizacja: Adres: doladuj.plus.pl ''Operacja: 00000088133698287 Numer referencyjny: 00000088133698287 (10.00 PLN)', '2025-05-09', 'seed-3f12373ca7705a29'
  FROM categories c WHERE c.name = 'biuro'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 142.51, 'Tytuł: 000498849 74230785128166857646391  Lokalizacja: Adres: NETTO 5304 SCO K.3 Miasto: POZNAN Kraj: POLSKA Data wykonania operacji: 2025-05-07 02:00 Oryginalna kwota operacji: 142.51 Numer karty: 42', '2025-05-09', 'seed-7dfb11ce30215db7'
  FROM categories c WHERE c.name = 'biedronka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 4.5, 'Tytuł: 010061097 74169505127631279501357  Lokalizacja: Adres: FABRYKA FORMY POZNAN BALT Miasto: POZNAN Kraj: POLSKA Data wykonania operacji: 2025-05-07 02:00 Oryginalna kwota operacji: 4.50 Numer kart', '2025-05-09', 'seed-05329f65b0abe5e2'
  FROM categories c WHERE c.name = 'biedronka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 129.98, 'Tytuł: 010082965 74987075128028594033492  Lokalizacja: Adres: Allegro Miasto: Poznan Kraj: POLSKA Data wykonania operacji: 2025-05-07 02:00 Oryginalna kwota operacji: 129.98 Numer karty: 425125******0', '2025-05-09', 'seed-f8f5f57c51f4121e'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 27.86, 'Tytuł:  74988855126496354091826  Lokalizacja: Adres: JMP S.A. BIEDRONKA 3950 Miasto: POZNAN Kraj: POLSKA Data wykonania operacji: 2025-05-06 02:00 Oryginalna kwota operacji: 27.86 Numer karty: 425125*', '2025-05-08', 'seed-d6cf7866b6618860'
  FROM categories c WHERE c.name = 'biedronka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 148.39, 'Tytuł: 000498849 74230785126166722643732  Lokalizacja: Adres: NETTO 5304 SCO K.2 Miasto: POZNAN Kraj: POLSKA Data wykonania operacji: 2025-05-05 02:00 Oryginalna kwota operacji: 148.39 Numer karty: 42', '2025-05-07', 'seed-a6dd7da7fb2a5de9'
  FROM categories c WHERE c.name = 'biedronka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 250.0, 'Tytuł: 010061097 74169505125611254336583  Lokalizacja: Adres: PRACOWNIA PSYCHOLOGICZNA Miasto: POZNAN Kraj: POLSKA Data wykonania operacji: 2025-05-05 02:00 Oryginalna kwota operacji: 250.00 Numer kar', '2025-05-07', 'seed-437dc6889fc9dd5c'
  FROM categories c WHERE c.name = 'lekarz'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 31.49, 'Tytuł: 000498849 74230785124166630830209  Lokalizacja: Adres: ZABKA Z5606 K.2 Miasto: POZNAN Kraj: POLSKA Data wykonania operacji: 2025-05-04 02:00 Oryginalna kwota operacji: 31.49 Numer karty: 425125', '2025-05-06', 'seed-648899e7e89497bb'
  FROM categories c WHERE c.name = 'żabka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 4.0, 'Nazwa odbiorcy: MOBILE-TRAFFIC-DATA SP. Z O. O. Adres odbiorcy: UL. DRUŻBICKIEGO 11 61-693 POZNAŃ Tytuł: ZAKUP BILETU KOMUNIKACYJNEGO W APLI KACJI IKO  Referencje własne zleceniodawcy: 175602922590 (4', '2025-05-05', 'seed-22c9a97bae1661ee'
  FROM categories c WHERE c.name = 'przejazdy'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 4.0, 'Nazwa odbiorcy: MOBILE-TRAFFIC-DATA SP. Z O. O. Adres odbiorcy: UL. DRUŻBICKIEGO 11 61-693 POZNAŃ Tytuł: ZAKUP BILETU KOMUNIKACYJNEGO W APLI KACJI IKO  Referencje własne zleceniodawcy: 175602600545 (4', '2025-05-05', 'seed-8aeb37bd87443db4'
  FROM categories c WHERE c.name = 'przejazdy'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 1280.0, 'Rachunek odbiorcy: 73 1090 2372 0000 0001 1332 9442 Nazwa odbiorcy: MARTA SZCZYGIEŁ Tytuł: PRZELEW NA TELEFON  OD: 48796555364 DO: 486*****967 (1280.00 PLN)', '2025-05-05', 'seed-04cb13fb0fe7614c'
  FROM categories c WHERE c.name = 'mieszkanie'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 16.0, 'Tytuł: 000498849 74230785123166579895065  Lokalizacja: Adres: IMPOSYT Miasto: ZABKOWICE SLA Kraj: POLSKA Data wykonania operacji: 2025-05-03 02:00 Oryginalna kwota operacji: 16.00 Numer karty: 425125*', '2025-05-05', 'seed-511d3473ccb9f876'
  FROM categories c WHERE c.name = 'arval'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 57.02, 'Tytuł:  74838495124308055405404  Lokalizacja: Adres: ORLEN STACJA NR 539 Miasto: ZABKOWICE SLA Kraj: POLSKA Data wykonania operacji: 2025-05-03 02:00 Oryginalna kwota operacji: 57.02 Numer karty: 4251', '2025-05-05', 'seed-592c40c47327f9d3'
  FROM categories c WHERE c.name = 'paliwo'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 425.77, 'Tytuł: 010062941 74987505122002606394053  Lokalizacja: Adres: WConcept-ESW-IRL Miasto: Swords Kraj: IRLANDIA Data wykonania operacji: 2025-05-02 02:00 Oryginalna kwota operacji: 425.77 Numer karty: 42', '2025-05-04', 'seed-956435aef061905e'
  FROM categories c WHERE c.name = 'prezenty'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 63.28, 'Tytuł: 010059127 74062945122126411487103  Lokalizacja: Adres: Polski Koncern Naftowy OR Miasto: Plock Kraj: POLSKA Data wykonania operacji: 2025-05-02 02:00 Oryginalna kwota operacji: 63.28 Numer kart', '2025-05-04', 'seed-aef85aa45e946957'
  FROM categories c WHERE c.name = 'arval'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 287.0, 'Tytuł: 000498849 74230785123166568116366  Lokalizacja: Adres: SYNEVO PUNKT POBRAN Miasto: ZABKOWICE SLA Kraj: POLSKA Data wykonania operacji: 2025-05-02 02:00 Oryginalna kwota operacji: 287.00 Numer k', '2025-05-04', 'seed-9c1c56fbda7d1797'
  FROM categories c WHERE c.name = 'lekarz'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 46.09, 'Tytuł: 010072805 24871155121088867672302  Lokalizacja: Adres: ALIEXPRESS.COM Miasto: Luxembourg Kraj: LUKSEMBURG Data wykonania operacji: 2025-05-01 02:00 Oryginalna kwota operacji: 46.09 Numer karty:', '2025-05-03', 'seed-d28d9ecf0956df2e'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 150.48, 'Tytuł:  74838495120307683803398  Lokalizacja: Adres: ZIKO APTEKA 05 Miasto: Poznan Kraj: POLSKA Data wykonania operacji: 2025-04-30 02:00 Oryginalna kwota operacji: 150.48 Numer karty: 425125******026', '2025-05-02', 'seed-1e045e080cca6ea6'
  FROM categories c WHERE c.name = 'apteka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 4.5, 'Tytuł: 000498849 74230785120166408698048  Lokalizacja: Adres: ZABKA Z0685 K.1 Miasto: POZNAN Kraj: POLSKA Data wykonania operacji: 2025-04-30 02:00 Oryginalna kwota operacji: 4.50 Numer karty: 425125*', '2025-05-02', 'seed-8bc5fee2a3a203c6'
  FROM categories c WHERE c.name = 'żabka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 3.47, 'Tytuł:  74838495121307743685834  Lokalizacja: Adres: ORLEN STACJA NR 600 Miasto: POZNAN Kraj: POLSKA Data wykonania operacji: 2025-04-30 02:00 Oryginalna kwota operacji: 3.47 Numer karty: 425125******', '2025-05-02', 'seed-482e98388cc1da7e'
  FROM categories c WHERE c.name = 'arval'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 429.28, 'Tytuł: 010075642 74987505120003642769037  Lokalizacja: Adres: aliexpress Miasto: Luxembourg Kraj: LUKSEMBURG Data wykonania operacji: 2025-04-30 02:00 Oryginalna kwota operacji: 429.28 Numer karty: 42', '2025-05-02', 'seed-51889ff3c8f3b1a5'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 25.98, 'Tytuł:  74838495120307536229635  Lokalizacja: Adres: PL KFC MOP MORZECINO S5 Miasto: MORZECINO Kraj: POLSKA Data wykonania operacji: 2025-04-29 02:00 Oryginalna kwota operacji: 25.98 Numer karty: 4251', '2025-05-02', 'seed-907248c7dabfdb59'
  FROM categories c WHERE c.name = 'restauracje'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 2.0, 'Tytuł: 010061097 74463675120581203067887  Lokalizacja: Adres: MYJNIA ADEX Miasto: RYBNIK Kraj: POLSKA Data wykonania operacji: 2025-04-29 02:00 Oryginalna kwota operacji: 2.00 Numer karty: 425125*****', '2025-05-02', 'seed-836a62e7f2bf9ec3'
  FROM categories c WHERE c.name = 'arval'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 2.0, 'Tytuł: 010061097 74463675120581203067937  Lokalizacja: Adres: MYJNIA ADEX Miasto: RYBNIK Kraj: POLSKA Data wykonania operacji: 2025-04-29 02:00 Oryginalna kwota operacji: 2.00 Numer karty: 425125*****', '2025-05-02', 'seed-073ceb505446f170'
  FROM categories c WHERE c.name = 'arval'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 5.0, 'Tytuł: 010061097 74463675120581203067796  Lokalizacja: Adres: MYJNIA ADEX Miasto: RYBNIK Kraj: POLSKA Data wykonania operacji: 2025-04-29 02:00 Oryginalna kwota operacji: 5.00 Numer karty: 425125*****', '2025-05-02', 'seed-85322214c5ffeed0'
  FROM categories c WHERE c.name = 'arval'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 5.0, 'Tytuł: 010061097 74463675120581203067838  Lokalizacja: Adres: MYJNIA ADEX Miasto: RYBNIK Kraj: POLSKA Data wykonania operacji: 2025-04-29 02:00 Oryginalna kwota operacji: 5.00 Numer karty: 425125*****', '2025-05-02', 'seed-cdc20a21ae4b232b'
  FROM categories c WHERE c.name = 'arval'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 363.0, 'Rachunek odbiorcy: 21 1940 1076 6256 6800 0000 0000 Nazwa odbiorcy: ADAM TYŻYK Tytuł: 12 MP/05/2025   Referencje własne zleceniodawcy: 175594086613 (363.00 PLN)', '2025-05-02', 'seed-25944e4e20372e06'
  FROM categories c WHERE c.name = 'mieszkanie'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 65.15, 'Tytuł:  74988855119496418080764  Lokalizacja: Adres: JMP S.A. BIEDRONKA 3352 Miasto: KUZNIA RACIBO Kraj: POLSKA Data wykonania operacji: 2025-04-29 02:00 Oryginalna kwota operacji: 65.15 Numer karty: ', '2025-05-01', 'seed-ed308169c0af83e7'
  FROM categories c WHERE c.name = 'biedronka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 278.99, 'Tytuł: 010046551 74796055119057003008369  Lokalizacja: Adres: KELLER SP Z O.O.- SALON H Miasto: GLIWICE Kraj: POLSKA Data wykonania operacji: 2025-04-29 02:00 Oryginalna kwota operacji: 278.99 Numer k', '2025-05-01', 'seed-8daf4d1e54f13f71'
  FROM categories c WHERE c.name = 'arval'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 500.0, 'Tytuł: 010085232 74350275119009647165909  Lokalizacja: Adres: Revolut**7108* Miasto: Dublin Kraj: IRLANDIA Data wykonania operacji: 2025-04-29 02:00 Oryginalna kwota operacji: 500.00 Numer karty: 4251', '2025-05-01', 'seed-f81afeeeec6b545e'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 202.13, 'SHELL 11  Wroclaw  POL   Płatność kartą 31.05.2025 Nr karty 4598xx4778', '2025-05-31', 'seed-86b4f8a15114c4c6'
  FROM categories c WHERE c.name = 'paliwo'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 203.99, 'SHELL 11  Wroclaw  POL   Płatność kartą 29.05.2025 Nr karty 4598xx4778', '2025-05-29', 'seed-a43aebc5d99b4d92'
  FROM categories c WHERE c.name = 'paliwo'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 142.38, 'ORLEN STACJA NR 539  ZABKOWICE SLA   Płatność kartą 25.05.2025 Nr karty 4598xx4778', '2025-05-25', 'seed-1048b02e6751fc84'
  FROM categories c WHERE c.name = 'paliwo'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 197.8, 'ORLEN STACJA NR 600  POZNAN  POL   Płatność kartą 23.05.2025 Nr karty 4598xx4778', '2025-05-23', 'seed-fc7ca6ebf4a9a302'
  FROM categories c WHERE c.name = 'paliwo'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 2444.0, 'Urząd Skarbowy Centrum Rozliczeniowe   /TI/N6392015837/OKR/25M04/SFP/PPE', '2025-05-20', 'seed-be69ae0a3a677a2a'
  FROM categories c WHERE c.name = 'pit36'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 3373.0, 'Urząd Skarbowy Centrum Rozliczeniowe   /TI/N6392015837/OKR/25M04/SFP/VAT7', '2025-05-20', 'seed-b206b4bc649ac2bc'
  FROM categories c WHERE c.name = 'vat'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 12.0, 'Urząd Skarbowy Centrum Rozliczeniowe   /TI/N6392015837/OKR/25M04/SFP/PIT4R', '2025-05-14', 'seed-d83509f24a8be343'
  FROM categories c WHERE c.name = 'pit36'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 3213.27, 'Zakład Ubezpieczeń Społecznych 47-400 Racibórz   Ubezpieczenie zdrowotne 04.2025', '2025-05-14', 'seed-834fa436781e951b'
  FROM categories c WHERE c.name = 'zus'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 82.29, 'Orange Polska S.A. Aleje Jerozolimskie 160 02-326 Warszawa NIP 526-025-09-95   F0083222849/005/25', '2025-05-07', 'seed-1f69d2e5b8ffff70'
  FROM categories c WHERE c.name = 'biuro'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 258.92, 'P4 Sp. z o.o. ul. Wynalazek 1 02-677 Warszawa   F/10029779/05/25', '2025-05-07', 'seed-10dc98258ce161ea'
  FROM categories c WHERE c.name = 'biuro'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 2326.74, 'BNP Paribas Leasing Services Sp. z o.o. 00-844 Warszawa, ul.Grzybowska 78   28919/05/2025/RL/LS', '2025-05-07', 'seed-835bdd2f1c10f4e8'
  FROM categories c WHERE c.name = 'arval'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 124.01, 'ORLEN STACJA NR 539  ZABKOWICE SLA   Płatność kartą 03.05.2025 Nr karty 4598xx4778', '2025-05-03', 'seed-4d3c166e151b757e'
  FROM categories c WHERE c.name = 'paliwo'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 381.87, 'KANCELARIA PODATKOWO-GOSPODARCZA SP ÓŁKA Z OGRANICZONĄ ODPOWIEDZIALNOŚC IĄ ul. Radomska 7 44-164 Gliwice NI P: PL 631-264-51-93   FA/64/04/2025', '2025-05-02', 'seed-e2d4a387a381f17f'
  FROM categories c WHERE c.name = 'biuro'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 4.5, 'Tytuł: 000498849 74230785118166262470975  Lokalizacja: Adres: ZABKA Z0685 K.1 Miasto: POZNAN Kraj: POLSKA Data wykonania operacji: 2025-04-28 02:00 Oryginalna kwota operacji: 4.50 Numer karty: 425125*', '2025-04-30', 'seed-bacf0583ac7dc6d4'
  FROM categories c WHERE c.name = 'żabka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 200.0, 'Tytuł: 010061097 74169505118611188209301  Lokalizacja: Adres: PRACOWNIA PSYCHOLOGICZNA Miasto: POZNAN Kraj: POLSKA Data wykonania operacji: 2025-04-28 02:00 Oryginalna kwota operacji: 200.00 Numer kar', '2025-04-30', 'seed-f7e60ee90f5722f3'
  FROM categories c WHERE c.name = 'lekarz'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 174.0, 'Tytuł: 000498707 74987075119028304558029  Lokalizacja: Adres: coffeedesk.pl Miasto: Kolobrzeg Kraj: POLSKA Data wykonania operacji: 2025-04-28 02:00 Oryginalna kwota operacji: 174.00 Numer karty: 4251', '2025-04-30', 'seed-659b364afb894177'
  FROM categories c WHERE c.name = 'kawa'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 2000.0, 'Rachunek odbiorcy: 63 1020 1068 1230 7223 1295 0585 Nazwa odbiorcy: PKO BIURO MAKLERSKIE Tytuł: ZAKUP OBLIGACJI (2000.00 PLN)', '2025-04-30', 'seed-b53c822a21dea9b6'
  FROM categories c WHERE c.name = 'inwestycje'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 3000.0, 'Rachunek odbiorcy: 63 1020 1068 1230 7223 1295 0585 Nazwa odbiorcy: PKO BIURO MAKLERSKIE Tytuł: ZAKUP OBLIGACJI (3000.00 PLN)', '2025-04-30', 'seed-6c6a7fc157c50ee4'
  FROM categories c WHERE c.name = 'inwestycje'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 13.69, 'Tytuł: 000498849 74230785116166149468475  Lokalizacja: Adres: ZABKA Z0685 K.1 Miasto: POZNAN Kraj: POLSKA Data wykonania operacji: 2025-04-26 02:00 Oryginalna kwota operacji: 13.69 Numer karty: 425125', '2025-04-28', 'seed-7e8007f99ed60872'
  FROM categories c WHERE c.name = 'żabka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 21.5, 'Tytuł:  74810315116155465692416  Lokalizacja: Adres: POLEWSKI CONCEPT Miasto: Poznan Kraj: POLSKA Data wykonania operacji: 2025-04-26 02:00 Oryginalna kwota operacji: 21.50 Numer karty: 425125******02', '2025-04-28', 'seed-36c5322bc2f4c089'
  FROM categories c WHERE c.name = 'biedronka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 19.98, 'Tytuł: 000498849 74230785116166149470190  Lokalizacja: Adres: ZABKA Z0685 K.1 Miasto: POZNAN Kraj: POLSKA Data wykonania operacji: 2025-04-26 02:00 Oryginalna kwota operacji: 19.98 Numer karty: 425125', '2025-04-28', 'seed-d727de2fa6c3b82d'
  FROM categories c WHERE c.name = 'żabka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 16.0, 'Tytuł:  74410495116024514321829  Lokalizacja: Adres: CYNAMONKI        65461 Miasto: Poznan Kraj: POLSKA Data wykonania operacji: 2025-04-26 02:00 Oryginalna kwota operacji: 16.00 Numer karty: 425125**', '2025-04-28', 'seed-f021990aa6f0472f'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 321.18, 'Tytuł:  74838495117307044259970  Lokalizacja: Adres: LIDL 1884 Miasto: POZNAN Kraj: POLSKA Data wykonania operacji: 2025-04-26 02:00 Oryginalna kwota operacji: 321.18 Numer karty: 425125******0264 (32', '2025-04-28', 'seed-c4b3cef4503f2b4e'
  FROM categories c WHERE c.name = 'arval'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 4.0, 'Nazwa odbiorcy: MOBILE-TRAFFIC-DATA SP. Z O. O. Adres odbiorcy: UL. DRUŻBICKIEGO 11 61-693 POZNAŃ Tytuł: ZAKUP BILETU KOMUNIKACYJNEGO W APLI KACJI IKO  Referencje własne zleceniodawcy: 175581154366 (4', '2025-04-28', 'seed-3464639bded881cf'
  FROM categories c WHERE c.name = 'przejazdy'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 4.0, 'Nazwa odbiorcy: MOBILE-TRAFFIC-DATA SP. Z O. O. Adres odbiorcy: UL. DRUŻBICKIEGO 11 61-693 POZNAŃ Tytuł: ZAKUP BILETU KOMUNIKACYJNEGO W APLI KACJI IKO  Referencje własne zleceniodawcy: 175580901066 (4', '2025-04-28', 'seed-63fab0a26f02f845'
  FROM categories c WHERE c.name = 'przejazdy'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 678.0, 'Tytuł:  74838495116306838039052  Lokalizacja: Adres: DOBRE OKO OKULISTA MARI Miasto: POZNAN Kraj: POLSKA Data wykonania operacji: 2025-04-25 02:00 Oryginalna kwota operacji: 678.00 Numer karty: 425125', '2025-04-27', 'seed-7409d4705ccd5f20'
  FROM categories c WHERE c.name = 'arval'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 159.0, 'Rachunek odbiorcy: 73 1090 2372 0000 0001 1332 9442 Nazwa odbiorcy: MARTA SZCZYGIEŁ Tytuł: PRZELEW NA TELEFON  OD: 48796555364 DO: 486*****967 (159.00 PLN)', '2025-04-26', 'seed-470678d28072d520'
  FROM categories c WHERE c.name = 'mieszkanie'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 36.74, 'Tytuł: 000498849 74230785115166037282831  Lokalizacja: Adres: NETTO 5304 SCO K.3 Miasto: POZNAN Kraj: POLSKA Data wykonania operacji: 2025-04-24 02:00 Oryginalna kwota operacji: 36.74 Numer karty: 425', '2025-04-26', 'seed-89974245f2cbe942'
  FROM categories c WHERE c.name = 'biedronka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 4.5, 'Tytuł: 000498849 74230785113165933886523  Lokalizacja: Adres: ZABKA Z0685 K.1 Miasto: POZNAN Kraj: POLSKA Data wykonania operacji: 2025-04-23 02:00 Oryginalna kwota operacji: 4.50 Numer karty: 425125*', '2025-04-25', 'seed-2ea7cb18f5c758f4'
  FROM categories c WHERE c.name = 'żabka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 7.49, 'Tytuł: 000498849 74230785113165933886689  Lokalizacja: Adres: ZABKA Z0685 K.1 Miasto: POZNAN Kraj: POLSKA Data wykonania operacji: 2025-04-23 02:00 Oryginalna kwota operacji: 7.49 Numer karty: 425125*', '2025-04-25', 'seed-cc073fa109660da2'
  FROM categories c WHERE c.name = 'żabka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 52.6, 'Tytuł: 00000087839695246   Numer telefonu: 48796555364 Lokalizacja: Adres: pyszne.pl ''Operacja: 00000087839695246 Numer referencyjny: 00000087839695246 (52.60 PLN)', '2025-04-24', 'seed-84582fbae33cf191'
  FROM categories c WHERE c.name = 'restauracje'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 4.5, 'Tytuł: 000498849 74230785113165892792001  Lokalizacja: Adres: ZABKA Z1521 K.2 Miasto: POZNAN Kraj: POLSKA Data wykonania operacji: 2025-04-22 02:00 Oryginalna kwota operacji: 4.50 Numer karty: 425125*', '2025-04-24', 'seed-65ff8836f8066bed'
  FROM categories c WHERE c.name = 'żabka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 77.96, 'Tytuł: 000498849 74230785113165904068101  Lokalizacja: Adres: NETTO 5304 SCO K.3 Miasto: POZNAN Kraj: POLSKA Data wykonania operacji: 2025-04-22 02:00 Oryginalna kwota operacji: 77.96 Numer karty: 425', '2025-04-24', 'seed-793bee2fd0ebffc2'
  FROM categories c WHERE c.name = 'biedronka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 500.0, 'Tytuł: 010085232 74350275112009550191816  Lokalizacja: Adres: Revolut**7108* Miasto: Dublin Kraj: IRLANDIA Data wykonania operacji: 2025-04-22 02:00 Oryginalna kwota operacji: 500.00 Numer karty: 4251', '2025-04-24', 'seed-d0df3cd26689ea42'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 170.0, 'Tytuł: 000498849 74230785112165860800365  Lokalizacja: Adres: EURO PRALNIE Miasto: POZNAN Kraj: POLSKA Data wykonania operacji: 2025-04-22 02:00 Oryginalna kwota operacji: 170.00 Numer karty: 425125**', '2025-04-24', 'seed-381bef510bef9b91'
  FROM categories c WHERE c.name = 'ubrania'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 69.39, 'Tytuł: 010075642 74987505111003659636096  Lokalizacja: Adres: aliexpress Miasto: Luxembourg Kraj: LUKSEMBURG Data wykonania operacji: 2025-04-21 02:00 Oryginalna kwota operacji: 69.39 Numer karty: 425', '2025-04-23', 'seed-b46c8e6ac270603b'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 4.37, 'Tytuł:  74838495112306247977516  Lokalizacja: Adres: ORLEN STACJA NR 539 Miasto: ZABKOWICE SLA Kraj: POLSKA Data wykonania operacji: 2025-04-21 02:00 Oryginalna kwota operacji: 4.37 Numer karty: 42512', '2025-04-23', 'seed-fad205c9fa84e9e3'
  FROM categories c WHERE c.name = 'arval'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 4.0, 'Tytuł:  74810315109154927154635  Lokalizacja: Adres: MYJNIA HENRYK DLUGOSZ Miasto: Kuznia Racibo Kraj: POLSKA Data wykonania operacji: 2025-04-19 02:00 Oryginalna kwota operacji: 4.00 Numer karty: 425', '2025-04-21', 'seed-ea67f3d8d906024e'
  FROM categories c WHERE c.name = 'arval'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 4.0, 'Tytuł:  74810315109154928642349  Lokalizacja: Adres: MYJNIA HENRYK DLUGOSZ Miasto: Kuznia Racibo Kraj: POLSKA Data wykonania operacji: 2025-04-19 02:00 Oryginalna kwota operacji: 4.00 Numer karty: 425', '2025-04-21', 'seed-de79b68c6314b415'
  FROM categories c WHERE c.name = 'arval'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 240.58, 'Tytuł:  74988855109496240040392  Lokalizacja: Adres: JMP S.A. BIEDRONKA 3352 Miasto: KUZNIA RACIBO Kraj: POLSKA Data wykonania operacji: 2025-04-19 02:00 Oryginalna kwota operacji: 240.58 Numer karty:', '2025-04-21', 'seed-e3c1341e6e22b7c7'
  FROM categories c WHERE c.name = 'biedronka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 4.0, 'Tytuł:  74810315109154929184259  Lokalizacja: Adres: MYJNIA HENRYK DLUGOSZ Miasto: Kuznia Racibo Kraj: POLSKA Data wykonania operacji: 2025-04-19 02:00 Oryginalna kwota operacji: 4.00 Numer karty: 425', '2025-04-21', 'seed-5b72ab07b3656b11'
  FROM categories c WHERE c.name = 'arval'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 6.0, 'Tytuł:  74810315109154927801946  Lokalizacja: Adres: MYJNIA HENRYK DLUGOSZ Miasto: Kuznia Racibo Kraj: POLSKA Data wykonania operacji: 2025-04-19 02:00 Oryginalna kwota operacji: 6.00 Numer karty: 425', '2025-04-21', 'seed-0aacf4b9543a89b0'
  FROM categories c WHERE c.name = 'arval'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 97.0, 'Tytuł: 010061097 74169505108651082891251  Lokalizacja: Adres: MANGO MAMA NADODRZE Miasto: WROCLAW Kraj: POLSKA Data wykonania operacji: 2025-04-18 02:00 Oryginalna kwota operacji: 97.00 Numer karty: 4', '2025-04-20', 'seed-92b93d84cb1f6355'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 9.0, 'Tytuł: 000498849 74230785107165601111723  Lokalizacja: Adres: ZABKA Z0685 K.1 Miasto: POZNAN Kraj: POLSKA Data wykonania operacji: 2025-04-17 02:00 Oryginalna kwota operacji: 9.00 Numer karty: 425125*', '2025-04-19', 'seed-acba720ba15ca860'
  FROM categories c WHERE c.name = 'żabka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 5.0, 'Tytuł: 000498849 74230785107165601099779  Lokalizacja: Adres: ZABKA Z0685 K.1 Miasto: POZNAN Kraj: POLSKA Data wykonania operacji: 2025-04-17 02:00 Oryginalna kwota operacji: 5.00 Numer karty: 425125*', '2025-04-19', 'seed-7b6973341f46275a'
  FROM categories c WHERE c.name = 'żabka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 6.2, 'Tytuł: 000498849 74230785107165614828529  Lokalizacja: Adres: ZABKA Z1048 K.2 Miasto: POZNAN Kraj: POLSKA Data wykonania operacji: 2025-04-17 02:00 Oryginalna kwota operacji: 6.20 Numer karty: 425125*', '2025-04-19', 'seed-98433abc8f9f2cd6'
  FROM categories c WHERE c.name = 'żabka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 16.99, 'Tytuł: 010071549 74985435107800178100589  Lokalizacja: Adres: PP*INPOST.PL Miasto: KRAKOW Kraj: POLSKA Data wykonania operacji: 2025-04-17 02:00 Oryginalna kwota operacji: 16.99 Numer karty: 425125***', '2025-04-19', 'seed-049d35b3cc1e31fc'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 18.99, 'Tytuł: 010071549 74985435107800178098411  Lokalizacja: Adres: PP*INPOST.PL Miasto: KRAKOW Kraj: POLSKA Data wykonania operacji: 2025-04-17 02:00 Oryginalna kwota operacji: 18.99 Numer karty: 425125***', '2025-04-19', 'seed-4b9bedddc3696c38'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 30.0, 'Tytuł: 00000087717507867   Numer telefonu: 48796555364 Lokalizacja: Adres: doladuj.plus.pl ''Operacja: 00000087717507867 Numer referencyjny: 00000087717507867 (30.00 PLN)', '2025-04-18', 'seed-dac6db2ad71df20e'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 12.0, 'Tytuł:  74838495106305543647573  Lokalizacja: Adres: Paczek w masle Miasto: Poznan Kraj: POLSKA Data wykonania operacji: 2025-04-16 02:00 Oryginalna kwota operacji: 12.00 Numer karty: 425125******0264', '2025-04-18', 'seed-c1d1f204a5f8b370'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 14.99, 'Tytuł: 010066928 74056285106108518929251  Lokalizacja: Adres: APPLE.COM/BILL Miasto: APPLE.COM/BIL Kraj: IRLANDIA Data wykonania operacji: 2025-04-16 02:00 Oryginalna kwota operacji: 14.99 Numer karty', '2025-04-18', 'seed-8f4ed4d75659ef45'
  FROM categories c WHERE c.name = 'biuro'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 52.94, 'Tytuł: 000498849 74230785107165553336575  Lokalizacja: Adres: NETTO 5304 SCO K.2 Miasto: POZNAN Kraj: POLSKA Data wykonania operacji: 2025-04-16 02:00 Oryginalna kwota operacji: 52.94 Numer karty: 425', '2025-04-18', 'seed-918fafb73a32756d'
  FROM categories c WHERE c.name = 'biedronka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 50.56, 'Tytuł: 000498849 74230785106165471158094  Lokalizacja: Adres: NETTO 5304 SCO K.3 Miasto: POZNAN Kraj: POLSKA Data wykonania operacji: 2025-04-15 02:00 Oryginalna kwota operacji: 50.56 Numer karty: 425', '2025-04-17', 'seed-4a178d5fe81e69d3'
  FROM categories c WHERE c.name = 'biedronka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 75.0, 'Tytuł: 010079750 74346355105107163861662  Lokalizacja: Adres: Amazon.pl*RH2XI9H24 Miasto: AMAZON.PL Kraj: LUKSEMBURG Data wykonania operacji: 2025-04-15 02:00 Oryginalna kwota operacji: 75.00 Numer ka', '2025-04-17', 'seed-12a68541dd394082'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 700.0, 'Tytuł:  74838495105305345506366  Lokalizacja: Adres: Optyka Okularowa- Kryst Miasto: Poznan Kraj: POLSKA Data wykonania operacji: 2025-04-15 02:00 Oryginalna kwota operacji: 700.00 Numer karty: 425125', '2025-04-17', 'seed-58c753565d4cf882'
  FROM categories c WHERE c.name = 'lekarz'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 200.0, 'Tytuł: PKO BP 10204027S1PO2028N6625C9387  Lokalizacja: Adres: UL. ROOSEVELTA 11 Miasto: POZNAN Kraj: POLSKA Data wykonania operacji: 2025-04-16 02:00 Oryginalna kwota operacji: 200.00 Numer karty: 425', '2025-04-17', 'seed-846c74c6619e41ed'
  FROM categories c WHERE c.name = 'arval'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 600.0, 'Rachunek odbiorcy: 25 1050 1520 1000 0090 8295 7284 Nazwa odbiorcy: KAROLINA JANUSZEWSKA NOWA FORMA Tytuł: PAKIET 4 TRENINGÓW OLAF KRAWCZYK   Referencje własne zleceniodawcy: 175545191709 (600.00 PLN)', '2025-04-16', 'seed-297212804069d2db'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 9.64, 'Tytuł: 000498849 74230785105165399542883  Lokalizacja: Adres: NETTO 5304 K.1 Miasto: POZNAN Kraj: POLSKA Data wykonania operacji: 2025-04-14 02:00 Oryginalna kwota operacji: 9.64 Numer karty: 425125**', '2025-04-16', 'seed-188ae78018b0dd39'
  FROM categories c WHERE c.name = 'biedronka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 5.0, 'Tytuł: 010061097 74463675104561041756073  Lokalizacja: Adres: BANIECZKA SPOLKA AKCYJNA Miasto: POZNAN Kraj: POLSKA Data wykonania operacji: 2025-04-13 02:00 Oryginalna kwota operacji: 5.00 Numer karty', '2025-04-16', 'seed-ae449f42c773b585'
  FROM categories c WHERE c.name = 'arval'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 2.0, 'Tytuł: 010061097 74463675104561041755786  Lokalizacja: Adres: BANIECZKA SPOLKA AKCYJNA Miasto: POZNAN Kraj: POLSKA Data wykonania operacji: 2025-04-13 02:00 Oryginalna kwota operacji: 2.00 Numer karty', '2025-04-16', 'seed-c2ff3dc9c2848f86'
  FROM categories c WHERE c.name = 'arval'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 5.0, 'Tytuł: 010061097 74463675104561041755943  Lokalizacja: Adres: BANIECZKA SPOLKA AKCYJNA Miasto: POZNAN Kraj: POLSKA Data wykonania operacji: 2025-04-13 02:00 Oryginalna kwota operacji: 5.00 Numer karty', '2025-04-16', 'seed-0f4fe09c6ebd8def'
  FROM categories c WHERE c.name = 'arval'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 2.0, 'Tytuł: 010061097 74463675104561041756040  Lokalizacja: Adres: BANIECZKA SPOLKA AKCYJNA Miasto: POZNAN Kraj: POLSKA Data wykonania operacji: 2025-04-13 02:00 Oryginalna kwota operacji: 2.00 Numer karty', '2025-04-16', 'seed-4420cd3693196997'
  FROM categories c WHERE c.name = 'arval'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 18.97, 'Tytuł:  74838495104305109990377  Lokalizacja: Adres: SKLEP LIDL 1221 WROCLAW Miasto: WROCLAW Kraj: POLSKA Data wykonania operacji: 2025-04-13 02:00 Oryginalna kwota operacji: 18.97 Numer karty: 425125', '2025-04-15', 'seed-3084980b95ca4652'
  FROM categories c WHERE c.name = 'biedronka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 20.0, 'Tytuł: 000498849 74230785103165300258548  Lokalizacja: Adres: ZABKA Z3596 K.1 Miasto: WROCLAW Kraj: POLSKA Data wykonania operacji: 2025-04-13 02:00 Oryginalna kwota operacji: 20.00 Numer karty: 42512', '2025-04-15', 'seed-71b07c186f8a26cf'
  FROM categories c WHERE c.name = 'żabka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 16.99, 'Tytuł: 000498849 74230785103165301947412  Lokalizacja: Adres: ZABKA Z0685 K.1 Miasto: POZNAN Kraj: POLSKA Data wykonania operacji: 2025-04-13 02:00 Oryginalna kwota operacji: 16.99 Numer karty: 425125', '2025-04-15', 'seed-6cb9d56696a14ed5'
  FROM categories c WHERE c.name = 'żabka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 183.74, 'Tytuł: 000498849 74230785104165329386121  Lokalizacja: Adres: NETTO 5304 SCO K.3 Miasto: POZNAN Kraj: POLSKA Data wykonania operacji: 2025-04-13 02:00 Oryginalna kwota operacji: 183.74 Numer karty: 42', '2025-04-15', 'seed-dfa5e480379689b1'
  FROM categories c WHERE c.name = 'biedronka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 24.0, 'Tytuł: 010059127 74043215103124466707363  Lokalizacja: Adres: NFM APM Miasto: Wroclaw Kraj: POLSKA Data wykonania operacji: 2025-04-13 02:00 Oryginalna kwota operacji: 24.00 Numer karty: 425125******0', '2025-04-15', 'seed-5a770d6f2fc882f9'
  FROM categories c WHERE c.name = 'arval'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 206.36, 'Rachunek odbiorcy: 91 1020 0029 9000 2023 2777 2284 Nazwa odbiorcy: OLAF KRAWCZYK Tytuł: SPŁATA AKTUALNEGO ZADŁUŻENIA KARTY KREDYTOWEJ * 8853 OD: 48796555364 Referencje własne zleceniodawcy: 175540820', '2025-04-15', 'seed-e2545ceed8a87d53'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 190.2, 'Tytuł: 00000087590091047   Numer telefonu: 48796555364 Lokalizacja: Adres: intercity.pl ''Operacja: 00000087590091047 Numer referencyjny: 00000087590091047 (190.20 PLN)', '2025-04-14', 'seed-85f6f2f5588999bb'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 500.0, 'Tytuł: 010085232 74350275101009414306462  Lokalizacja: Adres: Revolut**7108* Miasto: Dublin Kraj: IRLANDIA Data wykonania operacji: 2025-04-11 02:00 Oryginalna kwota operacji: 500.00 Numer karty: 4251', '2025-04-13', 'seed-f9c05b9a256a2ed6'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 500.0, 'Tytuł: 010085232 74350275098009375430868  Lokalizacja: Adres: Revolut**7108* Miasto: Dublin Kraj: IRLANDIA Data wykonania operacji: 2025-04-08 02:00 Oryginalna kwota operacji: 500.00 Numer karty: 4251', '2025-04-10', 'seed-ecb0cb3f8e78bd1d'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 99.9, 'Rachunek odbiorcy: 21 1020 4027 3011 0000 3014 3739 Nazwa odbiorcy: INEA SP. Z O.O.WYSOGOTOWO,UL.WIERZB OWA 8462-081 PRZEŹMIEROWO Tytuł: 93998/2025/04/IS/DS   Referencje własne zleceniodawcy: 17552186', '2025-04-10', 'seed-58feb22d52f798d9'
  FROM categories c WHERE c.name = 'mieszkanie'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 1000.0, 'Tytuł: 010085232 74350275097009359713090  Lokalizacja: Adres: Revolut**7108* Miasto: Dublin Kraj: IRLANDIA Data wykonania operacji: 2025-04-07 02:00 Oryginalna kwota operacji: 1000.00 Numer karty: 425', '2025-04-08', 'seed-9ce15846a35c3093'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 1280.0, 'Rachunek odbiorcy: 73 1090 2372 0000 0001 1332 9442 Nazwa odbiorcy: MARTA SZCZYGIEŁ Tytuł: PRZELEW NA TELEFON  OD: 48796555364 DO: 486*****967 (1280.00 PLN)', '2025-04-07', 'seed-c1b1c26fb84db2bf'
  FROM categories c WHERE c.name = 'mieszkanie'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 1000.0, 'Tytuł: 010085232 74350275093009320227364  Lokalizacja: Adres: Revolut**7108* Miasto: Dublin Kraj: IRLANDIA Data wykonania operacji: 2025-04-03 02:00 Oryginalna kwota operacji: 1000.00 Numer karty: 425', '2025-04-05', 'seed-b1e2890459fa7733'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 193.5, 'Tytuł: 010079724 24396965093000243709957  Lokalizacja: Adres: Cyfrowe Sp z oo Miasto: gdansk Kraj: POLSKA Data wykonania operacji: 2025-04-03 02:00 Oryginalna kwota operacji: 193.50 Numer karty: 42512', '2025-04-05', 'seed-37d4ad6b1a505cfd'
  FROM categories c WHERE c.name = 'arval'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 1000.0, 'Tytuł: 010085232 74350275092009297982075  Lokalizacja: Adres: Revolut**7108* Miasto: Dublin Kraj: IRLANDIA Data wykonania operacji: 2025-04-02 02:00 Oryginalna kwota operacji: 1000.00 Numer karty: 425', '2025-04-04', 'seed-8d768ba1f0abd4d1'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 500.0, 'Tytuł: 010085232 74350275090009270438501  Lokalizacja: Adres: Revolut**7108* Miasto: Dublin Kraj: IRLANDIA Data wykonania operacji: 2025-03-31 02:00 Oryginalna kwota operacji: 500.00 Numer karty: 4251', '2025-04-02', 'seed-9172dc4fede0f2a6'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 34.99, 'Tytuł: 010066928 74056285090103833225699  Lokalizacja: Adres: APPLE.COM/BILL Miasto: APPLE.COM/BIL Kraj: IRLANDIA Data wykonania operacji: 2025-03-31 02:00 Oryginalna kwota operacji: 34.99 Numer karty', '2025-04-02', 'seed-8fa50ddc1bc3d56e'
  FROM categories c WHERE c.name = 'biuro'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 27.02, 'Tytuł:  74980005090558801272713  Lokalizacja: Adres: MOBILE SUICA APPLE V Miasto: TOKYO Kraj: JAPONIA Data wykonania operacji: 2025-03-29 01:00 Oryginalna kwota operacji: 1000.00 Data przetworzenia: 2', '2025-04-02', 'seed-984d7a721f8158ed'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 363.0, 'Rachunek odbiorcy: 21 1940 1076 6256 6800 0000 0000 Nazwa odbiorcy: ADAM TYŻYK Tytuł: 12 MP/04/2025   Referencje własne zleceniodawcy: 175489011516 (363.00 PLN)', '2025-04-01', 'seed-8dcee596ce8c2c1f'
  FROM categories c WHERE c.name = 'mieszkanie'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 117.17, 'Rachunek odbiorcy: 91 1020 0029 9000 2023 2777 2284 Nazwa odbiorcy: OLAF KRAWCZYK Tytuł: SPŁATA AKTUALNEGO ZADŁUŻENIA KARTY KREDYTOWEJ * 8853 OD: 48796555364 Referencje własne zleceniodawcy: 175489009', '2025-04-01', 'seed-5d38daf51649e301'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 188.5, '202512297305441872'' - ORLEN STACJA NR 600  POZNAN  POL (188.50 PLN)', '2025-04-30', 'seed-28e9653b65cc9a23'
  FROM categories c WHERE c.name = 'paliwo'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 24.58, '202512197306171340'' - ORLEN STACJA NR 199  KUZNIA RACIBO (24.58 PLN)', '2025-04-29', 'seed-f32c61c3093b5ef6'
  FROM categories c WHERE c.name = 'paliwo'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 276.33, '202512197304766921'' - ORLEN STACJA NR 199  KUZNIA RACIBO (276.33 PLN)', '2025-04-29', 'seed-8473fb4ff7fec8eb'
  FROM categories c WHERE c.name = 'paliwo'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 79.61, '202511397301526735'' - ORLEN STACJA NR 539  ZABKOWICE SLA (79.61 PLN)', '2025-04-21', 'seed-f6e6a542d86cbac2'
  FROM categories c WHERE c.name = 'paliwo'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 104.58, '202511197304741697'' - ORLEN STACJA NR 199  KUZNIA RACIBO (104.58 PLN)', '2025-04-19', 'seed-8ac885ed9a0c711e'
  FROM categories c WHERE c.name = 'paliwo'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 2319.0, '202510897203166490'' - Urzďż˝d Skarbowy Centrum Rozliczeniowe (2319.00 PLN)', '2025-04-18', 'seed-bf35d972f94d9f58'
  FROM categories c WHERE c.name = 'vat'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 1830.0, '202510897203165685'' - Urzďż˝d Skarbowy Centrum Rozliczeniowe (1830.00 PLN)', '2025-04-18', 'seed-0be4771e684eb329'
  FROM categories c WHERE c.name = 'pit36'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 190.66, '202511097305517371'' - ORLEN STACJA NR 539  ZABKOWICE SLA (190.66 PLN)', '2025-04-18', 'seed-57660568b86e3132'
  FROM categories c WHERE c.name = 'paliwo'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 12.0, '202510597201369198'' - Urzďż˝d Skarbowy Centrum Rozliczeniowe (12.00 PLN)', '2025-04-15', 'seed-24dffda5fbe8fa81'
  FROM categories c WHERE c.name = 'pit36'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 3213.25, '202510597201367841'' - Zakďż˝ad Ubezpieczeďż˝ Spoďż˝ecznych 47-400 Racibďż˝rz (3213.25 PLN)', '2025-04-15', 'seed-251823fd7f77c340'
  FROM categories c WHERE c.name = 'zus'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 242.14, '202510597302596604'' - SHELL 11  Wroclaw  POL (242.14 PLN)', '2025-04-13', 'seed-1781319d9186dd09'
  FROM categories c WHERE c.name = 'paliwo'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 82.29, '202510097201177081'' - Orange Polska S.A. Aleje Jerozolimskie 160 02-326 Warszawa NIP 526-025-09-95 (82.29 PLN)', '2025-04-10', 'seed-c71120e066ac7d4e'
  FROM categories c WHERE c.name = 'biuro'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 258.92, '202510097201177012'' - P4 Sp. z o.o. ul. Wynalazek 1 02-677 Warszawa (258.92 PLN)', '2025-04-10', 'seed-3c3532e3f0c9ab46'
  FROM categories c WHERE c.name = 'biuro'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 2335.7, '202509397201154773'' - BNP Paribas Leasing Services Sp. z o.o. 00-844 Warszawa, ul.Grzybowska 78 (2335.70 PLN)', '2025-04-03', 'seed-dde77fd89dcfe6a0'
  FROM categories c WHERE c.name = 'arval'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 1000.0, 'Tytuł: 010085232 74350275087009231896362  Lokalizacja: Adres: Revolut**7108* Miasto: Dublin Kraj: IRLANDIA Data wykonania operacji: 2025-03-28 01:00 Oryginalna kwota operacji: 1000.00 Numer karty: 425', '2025-03-30', 'seed-81ccb0aa638d8c08'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 1000.0, 'Tytuł: 010085232 74350275085009202023618  Lokalizacja: Adres: Revolut**7108* Miasto: Dublin Kraj: IRLANDIA Data wykonania operacji: 2025-03-26 01:00 Oryginalna kwota operacji: 1000.00 Numer karty: 425', '2025-03-28', 'seed-969bb5b3228fee71'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 786.33, 'Rachunek odbiorcy: 91 1020 0029 9000 2023 2777 2284 Nazwa odbiorcy: OLAF KRAWCZYK Tytuł: SPŁATA AKTUALNEGO ZADŁUŻENIA KARTY KREDYTOWEJ * 8853 OD: 48796555364 Referencje własne zleceniodawcy: 175474585', '2025-03-27', 'seed-9709120cbae10599'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 1000.0, 'Tytuł: 010085232 74350275083009179731633  Lokalizacja: Adres: Revolut**7108* Miasto: Dublin Kraj: IRLANDIA Data wykonania operacji: 2025-03-24 01:00 Oryginalna kwota operacji: 1000.00 Numer karty: 425', '2025-03-26', 'seed-c87616d8d8798abd'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 1000.0, 'Tytuł: 010085232 74350275083009177942224  Lokalizacja: Adres: Revolut**7108* Miasto: Dublin Kraj: IRLANDIA Data wykonania operacji: 2025-03-24 01:00 Oryginalna kwota operacji: 1000.00 Numer karty: 425', '2025-03-25', 'seed-da7c9c22aff974b2'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 1500.0, 'Tytuł: 010085232 74350275082009170569231  Lokalizacja: Adres: Revolut**7108* Miasto: Dublin Kraj: IRLANDIA Data wykonania operacji: 2025-03-23 01:00 Oryginalna kwota operacji: 1500.00 Numer karty: 425', '2025-03-25', 'seed-5178eb20458d52fe'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 1500.0, 'Tytuł: 010085232 74350275078009118258588  Lokalizacja: Adres: Revolut**7108* Miasto: Dublin Kraj: IRLANDIA Data wykonania operacji: 2025-03-19 01:00 Oryginalna kwota operacji: 1500.00 Numer karty: 425', '2025-03-20', 'seed-f376155f360b49f3'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 14.99, 'Tytuł: 010066928 74056285075101092167114  Lokalizacja: Adres: APPLE.COM/BILL Miasto: APPLE.COM/BIL Kraj: IRLANDIA Data wykonania operacji: 2025-03-16 01:00 Oryginalna kwota operacji: 14.99 Numer karty', '2025-03-18', 'seed-c468d562c6c493b9'
  FROM categories c WHERE c.name = 'biuro'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 2000.0, 'Tytuł: 010085232 74350275074009076168120  Lokalizacja: Adres: Revolut**7108* Miasto: Dublin Kraj: IRLANDIA Data wykonania operacji: 2025-03-15 01:00 Oryginalna kwota operacji: 2000.00 Numer karty: 425', '2025-03-17', 'seed-91d36a194e0cc464'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 64.0, 'Tytuł:  74838495070300006205573  Lokalizacja: Adres: ALL GOOD S.A. KAWIARNIA Miasto: WARSZAWA Kraj: POLSKA Data wykonania operacji: 2025-03-11 01:00 Oryginalna kwota operacji: 64.00 Numer karty: 42512', '2025-03-13', 'seed-bb02eb3b89bfad1e'
  FROM categories c WHERE c.name = 'arval'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 1500.0, 'Tytuł: 010085232 74350275070009021869933  Lokalizacja: Adres: Revolut**7108* Miasto: Dublin Kraj: IRLANDIA Data wykonania operacji: 2025-03-11 01:00 Oryginalna kwota operacji: 1500.00 Numer karty: 425', '2025-03-12', 'seed-2b19d96c81c4d53c'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 500.0, 'Tytuł: 010085232 74350275069009019355781  Lokalizacja: Adres: Revolut**7108* Miasto: Dublin Kraj: IRLANDIA Data wykonania operacji: 2025-03-10 01:00 Oryginalna kwota operacji: 500.00 Numer karty: 4251', '2025-03-12', 'seed-3aa765c9ead9a569'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 5.49, 'Tytuł: 000498849 74230785069163153800013  Lokalizacja: Adres: ZABKA Z2050 K.2 Miasto: WARSZAWA Kraj: POLSKA Data wykonania operacji: 2025-03-10 01:00 Oryginalna kwota operacji: 5.49 Numer karty: 42512', '2025-03-12', 'seed-2e2e7790921e5ff5'
  FROM categories c WHERE c.name = 'żabka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 30.39, 'Tytuł: 000498849 74230785070163184355729  Lokalizacja: Adres: NETTO 5304 SCO K.3 Miasto: POZNAN Kraj: POLSKA Data wykonania operacji: 2025-03-10 01:00 Oryginalna kwota operacji: 30.39 Numer karty: 425', '2025-03-12', 'seed-232807ebdbb46441'
  FROM categories c WHERE c.name = 'biedronka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 99.9, 'Rachunek odbiorcy: 21 1020 4027 3011 0000 3014 3739 Nazwa odbiorcy: INEA SP. Z O.O.WYSOGOTOWO,UL.WIERZB OWA 8462-081 PRZEŹMIEROWO Tytuł: 95476/2025/03/IS/DS   Referencje własne zleceniodawcy: 17542192', '2025-03-11', 'seed-4f00743910527c52'
  FROM categories c WHERE c.name = 'mieszkanie'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 8.8, 'Nazwa odbiorcy: MOBILE-TRAFFIC-DATA SP. Z O. O. Adres odbiorcy: UL. DRUŻBICKIEGO 11 61-693 POZNAŃ Tytuł: ZAKUP BILETU KOMUNIKACYJNEGO W APLI KACJI IKO  Referencje własne zleceniodawcy: 175421590617 (8', '2025-03-11', 'seed-129183f938213471'
  FROM categories c WHERE c.name = 'przejazdy'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 6.8, 'Nazwa odbiorcy: MOBILE-TRAFFIC-DATA SP. Z O. O. Adres odbiorcy: UL. DRUŻBICKIEGO 11 61-693 POZNAŃ Tytuł: ZAKUP BILETU KOMUNIKACYJNEGO W APLI KACJI IKO  Referencje własne zleceniodawcy: 175419869953 (6', '2025-03-10', 'seed-361c232aaba95b9d'
  FROM categories c WHERE c.name = 'przejazdy'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 6.8, 'Nazwa odbiorcy: MOBILE-TRAFFIC-DATA SP. Z O. O. Adres odbiorcy: UL. DRUŻBICKIEGO 11 61-693 POZNAŃ Tytuł: ZAKUP BILETU KOMUNIKACYJNEGO W APLI KACJI IKO  Referencje własne zleceniodawcy: 175419867624 (6', '2025-03-10', 'seed-8573009634dd51a0'
  FROM categories c WHERE c.name = 'przejazdy'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 2.0, 'Tytuł: 010061097 74463675067560681967953  Lokalizacja: Adres: PUBLIC SECTOR CONSULTING Miasto: SLOMIN Kraj: POLSKA Data wykonania operacji: 2025-03-08 01:00 Oryginalna kwota operacji: 2.00 Numer karty', '2025-03-10', 'seed-423e0f5fdeb93b63'
  FROM categories c WHERE c.name = 'arval'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 68.96, 'Tytuł: 000498849 74230785068163071981037  Lokalizacja: Adres: NETTO 5304 SCO K.3 Miasto: POZNAN Kraj: POLSKA Data wykonania operacji: 2025-03-08 01:00 Oryginalna kwota operacji: 68.96 Numer karty: 425', '2025-03-10', 'seed-a9fbf34372392e0f'
  FROM categories c WHERE c.name = 'biedronka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 1.99, 'Tytuł: 000498849 74230785068163076111457  Lokalizacja: Adres: NETTO 5304 SCO K.3 Miasto: POZNAN Kraj: POLSKA Data wykonania operacji: 2025-03-08 01:00 Oryginalna kwota operacji: 1.99 Numer karty: 4251', '2025-03-10', 'seed-f8f9786f8abc49c9'
  FROM categories c WHERE c.name = 'biedronka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 100.0, 'Tytuł: 010085232 74350275067008995953819  Lokalizacja: Adres: Revolut**7108* Miasto: Dublin Kraj: IRLANDIA Data wykonania operacji: 2025-03-08 01:00 Oryginalna kwota operacji: 100.00 Numer karty: 4251', '2025-03-10', 'seed-48a4746d5a4eb43e'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 2.0, 'Tytuł: 010061097 74463675067560681967979  Lokalizacja: Adres: PUBLIC SECTOR CONSULTING Miasto: SLOMIN Kraj: POLSKA Data wykonania operacji: 2025-03-08 01:00 Oryginalna kwota operacji: 2.00 Numer karty', '2025-03-10', 'seed-413dfe79a5babeb5'
  FROM categories c WHERE c.name = 'arval'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 5.0, 'Tytuł: 010061097 74463675067560681967995  Lokalizacja: Adres: PUBLIC SECTOR CONSULTING Miasto: SLOMIN Kraj: POLSKA Data wykonania operacji: 2025-03-08 01:00 Oryginalna kwota operacji: 5.00 Numer karty', '2025-03-10', 'seed-9a9473b07f512dd7'
  FROM categories c WHERE c.name = 'arval'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 2.0, 'Tytuł: 010061097 74463675067560681968019  Lokalizacja: Adres: PUBLIC SECTOR CONSULTING Miasto: SLOMIN Kraj: POLSKA Data wykonania operacji: 2025-03-08 01:00 Oryginalna kwota operacji: 2.00 Numer karty', '2025-03-10', 'seed-1425042f2572e559'
  FROM categories c WHERE c.name = 'arval'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 5.0, 'Tytuł: 010061097 74463675067560681968027  Lokalizacja: Adres: PUBLIC SECTOR CONSULTING Miasto: SLOMIN Kraj: POLSKA Data wykonania operacji: 2025-03-08 01:00 Oryginalna kwota operacji: 5.00 Numer karty', '2025-03-10', 'seed-d8002a4f6d72e79e'
  FROM categories c WHERE c.name = 'arval'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 2.0, 'Tytuł: 010061097 74463675067560681968043  Lokalizacja: Adres: PUBLIC SECTOR CONSULTING Miasto: SLOMIN Kraj: POLSKA Data wykonania operacji: 2025-03-08 01:00 Oryginalna kwota operacji: 2.00 Numer karty', '2025-03-10', 'seed-91a8866ddc255a8f'
  FROM categories c WHERE c.name = 'arval'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 10.0, 'Tytuł: 010061097 74463675067560681968068  Lokalizacja: Adres: PUBLIC SECTOR CONSULTING Miasto: SLOMIN Kraj: POLSKA Data wykonania operacji: 2025-03-08 01:00 Oryginalna kwota operacji: 10.00 Numer kart', '2025-03-10', 'seed-1d7772e9f792b9bd'
  FROM categories c WHERE c.name = 'arval'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 2.0, 'Tytuł: 010061097 74463675067560681968050  Lokalizacja: Adres: PUBLIC SECTOR CONSULTING Miasto: SLOMIN Kraj: POLSKA Data wykonania operacji: 2025-03-08 01:00 Oryginalna kwota operacji: 2.00 Numer karty', '2025-03-10', 'seed-44ee3e9958f015f2'
  FROM categories c WHERE c.name = 'arval'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 776.64, 'Rachunek odbiorcy: 89 1020 2472 0000 6802 0594 6928 Nazwa odbiorcy: OLAF RADOSŁAW KRAWCZYK Adres odbiorcy: UL. DĘBOWA 7 47-420 KUŹNIA RACIBORSKA Tytuł: FX71258548 USD/PLN 3.8832  200,00 USD -776,64 PL', '2025-03-10', 'seed-a927275f34f3f791'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 43.8, 'Tytuł:  74838495066299544498169  Lokalizacja: Adres: PL SBX POZNAN KAPONIERA Miasto: POZNAN Kraj: POLSKA Data wykonania operacji: 2025-03-07 01:00 Oryginalna kwota operacji: 43.80 Numer karty: 425125*', '2025-03-09', 'seed-388734d5d892a6a0'
  FROM categories c WHERE c.name = 'kawa'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 229.28, 'Tytuł: 000483849 74838490065493192076243  Lokalizacja: Adres: ZIKO APTEKA 05 Miasto: Poznan Kraj: POLSKA Data wykonania operacji: 2025-03-07 01:00 Oryginalna kwota operacji: 229.28 Numer karty: 425125', '2025-03-08', 'seed-cb5739b5fec0ab0b'
  FROM categories c WHERE c.name = 'arval'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 243.65, 'Tytuł: 010066928 74056285065105174735187  Lokalizacja: Adres: AIRBNB * HMPEREQM9T Miasto: 822-307-2000 Kraj: LUKSEMBURG Data wykonania operacji: 2025-03-06 01:00 Oryginalna kwota operacji: 243.65 Nume', '2025-03-08', 'seed-3791cd1f52ebee23'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 89.0, 'Tytuł: 010061097 74463675065600650917126  Lokalizacja: Adres: OKRUSZKI EWA PLANK Miasto: POZNAN Kraj: POLSKA Data wykonania operacji: 2025-03-06 01:00 Oryginalna kwota operacji: 89.00 Numer karty: 425', '2025-03-08', 'seed-98381db2b48ea6d9'
  FROM categories c WHERE c.name = 'arval'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 67.8, 'Tytuł: 000498707 74987075066026293526307  Lokalizacja: Adres: cinema-city.pl Miasto: WARSZAWA Kraj: POLSKA Data wykonania operacji: 2025-03-06 01:00 Oryginalna kwota operacji: 67.80 Numer karty: 42512', '2025-03-08', 'seed-223bb48373aaa36a'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 120.0, 'Rachunek odbiorcy: 64 1140 2004 0000 3402 7691 7816 Nazwa odbiorcy: ODBIORCA PRZELEWU NA TELEFON Tytuł: PRZELEW  OD: 48796555364 DO: 486*****324 (120.00 PLN)', '2025-03-07', 'seed-cd885c31ea8407df'
  FROM categories c WHERE c.name = 'restauracje'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 599.0, 'Tytuł: 00000086854383987   Numer telefonu: 48796555364 Lokalizacja: Adres: www.mediaexpert.pl ''Operacja: 00000086854383987 Numer referencyjny: 00000086854383987 (599.00 PLN)', '2025-03-06', 'seed-03fb2931689fe23b'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 26.48, 'Tytuł: 000498849 74230785063162764644253  Lokalizacja: Adres: ZABKA Z0685 K.1 Miasto: POZNAN Kraj: POLSKA Data wykonania operacji: 2025-03-04 01:00 Oryginalna kwota operacji: 26.48 Numer karty: 425125', '2025-03-06', 'seed-5f3f5ca28ea47fac'
  FROM categories c WHERE c.name = 'żabka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 8.9, 'Tytuł: 000498849 74230785063162764632019  Lokalizacja: Adres: ZABKA Z0685 K.1 Miasto: POZNAN Kraj: POLSKA Data wykonania operacji: 2025-03-04 01:00 Oryginalna kwota operacji: 8.90 Numer karty: 425125*', '2025-03-06', 'seed-df10547482705ed0'
  FROM categories c WHERE c.name = 'żabka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 17.99, 'Tytuł: 000498849 74230785063162749262262  Lokalizacja: Adres: MOL SF221 K.2 Miasto: POZNAN Kraj: POLSKA Data wykonania operacji: 2025-03-04 01:00 Oryginalna kwota operacji: 17.99 Numer karty: 425125**', '2025-03-06', 'seed-a6f4166db407cd64'
  FROM categories c WHERE c.name = 'arval'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 3000.0, 'Rachunek odbiorcy: 48 1540 1157 8129 0000 0084 2846 Nazwa odbiorcy: DM BOŚ Tytuł: PRZELEW   Referencje własne zleceniodawcy: 175398640462 (3000.00 PLN)', '2025-03-05', 'seed-ee6db705b243c7a3'
  FROM categories c WHERE c.name = 'inwestycje'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 6.5, 'Tytuł: 000498849 74230785062162705109938  Lokalizacja: Adres: ZABKA Z0685 K.1 Miasto: POZNAN Kraj: POLSKA Data wykonania operacji: 2025-03-03 01:00 Oryginalna kwota operacji: 6.50 Numer karty: 425125*', '2025-03-05', 'seed-1f308155d1f311b7'
  FROM categories c WHERE c.name = 'żabka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 200.0, 'Tytuł: 010061097 74169505062600627036892  Lokalizacja: Adres: PRACOWNIA PSYCHOLOGICZNA Miasto: POZNAN Kraj: POLSKA Data wykonania operacji: 2025-03-03 01:00 Oryginalna kwota operacji: 200.00 Numer kar', '2025-03-05', 'seed-270f7758aa2d312b'
  FROM categories c WHERE c.name = 'arval'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 280.0, 'Tytuł: 000498849 74230785063162727619608  Lokalizacja: Adres: SYNAPSIS MED Miasto: POZNAN Kraj: POLSKA Data wykonania operacji: 2025-03-03 01:00 Oryginalna kwota operacji: 280.00 Numer karty: 425125**', '2025-03-05', 'seed-65f3a41f429da322'
  FROM categories c WHERE c.name = 'arval'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 500.0, 'Tytuł: OBCY 00000086817517155   Numer telefonu: 48796555364 Lokalizacja: Adres: UL  WAPIENNA 35 Miasto: WROCLAW Kraj: POLSKA Bankomat: OBCY ''Operacja: 00000086817517155 Numer referencyjny: 0000008681', '2025-03-04', 'seed-73c521dd83ff3540'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 4.0, 'Nazwa odbiorcy: MOBILE-TRAFFIC-DATA SP. Z O. O. Adres odbiorcy: UL. DRUŻBICKIEGO 11 61-693 POZNAŃ Tytuł: ZAKUP BILETU KOMUNIKACYJNEGO W APLI KACJI IKO  Referencje własne zleceniodawcy: 175390099440 (4', '2025-03-03', 'seed-da8119c3a0f5fb21'
  FROM categories c WHERE c.name = 'przejazdy'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 35.24, 'Tytuł: 010079564 74609055061500008469982  Lokalizacja: Adres: TIMELEFT Miasto: PARIS Kraj: FRANCJA Data wykonania operacji: 2025-03-02 01:00 Oryginalna kwota operacji: 35.24 Numer karty: 425125******0', '2025-03-03', 'seed-6144481f22e3462d'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 12.01, 'Tytuł:  74810315060150096043366  Lokalizacja: Adres: POLEWSKI CONCEPT Miasto: Poznan Kraj: POLSKA Data wykonania operacji: 2025-03-01 01:00 Oryginalna kwota operacji: 12.01 Numer karty: 425125******02', '2025-03-03', 'seed-c2ddcf9ac489108e'
  FROM categories c WHERE c.name = 'arval'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 4.0, 'Nazwa odbiorcy: MOBILE-TRAFFIC-DATA SP. Z O. O. Adres odbiorcy: UL. DRUŻBICKIEGO 11 61-693 POZNAŃ Tytuł: ZAKUP BILETU KOMUNIKACYJNEGO W APLI KACJI IKO  Referencje własne zleceniodawcy: 175389797751 (4', '2025-03-03', 'seed-adc3da840e650079'
  FROM categories c WHERE c.name = 'przejazdy'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 363.0, 'Rachunek odbiorcy: 21 1940 1076 6256 6800 0000 0000 Nazwa odbiorcy: ADAM TYŻYK Tytuł: 12 MP/03/2025   Referencje własne zleceniodawcy: 175384104836 (363.00 PLN)', '2025-03-03', 'seed-1a95368d4a6ba4b8'
  FROM categories c WHERE c.name = 'mieszkanie'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 1000.0, 'Tytuł: 010085232 74350275059008893061384  Lokalizacja: Adres: Revolut**7108* Miasto: Dublin Kraj: IRLANDIA Data wykonania operacji: 2025-02-28 01:00 Oryginalna kwota operacji: 1000.00 Numer karty: 425', '2025-03-02', 'seed-07a7b03b5a43ed1d'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 45.3, 'Tytuł: 000498849 74230785060162575787542  Lokalizacja: Adres: NETTO 5304 K.1 Miasto: POZNAN Kraj: POLSKA Data wykonania operacji: 2025-02-28 01:00 Oryginalna kwota operacji: 45.30 Numer karty: 425125*', '2025-03-02', 'seed-1ecf30b660f8459c'
  FROM categories c WHERE c.name = 'biedronka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 1280.0, 'Rachunek odbiorcy: 73 1090 2372 0000 0001 1332 9442 Nazwa odbiorcy: MARTA SZCZYGIEŁ Tytuł: PRZELEW NA TELEFON  OD: 48796555364 DO: 486*****967 (1280.00 PLN)', '2025-03-02', 'seed-2da8159f66bb1384'
  FROM categories c WHERE c.name = 'mieszkanie'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 498.0, 'Tytuł: 010059127 74062945058120048390770  Lokalizacja: Adres: ebilet.pl Miasto: Warszawa Kraj: POLSKA Data wykonania operacji: 2025-02-27 01:00 Oryginalna kwota operacji: 498.00 Numer karty: 425125***', '2025-03-02', 'seed-e41e70cd3f181abd'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 41.45, 'Tytuł: 000498849 74230785059162510361075  Lokalizacja: Adres: NETTO 5304 K.1 Miasto: POZNAN Kraj: POLSKA Data wykonania operacji: 2025-02-27 01:00 Oryginalna kwota operacji: 41.45 Numer karty: 425125*', '2025-03-02', 'seed-c05978f68262bb82'
  FROM categories c WHERE c.name = 'biedronka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 87.56, 'Tytuł: 010071549 74043215058120043980296  Lokalizacja: Adres: PayPro SA   *ALLEGRO SP. Miasto: Poznan Kraj: POLSKA Data wykonania operacji: 2025-02-27 01:00 Oryginalna kwota operacji: 87.56 Numer kart', '2025-03-02', 'seed-dbb8536d201bb290'
  FROM categories c WHERE c.name = 'arval'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 381.87, '202508897201136047'' - KANCELARIA PODATKOWO-GOSPODARCZA SP ÓŁKA Z OGRANICZONďż˝ ODPOWIEDZIALNOďż˝C Iďż˝ ul. Radomska 7 44-164 Gliwice NI P: PL 631-264-51-93 (381.87 PLN)', '2025-03-29', 'seed-ff5ab257cf73da25'
  FROM categories c WHERE c.name = 'biuro'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 5.0, '202508397202217519'' - Urzďż˝d Skarbowy Centrum Rozliczeniowe (5.00 PLN)', '2025-03-24', 'seed-cdc73ec59cbd6c6c'
  FROM categories c WHERE c.name = 'pit36'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 4928.0, '202507797202170260'' - Urzďż˝d Skarbowy Centrum Rozliczeniowe (4928.00 PLN)', '2025-03-18', 'seed-c8bd38bf06ddb07b'
  FROM categories c WHERE c.name = 'vat'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 3134.0, '202507797202168873'' - Urzďż˝d Skarbowy Centrum Rozliczeniowe (3134.00 PLN)', '2025-03-18', 'seed-4d23d0bba0ef4903'
  FROM categories c WHERE c.name = 'pit36'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 12.0, '202507497201162393'' - Urzďż˝d Skarbowy Centrum Rozliczeniowe (12.00 PLN)', '2025-03-15', 'seed-86fa0b3a2a97fcc7'
  FROM categories c WHERE c.name = 'pit36'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 3213.25, '202507497201162365'' - Zakďż˝ad Ubezpieczeďż˝ Spoďż˝ecznych 47-400 Racibďż˝rz (3213.25 PLN)', '2025-03-15', 'seed-9d305952bb5f416b'
  FROM categories c WHERE c.name = 'zus'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 82.29, '202506597209775156'' - Orange Polska S.A. Aleje Jerozolimskie 160 02-326 Warszawa NIP 526-025-09-95 (82.29 PLN)', '2025-03-06', 'seed-c7ea9da0597243e1'
  FROM categories c WHERE c.name = 'arval'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 262.74, '202506597209773874'' - P4 Sp. z o.o. ul. Wynalazek 1 02-677 Warszawa (262.74 PLN)', '2025-03-06', 'seed-45f53ff02582c510'
  FROM categories c WHERE c.name = 'biuro'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 2331.18, '202506597209770101'' - BNP Paribas Leasing Services Sp. z o.o. 00-844 Warszawa, ul.Grzybowska 78 (2331.18 PLN)', '2025-03-06', 'seed-c9c7e88988fefcaf'
  FROM categories c WHERE c.name = 'arval'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 91.52, '202506597304465207'' - SHELL 03  Torun  POL (91.52 PLN)', '2025-03-04', 'seed-4e993b11919a5341'
  FROM categories c WHERE c.name = 'paliwo'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 242.61, '202506597304387539'' - MOL SF221 K.2  POZNAN 61871 POL (242.61 PLN)', '2025-03-04', 'seed-49437c88ab340598'
  FROM categories c WHERE c.name = 'paliwo'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 381.87, '202506197202065527'' - KANCELARIA PODATKOWO-GOSPODARCZA SP ÓŁKA Z OGRANICZONďż˝ ODPOWIEDZIALNOďż˝C Iďż˝ ul. Radomska 7 44-164 Gliwice NI P: PL 631-264-51-93 (381.87 PLN)', '2025-03-02', 'seed-e3470e6ad376d6d7'
  FROM categories c WHERE c.name = 'biuro'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 71.5, NULL, '2025-02-15', 'seed-dd10de40a4fb11e0'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 81.5, 'kata aparat', '2025-02-15', 'seed-3cfa5cbd115bf985'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 200.0, NULL, '2025-02-15', 'seed-89b4c19ccb8052b9'
  FROM categories c WHERE c.name = 'lekarz'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 16.69, NULL, '2025-02-15', 'seed-5fb8ebe6548af8e5'
  FROM categories c WHERE c.name = 'żabka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 46.99, NULL, '2025-02-15', 'seed-e5d3afbe18169d27'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 64.0, NULL, '2025-02-15', 'seed-1670a23da4e29abf'
  FROM categories c WHERE c.name = 'kawa'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 2.49, NULL, '2025-02-15', 'seed-dba7ce04197d12f3'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 30.0, NULL, '2025-02-15', 'seed-cc02df5c306994c0'
  FROM categories c WHERE c.name = 'arval'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 680.13, 'wakaj', '2025-02-15', 'seed-0b7825d577758f27'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 4.0, NULL, '2025-02-15', 'seed-22b34eb1b4baf71a'
  FROM categories c WHERE c.name = 'przejazdy'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 75.0, NULL, '2025-02-15', 'seed-fd27c5303b5386ba'
  FROM categories c WHERE c.name = 'biedronka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 17.49, NULL, '2025-02-15', 'seed-ee0c00d16c78db77'
  FROM categories c WHERE c.name = 'żabka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 425.25, 'białko', '2025-02-15', 'seed-1620207607841aaa'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 37.8, NULL, '2025-02-15', 'seed-5dce8c34f7ddf7e2'
  FROM categories c WHERE c.name = 'kawa'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 24.9, NULL, '2025-02-15', 'seed-992f8d9f5cb54166'
  FROM categories c WHERE c.name = 'kawa'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 31.8, NULL, '2025-02-15', 'seed-bad93c5118d80eb2'
  FROM categories c WHERE c.name = 'kawa'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 45.0, NULL, '2025-02-15', 'seed-1d0cd97b523b56a6'
  FROM categories c WHERE c.name = 'arval'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 39.0, NULL, '2025-02-15', 'seed-2a4869966d62aced'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 56.0, NULL, '2025-02-15', 'seed-a25ab563da42f3bb'
  FROM categories c WHERE c.name = 'kawa'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 37.0, NULL, '2025-02-15', 'seed-ef8bfd0d88d152e6'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 15.18, NULL, '2025-02-15', 'seed-84a94c46feb87d75'
  FROM categories c WHERE c.name = 'rossman'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 6.4, NULL, '2025-02-15', 'seed-37359ca6b8c2139c'
  FROM categories c WHERE c.name = 'biuro'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 10.5, NULL, '2025-03-02', 'seed-06e7e9e2008f0b30'
  FROM categories c WHERE c.name = 'żabka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 21.9, NULL, '2025-02-15', 'seed-3e16b46bb7288c1a'
  FROM categories c WHERE c.name = 'kawa'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 14.99, NULL, '2025-02-15', 'seed-28952ec0a31af553'
  FROM categories c WHERE c.name = 'biuro'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 11.99, NULL, '2025-02-15', 'seed-5732590bdff0ade4'
  FROM categories c WHERE c.name = 'żabka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 200.0, NULL, '2025-02-15', 'seed-c7bb36cc6d0b6500'
  FROM categories c WHERE c.name = 'lekarz'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 25.88, NULL, '2025-02-15', 'seed-a874e269b0a3d327'
  FROM categories c WHERE c.name = 'żabka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 108.0, NULL, '2025-02-15', 'seed-ccac9cd94a5d7968'
  FROM categories c WHERE c.name = 'prezenty'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 28.68, NULL, '2025-02-15', 'seed-80c157d2bedc451b'
  FROM categories c WHERE c.name = 'biedronka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 4.0, NULL, '2025-02-15', 'seed-7d4487e05e4e6b54'
  FROM categories c WHERE c.name = 'arval'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 13.49, NULL, '2025-02-15', 'seed-623b3197fe88e4e6'
  FROM categories c WHERE c.name = 'żabka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 75.0, NULL, '2025-02-15', 'seed-3111271b918e9ace'
  FROM categories c WHERE c.name = 'kawa'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 5.0, NULL, '2025-02-15', 'seed-c5b6db54fbce43bb'
  FROM categories c WHERE c.name = 'arval'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 5.0, NULL, '2025-02-15', 'seed-9ccbf765b3f0cbec'
  FROM categories c WHERE c.name = 'arval'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 10.5, NULL, '2025-02-15', 'seed-4ce42f9ffa618f5d'
  FROM categories c WHERE c.name = 'arval'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 15.9, NULL, '2025-02-15', 'seed-523af7633b36d89a'
  FROM categories c WHERE c.name = 'taxi'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 4.0, NULL, '2025-02-15', 'seed-57f7468cdbd10bd2'
  FROM categories c WHERE c.name = 'arval'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 4.0, NULL, '2025-02-15', 'seed-9b647b6d413f18fb'
  FROM categories c WHERE c.name = 'przejazdy'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 4.0, NULL, '2025-02-15', 'seed-9e788e804f41c302'
  FROM categories c WHERE c.name = 'przejazdy'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 53.97, NULL, '2025-02-15', 'seed-908372a19838a5ef'
  FROM categories c WHERE c.name = 'apteka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 12.15, NULL, '2025-02-15', 'seed-b00bf97c43896bd2'
  FROM categories c WHERE c.name = 'biedronka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 27.0, NULL, '2025-02-15', 'seed-2cd47f22f2ff563a'
  FROM categories c WHERE c.name = 'przejazdy'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 55.33, NULL, '2025-02-15', 'seed-a18db816024b1254'
  FROM categories c WHERE c.name = 'biedronka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 7.99, NULL, '2025-02-15', 'seed-f31f138b6f4733c8'
  FROM categories c WHERE c.name = 'apteka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 3.0, NULL, '2025-02-15', 'seed-efd1c4f8ee61a6aa'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 237.21, NULL, '2025-02-15', 'seed-211b98dc668bdd16'
  FROM categories c WHERE c.name = 'biedronka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 1000.0, 'wycieczka', '2025-02-15', 'seed-f7f3f896615647f9'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 99.9, NULL, '2025-02-15', 'seed-e70d2c7da2bb7469'
  FROM categories c WHERE c.name = 'mieszkanie'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 23.99, NULL, '2025-02-15', 'seed-b16db01ada1570df'
  FROM categories c WHERE c.name = 'żabka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 500.0, 'wycieczka', '2025-02-15', 'seed-d20bfedf1e6f32e0'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 75.0, 'prezent', '2025-02-15', 'seed-56e1f4044c226101'
  FROM categories c WHERE c.name = 'prezenty'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 20.7, NULL, '2025-02-15', 'seed-52b687a2139dc52a'
  FROM categories c WHERE c.name = 'żabka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 280.0, NULL, '2025-02-15', 'seed-2a6b450ce4201ddc'
  FROM categories c WHERE c.name = 'lekarz'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 20.0, NULL, '2025-02-15', 'seed-98f42056862c83d0'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 282.27, NULL, '2025-02-15', 'seed-05a1a68b280c8af0'
  FROM categories c WHERE c.name = 'apteka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 4.0, NULL, '2025-02-15', 'seed-e9ec18c03848b23b'
  FROM categories c WHERE c.name = 'przejazdy'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 3.99, NULL, '2025-02-15', 'seed-24acfa585f598054'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 4.0, NULL, '2025-02-15', 'seed-1ca4fb1735f86f1a'
  FROM categories c WHERE c.name = 'przejazdy'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 36.2, NULL, '2025-02-15', 'seed-1d787e990ffc082f'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 4.0, NULL, '2025-02-15', 'seed-cd64550378c27080'
  FROM categories c WHERE c.name = 'przejazdy'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 4.0, NULL, '2025-02-15', 'seed-e7ddf745ccf1fc24'
  FROM categories c WHERE c.name = 'przejazdy'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 200.0, NULL, '2025-02-15', 'seed-38d9c310f988ea1e'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 500.0, 'wycieczka', '2025-02-15', 'seed-9238adfb1ef98ed2'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 12.0, NULL, '2025-02-15', 'seed-453f8ab2d7929027'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 16.0, NULL, '2025-02-15', 'seed-d5c75e118a08303d'
  FROM categories c WHERE c.name = 'przejazdy'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 16.0, NULL, '2025-02-15', 'seed-b32e19ee9dcd749b'
  FROM categories c WHERE c.name = 'przejazdy'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 10.5, NULL, '2025-02-15', 'seed-c58ef55599ba7780'
  FROM categories c WHERE c.name = 'żabka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 16.0, NULL, '2025-02-15', 'seed-c4b26c836b7c3cb5'
  FROM categories c WHERE c.name = 'przejazdy'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 16.0, NULL, '2025-02-15', 'seed-ad197e3763de2beb'
  FROM categories c WHERE c.name = 'przejazdy'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 1500.0, 'wycieczka', '2025-02-15', 'seed-6c989bbc14ec0092'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 11.99, NULL, '2025-02-15', 'seed-1a09b7b1e26ddb73'
  FROM categories c WHERE c.name = 'żabka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 1480.0, NULL, '2025-02-15', 'seed-5f406356faf6ad13'
  FROM categories c WHERE c.name = 'mieszkanie'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 200.0, 'wycieczka', '2025-02-15', 'seed-764ebdca6561aa25'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 417.0, 'wycieczka', '2025-03-02', 'seed-10cf5ae6434637ea'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 200.0, NULL, '2025-02-15', 'seed-59c643e9741afde5'
  FROM categories c WHERE c.name = 'lekarz'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 373.0, NULL, '2025-02-15', 'seed-e596a15aee6ef0d2'
  FROM categories c WHERE c.name = 'mieszkanie'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 35.0, NULL, '2025-02-15', 'seed-cde0ef2095dbe4df'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 549.0, 'kąkuter', '2025-02-15', 'seed-b9b4eb21cf48c747'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 317.19, 'wycieczka', '2025-02-15', 'seed-04946e4d3bd13ca5'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 1181.39, 'wycieczka', '2025-03-02', 'seed-bf722a7ace7f4822'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 1366.12, 'wycieczka', '2025-02-15', 'seed-2692f4acc50dcd6d'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 21.9, NULL, '2025-02-15', 'seed-08d21fa9654cfca2'
  FROM categories c WHERE c.name = 'kawa'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 653.06, 'wycieczka', '2025-02-15', 'seed-3ee16ee4dd4fc9dc'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 4.0, NULL, '2025-02-15', 'seed-6cbd09aa41c1f029'
  FROM categories c WHERE c.name = 'przejazdy'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 4.0, NULL, '2025-02-15', 'seed-e53bdeae35029a45'
  FROM categories c WHERE c.name = 'przejazdy'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 4.5, NULL, '2025-02-15', 'seed-70d9a99531718015'
  FROM categories c WHERE c.name = 'żabka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 469.99, NULL, '2025-02-15', 'seed-6af6e1b29b2d8c28'
  FROM categories c WHERE c.name = 'ubrania'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 1014.19, 'wycieczka', '2025-02-15', 'seed-0da7e9505225bbee'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 221.59, NULL, '2025-02-15', 'seed-b040f78c6e85656f'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 185.2, NULL, '2025-02-15', 'seed-1364b7cc1aa07ba5'
  FROM categories c WHERE c.name = 'paliwo'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 3980.0, NULL, '2025-02-15', 'seed-7f4511d94824c4b5'
  FROM categories c WHERE c.name = 'pit36'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 6088.0, NULL, '2025-02-15', 'seed-1687a72f3aa26ff2'
  FROM categories c WHERE c.name = 'vat'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 34.16, NULL, '2025-02-15', 'seed-d9a04d6d34e12495'
  FROM categories c WHERE c.name = 'paliwo'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 251.43, NULL, '2025-02-15', 'seed-1d1d177563d71fac'
  FROM categories c WHERE c.name = 'paliwo'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 250.6, NULL, '2025-02-15', 'seed-85ca718cfdbb8fb2'
  FROM categories c WHERE c.name = 'paliwo'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 12.0, NULL, '2025-02-15', 'seed-ebbac67ac1c6738a'
  FROM categories c WHERE c.name = 'pit36'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 3213.25, NULL, '2025-02-15', 'seed-c3380009a0c8ae43'
  FROM categories c WHERE c.name = 'zus'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 186.86, NULL, '2025-02-15', 'seed-459e6cfb98a2f7cb'
  FROM categories c WHERE c.name = 'paliwo'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 210.23, NULL, '2025-02-15', 'seed-c4ea7540f4f85a33'
  FROM categories c WHERE c.name = 'paliwo'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 50.0, NULL, '2025-02-15', 'seed-e57a8115eeef0914'
  FROM categories c WHERE c.name = 'arval'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 279.0, NULL, '2025-02-15', 'seed-3348825c6d495af5'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 178.34, NULL, '2025-02-15', 'seed-eee728f83864fe20'
  FROM categories c WHERE c.name = 'paliwo'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 202.06, NULL, '2025-02-15', 'seed-01120f186c654ad9'
  FROM categories c WHERE c.name = 'paliwo'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 82.29, NULL, '2025-02-15', 'seed-88fe5f84af04d0dd'
  FROM categories c WHERE c.name = 'biuro'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 246.0, NULL, '2025-02-15', 'seed-0d1f04e1dc9fa740'
  FROM categories c WHERE c.name = 'biuro'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 2330.28, NULL, '2025-02-15', 'seed-1a296c7a846352cd'
  FROM categories c WHERE c.name = 'arval'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 347.16, NULL, '2025-01-15', 'seed-0e56eca7686e6d9e'
  FROM categories c WHERE c.name = 'biuro'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 251.16, NULL, '2025-01-15', 'seed-e38e4a707a3248f9'
  FROM categories c WHERE c.name = 'paliwo'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 197.1, NULL, '2025-01-15', 'seed-3b98870c9507be5e'
  FROM categories c WHERE c.name = 'paliwo'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 5062.0, NULL, '2025-01-15', 'seed-d392687e1c577829'
  FROM categories c WHERE c.name = 'vat'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 3164.0, NULL, '2025-01-15', 'seed-78c5221f04fe470d'
  FROM categories c WHERE c.name = 'pit36'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 870.0, NULL, '2025-01-15', 'seed-b04e578f3f45eb2a'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 12.0, NULL, '2025-01-15', 'seed-df203d7750829cd3'
  FROM categories c WHERE c.name = 'pit36'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 1312.71, NULL, '2025-01-15', 'seed-dcd07201a542204d'
  FROM categories c WHERE c.name = 'zus'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 70.0, NULL, '2025-01-15', 'seed-5ebadf30bb04b2a4'
  FROM categories c WHERE c.name = 'przejazdy'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 70.0, NULL, '2025-01-15', 'seed-9f358739408b9567'
  FROM categories c WHERE c.name = 'przejazdy'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 82.29, NULL, '2025-01-15', 'seed-3a9319ad920d5d6e'
  FROM categories c WHERE c.name = 'biuro'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 2329.37, NULL, '2025-01-15', 'seed-259fc86c43ec359f'
  FROM categories c WHERE c.name = 'arval'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 104.2, NULL, '2025-01-15', 'seed-974f71ef90a02e80'
  FROM categories c WHERE c.name = 'biuro'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 15.0, NULL, '2025-01-15', 'seed-7db296258062ce29'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 199.0, NULL, '2025-01-15', 'seed-b5a21cc81c3bf672'
  FROM categories c WHERE c.name = 'kawa'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 7.9, NULL, '2025-01-15', 'seed-e87dfe2501e7cea3'
  FROM categories c WHERE c.name = 'żabka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 130.0, NULL, '2025-01-15', 'seed-561ebbda06472b0f'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 4.5, NULL, '2025-01-15', 'seed-d8fcf0bf864deafd'
  FROM categories c WHERE c.name = 'żabka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 1300.0, 'loty', '2025-01-15', 'seed-3a9df96f3e728f7b'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 500.0, 'loty', '2025-01-15', 'seed-686f1f69f20fa54a'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 54.75, NULL, '2025-01-15', 'seed-4efadbaedafb0e97'
  FROM categories c WHERE c.name = 'kawa'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 200.0, NULL, '2025-01-15', 'seed-ee546e9b57394e46'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 7.9, NULL, '2025-03-02', 'seed-f06f535bdf45b314'
  FROM categories c WHERE c.name = 'żabka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 500.0, 'angielski', '2025-01-15', 'seed-ea534c4424570658'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 400.0, NULL, '2025-01-15', 'seed-8e6e2e665b41604d'
  FROM categories c WHERE c.name = 'lekarz'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 64.48, NULL, '2025-01-15', 'seed-b4aef7024541a4ef'
  FROM categories c WHERE c.name = 'rossman'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 5.0, NULL, '2025-01-15', 'seed-c42245b3a8fd83b8'
  FROM categories c WHERE c.name = 'arval'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 2.0, NULL, '2025-01-15', 'seed-6e0ee853a60b7a9b'
  FROM categories c WHERE c.name = 'arval'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 5.0, NULL, '2025-01-15', 'seed-356234721a31bf74'
  FROM categories c WHERE c.name = 'arval'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 103.72, NULL, '2025-01-15', 'seed-9a00387f74d6970e'
  FROM categories c WHERE c.name = 'mieszkanie'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 64.0, NULL, '2025-01-15', 'seed-dfc5214896ee5b1d'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 35.99, NULL, '2025-01-15', 'seed-294c297981f6e969'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 4.0, NULL, '2025-01-15', 'seed-57001f648922002e'
  FROM categories c WHERE c.name = 'przejazdy'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 4.0, NULL, '2025-01-15', 'seed-67919b04d8a5f0d7'
  FROM categories c WHERE c.name = 'przejazdy'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 62.0, NULL, '2025-01-15', 'seed-ea374d5f7ffdb6ad'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 9.49, NULL, '2025-01-15', 'seed-e4ca063a1928e4d4'
  FROM categories c WHERE c.name = 'żabka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 59.78, NULL, '2025-01-15', 'seed-063886b0b9b25d42'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 107.89, NULL, '2025-01-15', 'seed-a1a9fe5dd9edde9d'
  FROM categories c WHERE c.name = 'prezenty'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 600.0, NULL, '2025-01-15', 'seed-c56ce6f5db3e83e8'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 39.0, NULL, '2025-01-15', 'seed-5625c5adccd473cc'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 29.9, NULL, '2025-01-15', 'seed-aa3b2ab2bbe21334'
  FROM categories c WHERE c.name = 'apteka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 14.99, NULL, '2025-01-15', 'seed-40e7518a182a83b0'
  FROM categories c WHERE c.name = 'biuro'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 4.0, NULL, '2025-01-15', 'seed-49e1b4ae52e6f0c9'
  FROM categories c WHERE c.name = 'przejazdy'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 200.0, NULL, '2025-01-15', 'seed-6c815af6a0c4f822'
  FROM categories c WHERE c.name = 'lekarz'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 31.99, NULL, '2025-01-15', 'seed-d9aab6725c703be2'
  FROM categories c WHERE c.name = 'apteka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 4.0, NULL, '2025-01-15', 'seed-3448d7d202845e0b'
  FROM categories c WHERE c.name = 'przejazdy'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 4.0, NULL, '2025-01-15', 'seed-68957e1c45f074e2'
  FROM categories c WHERE c.name = 'przejazdy'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 99.9, NULL, '2025-01-15', 'seed-57da015bc3e0404f'
  FROM categories c WHERE c.name = 'mieszkanie'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 200.0, NULL, '2025-01-15', 'seed-7ae6d504ec7dba3c'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 186.78, NULL, '2025-01-15', 'seed-5d3a8bd233261c0a'
  FROM categories c WHERE c.name = 'apteka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 239.99, NULL, '2025-01-15', 'seed-dd535e04823c69ff'
  FROM categories c WHERE c.name = 'lekarz'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 3865.0, 'loty', '2025-01-15', 'seed-7c115265ca204e32'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 168.49, NULL, '2025-01-15', 'seed-22f48cfccf67a327'
  FROM categories c WHERE c.name = 'kawa'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 180.18, NULL, '2025-01-15', 'seed-a0be07470982d82d'
  FROM categories c WHERE c.name = 'biedronka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 46.18, NULL, '2025-01-15', 'seed-e5a32f28ab93d8e5'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 46.18, NULL, '2025-01-15', 'seed-afa7136c1aef6e8f'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 60.9, NULL, '2025-01-15', 'seed-e4db98978288dabf'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 200.0, NULL, '2025-01-15', 'seed-f6552fa170224b21'
  FROM categories c WHERE c.name = 'lekarz'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 261.89, NULL, '2025-01-15', 'seed-21deceb01656e05d'
  FROM categories c WHERE c.name = 'prezenty'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 3.0, NULL, '2025-01-15', 'seed-d5fd70de11b4056a'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 1000.0, NULL, '2025-01-15', 'seed-efc20b16d46729c7'
  FROM categories c WHERE c.name = 'biedronka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 4.0, NULL, '2025-01-15', 'seed-40d80bcc1a645305'
  FROM categories c WHERE c.name = 'przejazdy'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 4.0, NULL, '2025-01-15', 'seed-c7d2bd6b8ff8210c'
  FROM categories c WHERE c.name = 'przejazdy'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 85.0, NULL, '2025-01-15', 'seed-f3b7c8d4e53a7148'
  FROM categories c WHERE c.name = 'biedronka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 206.47, NULL, '2025-01-15', 'seed-796f079f3d4368b3'
  FROM categories c WHERE c.name = 'biedronka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 1480.0, NULL, '2025-01-15', 'seed-26cb98e3db7b6924'
  FROM categories c WHERE c.name = 'mieszkanie'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 25.0, NULL, '2025-01-15', 'seed-a4dd181c582524d7'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 93.0, NULL, '2025-01-15', 'seed-5edb8bfedf77480e'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 152.96, NULL, '2025-01-15', 'seed-4f9f87e869538c66'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 11.9, NULL, '2025-01-15', 'seed-0a216953a3dfb520'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 350.0, NULL, '2025-01-15', 'seed-0fc6259ced3c9e97'
  FROM categories c WHERE c.name = 'mieszkanie'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 4.0, NULL, '2025-01-15', 'seed-5451138206056983'
  FROM categories c WHERE c.name = 'przejazdy'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 94.0, NULL, '2025-01-15', 'seed-6fa9d396ca016e40'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 9.88, NULL, '2025-01-15', 'seed-cb8ccd2d3fcea7a7'
  FROM categories c WHERE c.name = 'żabka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 16.5, NULL, '2025-03-02', 'seed-63c866ab3adadafd'
  FROM categories c WHERE c.name = 'żabka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 500.0, NULL, '2025-01-15', 'seed-6557f05175cd9242'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 8.1, NULL, '2025-01-15', 'seed-8079c682853bc9d7'
  FROM categories c WHERE c.name = 'żabka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 4763.0, 'OC/ac', '2024-11-30', 'seed-d0b983bcb9e9cf11'
  FROM categories c WHERE c.name = 'arval'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 1480.0, NULL, '2024-11-30', 'seed-a098d4a0859a83cc'
  FROM categories c WHERE c.name = 'mieszkanie'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 177.0, 'prezent mihvu', '2024-12-03', 'seed-a6651e40f89be849'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 350.0, 'parking', '2024-12-03', 'seed-a4f4da292eac0093'
  FROM categories c WHERE c.name = 'mieszkanie'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 200.0, NULL, '2024-12-03', 'seed-c0f99d153fae44a2'
  FROM categories c WHERE c.name = 'lekarz'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 105.0, 'pociag birr', '2024-12-03', 'seed-195926f0afd3f0fb'
  FROM categories c WHERE c.name = 'przejazdy'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 228.0, 'play', '2024-12-05', 'seed-17b4978c48da43c0'
  FROM categories c WHERE c.name = 'biuro'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 83.0, 'orange', '2024-12-05', 'seed-f7d7d9f548cb924a'
  FROM categories c WHERE c.name = 'biuro'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 2328.0, 'tucson', '2024-12-05', 'seed-7f4bab27b2f31f47'
  FROM categories c WHERE c.name = 'arval'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 120.0, 'latarka', '2024-12-12', 'seed-7f855a7f0377dd42'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 154.9, NULL, '2024-12-15', 'seed-e10a41e938d7614f'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 90.25, NULL, '2024-12-15', 'seed-fc143d01822d4c95'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 4.0, NULL, '2024-12-15', 'seed-f467d31d30794db0'
  FROM categories c WHERE c.name = 'arval'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 4.0, NULL, '2024-12-15', 'seed-49ff85cdc13e961e'
  FROM categories c WHERE c.name = 'arval'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 19.5, NULL, '2024-12-15', 'seed-09169319a867adfd'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 5.0, NULL, '2024-12-15', 'seed-76f3944165cdc9fb'
  FROM categories c WHERE c.name = 'arval'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 6.99, NULL, '2024-12-15', 'seed-2735ba4b6161a04e'
  FROM categories c WHERE c.name = 'biedronka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 28.0, NULL, '2024-12-15', 'seed-d16f066c5d05b210'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 19.99, NULL, '2024-12-15', 'seed-0b0880bd1602e6c5'
  FROM categories c WHERE c.name = 'biedronka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 2.0, NULL, '2024-12-15', 'seed-b6176ef9f7409b15'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 85.0, NULL, '2024-12-15', 'seed-276fc133d6505bc4'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 10.98, NULL, '2024-12-15', 'seed-eee3777ec6671cb1'
  FROM categories c WHERE c.name = 'biedronka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 35.97, NULL, '2024-12-15', 'seed-8f00a638c67e82de'
  FROM categories c WHERE c.name = 'biedronka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 94.81, NULL, '2024-12-15', 'seed-399b40ed1ac8f08c'
  FROM categories c WHERE c.name = 'biedronka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 34.66, NULL, '2024-12-15', 'seed-0fd424d0fb93c0ac'
  FROM categories c WHERE c.name = 'biedronka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 18.08, NULL, '2024-12-15', 'seed-32b453e0b38f199c'
  FROM categories c WHERE c.name = 'rossman'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 650.0, NULL, '2024-12-15', 'seed-88327ae0c610727c'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 3000.0, NULL, '2024-12-15', 'seed-2e58ff6dfcb96690'
  FROM categories c WHERE c.name = 'inwestycje'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 9.99, NULL, '2024-12-15', 'seed-b4c032b6f5a7aaee'
  FROM categories c WHERE c.name = 'żabka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 7.32, NULL, '2024-12-15', 'seed-ebea88218b21bc1d'
  FROM categories c WHERE c.name = 'biedronka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 7.0, NULL, '2024-12-15', 'seed-821cd2a1e1706c11'
  FROM categories c WHERE c.name = 'żabka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 16.0, NULL, '2024-12-15', 'seed-1cc46349c58792ab'
  FROM categories c WHERE c.name = 'przejazdy'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 173.0, NULL, '2024-12-15', 'seed-4b8cea3d4e7346ff'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 14.99, NULL, '2024-12-15', 'seed-2a02f1d9f0b2ebb2'
  FROM categories c WHERE c.name = 'biuro'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 44.0, NULL, '2024-12-15', 'seed-c8897693a5fe0720'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 214.99, NULL, '2024-12-15', 'seed-fc6c2647f6c51379'
  FROM categories c WHERE c.name = 'prezenty'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 200.0, NULL, '2024-12-15', 'seed-638bc024874897ac'
  FROM categories c WHERE c.name = 'lekarz'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 24.98, NULL, '2024-12-15', 'seed-59e89843888ed058'
  FROM categories c WHERE c.name = 'rossman'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 4.0, NULL, '2024-12-15', 'seed-ef10716a0598a27f'
  FROM categories c WHERE c.name = 'przejazdy'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 4.0, NULL, '2024-12-15', 'seed-36dc5ec0a6fb0b53'
  FROM categories c WHERE c.name = 'przejazdy'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 599.0, NULL, '2024-12-15', 'seed-dd76e2f2fb4b3953'
  FROM categories c WHERE c.name = 'prezenty'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 26.75, NULL, '2024-12-15', 'seed-17dc740104750cf7'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 179.9, NULL, '2024-12-15', 'seed-8b41b18adc374dc8'
  FROM categories c WHERE c.name = 'ubrania'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 36.0, NULL, '2024-12-15', 'seed-497f96beabb7dcbe'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 44.7, NULL, '2024-12-15', 'seed-13c10575f917f42f'
  FROM categories c WHERE c.name = 'przejazdy'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 10.59, NULL, '2024-12-15', 'seed-263ec5e9dc084519'
  FROM categories c WHERE c.name = 'żabka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 34.0, NULL, '2024-12-15', 'seed-2a12ab735e7a8c87'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 3.4, NULL, '2024-12-15', 'seed-c49b4fc2ac3e79c6'
  FROM categories c WHERE c.name = 'przejazdy'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 206.97, NULL, '2024-12-15', 'seed-c617a9305321c33b'
  FROM categories c WHERE c.name = 'apteka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 85.0, NULL, '2024-12-15', 'seed-a139889b981981e4'
  FROM categories c WHERE c.name = 'biedronka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 4000.0, NULL, '2024-12-15', 'seed-9ad72fd228255785'
  FROM categories c WHERE c.name = 'inwestycje'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 4000.0, NULL, '2024-12-15', 'seed-24d48041b38bd326'
  FROM categories c WHERE c.name = 'inwestycje'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 4.0, NULL, '2024-12-15', 'seed-71c811c00101b636'
  FROM categories c WHERE c.name = 'przejazdy'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 54.9, NULL, '2024-12-15', 'seed-30812b23e9b5b4b5'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 200.0, NULL, '2024-12-15', 'seed-71ec900160dc8777'
  FROM categories c WHERE c.name = 'lekarz'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 99.9, NULL, '2024-12-15', 'seed-c70a2bc8aac7c030'
  FROM categories c WHERE c.name = 'mieszkanie'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 122.0, NULL, '2024-12-15', 'seed-656bc35cf5fef2c5'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 38.0, NULL, '2024-12-15', 'seed-2aa94c00882f374e'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 597.08, NULL, '2024-12-15', 'seed-0c190729ce7d281c'
  FROM categories c WHERE c.name = 'prezenty'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 4.0, NULL, '2024-12-15', 'seed-c98e44cb9b8c3c6d'
  FROM categories c WHERE c.name = 'przejazdy'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 4.0, NULL, '2024-12-15', 'seed-6857688170f5200b'
  FROM categories c WHERE c.name = 'przejazdy'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 29.47, NULL, '2024-12-15', 'seed-472318d0dff2c241'
  FROM categories c WHERE c.name = 'rossman'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 114.0, NULL, '2024-12-15', 'seed-40af6522e41ed50a'
  FROM categories c WHERE c.name = 'prezenty'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 74.55, NULL, '2024-12-15', 'seed-3b3431d50f9e0d96'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 47.99, NULL, '2024-12-15', 'seed-2d9fdb7666179ae0'
  FROM categories c WHERE c.name = 'rossman'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 240.0, NULL, '2024-12-15', 'seed-84bea494b6c610eb'
  FROM categories c WHERE c.name = 'prezenty'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 9.98, NULL, '2024-12-15', 'seed-dfb4449cf370e4c8'
  FROM categories c WHERE c.name = 'żabka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 21.38, NULL, '2024-12-15', 'seed-463d96f1a9f423a2'
  FROM categories c WHERE c.name = 'biedronka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 14.49, NULL, '2024-12-15', 'seed-5e08b2e9cae0a64e'
  FROM categories c WHERE c.name = 'żabka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 81.48, NULL, '2024-12-15', 'seed-1983d84614107315'
  FROM categories c WHERE c.name = 'apteka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 525.0, NULL, '2024-12-15', 'seed-6c27f7bc459a33f1'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 17.98, NULL, '2024-12-15', 'seed-dfc068dc8030c5b1'
  FROM categories c WHERE c.name = 'przejazdy'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 200.0, NULL, '2024-12-15', 'seed-2c3a92c102c7b073'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 600.0, NULL, '2024-12-15', 'seed-b8c73a9840857ad9'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 4.0, NULL, '2024-12-15', 'seed-3d844806b661b74a'
  FROM categories c WHERE c.name = 'arval'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 4.0, NULL, '2024-12-15', 'seed-b7edff5cfc404b89'
  FROM categories c WHERE c.name = 'arval'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 4.0, NULL, '2024-12-15', 'seed-1bdbe1b3b9524c59'
  FROM categories c WHERE c.name = 'arval'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 98.22, NULL, '2024-12-15', 'seed-da78e46e4c5a29c0'
  FROM categories c WHERE c.name = 'biedronka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 4.0, NULL, '2024-12-15', 'seed-4558e108f058959e'
  FROM categories c WHERE c.name = 'arval'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 14.92, NULL, '2024-12-15', 'seed-83c18160a80a2b8b'
  FROM categories c WHERE c.name = 'biedronka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 4.0, NULL, '2024-12-15', 'seed-241acf7eee2124c9'
  FROM categories c WHERE c.name = 'przejazdy'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 4.0, NULL, '2024-12-15', 'seed-3855974c4648dc2d'
  FROM categories c WHERE c.name = 'przejazdy'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 347.16, NULL, '2024-12-15', 'seed-98651b82f3a70260'
  FROM categories c WHERE c.name = 'biuro'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 76.0, NULL, '2024-12-15', 'seed-ef3ebdfa9a9b4fc4'
  FROM categories c WHERE c.name = 'paliwo'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 218.89, NULL, '2024-12-15', 'seed-466e6b4491303968'
  FROM categories c WHERE c.name = 'paliwo'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 238.38, NULL, '2024-12-15', 'seed-1b8b63eda952c10a'
  FROM categories c WHERE c.name = 'paliwo'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 2913.03, NULL, '2024-12-15', 'seed-612d1be0dc7bc68d'
  FROM categories c WHERE c.name = 'zus'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 12.0, NULL, '2025-03-02', 'seed-208ab69dd2ec13f7'
  FROM categories c WHERE c.name = 'pit36'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 5477.0, NULL, '2025-03-02', 'seed-8d0c8b06847d11aa'
  FROM categories c WHERE c.name = 'vat'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 3295.0, NULL, '2025-03-02', 'seed-afb66cb59b375ac2'
  FROM categories c WHERE c.name = 'pit36'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 400.0, NULL, '2024-12-15', 'seed-5cb8c47b138f96fc'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 99.0, NULL, '2024-12-15', 'seed-2d48ede805c155ed'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 82.29, NULL, '2024-12-15', 'seed-81279234d906fb32'
  FROM categories c WHERE c.name = 'biuro'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 227.55, NULL, '2024-12-15', 'seed-809ffe48c24274ee'
  FROM categories c WHERE c.name = 'biuro'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 149.0, NULL, '2024-12-15', 'seed-7569c576f13c7f23'
  FROM categories c WHERE c.name = 'przejazdy'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 104.3, NULL, '2024-12-15', 'seed-be791ab5521b694c'
  FROM categories c WHERE c.name = 'przejazdy'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 167.04, NULL, '2024-12-15', 'seed-21ce249c53fe0a25'
  FROM categories c WHERE c.name = 'paliwo'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 140.65, NULL, '2024-12-15', 'seed-879d4b551f21bb90'
  FROM categories c WHERE c.name = 'paliwo'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 8200.0, 'aparat', '2024-11-10', 'seed-41572e9a36fa9747'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 2000.0, 'bossa', '2024-11-10', 'seed-e65808aa115550b2'
  FROM categories c WHERE c.name = 'biuro'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 300.0, 'birr', '2024-11-10', 'seed-1ef6750c7cc13c45'
  FROM categories c WHERE c.name = 'przejazdy'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 83.0, 'orange', '2024-11-10', 'seed-45bba00381669c44'
  FROM categories c WHERE c.name = 'biuro'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 230.0, 'play', '2024-11-10', 'seed-251eb54226dd317e'
  FROM categories c WHERE c.name = 'biuro'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 2325.0, NULL, '2024-11-10', 'seed-efba686723728346'
  FROM categories c WHERE c.name = 'arval'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 76.0, NULL, '2024-11-10', 'seed-6e1912f4288c6028'
  FROM categories c WHERE c.name = 'paliwo'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 100.0, 'frontendmasters', '2024-11-10', 'seed-cb8286a1b30cf856'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 113.0, 'madara', '2024-11-10', 'seed-b8582d544ffc6e73'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 20.0, NULL, '2024-11-10', 'seed-809257da8e5e6d91'
  FROM categories c WHERE c.name = 'biedronka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 8.0, NULL, '2024-11-10', 'seed-8e244a4833b84bfa'
  FROM categories c WHERE c.name = 'przejazdy'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 16.0, NULL, '2024-11-10', 'seed-f665b0e1b5254702'
  FROM categories c WHERE c.name = 'biedronka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 10.0, NULL, '2024-11-10', 'seed-4992e0c0733bde89'
  FROM categories c WHERE c.name = 'żabka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 258.0, 'prezent', '2024-11-10', 'seed-adea0b3d87ece980'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 600.0, 'nowa forma', '2024-11-10', 'seed-6d89a3f40fffa4d2'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 200.0, 'osłona fuji', '2024-11-10', 'seed-dff900d0c7d99a5f'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 100.0, 'bateria fuji', '2024-11-10', 'seed-03411a04edd24fab'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 9.0, NULL, '2024-11-10', 'seed-d4f1742dc447abbc'
  FROM categories c WHERE c.name = 'biedronka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 8.0, NULL, '2024-11-10', 'seed-bdfba6d9547df7b3'
  FROM categories c WHERE c.name = 'przejazdy'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 350.0, NULL, '2024-11-10', 'seed-e6a18136a9b03d7a'
  FROM categories c WHERE c.name = 'mieszkanie'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 40.0, NULL, '2024-11-10', 'seed-2785002deadbe29c'
  FROM categories c WHERE c.name = 'biedronka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 40.0, 'sml prezent', '2024-11-10', 'seed-1a7cb77ac93d4c0a'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 1500.0, NULL, '2024-11-10', 'seed-122d65e46b7e0366'
  FROM categories c WHERE c.name = 'mieszkanie'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 5.0, NULL, '2024-11-10', 'seed-f91b4c5de679cafa'
  FROM categories c WHERE c.name = 'żabka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 67.0, NULL, '2024-11-10', 'seed-f559d3e90889ccf0'
  FROM categories c WHERE c.name = 'biedronka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 136.0, 'pizza', '2024-11-10', 'seed-c88e5bddea75a673'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 130.0, NULL, '2024-11-10', 'seed-059d6c3840c9fb31'
  FROM categories c WHERE c.name = 'ubrania'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 10.0, NULL, '2024-11-10', 'seed-df430f2c956621d4'
  FROM categories c WHERE c.name = 'żabka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 2000.0, 'przeglad', '2024-11-10', 'seed-ba53fde48ee8f21c'
  FROM categories c WHERE c.name = 'arval'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 250.0, 'Badania', '2024-11-12', 'seed-f68f3d6cab5c467c'
  FROM categories c WHERE c.name = 'lekarz'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 20.0, NULL, '2024-11-12', 'seed-54b8fe6d6690b994'
  FROM categories c WHERE c.name = 'biedronka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 3000.0, NULL, '2024-11-14', 'seed-25f74b4ae0582a0f'
  FROM categories c WHERE c.name = 'zus'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 250.0, NULL, '2024-11-14', 'seed-88d8b0e548fb72b3'
  FROM categories c WHERE c.name = 'lekarz'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 200.0, NULL, '2024-11-14', 'seed-64fcb054b5199291'
  FROM categories c WHERE c.name = 'apteka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 6117.0, NULL, '2024-11-14', 'seed-a3c90094715a4447'
  FROM categories c WHERE c.name = 'vat'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 4072.0, NULL, '2024-11-14', 'seed-247c3e3324df02e8'
  FROM categories c WHERE c.name = 'pit36'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 350.0, 'hotel birr', '2024-11-24', 'seed-74e05227ee055d7e'
  FROM categories c WHERE c.name = 'biuro'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 227.0, NULL, '2024-11-24', 'seed-f07e3858148c5973'
  FROM categories c WHERE c.name = 'paliwo'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 120.0, NULL, '2024-11-24', 'seed-741d5e24eba2745d'
  FROM categories c WHERE c.name = 'paliwo'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 11.5, NULL, '2024-11-24', 'seed-e6a83e2cbf11c140'
  FROM categories c WHERE c.name = 'żabka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 185.0, NULL, '2024-11-24', 'seed-400a9bfa6f3e12df'
  FROM categories c WHERE c.name = 'biedronka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 20.0, NULL, '2024-11-24', 'seed-f47654319d42d5a6'
  FROM categories c WHERE c.name = 'ubrania'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 63.0, NULL, '2024-11-24', 'seed-abd5be95c414c055'
  FROM categories c WHERE c.name = 'biedronka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 69.0, 'pizza', '2024-11-24', 'seed-87110df2e9cf52b2'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 40.0, 'allegro smart', '2024-11-24', 'seed-3d368a41aa214267'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 257.0, 'prezent marta', '2024-11-24', 'seed-a99750d0a73006eb'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 53.0, NULL, '2024-11-24', 'seed-2e1c61009431f99d'
  FROM categories c WHERE c.name = 'biedronka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 50.0, NULL, '2024-11-24', 'seed-d99f1b04812e3e33'
  FROM categories c WHERE c.name = 'ubrania'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 20.0, NULL, '2024-11-24', 'seed-bec7a7d156afa213'
  FROM categories c WHERE c.name = 'żabka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 7.0, NULL, '2024-11-24', 'seed-0ef6f30df8abbd13'
  FROM categories c WHERE c.name = 'taxi'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 800.0, 'garnki', '2024-11-24', 'seed-5a50d252987fa434'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 9.0, NULL, '2024-11-24', 'seed-f2edd4aac6e2819f'
  FROM categories c WHERE c.name = 'taxi'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 200.0, NULL, '2024-11-24', 'seed-4bdbb43757f3a4bf'
  FROM categories c WHERE c.name = 'lekarz'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 23.0, NULL, '2024-11-24', 'seed-db60e9fdcff7905f'
  FROM categories c WHERE c.name = 'żabka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 100.0, 'kawa mama', '2024-11-24', 'seed-7f4e3ad8523dd783'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 4.0, NULL, '2024-11-24', 'seed-f06a2a63c970715e'
  FROM categories c WHERE c.name = 'przejazdy'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 15.0, 'apple', '2024-11-24', 'seed-ce0ba71f2015e557'
  FROM categories c WHERE c.name = 'biuro'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 71.0, 'prezent p eugeniusz', '2024-11-24', 'seed-8d5f91a5a6cbc5fc'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 250.0, 'uniqlo', '2024-11-24', 'seed-f5122c7f12200d89'
  FROM categories c WHERE c.name = 'ubrania'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 26.0, 'knajpa', '2024-11-24', 'seed-351a0ac59ec77b85'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 20.0, NULL, '2024-11-24', 'seed-68bdbd900fa19319'
  FROM categories c WHERE c.name = 'kawa'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 4.0, NULL, '2024-11-24', 'seed-8831a97adc834acf'
  FROM categories c WHERE c.name = 'przejazdy'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 36.0, NULL, '2024-11-24', 'seed-b0ec26231d4e9b82'
  FROM categories c WHERE c.name = 'kawa'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 10.0, NULL, '2024-11-24', 'seed-1af5e901df9b5a3a'
  FROM categories c WHERE c.name = 'rossman'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 15.0, 'kola', '2024-11-24', 'seed-738d315500ab5892'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 25.0, NULL, '2024-11-24', 'seed-c6890178466268e1'
  FROM categories c WHERE c.name = 'kawa'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 4.0, NULL, '2024-11-24', 'seed-cb44c8e3d22b7bbc'
  FROM categories c WHERE c.name = 'przejazdy'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 200.0, NULL, '2024-11-24', 'seed-e0ba5897605e396c'
  FROM categories c WHERE c.name = 'apteka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 13.0, NULL, '2024-11-24', 'seed-40ef448d56e2edb3'
  FROM categories c WHERE c.name = 'rossman'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 10.0, NULL, '2024-11-24', 'seed-ef8c81170e9ac1ef'
  FROM categories c WHERE c.name = 'ubrania'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 156.0, NULL, '2024-11-24', 'seed-a8019350acb06c14'
  FROM categories c WHERE c.name = 'kawa'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 249.0, 'badania', '2024-11-24', 'seed-5b700753ea4993d2'
  FROM categories c WHERE c.name = 'lekarz'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 20.0, NULL, '2024-11-24', 'seed-9af75af2a28126b6'
  FROM categories c WHERE c.name = 'biedronka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 100.0, 'siepomaga', '2024-11-24', 'seed-da034e4ecefdf361'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 178.0, NULL, '2024-11-24', 'seed-1052159fe773d69e'
  FROM categories c WHERE c.name = 'biedronka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 135.0, NULL, '2024-11-26', 'seed-a9905123686bbca8'
  FROM categories c WHERE c.name = 'kawa'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 200.0, 'prezent rodzice Tusi', '2024-11-26', 'seed-1f91e0b1b1f59e38'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 400.0, 'multisport', '2024-11-30', 'seed-2b00ef68ac829067'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 350.0, 'księgowa', '2024-11-30', 'seed-c331dbf6e9897d15'
  FROM categories c WHERE c.name = 'biuro'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 140.0, NULL, '2024-11-30', 'seed-6d25a409bf3c95ba'
  FROM categories c WHERE c.name = 'paliwo'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 100.0, NULL, '2024-11-30', 'seed-fc5aa0d34871b911'
  FROM categories c WHERE c.name = 'biedronka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 860.0, NULL, '2024-10-02', 'seed-ea4a4729b6267e7b'
  FROM categories c WHERE c.name = 'lekarz'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 600.0, 'nowa forma', '2024-10-02', 'seed-be376ec5a59ecff6'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 67.0, NULL, '2024-10-02', 'seed-05127331043f8921'
  FROM categories c WHERE c.name = 'apteka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 1382.0, NULL, '2024-10-02', 'seed-b07348e57c6bf595'
  FROM categories c WHERE c.name = 'mieszkanie'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 350.0, NULL, '2024-10-02', 'seed-4eff8f1c9b32f3c2'
  FROM categories c WHERE c.name = 'mieszkanie'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 8.0, NULL, '2024-10-02', 'seed-2084c8b3c1a7b62d'
  FROM categories c WHERE c.name = 'przejazdy'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 170.0, 'fryzjer', '2024-10-03', 'seed-36ea405b2d32d9fb'
  FROM categories c WHERE c.name = 'ubrania'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 360.0, 'drobny prezent', '2024-10-05', 'seed-2cc01a4fbeb75431'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 155.0, NULL, '2024-10-05', 'seed-9ec5ecb3e7b64224'
  FROM categories c WHERE c.name = 'paliwo'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 228.0, 'p4', '2024-10-05', 'seed-296fc0698db295fa'
  FROM categories c WHERE c.name = 'biuro'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 83.0, 'orange', '2024-10-05', 'seed-fc1acf56e97dd59f'
  FROM categories c WHERE c.name = 'biuro'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 3.0, NULL, '2024-10-05', 'seed-8f62763d483843d6'
  FROM categories c WHERE c.name = 'biedronka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 200.0, NULL, '2024-10-05', 'seed-67c24c5dce63f49b'
  FROM categories c WHERE c.name = 'lekarz'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 6.0, NULL, '2024-10-05', 'seed-f36411ead7032472'
  FROM categories c WHERE c.name = 'żabka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 12.0, NULL, '2024-10-05', 'seed-f108f6e26a0eee91'
  FROM categories c WHERE c.name = 'przejazdy'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 625.0, 'angielski', '2024-10-05', 'seed-811318ce036618c9'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 38.0, NULL, '2024-10-05', 'seed-c52bf528d6746cbd'
  FROM categories c WHERE c.name = 'rossman'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 8.0, NULL, '2024-10-05', 'seed-cbc5f3a2d4b29ca5'
  FROM categories c WHERE c.name = 'przejazdy'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 67.0, NULL, '2024-10-05', 'seed-2f3d3559ba71af7c'
  FROM categories c WHERE c.name = 'apteka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 30.0, 'ikea', '2024-10-05', 'seed-5ef28e7d0b115872'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 17.0, NULL, '2024-10-05', 'seed-8161e8c10bfeed4d'
  FROM categories c WHERE c.name = 'biedronka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 8.0, NULL, '2024-10-05', 'seed-360dac093f6b5274'
  FROM categories c WHERE c.name = 'przejazdy'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 78.0, 'blask', '2024-10-05', 'seed-917452ce7500ecc8'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 44.0, NULL, '2024-10-05', 'seed-e61f0bcbaf0611b7'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 140.0, 'paszport', '2024-10-05', 'seed-c1bb65ce14d05637'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 110.0, 'Kawa i książka ', '2024-10-06', 'seed-d7ca4782f6c3b1b3'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 208.0, NULL, '2024-10-07', 'seed-eed0d8052737d83c'
  FROM categories c WHERE c.name = 'kawa'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 3000.0, NULL, '2024-10-13', 'seed-4d6c1a311e2cef02'
  FROM categories c WHERE c.name = 'zus'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 126.0, NULL, '2024-10-13', 'seed-ea02674888bcb797'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 200.0, 'kamil', '2024-10-13', 'seed-5178215747f6dfc6'
  FROM categories c WHERE c.name = 'lekarz'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 100.0, 'inea', '2024-10-13', 'seed-2abd321e22a86525'
  FROM categories c WHERE c.name = 'mieszkanie'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 650.0, 'prezent mama', '2024-10-14', 'seed-f0fefef8bf022920'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 65.0, NULL, '2024-10-14', 'seed-6adb518a0d02ac04'
  FROM categories c WHERE c.name = 'apteka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 200.0, NULL, '2024-10-17', 'seed-e1743ebd12daae26'
  FROM categories c WHERE c.name = 'lekarz'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 350.0, NULL, '2024-10-17', 'seed-51254ec337aad00e'
  FROM categories c WHERE c.name = 'lekarz'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 140.0, NULL, '2024-10-17', 'seed-25445a2f0bd5525f'
  FROM categories c WHERE c.name = 'apteka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 3679.0, NULL, '2024-10-17', 'seed-09653a1fd8f66e7c'
  FROM categories c WHERE c.name = 'pit36'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 5602.0, NULL, '2024-10-17', 'seed-06e662796b88e4a3'
  FROM categories c WHERE c.name = 'vat'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 250.0, NULL, '2024-10-19', 'seed-293afa106da6128b'
  FROM categories c WHERE c.name = 'paliwo'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 180.0, NULL, '2024-10-19', 'seed-b2b9b2ed21dc2e59'
  FROM categories c WHERE c.name = 'paliwo'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 140.0, NULL, '2024-10-19', 'seed-0f2b3a47eeb7a641'
  FROM categories c WHERE c.name = 'apteka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 250.0, NULL, '2024-10-23', 'seed-a20f3c7c841841c3'
  FROM categories c WHERE c.name = 'biedronka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 1300.0, NULL, '2024-10-23', 'seed-2adfb6230464abc9'
  FROM categories c WHERE c.name = 'biedronka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 263.0, NULL, '2024-10-24', 'seed-0cf31fd10790e16e'
  FROM categories c WHERE c.name = 'kawa'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 350.0, NULL, '2024-10-29', 'seed-f966e006fc568355'
  FROM categories c WHERE c.name = 'biuro'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 400.0, 'multisport', '2024-10-29', 'seed-73dd46bae7b7c07b'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 200.0, 'kamil', '2024-10-29', 'seed-01e00f20620135ca'
  FROM categories c WHERE c.name = 'lekarz'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 600.0, 'Angielski', '2024-10-31', 'seed-f838c9dffe40ef6e'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 230.0, NULL, '2024-10-31', 'seed-754825db6dcd7f9f'
  FROM categories c WHERE c.name = 'paliwo'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 1382.0, NULL, '2024-09-03', 'seed-63217385ca457a72'
  FROM categories c WHERE c.name = 'mieszkanie'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 350.0, NULL, '2024-09-03', 'seed-d7935e4e1f8d51f5'
  FROM categories c WHERE c.name = 'mieszkanie'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 1200.0, NULL, '2024-09-03', 'seed-cab551337ef595cd'
  FROM categories c WHERE c.name = 'biedronka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 160.0, NULL, '2024-09-03', 'seed-f35a05a8eeacbdec'
  FROM categories c WHERE c.name = 'biedronka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 165.0, 'książka', '2024-09-03', 'seed-cb672ea6ebc51203'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 18.0, NULL, '2024-09-03', 'seed-cd274e8996ffbf93'
  FROM categories c WHERE c.name = 'rossman'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 9.0, NULL, '2024-09-03', 'seed-229c1f79bbb6a99c'
  FROM categories c WHERE c.name = 'biedronka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 60.0, NULL, '2024-09-03', 'seed-02a80ac8d07f7afe'
  FROM categories c WHERE c.name = 'biedronka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 175.0, 'multisport', '2024-09-03', 'seed-5d2fb1fe0f25981f'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 600.0, 'Nowa forma', '2024-09-04', 'seed-493cf049c6ef0a40'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 80.0, 'fryzjer', '2024-09-04', 'seed-beffa451ab841681'
  FROM categories c WHERE c.name = 'ubrania'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 9.0, NULL, '2024-09-04', 'seed-a92a8e2361952383'
  FROM categories c WHERE c.name = 'rossman'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 9.0, 'brystol i taśma do fotek', '2024-09-04', 'seed-20bebc166a37aa2a'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 187.0, NULL, '2024-09-04', 'seed-6ab424205052fc16'
  FROM categories c WHERE c.name = 'kawa'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 58.0, 'zdolni', '2024-09-07', 'seed-7dd20672b51a0c8a'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 227.55, 'p4', '2024-09-07', 'seed-2c4b6ecf70e29e78'
  FROM categories c WHERE c.name = 'biuro'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 82.0, 'orange', '2024-09-07', 'seed-440825d412b5f700'
  FROM categories c WHERE c.name = 'biuro'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 110.0, NULL, '2024-09-11', 'seed-2a7d94cf7887af49'
  FROM categories c WHERE c.name = 'rossman'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 50.0, NULL, '2024-09-12', 'seed-12b17e31e51b1f33'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 200.0, 'Kamil', '2024-09-12', 'seed-e71466617a29960c'
  FROM categories c WHERE c.name = 'lekarz'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 45.0, NULL, '2024-09-14', 'seed-a2c332060f907f02'
  FROM categories c WHERE c.name = 'rossman'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 60.0, NULL, '2024-09-14', 'seed-cded23369c47f3bd'
  FROM categories c WHERE c.name = 'apteka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 6227.0, NULL, '2024-09-14', 'seed-7219b95c2478c88e'
  FROM categories c WHERE c.name = 'vat'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 4131.0, NULL, '2024-09-14', 'seed-433e73a226a88782'
  FROM categories c WHERE c.name = 'pit36'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 3000.0, NULL, '2024-09-14', 'seed-cefc738fd8fab40e'
  FROM categories c WHERE c.name = 'zus'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 100.0, NULL, '2024-09-19', 'seed-b447c700f0c80938'
  FROM categories c WHERE c.name = 'mieszkanie'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 100.0, 'Frontend ', '2024-09-19', 'seed-af64555292347c54'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 200.0, NULL, '2024-09-19', 'seed-4a73106bd6a549cc'
  FROM categories c WHERE c.name = 'lekarz'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 460.0, NULL, '2024-09-19', 'seed-7e8a0b22a9441cdd'
  FROM categories c WHERE c.name = 'lekarz'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 300.0, NULL, '2024-09-22', 'seed-96264c9418727a24'
  FROM categories c WHERE c.name = 'paliwo'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 177.0, NULL, '2024-09-23', 'seed-498c618cb1509143'
  FROM categories c WHERE c.name = 'kawa'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 46.0, NULL, '2024-09-23', 'seed-1cc3738d2f6d4276'
  FROM categories c WHERE c.name = 'biedronka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 6.0, 'pićku', '2024-09-23', 'seed-3d18ebab8020a698'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 20.0, NULL, '2024-09-23', 'seed-9bf49755a93cee95'
  FROM categories c WHERE c.name = 'taxi'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 1200.0, NULL, '2024-09-23', 'seed-e2a3dd1bb3047a75'
  FROM categories c WHERE c.name = 'biedronka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 66.0, NULL, '2024-09-23', 'seed-48349066e9412048'
  FROM categories c WHERE c.name = 'biedronka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 300.0, 'prad', '2024-09-23', 'seed-31e07eb221ffd651'
  FROM categories c WHERE c.name = 'mieszkanie'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 44.0, 'wolt', '2024-09-23', 'seed-f510ca7cf16ce238'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 20.0, NULL, '2024-09-23', 'seed-184b638e0800c76b'
  FROM categories c WHERE c.name = 'biedronka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 70.0, NULL, '2024-09-23', 'seed-7c3e7e3ade830b70'
  FROM categories c WHERE c.name = 'rossman'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 40.0, NULL, '2024-09-23', 'seed-5d42f02d03b48045'
  FROM categories c WHERE c.name = 'biedronka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 20.0, 'medium', '2024-09-24', 'seed-da5e4da54a583f0c'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 40.0, 'disney', '2024-09-24', 'seed-824553327b2b92c5'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 100.0, 'frontendmasters', '2024-09-24', 'seed-8c49f86b6537d992'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 18.0, NULL, '2024-09-24', 'seed-ff26287e739da8e5'
  FROM categories c WHERE c.name = 'biedronka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 200.0, 'kamil', '2024-09-24', 'seed-93dda5188dcc17e7'
  FROM categories c WHERE c.name = 'lekarz'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 1603.0, 'x', '2024-09-24', 'seed-23c4f6ff39ae89d3'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 60.0, 'pitagoras', '2024-09-24', 'seed-84d026cfd2eb011e'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 25.0, 'biuro', '2024-09-24', 'seed-e8f9bd80f84618aa'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 180.0, 'szklanki', '2024-09-24', 'seed-41e9e8b8ddd86248'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 200.0, 'kamil', '2024-09-27', 'seed-840ef96992ccbc0d'
  FROM categories c WHERE c.name = 'lekarz'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 260.0, 'ikea', '2024-09-30', 'seed-17a9d587f7bc624d'
  FROM categories c WHERE c.name = 'mieszkanie'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 50.0, 'fotografia', '2024-09-30', 'seed-50817a0ee8f6875d'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 350.0, 'kancelaria', '2024-10-05', 'seed-c468789536b116f9'
  FROM categories c WHERE c.name = 'biuro'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 175.0, 'multisport', '2024-10-05', 'seed-72ad9eb6e0016b45'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 150.0, 'birr', '2024-10-05', 'seed-3146aa532f306565'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 200.0, 'kamil', '2024-10-05', 'seed-e86e575b60c4609e'
  FROM categories c WHERE c.name = 'lekarz'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 300.0, 'kluska', '2024-10-05', 'seed-1b0909fa54869494'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 1676.0, NULL, '2024-10-05', 'seed-c99d2b25de413159'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 1000.0, NULL, '2024-07-28', 'seed-47cb14d116e2801f'
  FROM categories c WHERE c.name = 'biedronka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 54.0, 'Aliexpress', '2024-07-29', 'seed-455a8181befc61be'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 173.0, NULL, '2024-07-30', 'seed-072c7883ed4e077a'
  FROM categories c WHERE c.name = 'kawa'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 170.0, 'powerbank', '2024-08-01', 'seed-caf1c06d933b0054'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 200.0, 'pranie kanapy', '2024-08-01', 'seed-b45cb827b5d4ea89'
  FROM categories c WHERE c.name = 'mieszkanie'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 37.0, NULL, '2024-08-01', 'seed-c875cdd5501306ce'
  FROM categories c WHERE c.name = 'biedronka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 28.0, NULL, '2024-08-01', 'seed-874ee5b31629051e'
  FROM categories c WHERE c.name = 'rossman'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 80.0, 'fryzjer', '2024-08-01', 'seed-20fb743b8c847114'
  FROM categories c WHERE c.name = 'ubrania'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 100.0, 'gawilk', '2024-08-01', 'seed-e627e3308daf3d2a'
  FROM categories c WHERE c.name = 'lekarz'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 1000.0, 'angielski', '2024-08-01', 'seed-ecbf786c4d26cd03'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 10.0, NULL, '2024-08-01', 'seed-cc47ea996926cab6'
  FROM categories c WHERE c.name = 'biedronka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 350.0, 'parking', '2024-08-01', 'seed-834b2a5248cc2da6'
  FROM categories c WHERE c.name = 'mieszkanie'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 1382.0, NULL, '2024-08-01', 'seed-7b0a9e24b6e799f4'
  FROM categories c WHERE c.name = 'mieszkanie'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 580.0, NULL, '2024-08-05', 'seed-884053679426a219'
  FROM categories c WHERE c.name = 'mieszkanie'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 140.0, 'jedzonko', '2024-08-05', 'seed-e14df227e1c9bc0a'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 72.0, NULL, '2024-08-05', 'seed-aa460a44e0a058d0'
  FROM categories c WHERE c.name = 'biedronka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 36.0, NULL, '2024-08-05', 'seed-32b20bd7bd290678'
  FROM categories c WHERE c.name = 'biedronka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 28.0, NULL, '2024-08-05', 'seed-3a51ad11252eed63'
  FROM categories c WHERE c.name = 'rossman'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 300.0, NULL, '2024-08-05', 'seed-e0660a9815c0cf16'
  FROM categories c WHERE c.name = 'biedronka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 255.0, 'lampka led części', '2024-08-05', 'seed-cd18f2f1289fd77b'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 105.0, 'ceramika', '2024-08-05', 'seed-40fe632424e93564'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 18.0, NULL, '2024-08-05', 'seed-9e67964167df7e5c'
  FROM categories c WHERE c.name = 'rossman'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 7.0, NULL, '2024-08-05', 'seed-a86dd3ac01228bdb'
  FROM categories c WHERE c.name = 'biedronka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 12.0, NULL, '2024-08-05', 'seed-f096c18b5e9529e1'
  FROM categories c WHERE c.name = 'biedronka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 350.0, 'ksiegowa', '2024-08-05', 'seed-09123494d47f4053'
  FROM categories c WHERE c.name = 'biuro'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 227.0, NULL, '2024-08-05', 'seed-ef2cf5c77add4204'
  FROM categories c WHERE c.name = 'paliwo'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 176.0, 'multisport', '2024-08-05', 'seed-f0e8a89d21ac1a1a'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 70.0, 'Pho', '2024-08-05', 'seed-b3168e7262d6cd1f'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 37.0, 'Kampucza', '2024-08-06', 'seed-d007abba40d07cec'
  FROM categories c WHERE c.name = 'rossman'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 78.0, NULL, '2024-08-07', 'seed-fd5c9275d91d53fa'
  FROM categories c WHERE c.name = 'biedronka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 600.0, 'Nowa forma', '2024-08-07', 'seed-cebb035f32ca0880'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 2332.0, NULL, '2024-08-08', 'seed-9b729e073734e27a'
  FROM categories c WHERE c.name = 'arval'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 228.0, 'p4', '2024-08-08', 'seed-45feb6c3effb575e'
  FROM categories c WHERE c.name = 'biuro'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 83.0, 'orange', '2024-08-08', 'seed-fe56bbaed2183f28'
  FROM categories c WHERE c.name = 'biuro'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 4159.0, NULL, '2024-08-14', 'seed-30723dcc92bd94a7'
  FROM categories c WHERE c.name = 'pit36'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 6204.0, NULL, '2024-08-14', 'seed-8de0583df8bdca9c'
  FROM categories c WHERE c.name = 'vat'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 100.0, 'inea', '2024-08-14', 'seed-54d2a9d2dff14698'
  FROM categories c WHERE c.name = 'mieszkanie'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 100.0, 'frontendmasters', '2024-08-14', 'seed-68c19add2eb7453a'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 64.0, 'autostrada', '2024-08-14', 'seed-b96de0ac149a8216'
  FROM categories c WHERE c.name = 'arval'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 213.0, NULL, '2024-08-14', 'seed-90b12e38020a48d7'
  FROM categories c WHERE c.name = 'paliwo'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 62.0, 'autostrada', '2024-08-14', 'seed-5a8dcf357b5da218'
  FROM categories c WHERE c.name = 'arval'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 155.0, NULL, '2024-08-14', 'seed-9cb2de7a22024e8e'
  FROM categories c WHERE c.name = 'paliwo'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 25.0, 'diody do lampki', '2024-08-14', 'seed-e4722c4ea33f3b4d'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 150.0, NULL, '2024-08-14', 'seed-555705faf375f8f7'
  FROM categories c WHERE c.name = 'biedronka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 240.0, 'prezent Martusia', '2024-08-14', 'seed-d97b8ee4c3a88fe5'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 5.0, NULL, '2024-08-14', 'seed-6278191939e31304'
  FROM categories c WHERE c.name = 'biedronka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 80.0, NULL, '2024-08-14', 'seed-272056a16cdd3900'
  FROM categories c WHERE c.name = 'biedronka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 100.0, 'prezent mieszko', '2024-08-14', 'seed-50d986ca9d7057a7'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 35.0, NULL, '2024-08-14', 'seed-a8c9151c1fa820ed'
  FROM categories c WHERE c.name = 'rossman'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 3000.0, NULL, '2024-08-14', 'seed-71aa62fc11d79531'
  FROM categories c WHERE c.name = 'zus'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 192.0, NULL, '2024-08-21', 'seed-28260e929b4670e1'
  FROM categories c WHERE c.name = 'kawa'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 200.0, 'psycholog', '2024-09-03', 'seed-6b1322ef40319c64'
  FROM categories c WHERE c.name = 'lekarz'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 250.0, 'dentysta', '2024-09-03', 'seed-df3b5d5850f6a261'
  FROM categories c WHERE c.name = 'lekarz'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 88.0, 'restauracja', '2024-09-03', 'seed-474b518edee627db'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 20.0, 'bielty', '2024-09-03', 'seed-75ece6e0179c8cf9'
  FROM categories c WHERE c.name = 'przejazdy'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 16.0, 'lody', '2024-09-03', 'seed-93e9681d0ba62da7'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 10.0, NULL, '2024-09-03', 'seed-17f9bc0ef9dd4b1d'
  FROM categories c WHERE c.name = 'przejazdy'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 21.0, NULL, '2024-09-03', 'seed-bfe950679973a519'
  FROM categories c WHERE c.name = 'taxi'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 20.0, NULL, '2024-09-03', 'seed-740c72d3cf3f5c43'
  FROM categories c WHERE c.name = 'biuro'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 108.0, NULL, '2024-09-03', 'seed-20bafc741a61374e'
  FROM categories c WHERE c.name = 'biedronka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 11.0, NULL, '2024-09-03', 'seed-2a2d2dd3eeecfdb4'
  FROM categories c WHERE c.name = 'żabka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 20.0, NULL, '2024-09-03', 'seed-4c6dd1d9fbf9d1b0'
  FROM categories c WHERE c.name = 'biedronka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 90.0, 'kubek martusia', '2024-09-03', 'seed-29743e46b9170d9a'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 20.0, 'parking', '2024-09-03', 'seed-ad61932292ee1012'
  FROM categories c WHERE c.name = 'arval'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 30.0, 'książka', '2024-09-03', 'seed-8ce1d919eba012b0'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 19.0, NULL, '2024-09-03', 'seed-eba75be964668f2a'
  FROM categories c WHERE c.name = 'rossman'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 37.0, 'mc donalds', '2024-09-03', 'seed-72fdc32806ee85dd'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 200.0, 'psycholog', '2024-09-03', 'seed-e87cfed730bc949b'
  FROM categories c WHERE c.name = 'lekarz'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 10.0, NULL, '2024-09-03', 'seed-4bede5b03fbdfee4'
  FROM categories c WHERE c.name = 'przejazdy'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 51.0, 'lutowanie', '2024-09-03', 'seed-a7be66c855723216'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 50.0, 'prime', '2024-09-03', 'seed-09460bd77aef0b74'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 7.0, NULL, '2024-09-03', 'seed-80415bde911b079e'
  FROM categories c WHERE c.name = 'żabka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 20.0, NULL, '2024-09-03', 'seed-aaae525b57fc1341'
  FROM categories c WHERE c.name = 'rossman'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 20.0, 'glupotty', '2024-09-03', 'seed-de0b78decf269e10'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 33.33, 'meetup', '2024-09-03', 'seed-5b80c21267eebfc2'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 30.0, 'allegro lutowanie', '2024-09-03', 'seed-736b9d755b0da643'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 46.0, 'pyszne', '2024-09-03', 'seed-72810d06c955460a'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 9.0, 'kompucza', '2024-09-03', 'seed-278f443cc1042179'
  FROM categories c WHERE c.name = 'rossman'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 22.0, 'piwna stopa', '2024-09-03', 'seed-9b7c26e721e30051'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 51.0, 'knajpa', '2024-09-03', 'seed-a61c86c20b428c91'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 80.0, 'modra', '2024-09-03', 'seed-ccf48ecffd5319d2'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 58.0, 'keycapy', '2024-09-03', 'seed-376b28966793357a'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 12.0, NULL, '2024-09-03', 'seed-2acca3bf0cc51a9d'
  FROM categories c WHERE c.name = 'taxi'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 17.0, NULL, '2024-09-03', 'seed-fd095583ebd1d2e8'
  FROM categories c WHERE c.name = 'taxi'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 65.0, 'tsunami', '2024-09-03', 'seed-ba94732d5ff0b6f4'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 18.0, NULL, '2024-09-03', 'seed-39283c35c0802ff8'
  FROM categories c WHERE c.name = 'rossman'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 16.0, 'myjnia', '2024-09-03', 'seed-0206c2e0e6abe7fd'
  FROM categories c WHERE c.name = 'arval'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 16.0, NULL, '2024-09-03', 'seed-cd98c49759389934'
  FROM categories c WHERE c.name = 'biedronka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 20.0, 'piwko', '2024-09-03', 'seed-203dd8b05892eee7'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 41.0, 'smaczki dlapsa', '2024-09-03', 'seed-47204d45711c571d'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 15.0, 'apple', '2024-09-03', 'seed-85dec08d3307e40b'
  FROM categories c WHERE c.name = 'biuro'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 32.0, NULL, '2024-09-03', 'seed-3dcf5e4aaba5e6d8'
  FROM categories c WHERE c.name = 'biedronka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 151.0, 'auchan kuźnia', '2024-09-03', 'seed-330344348a31c041'
  FROM categories c WHERE c.name = 'biedronka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 38.0, NULL, '2024-09-03', 'seed-799a2554bb4942f7'
  FROM categories c WHERE c.name = 'apteka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 35.0, NULL, '2024-09-03', 'seed-ce8e0473620b1f68'
  FROM categories c WHERE c.name = 'rossman'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 82.0, NULL, '2024-09-03', 'seed-bcb180fbd7178e82'
  FROM categories c WHERE c.name = 'paliwo'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 158.0, NULL, '2024-09-03', 'seed-083ff07f9b28e766'
  FROM categories c WHERE c.name = 'paliwo'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 196.0, NULL, '2024-09-03', 'seed-8d6ff8509a234cf2'
  FROM categories c WHERE c.name = 'paliwo'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 350.0, NULL, '2024-09-03', 'seed-d4e6cf63f533b7a0'
  FROM categories c WHERE c.name = 'biuro'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 230.0, 'myjnia', '2024-09-03', 'seed-52ea11dbac39fb2a'
  FROM categories c WHERE c.name = 'arval'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 192.0, NULL, '2024-09-03', 'seed-54d9c2ee5bc7ae75'
  FROM categories c WHERE c.name = 'paliwo'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 179.0, NULL, '2024-09-03', 'seed-74e53e56a9ccfb65'
  FROM categories c WHERE c.name = 'paliwo'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 46.0, NULL, '2024-09-03', 'seed-7badaaecb3a54293'
  FROM categories c WHERE c.name = 'paliwo'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 238.0, NULL, '2024-09-03', 'seed-4bb23ab63da501b8'
  FROM categories c WHERE c.name = 'paliwo'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 70.0, 'filtry', '2024-07-01', 'seed-18111843158469dd'
  FROM categories c WHERE c.name = 'biedronka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 192.0, NULL, '2024-07-01', 'seed-d881ee61fd9484cc'
  FROM categories c WHERE c.name = 'kawa'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 1382.0, NULL, '2024-07-03', 'seed-6957074c6cb18d9a'
  FROM categories c WHERE c.name = 'mieszkanie'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 350.0, NULL, '2024-07-03', 'seed-efe9525a8c51da75'
  FROM categories c WHERE c.name = 'mieszkanie'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 340.0, 'ikea', '2024-07-03', 'seed-e5cd5007a437dfc0'
  FROM categories c WHERE c.name = 'mieszkanie'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 210.0, 'zigbee', '2024-07-03', 'seed-d4cc47eedddabc33'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 2333.0, NULL, '2024-07-04', 'seed-37ab065cb405764d'
  FROM categories c WHERE c.name = 'arval'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 83.0, 'orange', '2024-07-04', 'seed-4f932d628c629a4c'
  FROM categories c WHERE c.name = 'biuro'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 233.0, 'play', '2024-07-04', 'seed-9f10c67d961e5e32'
  FROM categories c WHERE c.name = 'biuro'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 1000.0, NULL, '2024-07-04', 'seed-df02eb5fd76db93f'
  FROM categories c WHERE c.name = 'biedronka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 200.0, 'jula', '2024-07-04', 'seed-0540a4cd9c309122'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 100.0, NULL, '2024-07-11', 'seed-cf9c3368b78dcfe7'
  FROM categories c WHERE c.name = 'mieszkanie'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 500.0, 'Knajpa', '2024-07-11', 'seed-4e4ece4c0cb25a29'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 160.0, NULL, '2024-07-12', 'seed-111ccacb43612e20'
  FROM categories c WHERE c.name = 'arval'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 330.0, 'restauracja rudy', '2024-07-14', 'seed-8742b1dc950d135e'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 167.0, 'arduino ', '2024-07-14', 'seed-9232cb6da48f09fa'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 17.0, 'chilep', '2024-07-14', 'seed-b98d5cadbababe67'
  FROM categories c WHERE c.name = 'biedronka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 89.0, 'filamenty', '2024-07-14', 'seed-69453752a801881f'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 600.0, 'nowa forma', '2024-07-14', 'seed-122ca89c2e5ed087'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 93.0, 'strag', '2024-07-14', 'seed-dd62def7b1061cbc'
  FROM categories c WHERE c.name = 'kawa'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 8.0, 'lody', '2024-07-14', 'seed-158da75fa4e4bae3'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 136.0, 'ikea', '2024-07-14', 'seed-7e8f1cfc6457b1d6'
  FROM categories c WHERE c.name = 'mieszkanie'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 237.0, NULL, '2024-07-14', 'seed-0536a500ab93b10b'
  FROM categories c WHERE c.name = 'paliwo'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 120.0, NULL, '2024-07-14', 'seed-8c195c99daf8bd37'
  FROM categories c WHERE c.name = 'paliwo'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 76.0, NULL, '2024-07-15', 'seed-3bdb8c3898445c93'
  FROM categories c WHERE c.name = 'biedronka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 5365.0, NULL, '2024-07-16', 'seed-22aae18236a8fd1d'
  FROM categories c WHERE c.name = 'vat'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 3641.0, NULL, '2024-07-16', 'seed-d225b29fc756c852'
  FROM categories c WHERE c.name = 'pit36'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 2913.03, NULL, '2024-07-16', 'seed-d8dcb2ef2034ca38'
  FROM categories c WHERE c.name = 'zus'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 100.0, NULL, '2024-07-18', 'seed-c2110c967b2acee6'
  FROM categories c WHERE c.name = 'lekarz'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 100.0, 'Shelter', '2024-07-18', 'seed-405c288afbc6de13'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 2000.0, 'Jula', '2024-07-18', 'seed-18b847dfb734fb07'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 200.0, 'Autka', '2024-07-27', 'seed-67593fa96fdd5854'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 175.0, 'multisport', '2024-07-28', 'seed-a54916413cb08281'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 205.0, NULL, '2024-07-28', 'seed-34f4aeb3d02473d1'
  FROM categories c WHERE c.name = 'paliwo'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 267.0, NULL, '2024-07-28', 'seed-d1b46726da73c9e3'
  FROM categories c WHERE c.name = 'paliwo'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 160.0, 'przegląd', '2024-07-28', 'seed-b95bec7e83a7dab7'
  FROM categories c WHERE c.name = 'arval'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 30.0, NULL, '2024-07-28', 'seed-9b41b2082a4a6d81'
  FROM categories c WHERE c.name = 'żabka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 20.0, NULL, '2024-07-28', 'seed-64d7efcc8486701e'
  FROM categories c WHERE c.name = 'biedronka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 80.0, NULL, '2024-07-28', 'seed-5dd6689a4bade0a4'
  FROM categories c WHERE c.name = 'biedronka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 22.0, NULL, '2024-07-28', 'seed-c29695138cc528b0'
  FROM categories c WHERE c.name = 'biedronka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 5.0, NULL, '2024-07-28', 'seed-2e9579ae9166bd34'
  FROM categories c WHERE c.name = 'żabka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 22.0, NULL, '2024-07-28', 'seed-d18f92a2bb2a609f'
  FROM categories c WHERE c.name = 'biedronka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 52.0, 'czujniki', '2024-07-28', 'seed-22178fc0a42e15ad'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 85.0, NULL, '2024-07-28', 'seed-7a31e745c1e5f1ad'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 5.0, NULL, '2024-07-28', 'seed-ee40d08263127431'
  FROM categories c WHERE c.name = 'żabka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 134.0, NULL, '2024-07-28', 'seed-68e1b8e9af13b907'
  FROM categories c WHERE c.name = 'kawa'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 30.0, NULL, '2024-07-28', 'seed-bdca45bdcd5d13e1'
  FROM categories c WHERE c.name = 'rossman'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 3.0, NULL, '2024-07-28', 'seed-e3a74141bbe80000'
  FROM categories c WHERE c.name = 'żabka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 18.0, NULL, '2024-07-28', 'seed-d7d0b883a790fc24'
  FROM categories c WHERE c.name = 'taxi'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 15.0, 'apple', '2024-07-28', 'seed-2adfd6e1fe7ed4ae'
  FROM categories c WHERE c.name = 'biuro'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 14.0, NULL, '2024-07-28', 'seed-1428f4a467d19606'
  FROM categories c WHERE c.name = 'apteka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 400.0, 'garnki', '2024-07-28', 'seed-56b118ac7193e1b4'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 76.0, NULL, '2024-07-28', 'seed-26e83280c5a29184'
  FROM categories c WHERE c.name = 'biedronka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 10.0, 'castorama', '2024-07-28', 'seed-a1714d77ee5309f2'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 35.0, NULL, '2024-07-28', 'seed-a38e5cf724f842b4'
  FROM categories c WHERE c.name = 'biedronka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 70.0, 'buty siłka', '2024-07-28', 'seed-7be98ad413111d41'
  FROM categories c WHERE c.name = 'ubrania'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 55.0, 'wino', '2024-07-28', 'seed-1b1f543d93bea64d'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 5.0, 'parking', '2024-07-28', 'seed-490520f90b70dacb'
  FROM categories c WHERE c.name = 'arval'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 20.0, 'chliep', '2024-07-28', 'seed-84bb92114873cec6'
  FROM categories c WHERE c.name = 'biedronka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 17.0, 'czarny chliep', '2024-07-28', 'seed-5bc545ebb9f6ab98'
  FROM categories c WHERE c.name = 'biedronka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 9.0, NULL, '2024-07-28', 'seed-9fdbb64ebae3e6e2'
  FROM categories c WHERE c.name = 'rossman'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 17.0, 'inpost waga', '2024-07-28', 'seed-f91c151e0ec74d5a'
  FROM categories c WHERE c.name = 'biuro'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 8.0, 'lody', '2024-07-28', 'seed-b32cdd367c9093dc'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 200.0, 'japfest', '2024-07-28', 'seed-3f4cb821386b6bc8'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 130.0, 'koszulka', '2024-07-28', 'seed-f72271f332b39750'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 30.0, NULL, '2024-07-28', 'seed-d7d4c15bdfba2198'
  FROM categories c WHERE c.name = 'taxi'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 40.0, 'burger', '2024-07-28', 'seed-7eb8bbbf7a77b8f5'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 200.0, 'frontendmasters & disney', '2024-07-28', 'seed-b0e9aeb9bb380cc4'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 460.0, 'prąd ', '2024-07-28', 'seed-28e2185bf2af6498'
  FROM categories c WHERE c.name = 'mieszkanie'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 16.0, 'myjnia', '2024-07-28', 'seed-7808c358b841ac21'
  FROM categories c WHERE c.name = 'arval'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 200.0, NULL, '2024-07-28', 'seed-e5ae75d63fda8abf'
  FROM categories c WHERE c.name = 'biedronka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 20.0, ' miedium', '2024-07-28', 'seed-177804c9381df175'
  FROM categories c WHERE c.name = 'biuro'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 30.0, 'disney ', '2024-07-28', 'seed-94058538a040e18c'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 100.0, 'frontendmastsers', '2024-07-28', 'seed-9f2a9a115e537a0a'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 165.0, NULL, '2024-07-28', 'seed-18c082ff81ebfbbf'
  FROM categories c WHERE c.name = 'biedronka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 22.0, NULL, '2024-07-28', 'seed-0b0ca1e953fca297'
  FROM categories c WHERE c.name = 'biedronka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 216.0, 'Marta?', '2024-07-28', 'seed-8479c5e75dea64b4'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 433.0, NULL, '2024-07-28', 'seed-e8fa39741fd90fce'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 50.0, NULL, '2024-07-29', 'seed-0c7c7e1c31f1eacd'
  FROM categories c WHERE c.name = 'biedronka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 1000.0, NULL, '2024-05-30', 'seed-d7da949d58829bcf'
  FROM categories c WHERE c.name = 'biedronka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 163.0, NULL, '2024-05-31', 'seed-9318b7375aaf6345'
  FROM categories c WHERE c.name = 'kawa'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 680.0, 'nowa forma', '2024-05-31', 'seed-b014b886811f057f'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 58.0, 'zdolni', '2024-05-31', 'seed-a2c9992027113e6f'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 80.0, 'kabel i ladowarka ', '2024-06-02', 'seed-108f6e351dd52566'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 100.0, 'AirPods', '2024-06-03', 'seed-369859c7db39d67a'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 236.0, 'play', '2024-06-04', 'seed-8e64a5d36bc840f1'
  FROM categories c WHERE c.name = 'biuro'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 83.0, 'orange', '2024-06-04', 'seed-ebddd54639772f8c'
  FROM categories c WHERE c.name = 'biuro'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 1382.0, NULL, '2024-06-04', 'seed-296445a9f5b03e8f'
  FROM categories c WHERE c.name = 'mieszkanie'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 350.0, NULL, '2024-06-04', 'seed-3fe9156ab308c043'
  FROM categories c WHERE c.name = 'mieszkanie'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 15.0, NULL, '2024-06-06', 'seed-6c570d92c6e11e18'
  FROM categories c WHERE c.name = 'żabka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 2335.0, NULL, '2024-06-06', 'seed-a825a331fc65df07'
  FROM categories c WHERE c.name = 'arval'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 20.0, NULL, '2024-06-08', 'seed-d57c04a37be919d9'
  FROM categories c WHERE c.name = 'żabka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 33.0, NULL, '2024-06-08', 'seed-a3f1be6f14dfd88e'
  FROM categories c WHERE c.name = 'biedronka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 100.0, NULL, '2024-06-09', 'seed-74a2ff6f9655572c'
  FROM categories c WHERE c.name = 'mieszkanie'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 60.0, NULL, '2024-06-10', 'seed-a5f22713f5e9f2c6'
  FROM categories c WHERE c.name = 'biedronka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 20.0, NULL, '2024-06-10', 'seed-0ddb4c062139ba95'
  FROM categories c WHERE c.name = 'biedronka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 80.0, NULL, '2024-06-10', 'seed-322b08f65994a017'
  FROM categories c WHERE c.name = 'apteka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 60.0, 'Zdolni', '2024-06-11', 'seed-072a204f6019086d'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 30.0, NULL, '2024-06-11', 'seed-f9d102d62f6d2e6f'
  FROM categories c WHERE c.name = 'biedronka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 15.0, NULL, '2024-06-13', 'seed-e416cb346b6846e5'
  FROM categories c WHERE c.name = 'żabka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 36.0, 'bankook', '2024-06-13', 'seed-789eebea744594a7'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 20.0, NULL, '2024-06-13', 'seed-369fa7792fa2334c'
  FROM categories c WHERE c.name = 'rossman'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 50.0, NULL, '2024-06-13', 'seed-72533f3bd09efbf4'
  FROM categories c WHERE c.name = 'taxi'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 370.0, 'Studio', '2024-06-14', 'seed-7d2034a41a6c7d87'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 60.0, 'Bankook', '2024-06-15', 'seed-1457eca7e79179c1'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 40.0, NULL, '2024-06-15', 'seed-a477548a2d003914'
  FROM categories c WHERE c.name = 'biedronka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 70.0, NULL, '2024-06-15', 'seed-017855e43b09ae63'
  FROM categories c WHERE c.name = 'biedronka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 55.0, 'mokra wloszka', '2024-06-16', 'seed-8c377d96dc022376'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 3868.0, NULL, '2024-06-16', 'seed-6d2b46e4be4b0a2f'
  FROM categories c WHERE c.name = 'pit36'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 6208.0, NULL, '2024-06-16', 'seed-d773da62708b3418'
  FROM categories c WHERE c.name = 'vat'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 2914.0, NULL, '2024-06-16', 'seed-08fc8c993795d032'
  FROM categories c WHERE c.name = 'zus'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 12.0, NULL, '2024-06-16', 'seed-a9bc538cb4307a48'
  FROM categories c WHERE c.name = 'pit36'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 180.0, NULL, '2024-06-22', 'seed-43f1460b3ed4814f'
  FROM categories c WHERE c.name = 'biedronka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 168.0, 'waga', '2024-06-22', 'seed-efd789dd4a030968'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 140.0, NULL, '2024-06-24', 'seed-8617859e46a1d3f5'
  FROM categories c WHERE c.name = 'paliwo'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 50.0, NULL, '2024-06-24', 'seed-d6fd654de415962c'
  FROM categories c WHERE c.name = 'biedronka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 100.0, 'Falla', '2024-06-25', 'seed-52ccb6ade1d747c7'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 90.0, 'prezent andrzej', '2024-06-25', 'seed-3cab54758ba09933'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 95.0, NULL, '2024-06-25', 'seed-e1e0f5a0638d5e8f'
  FROM categories c WHERE c.name = 'biedronka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 100.0, NULL, '2024-06-30', 'seed-c7b5ca63839a1b32'
  FROM categories c WHERE c.name = 'paliwo'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 175.0, 'mutlisport', '2024-06-30', 'seed-81823fb011d79479'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 348.0, NULL, '2024-06-30', 'seed-611b981b8a041195'
  FROM categories c WHERE c.name = 'biuro'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 68.0, NULL, '2024-06-30', 'seed-b68646862433912e'
  FROM categories c WHERE c.name = 'biedronka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 131.0, NULL, '2024-06-30', 'seed-98b7cb2689b88317'
  FROM categories c WHERE c.name = 'biedronka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 3.0, NULL, '2024-06-30', 'seed-0ed4ce6f3e4b2cd3'
  FROM categories c WHERE c.name = 'apteka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 12.0, NULL, '2024-06-30', 'seed-c8bd725ebb6cd898'
  FROM categories c WHERE c.name = 'arval'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 200.0, 'suwmiarka', '2024-06-30', 'seed-a4026a5a56cc5a9a'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 180.0, 'fillament', '2024-06-30', 'seed-c00e0454cf3cff65'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 76.0, 'fillament', '2024-06-30', 'seed-b991a250caf0e387'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 90.0, 'fryzjer', '2024-06-30', 'seed-21ff344b715bd148'
  FROM categories c WHERE c.name = 'ubrania'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 10.0, NULL, '2024-06-30', 'seed-cd5706f83dab1c30'
  FROM categories c WHERE c.name = 'biedronka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 2330.0, 'leasing', '2024-05-05', 'seed-9275f5aed3ef37c7'
  FROM categories c WHERE c.name = 'arval'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 250.0, NULL, '2024-05-05', 'seed-05a3b921166999c8'
  FROM categories c WHERE c.name = 'paliwo'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 250.0, 'p4', '2024-05-05', 'seed-21603c4062ab87cb'
  FROM categories c WHERE c.name = 'biuro'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 83.0, 'orange', '2024-05-05', 'seed-1be7cee5ebd4641b'
  FROM categories c WHERE c.name = 'biuro'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 200.0, NULL, '2024-05-05', 'seed-adfff29128b07f28'
  FROM categories c WHERE c.name = 'biedronka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 350.0, 'parking', '2024-05-05', 'seed-f0db6e3a40c6579c'
  FROM categories c WHERE c.name = 'mieszkanie'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 1382.0, NULL, '2024-05-05', 'seed-b0e4d436922fe9fd'
  FROM categories c WHERE c.name = 'mieszkanie'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 30.0, 'Kfc', '2024-05-05', 'seed-7d7b3e9104998625'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 90.0, NULL, '2024-05-05', 'seed-8928d212bd72d692'
  FROM categories c WHERE c.name = 'paliwo'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 217.0, 'Części do robota', '2024-05-07', 'seed-340240cf7c0e402e'
  FROM categories c WHERE c.name = 'mieszkanie'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 333.0, 'prezent murrtusia', '2024-05-09', 'seed-b43c95f09e393c40'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 13.0, NULL, '2024-05-09', 'seed-e627c38b9f2bad30'
  FROM categories c WHERE c.name = 'żabka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 265.0, 'pad', '2024-05-09', 'seed-d88f42035bba4780'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 100.0, 'frontendmasters', '2024-05-09', 'seed-ca359d13c5dddb0c'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 100.0, 'inea', '2024-05-09', 'seed-353eb1af19202350'
  FROM categories c WHERE c.name = 'mieszkanie'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 246.0, 'upoważnienie', '2024-05-09', 'seed-c1115df79680513a'
  FROM categories c WHERE c.name = 'arval'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 19.0, NULL, '2024-05-09', 'seed-df3ad539627ac3a9'
  FROM categories c WHERE c.name = 'biedronka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 65.0, NULL, '2024-05-13', 'seed-ecca2e9b03154c0c'
  FROM categories c WHERE c.name = 'biedronka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 550.0, 'Jula', '2024-05-13', 'seed-aca5fda7dd3a2c8c'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 180.0, NULL, '2024-05-13', 'seed-b0e5ffb4f9fc7bd5'
  FROM categories c WHERE c.name = 'apteka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 55.0, NULL, '2024-05-15', 'seed-5cac35a3b2483632'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 58.0, NULL, '2024-05-17', 'seed-928f284ade13dbc2'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 7677.78, NULL, '2024-05-18', 'seed-0cc509c374fe4619'
  FROM categories c WHERE c.name = 'zus'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 12.0, NULL, '2024-05-18', 'seed-2f3a7ed792fcc627'
  FROM categories c WHERE c.name = 'pit36'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 80.0, 'Jula', '2024-05-20', 'seed-57418111c260ef7c'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 2011.0, NULL, '2024-05-20', 'seed-91149f0aed899f9b'
  FROM categories c WHERE c.name = 'vat'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 1714.0, NULL, '2024-05-20', 'seed-b2608c3cdbd8b06d'
  FROM categories c WHERE c.name = 'pit36'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 110.0, NULL, '2024-05-20', 'seed-67e1c2f536f354c3'
  FROM categories c WHERE c.name = 'biedronka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 100.0, NULL, '2024-05-20', 'seed-39e10c9e50116463'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 750.0, 'angielski', '2024-05-30', 'seed-5fa6b50f02e61e58'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 100.0, NULL, '2024-05-30', 'seed-86bd261b29df03a6'
  FROM categories c WHERE c.name = 'apteka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 80.0, 'temu', '2024-05-30', 'seed-a9412bd154e6dbcf'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 200.0, 'dermatolog', '2024-05-30', 'seed-f0d6b191c306f6fe'
  FROM categories c WHERE c.name = 'lekarz'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 30.0, 'czarity', '2024-05-30', 'seed-ca37bbc0dee02ed0'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 30.0, NULL, '2024-05-30', 'seed-87df78798f7ef241'
  FROM categories c WHERE c.name = 'biedronka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 200.0, 'jula', '2024-05-30', 'seed-b0292738800cb5c7'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 208.0, 'prezent tusia', '2024-05-30', 'seed-3267d374a86aa8c4'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 9.0, NULL, '2024-05-30', 'seed-d077edc89a09ac18'
  FROM categories c WHERE c.name = 'żabka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 95.0, 'tort', '2024-05-30', 'seed-53ffcf0385d7037d'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 80.0, 'koc piknik', '2024-05-30', 'seed-3866161b0fb749af'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 80.0, 'ziarna', '2024-05-30', 'seed-19bc5eeda78d2825'
  FROM categories c WHERE c.name = 'kawa'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 20.0, 'parking', '2024-05-30', 'seed-eea10a8dcbd0fe6c'
  FROM categories c WHERE c.name = 'arval'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 19.0, NULL, '2024-05-30', 'seed-ea6abb7628c65232'
  FROM categories c WHERE c.name = 'biedronka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 15.0, NULL, '2024-05-30', 'seed-75fa90a906e1c079'
  FROM categories c WHERE c.name = 'żabka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 150.0, 'kwiaty', '2024-05-30', 'seed-df3e499806e3c638'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 9.0, 'torebka', '2024-05-30', 'seed-720c4fa6862de036'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 150.0, NULL, '2024-05-30', 'seed-f266553dcd87bb54'
  FROM categories c WHERE c.name = 'mieszkanie'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 85.0, 'prezenty', '2024-05-30', 'seed-da2ff26dbc0f969d'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 58.0, 'prezent tusia', '2024-05-30', 'seed-07a3b5b36dcfd20b'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 17.0, NULL, '2024-05-30', 'seed-59b947ad397e0695'
  FROM categories c WHERE c.name = 'żabka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 9.0, NULL, '2024-05-30', 'seed-2d8a1e0c4c043f5e'
  FROM categories c WHERE c.name = 'żabka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 100.0, 'śniadanie Jula', '2024-05-30', 'seed-e4b9c1ac9cbf302d'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 110.0, NULL, '2024-05-30', 'seed-0ce0d19a5ec9f7af'
  FROM categories c WHERE c.name = 'biedronka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 25.0, 'meet.js', '2024-05-30', 'seed-a4de635708584157'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 157.0, 'piknik', '2024-05-30', 'seed-7c7f22e2c7ee3cf0'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 22.0, 'lody', '2024-05-30', 'seed-b3d9082e3286998f'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 150.0, NULL, '2024-05-30', 'seed-bfcf2841e2848900'
  FROM categories c WHERE c.name = 'biedronka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 5.0, NULL, '2024-05-30', 'seed-94e7e4a2d24b2e63'
  FROM categories c WHERE c.name = 'arval'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 9.0, NULL, '2024-05-30', 'seed-46a6a724069f1cdf'
  FROM categories c WHERE c.name = 'żabka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 33.0, 'wolt', '2024-05-30', 'seed-eafa8e099129949b'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 58.0, 'wolt', '2024-05-30', 'seed-f1a8dd4e65dd4f7c'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 30.0, NULL, '2024-05-30', 'seed-b4e524fbf4da0eae'
  FROM categories c WHERE c.name = 'biedronka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 15.0, 'apple', '2024-05-30', 'seed-ce3d42af469399a4'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 23.0, NULL, '2024-05-30', 'seed-ed6e63e76f25763e'
  FROM categories c WHERE c.name = 'żabka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 47.0, ' wolt', '2024-05-30', 'seed-02ce2434a015584b'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 55.0, 'wolt', '2024-05-30', 'seed-c7b04c63aa887fa8'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 70.0, NULL, '2024-05-30', 'seed-cd68dc608b6f83f8'
  FROM categories c WHERE c.name = 'rossman'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 60.0, NULL, '2024-05-30', 'seed-7e9d188a1929de85'
  FROM categories c WHERE c.name = 'biedronka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 130.0, 'prezenta Agatka', '2024-05-30', 'seed-bb7846a3a886503d'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 14.0, NULL, '2024-05-30', 'seed-b43de723d3778430'
  FROM categories c WHERE c.name = 'biedronka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 20.0, NULL, '2024-05-30', 'seed-170b258ee5236e64'
  FROM categories c WHERE c.name = 'żabka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 45.0, 'kwiaty', '2024-05-30', 'seed-2cbf785ab1e85157'
  FROM categories c WHERE c.name = 'mieszkanie'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 174.0, 'multisport', '2024-05-30', 'seed-12a16f787f744f98'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 347.0, NULL, '2024-05-30', 'seed-96c523b0de96572b'
  FROM categories c WHERE c.name = 'biuro'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 34.22, NULL, '2024-05-30', 'seed-c72be80301d9d586'
  FROM categories c WHERE c.name = 'biedronka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 100.0, NULL, '2024-04-03', 'seed-2b6d0a4d12d598c2'
  FROM categories c WHERE c.name = 'biedronka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 400.0, 'usd', '2024-04-03', 'seed-5c9a5fd7972da829'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 10.0, NULL, '2024-04-03', 'seed-b0f26736478eec22'
  FROM categories c WHERE c.name = 'żabka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 2332.0, NULL, '2024-04-04', 'seed-4096da2cd13d4d51'
  FROM categories c WHERE c.name = 'arval'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 244.0, 'play', '2024-04-04', 'seed-d10baa88c86a51aa'
  FROM categories c WHERE c.name = 'biuro'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 83.0, 'orange', '2024-04-04', 'seed-ab3ccc0ee43c17f0'
  FROM categories c WHERE c.name = 'biuro'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 1382.0, NULL, '2024-04-04', 'seed-219c8f0b78920346'
  FROM categories c WHERE c.name = 'mieszkanie'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 70.0, 'esim', '2024-04-04', 'seed-f5380db3ee9c5cea'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 40.0, NULL, '2024-04-04', 'seed-8ddf7ce13af46de8'
  FROM categories c WHERE c.name = 'kawa'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 25.0, NULL, '2024-04-04', 'seed-a3c6db8fbe9b3f88'
  FROM categories c WHERE c.name = 'taxi'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 470.0, NULL, '2024-04-10', 'seed-aec321a2f94c855d'
  FROM categories c WHERE c.name = 'ubrania'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 290.0, NULL, '2024-04-10', 'seed-6bc0dfb1c0fa295b'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 550.0, NULL, '2024-04-10', 'seed-d50d7e42406d55f6'
  FROM categories c WHERE c.name = 'mieszkanie'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 315.0, NULL, '2024-04-23', 'seed-50433b5687c3a8bf'
  FROM categories c WHERE c.name = 'paliwo'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 95.0, 'Szko nintendo', '2024-04-23', 'seed-bdc336bd6f090f8b'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 908.0, 'Nintendo ', '2024-04-23', 'seed-571f2b09ed79a51e'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 300.0, 'Zelda', '2024-04-23', 'seed-204041a836531dc1'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 107.0, 'BuJo', '2024-04-23', 'seed-6e9aed4015c539af'
  FROM categories c WHERE c.name = 'biuro'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 130.0, 'Pizza', '2024-04-24', 'seed-f69c4a1b1e23a875'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 94.0, 'parking', '2024-04-24', 'seed-516a57b0ddcd73f9'
  FROM categories c WHERE c.name = 'mieszkanie'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 350.0, 'kaucja parking', '2024-04-24', 'seed-bfb37df56962676b'
  FROM categories c WHERE c.name = 'mieszkanie'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 72.0, NULL, '2024-04-26', 'seed-a863397cac491641'
  FROM categories c WHERE c.name = 'biedronka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 153.0, NULL, '2024-04-26', 'seed-661581c2dda73a00'
  FROM categories c WHERE c.name = 'kawa'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 12.0, NULL, '2024-04-27', 'seed-cbae391b33c1e192'
  FROM categories c WHERE c.name = 'pit36'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 2913.0, NULL, '2024-04-27', 'seed-e352621e760a5544'
  FROM categories c WHERE c.name = 'zus'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 5879.0, NULL, '2024-04-27', 'seed-890ba47a23500625'
  FROM categories c WHERE c.name = 'vat'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 3373.0, NULL, '2024-04-27', 'seed-dadd4b902a5ed91e'
  FROM categories c WHERE c.name = 'pit36'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 8252.0, 'Japonia', '2024-04-27', 'seed-6be8a1e2f701dfd2'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 180.0, 'it takes two ', '2024-04-27', 'seed-75e5918a7a2b87ab'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 11.0, NULL, '2024-04-28', 'seed-b5c9b727dd215e82'
  FROM categories c WHERE c.name = 'żabka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 192.0, 'Opaska', '2024-04-29', 'seed-b3d101d4eb3cec73'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 80.0, 'Szkło IP', '2024-04-29', 'seed-2932507d9a5ba5ce'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 680.0, 'Nowa forma', '2024-05-01', 'seed-a0812751152bd9df'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 350.0, NULL, '2024-05-01', 'seed-c70920d122ce81ca'
  FROM categories c WHERE c.name = 'biuro'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 900.0, NULL, '2024-03-01', 'seed-d6c92ba26a78c007'
  FROM categories c WHERE c.name = 'biedronka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 350.0, NULL, '2024-03-01', 'seed-127dc0bcf4e8ac92'
  FROM categories c WHERE c.name = 'mieszkanie'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 40.0, 'Paperspace ', '2024-03-01', 'seed-fd5dc9762b3b3381'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 24.0, 'Mc Donalda', '2024-03-01', 'seed-1242e28fc51129b3'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 45.0, 'Szampon do okularów ', '2024-03-01', 'seed-d57bc07474082430'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 16.0, 'Maczek', '2024-03-01', 'seed-f0bf78675893b30c'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 530.0, NULL, '2024-03-02', 'seed-1a3da199772b3820'
  FROM categories c WHERE c.name = 'ubrania'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 290.0, NULL, '2024-03-03', 'seed-748e5725fc6d7b6b'
  FROM categories c WHERE c.name = 'biuro'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 60.0, 'Kino', '2024-03-04', 'seed-cc1462bbe63c30b3'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 22.0, NULL, '2024-03-04', 'seed-745642998f1a1d50'
  FROM categories c WHERE c.name = 'biedronka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 210.0, 'Mikrofon', '2024-03-04', 'seed-9704f22819757aae'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 2330.31, 'leasing', '2024-03-04', 'seed-7d63e4164129842f'
  FROM categories c WHERE c.name = 'arval'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 227.55, 'play', '2024-03-04', 'seed-b31de55b8bda9797'
  FROM categories c WHERE c.name = 'biuro'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 87.29, 'orange', '2024-03-04', 'seed-39f3f8a2898f3806'
  FROM categories c WHERE c.name = 'biuro'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 120.0, NULL, '2024-03-04', 'seed-fc28301f9ec27326'
  FROM categories c WHERE c.name = 'kawa'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 90.0, 'Dexeryl', '2024-03-05', 'seed-c5d3204cecaf906c'
  FROM categories c WHERE c.name = 'apteka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 45.0, 'dac', '2024-03-05', 'seed-6b04d49f7c79759a'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 45.0, 'apple music', '2024-03-05', 'seed-a31b4bb3569eafea'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 1382.0, NULL, '2024-03-05', 'seed-fe4fb75597cbfb86'
  FROM categories c WHERE c.name = 'mieszkanie'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 246.0, 'Upoważnienie', '2024-03-06', 'seed-3a5b0653b23dd862'
  FROM categories c WHERE c.name = 'arval'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 125.0, 'sluchawki', '2024-03-06', 'seed-a69c98d67257045b'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 100.0, 'internet', '2024-03-07', 'seed-f43f9a6559a9d7b2'
  FROM categories c WHERE c.name = 'mieszkanie'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 16.0, 'śniadanie ', '2024-03-07', 'seed-5168e9c66c77506d'
  FROM categories c WHERE c.name = 'żabka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 128.0, NULL, '2024-03-07', 'seed-cf0ecdb926a519a6'
  FROM categories c WHERE c.name = 'ubrania'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 75.0, NULL, '2024-03-08', 'seed-cd6be45b4ab868d8'
  FROM categories c WHERE c.name = 'biedronka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 257.0, NULL, '2024-03-08', 'seed-1224e9fa1d39d81a'
  FROM categories c WHERE c.name = 'paliwo'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 350.0, 'Kwiaty', '2024-03-08', 'seed-ac9dbe166463575b'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 186.0, NULL, '2024-03-09', 'seed-c0afde0530d5821b'
  FROM categories c WHERE c.name = 'paliwo'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 26.0, NULL, '2024-03-11', 'seed-bd3195c8ef51446f'
  FROM categories c WHERE c.name = 'biedronka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 250.0, 'koła', '2024-03-11', 'seed-248ab01fd1de9c72'
  FROM categories c WHERE c.name = 'arval'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 30.0, NULL, '2024-03-12', 'seed-779dc80ae361a109'
  FROM categories c WHERE c.name = 'biedronka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 50.0, NULL, '2024-03-12', 'seed-42647f66f4ca86bd'
  FROM categories c WHERE c.name = 'taxi'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 140.0, 'ostrovit', '2024-03-13', 'seed-e0171c91fa5f2390'
  FROM categories c WHERE c.name = 'apteka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 53.0, NULL, '2024-03-14', 'seed-5aefd1066925500c'
  FROM categories c WHERE c.name = 'biedronka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 2900.0, NULL, '2024-03-14', 'seed-ff41e6f7bc74e3a1'
  FROM categories c WHERE c.name = 'zus'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 350.0, 'Szkoła Jula ', '2024-03-15', 'seed-c6019ddbdd08a8bf'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 3519.0, NULL, '2024-03-15', 'seed-03894e429f8d0ab4'
  FROM categories c WHERE c.name = 'pit36'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 6329.0, NULL, '2024-03-15', 'seed-086cd3e118b824a2'
  FROM categories c WHERE c.name = 'vat'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 50.0, 'kasianski', '2024-03-17', 'seed-6ecbcef3d47c27ac'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 100.0, 'kawiarnia', '2024-03-17', 'seed-4925eadaad21f88e'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 30.0, NULL, '2024-03-18', 'seed-46e617d1eef2e753'
  FROM categories c WHERE c.name = 'biedronka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 100.0, 'fryzjer', '2024-03-20', 'seed-ff0c60fa661190df'
  FROM categories c WHERE c.name = 'ubrania'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 80.0, NULL, '2024-03-20', 'seed-4cfc9bc3b86362d4'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 150.0, NULL, '2024-03-22', 'seed-cc6174ff5a303f91'
  FROM categories c WHERE c.name = 'lekarz'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 270.0, NULL, '2024-03-22', 'seed-122a408082016ac3'
  FROM categories c WHERE c.name = 'paliwo'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 40.0, NULL, '2024-03-22', 'seed-40ca4f8a3013c73b'
  FROM categories c WHERE c.name = 'przejazdy'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 15.0, NULL, '2024-03-22', 'seed-2cf59e98eedeacca'
  FROM categories c WHERE c.name = 'biedronka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 32.0, NULL, '2024-03-25', 'seed-20af3096004e3bb5'
  FROM categories c WHERE c.name = 'taxi'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 100.0, NULL, '2024-03-25', 'seed-ef86c257d82464f8'
  FROM categories c WHERE c.name = 'biedronka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 260.0, NULL, '2024-03-30', 'seed-031dad340849de6d'
  FROM categories c WHERE c.name = 'paliwo'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 260.0, 'Prezent', '2024-03-30', 'seed-a882378d68cbf474'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 60.0, 'Chełb i rossmann', '2024-03-30', 'seed-93b0a369f1c178a6'
  FROM categories c WHERE c.name = 'biedronka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 290.0, NULL, '2024-03-30', 'seed-642ee821bfffc226'
  FROM categories c WHERE c.name = 'biedronka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 220.0, NULL, '2024-03-30', 'seed-bb9f438cac311925'
  FROM categories c WHERE c.name = 'paliwo'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 1000.0, 'Lozanna', '2024-03-30', 'seed-05811c892ef869f1'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 348.0, NULL, '2024-04-03', 'seed-81aac70945fc23cf'
  FROM categories c WHERE c.name = 'biuro'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 200.0, 'multisport', '2024-04-03', 'seed-ad59f72deefc31ec'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 58.0, 'starbucks', '2024-04-03', 'seed-cc9473d99e9f1af8'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 100.0, 'frontendmasters', '2024-04-03', 'seed-d9ecb1eb6ffb99c3'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 350.0, 'angielski', '2024-04-03', 'seed-c137f25d9ffc265a'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 35.0, 'ksiązka', '2024-04-03', 'seed-4f6edfdee934120d'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 22.0, 'ubezpieczenie', '2024-04-03', 'seed-4ec7805b4fa27c7f'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 10.0, NULL, '2024-04-03', 'seed-e13bc294343dfc3e'
  FROM categories c WHERE c.name = 'żabka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 10.0, NULL, '2024-04-03', 'seed-e827c6989052b189'
  FROM categories c WHERE c.name = 'biedronka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 70.0, NULL, '2024-04-03', 'seed-ece502d95899ce62'
  FROM categories c WHERE c.name = 'biedronka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 9.85, NULL, '2024-04-03', 'seed-7c4441e87cccafcb'
  FROM categories c WHERE c.name = 'kawa'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 252.0, 'nocleg kanazawa', '2024-01-29', 'seed-361985288de7453a'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 1221.0, 'nocleg tokio', '2024-01-29', 'seed-36de3e0d93c9ad3a'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 300.0, 'Mysz', '2024-01-30', 'seed-3977306c3cdd38d6'
  FROM categories c WHERE c.name = 'biuro'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 17.0, 'Ubezpieczenie ', '2024-01-31', 'seed-de5044513b55f5c8'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 1000.0, 'Biedronka ', '2024-02-01', 'seed-52cdeea5511f869e'
  FROM categories c WHERE c.name = 'biedronka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 400.0, 'Angielski', '2024-02-01', 'seed-0b2e18e956a1aaf0'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 300.0, 'Świadom lichwa ', '2024-02-03', 'seed-b62a30a863f94e7f'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 270.0, NULL, '2024-02-03', 'seed-e5d1355303a7f939'
  FROM categories c WHERE c.name = 'paliwo'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 197.0, NULL, '2024-02-03', 'seed-2a97b67291f2bcc4'
  FROM categories c WHERE c.name = 'paliwo'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 60.0, 'Autostrada', '2024-02-03', 'seed-8a096d7ca5e50375'
  FROM categories c WHERE c.name = 'przejazdy'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 380.0, NULL, '2024-02-03', 'seed-71d5c1f225ac4141'
  FROM categories c WHERE c.name = 'ubrania'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 30.0, 'Kabel', '2024-02-03', 'seed-32fdc08f9ee57727'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 17.0, 'chleb', '2024-02-03', 'seed-bd70706d1c2a6a8c'
  FROM categories c WHERE c.name = 'biedronka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 7.0, NULL, '2024-02-03', 'seed-43a796633017b452'
  FROM categories c WHERE c.name = 'żabka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 40.0, 'McDonalds', '2024-02-03', 'seed-30643a7712150934'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 50.0, 'Parking', '2024-02-03', 'seed-eab4f921e61a3935'
  FROM categories c WHERE c.name = 'przejazdy'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 35.0, 'Kebab', '2024-02-03', 'seed-6489c289b5ce7637'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 1700.0, 'Przegląd ', '2024-02-03', 'seed-6a6c1b577c8464af'
  FROM categories c WHERE c.name = 'arval'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 575.0, 'spanie kyoto', '2024-02-04', 'seed-a4454b3b2d28e31c'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 80.0, 'adapter', '2024-02-04', 'seed-6d8b39b5852f3b7b'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 1380.0, NULL, '2024-02-04', 'seed-49cce86a52caac3c'
  FROM categories c WHERE c.name = 'mieszkanie'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 281.0, 'Spanie Osaka', '2024-02-04', 'seed-6ef854cf2f248a92'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 228.0, 'play', '2024-02-04', 'seed-f33f36af88c46ae1'
  FROM categories c WHERE c.name = 'biuro'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 83.0, 'orange', '2024-02-04', 'seed-b91751c80d17cfbc'
  FROM categories c WHERE c.name = 'biuro'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 149.0, NULL, '2024-02-04', 'seed-cd058949af112a40'
  FROM categories c WHERE c.name = 'paliwo'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 350.0, NULL, '2024-02-05', 'seed-a1a6d3518011d4fa'
  FROM categories c WHERE c.name = 'mieszkanie'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 15.0, NULL, '2024-02-06', 'seed-e5ea3fe7e07df003'
  FROM categories c WHERE c.name = 'apteka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 44.0, 'Ramen ', '2024-02-06', 'seed-98bb61ff5fdcb6ab'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 165.0, 'Badania', '2024-02-07', 'seed-22d5368c7d838100'
  FROM categories c WHERE c.name = 'lekarz'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 350.0, 'Pierścionek', '2024-02-07', 'seed-ff5489f9500bce35'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 81.0, 'Paczki', '2024-02-08', 'seed-5cafd3d561dabf83'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 163.0, 'Nocleg Hiroshima', '2024-02-08', 'seed-4c502e1ac45e87e6'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 184.0, 'Nocleg napszima', '2024-02-08', 'seed-3c999252a948dbd7'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 37.0, NULL, '2024-02-09', 'seed-12460683157b8bcf'
  FROM categories c WHERE c.name = 'biedronka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 100.0, 'Inea ', '2024-02-09', 'seed-c3b7fcaec98badc5'
  FROM categories c WHERE c.name = 'mieszkanie'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 200.0, 'coffeedesk', '2024-02-10', 'seed-790f8dc17c65e828'
  FROM categories c WHERE c.name = 'kawa'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 34.0, 'koc', '2024-02-10', 'seed-506fed8da7f11778'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 15.0, 'wosk', '2024-02-10', 'seed-f5304b568fd8442c'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 19.0, 'lidl challenge', '2024-02-10', 'seed-7256127f7ad7b4ea'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 20.0, 'rossmann', '2024-02-10', 'seed-abdabf7bb2e10214'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 40.0, 'zasilacz', '2024-02-10', 'seed-3637854900c53286'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 690.0, 'spanie tokio 2', '2024-02-11', 'seed-c7813ddf681773cc'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 100.0, 'cyberpunk', '2024-02-11', 'seed-7584bc44c293dd2c'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 80.0, 'suple', '2024-02-11', 'seed-674c70de771ed1b0'
  FROM categories c WHERE c.name = 'apteka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 115.0, 'Mango mama ', '2024-02-13', 'seed-26f43ed8a214f355'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 56.0, NULL, '2024-02-14', 'seed-12e10e9b7f0f3ca7'
  FROM categories c WHERE c.name = 'biedronka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 230.0, NULL, '2024-02-14', 'seed-81f17df9956db045'
  FROM categories c WHERE c.name = 'paliwo'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 90.0, 'Fryzjera ', '2024-02-14', 'seed-b44382af110e04ba'
  FROM categories c WHERE c.name = 'ubrania'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 48.0, NULL, '2024-02-14', 'seed-cf537c5d28e15d31'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 500.0, NULL, '2024-02-15', 'seed-7c3e3e0c45db0a07'
  FROM categories c WHERE c.name = 'kredyt'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 57.0, 'Suple', '2024-02-15', 'seed-ea3efefcdc338ee8'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 54.0, 'Dexeryl', '2024-02-15', 'seed-ca221d166ac31b54'
  FROM categories c WHERE c.name = 'apteka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 71.0, 'żyletki', '2024-02-17', 'seed-735653615c3e4295'
  FROM categories c WHERE c.name = 'rossman'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 2800.0, NULL, '2024-02-17', 'seed-05b7330cd74a11c9'
  FROM categories c WHERE c.name = 'zus'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 100.0, 'Gf nie', '2024-02-17', 'seed-ef6252b27c1133a7'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 130.0, 'Teamlabs', '2024-02-17', 'seed-1528baeb77d0688e'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 170.0, 'Siłka ', '2024-02-18', 'seed-b77d7f5140422aad'
  FROM categories c WHERE c.name = 'ubrania'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 7656.0, NULL, '2024-02-19', 'seed-72a0c718dbdb0ae5'
  FROM categories c WHERE c.name = 'vat'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 4448.0, NULL, '2024-02-19', 'seed-120ff5ca8b771555'
  FROM categories c WHERE c.name = 'pit36'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 17.0, NULL, '2024-02-20', 'seed-948951d320689c9c'
  FROM categories c WHERE c.name = 'biedronka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 74.0, NULL, '2024-02-21', 'seed-8681aa2b6c6d1a85'
  FROM categories c WHERE c.name = 'apteka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 680.0, 'Nowa forma', '2024-02-21', 'seed-77f7014a437f4bf7'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 154.0, 'podkładka ', '2024-02-23', 'seed-f1655e6791f6b78c'
  FROM categories c WHERE c.name = 'biuro'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 40.0, NULL, '2024-02-23', 'seed-14ba103231916d85'
  FROM categories c WHERE c.name = 'biedronka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 46.0, NULL, '2024-02-26', 'seed-eae50a42ef6bcd8b'
  FROM categories c WHERE c.name = 'biedronka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 200.0, 'Hp tokyo', '2024-02-26', 'seed-b37d0474dd200db7'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 165.0, 'Ale kosmos', '2024-02-26', 'seed-6c111d27dd6995d2'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 17.0, NULL, '2024-02-26', 'seed-9d12cdd55e4766bf'
  FROM categories c WHERE c.name = 'biedronka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 100.0, 'Waga', '2024-02-26', 'seed-710f11824c0bc81b'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 250.0, NULL, '2024-02-27', 'seed-3a31b2d487c089ab'
  FROM categories c WHERE c.name = 'lekarz'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 100.0, NULL, '2024-02-27', 'seed-e5dc75fd9c2c7507'
  FROM categories c WHERE c.name = 'biedronka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 500.0, 'angielski', '2024-02-27', 'seed-9838e98843171141'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 100.0, 'fedmasters', '2024-02-27', 'seed-d99c009aebb3fc83'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 100.0, 'nvidia', '2024-02-27', 'seed-1a675e91e4c48f8a'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 50.0, 'medium', '2024-02-27', 'seed-2fb0c65e23a57b93'
  FROM categories c WHERE c.name = 'biuro'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 50.0, NULL, '2024-02-27', 'seed-6bbe94e9c7fa2369'
  FROM categories c WHERE c.name = 'żabka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 65.0, 'knajpa', '2024-02-27', 'seed-a6f95bbf9e897d2a'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 100.0, 'pyszne.pl', '2024-02-27', 'seed-ccbaef28cb2abc73'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 17.0, NULL, '2024-02-27', 'seed-2896593ef5b81ed8'
  FROM categories c WHERE c.name = 'biedronka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 70.0, 'suple', '2024-02-27', 'seed-516351e656c16501'
  FROM categories c WHERE c.name = 'apteka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 37.0, NULL, '2024-02-27', 'seed-2d70f075daa8b3ab'
  FROM categories c WHERE c.name = 'biedronka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 18.0, NULL, '2024-02-27', 'seed-1f2c94c66f98c0dd'
  FROM categories c WHERE c.name = 'biedronka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 17.0, 'chleb', '2024-02-27', 'seed-41ec7e72ca211bf6'
  FROM categories c WHERE c.name = 'biedronka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 10.0, 'parking', '2024-02-27', 'seed-cb7afb2e817b612f'
  FROM categories c WHERE c.name = 'arval'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 25.0, NULL, '2024-02-27', 'seed-b0ac109cb6eadbe7'
  FROM categories c WHERE c.name = 'żabka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 15.0, 'apple', '2024-02-27', 'seed-7e8e74c8718fd18b'
  FROM categories c WHERE c.name = 'biuro'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 184.0, 'spanie okayama', '2024-02-28', 'seed-4af9a2bf7ea7c92d'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 100.0, NULL, '2024-02-28', 'seed-5f3196155143ff68'
  FROM categories c WHERE c.name = 'biedronka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 689.0, 'spanie tokyo', '2024-02-28', 'seed-a08cc1703cbafc02'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 35.0, NULL, '2024-02-28', 'seed-9944eac142cc0618'
  FROM categories c WHERE c.name = 'biedronka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 160.0, 'adapter', '2024-02-28', 'seed-9fc35f0223523cf0'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 70.0, NULL, '2024-02-28', 'seed-f1a8597764639838'
  FROM categories c WHERE c.name = 'biedronka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 1570.0, '??', '2024-02-28', 'seed-ae419bd04d5a9231'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 250.0, 'dermatolog', '2024-02-28', 'seed-e37e8340a6b58cf7'
  FROM categories c WHERE c.name = 'lekarz'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 67.0, NULL, '2024-01-01', 'seed-47de18c47a610161'
  FROM categories c WHERE c.name = 'biedronka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 190.0, NULL, '2024-01-01', 'seed-7104d8a1216aa0c3'
  FROM categories c WHERE c.name = 'biedronka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 56.0, NULL, '2024-01-01', 'seed-6071408c123bab3e'
  FROM categories c WHERE c.name = 'biedronka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 176.0, NULL, '2024-01-01', 'seed-b6eb85370539153b'
  FROM categories c WHERE c.name = 'biedronka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 90.0, NULL, '2024-01-01', 'seed-716cd73e4628ae31'
  FROM categories c WHERE c.name = 'ubrania'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 215.0, NULL, '2024-01-01', 'seed-dd74540e6e534df6'
  FROM categories c WHERE c.name = 'biedronka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 35.0, NULL, '2024-01-02', 'seed-a7b2b507bf4e22c9'
  FROM categories c WHERE c.name = 'biedronka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 800.0, NULL, '2024-01-03', 'seed-fa837c313dd3d491'
  FROM categories c WHERE c.name = 'biedronka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 1382.0, NULL, '2024-01-03', 'seed-656496bb83252d38'
  FROM categories c WHERE c.name = 'mieszkanie'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 350.0, 'parking', '2024-01-03', 'seed-d4ba4e40f4ac0561'
  FROM categories c WHERE c.name = 'mieszkanie'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 2330.0, 'leasing', '2024-01-04', 'seed-d065dcfb88a66f79'
  FROM categories c WHERE c.name = 'arval'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 83.0, 'orange', '2024-01-04', 'seed-c227466d028df02a'
  FROM categories c WHERE c.name = 'biuro'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 230.0, 'play', '2024-01-04', 'seed-730084242900faea'
  FROM categories c WHERE c.name = 'biuro'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 5.0, NULL, '2024-01-04', 'seed-7102ad5c9985da66'
  FROM categories c WHERE c.name = 'żabka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 31.0, NULL, '2024-01-05', 'seed-e33fd68affb79fe5'
  FROM categories c WHERE c.name = 'biedronka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 200.0, 'Prezent ', '2024-01-06', 'seed-813d160e08c7fb99'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 60.0, 'przejazd birr', '2024-01-06', 'seed-e9ab3fd32f675049'
  FROM categories c WHERE c.name = 'biuro'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 5900.0, 'Japonia ', '2024-01-06', 'seed-a92f8b69b39224af'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 10.0, NULL, '2024-01-07', 'seed-30549c5d50e211a5'
  FROM categories c WHERE c.name = 'arval'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 300.0, NULL, '2024-01-08', 'seed-3bd54bf6f7671d5a'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 20.0, NULL, '2024-01-08', 'seed-83960deefabe8b2d'
  FROM categories c WHERE c.name = 'arval'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 127.0, 'pociąg birr', '2024-01-09', 'seed-b892322e7e07c19a'
  FROM categories c WHERE c.name = 'przejazdy'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 37.0, NULL, '2024-01-09', 'seed-37bb7bf2ef479146'
  FROM categories c WHERE c.name = 'biedronka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 69.0, 'filtry', '2024-01-09', 'seed-e6e6247cf849fc2f'
  FROM categories c WHERE c.name = 'mieszkanie'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 58.0, 'bankook', '2024-01-09', 'seed-6f76a334dcd2a8eb'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 226.0, NULL, '2024-01-11', 'seed-dbe2a84a8a88967f'
  FROM categories c WHERE c.name = 'paliwo'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 23.0, NULL, '2024-01-11', 'seed-f2c6385bb04ef31c'
  FROM categories c WHERE c.name = 'arval'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 29.0, 'Nero', '2024-01-11', 'seed-66c01b0154e89a4c'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 33.0, 'Nero', '2024-01-11', 'seed-1772db159c937528'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 36.0, 'Jula ', '2024-01-11', 'seed-efd79049666a4bd7'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 41.0, 'Czapka Jula ', '2024-01-11', 'seed-01ec4722646fd3b3'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 40.0, 'KFC', '2024-01-11', 'seed-3a1b26477e23554f'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 25.0, 'Wars ', '2024-01-12', 'seed-0e62452e556be400'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 232.0, 'Coffedesk', '2024-01-12', 'seed-939b6b9b41b8019a'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 80.0, 'Uniqlo ', '2024-01-12', 'seed-a261743036d1412d'
  FROM categories c WHERE c.name = 'ubrania'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 3.0, NULL, '2024-01-12', 'seed-11caf463391f1df8'
  FROM categories c WHERE c.name = 'biedronka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 258.0, NULL, '2024-01-13', 'seed-8a51a13d03c62569'
  FROM categories c WHERE c.name = 'paliwo'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 3319.0, NULL, '2024-01-13', 'seed-8397ac26549e7c6a'
  FROM categories c WHERE c.name = 'pit36'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 5645.0, NULL, '2024-01-13', 'seed-5bc611b2c8a85b63'
  FROM categories c WHERE c.name = 'vat'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 2600.0, NULL, '2024-01-13', 'seed-b3bc36e8033b67f7'
  FROM categories c WHERE c.name = 'zus'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 250.0, NULL, '2024-01-14', 'seed-68d2ffd1572dd158'
  FROM categories c WHERE c.name = 'mieszkanie'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 14.0, NULL, '2024-01-14', 'seed-5d1cd4c2805d1f21'
  FROM categories c WHERE c.name = 'żabka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 147.0, NULL, '2024-01-15', 'seed-d1ca158bbf5fd5a9'
  FROM categories c WHERE c.name = 'kawa'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 70.0, NULL, '2024-01-15', 'seed-f9a032a8f1e85f0f'
  FROM categories c WHERE c.name = 'biedronka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 162.0, NULL, '2024-01-16', 'seed-88d370c84b23bb67'
  FROM categories c WHERE c.name = 'apteka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 162.0, 'foto lampa', '2024-01-16', 'seed-30fd93097770ccc2'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 3550.0, 'Wyjazd Lozanna', '2024-01-17', 'seed-5c52b4cb9cbb2fad'
  FROM categories c WHERE c.name = 'biuro'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 71.0, NULL, '2024-01-19', 'seed-2fc941227400f259'
  FROM categories c WHERE c.name = 'biedronka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 140.0, 'kzn', '2024-01-20', 'seed-a2477f3ce032aaf2'
  FROM categories c WHERE c.name = 'biedronka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 57.0, NULL, '2024-01-20', 'seed-60b81ff96415943e'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 151.0, 'fripers', '2024-01-20', 'seed-0d7bd9450a73817f'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 234.0, NULL, '2024-01-21', 'seed-e7ac490467d2e172'
  FROM categories c WHERE c.name = 'paliwo'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 25.0, NULL, '2024-01-22', 'seed-e2b5289e25553686'
  FROM categories c WHERE c.name = 'biedronka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 500.0, 'Sigma ', '2024-01-23', 'seed-89d297ae8a756348'
  FROM categories c WHERE c.name = 'kredyt'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 680.0, 'Siłka', '2024-01-23', 'seed-a0e37c1848b97c6e'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 141.0, 'kwiaty', '2024-01-27', 'seed-0035761ecc806e81'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 150.0, 'poradnik foto', '2024-01-27', 'seed-625599fdf6fdb430'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 98.0, 'knajpa', '2024-01-27', 'seed-d8182628dc5769c9'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 105.0, 'mangez, płyn', '2024-01-27', 'seed-b65f287ea5d11ea1'
  FROM categories c WHERE c.name = 'apteka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 55.0, 'chleb', '2024-01-27', 'seed-38c404aed83759c2'
  FROM categories c WHERE c.name = 'biedronka'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 289.0, 'ksiegowa', '2024-01-27', 'seed-1159936c2e19a3a5'
  FROM categories c WHERE c.name = 'biuro'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 133.0, 'Knajpa ', '2024-01-27', 'seed-70bb7ee24d507f13'
  FROM categories c WHERE c.name = 'fun'
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, category_id, type, amount, description, date, import_hash)
  SELECT v_account_id, c.id, 'expense', 56.0, NULL, '2024-01-29', 'seed-3fa6de1ad0ff33eb'
  FROM categories c WHERE c.name = 'biedronka'
  ON CONFLICT (import_hash) DO NOTHING;

  INSERT INTO transactions (account_id, type, amount, description, date, import_hash)
  VALUES (v_account_id, 'income', 32914.0, 'sml', '2025-09-30', 'seed-inc-e7b57cbf5440bb2b')
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, type, amount, description, date, import_hash)
  VALUES (v_account_id, 'income', 32545.0, 'sml', '2025-07-27', 'seed-inc-9c6a4c507dc0c14b')
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, type, amount, description, date, import_hash)
  VALUES (v_account_id, 'income', 35649.0, 'sml', '2025-06-30', 'seed-inc-6e59f0c7f17dbaaf')
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, type, amount, description, date, import_hash)
  VALUES (v_account_id, 'income', 34143.57, 'sml', '2025-02-15', 'seed-inc-0a47f94c16c48272')
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, type, amount, description, date, import_hash)
  VALUES (v_account_id, 'income', 29217.42, 'sml', '2025-01-15', 'seed-inc-c3a543828dd2ac38')
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, type, amount, description, date, import_hash)
  VALUES (v_account_id, 'income', 31517.0, 'sml', '2024-11-30', 'seed-inc-bc0ecd0d5247996f')
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, type, amount, description, date, import_hash)
  VALUES (v_account_id, 'income', 36109.11, 'sml', '2024-11-10', 'seed-inc-f869341d207ab555')
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, type, amount, description, date, import_hash)
  VALUES (v_account_id, 'income', 32269.0, 'sml', '2024-10-02', 'seed-inc-9945de370b2aa942')
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, type, amount, description, date, import_hash)
  VALUES (v_account_id, 'income', 36211.0, 'sml', '2024-09-03', 'seed-inc-401cab9039a1fa2c')
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, type, amount, description, date, import_hash)
  VALUES (v_account_id, 'income', 35307.0, 'sml', '2024-07-28', 'seed-inc-fb21e5760437a045')
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, type, amount, description, date, import_hash)
  VALUES (v_account_id, 'income', 30750.0, 'sml', '2024-07-01', 'seed-inc-dbc55240a988922b')
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, type, amount, description, date, import_hash)
  VALUES (v_account_id, 'income', 150.0, 'sml prezent', '2024-07-03', 'seed-inc-1915ddf72dc8f5c7')
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, type, amount, description, date, import_hash)
  VALUES (v_account_id, 'income', 35307.0, 'sml', '2024-05-30', 'seed-inc-7491202012983d6e')
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, type, amount, description, date, import_hash)
  VALUES (v_account_id, 'income', 12792.0, 'sml', '2024-05-05', 'seed-inc-0f0290be46fa4255')
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, type, amount, description, date, import_hash)
  VALUES (v_account_id, 'income', 33948.0, 'sml', '2024-04-03', 'seed-inc-39ee82d1b7acb537')
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, type, amount, description, date, import_hash)
  VALUES (v_account_id, 'income', 36373.0, 'sml', '2024-03-01', 'seed-inc-15caa8a278a6eda6')
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, type, amount, description, date, import_hash)
  VALUES (v_account_id, 'income', 40185.0, 'sml', '2024-01-29', 'seed-inc-ec123386e0777e44')
  ON CONFLICT (import_hash) DO NOTHING;
  INSERT INTO transactions (account_id, type, amount, description, date, import_hash)
  VALUES (v_account_id, 'income', 32785.0, 'sml', '2024-01-01', 'seed-inc-ab48e0a761f0eedb')
  ON CONFLICT (import_hash) DO NOTHING;

END $$;
