import assert from 'node:assert/strict'
import test from 'node:test'
import {
  DEMO_ADDRESSES_STORAGE_KEY,
  MAX_DEMO_ADDRESSES,
  addDemoAddress,
  emptyDemoAddressBook,
  readDemoAddressBook,
  removeDemoAddress,
  selectDemoAddress,
  updateDemoAddress,
  writeDemoAddressBook,
} from '../src/lib/demoAddresses.ts'

const details = {
  name: ' Alex Rao ', phone: ' 9876543210 ', addressLine1: ' 12 Main Road ',
  addressLine2: ' Flat 3 ', locality: ' Indiranagar ', city: ' Bengaluru ',
  state: ' Karnataka ', pinCode: ' 560038 ',
}

function memoryStorage() {
  const values = new Map()
  return {
    values,
    getItem(key) { return values.get(key) ?? null },
    setItem(key, value) { values.set(key, value) },
  }
}

test('add, edit, select, delete and clear demo addresses without mutating previous state', () => {
  const empty = emptyDemoAddressBook()
  const first = addDemoAddress(empty, details, () => 'addr-first')
  assert.deepEqual(empty, { addresses: [], selectedId: null })
  assert.equal(first.selectedId, 'addr-first')
  assert.deepEqual(first.addresses[0], {
    id: 'addr-first', name: 'Alex Rao', phone: '9876543210', addressLine1: '12 Main Road',
    addressLine2: 'Flat 3', locality: 'Indiranagar', city: 'Bengaluru',
    state: 'Karnataka', pinCode: '560038',
  })
  const second = addDemoAddress(first, { ...details, name: 'Priya Sharma', addressLine2: '' }, () => 'addr-second')
  assert.equal(second.selectedId, 'addr-second')
  const selected = selectDemoAddress(second, 'addr-first')
  assert.equal(selected.selectedId, 'addr-first')
  const updated = updateDemoAddress(selected, 'addr-first', { ...details, city: 'Mysuru' })
  assert.equal(updated.addresses[0].city, 'Mysuru')
  assert.equal(updated.selectedId, 'addr-first')
  assert.equal(first.addresses[0].city, 'Bengaluru')
  const removed = removeDemoAddress(updated, 'addr-first')
  assert.deepEqual(removed.addresses.map(({ id }) => id), ['addr-second'])
  assert.equal(removed.selectedId, 'addr-second')
  assert.deepEqual(emptyDemoAddressBook(), { addresses: [], selectedId: null })
})

test('invalid contact, PIN, oversized data and duplicate IDs are rejected before save', () => {
  const empty = emptyDemoAddressBook()
  assert.throws(() => addDemoAddress(empty, { ...details, phone: '1234567890' }, () => 'addr-a'), /Check the recipient/)
  assert.throws(() => addDemoAddress(empty, { ...details, pinCode: '000000' }, () => 'addr-a'), /Check the recipient/)
  assert.throws(() => addDemoAddress(empty, { ...details, addressLine1: 'x' }, () => 'addr-a'), /Check the recipient/)
  assert.throws(() => addDemoAddress(empty, { ...details, name: 'Bad\nName' }, () => 'addr-a'), /Check the recipient/)
  assert.throws(() => addDemoAddress(empty, details, () => '__proto__'), /unique demo address/)
  const first = addDemoAddress(empty, details, () => 'addr-a')
  assert.throws(() => addDemoAddress(first, details, () => 'addr-a'), /unique demo address/)
  assert.throws(() => updateDemoAddress(first, 'missing', details), /no longer available/)
  assert.throws(() => selectDemoAddress(first, 'missing'), /no longer available/)
  assert.throws(() => removeDemoAddress(first, 'missing'), /no longer available/)
  let book = first
  for (let index = 2; index <= MAX_DEMO_ADDRESSES; index += 1) {
    book = addDemoAddress(book, details, () => `addr-${index}`)
  }
  assert.throws(() => addDemoAddress(book, details, () => 'addr-over-limit'), /up to 5/)
})

test('versioned storage round trip preserves the selected address only after explicit write', () => {
  const storage = memoryStorage()
  assert.equal(DEMO_ADDRESSES_STORAGE_KEY, 'proto:web:demo-addresses:v1')
  const book = addDemoAddress(emptyDemoAddressBook(), details, () => 'addr-a')
  assert.deepEqual(readDemoAddressBook(storage), emptyDemoAddressBook())
  assert.equal(writeDemoAddressBook(storage, book), true)
  assert.deepEqual(readDemoAddressBook(storage), book)
  assert.equal(JSON.parse(storage.values.get(DEMO_ADDRESSES_STORAGE_KEY)).version, 1)
  assert.equal(writeDemoAddressBook(storage, emptyDemoAddressBook()), true)
  assert.deepEqual(readDemoAddressBook(storage), emptyDemoAddressBook())
})

test('malformed, outdated and oversized storage safely yields empty or filtered addresses', () => {
  const storage = memoryStorage()
  storage.setItem(DEMO_ADDRESSES_STORAGE_KEY, '{broken')
  assert.deepEqual(readDemoAddressBook(storage), emptyDemoAddressBook())
  storage.setItem(DEMO_ADDRESSES_STORAGE_KEY, JSON.stringify({ version: 0, addresses: [details] }))
  assert.deepEqual(readDemoAddressBook(storage), emptyDemoAddressBook())
  storage.setItem(DEMO_ADDRESSES_STORAGE_KEY, JSON.stringify({ version: 1, addresses: [] }).repeat(2000))
  assert.deepEqual(readDemoAddressBook(storage), emptyDemoAddressBook())
  const good = addDemoAddress(emptyDemoAddressBook(), details, () => 'addr-good').addresses[0]
  storage.setItem(DEMO_ADDRESSES_STORAGE_KEY, JSON.stringify({
    version: 1, selectedId: 'missing', addresses: [
      { ...good, phone: 'bad' }, good, good,
      { ...good, id: 'addr-other', pinCode: '000000' },
    ],
  }))
  assert.deepEqual(readDemoAddressBook(storage), { addresses: [good], selectedId: 'addr-good' })
  storage.setItem(DEMO_ADDRESSES_STORAGE_KEY, JSON.stringify({ version: 1, selectedId: null, addresses: {} }))
  assert.deepEqual(readDemoAddressBook(storage), emptyDemoAddressBook())
})

test('blocked storage never throws and invalid books are not written', () => {
  const blocked = {
    getItem() { throw new Error('blocked read') },
    setItem() { throw new Error('blocked write') },
  }
  const book = addDemoAddress(emptyDemoAddressBook(), details, () => 'addr-a')
  assert.deepEqual(readDemoAddressBook(blocked), emptyDemoAddressBook())
  assert.equal(writeDemoAddressBook(blocked, book), false)
  assert.deepEqual(readDemoAddressBook(null), emptyDemoAddressBook())
  assert.equal(writeDemoAddressBook(null, book), false)
  assert.equal(writeDemoAddressBook(memoryStorage(), { addresses: [book.addresses[0]], selectedId: 'unknown' }), false)
})
