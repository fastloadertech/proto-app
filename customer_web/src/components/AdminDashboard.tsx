import { useEffect, useId, useMemo, useState } from 'react'
import { Icon } from './Icon.tsx'
import { ProductVisual } from './ProductVisual.tsx'
import { formatPrice } from '../lib/formatPrice.ts'
import type { CatalogMode } from '../api/catalog.ts'
import {
  deriveInventoryRows,
  filterInventoryRows,
  summarizeInventory,
  type InventoryEdits,
  type InventoryRow,
  type InventoryStockStatus,
} from '../lib/adminInventory.ts'
import {
  DEMO_ORDER_STATUSES,
  demoOrderStatusLabel,
  type DemoOrderHistoryEntry,
  type DemoOrderStatus,
} from '../lib/orderHistory.ts'
import type { Product } from '../types/catalog.ts'

type AdminTab = 'dashboard' | 'inventory' | 'orders'
type StockFilter = InventoryStockStatus | 'all'
type OrderStatusFilter = DemoOrderStatus | 'all'

type Props = {
  mode: CatalogMode
  products: Product[]
  orders: DemoOrderHistoryEntry[]
  inventoryEdits: InventoryEdits
  catalogState: 'loading' | 'ready' | 'error'
  catalogError: string
  onRetryCatalog: () => void
  onSaveInventory: (product: Product, priceInput: string, stockInput: string) => string | null
  onUpdateOrderStatus: (reference: string, status: DemoOrderStatus) => string | null
  onExit: () => void
  persistenceNotice: string
}

const stockLabels: Record<InventoryStockStatus, string> = {
  'in-stock': 'In stock',
  'low-stock': 'Low stock',
  'out-of-stock': 'Out of stock',
  unknown: 'Stock untracked',
}

function StockBadge({ status }: { status: InventoryStockStatus }) {
  return <span className={`admin-stock-badge admin-stock-${status}`}>{stockLabels[status]}</span>
}

function InventoryEditor({ row, onSave, mode }: {
  row: InventoryRow
  onSave: Props['onSaveInventory']
  mode: CatalogMode
}) {
  const fieldId = useId()
  const [priceInput, setPriceInput] = useState(row.price)
  const [stockInput, setStockInput] = useState(String(row.stock ?? ''))
  const [message, setMessage] = useState('')
  const [hasError, setHasError] = useState(false)
  const [invalidField, setInvalidField] = useState<'price' | 'stock' | null>(null)

  useEffect(() => {
    setPriceInput(row.price)
    setStockInput(String(row.stock ?? ''))
  }, [row.price, row.stock])

  const dirty = priceInput !== row.price || stockInput !== String(row.stock ?? '')

  return <article className="admin-inventory-row">
    <div className="admin-product-identity">
      <ProductVisual imageUrl={row.product.imageUrl} name={row.product.name} className="admin-product-art" />
      <div className="admin-product-copy">
        <h3>{row.product.name}</h3>
        <p>{row.product.category.name} <span aria-hidden="true">·</span> {row.product.sku}</p>
        <div className="admin-product-badges">
          <StockBadge status={row.stockStatus} />
          <span className={`admin-catalog-badge ${row.catalogAvailable ? '' : 'is-unavailable'}`}>
            Catalog {row.catalogAvailable ? 'available' : 'unavailable'}
          </span>
        </div>
      </div>
    </div>
    {mode === 'live' ? <div className="admin-live-values" aria-label="Read-only backend catalogue values">
      <div><span>Backend price</span><strong>{formatPrice(row.price, row.product.currency)}</strong></div>
      <div><span>Backend stock</span><strong>{row.stock === null ? 'Untracked' : `${row.stock} units`}</strong></div>
      <p>Read only. Inventory updates need an authorized backend API.</p>
    </div> : <form className="admin-inventory-form" onSubmit={(event) => {
      event.preventDefault()
      const error = onSave(row.product, priceInput, stockInput)
      setHasError(Boolean(error))
      setInvalidField(error ? /price/i.test(error) ? 'price' : /stock/i.test(error) ? 'stock' : null : null)
      if (!error) {
        const [whole, fraction = ''] = priceInput.trim().split('.')
        setPriceInput(`${whole}.${fraction.padEnd(2, '0')}`)
        setStockInput(stockInput.trim())
      }
      setMessage(error ?? 'Updated local demo inventory.')
    }}>
      <div className="admin-edit-fields">
        <div className="admin-field">
          <label htmlFor={`${fieldId}-price`}>Demo price ({row.product.currency})</label>
          <input id={`${fieldId}-price`} value={priceInput} onChange={(event) => { setPriceInput(event.target.value); setMessage(''); setInvalidField(null) }} inputMode="decimal" autoComplete="off" aria-invalid={invalidField === 'price'} aria-describedby={`${fieldId}-price-help${invalidField === 'price' ? ` ${fieldId}-feedback` : ''}`} />
          <small id={`${fieldId}-price-help`}>Current: {formatPrice(row.price, row.product.currency)}</small>
        </div>
        <div className="admin-field">
          <label htmlFor={`${fieldId}-stock`}>Demo stock</label>
          <input id={`${fieldId}-stock`} value={stockInput} onChange={(event) => { setStockInput(event.target.value); setMessage(''); setInvalidField(null) }} inputMode="numeric" autoComplete="off" aria-invalid={invalidField === 'stock'} aria-describedby={`${fieldId}-stock-help${invalidField === 'stock' ? ` ${fieldId}-feedback` : ''}`} />
          <small id={`${fieldId}-stock-help`}>Current: {row.stock} units</small>
        </div>
      </div>
      <div className="admin-save-line">
        <button type="submit" disabled={!dirty}>Save changes</button>
        {message && <span id={`${fieldId}-feedback`} className={hasError ? 'admin-feedback is-error' : 'admin-feedback'} role={hasError ? 'alert' : 'status'}>{message}</span>}
      </div>
    </form>}
  </article>
}

