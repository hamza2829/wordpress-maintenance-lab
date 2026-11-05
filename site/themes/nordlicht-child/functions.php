<?php
/**
 * Child theme assets.
 *
 * @package NordlichtChild
 */

/**
 * Load the child assets after the parent theme assets.
 *
 * @return void
 */
function wml_child_assets() {
	wp_enqueue_style( 'nordlicht-child', get_stylesheet_uri(), array( 'twenty-twenty-one-style' ), '1.0.0' );
	wp_dequeue_script( 'twenty-twenty-one-primary-navigation-script' );
	wp_enqueue_script( 'nordlicht-lab', get_stylesheet_directory_uri() . '/lab.js', array(), '1.0.0', true );
}
add_action( 'wp_enqueue_scripts', 'wml_child_assets', 20 );
