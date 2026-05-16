(function () {
    var toggle = document.querySelector('.menu-toggle');
    if (!toggle) return;

    var primaryMenu = document.getElementById('primary-menu');
    var categoriesMenu = document.getElementById('categories-menu');

    toggle.addEventListener('click', function () {
        var expanded = toggle.getAttribute('aria-expanded') === 'true';
        toggle.setAttribute('aria-expanded', String(!expanded));

        if (primaryMenu) primaryMenu.classList.toggle('is-active');
        if (categoriesMenu) categoriesMenu.classList.toggle('is-active');
    });
})();
