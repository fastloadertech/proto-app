import assert from 'node:assert/strict'
import test from 'node:test'
import { demoRouteHash, readDemoRoute } from '../src/lib/demoNavigation.ts'

test('demo routes round trip for catalogue, checkout and order detail', () => {
  for (const view of ['home', 'shop', 'categories', 'bag', 'checkout', 'confirmation', 'orders', 'you', 'addresses', 'admin']) {
    assert.deepEqual(readDemoRoute(demoRouteHash(view)), { view, reference: '' })
  }
  const reference = 'DEMO-123/ABC'
  assert.deepEqual(readDemoRoute(demoRouteHash('order-detail', reference)), { view: 'order-detail', reference })
})

test('unknown and malformed routes recover safely; unknown order references retain an unavailable view', () => {
  assert.deepEqual(readDemoRoute('#unknown'), { view: 'home', reference: '' })
  assert.deepEqual(readDemoRoute('#order/NOT-FOUND'), { view: 'order-detail', reference: 'NOT-FOUND' })
  assert.deepEqual(readDemoRoute('#order/%'), { view: 'order-detail', reference: '' })
  assert.deepEqual(readDemoRoute('#order/%00'), { view: 'order-detail', reference: '' })
  assert.deepEqual(readDemoRoute('#order/' + 'A'.repeat(129)), { view: 'order-detail', reference: '' })
})
