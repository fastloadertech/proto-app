import { colors } from '../theme';
import type { Category, Product } from '../types/catalog';

// Local demonstration catalog. Product details and prices are illustrative.
export const categories: Category[] = [
  { id: 'protein', name: 'Protein', icon: 'barbell-outline' },
  { id: 'eggs', name: 'Eggs', icon: 'egg-outline' },
  { id: 'dairy', name: 'Dairy', icon: 'water-outline' },
  { id: 'snacks', name: 'Snacks', icon: 'nutrition-outline' },
  { id: 'shakes', name: 'Shakes', icon: 'cafe-outline' },
  { id: 'fitness', name: 'Fitness', icon: 'fitness-outline' },
];

export const products: Product[] = [
  {
    id: 'whey-protein',
    name: 'Whey Protein',
    variant: 'Rich chocolate · 500 g',
    price: 1499,
    category: 'protein',
    artwork: 'whey',
    highlight: '24 g protein',
    background: colors.wheyBackground,
  },
  {
    id: 'protein-bar',
    name: 'Protein Bar',
    variant: 'Peanut crunch · 60 g',
    price: 99,
    category: 'snacks',
    artwork: 'bar',
    highlight: '20 g protein',
    background: colors.barBackground,
  },
  {
    id: 'greek-yogurt',
    name: 'Greek Yogurt',
    variant: 'Natural · 100 g',
    price: 75,
    category: 'dairy',
    artwork: 'yogurt',
    highlight: 'Thick & creamy',
    background: colors.yogurtBackground,
  },
  {
    id: 'eggs',
    name: 'Eggs',
    variant: 'Farm fresh · Pack of 6',
    price: 89,
    category: 'eggs',
    artwork: 'eggs',
    highlight: 'Everyday essential',
    background: colors.eggsBackground,
  },
  {
    id: 'milk',
    name: 'Milk',
    variant: 'Fresh toned milk · 500 ml',
    price: 32,
    category: 'dairy',
    artwork: 'milk',
    highlight: 'Fresh daily',
    background: colors.milkBackground,
  },
  {
    id: 'paneer',
    name: 'Paneer',
    variant: 'Soft & fresh · 200 g',
    price: 95,
    category: 'dairy',
    artwork: 'paneer',
    highlight: 'Meal prep favourite',
    background: colors.paneerBackground,
  },
  {
    id: 'protein-shake',
    name: 'Protein Shake',
    variant: 'Cold coffee · 250 ml',
    price: 129,
    category: 'shakes',
    artwork: 'shake',
    highlight: '25 g protein',
    background: colors.shakeBackground,
  },
  {
    id: 'shaker-bottle',
    name: 'Shaker Bottle',
    variant: 'Sage green · 700 ml',
    price: 299,
    category: 'fitness',
    artwork: 'shaker',
    highlight: 'Your gym companion',
    background: colors.shakerBackground,
  },
];

export function getProductById(id: string): Product | undefined {
  return products.find((product) => product.id === id);
}

const priceFormatter = new Intl.NumberFormat('en-IN', {
  style: 'currency',
  currency: 'INR',
  maximumFractionDigits: 2,
  minimumFractionDigits: 0,
});

export function formatPrice(value: number): string {
  return priceFormatter.format(value);
}
