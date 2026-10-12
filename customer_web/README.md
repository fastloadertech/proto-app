# Proto customer web

A separate React + TypeScript + Vite storefront for browsing Proto's catalog. The existing Flutter customer app and shared Loader backend remain separate.

## Run locally

Requires a current Node.js installation. From `customer_web`:

```bash
npm install
npm run dev
```

Open the URL printed by Vite (normally `http://localhost:5173`). The default mode is **demo**. It uses `src/data/demoCatalog.ts`, which mirrors the Flutter app's local catalog with demo IDs, and branded artwork exported from Flutter's `ProductArtwork` painter. No backend is needed.

## Live catalog configuration

The optional live mode reads the existing **public** catalog endpoints without authentication:

- `GET /api/v1/catalog/categories`
- `GET /api/v1/catalog/products?active=true&sort=newest`

To run against a locally running backend, set these Vite environment variables in your shell before starting Vite:

```powershell
$env:VITE_PROTO_CATALOG_MODE = 'live'
$env:VITE_PROTO_API_BASE_URL = 'http://localhost:3101'
npm run dev
```

For local development, copy `.env.example` to `.env.development.local`; that file is ignored and is not loaded by a production build. Do not commit environment files or place secrets in `VITE_` values, which are embedded in the client bundle. Development defaults to demo mode and uses `http://localhost:3101` only if live mode is selected without an API URL. A production build must set `VITE_PROTO_CATALOG_MODE` explicitly to `demo` or `live`; otherwise the app displays a configuration error. Production live mode additionally requires an explicit HTTPS `VITE_PROTO_API_BASE_URL` origin. An invalid or missing configuration shows an error instead of switching to demo data. The backend must permit the web origin through its CORS configuration.

The API mapper consumes the current catalog DTO: category `id`, `slug`, `name`, nullable `description`; product `id`, `sku`, `name`, nullable `description`, decimal-string `price`, `currency`, nullable `imageUrl`, nullable `stockQuantity`, `available`, nested `category`, and `createdAt`. The shared GET client reports network, HTTP, timeout, malformed JSON, and invalid DTO failures without exposing server response bodies. Live failures show a retryable error. The app does not silently replace live data with demo products.

## Customer authentication assessment (Day 6)

The shared backend has a **development-only** customer login at `POST /api/v1/auth/customer/login`. It accepts `{ phone, code }`: an E.164 phone number and a six-digit development code configured only on the server. For an existing active customer it returns `{ accessToken, role: "CUSTOMER", user }`, where `user` is a selected profile containing ID, name, phone, nullable email, role, active flag, and timestamps. `GET /api/v1/auth/me` requires a Bearer JWT and is restricted to customers. Separate driver login and profile routes require the `DRIVER` role; no administrator role exists. The JWT guard checks signature, issuer, audience, expiry, account role, and current account status.

This is **not a public customer sign-in flow**. The customer and driver login routes use the same server-configured development code and reject requests in production. There is no customer registration, code delivery or phone ownership check, rate limiting, session refresh, server logout, or token revocation. Proto therefore does not expose a login form, request a development code, or hold an access token. The **You** page remains an honest local account preview. Customer login would not grant access to the local demo admin or to any driver route.

Before enabling customer sign-in, the backend and web client need an agreed production contract:

1. A way to provision customers and verify control of their phone or another identity, with short-lived, per-user challenges. Responses must not reveal whether an account exists. Validate phone and challenge input server-side, and rate-limit by account, phone, and network source with abuse monitoring.
2. A browser session strategy with an explicit expiry and renewal policy. Prefer a server-managed `Secure`, `HttpOnly`, `SameSite` cookie with CSRF and origin protections, or an equivalent backend-for-frontend session. Never place access tokens, verification codes, or customer contact details in URLs, logs, Vite variables, or browser local storage.
3. A customer-only profile read, session expiry handling, and server-side logout/revocation. A 401 must clear the web session; a 403 must deny access and fail closed if the account role is wrong. Other network failures should show a retryable error without claiming the user is signed in. Profile and login responses need a documented versioned DTO, including the safe user fields and role.
4. Server-enforced customer/driver/admin authorization on every protected route. The demo admin remains separate until a real admin role and protected admin APIs exist. Checkout and order history stay local demos until authentication, pricing, stock reservation, payment and delivery behavior are complete and verified.

Once that contract exists, Proto can add a typed auth adapter and a memory-only session controller, validate response role and shape, and test successful login, invalid credentials, malformed responses, API failures, expiry and logout. No production auth endpoint or browser session contract was added on Day 6.

## Shared backend assessment (Day 5)

