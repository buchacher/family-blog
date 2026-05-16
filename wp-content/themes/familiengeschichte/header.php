<!DOCTYPE html>
<html <?php language_attributes(); ?>>
<head>
    <meta charset="<?php bloginfo('charset'); ?>">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <?php wp_head(); ?>
</head>
<body <?php body_class(); ?>>
<?php wp_body_open(); ?>

<a class="screen-reader-text" href="#content"><?php esc_html_e('Zum Inhalt springen', 'familiengeschichte'); ?></a>

<header class="site-header">
    <div class="header-accent"></div>

    <div class="header-main">
        <div class="container">
            <?php if (is_front_page()) : ?>
                <h1 class="site-title"><a href="<?php echo esc_url(home_url('/')); ?>"><?php bloginfo('name'); ?></a></h1>
            <?php else : ?>
                <p class="site-title"><a href="<?php echo esc_url(home_url('/')); ?>"><?php bloginfo('name'); ?></a></p>
            <?php endif; ?>

            <?php $tagline = get_bloginfo('description', 'display'); ?>
            <?php if ($tagline) : ?>
                <p class="site-tagline"><?php echo esc_html($tagline); ?></p>
            <?php endif; ?>
        </div>
    </div>

    <nav class="nav-primary" aria-label="<?php esc_attr_e('Hauptnavigation', 'familiengeschichte'); ?>">
        <div class="container">
            <button class="menu-toggle" aria-controls="primary-menu" aria-expanded="false">
                <span>
                    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" aria-hidden="true">
                        <line x1="3" y1="6" x2="21" y2="6"/>
                        <line x1="3" y1="12" x2="21" y2="12"/>
                        <line x1="3" y1="18" x2="21" y2="18"/>
                    </svg>
                    <?php esc_html_e('Menu', 'familiengeschichte'); ?>
                </span>
            </button>
            <?php
            wp_nav_menu([
                'theme_location' => 'primary',
                'container'      => false,
                'menu_class'     => 'nav-menu',
                'menu_id'        => 'primary-menu',
                'fallback_cb'    => false,
            ]);
            ?>
        </div>
    </nav>

    <?php if (has_nav_menu('categories')) : ?>
    <nav class="nav-categories" aria-label="<?php esc_attr_e('Kategorien', 'familiengeschichte'); ?>">
        <div class="container">
            <?php
            wp_nav_menu([
                'theme_location' => 'categories',
                'container'      => false,
                'menu_class'     => 'nav-menu',
                'menu_id'        => 'categories-menu',
                'fallback_cb'    => false,
            ]);
            ?>
        </div>
    </nav>
    <?php endif; ?>
</header>

<main id="content" class="site-main">
