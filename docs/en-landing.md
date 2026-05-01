# Catalog File Validation — English version (held, not implemented)

Saved on the `minimal-site` branch for later use. The live site stays
Swedish-only per directive. Schema field is `writer_ipi` (the EN draft used
`writer_jpi`; left as `writer_ipi` here for consistency with the schema).

---

## Catalog File Validation

File-based checks of structure, identifiers, and format.
No integration. No automation. No system access.

### What Kataloghub delivers

**PDF report**
Summary of structural issues in the catalog file.
Shows missing identifiers, invalid formats, and duplicates.

**CSV dataset**
Machine-readable list of issues per row.
Used as decision support before any correction work.

**Structure check**
Verification of column order, required fields, and file integrity.

**Identifier check**
Validation of work_id, writer_ipi, iswc, and isrc.

**Format check**
Validation of roles, shares, encoding, and numeric values.

**Duplicate check**
Detection of duplicates based on work_id and writer_ipi.

### How validation works

1. The publisher exports a catalog file in CSV format.
2. The file is validated against structural requirements.
3. A PDF report and CSV dataset are delivered.
4. The publisher decides whether any works should be corrected via HeyRoya.

### Start validation

Upload a catalog file for validation.
No login. No file storage after delivery.

[Upload catalog file]
