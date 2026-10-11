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

Vite also supports a local `.env.local` derived from `.env.example`; do not commit environment files or place secrets in `VITE_` values, which are embedded in the client bundle. Set the API base URL explicitly for production live builds. The backend must permit the web origin through its existing CORS configuration. The web app does not change backend settings.

The API mapper consumes the current catalog DTO: category `id`, `slug`, `name`, nullable `description`; product `id`, `sku`, `name`, nullable `description`, decimal-string `price`, `currency`, nullable `imageUrl`, `available`, nested `category`, and `createdAt`. Live failures show a retryable error. The app does not silently replace live data with demo products.

## Checks

```bash
npm run typecheck
npm test
npm run build
```

## Storefront scope and local state

The home, categories, and product listing screens follow the Flutter app's colors, Inter font, navigation, and product artwork. Search, category filtering, availability filtering, sorting, product details, favorites, and a local bag work in the browser. The three sample delivery locations only change the displayed location.

Bag quantities and favourites are saved in this browser's `localStorage` under the versioned keys `proto:web:bag:v1` and `proto:web:favourites:v1`. Invalid stored entries and IDs absent from the loaded catalog are ignored. If browser storage is unavailable, they still work until the page is refreshed. Bag lines and totals are recalculated from current catalog prices in integer paise; neither bag nor favourites are synced to a server.

The bag leads to an **explicitly local demo checkout** with Indian contact and address validation, an item-only total, confirmation reference, and demo order history. No delivery charge is quoted, so the displayed demo total is not a final real-world payable amount. No payment is collected and no delivery is scheduled. The full name, phone number, and street address appear on the in-session confirmation only. A validated history of up to 20 demo orders is saved separately under `proto:web:demo-orders:v1`, without contact or street address details. If storage is blocked, the order still completes in memory and the confirmation warns that it will disappear after refresh.

Only the catalog endpoints above are connected in optional live mode. The existing real order API requires customer authentication, which this web app does not provide; even in live catalog mode, checkout remains a local demo. No account, real order placement, payment, or delivery tracking is connected on web. The 12 MIN badge and sample locations reproduce the Flutter design and are illustrative, not live delivery estimates. Live catalog products use their API image URL; those without one use a branded placeholder. The app does not silently substitute demo products for a failed live request.

## Local demo admin

From the storefront, open **You → Open demo admin**. The dashboard reads the same catalog and local demo order history as the customer view. Its Dashboard, Inventory, and Demo orders tabs show product counts, sample stock levels, editable demo prices and quantities, and saved demo order records.

The Product model has no stock quantity, so admin inventory starts with **sample values**: 12 units for catalog-available products and 0 for unavailable products. Quantities 1–5 are marked low stock. Validated edits are stored separately under `proto:web:admin:inventory:v1`. They affect only the admin preview; customer catalog prices and availability are unchanged. Adding products is not supported by this local overlay.

Demo order statuses are local review annotations: **Demo confirmed**, **Demo reviewed**, and **Demo archived**. Status updates use the existing versioned `proto:web:demo-orders:v1` history key and remain visible after refresh when browser storage works. History contains item snapshots and city, state, and PIN code, but no stored name, phone, or street address. If storage is blocked, admin edits remain in memory only until refresh.

This admin view has no sign-in, backend database, production inventory connection, or real order actions. It is a local prototype, not a production administration tool.

The Flutter packaging PNGs in `public/images/proto-*.png` can be regenerated from the current Flutter catalog by running this command in `D:\proto-app\flutter_app`:

```powershell
& "D:\proto-app\.tools\flutter\bin\flutter.bat" test --no-pub ..\customer_web\scripts\export_flutter_artwork_test.dart
```
