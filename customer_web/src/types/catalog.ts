export type Category = {
  id: string
  slug: string
  name: string
  description: string | null
}

export type Product = {
  id: string
  sku: string
  name: string
  description: string | null
  price: string
  originalPrice?: string
  currency: string
  imageUrl: string | null
  available: boolean
  brand?: string
  weightLabel?: string
  badge?: string
  category: Category
  createdAt: string
}

export type Catalog = {
  categories: Category[]
  products: Product[]
}
