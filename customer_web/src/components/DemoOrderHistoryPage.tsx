import { Icon } from './Icon.tsx'
import { formatPrice } from '../lib/formatPrice.ts'
import type { DemoOrderHistoryEntry } from '../lib/orderHistory.ts'

type Props = {
  orders: DemoOrderHistoryEntry[]
  onBack: () => void
  onShop: () => void
}

export function DemoOrderHistoryPage({ orders, onBack, onShop }: Props) {
  return <div className="page-wrap simple-page order-page" aria-labelledby="orders-title">
    <div className="page-top"><button className="back-button" type="button" onClick={onBack} aria-label="Back to your profile"><Icon name="back" size={24} /></button></div>
    <p className="eyebrow">LOCAL DEMO RECORDS</p><h1 id="orders-title">Demo orders</h1>
    <p className="page-description">These are browser-only previews. They are not connected to fulfilment, payment, or delivery tracking. Contact and street address details are not saved in this history.</p>
    {orders.length ? <div className="order-history-list">{orders.map((order) => <article className="order-panel order-history-card" key={order.reference}>
      <div className="order-panel-header"><div><p className="eyebrow">DEMO REFERENCE</p><h2>{order.reference}</h2></div><span className="demo-status">Demo only</span></div>
      <p className="order-date">{new Date(order.createdAt).toLocaleString('en-IN', { dateStyle: 'medium', timeStyle: 'short' })} · {order.delivery.city}, {order.delivery.state} {order.delivery.pinCode}</p>
      <ul className="order-items">{order.items.map((item) => <li key={item.productId}><span><strong>{item.name}</strong><small>Qty {item.quantity}</small></span><strong>{formatPrice((item.lineMinor / 100).toFixed(2), order.currency)}</strong></li>)}</ul>
      <div className="order-total"><span>Demo item total</span><strong>{formatPrice((order.subtotalMinor / 100).toFixed(2), order.currency)}</strong></div>
    </article>)}</div> : <div className="state-panel"><Icon name="bag" size={38} /><h2>No demo orders yet.</h2><p>A local order preview will appear here after checkout when browser storage is available.</p><button className="primary-button" type="button" onClick={onShop}>Explore products <Icon name="arrow" size={18} /></button></div>}
  </div>
}
