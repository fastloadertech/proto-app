import assert from 'node:assert/strict'
import test from 'node:test'
import { demoCatalog } from '../src/data/demoCatalog.ts'
import { bagCatalogChanges } from '../src/lib/catalogRevalidation.ts'

const product = demoCatalog.products[0]
const previous = { categories: demoCatalog.categories, products: [product] }
const saved = { [product.id]: 2 }

test('fresh catalogues report saved-item price, availability, and stock changes', () => {
  const next = { ...previous, products: [{ ...product, price: '10.00', available: false, stockQuantity: 1 }] }
  const changes = bagCatalogChanges(previous, next, saved)
  assert.ok(changes.some((notice) => /changed price/.test(notice) && /10\.00/.test(notice)))
  assert.ok(changes.some((notice) => /now unavailable/.test(notice)))
  assert.equal(changes.some((notice) => /in stock/.test(notice)), false)

  const stockOnly = { ...previous, products: [{ ...product, available: true, stockQuantity: 1 }] }
  assert.ok(bagCatalogChanges(previous, stockOnly, saved).some((notice) => /only 1 in stock/.test(notice)))
  const soldOut = { ...previous, products: [{ ...product, available: true, stockQuantity: 0 }] }
  assert.ok(bagCatalogChanges(previous, soldOut, saved).some((notice) => /now unavailable/.test(notice)))
})

test('removed items are disclosed without treating unrelated saved IDs as missing', () => {
  const changes = bagCatalogChanges(previous, { ...previous, products: [] }, { ...saved, 'other-mode-item': 1 })
  assert.deepEqual(changes, [`${product.name} is no longer listed in this catalogue.`])
  assert.deepEqual(bagCatalogChanges(null, previous, saved), [])
})

test('unchanged products and already insufficient stock do not create stale notices', () => {
  assert.deepEqual(bagCatalogChanges(previous, previous, saved), [])
  const lowStock = { ...previous, products: [{ ...product, stockQuantity: 1 }] }
  assert.deepEqual(bagCatalogChanges(lowStock, lowStock, saved), [])
})
