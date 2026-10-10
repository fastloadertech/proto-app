import { useEffect, useMemo, useRef, useState } from 'react'
import { configuredCatalogMode, loadCatalog, type CatalogMode } from './api/catalog.ts'
import { Icon } from './components/Icon.tsx'
import { ProductCard } from './components/ProductCard.tsx'
import { ProductDetailDialog } from './components/ProductDetailDialog.tsx'
import { ProductVisual } from './components/ProductVisual.tsx'
import { filterProducts, type SortOption } from './lib/catalogFilters.ts'
import { formatPrice } from './lib/formatPrice.ts'
import type { Catalog, Product } from './types/catalog.ts'

type View = 'home' | 'shop' | 'categories' | 'bag' | 'you'
type LoadState = 'loading' | 'ready' | 'error'
const locations = ['Indiranagar, Bengaluru', 'Koramangala, Bengaluru', 'HSR Layout, Bengaluru']

function App() {
  const [view, setView] = useState<View>('home')
  const [catalog, setCatalog] = useState<Catalog | null>(null)
  const [loadState, setLoadState] = useState<LoadState>('loading')
  const [error, setError] = useState('')
  const [reload, setReload] = useState(0)
  const [query, setQuery] = useState('')
  const [categorySlug, setCategorySlug] = useState<string | null>(null)
  const [availableOnly, setAvailableOnly] = useState(false)
  const [sort, setSort] = useState<SortOption>('featured')
  const [filtersOpen, setFiltersOpen] = useState(false)
  const [selectedProduct, setSelectedProduct] = useState<Product | null>(null)
  const [quantities, setQuantities] = useState<Record<string, number>>({})
  const [favorites, setFavorites] = useState<string[]>([])
  const [location, setLocation] = useState(locations[0])
  const [locationOpen, setLocationOpen] = useState(false)
  const searchRef = useRef<HTMLInputElement>(null)

  let mode: CatalogMode = 'demo'
  let configurationError = ''
  try { mode = configuredCatalogMode() }
  catch (cause) { configurationError = cause instanceof Error ? cause.message : 'Invalid catalog configuration.' }

  useEffect(() => {
    if (configurationError) { setError(configurationError); setLoadState('error'); return }
    const controller = new AbortController()
    loadCatalog(mode, controller.signal)
      .then((result) => {
        if (controller.signal.aborted) return
        setCatalog(result); setError(''); setLoadState('ready')
      })
      .catch((cause: unknown) => {
        if (controller.signal.aborted) return
        setError(cause instanceof Error ? cause.message : 'Could not load the catalog.')
        setLoadState('error')
      })
    return () => controller.abort()
  }, [mode, reload, configurationError])

  const products = useMemo(() => filterProducts(catalog?.products ?? [], {
    query, categorySlug, availableOnly, sort,
  }), [catalog, query, categorySlug, availableOnly, sort])
  const bagProducts = (catalog?.products ?? []).filter((product) => (quantities[product.id] ?? 0) > 0)
  const bagCount = Object.values(quantities).reduce((total, value) => total + value, 0)
  const bagTotal = bagProducts.reduce((total, product) => total + Number(product.price) * quantities[product.id], 0)
  const activeCategory = catalog?.categories.find((category) => category.slug === categorySlug)
  const proteinCategory = catalog?.categories.find((category) => /protein/i.test(category.name))
  const hydrationCategory = catalog?.categories.find((category) => /hydration/i.test(category.name))
  const heroProduct = catalog?.products.find((product) => product.category.slug === proteinCategory?.slug) ?? catalog?.products[0]
  const hydrationProduct = catalog?.products.find((product) => product.category.slug === hydrationCategory?.slug)

  function navigate(next: View) {
    setView(next)
    setLocationOpen(false)
    window.scrollTo(0, 0)
  }
  function openShop(slug: string | null = null, focusSearch = false, showFilters = false) {
    setCategorySlug(slug)
    setFiltersOpen(showFilters)
    navigate('shop')
    if (focusSearch) window.setTimeout(() => searchRef.current?.focus(), 40)
  }
  function clearFilters() { setQuery(''); setCategorySlug(null); setAvailableOnly(false); setSort('featured') }
  function changeQuantity(product: Product, next: number) {
    setQuantities((current) => ({ ...current, [product.id]: Math.max(0, Math.min(99, next)) }))
  }
  function toggleFavorite(product: Product) {
    setFavorites((current) => current.includes(product.id)
      ? current.filter((id) => id !== product.id) : [...current, product.id])
  }
  function card(product: Product) {
    return <ProductCard key={product.id} product={product} onOpen={setSelectedProduct}
      quantity={quantities[product.id] ?? 0} onQuantityChange={changeQuantity}
      favorite={favorites.includes(product.id)} onFavoriteToggle={toggleFavorite} />
  }
  function retry() { setLoadState('loading'); setReload((count) => count + 1) }
  const catalogState = loadState === 'loading'
    ? <div className="loading-grid" aria-label="Loading catalog"><div className="skeleton" /><div className="skeleton" /><div className="skeleton" /></div>
    : loadState === 'error'
      ? <div className="state-panel" role="alert"><h2>We couldn't load the catalog.</h2><p>{error}</p><button className="primary-button" type="button" onClick={retry}>Try again <Icon name="arrow" size={18} /></button></div>
      : null

  return <div className="app-shell">
    <main className="main-content" id="main-content">
      {view === 'home' && <div className="page-wrap home-page">
        <header className="home-header">
          <button className="brand" type="button" onClick={() => navigate('home')} aria-label="Proto home"><Icon name="bolt" size={34} /><span>proto</span><i aria-hidden="true" /></button>
          <span className="header-tagline">PERFORMANCE, ON DEMAND.</span>
          <div className="header-actions"><span className="delivery-badge"><Icon name="bolt" size={17} />12 MIN</span><button className="icon-button profile-button" type="button" aria-label="Your profile" onClick={() => navigate('you')}><Icon name="user" size={23} /></button></div>
        </header>
        <div className="location-area">
          <button type="button" className="location-button" onClick={() => setLocationOpen((open) => !open)} aria-expanded={locationOpen} aria-controls="location-options"><Icon name="location" size={20} /><span>Deliver to <strong>{location}</strong></span><Icon name="chevron" size={18} /></button>
          {locationOpen && <div className="location-options" id="location-options"><p>Choose a sample location</p>{locations.map((option) => <button key={option} type="button" onClick={() => { setLocation(option); setLocationOpen(false) }}><span>{option}</span>{location === option && <Icon name="check" size={18} />}</button>)}</div>}
        </div>
        <div className="home-search-row"><button className="home-search" type="button" onClick={() => openShop(null, true)}><Icon name="search" size={23} /><span>Search protein, creatine, snacks...</span></button><button className="home-filter" type="button" aria-label="Open catalog filters" onClick={() => openShop(null, false, true)}><Icon name="filter" size={22} /></button></div>
        <div className="mode-banner"><Icon name="bolt" size={18} /><span>{mode === 'demo' ? 'LOCAL DEMO · Catalog and bag are local previews' : 'LIVE CATALOG · Bag is local; checkout is not connected'}</span></div>
        <section className="home-intro" aria-labelledby="home-title"><div><p className="eyebrow">BUILT FOR YOUR EVERYDAY</p><h1 id="home-title">Fuel your next level.</h1></div><span>Small habits. Stronger you.</span></section>
        {catalogState}
        {loadState === 'ready' && <>
          {heroProduct && <div className="hero-row">
            <section className="fuel-hero" aria-labelledby="fuel-hero-title"><div className="hero-ring" aria-hidden="true" /><div className="hero-copy"><p>THE DAILY EDGE</p><h2 id="fuel-hero-title">Good fuel.<br />Great form.</h2><span>Protein that keeps up with you.</span><button className="dark-button" type="button" onClick={() => openShop(proteinCategory?.slug ?? null)}>Shop protein <Icon name="arrow" size={19} /></button></div><ProductVisual imageUrl={heroProduct.imageUrl} name={heroProduct.name} className="hero-product" eager /></section>
            {hydrationProduct && <section className="hydration-hero" aria-labelledby="hydration-title"><p>SWEAT. RESET. REPEAT.</p><h2 id="hydration-title">Stay<br />in your<br />element.</h2><button className="round-dark-button" type="button" aria-label="Shop hydration" onClick={() => openShop(hydrationCategory?.slug ?? null)}><Icon name="arrow" size={20} /></button><ProductVisual imageUrl={hydrationProduct.imageUrl} name={hydrationProduct.name} className="hydration-product" /></section>}
          </div>}
          <div className="trust-strip"><span><Icon name="bolt" size={15} />Fast delivery</span><span><Icon name="check" size={15} />Curated quality</span><span><Icon name="heart" size={15} />Goal approved</span></div>
          <section className="home-section" aria-labelledby="categories-heading"><div className="section-title"><h2 id="categories-heading">Find your fuel</h2><button type="button" onClick={() => navigate('categories')}>View all <Icon name="arrow" size={19} /></button></div><div className="category-scroller">{catalog?.categories.map((category) => {
            const artwork = catalog.products.find((product) => product.category.slug === category.slug)
            return <button className="category-shortcut" type="button" key={category.id} onClick={() => openShop(category.slug)}><span className="category-art">{artwork ? <ProductVisual imageUrl={artwork.imageUrl} name={artwork.name} /> : <Icon name="bolt" size={38} />}</span><span>{category.name}</span></button>
          })}</div></section>
          <section className="home-section featured-section" aria-labelledby="featured-heading"><div className="section-title"><div><h2 id="featured-heading">Featured products</h2><p>The good stuff. Ready when you are.</p></div><button type="button" onClick={() => openShop()}>Shop all <Icon name="arrow" size={19} /></button></div><div className="product-grid">{catalog?.products.slice(0, 4).map(card)}</div></section>
        </>}
      </div>}

      {view === 'shop' && <div className="page-wrap listing-page">
        <div className="listing-top"><button className="back-button" type="button" onClick={() => navigate('home')} aria-label="Back to home"><Icon name="back" size={24} /></button><button className="bag-pill" type="button" onClick={() => navigate('bag')}><Icon name="bag" size={21} />{bagCount} in bag</button></div>
        <p className="eyebrow">GOOD FUEL, ON DEMAND.</p><h1>{activeCategory?.name ?? 'All products'}</h1>
        <div className="listing-search"><Icon name="search" size={23} /><label className="sr-only" htmlFor="product-search">Search products</label><input ref={searchRef} id="product-search" type="search" value={query} onChange={(event) => setQuery(event.target.value)} placeholder="Search protein, snacks & more" autoComplete="off" />{query && <button type="button" aria-label="Clear search" onClick={() => { setQuery(''); searchRef.current?.focus() }}>×</button>}</div>
        {loadState === 'ready' && <div className="category-chips" aria-label="Filter by category"><button type="button" aria-pressed={categorySlug === null} className={categorySlug === null ? 'active' : ''} onClick={() => setCategorySlug(null)}>All products</button>{catalog?.categories.map((category) => <button key={category.id} type="button" aria-pressed={categorySlug === category.slug} className={categorySlug === category.slug ? 'active' : ''} onClick={() => setCategorySlug(category.slug)}>{category.name}</button>)}</div>}
        <div className="listing-controls"><span role="status" aria-live="polite">{loadState === 'ready' ? products.length + (products.length === 1 ? ' essential' : ' essentials') : 'Loading essentials'}</span><button type="button" className="filter-button" onClick={() => setFiltersOpen((open) => !open)} aria-expanded={filtersOpen} aria-controls="filter-options"><Icon name="filter" size={18} />Filters</button></div>
        <div className="sort-line"><label htmlFor="sort-products"><Icon name="filter" size={18} /><span className="sr-only">Sort products</span></label><select id="sort-products" value={sort} onChange={(event) => setSort(event.target.value as SortOption)}><option value="featured">Recommended</option><option value="price-asc">Price: low to high</option><option value="price-desc">Price: high to low</option><option value="name-asc">Name: A to Z</option></select></div>
        {filtersOpen && <div className="filter-options" id="filter-options"><label><input type="checkbox" checked={availableOnly} onChange={(event) => setAvailableOnly(event.target.checked)} />Available only</label><button type="button" onClick={clearFilters}>Clear filters</button></div>}
        <div className="listing-mode">{mode === 'demo' ? 'Local demo products · Bag is saved for this visit only' : 'Live catalog · Bag is saved for this visit only'}</div>
        {catalogState}
        {loadState === 'ready' && (products.length ? <div className="product-grid listing-grid">{products.map(card)}</div> : <div className="state-panel"><h2>No products found.</h2><p>Try another search or reset your filters.</p><button className="primary-button" type="button" onClick={clearFilters}>Clear filters</button></div>)}
      </div>}

      {view === 'categories' && <div className="page-wrap simple-page"><div className="page-top"><button className="back-button" type="button" onClick={() => navigate('home')} aria-label="Back to home"><Icon name="back" size={24} /></button></div><p className="eyebrow">FIND YOUR FUEL</p><h1>Categories</h1><p className="page-description">Explore the essentials for your routine.</p>{catalogState}{loadState === 'ready' && <div className="categories-grid">{catalog?.categories.map((category) => { const artwork = catalog.products.find((product) => product.category.slug === category.slug); return <button className="category-tile" type="button" key={category.id} onClick={() => openShop(category.slug)}><span className="category-tile-art">{artwork && <ProductVisual imageUrl={artwork.imageUrl} name={artwork.name} />}</span><strong>{category.name}</strong><span>{category.description}</span><Icon name="arrow" size={19} /></button> })}</div>}</div>}

      {view === 'bag' && <div className="page-wrap simple-page"><div className="page-top"><button className="back-button" type="button" onClick={() => navigate('home')} aria-label="Back to home"><Icon name="back" size={24} /></button></div><p className="eyebrow">YOUR EVERYDAY FUEL</p><h1>Bag <span className="heading-count">{bagCount}</span></h1><p className="page-description">Local bag preview. Checkout and delivery are not connected on web yet.</p>{bagProducts.length ? <><div className="bag-list">{bagProducts.map((product) => <div className="bag-item" key={product.id}><ProductVisual imageUrl={product.imageUrl} name={product.name} /><div><strong>{product.name}</strong><span>{product.weightLabel ?? product.category.name}</span><b>{formatPrice(product.price, product.currency)}</b></div><div className="quantity-stepper"><button type="button" aria-label={'Remove one ' + product.name} onClick={() => changeQuantity(product, quantities[product.id] - 1)}><Icon name="minus" size={17} /></button><output aria-label={product.name + ' quantity'}>{quantities[product.id]}</output><button type="button" aria-label={'Add one ' + product.name} onClick={() => changeQuantity(product, quantities[product.id] + 1)}><Icon name="plus" size={17} /></button></div></div>)}</div><div className="bag-summary"><span>Estimated subtotal</span><strong>{formatPrice(bagTotal.toFixed(2), bagProducts[0].currency)}</strong></div></> : <div className="state-panel"><Icon name="bag" size={38} /><h2>Your bag is empty.</h2><p>Find something that fuels your next day.</p><button type="button" className="primary-button" onClick={() => openShop()}>Explore products <Icon name="arrow" size={18} /></button></div>}</div>}

      {view === 'you' && <div className="page-wrap simple-page"><div className="page-top"><button className="back-button" type="button" onClick={() => navigate('home')} aria-label="Back to home"><Icon name="back" size={24} /></button></div><p className="eyebrow">YOUR PROTO</p><h1>You</h1><div className="state-panel account-panel"><Icon name="user" size={38} /><h2>Your account is coming to web.</h2><p>Sign in, orders, and delivery tracking are not connected here yet. You can browse the catalog and keep a local bag for this visit.</p><button type="button" className="primary-button" onClick={() => openShop()}>Explore products <Icon name="arrow" size={18} /></button></div>{favorites.length > 0 && <section className="saved-section"><h2>Saved for this visit</h2><div className="product-grid">{catalog?.products.filter((product) => favorites.includes(product.id)).map(card)}</div></section>}</div>}
    </main>
    <nav className="bottom-nav" aria-label="Primary navigation"><div className="bottom-nav-inner">{([{ id: 'home', label: 'Shop', icon: 'home' }, { id: 'categories', label: 'Categories', icon: 'grid' }, { id: 'bag', label: 'Bag', icon: 'bag' }, { id: 'you', label: 'You', icon: 'user' }] as const).map((item) => <button key={item.id} type="button" className={(view === item.id || (view === 'shop' && item.id === 'home')) ? 'active' : ''} aria-current={(view === item.id || (view === 'shop' && item.id === 'home')) ? 'page' : undefined} onClick={() => navigate(item.id)}><span className="nav-icon"><Icon name={item.icon} size={22} filled={item.id === 'home' && (view === 'home' || view === 'shop')} />{item.id === 'bag' && bagCount > 0 && <i>{bagCount}</i>}</span><span>{item.label}</span></button>)}</div></nav>
    <ProductDetailDialog product={selectedProduct} onClose={() => setSelectedProduct(null)} quantity={selectedProduct ? quantities[selectedProduct.id] ?? 0 : 0} onQuantityChange={changeQuantity} favorite={selectedProduct ? favorites.includes(selectedProduct.id) : false} onFavoriteToggle={toggleFavorite} />
  </div>
}

export default App
