<?php
require_once ABSPATH . 'wp-admin/includes/plugin.php';
$dolly = get_plugin_data(WP_PLUGIN_DIR . '/hello-dolly/hello.php', false, false);
echo wp_json_encode(array('core' => get_bloginfo('version'), 'hello_dolly' => $dolly['Version'], 'parent_theme' => wp_get_theme('twentytwentyone')->get('Version'), 'child_theme' => wp_get_theme()->get_stylesheet()), JSON_PRETTY_PRINT) . "\n";
