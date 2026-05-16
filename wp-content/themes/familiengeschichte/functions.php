<?php

function familiengeschichte_setup() {
    load_theme_textdomain('familiengeschichte');
    add_theme_support('title-tag');
    add_theme_support('post-thumbnails');
    set_post_thumbnail_size(1200, 800, true);
    add_image_size('post-lead', 1100, 733, true);
    add_image_size('post-card', 550, 367, true);

    add_theme_support('html5', [
        'search-form', 'comment-form', 'comment-list',
        'gallery', 'caption', 'style', 'script',
    ]);

    add_theme_support('custom-logo', [
        'height'      => 100,
        'width'       => 400,
        'flex-height' => true,
        'flex-width'  => true,
    ]);

    add_theme_support('align-wide');
    add_theme_support('responsive-embeds');
    add_theme_support('editor-styles');
    add_editor_style('editor-style.css');

    add_theme_support('editor-color-palette', [
        ['name' => 'Akzent (Burgund)', 'slug' => 'accent',         'color' => '#8B1A1A'],
        ['name' => 'Text',             'slug' => 'text',           'color' => '#1A1A1A'],
        ['name' => 'Text Sekundaer',   'slug' => 'text-secondary', 'color' => '#666660'],
        ['name' => 'Hintergrund',      'slug' => 'background',     'color' => '#FAFAF7'],
        ['name' => 'Flaeche',          'slug' => 'surface',        'color' => '#F5F2EB'],
    ]);

    add_theme_support('editor-font-sizes', [
        ['name' => 'Klein',  'size' => 15, 'slug' => 'small'],
        ['name' => 'Normal', 'size' => 19, 'slug' => 'normal'],
        ['name' => 'Gross',  'size' => 24, 'slug' => 'large'],
        ['name' => 'Riesig', 'size' => 32, 'slug' => 'huge'],
    ]);

    register_nav_menus([
        'primary'    => 'Hauptnavigation',
        'categories' => 'Kategorien',
    ]);
}
add_action('after_setup_theme', 'familiengeschichte_setup');

function familiengeschichte_scripts() {
    wp_enqueue_style(
        'familiengeschichte-style',
        get_stylesheet_uri(),
        [],
        wp_get_theme()->get('Version')
    );

    wp_enqueue_script(
        'familiengeschichte-navigation',
        get_template_directory_uri() . '/assets/js/navigation.js',
        [],
        wp_get_theme()->get('Version'),
        true
    );
}
add_action('wp_enqueue_scripts', 'familiengeschichte_scripts');

function familiengeschichte_excerpt_length($length) {
    return 30;
}
add_filter('excerpt_length', 'familiengeschichte_excerpt_length');

function familiengeschichte_excerpt_more($more) {
    return '&hellip;';
}
add_filter('excerpt_more', 'familiengeschichte_excerpt_more');

// Security: disable XML-RPC
add_filter('xmlrpc_enabled', '__return_false');

// Security: remove WordPress version from HTML and RSS
remove_action('wp_head', 'wp_generator');
add_filter('the_generator', '__return_empty_string');

// Disable comments site-wide
function familiengeschichte_disable_comments() {
    remove_post_type_support('post', 'comments');
    remove_post_type_support('page', 'comments');
    remove_post_type_support('attachment', 'comments');
}
add_action('init', 'familiengeschichte_disable_comments');

add_filter('comments_open', '__return_false', 20, 2);
add_filter('pings_open', '__return_false', 20, 2);
add_filter('comments_array', '__return_empty_array', 10, 2);

function familiengeschichte_disable_comments_admin_menu() {
    remove_menu_page('edit-comments.php');
}
add_action('admin_menu', 'familiengeschichte_disable_comments_admin_menu');

function familiengeschichte_disable_comments_admin_bar() {
    if (is_admin_bar_showing()) {
        remove_action('admin_bar_menu', 'wp_admin_bar_comments_menu', 60);
    }
}
add_action('init', 'familiengeschichte_disable_comments_admin_bar');

// Remove unnecessary header cruft
remove_action('wp_head', 'rsd_link');
remove_action('wp_head', 'wlwmanifest_link');
remove_action('wp_head', 'wp_shortlink_wp_head');
