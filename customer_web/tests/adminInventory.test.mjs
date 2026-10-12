import assert from 'node:assert/strict'
import test from 'node:test'
import { demoCatalog } from '../src/data/demoCatalog.ts'
import {
  ADMIN_INVENTORY_STORAGE_KEY,
  deriveInventoryRows,
  filterInventoryRows,
  readAdminInventory,
  summarizeInventory,
  updateInventoryItem,
  writeAdminInventory,
} from '../src/lib/adminInventory.ts'

const whey = demoCatalog.products.find((product) => product.name === 'Whey Isolate')
const everyday = demoCatalog.products.find((product) => product.name === 'Everyday Whey')
const unavailable = demoCatalog.products.find((product) => product.name === 'Peanut Butter Bites')

function memoryStorage() {
  const values = new Map()
  return {
    values,
    getItem(key) { return values.get(key) ?? null },
    setItem(key, value) { values.set(key, value) },
  }
}

test('sample inventory defaults are explicit and never mutate catalog products', () => {
  const originalPrice = whey.price
  const rows = deriveInventoryRows([whey, unavailable], {})
  assert.deepEqual(rows.map(({ price, stock, stockStatus, catalogAvailable }) => ({ price, stock, stockStatus, catalogAvailable })), [
    { price: whey.price, stock: 12, stockStatus: 'in-stock', catalogAvailable: true },
    { price: unavailable.price, stock: 0, stockStatus: 'out-of-stock', catalogAvailable: false },
  ])
  assert.equal(whey.price, originalPrice)
  assert.equal(rows[0].product, whey)
  assert.deepEqual(summarizeInventory(rows), {
    totalProducts: 2, inStockProducts: 1, lowStockProducts: 0, outOfStockProducts: 1, unknownStockProducts: 0,
  })
})

test('price and stock edits normalize values and classify low and out of stock', () => {
  const first = updateInventoryItem({}, whey, ' 2500.5 ', '5')
  const second = updateInventoryItem(first, everyday, '0', '0')
  assert.deepEqual(first, { [whey.id]: { price: '2500.50', stock: 5 } })
  assert.deepEqual(second[everyday.id], { price: '0.00', stock: 0 })
  assert.notEqual(first, second)
  const rows = deriveInventoryRows([whey, everyday], second)
  assert.deepEqual(rows.map(({ price, stockStatus }) => ({ price, stockStatus })), [
    { price: '2500.50', stockStatus: 'low-stock' },
    { price: '0.00', stockStatus: 'out-of-stock' },
  ])
  assert.deepEqual(summarizeInventory(rows), {
    totalProducts: 2, inStockProducts: 1, lowStockProducts: 1, outOfStockProducts: 1, unknownStockProducts: 0,
  })
  assert.equal(whey.price, '2499.00')
})

test('live inventory uses backend prices and stock, ignoring local demo edits', () => {
  const backendProduct = { ...whey, price: '1899.00', stockQuantity: 4 }
  const edits = updateInventoryItem({}, whey, '10.00', '99')
  const liveRows = deriveInventoryRows([backendProduct], edits, 'live')
  assert.deepEqual(liveRows.map(({ price, stock, stockStatus }) => ({ price, stock, stockStatus })), [
    { price: '1899.00', stock: 4, stockStatus: 'low-stock' },
  ])
  assert.deepEqual(deriveInventoryRows([backendProduct], edits, 'demo').map(({ price, stock }) => ({ price, stock })), [
    { price: '10.00', stock: 99 },
  ])
  assert.equal(backendProduct.price, '1899.00')
  assert.equal(backendProduct.stockQuantity, 4)
})

test('live inventory marks untracked stock unknown without inventing demo quantities', () => {
  const products = [
    { ...whey, id: 'live-null', stockQuantity: null },
    { ...whey, id: 'live-missing' },
    { ...whey, id: 'live-out', stockQuantity: 0 },
    { ...whey, id: 'live-low', stockQuantity: 2 },
    { ...whey, id: 'live-in', stockQuantity: 20 },
  ]
  const rows = deriveInventoryRows(products, {}, 'live')
  assert.deepEqual(rows.map(({ stock, stockStatus }) => ({ stock, stockStatus })), [
    { stock: null, stockStatus: 'unknown' },
    { stock: null, stockStatus: 'unknown' },
    { stock: 0, stockStatus: 'out-of-stock' },
    { stock: 2, stockStatus: 'low-stock' },
    { stock: 20, stockStatus: 'in-stock' },
  ])
  assert.deepEqual(filterInventoryRows(rows, { query: '', categorySlug: 'all', stockStatus: 'unknown' }).map(({ product }) => product.id), [
    'live-null', 'live-missing',
  ])
  assert.deepEqual(summarizeInventory(rows), {
    totalProducts: 5, inStockProducts: 2, lowStockProducts: 1, outOfStockProducts: 1, unknownStockProducts: 2,
  })
})

