<?php get_header(); ?>

<header class="search-header">
    <div class="container">
        <h1 class="archive-title">
            Suchergebnisse f&uuml;r: &bdquo;<?php echo esc_html(get_search_query()); ?>&ldquo;
        </h1>
        <?php get_search_form(); ?>
    </div>
</header>

<section class="search-results">
    <div class="container">
        <?php if (have_posts()) : ?>
            <div class="post-grid">
                <?php while (have_posts()) : the_post(); ?>
                    <article <?php post_class('post-card'); ?>>
                        <h2 class="post-card__title"><a href="<?php the_permalink(); ?>"><?php the_title(); ?></a></h2>
                        <div class="post-meta">
                            <time datetime="<?php echo esc_attr(get_the_date('c')); ?>"><?php echo esc_html(get_the_date()); ?></time>
                        </div>
                        <p class="post-excerpt"><?php echo esc_html(get_the_excerpt()); ?></p>
                    </article>
                <?php endwhile; ?>
            </div>

            <?php the_posts_pagination([
                'prev_text' => '&#8592; Zur&uuml;ck',
                'next_text' => 'Weiter &#8594;',
            ]); ?>
        <?php else : ?>
            <div class="no-results container-narrow">
                <p>Keine Ergebnisse f&uuml;r &bdquo;<?php echo esc_html(get_search_query()); ?>&ldquo; gefunden.</p>
                <?php get_search_form(); ?>
            </div>
        <?php endif; ?>
    </div>
</section>

<?php get_footer(); ?>
