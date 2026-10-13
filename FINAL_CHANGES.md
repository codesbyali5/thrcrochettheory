# Final checkout changes

- Port remains `3000`.
- Cart coupon form was removed from the customer checkout summary.
- The cart checkout action is now a compact **Checkout** button.
- Clicking Checkout switches the cart area to a focused card-payment-only view; Back to basket restores the basket.
- Development card checkout accepts any numeric 14–19 digit card value without a Luhn requirement. Expiry still must be a future `MM/YY` value and CVV must be 3–4 digits.
- Customer-facing button/status copy now says **Complete payment**, not **test payment**.
- Development mode still does not transmit raw PAN/expiry/CVV to the Node server. Only card brand and last four digits are sent for the simulated order receipt.
- Navbar/product basket icons now use the clearer `shopping-basket-2` icon.

Production payment safety is unchanged: when `PAYMENT_TEST_MODE=false`, real card details must be handled by the approved Payoneer hosted/embedded checkout, not by this server.
