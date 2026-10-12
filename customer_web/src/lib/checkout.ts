import type { Product } from '../types/catalog.ts'
import { sanitizeBag } from './persistence.ts'

export type CheckoutDetails = {
  name: string
  phone: string
  addressLine1: string
  addressLine2: string
  locality: string
  city: string
  state: string
  pinCode: string
}

export type CheckoutErrors = Partial<Record<keyof CheckoutDetails, string>>

export type BagLine = {
  product: Product
  quantity: number
  unitMinor: number
  lineMinor: number
}

export type BagSummary = {
  lines: BagLine[]
  subtotalMinor: number
  currency: string | null
  count: number
  error: string | null
}

export type DemoOrderItem = {
  productId: string
  name: string
  weightLabel: string | null
  quantity: number
  unitMinor: number
  lineMinor: number
}

export type DemoOrder = {
  mode: 'local-demo'
  status: 'demo-confirmed'
  reference: string
  createdAt: string
  currency: 'INR'
  subtotalMinor: number
  count: number
  items: DemoOrderItem[]
  delivery: CheckoutDetails
}

const MAX_QUANTITY = 99
const MAX_SAFE_MINOR = BigInt(Number.MAX_SAFE_INTEGER)
const PRICE_PATTERN = /^(?:0|[1-9]\d*)\.\d{2}$/
const PIN_PATTERN = /^[1-9]\d{5}$/
const PHONE_PATTERN = /^[6-9]\d{9}$/
const unsafeIds = new Set(['__proto__', 'constructor', 'prototype'])

function validProductId(id: unknown): id is string {
  return typeof id === 'string' && id.length > 0 && id.length <= 256 &&
    id.trim() === id && !/[\u0000-\u001f\u007f]/.test(id) && !unsafeIds.has(id)
}

function invalidBag(error: string): BagSummary {
  return { lines: [], subtotalMinor: 0, currency: null, count: 0, error }
}

function priceToMinor(price: unknown): bigint | null {
  if (typeof price !== 'string' || price.length > 17 || !PRICE_PATTERN.test(price)) return null
  const [whole, fraction] = price.split('.')
  const minor = BigInt(whole) * 100n + BigInt(fraction)
  return minor <= MAX_SAFE_MINOR ? minor : null
}

export function setBagQuantity(quantities: Record<string, number>, productId: string, next: number): Record<string, number> {
  const updated = sanitizeBag(quantities)
  if (!validProductId(productId) || !Number.isInteger(next) || next < 0) return updated
  if (next === 0) delete updated[productId]
  else updated[productId] = Math.min(next, MAX_QUANTITY)
  return updated
}

/** Calculates in integer paise and rejects a bag that cannot be submitted. */
export function calculateBag(products: Product[], quantities: Record<string, number>): BagSummary {
  if (!Array.isArray(products) || quantities === null || typeof quantities !== 'object' || Array.isArray(quantities)) {
    return invalidBag('The bag could not be read. Please review your items.')
  }

  let entries: [string, number][]
  try {
    entries = Object.entries(quantities)
  } catch {
    return invalidBag('The bag could not be read. Please review your items.')
  }
  const selected = entries.filter(([, quantity]) => quantity !== 0)
  if (selected.length === 0) return invalidBag('Add products to your bag before checkout.')

  const productsById = new Map<string, Product>()
  for (const product of products) {
    if (!validProductId(product?.id) || productsById.has(product.id)) {
      return invalidBag('The catalog has an invalid product. Please reload it.')
    }
    productsById.set(product.id, product)
  }

  const lines: BagLine[] = []
  let subtotal = 0n
  let count = 0n
  let currency: string | null = null
  for (const [id, quantity] of selected) {
    if (!validProductId(id) || !Number.isInteger(quantity) || quantity < 1 || quantity > MAX_QUANTITY) {
      return invalidBag('Review your bag quantities before checkout.')
    }
    const product = productsById.get(id)
    if (!product) return invalidBag('A product in your bag is no longer in the catalog.')
    if (!product.available) return invalidBag(`${product.name} is currently unavailable.`)
    if (product.stockQuantity != null && quantity > product.stockQuantity) {
      return invalidBag(`${product.name} has only ${product.stockQuantity} ${product.stockQuantity === 1 ? 'unit' : 'units'} available. Reduce the quantity before checkout.`)
    }
    if (currency !== null && product.currency !== currency) {
      return invalidBag('Products in your bag use different currencies.')
    }
    currency = product.currency

    const unit = priceToMinor(product.price)
    if (unit === null) return invalidBag(`${product.name} has an invalid price.`)
    const line = unit * BigInt(quantity)
    subtotal += line
    count += BigInt(quantity)
    if (line > MAX_SAFE_MINOR || subtotal > MAX_SAFE_MINOR || count > MAX_SAFE_MINOR) {
      return invalidBag('The bag total is too large to process safely.')
    }
    lines.push({ product, quantity, unitMinor: Number(unit), lineMinor: Number(line) })
  }
  if (currency !== 'INR') return invalidBag('Only INR products can be checked out in this local demo.')
  return { lines, subtotalMinor: Number(subtotal), currency, count: Number(count), error: null }
}

