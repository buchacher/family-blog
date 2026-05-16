<?php get_header(); ?>

<section class="archive-posts">
    <div class="container">
        <?php if (have_posts()) : ?>
            <div class="post-grid">
                <?php while (have_posts()) : the_post();
                    $categories = get_the_category();
                    $category_name = ! empty($categories) ? $categories[0]->name : '';
                    $category_link = ! empty($categories) ? get_category_link($categories[0]->term_id) : '';
                ?>
                    <article <?php post_class('post-card'); ?>>
                        <?php if (has_post_thumbnail()) : ?>
                            <div class="post-card__image">
                                <a href="<?php the_permalink(); ?>">
                                    <?php the_post_thumbnail('post-card'); ?>
                                </a>
                            </div>
                        <?php endif; ?>
                        <?php if ($category_name) : ?>
                            <span class="post-category"><a href="<?php echo esc_url($category_link); ?>"><?php echo esc_html($category_name); ?></a></span>
                        <?php endif; ?>
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
            <p>Keine Beitr&auml;ge vorhanden.</p>
        <?php endif; ?>
    </div>
</section>

<?php get_footer(); ?>
