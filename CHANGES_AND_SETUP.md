# Latest payment-test update — 2026-09-14

- Added the complete **International Card Payment** test form: Cardholder Name, Card Number, Expiry Date, CVV, Phone with country code, full Country list, Province/State, City and ZIP Code.
- Added `PAYMENT_TEST_MODE=true` for development testing. A valid-format test submission completes the order and unlocks the purchased digital PDF without contacting or charging a real card.
- Raw card number, expiry and CVV never leave the browser in test mode; only brand + last four digits are sent as non-sensitive test metadata.
- Added `server/test-card.js`. The server refuses raw PAN/CVV and disables simulated success whenever `NODE_ENV=production`.
- Real mode remains provider-controlled: set `PAYMENT_TEST_MODE=false` and use only an approved Payoneer integration.
- Automated Node suite after this update: **40 passed, 0 failed** using the same temporary Linux Sharp test shim described below.

---

# THE CROCHET THEORY — Updated Build

Updated: 14 September 2026

## What was changed

### 1. Payoneer payment flow
- Added Payoneer as the primary payment provider.
- Checkout is for digital products only: no street/shipping address is requested.
- Checkout UI contains: International Card Payment, cardholder name, secure card-number/expiry/CVV placeholders, phone with country code, country, province/state, city, and ZIP/postal code.
- Raw card number, expiry, and CVV are intentionally **not sent to or stored by this application**. Customers are redirected to the Payoneer-hosted payment page to enter sensitive card details.
- The order is unlocked only after the server confirms the Payoneer payment state.
- Added a Payoneer order sync action in the admin order view plus a manual confirmation fallback that requires admin password re-authentication and a provider reference.
- `PAYOUT_MODE=request` remains an internal payout-request record. Actual withdrawal is performed from the Payoneer account/dashboard.

### 2. Shop filters
- Replaced the always-visible filter sidebar with a slide-out filter drawer.
- Added backdrop, close button, clear filters, active filter count, and "Show patterns" action.
- Responsive behavior is included for mobile/tablet/desktop.

### 3. Pattern cards
- Reduced product-card size slightly without redesigning the existing visual identity.
- Added optional hover-preview video. When a pattern has a video, hovering/focusing the product media starts the muted looped preview and leaving pauses/resets it.

### 4. Admin pattern editor
- Added MP4/WebM preview-video upload and remove controls.
- Video upload limit: 50 MB.
- Fixed downloadable PDF upload flow.
- PDF validation now accepts a real `.pdf` by file signature/EOF instead of depending on unreliable browser MIME values, while still rejecting active-content PDFs.
- PDF limit: 25 MB.
- Image upload remains validated and re-encoded.

### 5. User dashboard/profile
- Redesigned profile area into a more professional account layout.
- Added profile picture upload.
- Uploaded avatar is cropped/re-encoded to WebP on the server and stored on the user account.
- The profile image is also shown in the main website navigation for logged-in users.

### 6. Admin/security/settings
- Added provider-aware finance/order information for Payoneer.
- Added an Administrator Security section that can rotate the admin PIN and admin password after current-password re-authentication.
- Existing order/user/product security controls are preserved.

### 7. Currency and local development
- PKR is supported by the store backend.
- Development URL is standardized to `http://localhost:3000` in the included environment template.

## Important Payoneer setup

This project does not contain your Payoneer API credentials. Payoneer must approve/enable the relevant payment/API product for your account before live card payments can work.

Fill these values in `.env` after Payoneer provides/authorizes them:

```env
PAYMENT_PROVIDER=payoneer
PAYONEER_API_BASE=https://api.sandbox.payoneer.com/v4
PAYONEER_ACCOUNT_ID=YOUR_PAYONEER_ACCOUNT_ID
PAYONEER_ACCESS_TOKEN=YOUR_PAYONEER_ACCESS_TOKEN
PAYOUT_MODE=request
```

