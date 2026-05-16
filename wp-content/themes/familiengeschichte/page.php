<?php get_header(); ?>

<?php while (have_posts()) : the_post(); ?>

    <article <?php post_class(); ?>>
        <header class="page-header">
            <div class="container-narrow">
                <h1 class="page-title"><?php the_title(); ?></h1>
            </div>
        </header>

        <div class="page-content container-narrow">
            <div class="entry-content">
                <?php the_content(); ?>
            </div>
        </div>
    </article>

<?php endwhile; ?>

<?php get_footer(); ?>
