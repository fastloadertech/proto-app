import assert from 'node:assert/strict'
import test from 'node:test'
import { demoCatalog } from '../src/data/demoCatalog.ts'
import { filterProducts } from '../src/lib/catalogFilters.ts'
import { parseCatalog } from '../src/api/catalog.ts'

const defaults = { query: '', categorySlug: null, availableOnly: false, sort: 'featured' }

test('search matches product names and clears back to the full catalog', () => {
  const matches = filterProducts(demoCatalog.products, { ...defaults, query: 'whey isolate' })
  assert.deepEqual(matches.map((product) => product.name), ['Whey Isolate'])
  assert.equal(filterProducts(demoCatalog.products, defaults).length, demoCatalog.products.length)
})

test('category, availability, and empty filters work together', () => {
  const category = filterProducts(demoCatalog.products, { ...defaults, categorySlug: 'snacks' })
  assert.equal(category.length, 2)
  assert.ok(category.every((product) => product.category.slug === 'snacks'))
  const available = filterProducts(demoCatalog.products, { ...defaults, availableOnly: true })
  assert.ok(available.every((product) => product.available))
  assert.ok(available.length < demoCatalog.products.length)
  assert.deepEqual(filterProducts(demoCatalog.products, { ...defaults, query: 'no-such-protein' }), [])
})

test('price and name sorting do not mutate the source catalog', () => {
  const originalIds = demoCatalog.products.map((product) => product.id)
  const cheap = filterProducts(demoCatalog.products, { ...defaults, sort: 'price-asc' })
  const expensive = filterProducts(demoCatalog.products, { ...defaults, sort: 'price-desc' })
  const names = filterProducts(demoCatalog.products, { ...defaults, sort: 'name-asc' })
  assert.ok(Number(cheap[0].price) <= Number(cheap.at(-1).price))
  assert.ok(Number(expensive[0].price) >= Number(expensive.at(-1).price))
  assert.ok(names[0].name.localeCompare(names.at(-1).name) <= 0)
  assert.deepEqual(demoCatalog.products.map((product) => product.id), originalIds)
})

test('backend DTO mapping retains decimal prices, nullable artwork, and availability', () => {
  const category = { id: 'category-1', name: 'Eggs', slug: 'eggs', description: null, isActive: true, createdAt: '2026-10-01T00:00:00Z', updatedAt: '2026-10-01T00:00:00Z' }
  const product = { id: 'product-1', sku: 'EGGS-6', name: 'Farm Eggs', description: null, price: '119.00', currency: 'INR', imageUrl: null, stockQuantity: null, isActive: true, available: false, category, createdAt: '2026-10-01T00:00:00Z', updatedAt: '2026-10-01T00:00:00Z' }
  assert.deepEqual(parseCatalog([category], [product]), {
    categories: [{ id: 'category-1', slug: 'eggs', name: 'Eggs', description: null }],
    products: [{ id: 'product-1', sku: 'EGGS-6', name: 'Farm Eggs', description: null, price: '119.00', currency: 'INR', imageUrl: null, available: false, category: { id: 'category-1', slug: 'eggs', name: 'Eggs', description: null }, createdAt: '2026-10-01T00:00:00Z' }],
  })
})

test('invalid catalog shapes fail explicitly', () => {
  assert.throws(() => parseCatalog({}, []), /unexpected response/)
  assert.throws(() => parseCatalog([], [{ id: 'bad' }]), /unexpected response/)
})
