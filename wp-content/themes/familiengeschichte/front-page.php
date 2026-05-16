<?php get_header(); ?>

<section class="home-intro">
    <div class="container-narrow">
        <p>Willkommen! Hier erzählen wir die Geschichten unserer Familie — von den Großeltern bis heute.</p>
    </div>
</section>

<section class="home-posts">
    <div class="container">
        <?php if (have_posts()) :
            $post_index = 0;
            $paged = get_query_var('paged') ? get_query_var('paged') : 1;

            while (have_posts()) : the_post();
                $post_index++;
                $categories = get_the_category();
                $category_name = ! empty($categories) ? $categories[0]->name : '';
                $category_link = ! empty($categories) ? get_category_link($categories[0]->term_id) : '';

                if ($post_index === 1 && $paged <= 1) : ?>

                    <article <?php post_class('post-lead'); ?>>
                        <?php if (has_post_thumbnail()) : ?>
                            <div class="post-lead__image">
                                <a href="<?php the_permalink(); ?>">
                                    <?php the_post_thumbnail('post-lead'); ?>
                                </a>
                            </div>
                        <?php endif; ?>
                        <div class="post-lead__content">
                            <?php if ($category_name) : ?>
                                <span class="post-category"><a href="<?php echo esc_url($category_link); ?>"><?php echo esc_html($category_name); ?></a></span>
                            <?php endif; ?>
                            <h2 class="post-lead__title"><a href="<?php the_permalink(); ?>"><?php the_title(); ?></a></h2>
                            <div class="post-meta">
                                <time datetime="<?php echo esc_attr(get_the_date('c')); ?>"><?php echo esc_html(get_the_date()); ?></time>
                            </div>
                            <p class="post-excerpt"><?php echo esc_html(get_the_excerpt()); ?></p>
                            <a href="<?php the_permalink(); ?>" class="read-more">Weiterlesen &#8594;</a>
                        </div>
                    </article>

                    <?php
                    global $wp_query;
                    if ($wp_query->post_count > 1) :
                        echo '<div class="post-grid">';
                    endif;

                else : ?>

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

                <?php endif;
            endwhile;

            global $wp_query;
            if ($wp_query->post_count > 1) :
                echo '</div>';
            endif;

            the_posts_pagination([
                'prev_text' => '&#8592; Zur&uuml;ck',
                'next_text' => 'Weiter &#8594;',
                'mid_size'  => 1,
            ]);

        else : ?>
            <div class="no-posts container-narrow">
                <p>Noch keine Beitr&auml;ge vorhanden.</p>
            </div>
        <?php endif; ?>
    </div>
</section>

<?php get_footer(); ?>
