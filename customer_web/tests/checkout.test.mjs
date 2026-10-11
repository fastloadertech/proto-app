import assert from 'node:assert/strict'
import test from 'node:test'
import { demoCatalog } from '../src/data/demoCatalog.ts'
import {
  calculateBag,
  createDemoOrder,
  createDemoSubmitController,
  setBagQuantity,
  validateCheckoutDetails,
} from '../src/lib/checkout.ts'

const whey = demoCatalog.products.find((product) => product.name === 'Whey Isolate')
const everyday = demoCatalog.products.find((product) => product.name === 'Everyday Whey')
const unavailable = demoCatalog.products.find((product) => product.name === 'Peanut Butter Bites')

const details = {
  name: '  Alex Rao  ', phone: ' 9876543210 ', addressLine1: ' 12 Main Road ',
  addressLine2: ' Apt 3 ', locality: ' Indiranagar ', city: ' Bengaluru ',
  state: ' Karnataka ', pinCode: ' 560038 ',
}

test('bag quantity changes increment, decrement, remove, and cap safely', () => {
  const first = setBagQuantity({}, whey.id, 1)
  assert.deepEqual(first, { [whey.id]: 1 })
  const second = setBagQuantity(first, whey.id, first[whey.id] + 1)
  assert.deepEqual(second, { [whey.id]: 2 })
  assert.deepEqual(setBagQuantity(second, whey.id, second[whey.id] - 1), first)
  assert.deepEqual(setBagQuantity(first, whey.id, 99 + 1), { [whey.id]: 99 })
  assert.deepEqual(setBagQuantity(first, whey.id, first[whey.id] - 1), {})
  assert.deepEqual(setBagQuantity(first, whey.id, Number.NaN), first)
  assert.deepEqual(setBagQuantity(first, whey.id, -1), first)
  assert.deepEqual(first, { [whey.id]: 1 })
})

test('bag subtotal uses exact minor units and ignores removed zero entries', () => {
  const summary = calculateBag([whey, everyday], { [whey.id]: 2, [everyday.id]: 1, removed: 0 })
  assert.equal(summary.error, null)
  assert.equal(summary.currency, 'INR')
  assert.equal(summary.count, 3)
  assert.equal(summary.subtotalMinor, 679700)
  assert.deepEqual(summary.lines.map(({ quantity, unitMinor, lineMinor }) => ({ quantity, unitMinor, lineMinor })), [
    { quantity: 2, unitMinor: 249900, lineMinor: 499800 },
    { quantity: 1, unitMinor: 179900, lineMinor: 179900 },
  ])
  const tenths = calculateBag([{ ...whey, price: '0.10' }, { ...everyday, price: '0.20' }], {
    [whey.id]: 1, [everyday.id]: 1,
  })
  assert.equal(tenths.subtotalMinor, 30)
  assert.ok(calculateBag([whey], {}).error)
  assert.deepEqual(calculateBag([whey], {}).lines, [])
})

test('bag rejects invalid quantity, unavailable or missing products, bad prices, and currency problems', () => {
  for (const quantity of [-1, 1.5, 100, Number.NaN, '2']) {
    assert.ok(calculateBag([whey], { [whey.id]: quantity }).error)
  }
  assert.ok(calculateBag([unavailable], { [unavailable.id]: 1 }).error)
  const missing = calculateBag([whey], { 'demo-missing': 1 })
  assert.ok(missing.error)
  assert.deepEqual(missing.lines, [])
  assert.equal(missing.subtotalMinor, 0)
  for (const price of ['12.3', '12.345', '1e3', '-1.00', '90071992547409.92']) {
    assert.ok(calculateBag([{ ...whey, price }], { [whey.id]: 1 }).error)
  }
  assert.ok(calculateBag([{ ...whey, price: '90071992547409.91' }], { [whey.id]: 2 }).error)
  assert.match(calculateBag([whey, { ...everyday, currency: 'USD' }], { [whey.id]: 1, [everyday.id]: 1 }).error, /different currencies/)
  assert.ok(calculateBag([{ ...whey, currency: 'USD' }], { [whey.id]: 1 }).error)
})

