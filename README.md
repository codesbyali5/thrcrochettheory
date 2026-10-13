# THE CROCHET THEORY

> **Updated build (September 2026):** local development is configured for `http://localhost:3000`. The active payment provider in `.env.example` is Payoneer-hosted payment requests, subject to Payoneer account/API eligibility. See `PAYMENT_SETUP.md` and `CHANGES_AND_SETUP.md`. Card number, expiry and CVV are never handled by this Node server.


The existing HTML/CSS/JavaScript storefront, upgraded with a Node.js backend, a persistent SQLite database and a separate `/admin` studio. All original public pages remain. Public typography, colors and the original `assets/styles.css` are preserved. `assets/store.css` contains only the requested card alignment and necessary responsive account fixes. Admin styling lives entirely in `admin/admin.css`.

## Local setup

Use **Node.js 24.16 or a later 24.x release** and npm. This app uses Node's built-in SQLite API. Opening HTML files directly or serving this directory with a static server will not run authentication or checkout.

```sh
npm ci
```

Copy `.env.example` to `.env` and set `APP_URL` to your actual origin (default `http://localhost:3000`). In PowerShell:

```powershell
Copy-Item .env.example .env
npm run db:seed
```

Set `ADMIN_EMAIL`, `ADMIN_USERNAME`, a four-digit `ADMIN_PIN`, an `ADMIN_PASSWORD` of at least 8 characters, and optionally `ADMIN_NAME` in your private `.env`, then run:

```sh
npm run admin:create
npm start
```

Remove `ADMIN_PASSWORD` and the other bootstrap values from `.env` after creating the administrator. Admin usernames and salted PIN/password hashes are stored on the server. The local administrator requested for this workspace has been created; its credentials are not embedded in public JavaScript. A fresh database requires the bootstrap command. The bootstrap command refuses to overwrite or promote an existing account. Use `/forgot.html` with SMTP configured and the bootstrap email to reset a password. The requested local account uses `admin0909@crochet-theory.local`; configure a deliverable admin email before relying on email recovery.

Open the storefront at `http://localhost:3000` and the admin at `http://localhost:3000/admin`. `npm run dev` restarts the server when backend files change.

`db:seed` imports the original eight pattern names, prices, descriptions and artwork exactly once. It does not import fabricated reviews, orders, ratings, withdrawals or browser accounts. **No actual crochet PDFs were supplied**, so the imported patterns remain visible but unavailable for purchase. Upload each real PDF in Admin → Patterns, review the product, and set its status to `active` to sell it. Re-running the seed does not overwrite edits.

## What is connected

- Overview and analytics: actual orders, gross sales, refunds, recorded fees, net earnings, customers, individual pattern sales, downloads, top patterns, coupon usage, review activity and date filters.
- Pattern management: add, edit, soft-delete, duplicate, publish/unpublish, feature, availability, cover/gallery uploads, skill level, materials, making time, pattern details, tags and SEO fields. Deleted/unpublished products remain available in existing purchasers' libraries.
- Customers: searchable accounts, purchase/spending/download history, enable/disable. Disabling revokes all sessions; administrator accounts cannot be disabled through customer management.
- Orders: immutable line-item prices, totals, discounts, customer, timestamps, provider session/payment IDs, refund status and full-refund requests with password confirmation.
- Reviews: verified purchasers submit reviews; admins approve, hide, remove or correct them with a required reason. Previous text and moderation actions are retained in the append-only activity log. Removed reviews do not appear publicly.
- Coupons: percentage or fixed discount, expiry, minimum order, eligible patterns, usage limits, enable/disable and paid usage statistics. Checkout reservations prevent concurrent last-use overspending.
- Inbox: real contact submissions, private notes and new/read/resolved/spam status. Newsletter subscriptions persist and their count appears in Inbox. Inbox changes do **not** send email replies.
- Settings: store name, support address, announcement and emergency download pause. Payment/email/storage secrets remain server environment settings, never frontend settings.
- Customer pages: signup/login, password reset, editable name, order history, purchased library, verified downloads, reviews, wishlist and basket. Only guest basket/wishlist preferences use localStorage. Legacy browser passwords, users, sessions, orders and entitlements are cleared rather than trusted or migrated.

## Stripe payments

You need a properly activated Stripe merchant account in a supported business jurisdiction. Configure:

```dotenv
STRIPE_SECRET_KEY=your_server_side_key
STRIPE_WEBHOOK_SECRET=your_endpoint_signing_secret
STORE_CURRENCY=usd
```

