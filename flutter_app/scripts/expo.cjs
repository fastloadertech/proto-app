// Keep Expo state, Metro temporary files, and npm cache in this project.
const path = require('node:path');
const fs = require('node:fs');
const { spawnSync } = require('node:child_process');

const root = path.resolve(__dirname, '..');
const temp = path.join(root, '.temp');
fs.mkdirSync(temp, { recursive: true });
const result = spawnSync(process.execPath, [require.resolve('expo/bin/cli'), ...process.argv.slice(2)], {
  cwd: root,
  stdio: 'inherit',
  env: {
    ...process.env,
    EXPO_NO_TELEMETRY: '1',
    EXPO_HOME: path.join(root, '.expo-home'),
    npm_config_cache: path.join(root, '.npm-cache'),
    TEMP: temp,
    TMP: temp,
    TMPDIR: temp,
  },
});
if (result.error) {
  console.error(result.error.message);
}
process.exit(result.status ?? 1);
