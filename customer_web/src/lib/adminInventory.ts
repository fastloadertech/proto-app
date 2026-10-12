import type { Product } from '../types/catalog.ts'
import type { StorageLike } from './persistence.ts'

export const ADMIN_INVENTORY_STORAGE_KEY = 'proto:web:admin:inventory:v1'

export type InventoryEdit = { price: string; stock: number }
export type InventoryEdits = Record<string, InventoryEdit>
export type InventoryStockStatus = 'in-stock' | 'low-stock' | 'out-of-stock' | 'unknown'
export type InventoryMode = 'demo' | 'live'
export type InventoryRow = {
  product: Product
  price: string
  stock: number | null
  stockStatus: InventoryStockStatus
  catalogAvailable: boolean
}
export type InventoryFilters = {
  query: string
  categorySlug: string
  stockStatus: InventoryStockStatus | 'all'
}
export type InventorySummary = {
  totalProducts: number
  inStockProducts: number
  lowStockProducts: number
  outOfStockProducts: number
  unknownStockProducts: number
}

const SCHEMA_VERSION = 1
const LOW_STOCK_LIMIT = 5
const MAX_STOCK = 1_000_000
const MAX_SAFE_MINOR = BigInt(Number.MAX_SAFE_INTEGER)
const PRICE_PATTERN = /^(?:0|[1-9]\d*)(?:\.(\d{1,2}))?$/
const STORED_PRICE_PATTERN = /^(?:0|[1-9]\d*)\.\d{2}$/
const STOCK_PATTERN = /^(?:0|[1-9]\d*)$/
const unsafeKeys = new Set(['__proto__', 'constructor', 'prototype'])

function isRecord(value: unknown): value is Record<string, unknown> {
  return value !== null && typeof value === 'object' && !Array.isArray(value)
}

function isProductId(value: unknown): value is string {
  return typeof value === 'string' && value.length > 0 && value.length <= 256 &&
    value.trim() === value && !/[\u0000-\u001f\u007f]/.test(value) && !unsafeKeys.has(value)
}

function normalizePrice(value: unknown): string | null {
  if (typeof value !== 'string') return null
  const input = value.trim()
  if (!input || input.length > 17) return null
  const match = PRICE_PATTERN.exec(input)
  if (!match) return null
  const [whole, fraction = ''] = input.split('.')
  const minor = BigInt(whole) * 100n + BigInt(fraction.padEnd(2, '0') || '0')
  if (minor > MAX_SAFE_MINOR) return null
  return `${whole}.${fraction.padEnd(2, '0')}`
}

function validStoredEdit(value: unknown): value is InventoryEdit {
  if (!isRecord(value) || typeof value.price !== 'string' ||
      value.price.length > 17 || !STORED_PRICE_PATTERN.test(value.price) ||
      normalizePrice(value.price) !== value.price) return false
  return typeof value.stock === 'number' && Number.isSafeInteger(value.stock) &&
    value.stock >= 0 && value.stock <= MAX_STOCK
}

function sanitizeInventoryEdits(value: unknown): InventoryEdits {
  const edits: InventoryEdits = {}
  if (!isRecord(value)) return edits
  try {
    for (const [id, edit] of Object.entries(value)) {
      if (isProductId(id) && validStoredEdit(edit)) {
        edits[id] = { price: edit.price, stock: edit.stock }
      }
    }
  } catch {
    return {}
  }
  return edits
}

export function readAdminInventory(storage: StorageLike | null | undefined): InventoryEdits {
  try {
    const raw = storage?.getItem(ADMIN_INVENTORY_STORAGE_KEY)
    if (typeof raw !== 'string') return {}
    const payload: unknown = JSON.parse(raw)
    return isRecord(payload) && payload.version === SCHEMA_VERSION
      ? sanitizeInventoryEdits(payload.edits)
      : {}
  } catch {
    return {}
  }
}

