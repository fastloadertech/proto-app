import {
  createContext,
  useCallback,
  useContext,
  useMemo,
  useReducer,
  type ReactNode,
} from 'react';

import { getProductById, products } from '../data/catalog';
import type { Product } from '../types/catalog';
import { createCartReducer, initialCartState } from './cartReducer';

export interface CartItem {
  product: Product;
  quantity: number;
}

export interface CartContextValue {
  items: CartItem[];
  totalCount: number;
  subtotal: number;
  addItem: (productId: string) => void;
  removeItem: (productId: string) => void;
  clearCart: () => void;
  getQuantity: (productId: string) => number;
}

const CartContext = createContext<CartContextValue | undefined>(undefined);
const cartReducer = createCartReducer(products.map((product) => product.id));

export function CartProvider({ children }: { children: ReactNode }) {
  const [state, dispatch] = useReducer(cartReducer, initialCartState);

  const items = useMemo<CartItem[]>(
    () =>
      Object.entries(state).flatMap(([productId, quantity]) => {
        const product = getProductById(productId);
        return product && quantity > 0 ? [{ product, quantity }] : [];
      }),
    [state],
  );

  const totalCount = items.reduce((total, item) => total + item.quantity, 0);
  const subtotal = items.reduce((total, item) => total + item.product.price * item.quantity, 0);

  const addItem = useCallback((productId: string) => dispatch({ type: 'add', productId }), []);
  const removeItem = useCallback((productId: string) => dispatch({ type: 'remove', productId }), []);
  const clearCart = useCallback(() => dispatch({ type: 'clear' }), []);
  const getQuantity = useCallback(
    (productId: string) => (getProductById(productId) ? state[productId] ?? 0 : 0),
    [state],
  );

  const value = useMemo<CartContextValue>(
    () => ({ items, totalCount, subtotal, addItem, removeItem, clearCart, getQuantity }),
    [items, totalCount, subtotal, addItem, removeItem, clearCart, getQuantity],
  );

  return <CartContext.Provider value={value}>{children}</CartContext.Provider>;
}

export function useCart(): CartContextValue {
  const cart = useContext(CartContext);

  if (!cart) {
    throw new Error('useCart must be used within a CartProvider.');
  }

  return cart;
}
