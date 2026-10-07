import { useNavigation } from '@react-navigation/native';
import type { NativeStackNavigationProp } from '@react-navigation/native-stack';
import { Pressable, StyleSheet, Text, View } from 'react-native';
import { Icon } from '../components/Icon';
import { categories, products } from '../data/catalog';
import type { RootStackParamList } from '../navigation/types';
import { colors, radius, spacing, typography } from '../theme';
import { Page, PageIntro } from './ScreenParts';

export default function CategoriesScreen() {
  const navigation = useNavigation<NativeStackNavigationProp<RootStackParamList>>();

  return (
    <Page>
      <PageIntro eyebrow="FIND YOUR EVERYDAY FUEL" title="Good things, by category." description="From breakfast essentials to your next personal best." />
      <View style={styles.list}>
        {categories.map((category) => (
          <Pressable
            key={category.id}
            accessibilityRole="button"
            accessibilityLabel={`Browse ${category.name}`}
            onPress={() => navigation.navigate('Category', { categoryId: category.id })}
            style={({ pressed }) => [styles.row, pressed && styles.pressed]}
          >
            <View style={styles.icon}><Icon name={category.icon} size={26} color={colors.primary} /></View>
            <View style={styles.text}>
              <Text style={styles.name}>{category.name}</Text>
              <Text style={styles.count}>{products.filter((product) => product.category === category.id).length} essentials to explore</Text>
            </View>
            <Icon name="chevron-forward" size={20} color={colors.muted} />
          </Pressable>
        ))}
      </View>
    </Page>
  );
}

const styles = StyleSheet.create({
  list: { gap: spacing.sm },
  row: { minHeight: 86, flexDirection: 'row', alignItems: 'center', gap: spacing.md, padding: spacing.md, backgroundColor: colors.surface, borderRadius: radius.lg, borderWidth: 1, borderColor: colors.border },
  icon: { width: 52, height: 52, borderRadius: radius.md, backgroundColor: colors.primarySoft, alignItems: 'center', justifyContent: 'center' },
  text: { flex: 1, gap: spacing.xs },
  name: { ...typography.subheading, color: colors.ink },
  count: { ...typography.caption, color: colors.muted },
  pressed: { opacity: 0.65 },
});
