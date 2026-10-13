import { Icon } from './Icon.tsx'
import { formatPrice } from '../lib/formatPrice.ts'
import { DEMO_DELIVERY_FEE_MINOR, demoOrderTotalMinor } from '../lib/checkout.ts'
import { demoSimulationStageLabel, type DemoOrderHistoryEntry } from '../lib/orderHistory.ts'

type Props = {
  orders: DemoOrderHistoryEntry[]
  onBack: () => void
  onShop: () => void
  onOpen: (reference: string) => void
}

export function DemoOrderHistoryPage({ orders, onBack, onShop, onOpen }: Props) {
  return <div className="page-wrap simple-page order-page" aria-labelledby="orders-title">
    <div className="page-top"><button className="back-button" type="button" onClick={onBack} aria-label="Back to your profile"><Icon name="back" size={24} /></button></div>
    <p className="eyebrow">LOCAL DEMO RECORDS</p><h1 id="orders-title">Demo orders</h1>
    <p className="page-description">These are browser-only previews. Any progress shown here is manually simulated; no payment, fulfilment or delivery is connected. Contact and street address details are not saved in this history.</p>
    {orders.length ? <div className="order-history-list">{orders.map((order) => <article className="order-panel order-history-card" key={order.reference}>
      <div className="order-panel-header"><div><p className="eyebrow">DEMO REFERENCE</p><h2>{order.reference}</h2></div><span className="demo-status">Simulated: {demoSimulationStageLabel(order.simulationStage)}</span></div>
      <p className="order-date">{new Date(order.createdAt).toLocaleString('en-IN', { dateStyle: 'medium', timeStyle: 'short' })} · {order.delivery.city}, {order.delivery.state} {order.delivery.pinCode}</p>
      <ul className="order-items">{order.items.map((item) => <li key={item.productId}><span><strong>{item.name}</strong><small>Qty {item.quantity}</small></span><strong>{formatPrice((item.lineMinor / 100).toFixed(2), order.currency)}</strong></li>)}</ul>
      <div className="order-breakdown"><div><span>Item subtotal</span><span>{formatPrice((order.subtotalMinor / 100).toFixed(2), order.currency)}</span></div><div><span>Demo delivery fee</span><span>{formatPrice((DEMO_DELIVERY_FEE_MINOR / 100).toFixed(2), order.currency)}</span></div></div>
      <div className="order-total"><span>Demo total · no payment</span><strong>{formatPrice((demoOrderTotalMinor(order.subtotalMinor) / 100).toFixed(2), order.currency)}</strong></div>
      <button className="secondary-button order-view-details" type="button" onClick={() => onOpen(order.reference)} aria-label={`View details for demo order ${order.reference}`}>View details <Icon name="arrow" size={18} /></button>
    </article>)}</div> : <div className="state-panel"><Icon name="bag" size={38} /><h2>No demo orders yet.</h2><p>A local order preview will appear here after checkout when browser storage is available.</p><button className="primary-button" type="button" onClick={onShop}>Explore products <Icon name="arrow" size={18} /></button></div>}
  </div>
}