function OrderCard({ order, onUpdate }: {
  order: DemoOrderHistoryEntry
  onUpdate: Props['onUpdateOrderStatus']
}) {
  const fieldId = useId()
  const [status, setStatus] = useState<DemoOrderStatus>(order.status)
  const [message, setMessage] = useState('')
  const [hasError, setHasError] = useState(false)

  useEffect(() => setStatus(order.status), [order.status])

  return <article className="admin-order-card">
    <div className="admin-order-heading">
      <div>
        <p className="eyebrow">LOCAL DEMO ORDER</p>
        <h3>{order.reference}</h3>
        <p className="admin-order-meta">{new Date(order.createdAt).toLocaleString('en-IN', { dateStyle: 'medium', timeStyle: 'short' })}</p>
      </div>
      <span className="admin-order-status">{demoOrderStatusLabel(order.status)}</span>
    </div>
    <div className="admin-order-details">
      <div>
        <h4>Items · {order.count} units</h4>
        <ul className="admin-order-items">
          {order.items.map((item) => <li key={item.productId}>
            <span>{item.name} <small>× {item.quantity}</small></span>
            <strong>{formatPrice((item.lineMinor / 100).toFixed(2), order.currency)}</strong>
          </li>)}
        </ul>
      </div>
      <div className="admin-order-aside">
        <h4>Stored delivery area</h4>
        <p>{order.delivery.city}, {order.delivery.state} {order.delivery.pinCode}</p>
        <small>Contact and street address are not stored.</small>
        <div className="admin-order-total"><span>Demo item total</span><strong>{formatPrice((order.subtotalMinor / 100).toFixed(2), order.currency)}</strong></div>
      </div>
    </div>
    <form className="admin-status-form" onSubmit={(event) => {
      event.preventDefault()
      const error = onUpdate(order.reference, status)
      setHasError(Boolean(error))
      setMessage(error ?? 'Demo status saved locally.')
    }}>
      <div className="admin-field">
        <label htmlFor={`${fieldId}-status`}>Demo status</label>
        <select id={`${fieldId}-status`} value={status} onChange={(event) => { setStatus(event.target.value as DemoOrderStatus); setMessage('') }}>
          {DEMO_ORDER_STATUSES.map((item) => <option key={item} value={item}>{demoOrderStatusLabel(item)}</option>)}
        </select>
      </div>
      <button type="submit" disabled={status === order.status}>Save status</button>
      {message && <span className={hasError ? 'admin-feedback is-error' : 'admin-feedback'} role={hasError ? 'alert' : 'status'}>{message}</span>}
    </form>
  </article>
}

