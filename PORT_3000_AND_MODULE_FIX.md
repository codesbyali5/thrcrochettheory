# Port 3000 + MODULE_NOT_FOUND Fix

This build uses **port 3000** everywhere in local development.

## Why the Express error happened

The stack trace starts inside `node_modules/http-errors` / `body-parser` / `express`. That means the website source is loading, but the local `node_modules` installation is incomplete or corrupted. It is not a checkout, PDF, or Express application-code error.

## Recommended Windows fix

Open PowerShell in this project folder and run:

```powershell
npm run repair
npm run dev
```

Or double-click:

```text
FIX_WINDOWS_DEPENDENCIES.bat
```

The repair command:

1. Deletes the existing `node_modules` folder.
2. Runs `npm cache verify`.
3. Runs `npm ci` from the included `package-lock.json`.
4. Leaves the project ready for `npm run dev`.

Then open:

```text
http://localhost:3000
```

Admin:

```text
http://localhost:3000/admin
```

Do not use VS Code Live Server / Go Live for this project because the API, authentication, uploads, email verification, payments, and protected downloads require the Node server.
