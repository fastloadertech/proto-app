import assert from 'node:assert/strict'
import test from 'node:test'
import { demoCatalog } from '../src/data/demoCatalog.ts'
import { calculateBag, createDemoOrder } from '../src/lib/checkout.ts'
import {
  HISTORY_STORAGE_KEY,
  readDemoOrders,
  toHistoryEntry,
  writeDemoOrders,
} from '../src/lib/orderHistory.ts'

const product = demoCatalog.products[0]
const details = {
  name: 'Alex Rao', phone: '9876543210', addressLine1: '12 Main Road',
  addressLine2: 'Flat 3', locality: 'Indiranagar', city: 'Bengaluru',
  state: 'Karnataka', pinCode: '560038',
}
const order = createDemoOrder(calculateBag([product], { [product.id]: 2 }), details, () => 'DEMO-HISTORY-1')

function memoryStorage() {
  const values = new Map()
  return {
    values,
    getItem(key) { return values.get(key) ?? null },
    setItem(key, value) { values.set(key, value) },
  }
}

test('history entry and stored payload omit contact and full street address', () => {
  const entry = toHistoryEntry(order)
  assert.equal(entry.reference, order.reference)
  assert.equal(entry.subtotalMinor, order.subtotalMinor)
  assert.deepEqual(entry.delivery, { city: 'Bengaluru', state: 'Karnataka', pinCode: '560038' })
  const storage = memoryStorage()
  assert.equal(HISTORY_STORAGE_KEY, 'proto:web:demo-orders:v1')
  assert.equal(writeDemoOrders(storage, [entry]), true)
  assert.deepEqual(readDemoOrders(storage), [entry])
  const stored = storage.values.get(HISTORY_STORAGE_KEY)
  assert.ok(!stored.includes('9876543210'))
  assert.ok(!stored.includes('12 Main Road'))
  assert.ok(!stored.includes('Indiranagar'))
  assert.ok(!stored.includes('Alex Rao'))
})

test('history keeps at most 20 unique references in supplied order', () => {
  const storage = memoryStorage()
  const entries = Array.from({ length: 25 }, (_, index) => ({ ...toHistoryEntry(order), reference: `DEMO-${index}` }))
  assert.equal(writeDemoOrders(storage, [entries[0], entries[0], ...entries.slice(1)]), true)
  const restored = readDemoOrders(storage)
  assert.equal(restored.length, 20)
  assert.deepEqual(restored.map((entry) => entry.reference), entries.slice(0, 20).map((entry) => entry.reference))
})

test('history discards malformed records and rejects outdated or broken payloads', () => {
  const storage = memoryStorage()
  assert.deepEqual(readDemoOrders(storage), [])
  const valid = toHistoryEntry(order)
  storage.setItem(HISTORY_STORAGE_KEY, JSON.stringify({ version: 1, orders: [
    { ...valid, subtotalMinor: 1 }, valid, { ...valid, reference: 'DEMO-HISTORY-2', mode: 'live' },
  ] }))
  assert.deepEqual(readDemoOrders(storage), [valid])
  storage.setItem(HISTORY_STORAGE_KEY, JSON.stringify({ version: 0, orders: [valid] }))
  assert.deepEqual(readDemoOrders(storage), [])
  storage.setItem(HISTORY_STORAGE_KEY, '{bad json')
  assert.deepEqual(readDemoOrders(storage), [])
  storage.setItem(HISTORY_STORAGE_KEY, JSON.stringify([valid]))
  assert.deepEqual(readDemoOrders(storage), [])
})

test('blocked storage leaves in-memory order history usable', () => {
  const entry = toHistoryEntry(order)
  const blocked = {
    getItem() { throw new Error('blocked') },
    setItem() { throw new Error('quota') },
  }
  assert.deepEqual(readDemoOrders(blocked), [])
  assert.equal(writeDemoOrders(blocked, [entry]), false)
  assert.deepEqual(readDemoOrders(null), [])
  assert.equal(writeDemoOrders(null, [entry]), false)
  assert.equal(entry.reference, order.reference)
})
