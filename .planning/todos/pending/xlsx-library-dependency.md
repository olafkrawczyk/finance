# Todo: Install XLSX parsing library
**Date:** 2026-06-07
**Priority:** High
**Status:** Pending

Install a node-compatible spreadsheet parsing library in the project to support reading binary Excel files (`.xlsx`) on the backend.

## Tasks
* Run `bun add xlsx` or equivalent package (e.g. `exceljs` or `xlsx-populate`) in the workspace.
* Verify it is listed in `package.json` dependencies.
* Write a quick validation test to ensure the library runs on the Bun environment and can read basic cell values from a temporary sheet.
