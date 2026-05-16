<?php get_header(); ?>

<section class="error-404">
    <div class="container-narrow">
        <h1 class="error-404__title">Seite nicht gefunden</h1>
        <p class="error-404__text">Die angeforderte Seite konnte leider nicht gefunden werden.</p>
        <a href="<?php echo esc_url(home_url('/')); ?>" class="read-more">&#8592; Zur&uuml;ck zur Startseite</a>
    </div>
</section>

<?php get_footer(); ?>
