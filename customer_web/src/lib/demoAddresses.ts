import { validateCheckoutDetails, type CheckoutDetails } from './checkout.ts'
import type { StorageLike } from './persistence.ts'

export const DEMO_ADDRESSES_STORAGE_KEY = 'proto:web:demo-addresses:v1'
export const MAX_DEMO_ADDRESSES = 5

export type DemoAddress = CheckoutDetails & { id: string }
export type DemoAddressBook = { addresses: DemoAddress[]; selectedId: string | null }

const SCHEMA_VERSION = 1
const MAX_PAYLOAD_LENGTH = 16_000
const addressFields: (keyof CheckoutDetails)[] = [
  'name', 'phone', 'addressLine1', 'addressLine2', 'locality', 'city', 'state', 'pinCode',
]
const CONTROL_CHARACTERS = /[\u0000-\u001f\u007f]/
const ID_PATTERN = /^[a-zA-Z0-9_-]{1,80}$/
const UNSAFE_IDS = new Set(['__proto__', 'constructor', 'prototype'])

function isRecord(value: unknown): value is Record<string, unknown> {
  return value !== null && typeof value === 'object' && !Array.isArray(value)
}

function validId(value: unknown): value is string {
  return typeof value === 'string' && ID_PATTERN.test(value) && !UNSAFE_IDS.has(value)
}

function normalizeDetails(value: unknown): CheckoutDetails | null {
  if (!isRecord(value)) return null
  const details = {} as CheckoutDetails
  for (const field of addressFields) {
    const raw = value[field]
    if (field === 'addressLine2' && raw === undefined) {
      details[field] = ''
      continue
    }
    if (typeof raw !== 'string' || CONTROL_CHARACTERS.test(raw)) return null
    details[field] = raw.trim()
  }
  return Object.keys(validateCheckoutDetails(details)).length === 0 ? details : null
}

function normalizeAddress(value: unknown): DemoAddress | null {
  if (!isRecord(value) || !validId(value.id)) return null
  const details = normalizeDetails(value)
  return details ? { id: value.id, ...details } : null
}

export function emptyDemoAddressBook(): DemoAddressBook {
  return { addresses: [], selectedId: null }
}

function normalizeBook(value: unknown): DemoAddressBook {
  if (!isRecord(value) || !Array.isArray(value.addresses)) return emptyDemoAddressBook()
  const addresses: DemoAddress[] = []
  const seen = new Set<string>()
  for (const raw of value.addresses.slice(0, MAX_DEMO_ADDRESSES * 4)) {
    const address = normalizeAddress(raw)
    if (!address || seen.has(address.id)) continue
    seen.add(address.id)
    addresses.push(address)
    if (addresses.length === MAX_DEMO_ADDRESSES) break
  }
  const selectedId = validId(value.selectedId) && seen.has(value.selectedId)
    ? value.selectedId : addresses[0]?.id ?? null
  return { addresses, selectedId }
}

function assertBook(book: DemoAddressBook): DemoAddressBook {
  const clean = normalizeBook(book)
  if (!Array.isArray(book?.addresses) || clean.addresses.length !== book.addresses.length ||
      clean.selectedId !== book.selectedId) {
    throw new Error('The saved demo addresses need to be reviewed.')
  }
  return clean
}

function newAddressId(): string {
  const value = globalThis.crypto?.randomUUID?.() ??
    `${Date.now().toString(36)}-${Math.random().toString(36).slice(2)}`
  return `addr-${value}`
}

export function addDemoAddress(
  book: DemoAddressBook,
  details: CheckoutDetails,
  idFactory: () => string = newAddressId,
): DemoAddressBook {
  const current = assertBook(book)
  if (current.addresses.length >= MAX_DEMO_ADDRESSES) {
    throw new Error(`You can save up to ${MAX_DEMO_ADDRESSES} demo addresses.`)
  }
  const cleanDetails = normalizeDetails(details)
  if (!cleanDetails) throw new Error('Check the recipient and address fields before saving.')
  const id = idFactory()
  if (!validId(id) || current.addresses.some((address) => address.id === id)) {
    throw new Error('Could not create a unique demo address. Please try again.')
  }
  return { addresses: [...current.addresses, { id, ...cleanDetails }], selectedId: id }
}

export function updateDemoAddress(book: DemoAddressBook, id: string, details: CheckoutDetails): DemoAddressBook {
  const current = assertBook(book)
  const cleanDetails = normalizeDetails(details)
  if (!cleanDetails) throw new Error('Check the recipient and address fields before saving.')
  if (!current.addresses.some((address) => address.id === id)) throw new Error('That demo address is no longer available.')
  return {
    addresses: current.addresses.map((address) => address.id === id ? { id, ...cleanDetails } : address),
    selectedId: current.selectedId,
  }
}

export function selectDemoAddress(book: DemoAddressBook, id: string): DemoAddressBook {
  const current = assertBook(book)
  if (!current.addresses.some((address) => address.id === id)) throw new Error('That demo address is no longer available.')
  return { addresses: current.addresses, selectedId: id }
}

export function removeDemoAddress(book: DemoAddressBook, id: string): DemoAddressBook {
  const current = assertBook(book)
  if (!current.addresses.some((address) => address.id === id)) throw new Error('That demo address is no longer available.')
  const addresses = current.addresses.filter((address) => address.id !== id)
  const selectedId = current.selectedId === id ? addresses[0]?.id ?? null : current.selectedId
  return { addresses, selectedId }
}

export function readDemoAddressBook(storage: StorageLike | null | undefined): DemoAddressBook {
  try {
    const raw = storage?.getItem(DEMO_ADDRESSES_STORAGE_KEY)
    if (!raw || raw.length > MAX_PAYLOAD_LENGTH) return emptyDemoAddressBook()
    const payload: unknown = JSON.parse(raw)
    return isRecord(payload) && payload.version === SCHEMA_VERSION
      ? normalizeBook(payload) : emptyDemoAddressBook()
  } catch {
    return emptyDemoAddressBook()
  }
}

export function writeDemoAddressBook(storage: StorageLike | null | undefined, book: DemoAddressBook): boolean {
  try {
    if (!storage) return false
    const clean = assertBook(book)
    storage.setItem(DEMO_ADDRESSES_STORAGE_KEY, JSON.stringify({ version: SCHEMA_VERSION, ...clean }))
    return true
  } catch {
    return false
  }
}
