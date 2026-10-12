import type { Product } from '../types/catalog.ts'
import { formatPrice } from '../lib/formatPrice.ts'
import { Icon } from './Icon.tsx'
import { ProductVisual } from './ProductVisual.tsx'

type Props = {
  product: Product
  onOpen: (product: Product) => void
  quantity: number
  onQuantityChange: (product: Product, next: number) => void
  favorite: boolean
  onFavoriteToggle: (product: Product) => void
}

export function ProductCard({ product, onOpen, quantity, onQuantityChange, favorite, onFavoriteToggle }: Props) {
  const unavailable = !product.available || product.stockQuantity === 0
  const atQuantityLimit = quantity >= 99 || (product.stockQuantity != null && quantity >= product.stockQuantity)
  return (
    <article className="product-card">
      <div className="product-image-wrap">
        <button className="product-image-button" type="button" onClick={() => onOpen(product)} aria-label={`View ${product.name} details`}>
          <ProductVisual imageUrl={product.imageUrl} name={product.name} />
        </button>
        {(unavailable || product.badge) && (
          <span className={`availability ${unavailable ? 'sold-out' : 'product-badge'}`}>
            {unavailable ? 'UNAVAILABLE' : product.badge}
          </span>
        )}
        <button
          className={`favorite-button${favorite ? ' is-favorite' : ''}`}
          type="button"
          aria-label={favorite ? `Remove ${product.name} from saved` : `Save ${product.name}`}
          aria-pressed={favorite}
          onClick={() => onFavoriteToggle(product)}
        >
          <Icon name="heart" size={18} filled={favorite} />
        </button>
      </div>
      <div className="product-card-content">
        <span className="eyebrow product-category">{product.brand || product.category.name}</span>
        <h3><button className="product-name-button" type="button" onClick={() => onOpen(product)}>{product.name}</button></h3>
        {product.weightLabel && <span className="product-size">{product.weightLabel}</span>}
        <div className="price-row">
          <strong>{formatPrice(product.price, product.currency)}</strong>
          {product.originalPrice && Number(product.originalPrice) > Number(product.price) && (
            <del className="old-price">{formatPrice(product.originalPrice, product.currency)}</del>
          )}
        </div>
        {unavailable ? (
          <button className="add-button unavailable-button" type="button" disabled>UNAVAILABLE</button>
        ) : quantity > 0 ? (
          <div className="quantity-stepper" role="group" aria-label={`${product.name} quantity in bag`}>
            <button type="button" onClick={() => onQuantityChange(product, quantity - 1)} aria-label={`Remove one ${product.name}`}>
              <Icon name="minus" size={18} />
            </button>
            <output aria-live="polite" aria-label={`${product.name} quantity`}>{quantity}</output>
            <button type="button" onClick={() => onQuantityChange(product, quantity + 1)} aria-label={`Add one ${product.name}`} disabled={atQuantityLimit}>
              <Icon name="plus" size={18} />
            </button>
          </div>
        ) : (
          <button className="add-button" type="button" onClick={() => onQuantityChange(product, 1)} aria-label={`Add ${product.name} to bag`}>
            ADD <Icon name="plus" size={18} />
          </button>
        )}
      </div>
    </article>
  )
}
