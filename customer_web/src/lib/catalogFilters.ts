import type { Product } from '../types/catalog.ts'

export type SortOption = 'featured' | 'price-asc' | 'price-desc' | 'name-asc'

export type CatalogFilters = {
  query: string
  categorySlug: string | null
  availableOnly: boolean
  sort: SortOption
}

export function filterProducts(products: Product[], filters: CatalogFilters): Product[] {
  const terms = filters.query.trim().toLocaleLowerCase().split(/\s+/).filter(Boolean)
  const matches = products.filter((product) => {
    if (filters.categorySlug && product.category.slug !== filters.categorySlug) return false
    if (filters.availableOnly && !product.available) return false
    const searchable = [product.name, product.sku, product.description ?? '', product.category.name]
      .join(' ')
      .toLocaleLowerCase()
    return terms.every((term) => searchable.includes(term))
  })

  if (filters.sort === 'price-asc') return matches.sort((a, b) => Number(a.price) - Number(b.price))
  if (filters.sort === 'price-desc') return matches.sort((a, b) => Number(b.price) - Number(a.price))
  if (filters.sort === 'name-asc') return matches.sort((a, b) => a.name.localeCompare(b.name))
  return matches
}
