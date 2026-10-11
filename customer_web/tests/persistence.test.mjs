import assert from 'node:assert/strict'
import test from 'node:test'
import {
  BAG_STORAGE_KEY,
  FAVORITES_STORAGE_KEY,
  getBrowserStorage,
  readBag,
  readFavorites,
  sanitizeBag,
  sanitizeFavorites,
  writeBag,
  writeFavorites,
} from '../src/lib/persistence.ts'

function memoryStorage() {
  const values = new Map()
  return {
    values,
    getItem(key) { return values.get(key) ?? null },
    setItem(key, value) { values.set(key, value) },
  }
}

test('bag validation keeps only positive integer quantities and caps each at 99', () => {
  const input = Object.fromEntries([
    ['demo-whey-isolate', 2], ['product-uuid', 1000], ['zero', 0],
    ['negative', -1], ['fraction', 1.5], ['string', '3'], ['__proto__', 8],
  ])
  assert.deepEqual(sanitizeBag(input), { 'demo-whey-isolate': 2, 'product-uuid': 99 })
  assert.equal(input['product-uuid'], 1000)
  assert.deepEqual(sanitizeBag([['demo-whey-isolate', 2]]), {})
  assert.deepEqual(sanitizeBag(null), {})
})

test('favourites validation deduplicates IDs in their original order', () => {
  assert.deepEqual(sanitizeFavorites(['demo-a', 'demo-b', 'demo-a', '', 4, ' demo-c ', '__proto__']), ['demo-a', 'demo-b'])
  assert.deepEqual(sanitizeFavorites({ ids: ['demo-a'] }), [])
})

test('bag and favourites round trip through their versioned storage keys', () => {
  const storage = memoryStorage()
  assert.equal(BAG_STORAGE_KEY, 'proto:web:bag:v1')
  assert.equal(FAVORITES_STORAGE_KEY, 'proto:web:favourites:v1')
  assert.equal(writeBag(storage, { 'demo-whey-isolate': 3, 'demo-plant-protein': 100 }), true)
  assert.equal(writeFavorites(storage, ['demo-whey-isolate', 'demo-whey-isolate', 'demo-plant-protein']), true)
  assert.deepEqual(readBag(storage), { 'demo-whey-isolate': 3, 'demo-plant-protein': 99 })
  assert.deepEqual(readFavorites(storage), ['demo-whey-isolate', 'demo-plant-protein'])
  assert.deepEqual(JSON.parse(storage.values.get(BAG_STORAGE_KEY)), {
    version: 1, quantities: { 'demo-whey-isolate': 3, 'demo-plant-protein': 99 },
  })
})

test('missing, malformed, and outdated payloads restore empty state', () => {
  const storage = memoryStorage()
  storage.setItem('proto:web:bag:v0', JSON.stringify({ version: 0, quantities: { old: 2 } }))
  assert.deepEqual(readBag(storage), {})
  assert.deepEqual(readFavorites(storage), [])

  storage.setItem(BAG_STORAGE_KEY, '{broken json')
  storage.setItem(FAVORITES_STORAGE_KEY, JSON.stringify({ version: 0, ids: ['demo-a'] }))
  assert.deepEqual(readBag(storage), {})
  assert.deepEqual(readFavorites(storage), [])

  storage.setItem(BAG_STORAGE_KEY, JSON.stringify({ version: 0, quantities: { 'demo-a': 2 } }))
  storage.setItem(FAVORITES_STORAGE_KEY, JSON.stringify(['demo-a']))
  assert.deepEqual(readBag(storage), {})
  assert.deepEqual(readFavorites(storage), [])

  storage.setItem(BAG_STORAGE_KEY, JSON.stringify({ version: 1, quantities: [] }))
  storage.setItem(FAVORITES_STORAGE_KEY, JSON.stringify({ version: 1, ids: { 'demo-a': true } }))
  assert.deepEqual(readBag(storage), {})
  assert.deepEqual(readFavorites(storage), [])
})

test('blocked browser storage getters and methods do not break the storefront', () => {
  assert.equal(getBrowserStorage({ get localStorage() { throw new Error('blocked') } }), null)
  assert.equal(getBrowserStorage({ localStorage: null }), null)
  const storage = memoryStorage()
  assert.equal(getBrowserStorage({ localStorage: storage }), storage)

  const blocked = {
    getItem() { throw new Error('blocked read') },
    setItem() { throw new Error('blocked write') },
  }
  assert.deepEqual(readBag(blocked), {})
  assert.deepEqual(readFavorites(blocked), [])
  assert.equal(writeBag(blocked, { 'demo-a': 1 }), false)
  assert.equal(writeFavorites(blocked, ['demo-a']), false)
  assert.deepEqual(readBag(null), {})
  assert.equal(writeBag(null, { 'demo-a': 1 }), false)
})
