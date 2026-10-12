import { demoCatalog } from '../data/demoCatalog.ts'
import type { Catalog, Category, Product } from '../types/catalog.ts'
import { configuredApiOrigin, getJson, type ApiEnvironment } from './client.ts'

export type CatalogMode = 'demo' | 'live'
export type CatalogEnvironment = ApiEnvironment & { VITE_PROTO_CATALOG_MODE?: string }

export function configuredCatalogMode(env: CatalogEnvironment = import.meta.env): CatalogMode {
  const value = env.VITE_PROTO_CATALOG_MODE?.trim() || (env.DEV && !env.PROD ? 'demo' : '')
  if (value === 'demo' || value === 'live') return value
  throw new Error('Set VITE_PROTO_CATALOG_MODE explicitly to demo or live for this build.')
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
  const stockQuantity = item.stockQuantity
  if (!/^\d+\.\d{2}$/.test(price) || typeof item.available !== 'boolean' ||
      (item.imageUrl !== null && typeof item.imageUrl !== 'string') ||
      (item.description !== null && typeof item.description !== 'string') ||
      (stockQuantity !== undefined && stockQuantity !== null &&
        (!Number.isSafeInteger(stockQuantity) || (stockQuantity as number) < 0))) {
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
    ...(stockQuantity === undefined ? {} : { stockQuantity: stockQuantity as number | null }),
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

export async function loadCatalog(
  mode: CatalogMode,
  signal: AbortSignal,
  options: { env?: CatalogEnvironment; fetchImpl?: typeof fetch } = {},
): Promise<Catalog> {
  if (mode === 'demo') return demoCatalog
  const origin = configuredApiOrigin(options.env ?? import.meta.env)
  const [categories, products] = await Promise.all([
    getJson(`${origin}/api/v1/catalog/categories`, signal, options.fetchImpl),
    getJson(`${origin}/api/v1/catalog/products?active=true&sort=newest`, signal, options.fetchImpl),
  ])
  return parseCatalog(categories, products)
}
