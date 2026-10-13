# PDF upload 400 fix

The admin pattern PDF upload path was made more compatible with real-world PDF exporters.

## What was fixed

- Valid PDFs that contain harmless `OpenAction` / `AA` metadata are no longer rejected.
- The upload still blocks encrypted/password-protected PDFs and active content such as JavaScript, launch actions, embedded files, rich media, submit-form actions, and imported data.
- The strict parser is now used for page-count metadata instead of being allowed to reject an otherwise safe PDF just because that PDF uses a structure the parser cannot fully inspect.
- The PDF header probe accepts small BOM/metadata prefixes within the first 4 KiB.
- The upload response now includes compatibility information when page count cannot be detected.
- Admin API error handling now shows `error`, `message`, or `details` from the server instead of falling back to a generic `Request failed (400)` whenever possible.
- Admin JS/CSS are served with no-store/cache-busting so the browser does not keep an older broken uploader.

## Upload requirements

- PDF file
- Maximum 25 MB
- Not encrypted/password-protected
- No executable JavaScript, embedded files, launch actions, or rich media

After replacing the project, run `npm ci` (or `npm run repair` if dependencies are broken), then `npm run dev` and open `http://localhost:3000/admin`.
