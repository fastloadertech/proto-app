import type { Catalog } from '../types/catalog.ts'
import { formatPrice } from './formatPrice.ts'

/** Notices for saved items seen in both the previous and freshly loaded catalogues. */
export function bagCatalogChanges(previous: Catalog | null, current: Catalog, quantities: Record<string, number>): string[] {
  if (!previous) return []

  const before = new Map(previous.products.map((product) => [product.id, product]))
  const after = new Map(current.products.map((product) => [product.id, product]))
  const changes: string[] = []

  for (const [id, quantity] of Object.entries(quantities)) {
    if (!Number.isInteger(quantity) || quantity < 1) continue
    const oldProduct = before.get(id)
    if (!oldProduct) continue // This saved ID may belong to another catalogue mode.
    const product = after.get(id)
    if (!product) {
      changes.push(`${oldProduct.name} is no longer listed in this catalogue.`)
      continue
    }
    if (oldProduct.price !== product.price || oldProduct.currency !== product.currency) {
      changes.push(`${product.name} changed price from ${formatPrice(oldProduct.price, oldProduct.currency)} to ${formatPrice(product.price, product.currency)}.`)
    }
    const wasAvailable = oldProduct.available && oldProduct.stockQuantity !== 0
    const isAvailable = product.available && product.stockQuantity !== 0
    if (wasAvailable && !isAvailable) {
      changes.push(`${product.name} is now unavailable.`)
    }
    const newStock = product.stockQuantity
    const oldStock = oldProduct.stockQuantity
    if (isAvailable && newStock != null && newStock < quantity && (oldStock == null || oldStock >= quantity)) {
      changes.push(`${product.name} now has only ${newStock} in stock; your bag has ${quantity}.`)
    }
  }

  return changes
}
