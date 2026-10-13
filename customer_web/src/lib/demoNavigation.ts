export type DemoView = 'home' | 'shop' | 'categories' | 'bag' | 'checkout' | 'confirmation' |
  'orders' | 'order-detail' | 'you' | 'addresses' | 'admin'

export type DemoRoute = { view: DemoView; reference: string }

const views = new Set<DemoView>([
  'home', 'shop', 'categories', 'bag', 'checkout', 'confirmation',
  'orders', 'you', 'addresses', 'admin',
])

/** Hash routes contain only demo view names or a demo order reference. */
export function readDemoRoute(hash: string): DemoRoute {
  if (typeof hash !== 'string' || hash.length > 512) return { view: 'home', reference: '' }
  const route = hash.replace(/^#/, '')
  if (route.startsWith('order/')) {
    try {
      const reference = decodeURIComponent(route.slice('order/'.length))
      return { view: 'order-detail', reference: reference.length <= 128 && !/[\u0000-\u001f\u007f]/.test(reference) ? reference : '' }
    } catch {
      return { view: 'order-detail', reference: '' }
    }
  }
  return views.has(route as DemoView) ? { view: route as DemoView, reference: '' } : { view: 'home', reference: '' }
}

export function demoRouteHash(view: DemoView, reference = ''): string {
  return view === 'order-detail' ? `#order/${encodeURIComponent(reference)}` : `#${view}`
}
