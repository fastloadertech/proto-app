import assert from 'node:assert/strict'
import test from 'node:test'
import {
  parseOrderDetailResponse,
  parseOrderListResponse,
  parseOrderResponse,
} from '../src/api/orderContract.ts'

const order = {
  id: '11111111-1111-4111-8111-111111111111',
  reference: 'PROTO-ORDER-1',
  status: 'PENDING',
  subtotal: '159.90',
  deliveryFee: '0.00',
  total: '159.90',
  currency: 'INR',
  deliveryAddress: {
    line1: '12 Market Street', line2: null, city: 'Bengaluru', state: 'Karnataka',
    postalCode: '560001', recipientName: 'Sample Customer', phone: '+919876543210',
  },
  items: [{
    id: '22222222-2222-4222-8222-222222222222',
    productId: '33333333-3333-4333-8333-333333333333',
    productName: 'Original Whey', unitPrice: '79.95', quantity: 2, lineTotal: '159.90',
  }],
  createdAt: '2026-10-12T06:00:00.000Z',
  updatedAt: '2026-10-12T06:00:00.000Z',
}

test('verified create, list and detail responses retain server reference, amounts and delivery link', () => {
  assert.deepEqual(parseOrderResponse(order), order)
  assert.deepEqual(parseOrderListResponse([order]), [order])
  const detail = { ...order, delivery: { id: '44444444-4444-4444-8444-444444444444', status: 'AVAILABLE' } }
  assert.deepEqual(parseOrderDetailResponse(detail), detail)
  assert.deepEqual(parseOrderDetailResponse({ ...order, delivery: null }), { ...order, delivery: null })
})

test('legacy nullable address fields and zero delivery fee remain valid', () => {
  const legacy = { ...order, status: 'PLACED', deliveryAddress: null }
  assert.equal(parseOrderResponse(legacy).deliveryAddress, null)
  const sparse = { ...order, deliveryAddress: { line1: '12 Market Street', city: 'Bengaluru' } }
  assert.deepEqual(parseOrderResponse(sparse).deliveryAddress, {
    line1: '12 Market Street', line2: null, city: 'Bengaluru', state: null,
    postalCode: null, recipientName: null, phone: null,
  })
})

test('malformed status, identifiers, money, item arithmetic and totals fail closed', () => {
  const invalid = [
    { ...order, status: 'PAID' },
    { ...order, id: 'not-a-uuid' },
    { ...order, subtotal: '159.9' },
    { ...order, total: '159.91' },
    { ...order, items: [{ ...order.items[0], quantity: 0 }] },
    { ...order, items: [{ ...order.items[0], lineTotal: '158.90' }] },
    { ...order, items: [] },
    { ...order, createdAt: 'not-a-time' },
    { ...order, currency: 'Rupees' },
  ]
  for (const response of invalid) {
    assert.throws(() => parseOrderResponse(response), /unexpected response/)
  }
  assert.throws(() => parseOrderListResponse({ orders: [order] }), /unexpected response/)
})

test('invalid or missing linked delivery never becomes a confirmed order detail', () => {
  assert.throws(() => parseOrderDetailResponse(order), /unexpected response/)
  assert.throws(() => parseOrderDetailResponse({ ...order, delivery: { id: 'bad', status: 'AVAILABLE' } }), /unexpected response/)
  assert.throws(() => parseOrderDetailResponse({ ...order, delivery: { id: '44444444-4444-4444-8444-444444444444', status: 'SCHEDULED' } }), /unexpected response/)
})
