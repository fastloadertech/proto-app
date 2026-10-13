import { useEffect, useMemo, useRef, useState } from 'react'
import { configuredCatalogMode, loadCatalog, type CatalogMode } from './api/catalog.ts'
import { Icon } from './components/Icon.tsx'
import { ProductCard } from './components/ProductCard.tsx'
import { ProductDetailDialog } from './components/ProductDetailDialog.tsx'
import { ProductVisual } from './components/ProductVisual.tsx'
import { CheckoutPage, type CheckoutStep } from './components/CheckoutPage.tsx'
import { AdminDashboard } from './components/AdminDashboard.tsx'
import { DemoOrderHistoryPage } from './components/DemoOrderHistoryPage.tsx'
import { DemoOrderDetailPage } from './components/DemoOrderDetailPage.tsx'
import { DemoAccountPage } from './components/DemoAccountPage.tsx'
import { DemoAddressPage } from './components/DemoAddressPage.tsx'
import { OrderConfirmationPage } from './components/OrderConfirmationPage.tsx'
import { filterProducts, type SortOption } from './lib/catalogFilters.ts'
import { bagCatalogChanges } from './lib/catalogRevalidation.ts'
import { calculateBag, createDemoSubmitController, setBagQuantity, type CheckoutDetails, type DemoOrder } from './lib/checkout.ts'
import { readAdminInventory, updateInventoryItem, writeAdminInventory, type InventoryEdits } from './lib/adminInventory.ts'
import { formatPrice } from './lib/formatPrice.ts'
import { demoRouteHash, readDemoRoute, type DemoView } from './lib/demoNavigation.ts'
import { advanceDemoSimulation, appendDemoOrder, readDemoOrders, updateDemoOrderStatus, writeDemoOrders, type DemoOrderHistoryEntry, type DemoOrderStatus } from './lib/orderHistory.ts'
import { emptyDemoAddressBook, readDemoAddressBook, selectDemoAddress, writeDemoAddressBook, type DemoAddressBook } from './lib/demoAddresses.ts'
import { bagForCatalog, getBrowserStorage, readBag, readFavorites, withoutCatalogBag, writeBag, writeFavorites } from './lib/persistence.ts'
import type { Catalog, Product } from './types/catalog.ts'

type View = DemoView
type PrimaryTab = 'home' | 'categories' | 'bag' | 'you'
type LoadState = 'loading' | 'ready' | 'error'
const locations = ['Indiranagar, Bengaluru', 'Koramangala, Bengaluru', 'HSR Layout, Bengaluru']
const emptyCheckoutDetails: CheckoutDetails = {
  name: '', phone: '', addressLine1: '', addressLine2: '', locality: '', city: '', state: '', pinCode: '',
}

