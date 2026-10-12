import type { NavigatorScreenParams } from '@react-navigation/native';
import type { CategoryId } from '../types/catalog';

export type MainTabParamList = {
  Home: undefined;
  Categories: undefined;
  Cart: undefined;
  Orders: undefined;
  Account: undefined;
};

export type RootStackParamList = {
  Main: NavigatorScreenParams<MainTabParamList> | undefined;
  Category: { categoryId: CategoryId };
  ProductDetails: { productId: string };
  Address: { mode?: 'delivery' | 'checkout' } | undefined;
  Checkout: undefined;
  OrderConfirmation: undefined;
};
