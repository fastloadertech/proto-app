import { Icon } from './Icon.tsx'
import { formatPrice } from '../lib/formatPrice.ts'
import type { DemoOrder } from '../lib/checkout.ts'

type Props = {
  order: DemoOrder
  historySaved: boolean
  onShop: () => void
  onOrders: () => void
}

export function OrderConfirmationPage({ order, historySaved, onShop, onOrders }: Props) {
  const total = formatPrice((order.subtotalMinor / 100).toFixed(2), order.currency)

  return <div className="page-wrap simple-page order-page" aria-labelledby="confirmation-title">
    <p className="eyebrow">LOCAL DEMO CHECKOUT</p>
    <div className="order-success-icon" aria-hidden="true"><Icon name="check" size={30} /></div>
    <h1 id="confirmation-title">Demo order created</h1>
    <p className="page-description" role="status">Your local preview is complete. No real order was sent, no payment was taken, and no delivery has been scheduled.</p>
    {!historySaved && <p className="order-storage-warning" role="status">Browser storage is unavailable. This demo order is available only until you refresh the page.</p>}
    <section className="order-panel" aria-labelledby="confirmation-summary-title">
      <div className="order-panel-header"><div><p className="eyebrow">YOUR REFERENCE</p><h2 id="confirmation-summary-title">{order.reference}</h2></div><span className="demo-status">Demo only · no delivery scheduled</span></div>
      <p className="order-date">Created {new Date(order.createdAt).toLocaleString('en-IN', { dateStyle: 'medium', timeStyle: 'short' })}</p>
      <h3>Items</h3>
      <ul className="order-items">{order.items.map((item) => <li key={item.productId}><span><strong>{item.name}</strong><small>{item.weightLabel ? `${item.weightLabel} · ` : ''}Qty {item.quantity} × {formatPrice((item.unitMinor / 100).toFixed(2), order.currency)}</small></span><strong>{formatPrice((item.lineMinor / 100).toFixed(2), order.currency)}</strong></li>)}</ul>
      <div className="order-total"><span>Demo item total</span><strong>{total}</strong></div>
      <p className="order-fee-note">Delivery charge is not quoted in this demo. This amount covers items only and is not a payment request.</p>
      <h3>Address entered</h3>
      <address className="order-address">{order.delivery.name}<br />{order.delivery.addressLine1}<br />{order.delivery.addressLine2 && <>{order.delivery.addressLine2}<br /></>}{order.delivery.locality && <>{order.delivery.locality}<br /></>}{order.delivery.city}, {order.delivery.state} {order.delivery.pinCode}<br />{order.delivery.phone}</address>
    </section>
    <div className="order-actions"><button className="primary-button" type="button" onClick={onShop}>Return to storefront <Icon name="arrow" size={18} /></button><button className="secondary-button" type="button" onClick={onOrders}>View demo orders</button></div>
  </div>
}
