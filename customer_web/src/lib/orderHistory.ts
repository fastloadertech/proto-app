import type { DemoOrder, DemoOrderItem } from './checkout.ts'
import type { StorageLike } from './persistence.ts'

export const HISTORY_STORAGE_KEY = 'proto:web:demo-orders:v1'

export type DemoOrderHistoryEntry = {
  mode: 'local-demo'
  status: 'demo-confirmed'
  reference: string
  createdAt: string
  currency: 'INR'
  subtotalMinor: number
  count: number
  items: DemoOrderItem[]
  delivery: { city: string; state: string; pinCode: string }
}

const SCHEMA_VERSION = 1
const MAX_HISTORY_ENTRIES = 20
const MAX_SAFE_MINOR = BigInt(Number.MAX_SAFE_INTEGER)
const PIN_PATTERN = /^[1-9]\d{5}$/

function record(value: unknown): value is Record<string, unknown> {
  return value !== null && typeof value === 'object' && !Array.isArray(value)
}

function cleanText(value: unknown, maxLength: number): string | null {
  if (typeof value !== 'string') return null
  const clean = value.trim()
  return clean && clean.length <= maxLength && !/[\u0000-\u001f\u007f]/.test(clean) ? clean : null
}

function cleanItem(value: unknown): DemoOrderItem | null {
  if (!record(value)) return null
  const productId = cleanText(value.productId, 256)
  const name = cleanText(value.name, 160)
  const weightLabel = value.weightLabel === null ? null : value.weightLabel === undefined ? null : cleanText(value.weightLabel, 80)
  const quantity = value.quantity
  const unitMinor = value.unitMinor
  const lineMinor = value.lineMinor
  if (!productId || !name || (value.weightLabel !== null && value.weightLabel !== undefined && weightLabel === null) ||
      !Number.isInteger(quantity) || (quantity as number) < 1 || (quantity as number) > 99 ||
      !Number.isSafeInteger(unitMinor) || (unitMinor as number) < 0 ||
      !Number.isSafeInteger(lineMinor) || (lineMinor as number) < 0 ||
      BigInt(lineMinor as number) !== BigInt(unitMinor as number) * BigInt(quantity as number)) return null
  return { productId, name, weightLabel, quantity: quantity as number, unitMinor: unitMinor as number, lineMinor: lineMinor as number }
}

function cleanEntry(value: unknown): DemoOrderHistoryEntry | null {
  if (!record(value) || value.mode !== 'local-demo' || value.status !== 'demo-confirmed' || value.currency !== 'INR') return null
  const reference = cleanText(value.reference, 128)
  const createdAt = cleanText(value.createdAt, 40)
  if (!reference || !createdAt || !/^\d{4}-\d{2}-\d{2}T/.test(createdAt) || !Number.isFinite(Date.parse(createdAt))) return null
  if (!Number.isSafeInteger(value.subtotalMinor) || (value.subtotalMinor as number) < 0 ||
      !Number.isSafeInteger(value.count) || (value.count as number) < 1 ||
      !Array.isArray(value.items) || value.items.length === 0 || !record(value.delivery)) return null
  const city = cleanText(value.delivery.city, 100)
  const state = cleanText(value.delivery.state, 100)
  const pinCode = cleanText(value.delivery.pinCode, 6)
  if (!city || !state || !pinCode || !PIN_PATTERN.test(pinCode)) return null

  const items: DemoOrderItem[] = []
  const itemIds = new Set<string>()
  let total = 0n
  let count = 0
  for (const raw of value.items) {
    const item = cleanItem(raw)
    if (!item || itemIds.has(item.productId)) return null
    itemIds.add(item.productId)
    total += BigInt(item.lineMinor)
    count += item.quantity
    if (total > MAX_SAFE_MINOR || !Number.isSafeInteger(count)) return null
    items.push(item)
  }
  if (Number(total) !== value.subtotalMinor || count !== value.count) return null
  return {
    mode: 'local-demo', status: 'demo-confirmed', reference, createdAt, currency: 'INR',
    subtotalMinor: Number(total), count, items, delivery: { city, state, pinCode },
  }
}

function cleanEntries(value: unknown): DemoOrderHistoryEntry[] {
  if (!Array.isArray(value)) return []
  const entries: DemoOrderHistoryEntry[] = []
  const references = new Set<string>()
  try {
    for (const raw of value) {
      const entry = cleanEntry(raw)
      if (!entry || references.has(entry.reference)) continue
      references.add(entry.reference)
      entries.push(entry)
      if (entries.length === MAX_HISTORY_ENTRIES) break
    }
  } catch {
    return []
  }
  return entries
}

/** Removes contact details and street address before an order reaches storage. */
export function toHistoryEntry(order: DemoOrder): DemoOrderHistoryEntry {
  const entry = cleanEntry({
    mode: order.mode,
    status: order.status,
    reference: order.reference,
    createdAt: order.createdAt,
    currency: order.currency,
    subtotalMinor: order.subtotalMinor,
    count: order.count,
    items: order.items,
    delivery: {
      city: order.delivery.city,
      state: order.delivery.state,
      pinCode: order.delivery.pinCode,
    },
  })
  if (!entry) throw new Error('The demo order could not be added to local history.')
  return entry
}

export function readDemoOrders(storage: StorageLike | null | undefined): DemoOrderHistoryEntry[] {
  try {
    const raw = storage?.getItem(HISTORY_STORAGE_KEY)
    if (!raw) return []
    const payload: unknown = JSON.parse(raw)
    return record(payload) && payload.version === SCHEMA_VERSION ? cleanEntries(payload.orders) : []
  } catch {
    return []
  }
}

export function writeDemoOrders(storage: StorageLike | null | undefined, entries: DemoOrderHistoryEntry[]): boolean {
  try {
    if (!storage) return false
    storage.setItem(HISTORY_STORAGE_KEY, JSON.stringify({ version: SCHEMA_VERSION, orders: cleanEntries(entries) }))
    return true
  } catch {
    return false
  }
}
