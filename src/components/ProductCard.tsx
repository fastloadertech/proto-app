import { Pressable, StyleSheet, Text, View } from 'react-native';
import { formatPrice } from '../data/catalog';
import { useCart } from '../state/cart';
import { colors, radius, shadows, spacing, typography } from '../theme';
import type { Product } from '../types/catalog';
import { Icon } from './Icon';
import { ProductArtwork } from './ProductArtwork';

export function ProductCard({ product, onPress }: { product: Product; onPress: () => void }) {
  const { addItem, removeItem, getQuantity } = useCart();
  const quantity = getQuantity(product.id);

  return (
    <View style={styles.card}>
      <Pressable
        accessibilityRole="button"
        accessibilityLabel={`View ${product.name}, ${product.variant}, ${formatPrice(product.price)}`}
        onPress={onPress}
        style={({ pressed }) => [styles.details, pressed && styles.pressed]}
      >
        <View style={[styles.artwork, { backgroundColor: product.background }]}>
          <ProductArtwork kind={product.artwork} size={136} />
          <View style={styles.highlight}><Text style={styles.highlightText}>{product.highlight}</Text></View>
        </View>
        <Text style={styles.name} numberOfLines={2}>{product.name}</Text>
        <Text style={styles.variant} numberOfLines={1}>{product.variant}</Text>
      </Pressable>
      <View style={styles.footer}>
        <Text style={styles.price}>{formatPrice(product.price)}</Text>
        {quantity === 0 ? (
          <Pressable
            accessibilityRole="button"
            accessibilityLabel={`Add ${product.name} to cart`}
            onPress={() => addItem(product.id)}
            style={({ pressed }) => [styles.add, pressed && styles.pressed]}
          >
            <Text style={styles.addLabel}>ADD</Text>
            <Icon name="add" size={16} color={colors.primary} />
          </Pressable>
        ) : (
          <View style={styles.stepper}>
            <Pressable accessibilityRole="button" accessibilityLabel={`Remove one ${product.name}`} onPress={() => removeItem(product.id)} style={styles.step}>
              <Icon name="remove" size={17} color={colors.primary} />
            </Pressable>
            <Text accessibilityLiveRegion="polite" style={styles.count}>{quantity}</Text>
            <Pressable accessibilityRole="button" accessibilityLabel={`Add one ${product.name}`} onPress={() => addItem(product.id)} style={styles.step}>
              <Icon name="add" size={17} color={colors.primary} />
            </Pressable>
          </View>
        )}
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  card: { backgroundColor: colors.surface, borderRadius: radius.lg, borderWidth: 1, borderColor: colors.border, overflow: 'hidden', ...shadows.card },
  details: { padding: spacing.sm },
  pressed: { opacity: 0.65 },
  artwork: { height: 152, borderRadius: radius.md, alignItems: 'center', justifyContent: 'center', marginBottom: spacing.md },
  highlight: { position: 'absolute', left: spacing.sm, bottom: spacing.sm, backgroundColor: colors.surface, borderRadius: radius.xs, paddingHorizontal: spacing.sm, paddingVertical: spacing.xs },
  highlightText: { ...typography.caption, color: colors.sage, fontWeight: '700', fontSize: 9 },
  name: { ...typography.label, color: colors.ink, paddingHorizontal: spacing.xs, minHeight: 21 },
  variant: { ...typography.caption, color: colors.muted, paddingHorizontal: spacing.xs, marginTop: spacing.xs },
  footer: { padding: spacing.sm, paddingTop: spacing.xs, flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between', flexWrap: 'wrap', gap: spacing.xs },
  price: { ...typography.label, color: colors.ink, paddingLeft: spacing.xs },
  add: { minHeight: 44, minWidth: 72, borderWidth: 1, borderColor: colors.primary, borderRadius: radius.sm, flexDirection: 'row', alignItems: 'center', justifyContent: 'center', gap: spacing.xs, backgroundColor: colors.primarySoft, paddingHorizontal: spacing.sm },
  addLabel: { ...typography.caption, fontWeight: '800', color: colors.primary },
  stepper: { flexDirection: 'row', alignItems: 'center', backgroundColor: colors.primarySoft, borderRadius: radius.sm },
  step: { minWidth: 44, minHeight: 44, alignItems: 'center', justifyContent: 'center' },
  count: { ...typography.caption, fontWeight: '800', color: colors.primary, minWidth: 12, textAlign: 'center' },
});
