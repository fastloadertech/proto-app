export type CategoryId = 'protein' | 'eggs' | 'dairy' | 'snacks' | 'shakes' | 'fitness';

export type ProductArtwork = 'whey' | 'bar' | 'yogurt' | 'eggs' | 'milk' | 'paneer' | 'shake' | 'shaker';

export type CategoryIcon =
  | 'barbell-outline'
  | 'egg-outline'
  | 'water-outline'
  | 'nutrition-outline'
  | 'cafe-outline'
  | 'fitness-outline';

export interface Category {
  id: CategoryId;
  name: string;
  icon: CategoryIcon;
}

export interface Product {
  id: string;
  name: string;
  variant: string;
  price: number;
  category: CategoryId;
  artwork: ProductArtwork;
  highlight: string;
  background: string;
}
