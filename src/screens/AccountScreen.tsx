import { Text, View } from 'react-native';
import { EmptyState, Page, screenStyles } from './ScreenParts';

export default function AccountScreen() {
  return (
    <Page>
      <EmptyState icon="person-outline" title="Your space. Your pace." description="Your profile, saved addresses, and everyday favourites will have a home here soon." />
      <View style={screenStyles.card}>
        <Text style={screenStyles.sectionTitle}>PROTO · Protein Delivered</Text>
        <Text style={screenStyles.note}>A fresh way to fuel your everyday. Part of FastLoader Technologies.</Text>
      </View>
    </Page>
  );
}