The shared backend was inspected at `D:\loader-app\backend` on `main`; Loader's Flutter client is at `D:\loader-app\mobile`. The backend uses NestJS, Prisma, and PostgreSQL. Its public `GET /api/v1/catalog/categories` and `GET /api/v1/catalog/products?active=true&sort=newest` routes supply the live web catalogue. Products with zero stock remain visible; `stockQuantity: null` means stock is not tracked. Loader continues to use its separate, opt-in authenticated driver API. No backend or Loader files were changed for this integration.

The backend has no product/inventory write route, admin role, admin order list, or admin status update route. In live catalogue mode, the Proto admin reads the backend's price and tracked stock but is **read only**; it marks null stock as untracked. Demo orders and their status annotations remain in browser storage. The web checkout never calls `POST /api/v1/orders`. That existing endpoint requires a customer JWT, validates current prices and stock, and creates a delivery job; it does not reserve or decrement stock. Production customer login, payment, and delivery readiness are not available for this web flow.

For future inventory editing, the backend needs an authenticated admin role and a protected product update contract, for example `PATCH /api/v1/admin/products/:id/inventory` accepting a canonical two-decimal INR price and non-negative integer stock quantity, validating both server-side against the database schema and returning the updated product and version/timestamp. The client would need to reconcile its catalogue from that response or refetch after success, and retain the previous values on failure. Real order management likewise needs authorized admin list and status-transition endpoints. These are **proposed contracts**, not current routes.

Before a production deployment, configure `CORS_ORIGIN` on the backend as an explicit comma-separated list of trusted web origins; its current development value and code default allow all origins. Keep `DATABASE_URL`, `JWT_SECRET`, and development login code server-side. The shared API sanitizes internal server errors and validates request DTOs, but the pre-existing legacy delivery creation route needs a separate authorization review. For Day 5, the existing backend was started locally without migrations; its public catalogue returned 7 categories and 14 products, and the web mapper successfully loaded that response. Browser layout verification remains separate.

## Real ordering workflow assessment (Day 7)

**Verified backend behavior.** `POST /api/v1/orders`, `GET /api/v1/orders`, and `GET /api/v1/orders/:id` require an active customer Bearer JWT; a driver token cannot use them, and reads are scoped to the customer. The create DTO accepts 1–50 distinct product UUIDs with integer quantities of 1–99 and a delivery address with required `line1` and `city`. Optional item prices and top-level totals are accepted for compatibility but ignored. The service reads current database prices, product/category activity and tracked stock, rejects missing or unavailable products and mixed currencies, and calculates the subtotal with decimal arithmetic. It snapshots product names, unit prices and the address. A Prisma transaction creates a `PENDING` order, its items and an `AVAILABLE` Loader delivery job; failure to create the job rolls the order back. The order has a UUID ID and unique reference, and the job's order ID is unique. Customer detail can include the linked delivery status; assigned driver status changes update the order in a transaction.

**Why Proto customer web does not submit to this route.** Customer login only works with a shared development code in development/test, so the web app has no production customer session. Stock is checked from database rows but is never reserved or deducted: two requests can each buy the last tracked unit. Every successful retry creates another order and job because there is no idempotency key or duplicate-request record. A changed catalog price is used at creation without a prior customer-approved server quote. Delivery fee is always zero, there are no discount, delivery-area or delivery-option rules, the pickup hub is a placeholder, and the job becomes available to drivers immediately. Payment and cancellation/stock-restoration workflows are absent. This route is a development foundation, not a production checkout contract.

The current web bag recalculates an **illustrative item subtotal** from its last loaded catalog in integer paise. `createDemoSubmitController` prevents repeated clicks only in that local checkout instance, creates a `DEMO-` reference, and writes a limited local history without contact or street address. It never calls the order API, including in live catalog mode. Its cached price, availability flag, sample location and local single-flight guard cannot decide a real price, remaining stock, delivery charge or delivery eligibility. Demo history and status annotations must never be presented as backend orders.

**Proposed production contract and sequence — not existing API behavior:**

