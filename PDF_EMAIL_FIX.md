# PDF Upload + Email Verification Fix

This update keeps the existing THE CROCHET THEORY project and changes only the pattern PDF upload flow and customer email-verification experience.

## 1. Pattern PDF upload API fix

Updated files:

- `server/uploads.js`
- `server/pdf-worker.js`
- `server/admin.js`
- `admin/admin.js`
- `admin/admin.css`
- `tests/pdf-upload-regression.test.js`

Changes:

- Accepts normal PDF exports more reliably instead of requiring `%PDF-` at the exact first byte.
- Looks for the PDF header within the first 1 KiB and `%%EOF` within the final 1 MiB.
- Keeps the 25 MB maximum and private-file storage.
- Removes the old raw-binary keyword scan that could reject a legitimate compressed PDF by accident.
- Keeps structural checks for JavaScript, executable actions and embedded files.
- Gives the validator more time/memory for real crochet-pattern PDFs with many images.
- Returns PDF page count and file size to the admin interface after a successful upload.
- Removes a newly-written private file if the database insert fails, avoiding orphaned files.
- Gives a clear error when `PRIVATE_DIR` is not writable.
- Adds clearer 413 / proxy upload-limit messaging.
- Admin UI now checks file size/type before upload and shows uploading, success and error states.

### PDF requirements

- Maximum size: 25 MB
- Unencrypted PDF
- 1–1,000 pages
- No JavaScript, executable actions or embedded files

If a hosting provider has a lower request-body limit than 25 MB, that provider/proxy limit must also be increased or the PDF must be optimized below that limit.

## 2. Improved email-verification frontend

Updated files:

- `verify.html`
- `assets/verify.js`
- `assets/store.css`
- `server/email-verification.js`
- `tests/verification-ui-static.test.js`
- `tests/customer-ui.js`

Changes:

- Premium two-panel responsive verification UI.
- Account → Verify → Ready progress indicator.
- Clear verification states for sent, verifying, success and expired/used links.
- Email address chip when the address is known from signup/resend.
- Persistent 60-second resend countdown for the current browser session.
- Better server-unreachable and resend-error messages.
- Mobile responsive layout and improved accessibility/status announcements.
- Remix Icon stylesheet is now loaded on the verification page.
- Branded HTML verification email plus plain-text fallback.
- Verification link remains single-use and expires after 24 hours.

## Run

```bash
npm install
npm run dev
```

Open:

```text
http://localhost:3000/admin
```

For email verification, configure SMTP in `.env` and keep `APP_URL` equal to the URL customers actually open.

## Latest validation

The latest changed JavaScript files pass `node --check`.

Focused regression tests run successfully:

```text
2 tests passed
0 failed
```

These focused tests cover the PDF envelope checks and the required verification-page UI structure. The complete dependency-based API/browser suite should be run after `npm install` on the target machine.
