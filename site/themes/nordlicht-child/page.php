<?php
/**
 * Accessible page layout.
 *
 * @package NordlichtChild
 */

get_header();
?>
<main id="main" class="lab-wrap" tabindex="-1">
<?php
while ( have_posts() ) :
	the_post();
	?>
	<p class="lab-eyebrow"><?php esc_html_e( 'Bewahren. Reparieren. Weiterverwenden.', 'nordlicht-child' ); ?></p>
	<h1><?php the_title(); ?></h1>
	<?php the_content(); ?>
<?php endwhile; ?>
</main>
<?php get_footer(); ?>