function trimmed(value: unknown): string {
  return typeof value === 'string' ? value.trim() : ''
}

export function validateCheckoutDetails(details: CheckoutDetails): CheckoutErrors {
  const errors: CheckoutErrors = {}
  if (trimmed(details?.name).length < 2 || trimmed(details?.name).length > 100) errors.name = 'Enter your full name.'
  if (!PHONE_PATTERN.test(trimmed(details?.phone))) errors.phone = 'Enter a valid 10-digit Indian mobile number.'
  if (trimmed(details?.addressLine1).length < 3 || trimmed(details?.addressLine1).length > 160) errors.addressLine1 = 'Enter your street address.'
  if ((details?.addressLine2 !== undefined && typeof details.addressLine2 !== 'string') || trimmed(details?.addressLine2).length > 160) {
    errors.addressLine2 = 'Check the second address line.'
  }
  if (!trimmed(details?.locality) || trimmed(details?.locality).length > 100) errors.locality = 'Enter your locality.'
  if (!trimmed(details?.city) || trimmed(details?.city).length > 100) errors.city = 'Enter your city.'
  if (!trimmed(details?.state) || trimmed(details?.state).length > 100) errors.state = 'Enter your state.'
  if (!PIN_PATTERN.test(trimmed(details?.pinCode))) errors.pinCode = 'Enter a valid 6-digit PIN code.'
  return errors
}

function validSummary(summary: BagSummary): boolean {
  if (!summary || summary.error !== null || !Array.isArray(summary.lines) || summary.lines.length === 0 || summary.currency !== 'INR') return false
  const quantities: Record<string, number> = {}
  const products: Product[] = []
  for (const line of summary.lines) {
    if (!line || !validProductId(line.product?.id) || Object.hasOwn(quantities, line.product.id)) return false
    quantities[line.product.id] = line.quantity
    products.push(line.product)
  }
  const recalculated = calculateBag(products, quantities)
  return recalculated.error === null && recalculated.count === summary.count &&
    recalculated.subtotalMinor === summary.subtotalMinor && recalculated.currency === summary.currency &&
    recalculated.lines.every((line, index) => line.unitMinor === summary.lines[index].unitMinor &&
      line.lineMinor === summary.lines[index].lineMinor)
}

function defaultReference(): string {
  const unique = globalThis.crypto?.randomUUID?.() ?? Math.random().toString(36).slice(2)
  return `DEMO-${Date.now().toString(36).toUpperCase()}-${unique.slice(0, 8).toUpperCase()}`
}

export function createDemoOrder(summary: BagSummary, details: CheckoutDetails, referenceFactory: () => string = defaultReference): DemoOrder {
  if (!validSummary(summary)) throw new Error('Review your bag before placing this demo order.')
  if (Object.keys(validateCheckoutDetails(details)).length > 0) {
    throw new Error('Check your contact and delivery details before continuing.')
  }
  const reference = referenceFactory()
  if (typeof reference !== 'string' || reference.trim() !== reference || reference.length === 0 || reference.length > 128 || /[\u0000-\u001f\u007f]/.test(reference)) {
    throw new Error('Could not create a demo order reference.')
  }
  return {
    mode: 'local-demo',
    status: 'demo-confirmed',
    reference,
    createdAt: new Date().toISOString(),
    currency: 'INR',
    subtotalMinor: summary.subtotalMinor,
    count: summary.count,
    items: summary.lines.map(({ product, quantity, unitMinor, lineMinor }) => ({
      productId: product.id,
      name: product.name,
      weightLabel: product.weightLabel ?? null,
      quantity,
      unitMinor,
      lineMinor,
    })),
    delivery: {
      name: trimmed(details.name),
      phone: trimmed(details.phone),
      addressLine1: trimmed(details.addressLine1),
      addressLine2: trimmed(details.addressLine2),
      locality: trimmed(details.locality),
      city: trimmed(details.city),
      state: trimmed(details.state),
      pinCode: trimmed(details.pinCode),
    },
  }
}

export function createDemoSubmitController(
  persistOrder: (order: DemoOrder) => boolean | Promise<boolean>,
  clearBag: () => void,
  referenceFactory?: () => string,
): { submit: (summary: BagSummary, details: CheckoutDetails) => Promise<DemoOrder>; isSubmitting: () => boolean } {
  let pending: Promise<DemoOrder> | null = null
  let completed = false
  return {
    submit(summary, details) {
      if (pending) return pending
      if (completed) return Promise.reject(new Error('This demo order has already been submitted.'))
      let order: DemoOrder
      try {
        order = createDemoOrder(summary, details, referenceFactory)
      } catch (error) {
        return Promise.reject(error)
      }
      pending = Promise.resolve()
        .then(() => persistOrder(order))
        .then((persisted) => {
          if (persisted !== true) throw new Error('Could not save this demo order. Your bag is still here.')
          completed = true
          clearBag()
          return order
        })
        .finally(() => { pending = null })
      return pending
    },
    isSubmitting: () => pending !== null,
  }
}
