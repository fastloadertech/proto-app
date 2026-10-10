import { demoCatalog } from '../data/demoCatalog.ts'
import type { Catalog, Category, Product } from '../types/catalog.ts'

export type CatalogMode = 'demo' | 'live'

export function configuredCatalogMode(): CatalogMode {
  const value = import.meta.env.VITE_PROTO_CATALOG_MODE || 'demo'
  if (value === 'demo' || value === 'live') return value
  throw new Error('VITE_PROTO_CATALOG_MODE must be demo or live.')
}

function apiBaseUrl(): string {
  const configured = import.meta.env.VITE_PROTO_API_BASE_URL?.trim()
  const value = configured || (import.meta.env.DEV ? 'http://localhost:3101' : '')
  if (!value) throw new Error('Set VITE_PROTO_API_BASE_URL to use the live catalog in this build.')
  const url = new URL(value)
  if (!['http:', 'https:'].includes(url.protocol) || url.username || url.password) {
    throw new Error('VITE_PROTO_API_BASE_URL must be a plain HTTP(S) origin.')
  }
  return url.origin
}

async function getJson(url: string, signal: AbortSignal): Promise<unknown> {
  const timeout = AbortSignal.timeout(10000)
  try {
    const response = await fetch(url, {
      method: 'GET',
      headers: { Accept: 'application/json' },
      signal: AbortSignal.any([signal, timeout]),
    })
    if (!response.ok) throw new Error(`Catalog request failed (HTTP ${response.status}).`)
    return await response.json()
  } catch (error) {
    if (signal.aborted) throw error
    if (timeout.aborted) throw new Error('The catalog request timed out. Try again.')
    if (error instanceof TypeError) {
      throw new Error('Cannot reach the catalog. Check the backend address and browser CORS configuration.')
    }
    throw error
  }
}

function record(value: unknown): Record<string, unknown> {
  if (value === null || typeof value !== 'object' || Array.isArray(value)) {
    throw new Error('The catalog returned an unexpected response.')
  }
  return value as Record<string, unknown>
}

function text(value: unknown): string {
  if (typeof value !== 'string' || !value.trim()) {
    throw new Error('The catalog returned an unexpected response.')
  }
  return value
}

function categoryFromApi(value: unknown): Category {
  const item = record(value)
  if (item.description !== null && typeof item.description !== 'string') {
    throw new Error('The catalog returned an unexpected category.')
  }
  return {
    id: text(item.id),
    slug: text(item.slug),
    name: text(item.name),
    description: item.description,
  }
}

function productFromApi(value: unknown): Product {
  const item = record(value)
  const price = text(item.price)
  if (!/^\d+\.\d{2}$/.test(price) || typeof item.available !== 'boolean' ||
      (item.imageUrl !== null && typeof item.imageUrl !== 'string') ||
      (item.description !== null && typeof item.description !== 'string')) {
    throw new Error('The catalog returned an unexpected product.')
  }
  return {
    id: text(item.id),
    sku: text(item.sku),
    name: text(item.name),
    description: item.description,
    price,
    currency: text(item.currency),
    imageUrl: item.imageUrl,
    available: item.available,
    category: categoryFromApi(item.category),
    createdAt: text(item.createdAt),
  }
}

export function parseCatalog(categoriesBody: unknown, productsBody: unknown): Catalog {
  if (!Array.isArray(categoriesBody) || !Array.isArray(productsBody)) {
    throw new Error('The catalog returned an unexpected response.')
  }
  const categories = categoriesBody.map(categoryFromApi)
  const activeSlugs = new Set(categories.map((item) => item.slug))
  const products = productsBody.map(productFromApi).filter((item) => activeSlugs.has(item.category.slug))
  return { categories, products }
}

export async function loadCatalog(mode: CatalogMode, signal: AbortSignal): Promise<Catalog> {
  if (mode === 'demo') return demoCatalog
  const origin = apiBaseUrl()
  const [categories, products] = await Promise.all([
    getJson(`${origin}/api/v1/catalog/categories`, signal),
    getJson(`${origin}/api/v1/catalog/products?active=true&sort=newest`, signal),
  ])
  return parseCatalog(categories, products)
}
