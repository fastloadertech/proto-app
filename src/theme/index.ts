import { Platform, type TextStyle, type ViewStyle } from 'react-native';

// Central palette: PROTO's orange is provisional until an approved brand swatch is supplied.
export const colors = {
  primary: '#F46A25',
  primaryDark: '#C64309',
  primarySoft: '#FFF0E7',
  ink: '#20251F',
  muted: '#71796E',
  subtle: '#969D93',
  text: '#20251F',
  textSecondary: '#71796E',
  textMuted: '#969D93',
  background: '#FAFBF8',
  surface: '#FFFFFF',
  border: '#E9ECE5',
  sage: '#446D43',
  sageSoft: '#EAF0E4',
  success: '#446D43',
  danger: '#B83D32',
  shadow: '#20251F',
  wheyBackground: '#EDF1E8',
  barBackground: '#F5EDE4',
  yogurtBackground: '#EEF1F7',
  eggsBackground: '#F7EFE3',
  milkBackground: '#ECF3F4',
  paneerBackground: '#F2F2E6',
  shakeBackground: '#F3E9E1',
  shakerBackground: '#E9EEE7',
} as const;

export const spacing = {
  xxs: 4,
  xs: 8,
  sm: 12,
  md: 16,
  lg: 20,
  xl: 24,
  xxl: 32,
  xxxl: 40,
  screen: 24,
} as const;

export const radius = {
  xs: 8,
  sm: 12,
  md: 16,
  lg: 20,
  xl: 24,
  xxl: 32,
  pill: 999,
  full: 999,
} as const;

const fontFamily = Platform.select({
  ios: 'System',
  android: 'sans-serif',
  default: 'system-ui',
});

export const typography = {
  wordmark: { fontFamily, fontSize: 24, fontWeight: '900', letterSpacing: -1 },
  display: { fontFamily, fontSize: 34, lineHeight: 37, fontWeight: '800', letterSpacing: -1.4 },
  hero: { fontFamily, fontSize: 42, lineHeight: 46, fontWeight: '800', letterSpacing: -1.8 },
  title: { fontFamily, fontSize: 30, lineHeight: 36, fontWeight: '800', letterSpacing: -0.9 },
  heading: { fontFamily, fontSize: 22, lineHeight: 28, fontWeight: '700', letterSpacing: -0.6 },
  subheading: { fontFamily, fontSize: 18, lineHeight: 24, fontWeight: '700', letterSpacing: -0.3 },
  body: { fontFamily, fontSize: 15, lineHeight: 22, fontWeight: '400' },
  bodySmall: { fontFamily, fontSize: 13, lineHeight: 19, fontWeight: '400' },
  label: { fontFamily, fontSize: 14, lineHeight: 20, fontWeight: '600' },
  caption: { fontFamily, fontSize: 12, lineHeight: 17, fontWeight: '500' },
  eyebrow: { fontFamily, fontSize: 10, lineHeight: 15, fontWeight: '700', letterSpacing: 1.8 },
  micro: { fontFamily, fontSize: 9, lineHeight: 12, fontWeight: '700' },
  footer: { fontFamily, fontSize: 28, lineHeight: 34, fontWeight: '800', letterSpacing: -0.8 },
  search: { fontFamily, fontSize: 13, lineHeight: 20, fontWeight: '400' },
} satisfies Record<string, TextStyle>;

export const shadows = {
  subtle: {
    shadowColor: colors.shadow,
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.03,
    shadowRadius: 6,
    elevation: 1,
  },
  card: {
    shadowColor: colors.shadow,
    shadowOffset: { width: 0, height: 4 },
    shadowOpacity: 0.04,
    shadowRadius: 12,
    elevation: 2,
  },
  floating: {
    shadowColor: colors.shadow,
    shadowOffset: { width: 0, height: 5 },
    shadowOpacity: 0.08,
    shadowRadius: 18,
    elevation: 5,
  },
} satisfies Record<string, ViewStyle>;

export const theme = { colors, typography, spacing, radius, shadows } as const;
