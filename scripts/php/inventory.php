<?php
// Canonical content inventory, independent of runtime transients and timestamps.
global $wpdb;
$rows = $wpdb->get_results("SELECT ID, post_type, post_status, post_name, post_title, post_content, post_excerpt, post_parent, menu_order FROM {$wpdb->posts} WHERE post_type IN ('post','page') ORDER BY ID", ARRAY_A);
$counts = array('post' => 0, 'page' => 0);
foreach ($rows as $row) { ++$counts[$row['post_type']]; }
echo wp_json_encode(array('counts' => $counts, 'content_sha256' => hash('sha256', wp_json_encode($rows, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES))), JSON_PRETTY_PRINT) . "\n";
