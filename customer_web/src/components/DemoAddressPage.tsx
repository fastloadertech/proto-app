import { useEffect, useRef, useState, type FormEvent } from 'react'
import { validateCheckoutDetails, type CheckoutDetails, type CheckoutErrors } from '../lib/checkout.ts'
import {
  MAX_DEMO_ADDRESSES,
  addDemoAddress,
  emptyDemoAddressBook,
  removeDemoAddress,
  selectDemoAddress,
  updateDemoAddress,
  type DemoAddressBook,
} from '../lib/demoAddresses.ts'
import { Icon } from './Icon.tsx'

type Props = {
  book: DemoAddressBook
  persisted: boolean
  onBookChange: (next: DemoAddressBook) => void
  onBack: () => void
  onUseAtCheckout?: (id: string) => void
}

const blankAddress: CheckoutDetails = {
  name: '', phone: '', addressLine1: '', addressLine2: '',
  locality: '', city: '', state: '', pinCode: '',
}

const fieldOrder: (keyof CheckoutDetails)[] = [
  'name', 'phone', 'addressLine1', 'addressLine2', 'locality', 'city', 'state', 'pinCode',
]

const maxLength: Record<keyof CheckoutDetails, number> = {
  name: 100, phone: 10, addressLine1: 160, addressLine2: 160,
  locality: 100, city: 100, state: 100, pinCode: 6,
}

