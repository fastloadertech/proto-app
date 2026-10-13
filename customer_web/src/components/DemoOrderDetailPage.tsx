import { useState } from 'react'
import { Icon } from './Icon.tsx'
import { formatPrice } from '../lib/formatPrice.ts'
import { DEMO_DELIVERY_FEE_MINOR, demoOrderTotalMinor } from '../lib/checkout.ts'
import {
  DEMO_SIMULATION_STAGES,
  demoSimulationStageLabel,
  type DemoOrderHistoryEntry,
} from '../lib/orderHistory.ts'

type Props = {
  order: DemoOrderHistoryEntry | null
  reference: string
  onBack: () => void
  onShop: () => void
  onAdvance: (reference: string) => string | null
  persistenceNotice?: string
}

export function DemoOrderDetailPage({ order, reference, onBack, onShop, onAdvance, persistenceNotice }: Props) {
  const [feedback, setFeedback] = useState('')

  if (!order) return <div className="page-wrap simple-page order-page" aria-labelledby="order-detail-title">
    <div className="page-top"><button className="back-button" type="button" onClick={onBack} aria-label="Back to demo orders"><Icon name="back" size={24} /></button></div>
    <p className="eyebrow">LOCAL DEMO RECORDS</p><h1 id="order-detail-title">Demo order unavailable</h1>
    <div className="state-panel" role="status"><h2>We could not find that reference.</h2><p>The demo order may have been cleared or this browser may not have saved it. No real order was affected.</p>
      <button className="primary-button" type="button" onClick={onBack}>View demo orders <Icon name="arrow" size={18} /></button>
      <button className="secondary-button" type="button" onClick={onShop}>Continue shopping</button>
    </div>
  </div>

  const stageIndex = DEMO_SIMULATION_STAGES.indexOf(order.simulationStage)
  const nextStage = DEMO_SIMULATION_STAGES[stageIndex + 1]
  const money = (minor: number) => formatPrice((minor / 100).toFixed(2), order.currency)

  function advance() {
    const error = onAdvance(reference)
    setFeedback(error ?? 'Demo progress advanced in this browser only.')
  }

  return <div className="page-wrap simple-page order-page order-detail-page" aria-labelledby="order-detail-title">
    <div className="page-top"><button className="back-button" type="button" onClick={onBack} aria-label="Back to demo orders"><Icon name="back" size={24} /></button></div>
    <p className="eyebrow">LOCAL DEMO RECORD</p><h1 id="order-detail-title">Demo order details</h1>
    <p className="page-description"><strong>DEMO ORDER — NO PAYMENT COLLECTED.</strong> This is a local preview. Status changes below are simulations started by you; no real delivery is scheduled or tracked.</p>
    {persistenceNotice && <p className="order-storage-warning" role="status">{persistenceNotice}</p>}
    <section className="order-panel" aria-labelledby="order-detail-reference">
      <div className="order-panel-header"><div><p className="eyebrow">DEMO REFERENCE</p><h2 id="order-detail-reference">{order.reference}</h2></div><span className="demo-status">Simulated: {demoSimulationStageLabel(order.simulationStage)}</span></div>
      <p className="order-date">Created {new Date(order.createdAt).toLocaleString('en-IN', { dateStyle: 'medium', timeStyle: 'short' })}</p>
      <h3>Saved item snapshot</h3>
      <ul className="order-items">{order.items.map((item) => <li key={item.productId}><span><strong>{item.name}</strong><small>{item.weightLabel ? `${item.weightLabel} · ` : ''}Qty {item.quantity} × {money(item.unitMinor)}</small></span><strong>{money(item.lineMinor)}</strong></li>)}</ul>
      <div className="order-breakdown"><div><span>Item subtotal</span><span>{money(order.subtotalMinor)}</span></div><div><span>Demo delivery fee</span><span>{money(DEMO_DELIVERY_FEE_MINOR)}</span></div></div>
      <div className="order-total"><span>Demo total · no payment</span><strong>{money(demoOrderTotalMinor(order.subtotalMinor))}</strong></div>
      <p className="order-fee-note">The ₹0 delivery fee is a demo setting, not a live delivery quote. No payment is requested.</p>
      <h3>Saved delivery area</h3>
      <address className="order-address">{order.delivery.city}, {order.delivery.state} {order.delivery.pinCode}</address>
      <p className="order-fee-note">For privacy, contact and street address details are not retained in demo order history.</p>
    </section>
    <section className="order-panel demo-timeline" aria-labelledby="demo-timeline-title">
      <h2 id="demo-timeline-title">Simulated delivery timeline</h2>
      <p>Use the button to advance this local preview one stage at a time. These labels do not reflect a real order, driver or delivery.</p>
      <ol className="demo-timeline-list">{DEMO_SIMULATION_STAGES.map((stage, index) => <li key={stage} className={index < stageIndex ? 'is-complete' : index === stageIndex ? 'is-current' : ''} aria-current={index === stageIndex ? 'step' : undefined}>
        <span className="demo-timeline-marker" aria-hidden="true">{index < stageIndex ? <Icon name="check" size={16} /> : index + 1}</span>
        <span>{demoSimulationStageLabel(stage)}{index === stageIndex && <small> · current demo stage</small>}</span>
      </li>)}</ol>
      {nextStage ? <button className="primary-button" type="button" onClick={advance}>Simulate next step: {demoSimulationStageLabel(nextStage)} <Icon name="arrow" size={18} /></button>
        : <p className="demo-timeline-complete">Simulation complete. No actual delivery took place.</p>}
      {feedback && <p className={feedback.startsWith('Demo progress advanced') ? 'demo-timeline-feedback' : 'demo-timeline-feedback is-error'} role={feedback.startsWith('Demo progress advanced') ? 'status' : 'alert'}>{feedback}</p>}
    </section>
    <div className="order-actions"><button className="secondary-button" type="button" onClick={onBack}>Back to demo orders</button><button className="secondary-button" type="button" onClick={onShop}>Continue shopping</button></div>
  </div>
}
