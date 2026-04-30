# Katolog — Whitelabel Partner Portal

Static-HTML, brand-agnostic version of the Kataloghub partner-facing
catalog tools. Drop into any web host (no build step), then run a
search/replace to swap `{{PartnerBrand}}`, `{{PartnerContact}}`, and
`{{PartnerDomain}}` for the partner's values.

## Repo layout

```
.
├── README.md
├── about.txt           # product spec (what to deliver, partner-safe rules)
├── plan.txt            # engineering rules (single-file static, no Node, etc.)
├── brand.config.json   # placeholder values + theme tokens for one partner
└── pages/
    ├── index.html               # marketing landing
    ├── how-it-works.html        # 6-step workflow detail
    ├── pricing.html             # partner-facing wholesale tiers
    ├── pricing-kataloghub.html  # Kataloghub SaaS pricing (SV, hardcoded brand)
    ├── faq.html                 # 15 Q&A in 4 categories
    ├── partner.html             # 5-day onboarding timeline
    ├── contact.html             # contact form (mailto-only)
    ├── terms.html               # 10-clause terms of service
    ├── portal.html              # partner-facing portal (sidebar nav,
    │                             # Catalog Ingest Engine with folder
    │                             # drag-drop + SHA-256 hashing,
    │                             # Exportfiler driven by localStorage)
    ├── scan-catalog.html        # Part 1 — real working catalog scanner
    │                             # (parses CSV, builds XLSX worksheet
    │                             # via ExcelJS, generates Health Report HTML)
    └── apply-corrections.html   # Part 2 — real working corrections merge
                                  # (produces cleaned CSV + after-cleaning
                                  # Health Report; CWR generation handled
                                  # by /api/cwr/generate on the backend)
```

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

### 2. Multi-tenant via Kataloghub Phase 1 (recommended)

Deploy these pages inside the Kataloghub backend
(`automation.heyroya.se` / `kataloghub.se`). The FastAPI portal route
reads the `Host:` header on each request, looks up the tenant in
Postgres, and substitutes the placeholders + injects the per-tenant
accent color before serving. One deploy, every partner under their own
custom domain via CNAME.

See the auto repo (`mrglennc64/auto`) for the backend implementation:
- `app/api/portal.py` — the rendering route
- `app/services/tenants.py` — tenant lookup + cache + placeholder render
- `scripts/add_tenant.py` — admin CLI for tenant creation
- Migration `alembic/versions/0003_add_tenants.py`

## Strict rules (from about.txt and plan.txt)

- **Single-file pattern**: each page is self-contained — inline CSS +
  inline JS, no external bundles, no build step.
- **Tone**: Scandinavian enterprise — short, factual, metadata-only,
  zero-trust. No marketing adjectives, no royalty/financial claims, no
  system-access implications.
- **Boundaries**: file-based only, no live system access, no API
  endpoints exposed to the partner's end-clients, no automated changes
  to ownership data.

## Workflow tools (the partner-facing core)

- **`scan-catalog.html`** — Partner uploads a catalog CSV, gets back a
  Health Report and an XLSX worksheet listing every issue requiring
  publisher decision.
- **`apply-corrections.html`** — Partner uploads the filled-in
  worksheet plus the original catalog. Tool merges the publisher's
  Accept / Edit / Reject decisions and emits a cleaned CSV plus an
  after-cleaning Health Report.

Both tools run 100% client-side (no backend required). Real CWR v2.1
generation lives behind the backend `POST /api/cwr/generate` endpoint
(scaffolded; real builder TBD — see auto repo).