function App() {
  const storage = useMemo(() => getBrowserStorage(), [])
  const initialRoute = useMemo(() => readDemoRoute(typeof window === 'undefined' ? '' : window.location.hash), [])
  const [view, setView] = useState<View>(() => initialRoute.view === 'checkout' ? 'bag' : initialRoute.view === 'confirmation' ? 'orders' : initialRoute.view)
  const [catalog, setCatalog] = useState<Catalog | null>(null)
  const [loadState, setLoadState] = useState<LoadState>('loading')
  const [error, setError] = useState('')
  const [reload, setReload] = useState(0)
  const [catalogChanges, setCatalogChanges] = useState<string[]>([])
  const [query, setQuery] = useState('')
  const [categorySlug, setCategorySlug] = useState<string | null>(null)
  const [availableOnly, setAvailableOnly] = useState(false)
  const [sort, setSort] = useState<SortOption>('featured')
  const [filtersOpen, setFiltersOpen] = useState(false)
  const [selectedProduct, setSelectedProduct] = useState<Product | null>(null)
  const selectedProductRef = useRef(selectedProduct)
  selectedProductRef.current = selectedProduct
  const [productNotice, setProductNotice] = useState('')
  const [quantities, setQuantities] = useState<Record<string, number>>(() => readBag(storage))
  const quantitiesRef = useRef(quantities)
  quantitiesRef.current = quantities
  const [favorites, setFavorites] = useState<string[]>(() => readFavorites(storage))
  const [demoDisplayName, setDemoDisplayName] = useState('')
  const [addressBook, setAddressBook] = useState<DemoAddressBook>(() => readDemoAddressBook(storage))
  const [addressBookPersisted, setAddressBookPersisted] = useState(true)
  const [addressReturn, setAddressReturn] = useState<'checkout' | 'you'>('you')
  const [checkoutDetails, setCheckoutDetails] = useState<CheckoutDetails>(emptyCheckoutDetails)
  const [checkoutStep, setCheckoutStep] = useState<CheckoutStep>('contact')
  const [checkoutSelectedAddressId, setCheckoutSelectedAddressId] = useState<string | null>(null)
  const [demoOrders, setDemoOrders] = useState<DemoOrderHistoryEntry[]>(() => readDemoOrders(storage))
  const [selectedOrderReference, setSelectedOrderReference] = useState(initialRoute.reference)
  const demoOrdersRef = useRef(demoOrders)
  const [inventoryEdits, setInventoryEdits] = useState<InventoryEdits>(() => readAdminInventory(storage))
  const inventoryEditsRef = useRef(inventoryEdits)
  const [inventoryPersisted, setInventoryPersisted] = useState(true)
  const [ordersPersisted, setOrdersPersisted] = useState(true)
  const [confirmedOrder, setConfirmedOrder] = useState<DemoOrder | null>(null)
  const [historySaved, setHistorySaved] = useState(true)
  const [submitting, setSubmitting] = useState(false)
  const [submitError, setSubmitError] = useState('')
  const submitControllerRef = useRef<ReturnType<typeof createDemoSubmitController> | null>(null)
  const [location, setLocation] = useState(locations[0])
  const [locationOpen, setLocationOpen] = useState(false)
  const searchRef = useRef<HTMLInputElement>(null)
  const locationButtonRef = useRef<HTMLButtonElement>(null)
  const mainRef = useRef<HTMLElement>(null)
  const firstViewRef = useRef(true)
  const catalogRef = useRef<Catalog | null>(null)
  const requestIdRef = useRef(0)

  let mode: CatalogMode = 'demo'
  let configurationError = ''
  try { mode = configuredCatalogMode() }
  catch (cause) { configurationError = cause instanceof Error ? cause.message : 'Invalid catalog configuration.' }

  useEffect(() => {
    const requestId = ++requestIdRef.current
    if (configurationError) { catalogRef.current = null; setCatalog(null); setError(configurationError); setLoadState('error'); return }
    const controller = new AbortController()
    loadCatalog(mode, controller.signal)
      .then((result) => {
        if (controller.signal.aborted || requestId !== requestIdRef.current) return
        const previouslySelected = selectedProductRef.current
        const refreshedProduct = previouslySelected ? result.products.find((product) => product.id === previouslySelected.id) ?? null : null
        setSelectedProduct(refreshedProduct)
        if (previouslySelected && !refreshedProduct) setProductNotice(`${previouslySelected.name} is no longer in this catalogue.`)
        setCatalogChanges(mode === 'live' ? bagCatalogChanges(catalogRef.current, result, quantitiesRef.current) : [])
        catalogRef.current = result
        setCatalog(result); setError(''); setLoadState('ready')
      })
      .catch((cause: unknown) => {
        if (controller.signal.aborted || requestId !== requestIdRef.current) return
        setCatalog(null)
        if (selectedProductRef.current) setProductNotice('Product details are unavailable while the catalogue cannot load.')
        setSelectedProduct(null)
        setError(cause instanceof Error ? cause.message : 'Could not load the catalog.')
        setLoadState('error')
      })
    return () => controller.abort()
  }, [mode, reload, configurationError])

  useEffect(() => { writeBag(storage, quantities) }, [storage, quantities])
  useEffect(() => { writeFavorites(storage, favorites) }, [storage, favorites])
  useEffect(() => {
    function handleLocationChange() {
      const route = readDemoRoute(window.location.hash)
      setSelectedOrderReference(route.reference)
      setView(route.view === 'checkout' && !submitControllerRef.current ? 'bag' : route.view === 'confirmation' && !confirmedOrder ? 'orders' : route.view)
      setLocationOpen(false)
      window.scrollTo(0, 0)
    }
    window.addEventListener('popstate', handleLocationChange)
    window.addEventListener('hashchange', handleLocationChange)
    return () => { window.removeEventListener('popstate', handleLocationChange); window.removeEventListener('hashchange', handleLocationChange) }
  }, [confirmedOrder])
  useEffect(() => {
    if (firstViewRef.current) { firstViewRef.current = false; return }
    mainRef.current?.focus({ preventScroll: true })
  }, [view])

  const products = useMemo(() => filterProducts(catalog?.products ?? [], {
    query, categorySlug, availableOnly, sort,
  }), [catalog, query, categorySlug, availableOnly, sort])
  const catalogProductIds = useMemo(() => (catalog?.products ?? []).map((product) => product.id), [catalog])
  const currentBag = useMemo(() => bagForCatalog(quantities, catalogProductIds), [quantities, catalogProductIds])
  const hiddenSavedCount = Object.keys(quantities).length - Object.keys(currentBag).length
  const bagSummary = useMemo(() => calculateBag(catalog?.products ?? [], currentBag), [catalog, currentBag])
  const bagProducts = (catalog?.products ?? []).filter((product) => (quantities[product.id] ?? 0) > 0)
  const bagCount = bagProducts.reduce((total, product) => total + quantities[product.id], 0)
  const catalogEmpty = loadState === 'ready' && catalog?.products.length === 0
  const savedProducts = (catalog?.products ?? []).filter((product) => favorites.includes(product.id))
  const hiddenFavoriteCount = favorites.length - savedProducts.length
  const activeCategory = catalog?.categories.find((category) => category.slug === categorySlug)
  const proteinCategory = catalog?.categories.find((category) => /protein/i.test(category.name))
  const hydrationCategory = catalog?.categories.find((category) => /hydration/i.test(category.name))
  const heroProduct = catalog?.products.find((product) => product.category.slug === proteinCategory?.slug) ?? catalog?.products[0]
  const hydrationProduct = catalog?.products.find((product) => product.category.slug === hydrationCategory?.slug)
  const selectedOrder = demoOrders.find((order) => order.reference === selectedOrderReference) ?? null

  function navigate(next: View, reference = selectedOrderReference) {
    setView(next)
    setLocationOpen(false)
    const hash = demoRouteHash(next, reference)
    if (window.location.hash !== hash) window.history.pushState(null, '', hash)
    window.scrollTo(0, 0)
  }
  function isActiveTab(tab: PrimaryTab) {
    return view === tab || (view === 'shop' && tab === 'home') ||
      ((view === 'checkout' || view === 'confirmation' || (view === 'addresses' && addressReturn === 'checkout')) && tab === 'bag') ||
      ((view === 'orders' || view === 'order-detail' || (view === 'addresses' && addressReturn === 'you')) && tab === 'you')
  }
  function openShop(slug: string | null = null, focusSearch = false, showFilters = false) {
    setCategorySlug(slug)
    setFiltersOpen(showFilters)
    navigate('shop')
    if (focusSearch) window.setTimeout(() => searchRef.current?.focus(), 40)
  }
  function clearFilters() { setQuery(''); setCategorySlug(null); setAvailableOnly(false); setSort('featured') }
  function changeQuantity(product: Product, next: number) {
    setCatalogChanges([])
    setQuantities((current) => setBagQuantity(current, product.id, next))
  }
  function clearCurrentBag() {
    setCatalogChanges([])
    setQuantities((current) => withoutCatalogBag(current, catalogProductIds))
  }
  function beginCheckout() {
    if (!bagSummary.lines.length || bagSummary.error) return
    setSubmitError('')
    setCheckoutStep('contact')
    if (demoDisplayName) setCheckoutDetails((current) => current.name ? current : { ...current, name: demoDisplayName })
    submitControllerRef.current = createDemoSubmitController((order) => {
      const next = appendDemoOrder(demoOrdersRef.current, order)
      const saved = writeDemoOrders(storage, next)
      setHistorySaved(saved)
      setOrdersPersisted(saved)
      if (saved) {
        demoOrdersRef.current = next
        setDemoOrders(next)
      }
      return saved
    }, clearCurrentBag)
    navigate('checkout')
  }
  async function placeDemoOrder(details: CheckoutDetails) {
    if (!submitControllerRef.current) return
    setSubmitting(true)
    setSubmitError('')
    try {
      const order = await submitControllerRef.current.submit(bagSummary, details)
      submitControllerRef.current = null
      setConfirmedOrder(order)
      setCheckoutDetails(emptyCheckoutDetails)
      setCheckoutSelectedAddressId(null)
      setCheckoutStep('contact')
      navigate('confirmation')
    } catch (cause) {
      setSubmitError(cause instanceof Error ? cause.message : 'Could not create the demo order. Please try again.')
    } finally {
      setSubmitting(false)
    }
  }
  function saveInventory(product: Product, priceInput: string, stockInput: string): string | null {
    if (mode !== 'demo') return 'Backend inventory editing is unavailable. This catalogue is read only.'
    try {
      const next = updateInventoryItem(inventoryEditsRef.current, product, priceInput, stockInput)
      inventoryEditsRef.current = next
      setInventoryEdits(next)
      setInventoryPersisted(writeAdminInventory(storage, next))
      return null
    } catch (cause) {
      return cause instanceof Error ? cause.message : 'Could not update the demo inventory item.'
    }
  }
  function changeDemoOrderStatus(reference: string, status: DemoOrderStatus): string | null {
    try {
      const next = updateDemoOrderStatus(demoOrdersRef.current, reference, status)
      demoOrdersRef.current = next
      setDemoOrders(next)
      const saved = writeDemoOrders(storage, next)
      setOrdersPersisted(saved)
      setHistorySaved(saved)
      return null
    } catch (cause) {
      return cause instanceof Error ? cause.message : 'Could not update the demo order status.'
    }
  }
  function advanceDemoOrder(reference: string): string | null {
    try {
      const next = advanceDemoSimulation(demoOrdersRef.current, reference)
      const saved = writeDemoOrders(storage, next)
      setOrdersPersisted(saved)
      if (!saved) return 'Could not save the simulated status. Allow browser storage and try again.'
      demoOrdersRef.current = next
      setDemoOrders(next)
      return null
    } catch (cause) {
      return cause instanceof Error ? cause.message : 'Could not advance the simulated status.'
    }
  }
  function openOrderDetail(reference: string) {
    setSelectedOrderReference(reference)
    navigate('order-detail', reference)
  }
  function changeAddressBook(next: DemoAddressBook) {
    const saved = writeDemoAddressBook(storage, next)
    setAddressBook(next)
    setAddressBookPersisted(saved)
    if (checkoutSelectedAddressId && !next.addresses.some((address) => address.id === checkoutSelectedAddressId)) {
      setCheckoutSelectedAddressId(null)
    }
  }
  function chooseAddress(id: string) {
    if (!id) { setCheckoutSelectedAddressId(null); return }
    try {
      const next = selectDemoAddress(addressBook, id)
      changeAddressBook(next)
      const address = next.addresses.find((candidate) => candidate.id === id)
      if (address) {
        setCheckoutDetails(({ name, phone }) => ({ ...address, name: name || address.name, phone: phone || address.phone }))
        setCheckoutSelectedAddressId(id)
      }
    } catch {
      setCheckoutSelectedAddressId(null)
    }
  }
  function updateCheckoutDetails(next: CheckoutDetails) {
    setCheckoutDetails(next)
    const selected = addressBook.addresses.find((address) => address.id === checkoutSelectedAddressId)
    if (selected && (['addressLine1', 'addressLine2', 'locality', 'city', 'state', 'pinCode'] as const).some((key) => selected[key] !== next[key])) {
      setCheckoutSelectedAddressId(null)
    }
  }
  function openAddresses(from: 'checkout' | 'you') {
    setAddressReturn(from)
    navigate('addresses')
  }
  function resetDemoData() {
    setDemoDisplayName('')
    setQuantities({})
    setFavorites([])
    const emptyBook = emptyDemoAddressBook()
    changeAddressBook(emptyBook)
    setCheckoutDetails(emptyCheckoutDetails)
    setCheckoutSelectedAddressId(null)
    setDemoOrders([])
    demoOrdersRef.current = []
    setOrdersPersisted(writeDemoOrders(storage, []))
    setInventoryEdits({})
    inventoryEditsRef.current = {}
    setInventoryPersisted(writeAdminInventory(storage, {}))
    setConfirmedOrder(null)
    navigate('you')
  }
  function toggleFavorite(product: Product) {
    setFavorites((current) => current.includes(product.id)
      ? current.filter((id) => id !== product.id) : [...current, product.id])
  }
  function openProduct(product: Product) { setProductNotice(''); setSelectedProduct(product) }
  function card(product: Product) {
    return <ProductCard key={product.id} product={product} onOpen={openProduct}
      quantity={quantities[product.id] ?? 0} onQuantityChange={changeQuantity}
      favorite={favorites.includes(product.id)} onFavoriteToggle={toggleFavorite} />
  }
  function retry() { requestIdRef.current += 1; setSelectedProduct(null); setCatalogChanges([]); setLoadState('loading'); setReload((count) => count + 1) }
  const catalogState = loadState === 'loading'
    ? <div className="loading-grid" role="status" aria-live="polite"><span className="loading-label">Loading catalog...</span><div className="skeleton" /><div className="skeleton" /><div className="skeleton" /></div>
    : loadState === 'error'
      ? <div className="state-panel" role="alert"><h2>We couldn't load the catalog.</h2><p>{error}</p>{configurationError ? <p>Check the catalog mode setting and reload the page.</p> : <button className="primary-button" type="button" onClick={retry}>Try again <Icon name="arrow" size={18} /></button>}</div>
      : null

  return <div className="app-shell">
    <main className="main-content" id="main-content" ref={mainRef} tabIndex={-1}>
      {productNotice && <div className="page-wrap"><div className="bag-notice" role="status"><p>{productNotice}</p><button className="secondary-button" type="button" onClick={() => setProductNotice('')}>Dismiss</button></div></div>}
      {view === 'home' && <div className="page-wrap home-page">
        <header className="home-header">
          <button className="brand" type="button" onClick={() => navigate('home')} aria-label="Proto home"><Icon name="bolt" size={34} /><span>proto</span><i aria-hidden="true" /></button>
          <span className="header-tagline">PERFORMANCE, ON DEMAND.</span>
          <div className="header-actions"><span className="delivery-badge"><Icon name="bolt" size={17} />SAMPLE</span><button className="icon-button profile-button" type="button" aria-label="Your profile" onClick={() => navigate('you')}><Icon name="user" size={23} /></button></div>
        </header>
        <div className="location-area" onKeyDown={(event) => { if (event.key === 'Escape' && locationOpen) { setLocationOpen(false); locationButtonRef.current?.focus() } }}>
          <button ref={locationButtonRef} type="button" className="location-button" onClick={() => setLocationOpen((open) => !open)} aria-expanded={locationOpen} aria-controls={locationOpen ? 'location-options' : undefined}><Icon name="location" size={20} /><span>Sample area <strong>{location}</strong></span><Icon name="chevron" size={18} /></button>
          {locationOpen && <div className="location-options" id="location-options"><p>Choose a sample location</p>{locations.map((option) => <button key={option} type="button" onClick={() => { setLocation(option); setLocationOpen(false); locationButtonRef.current?.focus() }}><span>{option}</span>{location === option && <Icon name="check" size={18} />}</button>)}</div>}
        </div>
        <div className="home-search-row"><button className="home-search" type="button" onClick={() => openShop(null, true)}><Icon name="search" size={23} /><span>Search protein, creatine, snacks...</span></button><button className="home-filter" type="button" aria-label="Open catalog filters" onClick={() => openShop(null, false, true)}><Icon name="filter" size={22} /></button></div>
        <div className="mode-banner"><Icon name="bolt" size={18} /><span>{configurationError ? 'CATALOG CONFIGURATION ERROR' : mode === 'demo' ? 'LOCAL DEMO · Catalog, bag and checkout are local previews' : 'LIVE CATALOG · Bag and checkout remain local demos'}</span></div>
        <section className="home-intro" aria-labelledby="home-title"><div><p className="eyebrow">BUILT FOR YOUR EVERYDAY</p><h1 id="home-title">Fuel your next level.</h1></div><span>Small habits. Stronger you.</span></section>
        {catalogState}
        {catalogEmpty && <div className="state-panel"><h2>No products are available right now.</h2><p>Check back shortly or try loading the catalog again.</p><button className="primary-button" type="button" onClick={retry}>Try again <Icon name="arrow" size={18} /></button></div>}
        {loadState === 'ready' && !catalogEmpty && <>
          {heroProduct && <div className="hero-row">
            <section className="fuel-hero" aria-labelledby="fuel-hero-title"><div className="hero-ring" aria-hidden="true" /><div className="hero-copy"><p>THE DAILY EDGE</p><h2 id="fuel-hero-title">Good fuel.<br />Great form.</h2><span>Protein that keeps up with you.</span><button className="dark-button" type="button" onClick={() => openShop(proteinCategory?.slug ?? null)}>{proteinCategory ? 'Shop protein' : 'Shop all products'} <Icon name="arrow" size={19} /></button></div><ProductVisual imageUrl={heroProduct.imageUrl} name={heroProduct.name} className="hero-product" eager /></section>
            {hydrationProduct && <section className="hydration-hero" aria-labelledby="hydration-title"><p>SWEAT. RESET. REPEAT.</p><h2 id="hydration-title">Stay<br />in your<br />element.</h2><button className="round-dark-button" type="button" aria-label="Shop hydration" onClick={() => openShop(hydrationCategory?.slug ?? null)}><Icon name="arrow" size={20} /></button><ProductVisual imageUrl={hydrationProduct.imageUrl} name={hydrationProduct.name} className="hydration-product" /></section>}
          </div>}
          <div className="trust-strip"><span><Icon name="bolt" size={15} />Browse essentials</span><span><Icon name="check" size={15} />Save favourites</span><span><Icon name="heart" size={15} />Demo checkout</span></div>
          <section className="home-section" aria-labelledby="categories-heading"><div className="section-title"><h2 id="categories-heading">Find your fuel</h2><button type="button" onClick={() => navigate('categories')}>View all <Icon name="arrow" size={19} /></button></div><div className="category-scroller">{catalog?.categories.map((category) => {
            const artwork = catalog.products.find((product) => product.category.slug === category.slug)
            return <button className="category-shortcut" type="button" key={category.id} onClick={() => openShop(category.slug)}><span className="category-art">{artwork ? <ProductVisual imageUrl={artwork.imageUrl} name={artwork.name} /> : <Icon name="bolt" size={38} />}</span><span>{category.name}</span></button>
          })}</div></section>
          <section className="home-section featured-section" aria-labelledby="featured-heading"><div className="section-title"><div><h2 id="featured-heading">Featured products</h2><p>The good stuff. Ready when you are.</p></div><button type="button" onClick={() => openShop()}>Shop all <Icon name="arrow" size={19} /></button></div><div className="product-grid">{catalog?.products.slice(0, 4).map(card)}</div></section>
        </>}
      </div>}

      {view === 'shop' && <div className="page-wrap listing-page">
        <div className="listing-top"><button className="back-button" type="button" onClick={() => navigate('home')} aria-label="Back to home"><Icon name="back" size={24} /></button><button className="bag-pill" type="button" onClick={() => navigate('bag')}><Icon name="bag" size={21} />{loadState === 'ready' ? bagCount + ' in bag' : 'Bag'}</button></div>
        <p className="eyebrow">GOOD FUEL, ON DEMAND.</p><h1>{activeCategory?.name ?? 'All products'}</h1>
        <div className="listing-search"><Icon name="search" size={23} /><label className="sr-only" htmlFor="product-search">Search products</label><input ref={searchRef} id="product-search" type="search" value={query} onChange={(event) => setQuery(event.target.value)} placeholder="Search protein, snacks & more" autoComplete="off" />{query && <button type="button" aria-label="Clear search" onClick={() => { setQuery(''); searchRef.current?.focus() }}>×</button>}</div>
        {loadState === 'ready' && <div className="category-chips" aria-label="Filter by category"><button type="button" aria-pressed={categorySlug === null} className={categorySlug === null ? 'active' : ''} onClick={() => setCategorySlug(null)}>All products</button>{catalog?.categories.map((category) => <button key={category.id} type="button" aria-pressed={categorySlug === category.slug} className={categorySlug === category.slug ? 'active' : ''} onClick={() => setCategorySlug(category.slug)}>{category.name}</button>)}</div>}
        <div className="listing-controls"><span role="status" aria-live="polite">{loadState === 'ready' ? products.length + (products.length === 1 ? ' essential' : ' essentials') : loadState === 'loading' ? 'Loading essentials' : 'Catalog unavailable'}</span><button type="button" className="filter-button" onClick={() => setFiltersOpen((open) => !open)} aria-expanded={filtersOpen} aria-controls={filtersOpen ? 'filter-options' : undefined}><Icon name="filter" size={18} />Filters</button></div>
        <div className="sort-line"><label htmlFor="sort-products"><Icon name="filter" size={18} /><span className="sr-only">Sort products</span></label><select id="sort-products" value={sort} onChange={(event) => setSort(event.target.value as SortOption)}><option value="featured">Recommended</option><option value="price-asc">Price: low to high</option><option value="price-desc">Price: high to low</option><option value="name-asc">Name: A to Z</option></select></div>
        {filtersOpen && <div className="filter-options" id="filter-options"><label><input type="checkbox" checked={availableOnly} onChange={(event) => setAvailableOnly(event.target.checked)} />Available only</label><button type="button" onClick={clearFilters}>Clear filters</button></div>}
        <div className="listing-mode">{configurationError ? 'Catalog configuration needs attention' : mode === 'demo' ? 'Local demo products · Bag stays in this browser' : 'Live catalog · Bag stays in this browser'}</div>
        {catalogState}
        {catalogEmpty && <div className="state-panel"><h2>No products are available right now.</h2><p>Check back shortly or try loading the catalog again.</p><button className="primary-button" type="button" onClick={retry}>Try again <Icon name="arrow" size={18} /></button></div>}
        {loadState === 'ready' && !catalogEmpty && (products.length ? <div className="product-grid listing-grid">{products.map(card)}</div> : <div className="state-panel"><h2>No products found.</h2><p>Try another search or reset your filters.</p><button className="primary-button" type="button" onClick={clearFilters}>Clear filters</button></div>)}
      </div>}

      {view === 'categories' && <div className="page-wrap simple-page"><div className="page-top"><button className="back-button" type="button" onClick={() => navigate('home')} aria-label="Back to home"><Icon name="back" size={24} /></button></div><p className="eyebrow">FIND YOUR FUEL</p><h1>Categories</h1><p className="page-description">Explore the essentials for your routine.</p>{catalogState}{loadState === 'ready' && (catalog?.categories.length ? <div className="categories-grid">{catalog.categories.map((category) => { const artwork = catalog.products.find((product) => product.category.slug === category.slug); return <button className="category-tile" type="button" key={category.id} onClick={() => openShop(category.slug)}><span className="category-tile-art">{artwork && <ProductVisual imageUrl={artwork.imageUrl} name={artwork.name} />}</span><strong>{category.name}</strong><span>{category.description}</span><Icon name="arrow" size={19} /></button> })}</div> : <div className="state-panel"><h2>No categories are available yet.</h2><p>Try loading the catalog again shortly.</p><button className="primary-button" type="button" onClick={retry}>Try again <Icon name="arrow" size={18} /></button></div>)}</div>}

      {view === 'bag' && <div className="page-wrap simple-page">
        <div className="page-top"><button className="back-button" type="button" onClick={() => navigate('home')} aria-label="Back to home"><Icon name="back" size={24} /></button></div>
        <p className="eyebrow">YOUR EVERYDAY FUEL</p>
        <h1>Bag {loadState === 'ready' && <span className="heading-count">{bagCount}</span>}</h1>
        <p className="page-description">Your bag stays in this browser. Checkout creates a local demo order; no delivery is scheduled.</p>
        {mode === 'live' && loadState === 'ready' && <div className="bag-catalog-controls"><p>Prices and stock shown below come from the latest loaded catalogue. Review them before demo checkout.</p><button type="button" className="secondary-button" onClick={retry}>Refresh prices and stock</button></div>}
        {loadState === 'ready' && catalogChanges.length > 0 && <div className="bag-notice" role="status" aria-live="polite"><strong>Catalogue updates for your bag</strong><ul>{catalogChanges.map((change, index) => <li key={`${index}-${change}`}>{change}</li>)}</ul></div>}
        {loadState === 'ready' && hiddenSavedCount > 0 && <div className="bag-notice" role="status"><strong>{hiddenSavedCount} saved {hiddenSavedCount === 1 ? 'item is' : 'items are'} not shown here.</strong><p>They may belong to another catalogue mode or may no longer be listed. Your saved bag has been preserved in this browser.</p></div>}
        {loadState !== 'ready' ? catalogState : bagProducts.length ? <>
          <section className="bag-list" aria-label="Items in your bag">{bagProducts.map((product) => {
            const line = bagSummary.lines.find((candidate) => candidate.product.id === product.id)
            const quantity = quantities[product.id]
            return <article className="bag-item" key={product.id}>
              <ProductVisual imageUrl={product.imageUrl} name={product.name} />
              <div className="bag-item-info"><strong>{product.name}</strong><span>{product.weightLabel ?? product.category.name}</span><span>Unit price: {formatPrice(product.price, product.currency)}</span>{(!product.available || product.stockQuantity === 0) && <span className="bag-item-warning">Currently unavailable</span>}{product.available && product.stockQuantity != null && product.stockQuantity > 0 && quantity > product.stockQuantity && <span className="bag-item-warning">Only {product.stockQuantity} currently in stock</span>}<button type="button" className="bag-remove" onClick={() => changeQuantity(product, 0)}>Remove item</button></div>
              <div className="bag-item-actions"><div className="quantity-stepper"><button type="button" aria-label={'Remove one ' + product.name} onClick={() => changeQuantity(product, quantity - 1)} disabled={quantity < 1}><Icon name="minus" size={17} /></button><output aria-label={product.name + ' quantity'} aria-live="polite">{quantity}</output><button type="button" aria-label={'Add one ' + product.name} onClick={() => changeQuantity(product, quantity + 1)} disabled={!product.available || quantity >= 99 || (product.stockQuantity != null && quantity >= product.stockQuantity)}><Icon name="plus" size={17} /></button></div><div className="bag-line-total"><span>Line total</span><strong>{line ? formatPrice((line.lineMinor / 100).toFixed(2), product.currency) : '—'}</strong></div></div>
            </article>
          })}</section>
          <div className="bag-summary" role="status" aria-live="polite"><span>Item subtotal</span><strong>{bagSummary.currency ? formatPrice((bagSummary.subtotalMinor / 100).toFixed(2), bagSummary.currency) : '—'}</strong></div>
          {bagSummary.error && <div className="bag-error" role="alert"><p>{bagSummary.error} Update your bag before checkout.</p><button type="button" className="secondary-button" onClick={clearCurrentBag}>Clear bag</button></div>}
          <button type="button" className="primary-button bag-checkout-button" onClick={beginCheckout} disabled={Boolean(bagSummary.error)}>Continue to demo checkout <Icon name="arrow" size={18} /></button>
        </> : <div className="state-panel"><Icon name="bag" size={38} /><h2>{hiddenSavedCount > 0 ? 'No items from this catalogue in your bag.' : 'Your bag is empty.'}</h2><p>Find something that fuels your next day.</p><button type="button" className="primary-button" onClick={() => openShop()}>Explore products <Icon name="arrow" size={18} /></button></div>}
      </div>}

      {view === 'checkout' && <CheckoutPage summary={bagSummary} submitting={submitting} submitError={submitError} details={checkoutDetails} onDetailsChange={updateCheckoutDetails} step={checkoutStep} onStepChange={setCheckoutStep} savedAddresses={addressBook.addresses} selectedAddressId={checkoutSelectedAddressId} onSelectAddress={chooseAddress} onManageAddresses={() => openAddresses('checkout')} onBack={() => navigate('bag')} onPlace={placeDemoOrder} />}

      {view === 'confirmation' && confirmedOrder && <OrderConfirmationPage order={confirmedOrder} historySaved={historySaved} onShop={() => openShop()} onOrders={() => navigate('orders')} onViewDetails={openOrderDetail} />}

      {view === 'orders' && <DemoOrderHistoryPage orders={demoOrders} onBack={() => navigate('you')} onShop={() => openShop()} onOpen={openOrderDetail} />}

      {view === 'order-detail' && <DemoOrderDetailPage order={selectedOrder} reference={selectedOrderReference} onBack={() => navigate('orders')} onShop={() => openShop()} onAdvance={advanceDemoOrder} persistenceNotice={!ordersPersisted ? 'Browser storage is unavailable. Simulated status changes cannot be saved.' : undefined} />}

      {view === 'admin' && <AdminDashboard mode={mode} products={catalog?.products ?? []} orders={demoOrders} inventoryEdits={inventoryEdits} catalogState={loadState} catalogError={error} onRetryCatalog={retry} onSaveInventory={saveInventory} onUpdateOrderStatus={changeDemoOrderStatus} onExit={() => navigate('you')} persistenceNotice={(mode === 'demo' && !inventoryPersisted) || !ordersPersisted ? 'Browser storage is unavailable. Recent demo changes will last only until this page is refreshed.' : ''} />}

      {view === 'addresses' && <DemoAddressPage book={addressBook} persisted={addressBookPersisted} onBookChange={changeAddressBook} onBack={() => navigate(addressReturn)} onUseAtCheckout={addressReturn === 'checkout' ? (id) => { chooseAddress(id); navigate('checkout') } : undefined} />}

      {view === 'you' && <DemoAccountPage displayName={demoDisplayName} addressCount={addressBook.addresses.length} onEnterDemo={setDemoDisplayName} onSignOut={() => setDemoDisplayName('')} onResetDemo={resetDemoData} onAddresses={() => openAddresses('you')} onOrders={() => navigate('orders')} onAdmin={() => navigate('admin')} onBack={() => navigate('home')}><section className="saved-section"><h2>Saved products</h2>{loadState !== 'ready' ? catalogState : <>{hiddenFavoriteCount > 0 && <div className="bag-notice" role="status"><strong>{hiddenFavoriteCount} saved {hiddenFavoriteCount === 1 ? 'product is' : 'products are'} unavailable in this catalogue.</strong><p>These favourites remain saved in this browser for another catalogue mode or a future update.</p></div>}{savedProducts.length ? <div className="product-grid">{savedProducts.map(card)}</div> : <p className="page-description">{catalogEmpty ? 'No products are available to save right now.' : 'Nothing saved yet. Tap the heart on a product to find it here.'}</p>}</>}</section></DemoAccountPage>}
    </main>
    {view !== 'admin' && <nav className="bottom-nav" aria-label="Primary navigation"><div className="bottom-nav-inner">{([{ id: 'home', label: 'Shop', icon: 'home' }, { id: 'categories', label: 'Categories', icon: 'grid' }, { id: 'bag', label: 'Bag', icon: 'bag' }, { id: 'you', label: 'You', icon: 'user' }] as const).map((item) => <button key={item.id} type="button" className={isActiveTab(item.id) ? 'active' : ''} aria-current={isActiveTab(item.id) ? 'page' : undefined} disabled={submitting} onClick={() => navigate(item.id)}><span className="nav-icon"><Icon name={item.icon} size={22} filled={item.id === 'home' && (view === 'home' || view === 'shop')} />{item.id === 'bag' && loadState === 'ready' && bagCount > 0 && <i>{bagCount}</i>}</span><span>{item.label}</span></button>)}</div></nav>}
    <ProductDetailDialog product={selectedProduct} onClose={() => setSelectedProduct(null)} quantity={selectedProduct ? quantities[selectedProduct.id] ?? 0 : 0} onQuantityChange={changeQuantity} favorite={selectedProduct ? favorites.includes(selectedProduct.id) : false} onFavoriteToggle={toggleFavorite} />
  </div>
}

export default App