test('checkout details validate contact and delivery fields', () => {
  assert.deepEqual(validateCheckoutDetails(details), {})
  assert.ok(validateCheckoutDetails({ ...details, phone: '1234567890' }).phone)
  assert.ok(validateCheckoutDetails({ ...details, phone: '0000000000' }).phone)
  assert.ok(validateCheckoutDetails({ ...details, city: 'A'.repeat(101) }).city)
  const errors = validateCheckoutDetails({
    ...details, name: 'A', phone: '123', addressLine1: 'x', locality: '',
    city: '', state: '', pinCode: '000000',
  })
  assert.deepEqual(Object.keys(errors).sort(), ['name', 'phone', 'addressLine1', 'locality', 'city', 'state', 'pinCode'].sort())
})

test('demo order has a safe item and address snapshot, and rejects invalid input', () => {
  const mutableProduct = { ...whey }
  const summary = calculateBag([mutableProduct], { [whey.id]: 2 })
  const order = createDemoOrder(summary, details, () => 'DEMO-TEST-1')
  assert.equal(order.mode, 'local-demo')
  assert.equal(order.status, 'demo-confirmed')
  assert.equal(order.reference, 'DEMO-TEST-1')
  assert.match(order.createdAt, /^\d{4}-\d{2}-\d{2}T/)
  assert.equal(order.subtotalMinor, 499800)
  assert.deepEqual(order.items, [{
    productId: whey.id, name: whey.name, weightLabel: whey.weightLabel,
    quantity: 2, unitMinor: 249900, lineMinor: 499800,
  }])
  assert.equal(order.delivery.name, 'Alex Rao')
  assert.equal(order.delivery.addressLine1, '12 Main Road')
  assert.equal(order.delivery.pinCode, '560038')
  mutableProduct.name = 'Changed later'
  assert.equal(order.items[0].name, 'Whey Isolate')
  assert.throws(() => createDemoOrder(calculateBag([], {}), details), /Review your bag/)
  assert.throws(() => createDemoOrder(summary, { ...details, phone: 'wrong' }), /Check your contact/)
  assert.throws(() => createDemoOrder({ ...summary, subtotalMinor: 1 }, details), /Review your bag/)
})

test('single-flight submission shares the pending request and clears bag only on success', async () => {
  const summary = calculateBag([whey], { [whey.id]: 1 })
  let resolvePersist
  let persistCalls = 0
  let clearCalls = 0
  const controller = createDemoSubmitController(() => {
    persistCalls += 1
    return new Promise((resolve) => { resolvePersist = resolve })
  }, () => { clearCalls += 1 }, () => 'DEMO-SINGLE-FLIGHT')
  const first = controller.submit(summary, details)
  const second = controller.submit(summary, details)
  assert.strictEqual(first, second)
  assert.equal(controller.isSubmitting(), true)
  await Promise.resolve()
  assert.equal(persistCalls, 1)
  assert.equal(clearCalls, 0)
  resolvePersist(true)
  assert.equal((await first).reference, 'DEMO-SINGLE-FLIGHT')
  assert.equal(clearCalls, 1)
  assert.equal(controller.isSubmitting(), false)
  await assert.rejects(controller.submit(summary, details), /already been submitted/)
  assert.equal(persistCalls, 1)
})

test('failed submission preserves bag and can be retried', async () => {
  const summary = calculateBag([whey], { [whey.id]: 1 })
  let attempts = 0
  let clearCalls = 0
  const controller = createDemoSubmitController(() => {
    attempts += 1
    return attempts > 1
  }, () => { clearCalls += 1 }, () => 'DEMO-RETRY')
  await assert.rejects(controller.submit(summary, details), /bag is still here/)
  assert.equal(clearCalls, 0)
  assert.equal(controller.isSubmitting(), false)
  assert.equal((await controller.submit(summary, details)).reference, 'DEMO-RETRY')
  assert.equal(clearCalls, 1)
  assert.equal(attempts, 2)
})