export function AdminDashboard({
  mode, products, orders, inventoryEdits, catalogState, catalogError, onRetryCatalog,
  onSaveInventory, onUpdateOrderStatus, onExit, persistenceNotice,
}: Props) {
  const [tab, setTab] = useState<AdminTab>('dashboard')
  const [query, setQuery] = useState('')
  const [categorySlug, setCategorySlug] = useState('all')
  const [stockStatus, setStockStatus] = useState<StockFilter>('all')
  const [orderQuery, setOrderQuery] = useState('')
  const [orderStatus, setOrderStatus] = useState<OrderStatusFilter>('all')

  const rows = useMemo(() => deriveInventoryRows(products, inventoryEdits, mode), [products, inventoryEdits, mode])
  const summary = useMemo(() => summarizeInventory(rows), [rows])
  const filteredRows = useMemo(() => filterInventoryRows(rows, { query, categorySlug, stockStatus }), [rows, query, categorySlug, stockStatus])
  const categories = useMemo(() => [...new Map(products.map((product) => [product.category.slug, product.category])).values()].sort((a, b) => a.name.localeCompare(b.name)), [products])
  const filteredOrders = useMemo(() => orders.filter((order) =>
    order.reference.toLocaleLowerCase().includes(orderQuery.trim().toLocaleLowerCase()) &&
    (orderStatus === 'all' || order.status === orderStatus)
  ), [orders, orderQuery, orderStatus])

  const catalogPanel = catalogState === 'loading'
    ? <div className="admin-state" role="status"><h3>Loading catalogue…</h3><p>Inventory will appear once the product list is ready.</p></div>
    : catalogState === 'error'
      ? <div className="admin-state" role="alert"><h3>Catalogue unavailable</h3><p>{catalogError || 'Products could not be loaded.'}</p><button className="secondary-button" type="button" onClick={onRetryCatalog}>Try again</button></div>
      : null

  return <div className="page-wrap admin-page" aria-labelledby="admin-title">
    <header className="admin-header">
      <div><p className="eyebrow">{mode === 'live' ? 'PROTO · BACKEND CATALOGUE' : 'PROTO · LOCAL DEMO'}</p><h1 id="admin-title">Admin dashboard</h1><p>Review your catalogue and local demo orders.</p></div>
      <button className="admin-exit" type="button" onClick={onExit}><Icon name="back" size={17} /> Back to storefront</button>
    </header>
    <div className="admin-scope-note"><Icon name="check" size={18} /><p>{mode === 'live' ? <><strong>Backend catalogue, read only.</strong> Prices and tracked stock come from the public API. Inventory changes are disabled because there is no authorized write route. Orders and their status labels remain local demos.</> : <><strong>Local demo workspace.</strong> Inventory edits stay in this browser and do not change customer catalogue prices, availability, fulfilment, or payments. Order statuses are demo labels only.</>}</p></div>
    {persistenceNotice && <p className="admin-persistence-note" role="status">{persistenceNotice}</p>}
    <nav className="admin-nav" aria-label="Admin sections">
      <button type="button" className={tab === 'dashboard' ? 'is-active' : ''} aria-current={tab === 'dashboard' ? 'page' : undefined} onClick={() => setTab('dashboard')}>Dashboard</button>
      <button type="button" className={tab === 'inventory' ? 'is-active' : ''} aria-current={tab === 'inventory' ? 'page' : undefined} onClick={() => setTab('inventory')}>Inventory</button>
      <button type="button" className={tab === 'orders' ? 'is-active' : ''} aria-current={tab === 'orders' ? 'page' : undefined} onClick={() => setTab('orders')}>Demo orders <span>{orders.length}</span></button>
    </nav>

    {tab === 'dashboard' && <section className="admin-section" aria-labelledby="admin-overview-title">
      <div className="admin-section-heading"><div><p className="eyebrow">AT A GLANCE</p><h2 id="admin-overview-title">Overview</h2></div><p>{mode === 'live' ? 'Backend catalogue · local demo orders' : 'Local data in this browser'}</p></div>
      <div className="admin-summary-grid">
        <div className="admin-summary-card"><span>Total products</span><strong>{catalogState === 'ready' ? summary.totalProducts : '—'}</strong><small>{mode === 'live' ? 'Public catalogue entries' : 'Catalogue entries'}</small></div>
        <div className="admin-summary-card"><span>In stock</span><strong>{catalogState === 'ready' ? summary.inStockProducts : '—'}</strong><small>{mode === 'live' ? `${summary.unknownStockProducts} untracked · includes low stock` : 'Includes low stock'}</small></div>
        <div className="admin-summary-card"><span>Low stock</span><strong>{catalogState === 'ready' ? summary.lowStockProducts : '—'}</strong><small>{mode === 'live' ? 'Tracked stock: 1–5 units' : 'Review these products'}</small></div>
        <div className="admin-summary-card"><span>Demo orders</span><strong>{orders.length}</strong><small>Saved local records</small></div>
      </div>
      {catalogPanel}
      <div className="admin-overview-panels">
        <section className="admin-overview-card" aria-labelledby="admin-stock-overview"><div className="admin-overview-title"><h3 id="admin-stock-overview">Inventory status</h3><button type="button" onClick={() => setTab('inventory')}>View inventory <Icon name="arrow" size={16} /></button></div><p><strong>{catalogState === 'ready' ? summary.outOfStockProducts : '—'}</strong> out of stock {mode === 'live' ? 'in tracked backend stock' : 'in the demo inventory'}</p><p>{mode === 'live' ? `${summary.unknownStockProducts} products have untracked stock. Availability comes from the backend.` : 'Catalogue availability is shown separately from local demo stock.'}</p></section>
        <section className="admin-overview-card" aria-labelledby="admin-orders-overview"><div className="admin-overview-title"><h3 id="admin-orders-overview">Recent demo orders</h3><button type="button" onClick={() => setTab('orders')}>View all <Icon name="arrow" size={16} /></button></div>{orders.length ? <ul className="admin-recent-orders">{orders.slice(0, 3).map((order) => <li key={order.reference}><span>{order.reference}<small>{demoOrderStatusLabel(order.status)}</small></span><strong>{formatPrice((order.subtotalMinor / 100).toFixed(2), order.currency)}</strong></li>)}</ul> : <p>No demo orders saved yet.</p>}</section>
      </div>
    </section>}

    {tab === 'inventory' && <section className="admin-section" aria-labelledby="admin-inventory-title">
      <div className="admin-section-heading"><div><p className="eyebrow">{mode === 'live' ? 'BACKEND CATALOGUE' : 'PRODUCT MANAGEMENT'}</p><h2 id="admin-inventory-title">Inventory</h2></div><p>{mode === 'live' ? 'Backend price and stock · read only' : 'Price and stock edits are local demo values'}</p></div>
      {catalogPanel || <>
        <div className="admin-filters">
          <div className="admin-field admin-search-field"><label htmlFor="admin-product-search">Search products</label><input id="admin-product-search" type="search" value={query} onChange={(event) => setQuery(event.target.value)} placeholder="Search by name" /></div>
          <div className="admin-field"><label htmlFor="admin-category-filter">Category</label><select id="admin-category-filter" value={categorySlug} onChange={(event) => setCategorySlug(event.target.value)}><option value="all">All categories</option>{categories.map((category) => <option value={category.slug} key={category.slug}>{category.name}</option>)}</select></div>
          <div className="admin-field"><label htmlFor="admin-stock-filter">Stock status</label><select id="admin-stock-filter" value={stockStatus} onChange={(event) => setStockStatus(event.target.value as StockFilter)}><option value="all">All stock</option><option value="in-stock">In stock</option><option value="low-stock">Low stock</option><option value="out-of-stock">Out of stock</option>{mode === 'live' && <option value="unknown">Untracked stock</option>}</select></div>
        </div>
        <p className="admin-results-count" role="status">Showing {filteredRows.length} of {rows.length} products</p>
        {filteredRows.length ? <div className="admin-inventory-list">{filteredRows.map((row) => <InventoryEditor key={row.product.id} row={row} mode={mode} onSave={onSaveInventory} />)}</div> : <div className="admin-state"><h3>{rows.length ? 'No matching products' : 'No products in the catalogue'}</h3><p>{rows.length ? 'Try another name, category, or stock status.' : 'Products will appear here when the catalogue has entries.'}</p>{rows.length > 0 && <button className="secondary-button" type="button" onClick={() => { setQuery(''); setCategorySlug('all'); setStockStatus('all') }}>Clear filters</button>}</div>}
      </>}
    </section>}

    {tab === 'orders' && <section className="admin-section" aria-labelledby="admin-orders-title">
      <div className="admin-section-heading"><div><p className="eyebrow">BROWSER-ONLY RECORDS</p><h2 id="admin-orders-title">Demo orders</h2></div><p>Status changes do not start fulfilment</p></div>
      <div className="admin-filters admin-order-filters">
        <div className="admin-field admin-search-field"><label htmlFor="admin-order-search">Search by reference</label><input id="admin-order-search" type="search" value={orderQuery} onChange={(event) => setOrderQuery(event.target.value)} placeholder="Enter demo reference" /></div>
        <div className="admin-field"><label htmlFor="admin-order-status-filter">Demo status</label><select id="admin-order-status-filter" value={orderStatus} onChange={(event) => setOrderStatus(event.target.value as OrderStatusFilter)}><option value="all">All statuses</option>{DEMO_ORDER_STATUSES.map((status) => <option key={status} value={status}>{demoOrderStatusLabel(status)}</option>)}</select></div>
      </div>
      <p className="admin-results-count" role="status">Showing {filteredOrders.length} of {orders.length} demo orders</p>
      {filteredOrders.length ? <div className="admin-order-list">{filteredOrders.map((order) => <OrderCard key={order.reference} order={order} onUpdate={onUpdateOrderStatus} />)}</div> : <div className="admin-state"><h3>{orders.length ? 'No matching orders' : 'No demo orders yet'}</h3><p>{orders.length ? 'Try another reference or status.' : 'Local order previews appear here after checkout in this browser.'}</p>{orders.length && <button className="secondary-button" type="button" onClick={() => { setOrderQuery(''); setOrderStatus('all') }}>Clear filters</button>}</div>}
    </section>}
  </div>
}
