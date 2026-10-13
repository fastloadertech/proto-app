import { useState, type FormEvent, type ReactNode } from 'react'
import { Icon } from './Icon.tsx'

type Props = {
  displayName: string | null
  addressCount: number
  onEnterDemo: (name: string) => void
  onSignOut: () => void
  onResetDemo?: () => void
  onAddresses: () => void
  onOrders: () => void
  onAdmin: () => void
  onBack: () => void
  children?: ReactNode
}

function cleanDisplayName(value: string): string | null {
  const name = value.trim()
  return name.length >= 2 && name.length <= 60 && !/[\u0000-\u001f\u007f]/.test(name) ? name : null
}

export function DemoAccountPage({
  displayName, addressCount, onEnterDemo, onSignOut, onAddresses, onOrders, onAdmin, onBack, children,
  onResetDemo,
}: Props) {
  const [nameInput, setNameInput] = useState('')
  const [error, setError] = useState('')
  const [resetPending, setResetPending] = useState(false)

  function enter(event: FormEvent<HTMLFormElement>) {
    event.preventDefault()
    const name = cleanDisplayName(nameInput)
    if (!name) {
      setError('Enter a demo display name between 2 and 60 characters.')
      return
    }
    setError('')
    onEnterDemo(name)
    setNameInput('')
  }

  return <div className="page-wrap simple-page demo-account-page">
    <div className="page-top"><button className="back-button" type="button" onClick={onBack} aria-label="Back to home"><Icon name="back" size={24} /></button></div>
    <p className="eyebrow">YOUR PROTO</p>
    <h1>{displayName ? 'Demo account' : 'Demo sign-in'}</h1>
    <p className="page-description">Explore a sample customer journey in this browser. This is not a real sign-in, account, or identity check.</p>

    <section className="state-panel account-panel demo-account-panel" aria-labelledby="demo-account-title">
      <Icon name="user" size={38} />
      {displayName ? <>
        <h2 id="demo-account-title">Hello, {displayName}.</h2>
        <p>Your demo display name exists only for this page session. No OTP was sent and this does not authenticate you with the backend.</p>
        <button className="secondary-button" type="button" onClick={() => { setNameInput(''); onSignOut() }}>Leave demo account</button>
        <p className="demo-account-privacy">Leaving hides your display name. It does not erase the bag, favourites, demo orders, or addresses saved in this browser.</p>
      </> : <>
        <h2 id="demo-account-title">Enter the local demo.</h2>
        <p>Choose a display name to personalise this sample screen. No phone code, password, or backend session is used.</p>
        <form className="demo-account-form" onSubmit={enter} noValidate>
          <label htmlFor="demo-display-name">Demo display name</label>
          <input id="demo-display-name" name="demo-display-name" autoComplete="off" maxLength={60} value={nameInput}
            onChange={(event) => { setNameInput(event.target.value); setError('') }}
            aria-invalid={error ? true : undefined} aria-describedby={error ? 'demo-display-name-error' : undefined} required />
          {error && <span className="checkout-field-error" id="demo-display-name-error" role="alert">{error}</span>}
          <button className="primary-button" type="submit">Continue in demo <Icon name="arrow" size={18} /></button>
          <button className="secondary-button" type="button" onClick={onBack}>Cancel demo sign-in</button>
        </form>
      </>}
    </section>

    <section className="demo-account-actions" aria-label="Demo account options">
      <div className="demo-account-action">
        <h2>Saved demo addresses</h2>
        <p>{addressCount} {addressCount === 1 ? 'address' : 'addresses'} saved on this browser. Anyone using this browser can view them.</p>
        <button className="secondary-button" type="button" onClick={onAddresses}>Manage demo addresses</button>
      </div>
      <div className="demo-account-action">
        <h2>Demo orders</h2>
        <p>Review local order previews. They are not backend orders or live delivery tracking.</p>
        <button className="secondary-button" type="button" onClick={onOrders}>View demo orders</button>
      </div>
      <div className="demo-account-action">
        <h2>Demo admin</h2>
        <p>Inspect local inventory and order previews.</p>
        <button className="secondary-button" type="button" onClick={onAdmin}>Open demo admin</button>
      </div>
    </section>

    {onResetDemo && <section className="demo-account-reset" aria-labelledby="demo-account-reset-title">
      <h2 id="demo-account-reset-title">Reset the local demo</h2>
      <p>Clear saved demo data from this browser, including your bag, favourites, addresses and order history.</p>
      {resetPending ? <div className="demo-account-reset-confirm" role="group" aria-label="Confirm local demo reset">
        <button className="secondary-button" type="button" onClick={() => setResetPending(false)}>Keep demo data</button>
        <button className="secondary-button" type="button" onClick={() => { setResetPending(false); onResetDemo() }}>Clear local demo data</button>
      </div> : <button className="secondary-button" type="button" onClick={() => setResetPending(true)}>Reset local demo data</button>}
    </section>}
    {children}
  </div>
}