For production, use the API base/credentials supplied by Payoneer for your approved live integration. Do not guess a production URL or reuse sandbox credentials.

## Email and admin secrets

The delivered `.env` has been sanitized. Previously exposed credentials are not included in this package.

Before using email verification in a real deployment:

```env
SMTP_USER=YOUR_EMAIL
SMTP_PASSWORD=YOUR_NEW_APP_PASSWORD
MAIL_FROM=YOUR_EMAIL
GMAIL_USER=YOUR_EMAIL
GMAIL_APP_PASSWORD=YOUR_NEW_APP_PASSWORD
OTP_SIGNING_SECRET=GENERATE_A_LONG_RANDOM_SECRET
```

Also rotate any admin/Gmail credentials that were previously shared or exposed. Admin PIN/password can be rotated from the admin Settings/Security page after login.

## Run locally

```bash
npm install
npm run dev
```

Then open:

```text
http://localhost:3000
```

Do not use VS Code Live Server for the complete application. The backend must run because authentication, SQLite, uploads, order verification, and protected downloads are server features.

## Files changed

- `.env` — sanitized local configuration, Payoneer selected, port 3000, PKR.
- `.env.example` — safe configuration template including Payoneer.
- `PAYMENT_SETUP.md` — payment-provider setup and security notes.
- `README.md` — updated run/setup guidance.
- `patterns.html` — filter drawer markup.
- `policy.html` — updated payment/privacy wording.
- `assets/app.js` — Payoneer checkout UI/flow, filter drawer, hover video, nav avatar, PKR formatting.
- `assets/store.css` — smaller cards, filter drawer, video, secure-payment and avatar styles.
- `assets/dashboard.js` — profile redesign logic and avatar upload.
- `assets/dashboard.css` — professional profile/account styling.
- `admin/admin.js` — product video upload, PDF flow, Payoneer order actions, admin security form.
- `admin/admin.css` — admin video-preview styles.
- `server/app.js` — Payoneer checkout integration, account avatar route, provider sync, media serving.
- `server/admin.js` — fixed PDF upload, video upload, Payoneer admin actions, security credential rotation.
- `server/db.js` — migration for user avatars, product videos, and Payoneer request records.
- `server/payoneer.js` — Payoneer payment-request creation/status synchronization.
- `server/security.js` — avatar included in public user model.
- `server/validation.js` — video validation and updated product schema.
- `server/uploads.js` / `server/pdf-worker.js` — hardened PDF validation worker settings.
- `tests/payoneer.test.js` — Payoneer payment-security tests.

## Final verification performed

- JavaScript syntax checks passed for the changed server, admin, dashboard, storefront, and test files.
- Full Node test suite after the original update: **38 passed, 0 failed**. The latest payment-test update adds two tests; the current suite is **40 passed, 0 failed**.
- Payoneer tests confirm raw card fields are rejected by the application server and that only a verified provider payment grants the purchased digital entitlement.
- Secret scan confirmed the previously exposed card/app-password/admin-password strings are not present in deliverable source files.

### Test-environment note
The uploaded archive contained Windows-native `sharp` binaries, while the build/test container runs Linux. For the automated test pass, a temporary test-only Sharp compatibility shim was used and then restored. `node_modules` is intentionally excluded from the final ZIP. Running `npm install` on your Windows machine installs the correct native Sharp package for Windows.

---

## Latest update — PDF upload API + verification frontend

The pattern PDF upload path was made more tolerant of legitimate exported PDFs while preserving private storage and structural security checks. The admin uploader now shows clear upload/validation states, page count and file size, and gives better messages for 413/proxy limits or an unwritable private directory.

The customer `verify.html` experience was redesigned with a responsive Account → Verify → Ready flow, branded email state, persistent resend cooldown, success/error states, and a branded HTML verification email.

See `PDF_EMAIL_FIX.md` for the exact files and validation notes.
