<?php
/**
 * Article list and single article fallback.
 *
 * @package NordlichtChild
 */
get_header();
?>
<main id="main" class="lab-wrap post-list" tabindex="-1">
	<h1><?php esc_html_e( 'Werkstattjournal', 'nordlicht-child' ); ?></h1>
	<?php while ( have_posts() ) : ?>
		<?php the_post(); ?>
		<article>
			<h2><a href="<?php the_permalink(); ?>"><?php the_title(); ?></a></h2>
			<?php the_content(); ?>
		</article>
	<?php endwhile; ?>
</main>
<?php get_footer(); ?>
