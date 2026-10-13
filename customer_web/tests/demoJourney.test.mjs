import assert from 'node:assert/strict'
import test from 'node:test'
import { demoCatalog } from '../src/data/demoCatalog.ts'
import { calculateBag, createDemoSubmitController, demoOrderTotalMinor } from '../src/lib/checkout.ts'
import { addDemoAddress, emptyDemoAddressBook, readDemoAddressBook, writeDemoAddressBook } from '../src/lib/demoAddresses.ts'
import { advanceDemoSimulation, appendDemoOrder, readDemoOrders, writeDemoOrders } from '../src/lib/orderHistory.ts'
import { readBag, readFavorites, writeBag, writeFavorites } from '../src/lib/persistence.ts'

function memoryStorage() {
  const values = new Map()
  return {
    getItem: (key) => values.get(key) ?? null,
    setItem: (key, value) => { values.set(key, value) },
  }
}

const details = {
  name: 'Demo Customer', phone: '9876543210', addressLine1: '12 Sample Road',
  addressLine2: '', locality: 'Indiranagar', city: 'Bengaluru', state: 'Karnataka', pinCode: '560038',
}

test('local journey saves bag, favourite and address, then confirms a redacted demo order', async () => {
  const storage = memoryStorage()
  const product = demoCatalog.products.find((item) => item.name === 'Whey Isolate')
  const bag = { [product.id]: 2 }
  assert.equal(writeBag(storage, bag), true)
  assert.equal(writeFavorites(storage, [product.id]), true)
  const addresses = addDemoAddress(emptyDemoAddressBook(), details, () => 'addr-sample')
  assert.equal(writeDemoAddressBook(storage, addresses), true)
  assert.equal(readDemoAddressBook(storage).selectedId, 'addr-sample')

  const summary = calculateBag([product], readBag(storage))
  let entries = readDemoOrders(storage)
  const submit = createDemoSubmitController((order) => {
    const next = appendDemoOrder(entries, order)
    if (!writeDemoOrders(storage, next)) return false
    entries = next
    return true
  }, () => { writeBag(storage, {}) }, () => 'DEMO-JOURNEY-1')
  const confirmation = await submit.submit(summary, details)

  assert.equal(confirmation.reference, 'DEMO-JOURNEY-1')
  assert.equal(demoOrderTotalMinor(confirmation.subtotalMinor), summary.subtotalMinor)
  assert.equal(confirmation.delivery.addressLine1, details.addressLine1)
  assert.deepEqual(readBag(storage), {})
  assert.deepEqual(readFavorites(storage), [product.id])
  assert.equal(readDemoAddressBook(storage).addresses.length, 1)
  const [history] = readDemoOrders(storage)
  assert.equal(history.reference, confirmation.reference)
  assert.equal(history.simulationStage, 'placed')
  assert.equal(history.items[0].lineMinor, summary.subtotalMinor)
  assert.equal(history.delivery.city, details.city)
  assert.equal(JSON.stringify(history).includes(details.phone), false)
  assert.equal(JSON.stringify(history).includes(details.addressLine1), false)
  const advanced = advanceDemoSimulation(readDemoOrders(storage), confirmation.reference)
  assert.equal(writeDemoOrders(storage, advanced), true)
  assert.equal(readDemoOrders(storage)[0].simulationStage, 'confirmed')
})

test('failed order-history persistence leaves the original bag available for retry', async () => {
  const storage = memoryStorage()
  const product = demoCatalog.products.find((item) => item.name === 'Whey Isolate')
  const bag = { [product.id]: 1 }
  writeBag(storage, bag)
  let clearCalls = 0
  const submit = createDemoSubmitController(() => false, () => { clearCalls += 1; writeBag(storage, {}) }, () => 'DEMO-FAILED-SAVE')
  await assert.rejects(submit.submit(calculateBag([product], readBag(storage)), details), /bag is still here/)
  assert.deepEqual(readBag(storage), bag)
  assert.deepEqual(readDemoOrders(storage), [])
  assert.equal(clearCalls, 0)
})
