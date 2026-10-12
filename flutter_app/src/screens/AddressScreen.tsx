import { useState } from 'react';
import type { NativeStackScreenProps } from '@react-navigation/native-stack';
import { Pressable, StyleSheet, Text, View } from 'react-native';
import { Icon } from '../components/Icon';
import type { RootStackParamList } from '../navigation/types';
import { colors, radius, spacing, typography } from '../theme';
import { ActionButton, Page, PageIntro, screenStyles } from './ScreenParts';

export default function AddressScreen({ navigation, route }: NativeStackScreenProps<RootStackParamList, 'Address'>) {
  const [selected, setSelected] = useState(false);
  const isCheckout = route.params?.mode === 'checkout';

  return (
    <Page>
      <PageIntro eyebrow="A LITTLE CLOSER TO YOU" title="Where should we deliver?" description="Choose the sample location to explore your delivery experience." />
      <Pressable accessibilityRole="radio" accessibilityState={{ selected }} accessibilityLabel="Select Home, Indiranagar, Bengaluru" onPress={() => setSelected(true)} style={({ pressed }) => [styles.address, selected && styles.selected, pressed && styles.pressed]}>
        <View style={styles.homeIcon}><Icon name="home-outline" size={24} color={colors.primary} /></View>
        <View style={styles.addressText}>
          <Text style={styles.name}>Home</Text>
          <Text style={styles.location}>Indiranagar, Bengaluru</Text>
          <Text style={styles.sample}>Sample delivery address</Text>
        </View>
        <Icon name={selected ? 'radio-button-on' : 'radio-button-off'} size={22} color={selected ? colors.primary : colors.subtle} />
      </Pressable>
      <ActionButton label={isCheckout ? 'Continue to checkout' : 'Use this location'} disabled={!selected} onPress={() => isCheckout ? navigation.navigate('Checkout') : navigation.goBack()} />
      <Text style={screenStyles.note}>More address options are coming soon.</Text>
    </Page>
  );
}

const styles = StyleSheet.create({
  address: { flexDirection: 'row', alignItems: 'center', padding: spacing.lg, gap: spacing.md, borderRadius: radius.lg, borderWidth: 1, borderColor: colors.border, backgroundColor: colors.surface },
  selected: { borderColor: colors.primary, backgroundColor: colors.primarySoft },
  homeIcon: { alignSelf: 'flex-start', paddingTop: spacing.xs },
  addressText: { flex: 1, gap: spacing.xs },
  name: { ...typography.subheading, color: colors.ink },
  location: { ...typography.bodySmall, color: colors.ink },
  sample: { ...typography.caption, color: colors.muted },
  pressed: { opacity: 0.65 },
});