Supported store currencies are `usd`, `gbp`, `eur`, `cad`, and `aud` (two decimal places). Choose the currency before taking orders; do not change it after recording transactions without a deliberate data migration.

The server creates Stripe **hosted Checkout** sessions. It never receives raw card numbers, expiry dates or CVCs. Prices, availability, coupon eligibility and final amounts are calculated from the database, in integer minor units. A checkout total must be at least 0.50 after discounts. Existing orders retain their saved prices even if the catalog changes.

Create a webhook endpoint at:

```text
https://your-domain.example/api/webhooks/stripe
```

Subscribe to:

```text
checkout.session.completed
checkout.session.async_payment_succeeded
checkout.session.async_payment_failed
checkout.session.expired
charge.succeeded
charge.refunded
payout.created
payout.updated
payout.paid
payout.failed
payout.canceled
```

Webhook signatures are checked against the **raw body** with the Stripe SDK and its timestamp tolerance. Test/live mode, saved order identity, customer metadata, session binding, currency and total must match. The server retrieves the current provider object, then atomically records the event and grants **only the saved purchased products**. Repeated deliveries are idempotent. A success URL never grants access; that page only polls the customer's own order status. Keep webhook deliveries healthy and monitor/replay failed events through Stripe.

For local provider testing, install and authenticate the official Stripe CLI, then:

```sh
stripe listen --forward-to localhost:3000/api/webhooks/stripe
```

Set the signing secret printed by that command in `.env`, restart the app, and make an actual checkout using your Stripe test account. Use the provider's documented test cards **only on Stripe's hosted checkout**. Generic `stripe trigger` checkout fixtures are not associated with a real store order and deliberately do not unlock files.

A full-refund action calls Stripe with an idempotency key. Access and refunded amounts change only on the confirmed charge webhook. The current digital-delivery policy conservatively revokes all grants from any partially or fully refunded order; a separate unrefunded purchase still provides access. Partial refunds can be managed in Stripe's dashboard and are reflected through webhooks. Never manually edit an order to `paid`.