1. Establish production customer identity and a secure browser session as described in the Day 6 assessment. The server must derive the customer ID from that session and enforce customer-only access on create, list and detail; the browser must not supply an authoritative customer ID or reuse driver credentials.
2. Submit only canonical live-catalog product UUIDs and requested quantities, plus a validated delivery address and an agreed delivery option. The current form's `locality` has no separate backend DTO field, and its 10-digit phone must be normalized to E.164 if sent; settle these mappings and supported delivery areas before wiring the form. Never send browser-calculated prices, stock, discounts or totals as authority.
3. Have the server check current product price, activity, currency, stock, delivery serviceability and discount eligibility, then return a time-limited, server-calculated quote showing item subtotal, discount, delivery fee, tax if applicable, currency and final total. Require the customer to review a changed price or unavailable item before creation; define quote expiry and the payment or cash-on-delivery policy before accepting an order. No quote or delivery-pricing route exists today.
4. At creation, enforce quantity limits and atomically reserve or conditionally deduct tracked stock with the order write, so concurrent buyers cannot both take the final unit. Define whether `stockQuantity: null` is sellable without tracking. Roll back on any order/job failure; release reserved stock on cancellation, expiry or payment failure according to a documented state machine. Browser stock checks remain informational.
5. Keep order items, address, server totals and a unique reference as immutable snapshots. Persist the order and its fulfillment handoff atomically or through a recoverable outbox; publish a real Loader job only when payment, pickup location and fulfillment readiness allow it. Define authorized transitions for confirmation, preparation, dispatch, delivery, cancellation and refunds, including how job and order states reconcile after failures. The current driver path only synchronizes pickup, out-for-delivery and delivered transitions.
6. Require a server-enforced idempotency key scoped to the customer and request contents. Repeating the same request must return the original result; reusing a key with different contents must fail. After a timeout or lost response, the client must reconcile by that key before retrying. An expired session must stop submission, a stale quote or stock conflict must return the customer to review, and a server/network failure must never silently create a demo order or claim success. Define safe, non-sensitive error responses and recovery for uncertain outcomes.

Only after those guarantees are implemented and tested should Proto customer web add a typed order adapter, response validation and a separate real order history. Keep the existing demo path explicit and isolated. No ordering endpoint, request helper, backend change, migration or payment flow was added for Day 7.

## Checks

```bash
npm run typecheck
npm test
npm run build
```

## Storefront scope and local state

The home, categories, and product listing screens follow the Flutter app's colors, Inter font, navigation, and product artwork. Search, category filtering, availability filtering, sorting, product details, favorites, and a local bag work in the browser. The three sample delivery locations only change the displayed location.

Bag quantities and favourites are saved in this browser's `localStorage` under the versioned keys `proto:web:bag:v1` and `proto:web:favourites:v1`. Invalid stored entries are ignored. Product IDs absent from the current catalogue are hidden but retained, so switching between demo and live catalogues does not erase saved items; checkout clears only items from the current catalogue. If browser storage is unavailable, they still work until the page is refreshed. Bag lines and totals are recalculated from current catalogue prices in integer paise; neither bag nor favourites are synced to a server.

The bag leads to an **explicitly local demo checkout** with Indian contact and address validation, an item-only total, confirmation reference, and demo order history. No delivery charge is quoted, so the displayed demo total is not a final real-world payable amount. No payment is collected and no delivery is scheduled. The full name, phone number, and street address appear on the in-session confirmation only. A validated history of up to 20 demo orders is saved separately under `proto:web:demo-orders:v1`, without contact or street address details. If storage is blocked, the order still completes in memory and the confirmation warns that it will disappear after refresh.

Only the catalog endpoints above are connected in optional live mode. The existing real order API requires customer authentication, which this web app does not provide; even in live catalog mode, checkout remains a local demo. No account, real order placement, payment, or delivery tracking is connected on web. The 12 MIN badge and sample locations reproduce the Flutter design and are illustrative, not live delivery estimates. Live catalog products use their API image URL; those without one use a branded placeholder. The app does not silently substitute demo products for a failed live request.

## Local demo admin

From the storefront, open **You → Open demo admin**. The dashboard reads the same catalogue and local demo order history as the customer view. Its Dashboard, Inventory, and Demo orders tabs show product counts, inventory information, and saved demo order records.

In **demo catalogue mode**, admin inventory starts with **sample values**: 12 units for catalogue-available products and 0 for unavailable products. Quantities 1–5 are marked low stock. Validated edits are stored separately under `proto:web:admin:inventory:v1`. They affect only the admin preview; customer catalogue prices and availability are unchanged. Adding products is not supported by this local overlay. In **live catalogue mode**, the admin shows the backend's price and nullable stock quantity, ignores local inventory edits, and does not offer edit controls.

Demo order statuses are local review annotations: **Demo confirmed**, **Demo reviewed**, and **Demo archived**. Status updates use the existing versioned `proto:web:demo-orders:v1` history key and remain visible after refresh when browser storage works. History contains item snapshots and city, state, and PIN code, but no stored name, phone, or street address. If storage is blocked, admin edits remain in memory only until refresh.

This admin view has no sign-in or authorized backend mutation API. Its live inventory data is a read-only public catalogue preview, not a production administration tool.

The Flutter packaging PNGs in `public/images/proto-*.png` can be regenerated from the current Flutter catalog by running this command in `D:\proto-app\flutter_app`:

```powershell
& "D:\proto-app\.tools\flutter\bin\flutter.bat" test --no-pub ..\customer_web\scripts\export_flutter_artwork_test.dart
```
