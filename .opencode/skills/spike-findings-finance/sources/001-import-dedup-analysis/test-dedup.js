import { createHash } from 'crypto';

function computeImportHash(date, amount, description) {
  return createHash('sha256')
    .update(`${date}|${amount}|${description}`)
    .digest('hex');
}

// ─── Test 1: Basic dedup — same transaction twice ───
const h1 = computeImportHash('2026-01-15', '1234.50', 'Some description');
const h2 = computeImportHash('2026-01-15', '1234.50', 'Some description');
console.log(`Test 1 - Same tx twice: ${h1 === h2 ? 'PASS' : 'FAIL'} (hashes ${h1 === h2 ? 'match' : 'differ'})`);

// ─── Test 2: Different amounts, same date+desc ───
const h3 = computeImportHash('2026-01-15', '100.00', 'Coffee shop');
const h4 = computeImportHash('2026-01-15', '100.01', 'Coffee shop');
console.log(`Test 2 - Different amounts: ${h3 !== h4 ? 'PASS' : 'FAIL'} (hashes ${h3 !== h4 ? 'differ' : 'match — BAD'})`);

// ─── Test 3: Different dates, same amount+desc ───
const h5 = computeImportHash('2026-01-15', '100.00', 'Coffee shop');
const h6 = computeImportHash('2026-01-16', '100.00', 'Coffee shop');
console.log(`Test 3 - Different dates: ${h5 !== h6 ? 'PASS' : 'FAIL'} (hashes ${h5 !== h6 ? 'differ' : 'match — BAD'})`);

// ─── Test 4: Different description, same date+amount ───
const h7 = computeImportHash('2026-01-15', '100.00', 'Coffee shop A');
const h8 = computeImportHash('2026-01-15', '100.00', 'Coffee shop B');
console.log(`Test 4 - Different desc: ${h7 !== h8 ? 'PASS' : 'FAIL'} (hashes ${h7 !== h8 ? 'differ' : 'match — BAD'})`);

// ─── Test 5: Legitimate duplicates — two 15 PLN coffees same day ───
const coffee1 = computeImportHash('2026-01-15', '15.00', 'ZABKA Z0685 K.2');
const coffee2 = computeImportHash('2026-01-15', '15.00', 'ZABKA Z0685 K.2');
console.log(`Test 5 - Same coffee twice: ${coffee1 === coffee2 ? 'PASS (will dedup — KNOWN LIMITATION)' : 'FAIL'} (hashes match, second import skipped)`);
// This is the documented limitation — LLM returns identical descriptions for identical transactions

// ─── Test 6: account_id NOT in hash ───
// The hash computed in import-worker.ts line 83-87 does NOT include account_id
const hashForAccountA = computeImportHash('2026-01-15', '100.00', 'Salary');
const hashForAccountB = computeImportHash('2026-01-15', '100.00', 'Salary');
console.log(`Test 6 - account_id missing: ${hashForAccountA === hashForAccountB ? 'CONFIRMED: account_id NOT in hash' : 'FAIL'} (same tx imported to two accounts would collide)`);

// ─── Test 7: Null description handling ───
const hNull1 = computeImportHash('2026-01-15', '100.00', 'null');
const hNull2 = computeImportHash('2026-01-15', '100.00', 'null');
console.log(`Test 7 - Null desc literal: ${hNull1 === hNull2 ? 'PASS (string "null" hashes predictably)' : 'FAIL'}`);

// ─── Test 8: leading/trailing whitespace sensitivity ───
const trimmed = computeImportHash('2026-01-15', '100.00', 'Coffee');
const untrimmed = computeImportHash('2026-01-15', '100.00', ' Coffee ');
console.log(`Test 8 - Whitespace: ${trimmed !== untrimmed ? 'PASS (whitespace-sensitive — LLM must not pad)' : 'FAIL (whitespace insensitive — dangerous)'}`);

// ─── Test 9: Amount format sensitivity (1234.5 vs 1234.50) ───
const fmt1 = computeImportHash('2026-01-15', '1234.50', 'Desc');
const fmt2 = computeImportHash('2026-01-15', '1234.5', 'Desc');
console.log(`Test 9 - Amount format: ${fmt1 !== fmt2 ? 'PASS (formats differ — LLM must output consistent format)' : 'FAIL (format-insensitive)'}`);

// ─── Summary ───
console.log('\n─── Summary ───');
console.log('Hash components: date|amount|description (NO account_id)');
console.log('');
console.log('Confirms:');
console.log('  ✓ Duplicate prevention works for identical CSV rows');
console.log('  ✓ Different amounts/dates/descriptions produce different hashes');
console.log('  ✓ Whitespace-sensitive (LLM must be consistent)');
console.log('  ✓ Amount format-sensitive (LLM must output "N.NN" consistently)');
console.log('');
console.log('Risks:');
console.log('  ⚠ account_id NOT in hash — same transaction imported to two accounts would dedup');
console.log('  ⚠ Two genuinely separate purchases of same amount at same place = silently deduped');
console.log('  ⚠ LLM inconsistency in formatting amounts/descriptions could cause missed dedups');
