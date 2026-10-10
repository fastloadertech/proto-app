import type { Catalog, Category, Product } from '../types/catalog.ts'

// Mirrors Flutter's local catalog. IDs and SKUs identify these as demo records.
const categories: Category[] = [
  { id: 'demo-protein', slug: 'protein', name: 'Protein', description: 'Build & recover' },
  { id: 'demo-snacks', slug: 'snacks', name: 'Smart snacks', description: 'Better between meals' },
  { id: 'demo-creatine', slug: 'creatine', name: 'Creatine', description: 'Power every rep' },
  { id: 'demo-preworkout', slug: 'preworkout', name: 'Pre-workout', description: 'Find your focus' },
  { id: 'demo-essentials', slug: 'essentials', name: 'Essentials', description: 'Your daily baseline' },
  { id: 'demo-hydration', slug: 'hydration', name: 'Hydration', description: 'Refill & reset' },
]

const bySlug = (slug: string) => categories.find((category) => category.slug === slug)!

type DemoProduct = Pick<Product, 'name' | 'description' | 'price' | 'originalPrice' | 'brand' | 'weightLabel' | 'badge'> & {
  slug: string
  categorySlug: string
  available?: boolean
}

const demoProducts: DemoProduct[] = [
  {
    slug: 'whey-isolate', name: 'Whey Isolate', brand: 'PROTO FUEL', categorySlug: 'protein',
    price: '2499.00', originalPrice: '2999.00', weightLabel: '1 kg', badge: 'BESTSELLER',
    description: 'A smooth whey isolate for the work you put in. Each serving delivers 27 g of protein in a light, easy-mixing shake. Add one scoop to 250 ml of water or milk and shake well. Contains milk.',
  },
  {
    slug: 'everyday-whey', name: 'Everyday Whey', brand: 'PROTO FUEL', categorySlug: 'protein',
    price: '1799.00', originalPrice: '2299.00', weightLabel: '1 kg', badge: 'DAILY FAVOURITE',
    description: 'Rich, creamy whey concentrate made for your daily routine. Mix one scoop with 250 ml of water or milk after training, or blend into your breakfast smoothie. Contains milk.',
  },
  {
    slug: 'plant-protein', name: 'Plant Protein Blend', brand: 'PROTO FUEL', categorySlug: 'protein',
    price: '1499.00', originalPrice: '1799.00', weightLabel: '750 g', badge: 'PLANT POWERED',
    description: 'A balanced blend of pea and brown rice protein with a gentle cocoa finish. Made without dairy. Shake one scoop with 300 ml of water or your favourite plant milk.',
  },
  {
    slug: 'crunch-protein-bar', name: 'Crunch Protein Bar', brand: 'PROTO KITCHEN', categorySlug: 'snacks',
    price: '99.00', originalPrice: '129.00', weightLabel: '60 g', badge: '20 G PROTEIN',
    description: 'A crisp, chocolate-coated protein bar for busy days, gym bags, and the space between meals. Individually wrapped and ready when you are. Contains milk, peanuts, and soy.',
  },
  {
    slug: 'protein-bites', name: 'Peanut Butter Bites', brand: 'PROTO KITCHEN', categorySlug: 'snacks',
    price: '299.00', originalPrice: '349.00', weightLabel: '150 g', badge: 'SNACK SMART', available: false,
    description: 'Soft peanut butter bites with oats, cocoa, and a satisfying crunch. A resealable pouch makes these an easy desk or post-training snack. Protein shown is per 30 g serving. Contains peanuts and milk.',
  },
  {
    slug: 'creatine-monohydrate', name: 'Creatine Monohydrate', brand: 'PROTO LABS', categorySlug: 'creatine',
    price: '699.00', originalPrice: '899.00', weightLabel: '250 g', badge: 'PURE PERFORMANCE',
    description: 'Single-ingredient, micronized creatine monohydrate with no added flavours or fillers. Stir one 3 g serving into water or your usual shake. A simple addition to a consistent training routine.',
  },
  {
    slug: 'ignite-preworkout', name: 'Ignite Pre-workout', brand: 'PROTO LABS', categorySlug: 'preworkout',
    price: '999.00', originalPrice: '1299.00', weightLabel: '200 g', badge: 'WORKOUT READY',
    description: 'A bright, refreshing pre-workout with caffeine and citrulline. Mix one serving with 250 ml of cold water before training. Each serving contains 150 mg caffeine; avoid taking near bedtime.',
  },
  {
    slug: 'focus-preworkout', name: 'Focus Pre-workout', brand: 'PROTO LABS', categorySlug: 'preworkout',
    price: '1299.00', originalPrice: '1599.00', weightLabel: '250 g', badge: 'FIND YOUR FOCUS',
    description: 'A clean-tasting pre-workout with 100 mg caffeine per serving. Designed for the days you want a measured lift before your session. Mix with 250 ml of water. Contains caffeine.',
  },
  {
    slug: 'daily-greens', name: 'Daily Greens', brand: 'PROTO DAILY', categorySlug: 'essentials',
    price: '899.00', originalPrice: '1099.00', weightLabel: '200 g', badge: 'DAILY ESSENTIAL',
    description: 'A daily greens blend with spinach, moringa, and a light citrus flavour. Mix one scoop into 250 ml of cold water or a smoothie. An easy companion to a varied, balanced diet.',
  },
  {
    slug: 'omega-3', name: 'Omega 3 Softgels', brand: 'PROTO DAILY', categorySlug: 'essentials',
    price: '499.00', originalPrice: '649.00', weightLabel: '60 softgels', badge: 'EVERYDAY WELLNESS',
    description: 'Easy-to-take fish oil softgels for your daily routine. The pack contains 60 softgels. Follow the serving guidance on the pack and take with a meal. Contains fish.',
  },
  {
    slug: 'electrolyte-mix', name: 'Electrolyte Mix', brand: 'PROTO HYDRATE', categorySlug: 'hydration',
    price: '599.00', originalPrice: '749.00', weightLabel: '15 sachets', badge: 'REFILL & RESET',
    description: 'Pocket-ready electrolyte sachets with sodium, potassium, and magnesium. Mix one sachet with 500 ml of cold water after a sweaty session, or whenever your day calls for a refresh.',
  },
  {
    slug: 'hydration-water', name: 'Hydration Water', brand: 'PROTO HYDRATE', categorySlug: 'hydration',
    price: '89.00', originalPrice: '109.00', weightLabel: '500 ml', badge: 'READY TO REFRESH',
    description: 'A refreshing, ready-to-drink electrolyte water with a light lemon-lime finish. Keep it chilled for your next session or take it with you for an easy refresh on the move.',
  },
]

export const demoCatalog: Catalog = {
  categories,
  products: demoProducts.map(({ slug, categorySlug, available = true, ...details }) => ({
    ...details,
    id: `demo-${slug}`,
    sku: `DEMO-${slug.toUpperCase()}`,
    currency: 'INR',
    imageUrl: `/images/proto-${slug}.png`,
    available,
    category: bySlug(categorySlug),
    createdAt: '2026-10-01T00:00:00.000Z',
  })),
}
