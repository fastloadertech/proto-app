import { useState } from 'react'

type Props = {
  imageUrl: string | null
  name: string
  className?: string
  eager?: boolean
}

export function ProductVisual({ imageUrl, name, className = '', eager = false }: Props) {
  const [failedUrl, setFailedUrl] = useState<string | null>(null)
  const source = imageUrl && imageUrl !== failedUrl ? imageUrl : null

  return (
    <div className={`product-visual ${className}`}>
      {source ? (
        <img
          src={source}
          alt={name}
          loading={eager ? 'eager' : 'lazy'}
          onError={() => setFailedUrl(source)}
        />
      ) : (
        <div className="product-placeholder" role="img" aria-label={`${name} artwork unavailable`}>
          <span className="placeholder-mark">P<span>.</span></span>
          <span className="placeholder-caption">PROTO</span>
        </div>
      )}
    </div>
  )
}