export function writeAdminInventory(storage: StorageLike | null | undefined, edits: InventoryEdits): boolean {
  try {
    if (!storage) return false
    storage.setItem(ADMIN_INVENTORY_STORAGE_KEY, JSON.stringify({
      version: SCHEMA_VERSION,
      edits: sanitizeInventoryEdits(edits),
    }))
    return true
  } catch {
    return false
  }
}

/** Returns a fresh edit map. The catalog product itself is never changed. */
export function updateInventoryItem(
  edits: InventoryEdits,
  product: Product,
  priceInput: string,
  stockInput: string,
): InventoryEdits {
  if (!isProductId(product?.id)) throw new Error('This product cannot be edited.')
  if (product.currency !== 'INR') throw new Error('Only INR prices can be edited in this local demo.')
  const price = normalizePrice(priceInput)
  if (price === null) throw new Error('Enter a valid non-negative INR price with up to two decimal places.')
  const stockText = typeof stockInput === 'string' ? stockInput.trim() : ''
  if (!STOCK_PATTERN.test(stockText)) throw new Error('Enter a whole, non-negative stock quantity.')
  const stock = Number(stockText)
  if (!Number.isSafeInteger(stock) || stock > MAX_STOCK) {
    throw new Error(`Stock quantity must be ${MAX_STOCK.toLocaleString('en-IN')} or less.`)
  }
  return { ...sanitizeInventoryEdits(edits), [product.id]: { price, stock } }
}

function classifyStock(stock: number): InventoryStockStatus {
  return stock === 0 ? 'out-of-stock' : stock <= LOW_STOCK_LIMIT ? 'low-stock' : 'in-stock'
}

/** Demo edits are browser-only. Live rows reflect the read-only backend catalogue. */
export function deriveInventoryRows(products: Product[], edits: InventoryEdits, mode: InventoryMode = 'demo'): InventoryRow[] {
  const safeEdits = mode === 'demo' ? sanitizeInventoryEdits(edits) : {}
  const seen = new Set<string>()
  const rows: InventoryRow[] = []
  for (const product of products) {
    if (!isProductId(product?.id) || seen.has(product.id)) continue
    seen.add(product.id)
    const edit = safeEdits[product.id]
    const liveStock = product.stockQuantity
    const stock = mode === 'live'
      ? typeof liveStock === 'number' && Number.isSafeInteger(liveStock) && liveStock >= 0 ? liveStock : null
      : edit?.stock ?? (product.available ? 12 : 0)
    rows.push({
      product,
      price: mode === 'live' ? product.price : edit?.price ?? product.price,
      stock,
      stockStatus: stock === null ? 'unknown' : classifyStock(stock),
      catalogAvailable: product.available,
    })
  }
  return rows
}

export function filterInventoryRows(rows: InventoryRow[], filters: InventoryFilters): InventoryRow[] {
  const query = filters.query.trim().toLocaleLowerCase('en-IN')
  return rows.filter((row) =>
    (!query || row.product.name.toLocaleLowerCase('en-IN').includes(query)) &&
    (filters.categorySlug === 'all' || row.product.category.slug === filters.categorySlug) &&
    (filters.stockStatus === 'all' || row.stockStatus === filters.stockStatus),
  )
}

export function summarizeInventory(rows: InventoryRow[]): InventorySummary {
  return rows.reduce<InventorySummary>((summary, row) => {
    summary.totalProducts += 1
    if (row.stock !== null && row.stock > 0) summary.inStockProducts += 1
    if (row.stockStatus === 'low-stock') summary.lowStockProducts += 1
    if (row.stockStatus === 'out-of-stock') summary.outOfStockProducts += 1
    if (row.stockStatus === 'unknown') summary.unknownStockProducts += 1
    return summary
  }, { totalProducts: 0, inStockProducts: 0, lowStockProducts: 0, outOfStockProducts: 0, unknownStockProducts: 0 })
}
