export type CartState = Readonly<Record<string, number>>;

export type CartAction =
  | { type: 'add'; productId: string }
  | { type: 'remove'; productId: string }
  | { type: 'clear' };

export const initialCartState: CartState = {};

/** Accept only catalog IDs, so stale routes or invalid input cannot create phantom items. */
export function createCartReducer(productIds: readonly string[]) {
  const validProductIds = new Set(productIds);

  return function cartReducer(state: CartState, action: CartAction): CartState {
    if (action.type === 'clear') {
      return initialCartState;
    }

    if (!validProductIds.has(action.productId)) {
      return state;
    }

    const quantity = state[action.productId] ?? 0;

    if (action.type === 'add') {
      return { ...state, [action.productId]: quantity + 1 };
    }

    if (quantity === 0) {
      return state;
    }

    if (quantity === 1) {
      const nextState = { ...state };
      delete nextState[action.productId];
      return nextState;
    }

    return { ...state, [action.productId]: quantity - 1 };
  };
}
