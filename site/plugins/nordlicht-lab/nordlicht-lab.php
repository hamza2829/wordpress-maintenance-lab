<?php
/**
 * Plugin Name: Nordlicht Labor
 * Description: Synthetische Kontaktkarte, Laborformular und Einstellungen.
 * Version: 1.0.0
 * Text Domain: nordlicht-lab
 *
 * @package NordlichtLab
 */

if ( ! defined( 'ABSPATH' ) ) {
	exit;
}

/**
 * Return the synthetic defaults.
 *
 * @return array
 */
function wml_defaults() {
	return array(
		'company' => 'Nordlicht Reparaturatelier',
		'email'   => 'kontakt@example.test',
		'phone'   => '+49 000 123456',
		'hours'   => 'Montag bis Freitag, 10 bis 17 Uhr',
	);
}

/**
 * Sanitize the settings and discard unknown fields.
 *
 * @param mixed $input Submitted settings.
 * @return array
 */
function wml_sanitize_settings( $input ) {
	$defaults = wml_defaults();
	if ( ! is_array( $input ) ) {
		return $defaults;
	}
	$output = $defaults;
	foreach ( array( 'company', 'hours' ) as $key ) {
		if ( isset( $input[ $key ] ) && is_string( $input[ $key ] ) ) {
			$output[ $key ] = sanitize_text_field( $input[ $key ] );
		}
	}
	if ( isset( $input['email'] ) && is_string( $input['email'] ) ) {
		$email = sanitize_email( $input['email'] );
		if ( is_email( $email ) ) {
			$output['email'] = $email;
		}
	}
	if ( isset( $input['phone'] ) && is_string( $input['phone'] ) ) {
		$output['phone'] = preg_replace( '/[^0-9+() -]/', '', $input['phone'] );
	}
	return $output;
}

/**
 * Render the escaped contact shortcode.
 *
 * @return string
 */
function wml_contact_shortcode() {
	$settings = wml_sanitize_settings( get_option( 'wml_contact_settings', array() ) );
	return '<section class="nordlicht-contact" aria-label="' . esc_attr__( 'Kontaktinformationen', 'nordlicht-lab' ) . '"><h2>'
		. esc_html( $settings['company'] ) . '</h2><p>' . esc_html( $settings['hours'] ) . '</p><p><a href="'
		. esc_url( 'mailto:' . $settings['email'] ) . '">' . esc_html( $settings['email'] ) . '</a><br>'
		. esc_html( $settings['phone'] ) . '</p></section>';
}
add_shortcode( 'nordlicht_kontakt', 'wml_contact_shortcode' );

/**
 * Register settings using the native Settings API.
 *
 * @return void
 */
function wml_register_settings() {
	register_setting( 'wml_settings', 'wml_contact_settings', array( 'sanitize_callback' => 'wml_sanitize_settings', 'type' => 'array' ) );
}
add_action( 'admin_init', 'wml_register_settings' );

/**
 * Add the settings page.
 *
 * @return void
 */
function wml_settings_menu() {
	add_options_page( __( 'Nordlicht Labor', 'nordlicht-lab' ), __( 'Nordlicht Labor', 'nordlicht-lab' ), 'manage_options', 'nordlicht-lab', 'wml_settings_page' );
}
add_action( 'admin_menu', 'wml_settings_menu' );

/**
 * Render settings for authorized administrators.
 *
 * @return void
 */
function wml_settings_page() {
	if ( ! current_user_can( 'manage_options' ) ) {
		wp_die( esc_html__( 'Keine Berechtigung.', 'nordlicht-lab' ) );
	}
	$settings = wml_sanitize_settings( get_option( 'wml_contact_settings', array() ) );
	$labels   = array(
		'company' => __( 'Betriebsname', 'nordlicht-lab' ),
		'email'   => __( 'E-Mail', 'nordlicht-lab' ),
		'phone'   => __( 'Telefon', 'nordlicht-lab' ),
		'hours'   => __( 'Öffnungszeiten', 'nordlicht-lab' ),
	);
	?>
	<div class="wrap">
		<h1><?php esc_html_e( 'Nordlicht Labor', 'nordlicht-lab' ); ?></h1>
		<p><?php esc_html_e( 'Nur synthetische Angaben verwenden. Es wird keine E-Mail versendet.', 'nordlicht-lab' ); ?></p>
		<form action="options.php" method="post">
			<?php settings_fields( 'wml_settings' ); ?>
			<table class="form-table" role="presentation">
			<?php foreach ( $labels as $key => $label ) : ?>
				<tr><th scope="row"><label for="wml-<?php echo esc_attr( $key ); ?>"><?php echo esc_html( $label ); ?></label></th>
				<td><input class="regular-text" id="wml-<?php echo esc_attr( $key ); ?>" name="wml_contact_settings[<?php echo esc_attr( $key ); ?>]" value="<?php echo esc_attr( $settings[ $key ] ); ?>" type="<?php echo 'email' === $key ? 'email' : 'text'; ?>"></td></tr>
			<?php endforeach; ?>
			</table>
			<?php submit_button(); ?>
		</form>
	</div>
	<?php
}

