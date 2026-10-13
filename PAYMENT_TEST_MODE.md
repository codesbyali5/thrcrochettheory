# Payment test mode — quick reference

## Enabled now

```env
NODE_ENV=development
PAYMENT_TEST_MODE=true
PAYMENT_PROVIDER=payoneer
```

Test checkout accepts the complete card/billing UI and then simulates a successful payment. It does not contact Payoneer and does not charge a card.

## Card data handling

`assets/app.js` validates card number, expiry and CVV in the browser. Before calling `/api/checkout`, it removes those sensitive values and sends only:

```json
{
  "card": {
    "brand": "visa",
    "last4": "4242"
  }
}
```

`server/test-card.js` rejects a request if raw `cardNumber`, `cvv`, `cvc`, `expiry` or `expiryDate` fields are sent to it.

## Real mode later

```env
NODE_ENV=production
PAYMENT_TEST_MODE=false
PAYMENT_PROVIDER=payoneer
```

Production also requires an HTTPS `APP_URL` and approved provider configuration. The simulated payment path is unavailable in production even if someone accidentally leaves `PAYMENT_TEST_MODE=true`.
