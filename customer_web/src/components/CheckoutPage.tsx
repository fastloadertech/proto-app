import { useRef, useState, type FormEvent } from 'react'
import { Icon } from './Icon.tsx'
import { ProductVisual } from './ProductVisual.tsx'
import { formatPrice } from '../lib/formatPrice.ts'
import {
  validateCheckoutDetails,
  type BagSummary,
  type CheckoutDetails,
  type CheckoutErrors,
} from '../lib/checkout.ts'

type Props = {
  summary: BagSummary
  submitting: boolean
  submitError: string
  onBack: () => void
  onPlace: (details: CheckoutDetails) => Promise<void> | void
}

const initialDetails: CheckoutDetails = {
  name: '',
  phone: '',
  addressLine1: '',
  addressLine2: '',
  locality: '',
  city: '',
  state: '',
  pinCode: '',
}

const fieldOrder: (keyof CheckoutDetails)[] = [
  'name', 'phone', 'addressLine1', 'addressLine2',
  'locality', 'city', 'state', 'pinCode',
]
const fieldMaxLength: Record<keyof CheckoutDetails, number> = {
  name: 100, phone: 10, addressLine1: 160, addressLine2: 160,
  locality: 100, city: 100, state: 100, pinCode: 6,
}

export function CheckoutPage({ summary, submitting, submitError, onBack, onPlace }: Props) {
  const [details, setDetails] = useState<CheckoutDetails>(initialDetails)
  const [errors, setErrors] = useState<CheckoutErrors>({})
  const [validated, setValidated] = useState(false)
  const [localSubmitError, setLocalSubmitError] = useState('')
  const inputRefs = useRef<Partial<Record<keyof CheckoutDetails, HTMLInputElement | null>>>({})
  const canPlace = summary.error === null && summary.lines.length > 0 && summary.count > 0 && summary.currency !== null

  function money(minor: number): string {
    return summary.currency ? formatPrice((minor / 100).toFixed(2), summary.currency) : '—'
  }

  function updateField(key: keyof CheckoutDetails, value: string) {
    const next = { ...details, [key]: value }
    setDetails(next)
    if (validated) setErrors(validateCheckoutDetails(next))
    setLocalSubmitError('')
  }

  async function handleSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault()
    if (!canPlace || submitting) return

    const nextErrors = validateCheckoutDetails(details)
    setValidated(true)
    setErrors(nextErrors)
    const firstInvalid = fieldOrder.find((field) => nextErrors[field])
    if (firstInvalid) {
      inputRefs.current[firstInvalid]?.focus()
      return
    }

    setLocalSubmitError('')
    try {
      await onPlace(details)
    } catch {
      setLocalSubmitError('Could not place the demo order. Please try again.')
    }
  }

  function field(
    key: keyof CheckoutDetails,
    label: string,
    autoComplete: string,
    options: { optional?: boolean; type?: 'text' | 'tel'; inputMode?: 'text' | 'tel' | 'numeric'; full?: boolean } = {},
  ) {
    const error = errors[key]
    const id = `checkout-${key}`
    return <div className={`checkout-field${options.full ? ' checkout-field-full' : ''}`} key={key}>
      <label htmlFor={id}>{label}{options.optional && <span> (optional)</span>}</label>
      <input
        ref={(element) => { inputRefs.current[key] = element }}
        id={id}
        name={key}
        type={options.type ?? 'text'}
        inputMode={options.inputMode}
        autoComplete={autoComplete}
        maxLength={fieldMaxLength[key]}
        value={details[key]}
        onChange={(event) => updateField(key, event.target.value)}
        aria-invalid={error ? true : undefined}
        aria-describedby={error ? `${id}-error` : undefined}
        required={!options.optional}
        disabled={submitting}
      />
      {error && <span className="checkout-field-error" id={`${id}-error`}>{error}</span>}
    </div>
  }

  const visibleSubmitError = submitError || localSubmitError

  return <section className="page-wrap checkout-page" aria-labelledby="checkout-title">
    <div className="checkout-top">
      <button className="checkout-back" type="button" onClick={onBack} disabled={submitting}>
        <Icon name="back" size={20} /> Back to bag
      </button>
      <span className="checkout-mode">LOCAL DEMO</span>
    </div>

    <header className="checkout-heading">
      <p className="eyebrow">ONE STEP CLOSER.</p>
      <h1 id="checkout-title">Ready for your next level.</h1>
      <p>Review your items and enter a sample delivery address to place a local demo order.</p>
    </header>

    <div className="checkout-demo-note">
      <Icon name="bolt" size={20} />
      <p><strong>Demo checkout.</strong> No payment is collected and no delivery is arranged.</p>
    </div>

    <div className="checkout-layout">
      <form className="checkout-form" onSubmit={handleSubmit} noValidate aria-busy={submitting}>
        <section className="checkout-section" aria-labelledby="checkout-contact-title">
          <div className="checkout-section-title"><span>01</span><h2 id="checkout-contact-title">Your details</h2></div>
          <p>How should this demo order be addressed?</p>
          <div className="checkout-fields">
            {field('name', 'Full name', 'name')}
            {field('phone', 'Mobile number', 'tel', { type: 'tel', inputMode: 'tel' })}
          </div>
        </section>

        <section className="checkout-section" aria-labelledby="checkout-address-title">
          <div className="checkout-section-title"><span>02</span><h2 id="checkout-address-title">Delivery address</h2></div>
          <p>This address stays in the local demo order.</p>
          <div className="checkout-fields">
            {field('addressLine1', 'Address line 1', 'address-line1', { full: true })}
            {field('addressLine2', 'Address line 2', 'address-line2', { optional: true, full: true })}
            {field('locality', 'Locality', 'address-level3')}
            {field('city', 'City', 'address-level2')}
            {field('state', 'State', 'address-level1')}
            {field('pinCode', 'PIN code', 'postal-code', { inputMode: 'numeric' })}
          </div>
        </section>

        <div className="checkout-submit-area">
          {visibleSubmitError && <p className="checkout-submit-error" role="alert">{visibleSubmitError}</p>}
          <div className="checkout-submit-status" role="status" aria-live="polite">
            {submitting ? 'Placing your local demo order…' : ''}
          </div>
          <button className="checkout-place-button" type="submit" disabled={!canPlace || submitting}>
            {submitting ? 'Placing demo order…' : 'Place demo order'}
            {!submitting && <Icon name="arrow" size={19} />}
          </button>
          <p className="checkout-submit-caption">Demo item total only. Delivery charge is not quoted.</p>
        </div>
      </form>

      <aside className="checkout-summary" aria-labelledby="checkout-summary-title">
        <div className="checkout-section-title"><span>03</span><h2 id="checkout-summary-title">Your demo order</h2></div>
        <p className="checkout-summary-count">{summary.count} {summary.count === 1 ? 'item' : 'items'} in your bag</p>
        {summary.error && <p className="checkout-summary-error" role="alert">{summary.error}</p>}
        {!summary.error && summary.lines.length === 0 && <p className="checkout-summary-empty">Your bag is empty. Go back to add items before checkout.</p>}
        {summary.lines.length > 0 && <ul className="checkout-lines">
          {summary.lines.map((line) => <li className="checkout-line" key={line.product.id}>
            <ProductVisual imageUrl={line.product.imageUrl} name={line.product.name} className="checkout-line-art" />
            <div className="checkout-line-copy">
              <strong>{line.product.name}</strong>
              <span>{line.product.weightLabel ?? line.product.category.name}</span>
              <span>Quantity {line.quantity}</span>
            </div>
            <strong className="checkout-line-price">{money(line.lineMinor)}</strong>
          </li>)}
        </ul>}
        <div className="checkout-totals">
          <div><span>Items subtotal</span><strong>{money(summary.subtotalMinor)}</strong></div>
          <div><span>Delivery charge</span><span>Not quoted for demo</span></div>
          <div className="checkout-demo-total"><span>Demo item total</span><strong>{money(summary.subtotalMinor)}</strong></div>
        </div>
        <p className="checkout-summary-note">This total covers items only. No payment or delivery service is included.</p>
      </aside>
    </div>
  </section>
}