test('inventory rejects invalid, negative, and overflowing price or stock input', () => {
  for (const price of ['', '-1', '1.234', '1e3', '01.00', 'NaN', '90071992547409.92']) {
    assert.throws(() => updateInventoryItem({}, whey, price, '1'), /price/i)
  }
  for (const stock of ['', '-1', '1.5', '1e3', '01', '1000001', '9007199254740992']) {
    assert.throws(() => updateInventoryItem({}, whey, '1.00', stock), /stock/i)
  }
  assert.deepEqual(updateInventoryItem({}, whey, '90071992547409.91', '1000000')[whey.id], {
    price: '90071992547409.91', stock: 1_000_000,
  })
  assert.throws(() => updateInventoryItem({}, { ...whey, currency: 'USD' }, '1', '1'), /INR/)
  assert.throws(() => updateInventoryItem({}, { ...whey, id: '__proto__' }, '1', '1'), /cannot be edited/)
})

test('inventory filters by product name, category, and stock status together', () => {
  const products = [whey, everyday, unavailable]
  let edits = updateInventoryItem({}, everyday, everyday.price, '4')
  edits = updateInventoryItem(edits, unavailable, unavailable.price, '7')
  const rows = deriveInventoryRows(products, edits)
  assert.deepEqual(filterInventoryRows(rows, { query: ' WHEY ', categorySlug: 'all', stockStatus: 'all' }).map(({ product }) => product.id), [whey.id, everyday.id])
  assert.deepEqual(filterInventoryRows(rows, { query: 'whey', categorySlug: everyday.category.slug, stockStatus: 'low-stock' }).map(({ product }) => product.id), [everyday.id])
  assert.deepEqual(filterInventoryRows(rows, { query: '', categorySlug: 'all', stockStatus: 'in-stock' }).map(({ product }) => product.id), [whey.id, unavailable.id])
  assert.deepEqual(filterInventoryRows(rows, { query: 'nothing', categorySlug: 'all', stockStatus: 'all' }), [])
})

test('inventory edits round trip under a distinct versioned key without touching customer state', () => {
  const storage = memoryStorage()
  storage.setItem('proto:web:bag:v1', 'customer bag')
  storage.setItem('proto:web:demo-orders:v1', 'customer orders')
  const edits = updateInventoryItem({}, whey, '2999.99', '3')
  assert.equal(writeAdminInventory(storage, edits), true)
  assert.equal(ADMIN_INVENTORY_STORAGE_KEY, 'proto:web:admin:inventory:v1')
  assert.deepEqual(readAdminInventory(storage), edits)
  assert.deepEqual(JSON.parse(storage.values.get(ADMIN_INVENTORY_STORAGE_KEY)), {
    version: 1, edits,
  })
  assert.equal(storage.values.get('proto:web:bag:v1'), 'customer bag')
  assert.equal(storage.values.get('proto:web:demo-orders:v1'), 'customer orders')
})

test('missing, malformed, outdated, and dangerous stored edits restore safely', () => {
  const storage = memoryStorage()
  assert.deepEqual(readAdminInventory(storage), {})
  storage.setItem(ADMIN_INVENTORY_STORAGE_KEY, '{bad json')
  assert.deepEqual(readAdminInventory(storage), {})
  storage.setItem(ADMIN_INVENTORY_STORAGE_KEY, JSON.stringify({ version: 0, edits: { [whey.id]: { price: '1.00', stock: 1 } } }))
  assert.deepEqual(readAdminInventory(storage), {})
  storage.setItem(ADMIN_INVENTORY_STORAGE_KEY, JSON.stringify({ version: 1, edits: [1, 2] }))
  assert.deepEqual(readAdminInventory(storage), {})
  storage.setItem(ADMIN_INVENTORY_STORAGE_KEY, JSON.stringify({
    version: 1,
    edits: {
      [whey.id]: { price: '99.00', stock: 1 },
      [everyday.id]: { price: '-1.00', stock: 3 },
      [unavailable.id]: { price: '2.00', stock: -1 },
      __proto__: { price: '1.00', stock: 1 },
      constructor: { price: '1.00', stock: 1 },
    },
  }))
  assert.deepEqual(readAdminInventory(storage), { [whey.id]: { price: '99.00', stock: 1 } })
  storage.setItem(ADMIN_INVENTORY_STORAGE_KEY, '{"version":1,"edits":{"__proto__":{"price":"1.00","stock":1}}}')
  assert.deepEqual(readAdminInventory(storage), {})
  assert.equal(Object.prototype.price, undefined)
})

test('blocked storage reads and writes leave safe in-memory behavior', () => {
  const blocked = {
    getItem() { throw new Error('blocked read') },
    setItem() { throw new Error('blocked write') },
  }
  assert.deepEqual(readAdminInventory(blocked), {})
  assert.equal(writeAdminInventory(blocked, { [whey.id]: { price: '1.00', stock: 1 } }), false)
  assert.deepEqual(readAdminInventory(null), {})
  assert.equal(writeAdminInventory(null, {}), false)
  assert.deepEqual(deriveInventoryRows([whey], {}), deriveInventoryRows([whey], readAdminInventory(blocked)))
})
