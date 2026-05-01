# Kataloghub — Validering av musikförlagskataloger

Static-HTML, brand-agnostic version of the Kataloghub partner-facing
catalog tools. **Validation-only** — no correction logic, no CWR generation,
no workflow logic. Drop into any web host (no build step), then run a
search/replace to swap `{{PartnerBrand}}`, `{{PartnerContact}}`, and
`{{PartnerDomain}}` for the partner's values.

Korrigering av metadata utförs separat via HeyRoya och ingår inte i Kataloghub.

## Repo layout

```
.
├── README.md
├── about.txt           # product spec (validation-only, partner-safe rules)
├── plan.txt            # engineering rules (single-file static, no Node, etc.)
├── brand.config.json   # placeholder values + theme tokens for one partner
├── lib/
│   └── tier-limits.js          # backend tier-limit enforcement module
├── scripts/
│   └── minify-pages.ps1        # conservative inline-asset minifier
└── pages/
    ├── index.html              # marketing landing
    ├── how-it-works.html       # 3-step validation workflow
    ├── pricing.html            # partner-facing wholesale tiers
    ├── pricing-kataloghub.html # Kataloghub publisher pricing (Lite/Standard/Enterprise)
    ├── faq.html                # vanliga frågor
    ├── partner.html            # 5-day onboarding timeline
    ├── contact.html            # contact form (mailto-only)
    ├── terms.html              # 13-clause villkor
    ├── portal.html             # Historik — read-only scan history
    └── scan-catalog.html       # validation tool: CSV in → PDF + CSV-mall
```

All operational pages are Swedish-only and follow Carina-tone (kort, neutral,
operativ, faktabaserad, utan hype, utan metaforer, utan värdeord).

## Two ways to deploy

### 1. Static drop (any host)

Copy the contents of this repo to any web server (nginx, S3, Netlify,
Cloudflare Pages, GitHub Pages). For a single partner:

1. Find/replace across all `pages/*.html`:
   - `{{PartnerBrand}}` → partner's display name
   - `{{PartnerContact}}` → partner's contact email
   - `{{PartnerDomain}}` → partner's domain
2. To rebrand colors: search/replace the `--accent` hex value in the
   `:root` block of each HTML file. Defaults are the Kataloghub palette
   (see `brand.config.json` for the tokens).
3. Optionally run `scripts/minify-pages.ps1` to produce a `pages.min/`
   directory with stripped comments and tightened whitespace.

### 2. Multi-tenant via Kataloghub Phase 1 (recommended)

Deploy these pages inside the Kataloghub backend
(`automation.heyroya.se` / `kataloghub.se`). The FastAPI portal route
reads the `Host:` header on each request, looks up the tenant in
Postgres, and substitutes the placeholders + injects the per-tenant
accent color before serving. One deploy, every partner under their own
custom domain via CNAME.

The backend may also inject:
- `window.KATALOGHUB_TIER_CONFIG` — `{ maxWorksPerValidation, maxValidationsPerPeriod, maxCatalogsPerPeriod }`
- `window.KATALOGHUB_USAGE_STATE` — `{ validationsThisPeriod, catalogsThisPeriod, userId }`
- `window.KATALOGHUB_HISTORY` — array of `{ date, catalog, works, status, reportUrl?, csvUrl?, blockCode? }`
- `window.KATALOGHUB_PERIOD` — current period meta for the Historik page

Defaults if not injected: Lite-tier limits (1 000 verk per validering, 1
validering per månad, 1 katalog per månad), empty history.

See the auto repo (`mrglennc64/auto`) for the backend implementation:
- `app/api/portal.py` — the rendering route
- `app/services/tenants.py` — tenant lookup + cache + placeholder render
- `scripts/add_tenant.py` — admin CLI for tenant creation
- Migration `alembic/versions/0003_add_tenants.py`

## Strict rules

- **Validation only.** No correction logic. No CWR generation. No workflow
  logic. No automatic upgrades. No analytics or usage dashboards.
- **Single-file pattern**: each page is self-contained — inline CSS +
  inline JS, no external bundles, no build step (apart from the optional
  minify script).
- **Tone**: Carina-tone — short, neutral, operational, fact-based, no hype,
  no metaphors, no value-words, no marketing CTAs in administrative copy.
- **Boundaries**: file-based only, no live system access, no API
  endpoints exposed to the partner's end-clients, no automated changes
  to ownership data.
- **Tier-limit enforcement**: validation is gated by tier. Either full
  validation or no validation — no partial validation. Violations show
  Carina-tone administrative messages only (no upsell, no CTA buttons,
  no "uppgradera" language).

## Tier-limit module

`lib/tier-limits.js` implements server-side validation gating. Public API:

```js
const { validateTierLimits, countWorks, MESSAGES } = require('./lib/tier-limits.js');

const result = validateTierLimits(
  uploadedFile,                                        // CSV string or Buffer
  { maxWorksPerValidation: 1000,                       // tier config
    maxValidationsPerPeriod: 1,
    maxCatalogsPerPeriod: 1 },
  { validationsThisPeriod: 0,                          // usage state
    catalogsThisPeriod: 0,
    userId: 'publisher-42' }
);
// → { status: 'allowed' | 'blocked', reason: string, code: string }
// codes: OK | LIMIT_WORKS | LIMIT_VALIDATIONS | LIMIT_CATALOGS
```

Logging on block: timestamp, userId, numberOfWorks, reasonCode. No
analytics, no aggregation, no dashboards.

## Validation tool — outputs

`pages/scan-catalog.html` produces exactly two artifacts per scan:

- **PDF** (Health Report) — printable from the browser, generated by `Generera hälsorapport (PDF)`.
- **CSV-mall** — 8-column CSV (`issue_id, work, field, current_value, suggested, decision, publisher_value, note`) used as input for correction via HeyRoya.

No XLSX, no instructions.txt, no CWR export, no cleaned-catalog export.
