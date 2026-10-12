import assert from 'node:assert/strict'
import test from 'node:test'
import { configuredCatalogMode, loadCatalog } from '../src/api/catalog.ts'
import { configuredApiOrigin, getJson } from '../src/api/client.ts'
import { demoCatalog } from '../src/data/demoCatalog.ts'
import { calculateBag, createDemoSubmitController } from '../src/lib/checkout.ts'

const development = { DEV: true, PROD: false, VITE_PROTO_API_BASE_URL: 'http://localhost:3101' }
const category = { id: 'category-1', name: 'Eggs', slug: 'eggs', description: null }
const product = {
  id: 'product-1', sku: 'EGGS-6', name: 'Farm Eggs', description: null,
  price: '119.00', currency: 'INR', imageUrl: null, stockQuantity: 4,
  available: true, category, createdAt: '2026-10-01T00:00:00Z',
}

function catalogFetch(categories = [category], products = [product], requests = []) {
  return async (url, init) => {
    requests.push({ url, method: init.method, accept: init.headers.Accept })
    return Response.json(url.includes('/categories') ? categories : products)
  }
}

test('development defaults to demo, while production requires an explicit mode', () => {
  assert.equal(configuredCatalogMode({ DEV: true, PROD: false }), 'demo')
  assert.equal(configuredCatalogMode({ DEV: false, PROD: true, VITE_PROTO_CATALOG_MODE: 'live' }), 'live')
  assert.equal(configuredCatalogMode({ DEV: false, PROD: true, VITE_PROTO_CATALOG_MODE: 'demo' }), 'demo')
  assert.throws(() => configuredCatalogMode({ DEV: false, PROD: true }), /explicitly/)
  assert.throws(() => configuredCatalogMode({ DEV: true, PROD: false, VITE_PROTO_CATALOG_MODE: 'automatic' }), /explicitly/)
})

test('API origin is explicit and HTTPS in production', () => {
  assert.equal(configuredApiOrigin({ DEV: true, PROD: false }), 'http://localhost:3101')
  assert.equal(configuredApiOrigin({ PROD: true, VITE_PROTO_API_BASE_URL: 'https://api.example.test/' }), 'https://api.example.test')
  assert.throws(() => configuredApiOrigin({ PROD: true }), /VITE_PROTO_API_BASE_URL/)
  assert.throws(() => configuredApiOrigin({ PROD: true, VITE_PROTO_API_BASE_URL: 'http://localhost:3101' }), /HTTPS/)
  for (const value of ['https://user:pass@api.example.test', 'https://api.example.test/v1', 'https://api.example.test?x=1', 'ftp://api.example.test']) {
    assert.throws(() => configuredApiOrigin({ PROD: true, VITE_PROTO_API_BASE_URL: value }), /origin|HTTP/)
  }
})

test('live catalogue fetches the verified public GET routes and maps backend stock', async () => {
  const requests = []
  const catalog = await loadCatalog('live', new AbortController().signal, {
    env: development, fetchImpl: catalogFetch([category], [product], requests),
  })
  assert.deepEqual(requests, [
    { url: 'http://localhost:3101/api/v1/catalog/categories', method: 'GET', accept: 'application/json' },
    { url: 'http://localhost:3101/api/v1/catalog/products?active=true&sort=newest', method: 'GET', accept: 'application/json' },
  ])
  assert.equal(catalog.products[0].price, '119.00')
  assert.equal(catalog.products[0].stockQuantity, 4)
  assert.equal(catalog.products[0].available, true)
})

test('an empty backend catalogue stays empty and demo mode makes no API request', async () => {
  const empty = await loadCatalog('live', new AbortController().signal, {
    env: development, fetchImpl: catalogFetch([], []),
  })
  assert.deepEqual(empty, { categories: [], products: [] })
  const demo = await loadCatalog('demo', new AbortController().signal, {
    env: { PROD: true }, fetchImpl: () => { throw new Error('Demo mode must not call the API') },
  })
  assert.equal(demo, demoCatalog)
})

test('live catalogue remains pending until both public responses are ready', async () => {
  const pending = new Map()
  const loading = loadCatalog('live', new AbortController().signal, {
    env: development,
    fetchImpl: (url) => new Promise((resolve) => pending.set(url.includes('/categories') ? 'categories' : 'products', resolve)),
  })
  assert.equal(pending.size, 2)
  let settled = false
  loading.then(() => { settled = true })
  pending.get('categories')(Response.json([category]))
  await new Promise((resolve) => setImmediate(resolve))
  assert.equal(settled, false)
  pending.get('products')(Response.json([product]))
  assert.equal((await loading).products.length, 1)
  assert.equal(settled, true)
})

test('network and HTTP errors stay clear without exposing response bodies', async () => {
  const signal = new AbortController().signal
  await assert.rejects(getJson('https://api.example.test/catalog', signal, async () => { throw new TypeError('internal socket detail') }),
    (error) => /Cannot reach the API/.test(error.message) && !/socket detail/.test(error.message))
  await assert.rejects(getJson('https://api.example.test/catalog', signal,
    async () => new Response('private server diagnostic', { status: 503 })),
  (error) => /HTTP 503/.test(error.message) && !/private/.test(error.message))
})

test('malformed JSON and backend DTOs fail instead of falling back to demo products', async () => {
  const signal = new AbortController().signal
  await assert.rejects(loadCatalog('live', signal, {
    env: development,
    fetchImpl: async (url) => url.includes('/categories')
      ? new Response('{broken', { status: 200 })
      : Response.json([product]),
  }), /malformed JSON/)
  await assert.rejects(loadCatalog('live', signal, {
    env: development, fetchImpl: catalogFetch([category], [{ ...product, stockQuantity: -2 }]),
  }), /unexpected product/)
})

test('a demo checkout using a live catalogue product sends no production order request', async () => {
  const requests = []
  const catalog = await loadCatalog('live', new AbortController().signal, {
    env: development, fetchImpl: catalogFetch([category], [product], requests),
  })
  const bag = calculateBag(catalog.products, { [product.id]: 1 })
  let savedReference = ''
  let cleared = false
  const controller = createDemoSubmitController((order) => {
    savedReference = order.reference
    return true
  }, () => { cleared = true }, () => 'DEMO-DAY5')
  const order = await controller.submit(bag, {
    name: 'Test Customer', phone: '9876543210', addressLine1: '12 Main Road',
    addressLine2: '', locality: 'Indiranagar', city: 'Bengaluru',
    state: 'Karnataka', pinCode: '560001',
  })
  assert.equal(order.mode, 'local-demo')
  assert.equal(savedReference, 'DEMO-DAY5')
  assert.equal(cleared, true)
  assert.ok(requests.every((request) => request.method === 'GET' && request.url.includes('/catalog/')))
})
