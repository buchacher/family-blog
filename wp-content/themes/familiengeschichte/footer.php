</main>

<footer class="site-footer">
    <div class="container">
        <div class="footer-content">
            <p class="footer-copyright">&copy; <?php echo esc_html(date('Y')); ?> <?php bloginfo('name'); ?></p>
            <nav class="footer-nav">
                <a href="<?php echo esc_url(home_url('/impressum/')); ?>">Impressum</a>
                <a href="<?php echo esc_url(home_url('/datenschutz/')); ?>">Datenschutz</a>
            </nav>
        </div>
    </div>
</footer>

<?php wp_footer(); ?>
</body>
</html>
