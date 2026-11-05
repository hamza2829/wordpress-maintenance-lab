<?php
// Run only through WP-CLI in the disposable lab.
$existing = get_posts(array('post_type' => array('post', 'page'), 'post_status' => 'any', 'numberposts' => -1));
foreach ($existing as $item) { wp_delete_post($item->ID, true); }
$pages = array(
    'start' => array('Reparieren lohnt sich.', '<p class="lab-lead">Wir geben vertrauten Dingen eine zweite Runde. Das Nordlicht Reparaturatelier ist ein erfundener kleiner Betrieb in einer synthetischen Nachbarschaft.</p><div class="lab-grid"><section class="lab-card"><h2>Prüfen</h2><p>Wir schauen genau hin und erklären verständlich, was noch möglich ist.</p></section><section class="lab-card"><h2>Reparieren</h2><p>Wir planen kleine, nachvollziehbare Schritte für die weitere Nutzung.</p></section><section class="lab-card"><h2>Bewahren</h2><p>Wir erzählen, wie sich gute Dinge länger erhalten lassen.</p></section></div><div class="lab-banner"><h2>Ein guter Anfang: miteinander sprechen.</h2><p><a href="/kontakt/">Zur synthetischen Kontaktseite</a></p></div>[nordlicht_kontakt]'),
    'leistungen' => array('Unsere Leistungen', '<p class="lab-lead">Kleine Reparaturen, klare Absprachen und verständliche Hinweise.</p><h2>Werkstattgespräch</h2><p>Ein synthetisches Beispielangebot für eine erste gemeinsame Einschätzung.</p><h2>Pflege und Erhalt</h2><p>Beispielhafte Hinweise zur Wartung und zur längeren Nutzung vorhandener Gegenstände.</p>'),
    'kontakt' => array('Kontakt', '<p>Hier können ausschließlich erfundene Laboranfragen gespeichert werden. Es wird keine E-Mail versendet.</p>[nordlicht_kontakt][nordlicht_formular]'),
    'journal' => array('Werkstattjournal', '<p>Notizen aus einer erfundenen Werkstatt.</p>'),
);
$ids = array();
foreach ($pages as $slug => $data) {
    $ids[$slug] = wp_insert_post(array('post_type' => 'page', 'post_status' => 'publish', 'post_name' => $slug, 'post_title' => $data[0], 'post_content' => $data[1]), true);
    if (is_wp_error($ids[$slug])) { throw new RuntimeException($ids[$slug]->get_error_message()); }
}
foreach (array('Kleine Pflege, lange Freude' => 'Regelmäßiges Prüfen kann helfen, die Lebensdauer vertrauter Dinge besser einzuschätzen.', 'Was wir dokumentieren' => 'Im Labor halten wir jeden Wartungsschritt, jede Sicherung und jede Wiederherstellung nachvollziehbar fest.') as $title => $content) {
    wp_insert_post(array('post_type' => 'post', 'post_status' => 'publish', 'post_title' => $title, 'post_content' => '<p>' . $content . '</p>'));
}
update_option('show_on_front', 'page');
update_option('page_on_front', $ids['start']);
update_option('page_for_posts', $ids['journal']);
update_option('blogdescription', 'Synthetische Werkstatt. Getestete Wartung.');
update_option('wml_contact_settings', wml_defaults());
update_option('default_comment_status', 'closed');
update_option('timezone_string', 'Europe/Berlin');
$menu = wp_create_nav_menu('Hauptnavigation');
if (is_wp_error($menu)) { $menu = wp_get_nav_menu_object('Hauptnavigation')->term_id; }
foreach (wp_get_nav_menu_items($menu) ?: array() as $item) { wp_delete_post($item->ID, true); }
foreach (array('start' => 'Start', 'leistungen' => 'Leistungen', 'journal' => 'Journal', 'kontakt' => 'Kontakt') as $slug => $label) {
    wp_update_nav_menu_item($menu, 0, array('menu-item-title' => $label, 'menu-item-object' => 'page', 'menu-item-object-id' => $ids[$slug], 'menu-item-type' => 'post_type', 'menu-item-status' => 'publish'));
}
set_theme_mod('nav_menu_locations', array('primary' => $menu));
$uploads = wp_upload_dir();
wp_mkdir_p($uploads['basedir']);
file_put_contents($uploads['basedir'] . '/labor-probe.txt', "Synthetische Upload-Datei für den Restore-Test.\n");
echo "Created four pages, two posts, a menu, settings and a synthetic upload.\n";
