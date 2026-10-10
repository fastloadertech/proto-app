export function formatPrice(amount: string, currency: string): string {
  const value = Number(amount)
  if (!Number.isFinite(value)) return amount
  try {
    return new Intl.NumberFormat('en-IN', {
      style: 'currency',
      currency,
      maximumFractionDigits: 2,
    }).format(value)
  } catch {
    return `${currency} ${amount}`
  }
}
