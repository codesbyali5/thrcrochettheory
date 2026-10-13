# International card payment setup — THE CROCHET THEORY

This build has **two payment modes** so the complete digital-product purchase flow can be tested safely now and switched to an approved Payoneer flow later.

## 1) Development test mode — included and enabled

The included `.env` contains:

```env
NODE_ENV=development
PAYMENT_PROVIDER=payoneer
PAYMENT_TEST_MODE=true
```

In this mode the checkout shows the complete requested form:

- International Card Payment
- Cardholder Name
- Card Number
- Expiry Date
- CVV
- Phone Number with country code
- Country — full world-country list
- Province / State
- City
- ZIP Code

The browser performs basic card-format, Luhn, expiry and CVV validation. **No real payment is processed.** After a valid test submission, the server creates the real order from database prices, marks that order as a test-paid order, grants only the purchased digital pattern entitlement and opens the normal success/download page.

### Important test-mode security behavior

Raw card number, expiry and CVV are **not sent to the Node server, not stored in SQLite, not logged and not saved in localStorage**. Before the request is sent, the browser discards those values and sends only the card brand and last four digits as a non-sensitive test receipt reference.

Use test data only. Do not enter a real card while `PAYMENT_TEST_MODE=true` because no provider is being contacted and no money will move.

The backend also blocks test-card checkout automatically when `NODE_ENV=production`, so the test success shortcut cannot be used as the production payment system.

## 2) Real Payoneer mode — enable after provider approval

To disable the simulated success flow:

```env
PAYMENT_TEST_MODE=false
PAYMENT_PROVIDER=payoneer
```

Then add only credentials/endpoints officially issued for your approved Payoneer integration. Never invent API credentials or place merchant access tokens in browser JavaScript.

Current real-mode fallback in this project is provider-hosted Payoneer collection: sensitive card details stay with the payment provider and the website waits for provider confirmation before unlocking downloads.

If your approved Payoneer Checkout account provides an **embedded secure checkout** integration, its provider-controlled card fields can be mounted into the same visual form. Do not replace them with ordinary HTML card inputs that post PAN/CVV to this server.

## Real payment expectations

Payoneer's public Checkout information says its online checkout can accept major cards and can settle checkout revenue into the Payoneer account, but payment methods and Checkout availability depend on account, market and integration eligibility. A test success in this project does **not** mean a real card was charged or that Payoneer has approved your store.

## Digital products

There is no shipping/street-address section. The payment form asks only for card/billing contact fields needed for the requested international-card flow. A successful order unlocks the purchased PDF in the user's library and on the success page.

## Run locally

```bash
npm install
npm run dev
```

Open:

```text
http://localhost:3000
```

Do not use VS Code Live Server for this full application because authentication, SQLite, uploads, protected downloads and checkout are Node server features.
