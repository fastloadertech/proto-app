export const BAG_STORAGE_KEY = 'proto:web:bag:v1'
export const FAVORITES_STORAGE_KEY = 'proto:web:favourites:v1'

const SCHEMA_VERSION = 1
const MAX_QUANTITY = 99
const MAX_ID_LENGTH = 256
const unsafeKeys = new Set(['__proto__', 'constructor', 'prototype'])

export type StorageLike = {
  getItem(key: string): string | null
  setItem(key: string, value: string): void
}

type StorageHost = { readonly localStorage?: StorageLike | null }

/** Reading window.localStorage itself can throw when browser storage is blocked. */
export function getBrowserStorage(host: StorageHost | null | undefined = typeof window === 'undefined' ? null : window): StorageLike | null {
  try {
    return host?.localStorage ?? null
  } catch {
    return null
  }
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return value !== null && typeof value === 'object' && !Array.isArray(value)
}

function isProductId(value: unknown): value is string {
  return typeof value === 'string' && value.length > 0 && value.length <= MAX_ID_LENGTH &&
    value.trim() === value && !/[\u0000-\u001f\u007f]/.test(value) && !unsafeKeys.has(value)
}

/** Returns only usable quantities; zero and invalid entries do not persist. */
export function sanitizeBag(value: unknown): Record<string, number> {
  const bag: Record<string, number> = {}
  if (!isRecord(value)) return bag
  try {
    for (const [id, quantity] of Object.entries(value)) {
      if (isProductId(id) && typeof quantity === 'number' && Number.isInteger(quantity) && quantity > 0) {
        bag[id] = Math.min(quantity, MAX_QUANTITY)
      }
    }
  } catch {
    return {}
  }
  return bag
}

/** Hide items absent from the current catalogue without deleting saved items from another catalogue mode. */
export function bagForCatalog(bag: Record<string, number>, productIds: readonly string[]): Record<string, number> {
  const ids = new Set(productIds)
  return Object.fromEntries(Object.entries(sanitizeBag(bag)).filter(([id]) => ids.has(id)))
}

/** Checkout clears only the items it submitted, preserving items from another catalogue mode. */
export function withoutCatalogBag(bag: Record<string, number>, productIds: readonly string[]): Record<string, number> {
  const ids = new Set(productIds)
  return Object.fromEntries(Object.entries(sanitizeBag(bag)).filter(([id]) => !ids.has(id)))
}

/** Keeps the first occurrence of each valid product ID. */
export function sanitizeFavorites(value: unknown): string[] {
  if (!Array.isArray(value)) return []
  const ids: string[] = []
  const seen = new Set<string>()
  try {
    for (const id of value) {
      if (isProductId(id) && !seen.has(id)) {
        seen.add(id)
        ids.push(id)
      }
    }
  } catch {
    return []
  }
  return ids
}

function readPayload(storage: StorageLike | null | undefined, key: string): unknown {
  try {
    const raw = storage?.getItem(key)
    return typeof raw === 'string' ? JSON.parse(raw) as unknown : null
  } catch {
    return null
  }
}

function writePayload(storage: StorageLike | null | undefined, key: string, payload: unknown): boolean {
  try {
    if (!storage) return false
    storage.setItem(key, JSON.stringify(payload))
    return true
  } catch {
    return false
  }
}

export function readBag(storage: StorageLike | null | undefined): Record<string, number> {
  const payload = readPayload(storage, BAG_STORAGE_KEY)
  try {
    return isRecord(payload) && payload.version === SCHEMA_VERSION
      ? sanitizeBag(payload.quantities)
      : {}
  } catch {
    return {}
  }
}

export function writeBag(storage: StorageLike | null | undefined, bag: Record<string, number>): boolean {
  return writePayload(storage, BAG_STORAGE_KEY, {
    version: SCHEMA_VERSION,
    quantities: sanitizeBag(bag),
  })
}

export function readFavorites(storage: StorageLike | null | undefined): string[] {
  const payload = readPayload(storage, FAVORITES_STORAGE_KEY)
  try {
    return isRecord(payload) && payload.version === SCHEMA_VERSION
      ? sanitizeFavorites(payload.ids)
      : []
  } catch {
    return []
  }
}

export function writeFavorites(storage: StorageLike | null | undefined, favorites: string[]): boolean {
  return writePayload(storage, FAVORITES_STORAGE_KEY, {
    version: SCHEMA_VERSION,
    ids: sanitizeFavorites(favorites),
  })
}
