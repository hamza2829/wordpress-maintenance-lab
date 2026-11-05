<?php
/**
 * Site footer.
 *
 * @package NordlichtChild
 */

?>
<footer class="lab-footer">
	<div class="lab-wrap">
		<p><?php esc_html_e( 'Nordlicht Reparaturatelier. Alle Namen, Angebote und Nachrichten sind synthetisch.', 'nordlicht-child' ); ?></p>
		<button type="button" data-lab-toggle aria-expanded="false" aria-controls="lab-hint"><?php esc_html_e( 'Laborhinweis anzeigen', 'nordlicht-child' ); ?></button>
		<p class="lab-hint" id="lab-hint" hidden><?php esc_html_e( 'Diese Seite wird nur im Wartungslabor getestet. Es werden keine Nachrichten versendet.', 'nordlicht-child' ); ?></p>
	</div>
</footer>
<?php wp_footer(); ?>
</body>
</html>
