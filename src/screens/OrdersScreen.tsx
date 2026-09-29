import { useNavigation } from '@react-navigation/native';
import type { NativeStackNavigationProp } from '@react-navigation/native-stack';
import type { RootStackParamList } from '../navigation/types';
import { EmptyState, Page } from './ScreenParts';

export default function OrdersScreen() {
  const navigation = useNavigation<NativeStackNavigationProp<RootStackParamList>>();
  return <Page><EmptyState icon="receipt-outline" title="Good things are on their way." description="Your orders will live here once ordering launches. For now, find your next everyday favourite." action="Find your fuel" onAction={() => navigation.navigate('Main', { screen: 'Home' })} /></Page>;
}
