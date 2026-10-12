import type { NativeStackScreenProps } from '@react-navigation/native-stack';
import { StyleSheet, Text, View } from 'react-native';
import { Icon } from '../components/Icon';
import { formatPrice } from '../data/catalog';
import type { RootStackParamList } from '../navigation/types';
import { useCart } from '../state/cart';
import { colors, radius, spacing, typography } from '../theme';
import { ActionButton, Page, screenStyles, SummaryRow } from './ScreenParts';

export default function OrderConfirmationScreen({ navigation }: NativeStackScreenProps<RootStackParamList, 'OrderConfirmation'>) {
  const { totalCount, subtotal } = useCart();

  return (
    <Page>
      <View style={styles.message}>
        <View style={styles.icon}><Icon name="checkmark" size={44} color={colors.sage} /></View>
        <Text style={styles.eyebrow}>PROTO PREVIEW</Text>
        <Text style={styles.title}>Good fuel. Great choice.</Text>
        <Text style={styles.description}>This is a demo confirmation. No order was placed, and no delivery has been scheduled.</Text>
      </View>
      <View style={screenStyles.card}>
        <SummaryRow label="Items in your preview" value={String(totalCount)} />
        <SummaryRow label="Items subtotal" value={formatPrice(subtotal)} />
        <Text style={screenStyles.note}>Your basket is saved for this session. Come back and make it yours.</Text>
      </View>
      <ActionButton label="Continue browsing" onPress={() => navigation.reset({ index: 0, routes: [{ name: 'Main', params: { screen: 'Home' } }] })} />
    </Page>
  );
}

const styles = StyleSheet.create({
  message: { alignItems: 'center', gap: spacing.lg, paddingVertical: spacing.xl },
  icon: { width: 96, height: 96, borderRadius: radius.xxl, backgroundColor: colors.sageSoft, justifyContent: 'center', alignItems: 'center' },
  eyebrow: { ...typography.eyebrow, color: colors.sage },
  title: { ...typography.title, color: colors.ink, textAlign: 'center' },
  description: { ...typography.body, color: colors.muted, textAlign: 'center' },
});
