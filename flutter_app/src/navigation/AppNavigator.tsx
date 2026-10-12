import type { ComponentProps } from 'react';
import { DefaultTheme, NavigationContainer } from '@react-navigation/native';
import { createBottomTabNavigator } from '@react-navigation/bottom-tabs';
import { createNativeStackNavigator } from '@react-navigation/native-stack';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { Icon } from '../components/Icon';
import HomeScreen from '../screens/HomeScreen';
import CategoriesScreen from '../screens/CategoriesScreen';
import CategoryScreen from '../screens/CategoryScreen';
import ProductDetailsScreen from '../screens/ProductDetailsScreen';
import CartScreen from '../screens/CartScreen';
import AddressScreen from '../screens/AddressScreen';
import CheckoutScreen from '../screens/CheckoutScreen';
import OrderConfirmationScreen from '../screens/OrderConfirmationScreen';
import OrdersScreen from '../screens/OrdersScreen';
import AccountScreen from '../screens/AccountScreen';
import { useCart } from '../state/cart';
import { colors, spacing, typography } from '../theme';
import type { MainTabParamList, RootStackParamList } from './types';

const Stack = createNativeStackNavigator<RootStackParamList>();
const Tab = createBottomTabNavigator<MainTabParamList>();

const tabIcons: Record<keyof MainTabParamList, { active: ComponentProps<typeof Icon>['name']; inactive: ComponentProps<typeof Icon>['name'] }> = {
  Home: { active: 'home', inactive: 'home-outline' },
  Categories: { active: 'grid', inactive: 'grid-outline' },
  Cart: { active: 'bag-handle', inactive: 'bag-handle-outline' },
  Orders: { active: 'receipt', inactive: 'receipt-outline' },
  Account: { active: 'person', inactive: 'person-outline' },
};

const navigationTheme = {
  ...DefaultTheme,
  colors: {
    ...DefaultTheme.colors,
    primary: colors.primary,
    background: colors.background,
    card: colors.surface,
    text: colors.ink,
    border: colors.border,
    notification: colors.primary,
  },
};

function MainTabs() {
  const { totalCount } = useCart();
  const insets = useSafeAreaInsets();

  return (
    <Tab.Navigator screenOptions={({ route }) => ({
      headerStyle: { backgroundColor: colors.surface },
      headerTitleStyle: { ...typography.subheading, color: colors.ink },
      headerShadowVisible: false,
      tabBarActiveTintColor: colors.primaryDark,
      tabBarInactiveTintColor: colors.muted,
      tabBarLabelStyle: { ...typography.caption, fontWeight: '600', marginTop: spacing.xxs },
      tabBarStyle: {
        backgroundColor: colors.surface,
        borderTopColor: colors.border,
        height: 64 + Math.max(insets.bottom, spacing.sm),
        paddingTop: spacing.sm,
        paddingBottom: Math.max(insets.bottom, spacing.sm),
      },
      tabBarIcon: ({ focused, color }) => <Icon name={focused ? tabIcons[route.name].active : tabIcons[route.name].inactive} size={23} color={color} />,
    })}>
      <Tab.Screen name="Home" component={HomeScreen} options={{ headerShown: false }} />
      <Tab.Screen name="Categories" component={CategoriesScreen} options={{ title: 'Categories' }} />
      <Tab.Screen name="Cart" component={CartScreen} options={{ title: 'Cart', tabBarBadge: totalCount > 0 ? totalCount : undefined, tabBarBadgeStyle: { backgroundColor: colors.primary, color: colors.surface } }} />
      <Tab.Screen name="Orders" component={OrdersScreen} />
      <Tab.Screen name="Account" component={AccountScreen} />
    </Tab.Navigator>
  );
}

export default function AppNavigator() {
  return (
    <NavigationContainer theme={navigationTheme}>
      <Stack.Navigator screenOptions={{
        headerStyle: { backgroundColor: colors.surface },
        headerTintColor: colors.ink,
        headerTitleStyle: typography.subheading,
        headerShadowVisible: false,
        contentStyle: { backgroundColor: colors.background },
      }}>
        <Stack.Screen name="Main" component={MainTabs} options={{ headerShown: false }} />
        <Stack.Screen name="Category" component={CategoryScreen} options={{ title: 'PROTO essentials' }} />
        <Stack.Screen name="ProductDetails" component={ProductDetailsScreen} options={{ title: 'The good stuff' }} />
        <Stack.Screen name="Address" component={AddressScreen} options={{ title: 'Delivery location' }} />
        <Stack.Screen name="Checkout" component={CheckoutScreen} options={{ title: 'Review your basket' }} />
        <Stack.Screen name="OrderConfirmation" component={OrderConfirmationScreen} options={{ title: 'Your preview' }} />
      </Stack.Navigator>
    </NavigationContainer>
  );
}
