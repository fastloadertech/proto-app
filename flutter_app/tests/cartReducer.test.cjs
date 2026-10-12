const test = require('node:test');
const assert = require('node:assert/strict');
const { createCartReducer, initialCartState } = require('../src/state/cartReducer.ts');

const reduce = createCartReducer(['whey-protein', 'eggs']);

test('adds repeated products and preserves unrelated items without mutating state', () => {
  const previous = Object.freeze({ eggs: 2 });
  const added = reduce(previous, { type: 'add', productId: 'whey-protein' });
  const repeated = reduce(added, { type: 'add', productId: 'whey-protein' });

  assert.deepEqual(repeated, { eggs: 2, 'whey-protein': 2 });
  assert.deepEqual(previous, { eggs: 2 });
  assert.equal(Object.values(repeated).reduce((total, quantity) => total + quantity, 0), 4);
});

test('decrements a product, removes its final unit, and cannot go below zero', () => {
  const previous = Object.freeze({ eggs: 2, 'whey-protein': 1 });
  const decremented = reduce(previous, { type: 'remove', productId: 'eggs' });
  const removed = reduce(decremented, { type: 'remove', productId: 'eggs' });
  const repeated = reduce(removed, { type: 'remove', productId: 'eggs' });

  assert.deepEqual(decremented, { eggs: 1, 'whey-protein': 1 });
  assert.deepEqual(removed, { 'whey-protein': 1 });
  assert.strictEqual(repeated, removed);
  assert.deepEqual(previous, { eggs: 2, 'whey-protein': 1 });
});

test('rejects unknown product IDs for additions and removals', () => {
  const previous = Object.freeze({ eggs: 1 });

  for (const productId of ['', 'not-a-product', '__proto__']) {
    assert.strictEqual(reduce(previous, { type: 'add', productId }), previous);
    assert.strictEqual(reduce(previous, { type: 'remove', productId }), previous);
  }
});

test('clears the cart and allows adding items again', () => {
  const cleared = reduce({ eggs: 3, 'whey-protein': 1 }, { type: 'clear' });

  assert.deepEqual(cleared, {});
  assert.deepEqual(reduce(cleared, { type: 'add', productId: 'eggs' }), { eggs: 1 });
  assert.deepEqual(initialCartState, {});
});
