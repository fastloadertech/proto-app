import type { SVGProps } from 'react'

export type IconName = 'bolt' | 'bag' | 'user' | 'location' | 'chevron' | 'search' | 'filter' | 'arrow' | 'back' | 'home' | 'grid' | 'heart' | 'minus' | 'plus' | 'check'

type Props = SVGProps<SVGSVGElement> & { name: IconName; size?: number; filled?: boolean }

export function Icon({ name, size = 22, filled = false, ...props }: Props) {
  if (name === 'bolt') return <svg width={size} height={size} viewBox="0 0 24 24" fill="currentColor" aria-hidden="true" {...props}><path d="M13.9 1.5 4.7 13h6.1l-1 9.5L19.4 10h-6.2z" /></svg>
  const paths: Record<Exclude<IconName, 'bolt'>, React.ReactNode> = {
    bag: <><path d="M5 8h14l-1 13H6L5 8Z" /><path d="M9 9V6a3 3 0 0 1 6 0v3" /></>,
    user: <><circle cx="12" cy="7" r="3.5" /><path d="M4.5 20a7.5 7.5 0 0 1 15 0H4.5Z" /></>,
    location: <><path d="M19 10c0 5-7 11-7 11S5 15 5 10a7 7 0 1 1 14 0Z" /><circle cx="12" cy="10" r="2.5" /></>,
    chevron: <path d="m6 9 6 6 6-6" />,
    search: <><circle cx="10.5" cy="10.5" r="6.5" /><path d="m15.5 15.5 5 5" /></>,
    filter: <><path d="M3 6h18M6 12h12M9 18h6" /></>,
    arrow: <><path d="M4 12h15M13 6l6 6-6 6" /></>,
    back: <><path d="M20 12H5m6-6-6 6 6 6" /></>,
    home: <path d="m3 11 9-8 9 8v10h-6v-7H9v7H3V11Z" />,
    grid: <><rect x="3" y="3" width="7" height="7" /><rect x="14" y="3" width="7" height="7" /><rect x="3" y="14" width="7" height="7" /><rect x="14" y="14" width="7" height="7" /></>,
    heart: <path d="M20.8 8.4c0 4.5-8.8 11.3-8.8 11.3S3.2 12.9 3.2 8.4a4.5 4.5 0 0 1 8.8-1.1 4.5 4.5 0 0 1 8.8 1.1Z" />,
    minus: <path d="M5 12h14" />,
    plus: <path d="M12 5v14M5 12h14" />,
    check: <path d="m4 12 5 5L20 6" />,
  }
  return <svg width={size} height={size} viewBox="0 0 24 24" fill={filled ? 'currentColor' : 'none'} stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true" {...props}>{paths[name]}</svg>
}
