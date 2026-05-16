<?php get_header(); ?>

<?php while (have_posts()) : the_post(); ?>

    <article <?php post_class('single-post'); ?>>
        <header class="single-post__header">
            <div class="container-narrow">
                <?php $categories = get_the_category(); ?>
                <?php if (! empty($categories)) : ?>
                    <span class="post-category">
                        <a href="<?php echo esc_url(get_category_link($categories[0]->term_id)); ?>">
                            <?php echo esc_html($categories[0]->name); ?>
                        </a>
                    </span>
                <?php endif; ?>

                <h1 class="single-post__title"><?php the_title(); ?></h1>

                <div class="single-post__meta">
                    <time datetime="<?php echo esc_attr(get_the_date('c')); ?>"><?php echo esc_html(get_the_date()); ?></time>
                    <?php $tags = get_the_tags(); ?>
                    <?php if ($tags) : ?>
                        <span class="post-tags">
                            <?php
                            $tag_links = array_map(function ($tag) {
                                return '<a href="' . esc_url(get_tag_link($tag->term_id)) . '">' . esc_html($tag->name) . '</a>';
                            }, $tags);
                            echo implode(', ', $tag_links);
                            ?>
                        </span>
                    <?php endif; ?>
                </div>
            </div>
        </header>

        <?php if (has_post_thumbnail()) : ?>
            <div class="single-post__image">
                <div class="container-wide">
                    <?php the_post_thumbnail('large'); ?>
                </div>
            </div>
        <?php endif; ?>

        <div class="single-post__content container-narrow">
            <div class="entry-content">
                <?php the_content(); ?>
            </div>
        </div>

        <footer class="single-post__footer container-narrow">
            <?php
            $prev_post = get_previous_post();
            $next_post = get_next_post();
            ?>
            <?php if ($prev_post || $next_post) : ?>
                <nav class="post-navigation" aria-label="Beitragsnavigation">
                    <?php if ($prev_post) : ?>
                        <a href="<?php echo esc_url(get_permalink($prev_post)); ?>" class="post-navigation__link post-navigation__link--prev">
                            <span class="post-navigation__label">&#8592; Vorheriger Beitrag</span>
                            <span class="post-navigation__title"><?php echo esc_html($prev_post->post_title); ?></span>
                        </a>
                    <?php else : ?>
                        <div class="post-navigation__link"></div>
                    <?php endif; ?>

                    <?php if ($next_post) : ?>
                        <a href="<?php echo esc_url(get_permalink($next_post)); ?>" class="post-navigation__link post-navigation__link--next">
                            <span class="post-navigation__label">N&auml;chster Beitrag &#8594;</span>
                            <span class="post-navigation__title"><?php echo esc_html($next_post->post_title); ?></span>
                        </a>
                    <?php endif; ?>
                </nav>
            <?php endif; ?>
        </footer>
    </article>

<?php endwhile; ?>

<?php get_footer(); ?>
