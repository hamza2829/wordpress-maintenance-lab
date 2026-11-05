const { defineConfig } = require('@playwright/test');
const path = require('path');
const phase = process.env.TEST_PHASE || 'manual';
const report = path.join('artifacts', 'playwright', phase);
module.exports = defineConfig({
  testDir: './tests/browser',
  fullyParallel: false,
  workers: 1,
  retries: 0,
  timeout: 30000,
  reporter: [['list'], ['html', { outputFolder: path.join(report, 'html'), open: 'never' }], ['junit', { outputFile: path.join(report, 'junit.xml') }]],
  outputDir: path.join(report, 'results'),
  use: { baseURL: process.env.BASE_URL || 'http://127.0.0.1:8080', browserName: 'chromium', screenshot: 'on', trace: 'retain-on-failure', viewport: { width: 1280, height: 900 } }
});
