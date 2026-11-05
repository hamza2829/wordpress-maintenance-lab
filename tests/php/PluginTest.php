<?php
use PHPUnit\Framework\TestCase;

final class PluginTest extends TestCase {
    private mixed $previous;
    protected function setUp(): void {
        $this->previous = get_option('wml_contact_settings', null);
        wp_set_current_user(1);
    }
    protected function tearDown(): void {
        if ($this->previous === null) { delete_option('wml_contact_settings'); }
        else { update_option('wml_contact_settings', $this->previous); }
        wp_set_current_user(0);
    }
    public function testDefaultsAreSynthetic(): void {
        self::assertCount(4, wml_defaults());
        self::assertSame('kontakt@example.test', wml_defaults()['email']);
    }
    public function testTextAndPhoneAreSanitized(): void {
        $result = wml_sanitize_settings(array('company' => '<b>Labor</b>', 'phone' => '+49 abc (000)'));
        self::assertSame('Labor', $result['company']);
        self::assertSame('+49  (000)', $result['phone']);
    }
    public function testInvalidEmailUsesDefault(): void {
        self::assertSame(wml_defaults()['email'], wml_sanitize_settings(array('email' => 'javascript:bad'))['email']);
    }
    public function testUnknownFieldsAreDiscarded(): void {
        self::assertArrayNotHasKey('script', wml_sanitize_settings(array('script' => 'bad')));
    }
    public function testNonArraySettingsUseDefaults(): void {
        self::assertSame(wml_defaults(), wml_sanitize_settings('bad'));
    }
    public function testNonStringFieldsUseDefaults(): void {
        self::assertSame(wml_defaults(), wml_sanitize_settings(array('company' => array('bad'), 'email' => array('bad'))));
    }
    public function testShortcodesAreRegistered(): void {
        self::assertTrue(shortcode_exists('nordlicht_kontakt'));
        self::assertTrue(shortcode_exists('nordlicht_formular'));
    }
    public function testShortcodeRendersEscapedContactCard(): void {
        update_option('wml_contact_settings', array('company' => '<b>Labor & Test</b>', 'email' => 'demo@example.test'));
        $html = do_shortcode('[nordlicht_kontakt]');
        self::assertStringContainsString('Labor &amp; Test', $html);
        self::assertStringNotContainsString('<b>', $html);
        self::assertStringContainsString('mailto:demo@example.test', $html);
    }
    public function testFormHasNonceLabelsAndLocalAction(): void {
        $html = do_shortcode('[nordlicht_formular]');
        self::assertStringContainsString('name="wml_nonce"', $html);
        self::assertStringContainsString('for="lab-email"', $html);
        self::assertStringContainsString('admin-post.php', $html);
        self::assertStringContainsString('nicht versendet', $html);
    }
    public function testValidMessageIsSanitized(): void {
        $result = wml_validate_message(array('name' => '<b>Mara Muster</b>', 'email' => 'mara@example.test', 'message' => '<script>bad</script>Hallo Labor'));
        self::assertIsArray($result);
        self::assertSame('Mara Muster', $result['name']);
        self::assertStringNotContainsString('<script>', $result['message']);
    }
    public function testMissingFieldsAreRejected(): void {
        foreach (array('name', 'email', 'message') as $missing) {
            $input = array('name' => 'Mara', 'email' => 'mara@example.test', 'message' => 'Hallo');
            unset($input[$missing]);
            self::assertWPErrorResult(wml_validate_message($input));
        }
    }
    public function testInvalidEmailIsRejected(): void {
        self::assertWPErrorResult(wml_validate_message(array('name' => 'Mara', 'email' => 'invalid', 'message' => 'Hallo')));
    }
    public function testHoneypotIsRejected(): void {
        self::assertWPErrorResult(wml_validate_message(array('website' => 'spam')));
    }
    public function testLongMessageIsRejected(): void {
        self::assertWPErrorResult(wml_validate_message(array('name' => 'Mara', 'email' => 'mara@example.test', 'message' => str_repeat('x', 3001))));
    }
    public function testSettingsRegistrationUsesSanitizer(): void {
        wml_register_settings();
        global $wp_registered_settings;
        self::assertSame('wml_sanitize_settings', $wp_registered_settings['wml_contact_settings']['sanitize_callback']);
    }
    public function testAdminSettingsContainNonceAndFields(): void {
        ob_start();
        wml_settings_page();
        $html = ob_get_clean();
        self::assertStringContainsString('options.php', $html);
        self::assertStringContainsString('_wpnonce', $html);
        self::assertStringContainsString('wml_contact_settings[email]', $html);
    }
    private static function assertWPErrorResult(mixed $value): void {
        self::assertInstanceOf(WP_Error::class, $value);
    }
}
