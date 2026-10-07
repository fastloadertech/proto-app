import type { NativeStackScreenProps } from '@react-navigation/native-stack';
import { Pressable, StyleSheet, Text, View } from 'react-native';
import { Icon } from '../components/Icon';
import { ProductArtwork } from '../components/ProductArtwork';
import { categories, formatPrice, products } from '../data/catalog';
import type { RootStackParamList } from '../navigation/types';
import { colors, radius, spacing, typography } from '../theme';
import { Page, PageIntro } from './ScreenParts';

export default function CategoryScreen({ navigation, route }: NativeStackScreenProps<RootStackParamList, 'Category'>) {
  const category = categories.find((item) => item.id === route.params.categoryId);
  const categoryProducts = products.filter((product) => product.category === route.params.categoryId);

  return (
    <Page>
      <PageIntro eyebrow="THE GOOD STUFF" title={category?.name ?? 'Your essentials'} description="A little fuel for whatever your day has planned." />
      <View style={styles.list}>
        {categoryProducts.map((product) => (
          <Pressable key={product.id} accessibilityRole="button" accessibilityLabel={`View ${product.name}`} onPress={() => navigation.navigate('ProductDetails', { productId: product.id })} style={({ pressed }) => [styles.product, pressed && styles.pressed]}>
            <View style={[styles.artwork, { backgroundColor: product.background }]}><ProductArtwork kind={product.artwork} size={76} /></View>
            <View style={styles.info}>
              <Text style={styles.name}>{product.name}</Text>
              <Text style={styles.variant}>{product.variant}</Text>
              <Text style={styles.price}>{formatPrice(product.price)}</Text>
            </View>
            <Icon name="chevron-forward" size={20} color={colors.muted} />
          </Pressable>
        ))}
      </View>
    </Page>
  );
}

const styles = StyleSheet.create({
  list: { gap: spacing.md },
  product: { padding: spacing.md, borderRadius: radius.lg, borderWidth: 1, borderColor: colors.border, backgroundColor: colors.surface, flexDirection: 'row', alignItems: 'center', gap: spacing.md },
  artwork: { width: 88, height: 100, borderRadius: radius.md, alignItems: 'center', justifyContent: 'center' },
  info: { flex: 1, gap: spacing.xs },
  name: { ...typography.label, color: colors.ink },
  variant: { ...typography.caption, color: colors.muted },
  price: { ...typography.subheading, color: colors.ink, marginTop: spacing.xs },
  pressed: { opacity: 0.65 },
});
