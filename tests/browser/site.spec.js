const { test: base, expect } = require('@playwright/test');
const AxeBuilder = require('@axe-core/playwright').default;
const fs = require('fs');
const path = require('path');
const test = base.extend({
  page: async ({ page }, use) => {
    const errors = [];
    page.on('pageerror', error => errors.push(error.message));
    page.on('console', message => { if (message.type() === 'error') errors.push(message.text()); });
    await use(page);
    expect(errors, 'No JavaScript or browser console errors').toEqual([]);
  }
});

test('home page loads with a title and one main heading', async ({ page }) => {
  const response = await page.goto('/');
  expect(response.status()).toBe(200);
  await expect(page).toHaveTitle(/Nordlicht Reparaturatelier/);
  await expect(page.getByRole('heading', { level: 1 })).toHaveText('Reparieren lohnt sich.');
  await expect(page.locator('html')).toHaveAttribute('lang', /de/);
  fs.mkdirSync('artifacts/screenshots', { recursive: true });
  await page.screenshot({ path: path.join('artifacts/screenshots', `${process.env.TEST_PHASE || 'manual'}-home.png`), fullPage: true });
});

test('all main menu links reach their pages', async ({ page }) => {
  for (const [label, url] of [['Start', '/'], ['Leistungen', '/leistungen/'], ['Journal', '/journal/'], ['Kontakt', '/kontakt/']]) {
    await page.goto('/');
    await page.getByRole('navigation', { name: 'Hauptnavigation' }).getByRole('link', { name: label, exact: true }).click();
    await expect(page).toHaveURL(new RegExp(`${url.replaceAll('/', '\\/')}$`));
    await expect(page.getByRole('main')).toBeVisible();
  }
});

test('shortcode renders escaped synthetic contact information', async ({ page }) => {
  await page.goto('/kontakt/');
  const contact = page.getByRole('region', { name: 'Kontaktinformationen' });
  await expect(contact).toContainText('Nordlicht Reparaturatelier');
  await expect(contact.getByRole('link', { name: 'kontakt@example.test' })).toHaveAttribute('href', 'mailto:kontakt@example.test');
  await expect(page.locator('body')).not.toContainText('[nordlicht_');
});

test('contact form stores a synthetic message and shows confirmation', async ({ page }) => {
  await page.goto('/kontakt/');
  await page.getByLabel('Name', { exact: true }).fill('Mara Muster');
  await page.getByLabel('E-Mail', { exact: true }).fill('mara@example.test');
  await page.getByLabel('Nachricht', { exact: true }).fill('Synthetische Anfrage aus dem automatisierten Wartungslabor.');
  await page.getByRole('button', { name: 'Laboranfrage speichern' }).click();
  await expect(page).toHaveURL(/\/kontakt\/#lab-sent$/);
  await expect(page.getByRole('status').filter({ hasText: 'synthetische Anfrage' })).toBeVisible();
});

test('contact submission without a nonce is rejected', async ({ request, page }) => {
  await page.goto('/kontakt/');
  const response = await request.post('/wp-admin/admin-post.php', { form: { action: 'wml_contact', name: 'Mara', email: 'mara@example.test', message: 'Ungültige Testanfrage' } });
  expect(response.status()).toBe(403);
});

test('front pages have no PHP error text and valid document titles', async ({ page }) => {
  for (const url of ['/', '/leistungen/', '/journal/', '/kontakt/']) {
    expect((await page.goto(url)).status()).toBe(200);
    await expect(page).toHaveTitle(/Nordlicht/);
    expect(await page.locator('body').innerText()).not.toMatch(/Fatal error|Parse error|Warning:|Notice:/i);
  }
});

test('basic automated accessibility checks pass', async ({ page }) => {
  for (const url of ['/', '/kontakt/']) {
    await page.goto(url);
    const result = await new AxeBuilder({ page }).withTags(['wcag2a', 'wcag2aa', 'wcag21a', 'wcag21aa']).analyze();
    expect(result.violations).toEqual([]);
  }
});

test('keyboard skip link and small JavaScript interaction work', async ({ page }) => {
  await page.goto('/');
  await page.keyboard.press('Tab');
  await expect(page.getByRole('link', { name: 'Zum Inhalt' })).toBeFocused();
  await page.keyboard.press('Enter');
  await expect(page.getByRole('main')).toBeFocused();
  const button = page.getByRole('button', { name: 'Laborhinweis anzeigen' });
  await button.click();
  await expect(button).toHaveAttribute('aria-expanded', 'true');
  await expect(page.locator('#lab-hint')).toBeVisible();
});

test('plugin settings page works for the lab administrator', async ({ page }) => {
  await page.goto('/wp-login.php');
  await page.locator('#user_login').fill('labadmin');
  await page.locator('#user_pass').fill('synthetic-lab-password-only');
  await page.locator('#wp-submit').click();
  await page.goto('/wp-admin/options-general.php?page=nordlicht-lab');
  await expect(page.getByRole('heading', { name: 'Nordlicht Labor', exact: true })).toBeVisible();
  await expect(page.locator('#wml-email')).toHaveValue('kontakt@example.test');
  await page.locator('#submit').click();
  await expect(page.locator('#wml-company')).toHaveValue('Nordlicht Reparaturatelier');
});