References: [Stripe fulfillment](https://docs.stripe.com/checkout/fulfillment), [webhook verification](https://docs.stripe.com/webhooks/signature), [test payments](https://docs.stripe.com/testing).

## Payouts and balance

`PAYOUT_MODE=request` is the default. Administrators can create password-confirmed withdrawal requests and track `requested`, `under_review` or `cancelled` with notes and activity history. **This mode does not initiate a bank transfer and cannot mark a request as paid.** Do not put bank numbers or other sensitive banking data in request notes.

Set `PAYOUT_MODE=stripe` only after configuring Stripe and confirming that manual payouts are supported and enabled on your account. Requests call the **real Stripe Payouts API** with a stable idempotency key. The destination is the default bank account configured securely in Stripe; no bank-account entry form exists in this application. Stripe enforces balance, eligibility, currency and bank restrictions. If an API attempt has an uncertain result, use Review on the `submitting` request to retry the same request ID rather than creating a new transfer.

Payout status comes from signed provider webhooks or the explicit Sync status action. The first state returned by Stripe is normally `pending`; the UI never treats that as settled. Test-mode payouts do not transfer real money. Payout history records requests and provider events received by this deployment, including automatic payouts; it does not invent historical transfers. Unsupported accounts should use request mode and their provider's supported withdrawal channel.

Available and pending balances are read directly from Stripe. Gross sales, refunds and known fees come from this store's orders. Provider balances may include unrelated account activity. Net earnings are shown as awaiting fees until every relevant paid order has a confirmed fee in the same currency. Fee amounts are never estimated as a percentage. Sync provider records retrieves up to 50 missing order fees and the 100 most recent provider payouts; repeat to fill a longer fee backlog. Fulfillment remains independent of fee reporting.

Reference: [Stripe create payout API and eligibility](https://docs.stripe.com/api/payouts/create).

## Authentication and file security

- Admin entrance: four-digit server-verified PIN followed by username/password. The checkpoint is session-bound, expires after five minutes, and is consumed by session rotation on successful sign-in. PIN and credential attempts are throttled. Accounts with configured admin identities cannot bypass the checkpoint using customer email login.
- Random opaque sessions stored as SHA-256 token hashes in SQLite; 12-hour expiry, HttpOnly, SameSite=Lax cookies, Secure cookies under `NODE_ENV=production`. Login rotates the session and CSRF token.
- Passwords are salted and hashed with scrypt (`N=32768`, `r=8`, `p=1`, 64-byte output). Password reset links contain random one-use tokens stored only as hashes, expire in 30 minutes and revoke existing sessions.
- All mutation APIs require the configured Origin and a session-bound CSRF token, including login and multipart uploads. Every admin API checks an active database-backed admin role. Auth attempt throttles persist in SQLite; request/download/submission limits run per server process.
- Public routes are explicitly allowlisted. `.env`, database files, backend source, test artifacts and private PDFs cannot be served through the application. Do not expose the project directory through a separate static server or an Nginx document root.
- Private PDFs are stored outside the public asset tree. Every download checks the active user's entitlement, streams an attachment with `no-store`, and records successful delivery. Never place real pattern PDFs in `assets/` or use public external PDF URLs.
- Uploads are admin-only, size bounded and type validated. Images are decoded, resized and reencoded to WebP without metadata. PDFs are structurally parsed in a time/memory-bounded worker; encrypted PDFs, scripts, automatic actions and embedded attachments are rejected. Uploads cannot choose disk paths. Use trusted authoring sources; these checks do not claim to be antivirus scanning.
- CSP forbids inline JavaScript, framing and object embedding. Dynamic text is escaped. Admin pages use no public stylesheet or font imports.

Configure `SMTP_HOST`, `SMTP_PORT`, `SMTP_SECURE`, `SMTP_USER`, `SMTP_PASSWORD` and `MAIL_FROM` for password-reset email. Without email configuration, the reset form clearly reports that support is required. No reset tokens or credentials are logged or returned to clients. Contact submissions are stored in the admin inbox independently of SMTP.

## Database, deployment and backups

This release is designed for **one Node server process with a durable local disk**. SQLite uses WAL, foreign keys, prepared statements, transactions and indexes. Startup applies schema versions 1 and 2 idempotently; future migrations belong in the versioned migration path in `server/db.js`. Avoid ephemeral/serverless disk or multiple replicas sharing SQLite. Move the data layer to a server database before horizontal scaling.

Production requirements:

1. Set `NODE_ENV=production`, `APP_URL=https://your-domain`, a two-decimal store currency and the provider/email secrets in your deployment's secret manager.
2. Put the Node process behind a TLS reverse proxy. Forward the original host/protocol and set `TRUST_PROXY` to the **exact** number of trusted proxy hops (usually `1`), never a broad trust-all value. Block direct internet access to the Node port.
3. Persist `DATABASE_PATH`, `PRIVATE_DIR` and `UPLOAD_DIR` with permissions restricted to the service account. Back up all three. The original SVG artwork stays in `assets/images/`.
4. Run `npm ci --omit=dev`, seed the catalog once, bootstrap an admin, upload the actual PDFs and configure webhooks. Keep payment secrets out of public build configuration.
5. Use a process supervisor with restart-on-failure, monitor `/healthz`, application errors and Stripe webhook deliveries. Forward the raw webhook request unchanged; allow up to 21 MB for admin uploads and do not cache `/api/`.
6. Review the retained store policy copy for your actual business, jurisdiction, privacy/contact details and refund terms before launch. The project contains no supplied business policy or actual pattern files to certify.

A Dockerfile is included. Example (run seeding/admin creation with the same volumes and private environment):

```sh
docker build -t crochet-theory .
docker run --rm --env-file .env -p 3000:3000 \
  -v tct-data:/app/data -v tct-private:/app/private -v tct-uploads:/app/uploads \
  crochet-theory
```

Set `APP_URL` to your HTTPS origin when running production behind a proxy. For local Docker testing, override `NODE_ENV=development` and use `APP_URL=http://localhost:3000`. The image starts the app, not the seed or bootstrap commands automatically.

For a consistent backup, use `npm run db:backup` (SQLite's online backup API) and copy the private/upload directories to encrypted backup storage. Keep immutable uploaded files until all backups referencing them have expired. To restore, stop the app, restore the database and matching files, remove any stale WAL/SHM files from the old database instance, restore ownership, then start and verify a purchased download. Test restoration before relying on backups.

## Verification

```sh
npm test
npm run test:ui
npm audit
```

API tests use isolated in-memory databases, temporary files and an explicitly test-only payment adapter; webhook signatures use the real Stripe SDK. They cover authorization/CSRF, sessions and account disabling, hashing/reset, product CRUD and publication, validated uploads, provider-bound orders, forged/stale/duplicate webhooks, payment amount/currency/customer mismatches, purchased-only grants, private downloads, refunds/fees, coupons/reservations, moderation, analytics, inbox/settings and payouts.

Browser tests use installed Chrome or Edge on Windows, or Playwright Chromium elsewhere (`npx playwright install chromium`; optionally set `BROWSER_PATH`). They exercise real UI/API routes, customer signup/login/checkout/library/download/review, admin forms, storefront updates, and mobile/tablet/desktop layouts. They write screenshots and a report to ignored `test-results/`. The provider page is intercepted **only by the browser test**; application code contains no fake checkout or transfer path.

Automated adapter tests do not certify your live Stripe account, SMTP delivery, bank eligibility or deployed TLS configuration. Before accepting real money, complete a real Stripe test-mode purchase and refund on the deployed origin, confirm webhook delivery and the purchased-only library, test reset-email delivery, and verify supported payouts through the provider. No real payment or bank transfer was made during local development.

## Source map

```text
*.html                  Preserved public pages
assets/styles.css       Original public visual design (unchanged)
assets/store.css        Requested card alignment and responsive repairs
assets/app.js           Storefront API integration
admin/                  Independent admin HTML, CSS and JavaScript
server/app.js           HTTP middleware, authentication and storefront APIs
server/admin.js         Protected management APIs
server/payments.js      Checkout pricing, fulfillment and provider events
server/security.js      Sessions, hashing, authentication throttles and auditing
server/db.js            SQLite schema, transaction/query helpers
server/uploads.js       Bounded PDF validation worker launcher
server/pdf-worker.js    Structural PDF validation
server/catalog.json     Original catalog metadata, without fabricated metrics
server/seed.js           Idempotent catalog import
server/create-admin.js   Environment-based admin bootstrap
server/backup.js         Consistent SQLite backup command
tests/                   Isolated API and browser tests
```

## Customer email verification

New signups receive a single-use verification link that expires after 24 hours. Unverified new accounts cannot sign in. The verification page now uses a responsive Account → Verify → Ready flow with clear sent/success/error states, a persistent one-minute resend cooldown, and improved mobile accessibility. Verification emails include a branded HTML button plus a plain-text fallback. Existing accounts keep their access and can verify from their profile. Reviews require a purchased pattern; customers see their moderation status and may update pending or published reviews, which returns them to moderation. Admin > Users management shows distinct purchased patterns, current download access, confirmed orders and email status.

For Gmail SMTP, set SMTP_HOST=smtp.gmail.com, SMTP_PORT=587, SMTP_SECURE=false, SMTP_USER to the sending Gmail address, SMTP_PASSWORD to its Google app password, and MAIL_FROM to that sender in the private .env file. APP_URL must be the public HTTPS store URL so email links work for customers. Keep credentials out of .env.example. Restart the Node server after changing configuration.

Run node --env-file=.env tests/mail-check.js to verify the SMTP connection without sending email. Run npm test for API tests and npm run test:customer for signup, verification, user management and review browser checks.

## Development card-payment test mode

For local end-to-end testing, `.env` currently enables:

```env
PAYMENT_TEST_MODE=true
```

The checkout displays Cardholder Name, Card Number, Expiry, CVV, phone, country, state, city and ZIP. A valid-format test submission is marked successful and unlocks the purchased PDF, but **no real card is charged and no money is sent to Payoneer**. Raw PAN/expiry/CVV are discarded in the browser and are not posted to the server.

Before a real launch, set `PAYMENT_TEST_MODE=false`, use `NODE_ENV=production`, configure HTTPS, and connect only an approved Payoneer payment integration. See `PAYMENT_SETUP.md` and `PAYMENT_TEST_MODE.md`.


## Latest PDF/email update

See `PDF_EMAIL_FIX.md` for the PDF upload API fix, admin upload states, and verification frontend changes.

## Windows: `MODULE_NOT_FOUND` inside Express / http-errors

If Node reports `MODULE_NOT_FOUND` from `node_modules/http-errors`, `body-parser`, or `express`, the local dependency folder is incomplete or corrupted. This build intentionally does not ship `node_modules`.

From the project root run:

```powershell
npm run repair
npm run dev
```

Or double-click `FIX_WINDOWS_DEPENDENCIES.bat`. The repair removes the broken `node_modules`, verifies the npm cache, and installs the exact versions from `package-lock.json` using `npm ci`.

Local URLs:

- Store: `http://localhost:3000`
- Admin: `http://localhost:3000/admin`
