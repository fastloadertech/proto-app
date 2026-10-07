import type { NativeStackScreenProps } from '@react-navigation/native-stack';
import { StyleSheet, Text, View } from 'react-native';
import { Icon } from '../components/Icon';
import { ProductArtwork } from '../components/ProductArtwork';
import { formatPrice, getProductById } from '../data/catalog';
import type { RootStackParamList } from '../navigation/types';
import { useCart } from '../state/cart';
import { colors, radius, spacing, typography } from '../theme';
import { ActionButton, EmptyState, Page, PageIntro, screenStyles } from './ScreenParts';

export default function ProductDetailsScreen({ navigation, route }: NativeStackScreenProps<RootStackParamList, 'ProductDetails'>) {
  const product = getProductById(route.params.productId);
  const { addItem, getQuantity } = useCart();

  if (!product) {
    return <Page><EmptyState icon="basket-outline" title="This essential is taking a break." description="Explore more everyday favourites in our collection." action="Browse products" onAction={() => navigation.popTo('Main', { screen: 'Home' })} /></Page>;
  }

  const quantity = getQuantity(product.id);

  return (
    <Page>
      <View style={[styles.hero, { backgroundColor: product.background }]}>
        <ProductArtwork kind={product.artwork} size={224} />
        <View style={styles.badge}><Icon name="sparkles-outline" size={14} color={colors.sage} /><Text style={styles.badgeText}>{product.highlight}</Text></View>
      </View>
      <PageIntro eyebrow="EVERYDAY FUEL" title={product.name} description={product.variant} />
      <View style={styles.priceRow}><Text style={styles.price}>{formatPrice(product.price)}</Text><Text style={styles.priceNote}>per pack</Text></View>
      <ActionButton label={quantity > 0 ? `Add another · ${quantity} in cart` : 'Add to cart'} onPress={() => addItem(product.id)} />
      {quantity > 0 ? <ActionButton secondary label="View your cart" onPress={() => navigation.popTo('Main', { screen: 'Cart' })} /> : null}
      <View style={screenStyles.card}>
        <Text style={screenStyles.sectionTitle}>A good addition to your day.</Text>
        <Text style={screenStyles.note}>An everyday essential from the PROTO collection. More product information will be available here soon.</Text>
      </View>
    </Page>
  );
}

const styles = StyleSheet.create({
  hero: { minHeight: 292, borderRadius: radius.xxl, alignItems: 'center', justifyContent: 'center', padding: spacing.lg, gap: spacing.sm },
  badge: { flexDirection: 'row', alignItems: 'center', gap: spacing.xs, backgroundColor: colors.surface, borderRadius: radius.pill, paddingHorizontal: spacing.md, paddingVertical: spacing.sm },
  badgeText: { ...typography.caption, color: colors.sage },
  priceRow: { flexDirection: 'row', gap: spacing.sm, alignItems: 'baseline' },
  price: { ...typography.title, color: colors.ink },
  priceNote: { ...typography.bodySmall, color: colors.muted },
});
