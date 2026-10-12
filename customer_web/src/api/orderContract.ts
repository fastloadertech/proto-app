/**
 * Read-only boundary for the shared backend's OrdersService responses.
 * These parsers do not authenticate, submit, or enable live ordering.
 */

const ORDER_STATUSES = [
  'PENDING', 'PLACED', 'CONFIRMED', 'PREPARING', 'READY_FOR_PICKUP',
  'PICKED_UP', 'OUT_FOR_DELIVERY', 'DELIVERED', 'CANCELLED',
] as const

const DELIVERY_STATUSES = [
  'OUT_FOR_DELIVERY', 'REQUESTED', 'AVAILABLE', 'ARRIVED_AT_PICKUP',
  'ON_THE_WAY', 'ACCEPTED', 'DRIVER_ASSIGNED', 'DRIVER_ARRIVING',
  'PICKED_UP', 'IN_TRANSIT', 'DELIVERED', 'CANCELLED',
] as const

export type OrderStatus = typeof ORDER_STATUSES[number]
export type DeliveryStatus = typeof DELIVERY_STATUSES[number]

export type OrderAddressResponse = {
  line1: string
  line2: string | null
  city: string
  state: string | null
  postalCode: string | null
  recipientName: string | null
  phone: string | null
}

export type OrderItemResponse = {
  id: string
  productId: string
  productName: string
  unitPrice: string
  quantity: number
  lineTotal: string
}

export type OrderResponse = {
  id: string
  reference: string
  status: OrderStatus
  subtotal: string
  deliveryFee: string
  total: string
  currency: string
  deliveryAddress: OrderAddressResponse | null
  items: OrderItemResponse[]
  createdAt: string
  updatedAt: string
}

export type OrderDetailResponse = OrderResponse & {
  delivery: { id: string; status: DeliveryStatus } | null
}

const UUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i
const DECIMAL = /^(?:0|[1-9]\d{0,9})\.\d{2}$/

function invalid(): never {
  throw new Error('The order API returned an unexpected response.')
}

function record(value: unknown): Record<string, unknown> {
  if (value === null || typeof value !== 'object' || Array.isArray(value)) return invalid()
  return value as Record<string, unknown>
}

function uuid(value: unknown): string {
  return typeof value === 'string' && UUID.test(value) ? value : invalid()
}

function text(value: unknown): string {
  return typeof value === 'string' && value.trim().length > 0 ? value : invalid()
}

function money(value: unknown): string {
  return typeof value === 'string' && DECIMAL.test(value) ? value : invalid()
}

function minor(value: string): bigint {
  const [whole, fraction] = value.split('.')
  return BigInt(whole) * 100n + BigInt(fraction)
}

function timestamp(value: unknown): string {
  if (typeof value !== 'string') return invalid()
  const parsed = new Date(value)
  return Number.isFinite(parsed.getTime()) && parsed.toISOString() === value ? value : invalid()
}

function nullableText(value: unknown): string | null {
  return value === null || value === undefined ? null : typeof value === 'string' ? value : invalid()
}

function address(value: unknown): OrderAddressResponse | null {
  if (value === null) return null
  const item = record(value)
  return {
    line1: text(item.line1),
    line2: nullableText(item.line2),
    city: text(item.city),
    state: nullableText(item.state),
    postalCode: nullableText(item.postalCode),
    recipientName: nullableText(item.recipientName),
    phone: nullableText(item.phone),
  }
}

function orderItem(value: unknown): OrderItemResponse {
  const item = record(value)
  const quantity = item.quantity
  if (!Number.isSafeInteger(quantity) || (quantity as number) < 1 || (quantity as number) > 99) return invalid()
  const unitPrice = money(item.unitPrice)
  const lineTotal = money(item.lineTotal)
  if (minor(unitPrice) * BigInt(quantity as number) !== minor(lineTotal)) return invalid()
  return {
    id: uuid(item.id),
    productId: uuid(item.productId),
    productName: text(item.productName),
    unitPrice,
    quantity: quantity as number,
    lineTotal,
  }
}

/** Parses POST /orders and GET /orders entries without trusting raw JSON as an order. */
export function parseOrderResponse(value: unknown): OrderResponse {
  const item = record(value)
  if (!ORDER_STATUSES.some((status) => status === item.status) ||
      !Array.isArray(item.items) || typeof item.currency !== 'string' ||
      !/^[A-Z]{3}$/.test(item.currency)) return invalid()
  const items = item.items.map(orderItem)
  const subtotal = money(item.subtotal)
  const deliveryFee = money(item.deliveryFee)
  const total = money(item.total)
  if (minor(subtotal) + minor(deliveryFee) !== minor(total) ||
      items.reduce((sum, line) => sum + minor(line.lineTotal), 0n) !== minor(subtotal)) return invalid()
  return {
    id: uuid(item.id),
    reference: text(item.reference),
    status: item.status as OrderStatus,
    subtotal,
    deliveryFee,
    total,
    currency: item.currency,
    deliveryAddress: address(item.deliveryAddress),
    items,
    createdAt: timestamp(item.createdAt),
    updatedAt: timestamp(item.updatedAt),
  }
}

/** Parses the customer-scoped GET /orders array. */
export function parseOrderListResponse(value: unknown): OrderResponse[] {
  return Array.isArray(value) ? value.map(parseOrderResponse) : invalid()
}

/** GET /orders/:id adds a nullable linked Loader delivery job. */
export function parseOrderDetailResponse(value: unknown): OrderDetailResponse {
  const item = record(value)
  const order = parseOrderResponse(item)
  if (item.delivery === null) return { ...order, delivery: null }
  const delivery = record(item.delivery)
  if (!DELIVERY_STATUSES.some((status) => status === delivery.status)) return invalid()
  return {
    ...order,
    delivery: { id: uuid(delivery.id), status: delivery.status as DeliveryStatus },
  }
}
