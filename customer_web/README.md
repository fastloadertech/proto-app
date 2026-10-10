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

## Day 1 storefront scope

The home, categories, and product listing screens follow the Flutter app's colors, Inter font, navigation, and product artwork. Search, category filtering, availability filtering, sorting, product details, favorites, and a local in-memory bag work in the browser. The three sample delivery locations only change the displayed location.

Only the catalog endpoints above are connected in optional live mode. Both modes keep favorites and bag quantities in the current page session; no account, checkout, order placement, payment, or delivery tracking is connected on web. The You screen says so directly. The 12 MIN badge and sample locations reproduce the Flutter design and are illustrative, not live delivery estimates. Live catalog products use their API image URL; those without one use a branded placeholder. The app does not silently substitute demo products for a failed live request.

The Flutter packaging PNGs in `public/images/proto-*.png` can be regenerated from the current Flutter catalog by running this command in `D:\proto-app\flutter_app`:

```powershell
& "D:\proto-app\.tools\flutter\bin\flutter.bat" test --no-pub ..\customer_web\scripts\export_flutter_artwork_test.dart
```
