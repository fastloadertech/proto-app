import { useNavigation } from '@react-navigation/native';
import type { NativeStackNavigationProp } from '@react-navigation/native-stack';
import { Pressable, StyleSheet, Text, View } from 'react-native';
import { Icon } from '../components/Icon';
import { ProductArtwork } from '../components/ProductArtwork';
import { formatPrice } from '../data/catalog';
import type { RootStackParamList } from '../navigation/types';
import { useCart } from '../state/cart';
import { colors, radius, spacing, typography } from '../theme';
import { ActionButton, EmptyState, Page, PageIntro, screenStyles, SummaryRow } from './ScreenParts';

export default function CartScreen() {
  const navigation = useNavigation<NativeStackNavigationProp<RootStackParamList>>();
  const { items, totalCount, subtotal, addItem, removeItem } = useCart();

  if (items.length === 0) {
    return (
      <Page>
        <EmptyState icon="bag-handle-outline" title="Your next good habit starts here." description="Add a few everyday essentials and make room for a little more protein." action="Explore essentials" onAction={() => navigation.navigate('Main', { screen: 'Home' })} />
      </Page>
    );
  }

  return (
    <Page>
      <PageIntro eyebrow="GOOD CHOICES, ALL TOGETHER" title="Your daily fuel." description={`${totalCount} ${totalCount === 1 ? 'item' : 'items'} in your cart`} />
      <View style={styles.list}>
        {items.map(({ product, quantity }) => (
          <View key={product.id} style={styles.item}>
            <Pressable accessibilityRole="button" accessibilityLabel={`View ${product.name}`} onPress={() => navigation.navigate('ProductDetails', { productId: product.id })} style={[styles.artwork, { backgroundColor: product.background }]}>
              <ProductArtwork kind={product.artwork} size={72} />
            </Pressable>
            <View style={styles.itemInfo}>
              <Text style={styles.name}>{product.name}</Text>
              <Text style={styles.variant}>{product.variant}</Text>
              <View style={styles.bottomRow}>
                <Text style={styles.price}>{formatPrice(product.price * quantity)}</Text>
                <View style={styles.stepper}>
                  <Pressable accessibilityRole="button" accessibilityLabel={`Remove one ${product.name}`} onPress={() => removeItem(product.id)} style={({ pressed }) => [styles.stepButton, pressed && styles.pressed]}><Icon name="remove" size={17} color={colors.primaryDark} /></Pressable>
                  <Text style={styles.quantity} accessibilityLabel={`${quantity} ${product.name} in cart`}>{quantity}</Text>
                  <Pressable accessibilityRole="button" accessibilityLabel={`Add one ${product.name}`} onPress={() => addItem(product.id)} style={({ pressed }) => [styles.stepButton, pressed && styles.pressed]}><Icon name="add" size={17} color={colors.primaryDark} /></Pressable>
                </View>
              </View>
            </View>
          </View>
        ))}
      </View>
      <View style={screenStyles.card}>
        <Text style={screenStyles.sectionTitle}>Your basket</Text>
        <SummaryRow label={`Items (${totalCount})`} value={formatPrice(subtotal)} />
        <View style={screenStyles.divider} />
        <SummaryRow label="Subtotal" value={formatPrice(subtotal)} strong />
      </View>
      <ActionButton label="Choose delivery address" onPress={() => navigation.navigate('Address', { mode: 'checkout' })} disabled={items.length === 0} />
      <Text style={screenStyles.note}>You’re exploring the PROTO preview. Checkout is a demo and won’t place an order.</Text>
    </Page>
  );
}

const styles = StyleSheet.create({
  list: { gap: spacing.md },
  item: { flexDirection: 'row', alignItems: 'center', gap: spacing.md, padding: spacing.md, backgroundColor: colors.surface, borderRadius: radius.lg, borderWidth: 1, borderColor: colors.border },
  artwork: { width: 78, height: 94, borderRadius: radius.md, alignItems: 'center', justifyContent: 'center' },
  itemInfo: { flex: 1, gap: spacing.xs },
  name: { ...typography.label, color: colors.ink },
  variant: { ...typography.caption, color: colors.muted },
  bottomRow: { flexDirection: 'row', flexWrap: 'wrap', alignItems: 'center', justifyContent: 'space-between', gap: spacing.sm, marginTop: spacing.xs },
  price: { ...typography.label, color: colors.ink },
  stepper: { flexDirection: 'row', alignItems: 'center', borderRadius: radius.sm, backgroundColor: colors.primarySoft, overflow: 'hidden' },
  stepButton: { width: 44, height: 44, alignItems: 'center', justifyContent: 'center' },
  quantity: { ...typography.label, minWidth: 20, textAlign: 'center', color: colors.primaryDark },
  pressed: { opacity: 0.5 },
});
