<?php
/**
 * Site header.
 *
 * @package NordlichtChild
 */

?>
<!doctype html>
<html <?php language_attributes(); ?>>
<head>
<meta charset="<?php bloginfo( 'charset' ); ?>">
<meta name="viewport" content="width=device-width, initial-scale=1">
<link rel="icon" href="data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 32 32'%3E%3Crect width='32' height='32' rx='6' fill='%23244e3d'/%3E%3Cpath d='M9 24V8l14 16V8' stroke='white' stroke-width='3' fill='none'/%3E%3C/svg%3E">
<?php wp_head(); ?>
</head>
<body <?php body_class(); ?>>
<?php wp_body_open(); ?>
<a class="skip-link" href="#main"><?php esc_html_e( 'Zum Inhalt', 'nordlicht-child' ); ?></a>
<header class="lab-header">
	<div class="lab-wrap">
		<a class="lab-brand" href="<?php echo esc_url( home_url( '/' ) ); ?>">Nordlicht<span><?php esc_html_e( 'Reparaturatelier · Laborseite', 'nordlicht-child' ); ?></span></a>
		<nav aria-label="<?php esc_attr_e( 'Hauptnavigation', 'nordlicht-child' ); ?>">
			<?php
			wp_nav_menu(
				array(
					'theme_location' => 'primary',
					'container'      => false,
					'fallback_cb'    => false,
				)
			);
			?>
		</nav>
	</div>
</header>
