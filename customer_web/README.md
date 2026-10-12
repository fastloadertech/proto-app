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

## Shared backend assessment (Day 5)

The shared backend was inspected at `D:\loader-app\backend` on `main`; Loader's Flutter client is at `D:\loader-app\mobile`. The backend uses NestJS, Prisma, and PostgreSQL. Its public `GET /api/v1/catalog/categories` and `GET /api/v1/catalog/products?active=true&sort=newest` routes supply the live web catalogue. Products with zero stock remain visible; `stockQuantity: null` means stock is not tracked. Loader continues to use its separate, opt-in authenticated driver API. No backend or Loader files were changed for this integration.

The backend has no product/inventory write route, admin role, admin order list, or admin status update route. In live catalogue mode, the Proto admin reads the backend's price and tracked stock but is **read only**; it marks null stock as untracked. Demo orders and their status annotations remain in browser storage. The web checkout never calls `POST /api/v1/orders`. That existing endpoint requires a customer JWT, validates current prices and stock, and creates a delivery job; it does not reserve or decrement stock. Production customer login, payment, and delivery readiness are not available for this web flow.

For future inventory editing, the backend needs an authenticated admin role and a protected product update contract, for example `PATCH /api/v1/admin/products/:id/inventory` accepting a canonical two-decimal INR price and non-negative integer stock quantity, validating both server-side against the database schema and returning the updated product and version/timestamp. The client would need to reconcile its catalogue from that response or refetch after success, and retain the previous values on failure. Real order management likewise needs authorized admin list and status-transition endpoints. These are **proposed contracts**, not current routes.

Before a production deployment, configure `CORS_ORIGIN` on the backend as an explicit comma-separated list of trusted web origins; its current development value and code default allow all origins. Keep `DATABASE_URL`, `JWT_SECRET`, and development login code server-side. The shared API sanitizes internal server errors and validates request DTOs, but the pre-existing legacy delivery creation route needs a separate authorization review. For Day 5, the existing backend was started locally without migrations; its public catalogue returned 7 categories and 14 products, and the web mapper successfully loaded that response. Browser layout verification remains separate.

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