export function DemoAddressPage({ book, persisted, onBookChange, onBack, onUseAtCheckout }: Props) {
  const [formOpen, setFormOpen] = useState(false)
  const [editingId, setEditingId] = useState<string | null>(null)
  const [draft, setDraft] = useState<CheckoutDetails>(blankAddress)
  const [errors, setErrors] = useState<CheckoutErrors>({})
  const [validated, setValidated] = useState(false)
  const [notice, setNotice] = useState('')
  const [confirmClear, setConfirmClear] = useState(false)
  const inputRefs = useRef<Partial<Record<keyof CheckoutDetails, HTMLInputElement | null>>>({})

  useEffect(() => {
    if (formOpen) inputRefs.current.name?.focus()
  }, [formOpen, editingId])

  function changeBook(next: DemoAddressBook, message: string): boolean {
    try {
      onBookChange(next)
      setNotice(message)
      setConfirmClear(false)
      return true
    } catch (cause) {
      setNotice(cause instanceof Error ? cause.message : 'Could not update demo addresses.')
      return false
    }
  }

  function startNew() {
    setEditingId(null)
    setDraft({ ...blankAddress })
    setErrors({})
    setValidated(false)
    setNotice('')
    setFormOpen(true)
  }

  function startEdit(id: string) {
    const address = book.addresses.find((item) => item.id === id)
    if (!address) {
      setNotice('That demo address is no longer available.')
      return
    }
    setEditingId(id)
    setDraft({
      name: address.name, phone: address.phone, addressLine1: address.addressLine1,
      addressLine2: address.addressLine2, locality: address.locality,
      city: address.city, state: address.state, pinCode: address.pinCode,
    })
    setErrors({})
    setValidated(false)
    setNotice('')
    setFormOpen(true)
  }

  function updateField(key: keyof CheckoutDetails, value: string) {
    const next = { ...draft, [key]: value }
    setDraft(next)
    if (validated) setErrors(validateCheckoutDetails(next))
  }

  function save(event: FormEvent<HTMLFormElement>) {
    event.preventDefault()
    const nextErrors = validateCheckoutDetails(draft)
    setValidated(true)
    setErrors(nextErrors)
    const firstInvalid = fieldOrder.find((field) => nextErrors[field])
    if (firstInvalid) {
      inputRefs.current[firstInvalid]?.focus()
      return
    }
    try {
      const next = editingId
        ? updateDemoAddress(book, editingId, draft)
        : addDemoAddress(book, draft)
      if (changeBook(next, editingId ? 'Demo address updated.' : 'Demo address added and selected.')) {
        setFormOpen(false)
        setEditingId(null)
      }
    } catch (cause) {
      setNotice(cause instanceof Error ? cause.message : 'Could not save the demo address.')
    }
  }

  function field(
    key: keyof CheckoutDetails,
    label: string,
    autoComplete: string,
    options: { optional?: boolean; full?: boolean; type?: 'text' | 'tel'; inputMode?: 'tel' | 'numeric' } = {},
  ) {
    const id = `demo-address-${key}`
    const error = errors[key]
    return <div className={`checkout-field${options.full ? ' checkout-field-full' : ''}`} key={key}>
      <label htmlFor={id}>{label}{options.optional && <span> (optional)</span>}</label>
      <input id={id} name={key} ref={(element) => { inputRefs.current[key] = element }}
        value={draft[key]} onChange={(event) => updateField(key, event.target.value)}
        type={options.type ?? 'text'} inputMode={options.inputMode} autoComplete={autoComplete}
        maxLength={maxLength[key]} required={!options.optional}
        aria-invalid={error ? true : undefined} aria-describedby={error ? `${id}-error` : undefined} />
      {error && <span className="checkout-field-error" id={`${id}-error`}>{error}</span>}
    </div>
  }

  return <section className="page-wrap simple-page demo-address-page" aria-labelledby="demo-address-title">
    <div className="page-top"><button className="back-button" type="button" onClick={onBack} aria-label="Back from demo addresses"><Icon name="back" size={24} /></button></div>
    <p className="eyebrow">LOCAL DEMO</p>
    <h1 id="demo-address-title">Delivery addresses</h1>
    <p className="page-description">Choose a saved sample address for demo checkout. This does not check delivery coverage or arrange a delivery.</p>
    <div className="demo-address-privacy" role="note">
      Saved demo addresses include the recipient name, phone and street details in this browser's storage. Anyone using this browser can view them. Use sample details and delete them when finished.
    </div>
    {!persisted && <p className="demo-address-storage-warning" role="status">Browser storage is unavailable. Addresses work for this session but will not survive a refresh.</p>}
    {notice && <p className="demo-address-notice" role="status" aria-live="polite">{notice}</p>}

    <div className="demo-address-toolbar">
      <h2>Saved addresses ({book.addresses.length}/{MAX_DEMO_ADDRESSES})</h2>
      {!formOpen && book.addresses.length < MAX_DEMO_ADDRESSES && <button className="primary-button" type="button" onClick={startNew}>Add demo address</button>}
    </div>

    {book.addresses.length ? <div className="demo-address-list" role="radiogroup" aria-label="Select a demo address">
      {book.addresses.map((address) => <article className="demo-address-card" key={address.id}>
        <label className="demo-address-select" htmlFor={`choose-${address.id}`}>
          <input id={`choose-${address.id}`} type="radio" name="selected-demo-address" checked={book.selectedId === address.id}
            onChange={() => { try { changeBook(selectDemoAddress(book, address.id), 'Demo address selected.') } catch (cause) { setNotice(cause instanceof Error ? cause.message : 'Could not select the demo address.') } }} />
          <strong>{address.name}</strong>
          {book.selectedId === address.id && <span>Selected</span>}
        </label>
        <address>{address.addressLine1}<br />{address.addressLine2 && <>{address.addressLine2}<br /></>}{address.locality}<br />{address.city}, {address.state} {address.pinCode}<br />{address.phone}</address>
        <div className="demo-address-card-actions">
          <button className="secondary-button" type="button" onClick={() => startEdit(address.id)}>Edit</button>
          <button className="secondary-button" type="button" onClick={() => {
            try { changeBook(removeDemoAddress(book, address.id), 'Demo address deleted.') }
            catch (cause) { setNotice(cause instanceof Error ? cause.message : 'Could not delete the demo address.') }
            if (editingId === address.id) setFormOpen(false)
          }}>Delete</button>
        </div>
      </article>)}
    </div> : <div className="state-panel demo-address-empty"><h2>No demo addresses saved.</h2><p>Add a sample address to select it during demo checkout.</p></div>}

    {formOpen && <form className="demo-address-form" onSubmit={save} noValidate aria-labelledby="demo-address-form-title">
      <h2 id="demo-address-form-title">{editingId ? 'Edit demo address' : 'Add demo address'}</h2>
      <p>Saving is optional. The details entered directly at checkout are not automatically added here.</p>
      <div className="checkout-fields">
        {field('name', 'Recipient name', 'name')}
        {field('phone', 'Mobile number', 'tel', { type: 'tel', inputMode: 'tel' })}
        {field('addressLine1', 'Address line 1', 'address-line1', { full: true })}
        {field('addressLine2', 'Address line 2', 'address-line2', { optional: true, full: true })}
        {field('locality', 'Locality', 'address-level3')}
        {field('city', 'City', 'address-level2')}
        {field('state', 'State', 'address-level1')}
        {field('pinCode', 'PIN code', 'postal-code', { inputMode: 'numeric' })}
      </div>
      <div className="demo-address-form-actions">
        <button className="secondary-button" type="button" onClick={() => { setFormOpen(false); setEditingId(null) }}>Cancel</button>
        <button className="primary-button" type="submit">{editingId ? 'Save changes' : 'Save demo address'}</button>
      </div>
    </form>}

    {book.addresses.length > 0 && <div className="demo-address-footer">
      {onUseAtCheckout && <button className="primary-button" type="button" disabled={!book.selectedId || formOpen}
        onClick={() => { if (book.selectedId) onUseAtCheckout(book.selectedId) }}>Use selected address in checkout</button>}
      {!confirmClear ? <button className="secondary-button" type="button" onClick={() => setConfirmClear(true)}>Clear saved addresses</button>
        : <div className="demo-address-clear-confirm" role="group" aria-label="Confirm clearing demo addresses">
          <p>Delete every saved demo address from this browser?</p>
          <button className="secondary-button" type="button" onClick={() => setConfirmClear(false)}>Keep addresses</button>
          <button className="secondary-button" type="button" onClick={() => {
            if (changeBook(emptyDemoAddressBook(), 'All saved demo addresses cleared.')) {
              setFormOpen(false)
              setEditingId(null)
            }
          }}>Delete all addresses</button>
        </div>}
    </div>}
  </section>
}
