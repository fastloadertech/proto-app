import type { NativeStackScreenProps } from '@react-navigation/native-stack';
import { StyleSheet, Text, View } from 'react-native';
import { Icon } from '../components/Icon';
import { formatPrice } from '../data/catalog';
import type { RootStackParamList } from '../navigation/types';
import { useCart } from '../state/cart';
import { colors, spacing, typography } from '../theme';
import { ActionButton, Page, PageIntro, screenStyles, SummaryRow } from './ScreenParts';

export default function CheckoutScreen({ navigation }: NativeStackScreenProps<RootStackParamList, 'Checkout'>) {
  const { items, subtotal, totalCount } = useCart();

  return (
    <Page>
      <PageIntro eyebrow="ONE LAST LOOK" title="Everything you need." description="Review your basket and delivery location." />
      <View style={screenStyles.card}>
        <View style={styles.addressHeading}><Icon name="location-outline" size={21} color={colors.primary} /><Text style={screenStyles.sectionTitle}>Delivering to Home</Text></View>
        <Text style={screenStyles.note}>Indiranagar, Bengaluru · Sample address</Text>
      </View>
      <View style={screenStyles.card}>
        <Text style={screenStyles.sectionTitle}>Your essentials ({totalCount})</Text>
        {items.map(({ product, quantity }) => <SummaryRow key={product.id} label={`${quantity} × ${product.name}`} value={formatPrice(product.price * quantity)} />)}
        <View style={screenStyles.divider} />
        <SummaryRow label="Items subtotal" value={formatPrice(subtotal)} strong />
        <Text style={screenStyles.note}>Delivery charges will be available when ordering launches.</Text>
      </View>
      <View style={screenStyles.card}>
        <Text style={styles.previewTitle}>A preview of what’s next</Text>
        <Text style={screenStyles.note}>No payment is required. This preview won’t place an order or arrange a delivery.</Text>
      </View>
      <ActionButton label="Preview confirmation" disabled={items.length === 0} onPress={() => navigation.navigate('OrderConfirmation')} />
    </Page>
  );
}

const styles = StyleSheet.create({
  addressHeading: { flexDirection: 'row', alignItems: 'center', gap: spacing.sm },
  previewTitle: { ...typography.label, color: colors.primaryDark },
});
