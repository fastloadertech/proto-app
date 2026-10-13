import type { DemoOrder, DemoOrderItem } from './checkout.ts'
import type { StorageLike } from './persistence.ts'

export const HISTORY_STORAGE_KEY = 'proto:web:demo-orders:v1'

export const DEMO_ORDER_STATUSES = ['demo-confirmed', 'demo-reviewed', 'demo-archived'] as const
export type DemoOrderStatus = typeof DEMO_ORDER_STATUSES[number]

/** Customer-facing stages are a manual simulation, unrelated to fulfilment or admin annotations. */
export const DEMO_SIMULATION_STAGES = ['placed', 'confirmed', 'preparing', 'ready', 'delivered'] as const
export type DemoSimulationStage = typeof DEMO_SIMULATION_STAGES[number]

export function demoSimulationStageLabel(stage: DemoSimulationStage): string {
  switch (stage) {
    case 'placed': return 'Placed'
    case 'confirmed': return 'Confirmed'
    case 'preparing': return 'Preparing'
    case 'ready': return 'Ready for delivery'
    case 'delivered': return 'Delivered'
    default: throw new Error('Unsupported demo simulation stage.')
  }
}

export function demoOrderStatusLabel(status: DemoOrderStatus): string {
  switch (status) {
    case 'demo-confirmed': return 'Demo confirmed'
    case 'demo-reviewed': return 'Demo reviewed'
    case 'demo-archived': return 'Demo archived'
    default: throw new Error('Unsupported demo order status.')
  }
}

function isDemoOrderStatus(value: unknown): value is DemoOrderStatus {
  return typeof value === 'string' && DEMO_ORDER_STATUSES.some((status) => status === value)
}

function isDemoSimulationStage(value: unknown): value is DemoSimulationStage {
  return typeof value === 'string' && DEMO_SIMULATION_STAGES.some((stage) => stage === value)
}

export type DemoOrderHistoryEntry = {
  mode: 'local-demo'
  status: DemoOrderStatus
  simulationStage: DemoSimulationStage
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
  if (!record(value) || value.mode !== 'local-demo' || !isDemoOrderStatus(value.status) || value.currency !== 'INR') return null
  // Existing v1 records predate the customer timeline; their first stage is Placed.
  const simulationStage = value.simulationStage === undefined ? 'placed' : value.simulationStage
  if (!isDemoSimulationStage(simulationStage)) return null
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
    mode: 'local-demo', status: value.status, simulationStage, reference, createdAt, currency: 'INR',
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
    simulationStage: 'placed',
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

/** Prepends a new local order without replacing an earlier reference. */
export function appendDemoOrder(entries: DemoOrderHistoryEntry[], order: DemoOrder): DemoOrderHistoryEntry[] {
  if (!Array.isArray(entries)) throw new Error('Demo order history is invalid.')
  const entry = toHistoryEntry(order)
  const existing: DemoOrderHistoryEntry[] = []
  const references = new Set<string>()
  for (const raw of entries) {
    const valid = cleanEntry(raw)
    if (!valid || references.has(valid.reference)) throw new Error('Demo order history contains an invalid record.')
    if (valid.reference === entry.reference) throw new Error('Demo order reference already exists. Please try again.')
    references.add(valid.reference)
    existing.push(valid)
  }
  return [entry, ...existing].slice(0, MAX_HISTORY_ENTRIES)
}

/** Updates an admin annotation on a local demo record without changing its order snapshot. */
export function updateDemoOrderStatus(
  entries: DemoOrderHistoryEntry[],
  reference: string,
  status: DemoOrderStatus,
): DemoOrderHistoryEntry[] {
  if (typeof reference !== 'string' || !reference || reference !== reference.trim() ||
      reference.length > 128 || /[\u0000-\u001f\u007f]/.test(reference)) {
    throw new Error('Enter a valid demo order reference.')
  }
  if (!isDemoOrderStatus(status)) throw new Error('Unsupported demo order status.')
  if (!Array.isArray(entries)) throw new Error('Demo order history is invalid.')

  let found = false
  const updated = entries.map((entry) => {
    const valid = cleanEntry(entry)
    if (!valid) throw new Error('Demo order history contains an invalid record.')
    if (valid.reference === reference) {
      found = true
      valid.status = status
    }
    return valid
  })
  if (!found) throw new Error('Demo order reference was not found.')
  return updated
}

/** Advances exactly one step after a customer action; never starts real fulfilment. */
export function advanceDemoSimulation(entries: DemoOrderHistoryEntry[], reference: string): DemoOrderHistoryEntry[] {
  if (typeof reference !== 'string' || !reference || reference !== reference.trim() ||
      reference.length > 128 || /[\u0000-\u001f\u007f]/.test(reference)) {
    throw new Error('Enter a valid demo order reference.')
  }
  if (!Array.isArray(entries)) throw new Error('Demo order history is invalid.')

  let found = false
  const updated = entries.map((entry) => {
    const valid = cleanEntry(entry)
    if (!valid) throw new Error('Demo order history contains an invalid record.')
    if (valid.reference !== reference) return valid
    found = true
    const currentIndex = DEMO_SIMULATION_STAGES.indexOf(valid.simulationStage)
    if (currentIndex === DEMO_SIMULATION_STAGES.length - 1) {
      throw new Error('This demo timeline is already complete.')
    }
    return { ...valid, simulationStage: DEMO_SIMULATION_STAGES[currentIndex + 1] }
  })
  if (!found) throw new Error('Demo order reference was not found.')
  return updated
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
