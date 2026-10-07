import { useMemo, useState } from 'react';
import { Pressable, ScrollView, StyleSheet, Text, TextInput, View, useWindowDimensions } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import type { CompositeScreenProps } from '@react-navigation/native';
import type { BottomTabScreenProps } from '@react-navigation/bottom-tabs';
import type { NativeStackScreenProps } from '@react-navigation/native-stack';
import { Icon } from '../components/Icon';
import { ProductArtwork } from '../components/ProductArtwork';
import { ProductCard } from '../components/ProductCard';
import { categories, products } from '../data/catalog';
import type { MainTabParamList, RootStackParamList } from '../navigation/types';
import { colors, radius, spacing, typography } from '../theme';

type Props = CompositeScreenProps<BottomTabScreenProps<MainTabParamList, 'Home'>, NativeStackScreenProps<RootStackParamList>>;

export default function HomeScreen({ navigation }: Props) {
  const [query, setQuery] = useState('');
  const { width, fontScale } = useWindowDimensions();
  const compact = width < 370 || fontScale > 1.15;
  const visibleProducts = useMemo(() => {
    const normalized = query.trim().toLowerCase();
    return products.filter((product) => `${product.name} ${product.variant} ${product.category}`.toLowerCase().includes(normalized));
  }, [query]);

  return (
    <SafeAreaView edges={['top', 'left', 'right']} style={styles.screen}>
      <ScrollView keyboardShouldPersistTaps="handled" showsVerticalScrollIndicator={false} contentContainerStyle={styles.scroll}>
        <View style={styles.header}>
          <View accessibilityLabel="PROTO" style={styles.brand}>
            <View style={styles.brandMark}><Icon name="flash" size={18} color={colors.surface} /></View>
            <Text style={styles.wordmark}>PROTO<Text style={styles.brandDot}>.</Text></Text>
          </View>
          <Pressable
            accessibilityRole="button"
            accessibilityLabel="Delivery location: Home, Indiranagar, Bengaluru. Select address"
            onPress={() => navigation.navigate('Address', { mode: 'delivery' })}
            style={({ pressed }) => [styles.location, pressed && styles.pressed]}
          >
            <Text style={styles.deliverTo}>DELIVER TO</Text>
            <View style={styles.locationLine}><Text style={styles.locationText} numberOfLines={1}>Home, Indiranagar</Text><Icon name="chevron-down" size={13} /></View>
          </Pressable>
          <Pressable accessibilityRole="button" accessibilityLabel="Open account" onPress={() => navigation.navigate('Account')} style={styles.account}>
            <Icon name="person-outline" size={21} />
          </Pressable>
        </View>

        <View style={styles.hero}>
          <View style={styles.heroCircle} />
          <View style={styles.heroCopy}>
            <View style={styles.eyebrowRow}><View style={styles.greenDot} /><Text style={styles.eyebrow}>FUEL YOUR EVERYDAY</Text></View>
            <Text accessibilityRole="header" style={styles.heroTitle}>Protein{ '\n' }<Text style={styles.orange}>Delivered</Text><Text style={styles.orange}>.</Text></Text>
            <Text style={styles.heroDescription}>Your everyday nutrition,{ '\n' }delivered fast.</Text>
            <View style={styles.heroPill}><Icon name="leaf-outline" color={colors.sage} size={12} /><Text style={styles.heroPillText}>Good fuel. Great days.</Text></View>
          </View>
          {!compact && <View style={styles.heroArt} pointerEvents="none" accessible={false}>
            <View style={styles.heroShaker}><ProductArtwork kind="shaker" size={110} /></View>
            <View style={styles.heroWhey}><ProductArtwork kind="whey" size={145} /></View>
            <View style={styles.heroBar}><ProductArtwork kind="bar" size={105} /></View>
            <View style={styles.heroSpark}><Icon name="sparkles" size={18} color={colors.sage} /></View>
          </View>}
        </View>

        <View style={styles.search}>
          <Icon name="search-outline" size={22} color={colors.ink} />
          <TextInput
            accessibilityLabel="Search products"
            placeholder="Search protein, eggs, milk & more"
            placeholderTextColor={colors.muted}
            value={query}
            onChangeText={setQuery}
            returnKeyType="search"
            autoCorrect={false}
            style={styles.searchInput}
          />
          {query.length > 0 && <Pressable accessibilityRole="button" accessibilityLabel="Clear search" onPress={() => setQuery('')} style={styles.clearSearch}><Icon name="close-circle" size={20} color={colors.muted} /></Pressable>}
        </View>

        <View style={styles.sectionHeading}>
          <Text accessibilityRole="header" style={styles.sectionTitle}>Shop by category</Text>
          <Text style={styles.sectionNote}>Find your fuel</Text>
        </View>
        <ScrollView horizontal showsHorizontalScrollIndicator={false} contentContainerStyle={styles.categoryList}>
          {categories.map((category, index) => (
            <Pressable key={category.id} accessibilityRole="button" accessibilityLabel={`Shop ${category.name}`} onPress={() => navigation.navigate('Category', { categoryId: category.id })} style={({ pressed }) => [styles.category, pressed && styles.pressed]}>
              <View style={[styles.categoryIcon, { backgroundColor: index % 2 === 0 ? colors.sageSoft : colors.primarySoft }]}>
                <Icon name={category.icon} size={27} color={index % 2 === 0 ? colors.sage : colors.primaryDark} />
              </View>
              <Text style={styles.categoryLabel}>{category.name}</Text>
            </Pressable>
          ))}
        </ScrollView>

        <View style={styles.productHeading}>
          <View style={styles.headingCopy}>
            <Text accessibilityRole="header" style={styles.sectionTitle}>{query.trim() ? 'Your search results' : 'Popular near you'}</Text>
            <Text style={styles.productSubtitle}>{query.trim() ? `${visibleProducts.length} ${visibleProducts.length === 1 ? 'find' : 'finds'} for your everyday` : 'The good stuff, on repeat.'}</Text>
          </View>
          <Pressable accessibilityRole="button" accessibilityLabel="See all categories" onPress={() => navigation.navigate('Categories')} style={styles.seeAll}>
            <Text style={styles.seeAllLabel}>See all</Text><Icon name="arrow-forward" size={16} color={colors.primaryDark} />
          </Pressable>
        </View>

        <View style={styles.grid}>
          {visibleProducts.map((product) => (
            <View key={product.id} style={[styles.gridCell, fontScale > 1.4 && styles.fullCell]}>
              <ProductCard product={product} onPress={() => navigation.navigate('ProductDetails', { productId: product.id })} />
            </View>
          ))}
          {visibleProducts.length === 0 && <View style={styles.empty}>
            <Icon name="search-outline" size={32} color={colors.sage} />
            <Text style={styles.emptyTitle}>A fresh search?</Text>
            <Text style={styles.emptyBody}>Try protein, dairy, or a favourite snack.</Text>
            <Pressable accessibilityRole="button" onPress={() => setQuery('')} style={styles.resetButton}><Text style={styles.seeAllLabel}>Show all products</Text></Pressable>
          </View>}
        </View>

        {!query.trim() && <View style={styles.dailyNote}>
          <View style={styles.noteIcon}><Icon name="fitness-outline" size={26} color={colors.sage} /></View>
          <View style={styles.noteCopy}><Text style={styles.noteTitle}>Small habits. Stronger you.</Text><Text style={styles.noteBody}>Make everyday nutrition your thing.</Text></View>
        </View>}
        <View style={styles.footer}>
          <Text style={styles.footerTitle}>A little stronger,{ '\n' }every day.</Text>
          <View style={styles.footerBrand}><View style={styles.footerLine} /><Text style={styles.footerText}>PROTO · BY FASTLOADER TECHNOLOGIES</Text></View>
        </View>
      </ScrollView>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  screen: { flex: 1, backgroundColor: colors.background },
  scroll: { paddingBottom: spacing.xl, maxWidth: 720, width: '100%', alignSelf: 'center' },
  header: { flexDirection: 'row', alignItems: 'center', paddingHorizontal: spacing.lg, paddingTop: spacing.sm, paddingBottom: spacing.lg, gap: spacing.sm },
  brand: { flexDirection: 'row', alignItems: 'center', gap: spacing.xxs },
  brandMark: { height: 27, width: 24, borderRadius: radius.xs, backgroundColor: colors.primary, alignItems: 'center', justifyContent: 'center', transform: [{ rotate: '-8deg' }] },
  wordmark: { ...typography.wordmark, color: colors.ink },
  brandDot: { color: colors.primary },
  location: { flex: 1, minHeight: 44, justifyContent: 'center', paddingLeft: spacing.xs, borderLeftWidth: 1, borderColor: colors.border },
  deliverTo: { ...typography.micro, color: colors.muted, letterSpacing: 1.4 },
  locationLine: { flexDirection: 'row', alignItems: 'center', gap: spacing.xxs, marginTop: spacing.xxs },
  locationText: { ...typography.caption, color: colors.ink, fontWeight: '700', flexShrink: 1 },
  account: { minWidth: 44, minHeight: 44, borderWidth: 1, borderColor: colors.border, borderRadius: radius.pill, alignItems: 'center', justifyContent: 'center', backgroundColor: colors.surface },
  pressed: { opacity: 0.65 },
  hero: { marginHorizontal: spacing.lg, minHeight: 231, backgroundColor: colors.sageSoft, borderRadius: radius.xl, overflow: 'hidden', padding: spacing.lg },
  heroCircle: { position: 'absolute', right: -70, top: -35, height: 280, width: 230, borderRadius: radius.pill, backgroundColor: colors.wheyBackground, borderWidth: 1, borderColor: colors.surface },
  heroCopy: { zIndex: 2, alignItems: 'flex-start' },
  eyebrowRow: { flexDirection: 'row', alignItems: 'center', gap: spacing.xxs, marginBottom: spacing.sm },
  greenDot: { width: 5, height: 5, backgroundColor: colors.sage, borderRadius: radius.pill },
  eyebrow: { ...typography.micro, letterSpacing: 1.4, color: colors.sage },
  heroTitle: { ...typography.display, color: colors.ink },
  orange: { color: colors.primaryDark },
  heroDescription: { ...typography.bodySmall, color: colors.muted, marginTop: spacing.sm },
  heroPill: { marginTop: spacing.md, flexDirection: 'row', gap: spacing.xxs, alignItems: 'center', backgroundColor: colors.surface, paddingHorizontal: spacing.xs, paddingVertical: spacing.xxs, borderRadius: radius.pill },
  heroPillText: { ...typography.micro, color: colors.sage },
  heroArt: { position: 'absolute', right: -8, top: 49, width: 165, height: 175 },
  heroShaker: { position: 'absolute', right: 0, top: -15, transform: [{ rotate: '12deg' }] },
  heroWhey: { position: 'absolute', right: 17, top: 12, transform: [{ rotate: '-8deg' }] },
  heroBar: { position: 'absolute', right: -4, top: 89, transform: [{ rotate: '10deg' }] },
  heroSpark: { position: 'absolute', right: 27, top: -28 },
  search: { marginHorizontal: spacing.lg, marginTop: spacing.md, minHeight: 56, borderWidth: 1, borderColor: colors.border, borderRadius: radius.md, backgroundColor: colors.surface, flexDirection: 'row', alignItems: 'center', paddingHorizontal: spacing.md, gap: spacing.xs },
  searchInput: { ...typography.search, flex: 1, minWidth: 0, minHeight: 54, color: colors.ink, paddingVertical: spacing.sm },
  clearSearch: { minHeight: 44, minWidth: 32, alignItems: 'center', justifyContent: 'center' },
  sectionHeading: { marginTop: spacing.xl, marginHorizontal: spacing.lg, flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between', gap: spacing.xs, flexWrap: 'wrap' },
  sectionTitle: { ...typography.subheading, color: colors.ink },
  sectionNote: { ...typography.caption, color: colors.muted },
  categoryList: { paddingHorizontal: spacing.lg, paddingTop: spacing.md, paddingBottom: spacing.xs, gap: spacing.md },
  category: { alignItems: 'center', width: 60, gap: spacing.xs },
  categoryIcon: { height: 60, width: 60, borderRadius: radius.lg, alignItems: 'center', justifyContent: 'center' },
  categoryLabel: { ...typography.caption, color: colors.ink, fontWeight: '600' },
  productHeading: { marginHorizontal: spacing.lg, marginTop: spacing.xl, marginBottom: spacing.md, flexDirection: 'row', justifyContent: 'space-between', gap: spacing.xs, alignItems: 'center' },
  headingCopy: { flex: 1 },
  productSubtitle: { ...typography.caption, color: colors.muted, marginTop: spacing.xxs },
  seeAll: { flexDirection: 'row', alignItems: 'center', minHeight: 44, gap: spacing.xxs },
  seeAllLabel: { ...typography.caption, color: colors.primaryDark, fontWeight: '700' },
  grid: { flexDirection: 'row', flexWrap: 'wrap', gap: spacing.sm, paddingHorizontal: spacing.lg },
  gridCell: { width: '47%', flexGrow: 1, flexBasis: '45%', maxWidth: '49%' },
  fullCell: { width: '100%', flexBasis: '100%', maxWidth: '100%' },
  empty: { width: '100%', padding: spacing.xxl, gap: spacing.sm, alignItems: 'center', backgroundColor: colors.surface, borderRadius: radius.lg },
  emptyTitle: { ...typography.subheading, color: colors.ink },
  emptyBody: { ...typography.bodySmall, color: colors.muted, textAlign: 'center' },
  resetButton: { minHeight: 44, justifyContent: 'center' },
  dailyNote: { marginHorizontal: spacing.lg, marginTop: spacing.xl, padding: spacing.md, borderRadius: radius.lg, backgroundColor: colors.sageSoft, flexDirection: 'row', alignItems: 'center', gap: spacing.sm },
  noteIcon: { height: 44, width: 44, borderRadius: radius.md, backgroundColor: colors.surface, alignItems: 'center', justifyContent: 'center' },
  noteCopy: { flex: 1 },
  noteTitle: { ...typography.label, color: colors.ink },
  noteBody: { ...typography.caption, color: colors.sage, marginTop: spacing.xxs },
  footer: { marginHorizontal: spacing.lg, marginTop: spacing.xxxl, marginBottom: spacing.sm },
  footerTitle: { ...typography.footer, color: colors.subtle },
  footerBrand: { flexDirection: 'row', alignItems: 'center', gap: spacing.xs, marginTop: spacing.md },
  footerLine: { height: 1, width: 20, backgroundColor: colors.subtle },
  footerText: { ...typography.micro, letterSpacing: 1, color: colors.muted },
});
