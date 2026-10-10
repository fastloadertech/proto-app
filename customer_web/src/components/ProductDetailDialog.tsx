import { useEffect, useRef } from 'react'
import type { Product } from '../types/catalog.ts'
import { formatPrice } from '../lib/formatPrice.ts'
import { Icon } from './Icon.tsx'
import { ProductVisual } from './ProductVisual.tsx'

type Props = {
  product: Product | null
  onClose: () => void
  quantity?: number
  onQuantityChange?: (product: Product, next: number) => void
  favorite?: boolean
  onFavoriteToggle?: (product: Product) => void
}

export function ProductDetailDialog({ product, onClose, quantity = 0, onQuantityChange, favorite = false, onFavoriteToggle }: Props) {
  const dialogRef = useRef<HTMLDialogElement>(null)

  useEffect(() => {
    const dialog = dialogRef.current
    if (!dialog) return
    if (product && !dialog.open) dialog.showModal()
    if (!product && dialog.open) dialog.close()
  }, [product])

  return (
    <dialog ref={dialogRef} className="detail-dialog" onClose={onClose} aria-label={product ? `${product.name} details` : 'Product details'}>
      {product && (
        <div className="detail-layout">
          <button className="dialog-close" type="button" onClick={() => dialogRef.current?.close()} aria-label="Close product details">×</button>
          <ProductVisual imageUrl={product.imageUrl} name={product.name} className="detail-art" eager />
          <div className="detail-copy">
            <span className="eyebrow">{product.brand || product.category.name}</span>
            {product.badge && product.available && <span className="detail-badge">{product.badge}</span>}
            <h2>{product.name}</h2>
            {product.weightLabel && <span className="product-size">{product.weightLabel}</span>}
            <p>{product.description || 'Product details are coming soon.'}</p>
            <span className={`detail-availability ${product.available ? 'positive' : 'muted'}`}>
              <span className="status-dot" aria-hidden="true" />{product.available ? 'Available now' : 'Currently unavailable'}
            </span>
            <div className="detail-price-row">
              <strong>{formatPrice(product.price, product.currency)}</strong>
              {product.originalPrice && Number(product.originalPrice) > Number(product.price) && (
                <del className="old-price">{formatPrice(product.originalPrice, product.currency)}</del>
              )}
            </div>
            <div className="detail-actions">
              {onQuantityChange && (
                !product.available ? <button className="add-button unavailable-button" type="button" disabled>UNAVAILABLE</button>
                  : quantity > 0 ? (
                    <div className="quantity-stepper" role="group" aria-label={`${product.name} quantity in bag`}>
                      <button type="button" onClick={() => onQuantityChange(product, quantity - 1)} aria-label={`Remove one ${product.name}`}><Icon name="minus" size={18} /></button>
                      <output aria-live="polite" aria-label={`${product.name} quantity`}>{quantity}</output>
                      <button type="button" onClick={() => onQuantityChange(product, quantity + 1)} aria-label={`Add one ${product.name}`}><Icon name="plus" size={18} /></button>
                    </div>
                  ) : <button className="add-button" type="button" onClick={() => onQuantityChange(product, 1)} aria-label={`Add ${product.name} to bag`}>ADD TO BAG <Icon name="plus" size={18} /></button>
              )}
              {onFavoriteToggle && (
                <button className={`detail-save-button${favorite ? ' is-favorite' : ''}`} type="button" onClick={() => onFavoriteToggle(product)} aria-pressed={favorite} aria-label={favorite ? `Remove ${product.name} from saved` : `Save ${product.name}`}>
                  <Icon name="heart" size={20} filled={favorite} />
                </button>
              )}
            </div>
          </div>
        </div>
      )}
    </dialog>
  )
}
