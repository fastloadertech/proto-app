import type { PropsWithChildren } from 'react';
import { Pressable, ScrollView, StyleSheet, Text, View } from 'react-native';
import type { ComponentProps } from 'react';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { Icon } from '../components/Icon';
import { colors, radius, spacing, typography } from '../theme';

export function Page({ children }: PropsWithChildren) {
  const insets = useSafeAreaInsets();

  return (
    <ScrollView style={styles.page} contentContainerStyle={[styles.pageContent, { paddingBottom: Math.max(spacing.xxxl, insets.bottom + spacing.xl) }]}>
      {children}
    </ScrollView>
  );
}

export function PageIntro({ eyebrow, title, description }: {
  eyebrow?: string;
  title: string;
  description?: string;
}) {
  return (
    <View style={styles.intro}>
      {eyebrow ? <Text style={styles.eyebrow}>{eyebrow}</Text> : null}
      <Text style={styles.title}>{title}</Text>
      {description ? <Text style={styles.description}>{description}</Text> : null}
    </View>
  );
}

export function ActionButton({ label, onPress, disabled = false, secondary = false }: {
  label: string;
  onPress: () => void;
  disabled?: boolean;
  secondary?: boolean;
}) {
  return (
    <Pressable
      accessibilityRole="button"
      accessibilityLabel={label}
      accessibilityState={{ disabled }}
      disabled={disabled}
      onPress={onPress}
      style={({ pressed }) => [
        styles.action,
        secondary && styles.secondaryAction,
        disabled && styles.disabledAction,
        pressed && styles.pressed,
      ]}
    >
      <Text style={[styles.actionLabel, secondary && styles.secondaryLabel]}>{label}</Text>
      <Icon name="arrow-forward" size={18} color={secondary ? colors.ink : colors.surface} />
    </Pressable>
  );
}

export function EmptyState({ icon, title, description, action, onAction }: {
  icon: ComponentProps<typeof Icon>['name'];
  title: string;
  description: string;
  action?: string;
  onAction?: () => void;
}) {
  return (
    <View style={styles.empty}>
      <View style={styles.emptyIcon}><Icon name={icon} size={32} color={colors.primary} /></View>
      <Text style={styles.emptyTitle}>{title}</Text>
      <Text style={styles.emptyDescription}>{description}</Text>
      {action && onAction ? <ActionButton label={action} onPress={onAction} /> : null}
    </View>
  );
}

export function SummaryRow({ label, value, strong = false }: {
  label: string;
  value: string;
  strong?: boolean;
}) {
  return (
    <View style={styles.summaryRow}>
      <Text style={strong ? styles.summaryStrong : styles.summaryText}>{label}</Text>
      <Text style={strong ? styles.summaryStrong : styles.summaryValue}>{value}</Text>
    </View>
  );
}

export const screenStyles = StyleSheet.create({
  card: {
    backgroundColor: colors.surface,
    borderWidth: 1,
    borderColor: colors.border,
    borderRadius: radius.lg,
    padding: spacing.lg,
    gap: spacing.md,
  },
  note: { ...typography.bodySmall, color: colors.muted },
  sectionTitle: { ...typography.subheading, color: colors.ink },
  divider: { height: 1, backgroundColor: colors.border },
});

const styles = StyleSheet.create({
  page: { flex: 1, backgroundColor: colors.background },
  pageContent: { padding: spacing.screen, paddingBottom: spacing.xxxl, gap: spacing.xl },
  intro: { gap: spacing.sm },
  eyebrow: { ...typography.eyebrow, color: colors.primary },
  title: { ...typography.title, color: colors.ink },
  description: { ...typography.body, color: colors.muted },
  action: {
    minHeight: 54,
    borderRadius: radius.md,
    backgroundColor: colors.primary,
    paddingHorizontal: spacing.lg,
    paddingVertical: spacing.md,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    gap: spacing.md,
  },
  secondaryAction: { backgroundColor: colors.primarySoft },
  disabledAction: { opacity: 0.42 },
  pressed: { opacity: 0.75 },
  actionLabel: { ...typography.label, color: colors.surface, flexShrink: 1 },
  secondaryLabel: { color: colors.ink },
  empty: { gap: spacing.lg, paddingVertical: spacing.xxl },
  emptyIcon: {
    width: 76,
    height: 76,
    alignItems: 'center',
    justifyContent: 'center',
    borderRadius: radius.xl,
    backgroundColor: colors.primarySoft,
  },
  emptyTitle: { ...typography.heading, color: colors.ink },
  emptyDescription: { ...typography.body, color: colors.muted },
  summaryRow: { flexDirection: 'row', justifyContent: 'space-between', gap: spacing.md },
  summaryText: { ...typography.bodySmall, color: colors.muted, flexShrink: 1 },
  summaryValue: { ...typography.label, color: colors.ink },
  summaryStrong: { ...typography.subheading, color: colors.ink },
});
