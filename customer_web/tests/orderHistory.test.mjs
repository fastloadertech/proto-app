import assert from 'node:assert/strict'
import test from 'node:test'
import { demoCatalog } from '../src/data/demoCatalog.ts'
import { calculateBag, createDemoOrder } from '../src/lib/checkout.ts'
import {
  DEMO_ORDER_STATUSES,
  DEMO_SIMULATION_STAGES,
  HISTORY_STORAGE_KEY,
  appendDemoOrder,
  advanceDemoSimulation,
  demoOrderStatusLabel,
  demoSimulationStageLabel,
  readDemoOrders,
  toHistoryEntry,
  updateDemoOrderStatus,
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
  assert.equal(entry.simulationStage, 'placed')
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

test('appending a demo order snapshots it without replacing a reference or mutating history', () => {
  const oldOrder = createDemoOrder(calculateBag([product], { [product.id]: 1 }), details, () => 'DEMO-OLD')
  const oldEntry = toHistoryEntry(oldOrder)
  const original = [oldEntry]
  const next = appendDemoOrder(original, order)
  assert.deepEqual(next.map((entry) => entry.reference), ['DEMO-HISTORY-1', 'DEMO-OLD'])
  assert.notStrictEqual(next, original)
  assert.notStrictEqual(next[1], oldEntry)
  assert.deepEqual(original, [oldEntry])
  assert.deepEqual(next[0].delivery, { city: 'Bengaluru', state: 'Karnataka', pinCode: '560038' })
  assert.throws(() => appendDemoOrder(next, order), /reference already exists/)
  assert.deepEqual(next.map((entry) => entry.reference), ['DEMO-HISTORY-1', 'DEMO-OLD'])
  const many = Array.from({ length: 20 }, (_, index) => ({ ...oldEntry, reference: `DEMO-OLD-${index}` }))
  const capped = appendDemoOrder(many, order)
  assert.equal(capped.length, 20)
  assert.equal(capped[0].reference, order.reference)
  assert.equal(capped.at(-1).reference, 'DEMO-OLD-18')
  assert.equal(many.length, 20)
  assert.throws(() => appendDemoOrder([oldEntry, oldEntry], order), /invalid record/)
})

test('customer demo timeline advances one stage per action and persists without private address data', () => {
  const initial = toHistoryEntry(order)
  assert.deepEqual(DEMO_SIMULATION_STAGES, ['placed', 'confirmed', 'preparing', 'ready', 'delivered'])
  assert.deepEqual(DEMO_SIMULATION_STAGES.map(demoSimulationStageLabel), [
    'Placed', 'Confirmed', 'Preparing', 'Ready for delivery', 'Delivered',
  ])
  const storage = memoryStorage()
  let entries = [initial]
  for (const stage of DEMO_SIMULATION_STAGES.slice(1)) {
    const previous = entries
    entries = advanceDemoSimulation(entries, initial.reference)
    assert.notStrictEqual(entries, previous)
    assert.equal(entries[0].simulationStage, stage)
    assert.equal(entries[0].status, 'demo-confirmed')
    assert.deepEqual(entries[0].items, initial.items)
    assert.deepEqual(entries[0].delivery, { city: 'Bengaluru', state: 'Karnataka', pinCode: '560038' })
    assert.equal(writeDemoOrders(storage, entries), true)
    entries = readDemoOrders(storage)
    assert.equal(entries[0].simulationStage, stage)
    const stored = storage.values.get(HISTORY_STORAGE_KEY)
    assert.ok(!stored.includes(details.phone))
    assert.ok(!stored.includes(details.addressLine1))
  }
  assert.equal(initial.simulationStage, 'placed')
  assert.throws(() => advanceDemoSimulation(entries, initial.reference), /already complete/)
  const annotated = updateDemoOrderStatus(entries, initial.reference, 'demo-reviewed')
  assert.equal(annotated[0].simulationStage, 'delivered')
  assert.equal(annotated[0].status, 'demo-reviewed')
})

test('customer timeline rejects invalid records and references without advancing', () => {
  const entry = toHistoryEntry(order)
  assert.throws(() => advanceDemoSimulation([entry], 'UNKNOWN'), /reference was not found/)
  assert.throws(() => advanceDemoSimulation([entry], ` ${entry.reference}`), /valid demo order reference/)
  assert.throws(() => advanceDemoSimulation([{ ...entry, simulationStage: 'shipped' }], entry.reference), /invalid record/)
  assert.equal(entry.simulationStage, 'placed')
})

test('previous v1 records load at Placed while malformed stages are discarded', () => {
  const storage = memoryStorage()
  const { simulationStage, ...legacy } = toHistoryEntry(order)
  storage.setItem(HISTORY_STORAGE_KEY, JSON.stringify({ version: 1, orders: [
    legacy, { ...legacy, reference: 'DEMO-BAD-STAGE', simulationStage: 'in-transit' },
  ] }))
  assert.deepEqual(readDemoOrders(storage), [{ ...legacy, simulationStage: 'placed' }])
})

test('demo status changes preserve the order and survive storage reload', () => {
  const initial = toHistoryEntry(order)
  const other = { ...initial, reference: 'DEMO-HISTORY-OTHER' }
  assert.deepEqual(DEMO_ORDER_STATUSES, ['demo-confirmed', 'demo-reviewed', 'demo-archived'])
  assert.equal(demoOrderStatusLabel(initial.status), 'Demo confirmed')
  const originals = [initial, other]
  const reviewed = updateDemoOrderStatus(originals, initial.reference, 'demo-reviewed')
  assert.notStrictEqual(reviewed, originals)
  assert.notStrictEqual(reviewed[0], initial)
  assert.notStrictEqual(reviewed[0].items, initial.items)
  assert.deepEqual(reviewed[0], { ...initial, status: 'demo-reviewed' })
  assert.deepEqual(reviewed[1], other)
  assert.notStrictEqual(reviewed[1], other)
  assert.equal(initial.status, 'demo-confirmed')
  assert.equal(demoOrderStatusLabel(reviewed[0].status), 'Demo reviewed')

  const storage = memoryStorage()
  assert.equal(writeDemoOrders(storage, reviewed), true)
  const restored = readDemoOrders(storage)
  assert.deepEqual(restored, reviewed)
  const archived = updateDemoOrderStatus(restored, initial.reference, 'demo-archived')
  assert.equal(archived[0].status, 'demo-archived')
  assert.equal(demoOrderStatusLabel(archived[0].status), 'Demo archived')
  assert.equal(writeDemoOrders(storage, archived), true)
  assert.deepEqual(readDemoOrders(storage), archived)
})

test('status changes reject invalid statuses and unknown or malformed references', () => {
  const entry = toHistoryEntry(order)
  assert.throws(() => updateDemoOrderStatus([entry], entry.reference, 'shipped'), /Unsupported demo order status/)
  assert.throws(() => updateDemoOrderStatus([entry], 'DOES-NOT-EXIST', 'demo-reviewed'), /reference was not found/)
  assert.throws(() => updateDemoOrderStatus([entry], ' ', 'demo-reviewed'), /valid demo order reference/)
  assert.throws(() => updateDemoOrderStatus([entry], ` ${entry.reference}`, 'demo-reviewed'), /valid demo order reference/)
  assert.throws(() => updateDemoOrderStatus([{ ...entry, status: 'delivered' }], entry.reference, 'demo-reviewed'), /invalid record/)
  assert.equal(entry.status, 'demo-confirmed')
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
  storage.setItem(HISTORY_STORAGE_KEY, JSON.stringify({ version: 1, orders: [
    { ...valid, status: 'shipped' }, valid,
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
  const reviewed = updateDemoOrderStatus([entry], entry.reference, 'demo-reviewed')
  assert.equal(reviewed[0].status, 'demo-reviewed')
  assert.equal(writeDemoOrders(blocked, reviewed), false)
  assert.deepEqual(readDemoOrders(null), [])
  assert.equal(writeDemoOrders(null, [entry]), false)
  assert.equal(entry.reference, order.reference)
})