/**
 * Validate a synthetic contact message.
 *
 * @param array $input Submitted fields.
 * @return array|WP_Error
 */
function wml_validate_message( $input ) {
	if ( ! is_array( $input ) || ! empty( $input['website'] ) ) {
		return new WP_Error( 'invalid', __( 'Ungültige Laboranfrage.', 'nordlicht-lab' ) );
	}
	foreach ( array( 'name', 'email', 'message' ) as $field ) {
		if ( ! isset( $input[ $field ] ) || ! is_string( $input[ $field ] ) || '' === trim( $input[ $field ] ) ) {
			return new WP_Error( 'required', __( 'Bitte alle Pflichtfelder ausfüllen.', 'nordlicht-lab' ) );
		}
	}
	$email = sanitize_email( $input['email'] );
	if ( ! is_email( $email ) || strlen( $input['message'] ) > 3000 ) {
		return new WP_Error( 'invalid', __( 'Bitte E-Mail und Nachrichtenlänge prüfen.', 'nordlicht-lab' ) );
	}
	return array( 'name' => sanitize_text_field( $input['name'] ), 'email' => $email, 'message' => sanitize_textarea_field( $input['message'] ) );
}

/**
 * Render the nonce-protected synthetic contact form.
 *
 * @return string
 */
function wml_form_shortcode() {
	ob_start();
	?>
	<form class="lab-form" method="post" action="<?php echo esc_url( admin_url( 'admin-post.php' ) ); ?>">
		<input type="hidden" name="action" value="wml_contact">
		<?php wp_nonce_field( 'wml_contact', 'wml_nonce' ); ?>
		<label for="lab-name"><?php esc_html_e( 'Name', 'nordlicht-lab' ); ?></label><input id="lab-name" name="name" autocomplete="name" required maxlength="100">
		<label for="lab-email"><?php esc_html_e( 'E-Mail', 'nordlicht-lab' ); ?></label><input id="lab-email" name="email" type="email" autocomplete="email" required>
		<label for="lab-message"><?php esc_html_e( 'Nachricht', 'nordlicht-lab' ); ?></label><textarea id="lab-message" name="message" rows="5" maxlength="3000" required></textarea>
		<div class="lab-honeypot" aria-hidden="true"><label for="lab-website">Website</label><input id="lab-website" name="website" tabindex="-1" autocomplete="off"></div>
		<p><?php esc_html_e( 'Nur erfundene Daten eingeben. Die Nachricht wird im Labor gespeichert, aber nicht versendet.', 'nordlicht-lab' ); ?></p>
		<button type="submit"><?php esc_html_e( 'Laboranfrage speichern', 'nordlicht-lab' ); ?></button>
	</form>
	<p id="lab-sent" class="lab-notice" role="status" hidden><?php esc_html_e( 'Die synthetische Anfrage wurde im Labor gespeichert.', 'nordlicht-lab' ); ?></p>
	<p id="lab-error" class="lab-notice" role="status" hidden><?php esc_html_e( 'Die Anfrage konnte nicht gespeichert werden.', 'nordlicht-lab' ); ?></p>
	<?php
	return ob_get_clean();
}
add_shortcode( 'nordlicht_formular', 'wml_form_shortcode' );

/**
 * Store a validated lab message without sending mail.
 *
 * @return void
 */
function wml_handle_contact() {
	check_admin_referer( 'wml_contact', 'wml_nonce' );
	$message = wml_validate_message( wp_unslash( $_POST ) );
	if ( is_wp_error( $message ) ) {
		wp_safe_redirect( home_url( '/kontakt/#lab-error' ) );
		exit;
	}
	update_option( 'wml_last_contact', $message, false );
	wp_safe_redirect( home_url( '/kontakt/#lab-sent' ) );
	exit;
}
add_action( 'admin_post_wml_contact', 'wml_handle_contact' );
add_action( 'admin_post_nopriv_wml_contact', 'wml_handle_contact' );
