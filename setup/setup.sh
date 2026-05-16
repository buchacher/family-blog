#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# Familiengeschichte — WordPress Setup Script
#
# Prerequisite: docker compose up -d
# Usage:        ./setup/setup.sh
#
# This script configures a fresh WordPress installation via WP-CLI:
# language, settings, theme, categories, pages, sample posts, and menus.
#
# For a clean restart:
#   docker compose down -v && docker compose up -d && ./setup/setup.sh
# =============================================================================

wp() {
    docker compose run --rm wpcli wp "$@"
}

echo ""
echo "=== Familiengeschichte — Setup ==="
echo ""

# ---------------------------------------------------------------------------
# Wait for services
# ---------------------------------------------------------------------------
echo "Warte auf Datenbank..."
until docker compose exec -T db mariadb -u wp_user -plocaldev_wp_pw wordpress -e "SELECT 1" 2>/dev/null; do
    sleep 2
done
echo "  Datenbank bereit."

echo "Warte auf WordPress-Dateien..."
until docker compose run --rm wpcli wp core version 2>/dev/null; do
    sleep 3
done
echo "  WordPress bereit."

# ---------------------------------------------------------------------------
# Install WordPress core
# ---------------------------------------------------------------------------
if wp core is-installed 2>/dev/null; then
    echo "  WordPress bereits installiert — ueberspringe Installation."
else
    echo "Installiere WordPress..."
    wp core install \
        --url="http://localhost:8080" \
        --title="Unsere Familiengeschichte" \
        --admin_user="admin" \
        --admin_password="localdev_admin_pw" \
        --admin_email="admin@example.com" \
        --locale="de_DE"
    echo "  WordPress installiert."
fi

# ---------------------------------------------------------------------------
# Language
# ---------------------------------------------------------------------------
echo "Konfiguriere Sprache..."
wp language core install de_DE --activate 2>/dev/null || true

# ---------------------------------------------------------------------------
# Core settings
# ---------------------------------------------------------------------------
echo "Konfiguriere Einstellungen..."
wp option update blogname "Unsere Familiengeschichte"
wp option update blogdescription "Geschichten, Erinnerungen und Anekdoten aus unserer Familie"
wp option update timezone_string "Europe/Vienna"
wp option update date_format "j. F Y"
wp option update time_format "H:i"
wp option update start_of_week 1
wp option update permalink_structure "/%postname%/"
wp option update default_comment_status "closed"
wp option update default_ping_status "closed"
wp option update users_can_register 0
wp option update posts_per_page 10
wp option update blog_public 1
wp rewrite flush --hard 2>/dev/null || true

# ---------------------------------------------------------------------------
# Editor account
# ---------------------------------------------------------------------------
echo "Erstelle Benutzerkonten..."
wp user create vater vater@example.com \
    --role=editor \
    --user_pass="localdev_editor_pw" \
    --display_name="Vater" 2>/dev/null \
    || echo "  (Benutzer 'vater' existiert bereits)"

# ---------------------------------------------------------------------------
# Activate theme
# ---------------------------------------------------------------------------
echo "Aktiviere Theme..."
wp theme activate familiengeschichte

# ---------------------------------------------------------------------------
# Categories
# ---------------------------------------------------------------------------
echo "Erstelle Kategorien..."
wp term create category "Großeltern"  --slug=grosseltern  --description="Geschichten über die Großeltern" 2>/dev/null || true
wp term create category "Eltern"      --slug=eltern       --description="Geschichten über die Eltern" 2>/dev/null || true
wp term create category "Kindheit"    --slug=kindheit     --description="Kindheitserinnerungen" 2>/dev/null || true
wp term create category "Kurioses"    --slug=kurioses     --description="Erstaunliche, lustige und ungewöhnliche Geschichten" 2>/dev/null || true
wp term create category "Traditionen" --slug=traditionen  --description="Familientraditionen und Bräuche" 2>/dev/null || true

DEFAULT_CAT=$(wp option get default_category 2>/dev/null)
if [ -n "$DEFAULT_CAT" ]; then
    wp term update category "$DEFAULT_CAT" --name="Allgemein" --slug=allgemein \
        --description="Allgemeine Beiträge" 2>/dev/null || true
fi

# ---------------------------------------------------------------------------
# Remove default content
# ---------------------------------------------------------------------------
echo "Entferne Standard-Inhalte..."
wp post delete 1 --force 2>/dev/null || true
wp post delete 2 --force 2>/dev/null || true
wp post delete 3 --force 2>/dev/null || true

# ---------------------------------------------------------------------------
# Static pages
# ---------------------------------------------------------------------------
echo "Erstelle Seiten..."

UEBER_UNS_EXISTS=$(wp post list --post_type=page --name=ueber-uns --field=ID 2>/dev/null || true)
if [ -z "$UEBER_UNS_EXISTS" ]; then
    wp post create --post_type=page --post_title="Über uns" --post_name="ueber-uns" \
        --post_status=publish --comment_status=closed --ping_status=closed \
        --post_content='<!-- wp:paragraph -->
<p>Diese Seite erzählt die Geschichte der Familie [Nachname]. Wir sammeln Erinnerungen, Anekdoten und Fotos, damit sie nicht verloren gehen.</p>
<!-- /wp:paragraph -->
<!-- wp:paragraph -->
<p><em>[Platzhalter — bitte mit eigenen Inhalten ersetzen]</em></p>
<!-- /wp:paragraph -->'
fi

IMPRESSUM_EXISTS=$(wp post list --post_type=page --name=impressum --field=ID 2>/dev/null || true)
if [ -z "$IMPRESSUM_EXISTS" ]; then
    wp post create --post_type=page --post_title="Impressum" --post_name="impressum" \
        --post_status=publish --comment_status=closed --ping_status=closed \
        --post_content='<!-- wp:heading -->
<h2>Angaben gemäß § 25 Mediengesetz</h2>
<!-- /wp:heading -->
<!-- wp:paragraph -->
<p>[Vor- und Nachname]<br>[Adresse]<br>[E-Mail-Adresse]</p>
<!-- /wp:paragraph -->
<!-- wp:heading -->
<h2>Haftungsausschluss</h2>
<!-- /wp:heading -->
<!-- wp:paragraph -->
<p><em>[Platzhalter — der Betreiber wird dies selbst ausfüllen]</em></p>
<!-- /wp:paragraph -->'
fi

DATENSCHUTZ_EXISTS=$(wp post list --post_type=page --name=datenschutz --field=ID 2>/dev/null || true)
if [ -z "$DATENSCHUTZ_EXISTS" ]; then
    wp post create --post_type=page --post_title="Datenschutz" --post_name="datenschutz" \
        --post_status=publish --comment_status=closed --ping_status=closed \
        --post_content='<!-- wp:paragraph -->
<p><em>Diese Seite muss mit einer DSGVO-konformen Datenschutzerklärung ausgefüllt werden.</em></p>
<!-- /wp:paragraph -->
<!-- wp:paragraph -->
<p>Hilfreiche Ressourcen zur Erstellung:</p>
<!-- /wp:paragraph -->
<!-- wp:list -->
<ul><li>oesterreich.gv.at — Informationen zur Datenschutzerklärung</li><li>e-recht24.de — Datenschutz-Generator</li></ul>
<!-- /wp:list -->
<!-- wp:paragraph -->
<p><em>[Platzhalter — bitte ersetzen mit Angaben zu: erhobene Daten, Hosting-Anbieter (AWS), Kontaktdaten, Rechte der Betroffenen]</em></p>
<!-- /wp:paragraph -->'
fi

# ---------------------------------------------------------------------------
# Sample posts
# ---------------------------------------------------------------------------
echo "Erstelle Beispiel-Beitraege..."

GROSSELTERN_ID=$(wp term list category --name="Großeltern" --field=term_id 2>/dev/null || true)
KURIOSES_ID=$(wp term list category --name="Kurioses" --field=term_id 2>/dev/null || true)

POST1_EXISTS=$(wp post list --post_type=post --name="wie-opa-seinen-ersten-traktor-kaufte" --field=ID 2>/dev/null || true)
POST1_ID=""
if [ -z "$POST1_EXISTS" ]; then
    POST1_ID=$(wp post create \
        --post_title="Wie Opa seinen ersten Traktor kaufte" \
        --post_status=publish \
        --post_date="2026-05-10 10:00:00" \
        --post_category="${GROSSELTERN_ID:-1}" \
        --tags_input="Opa, Landwirtschaft, 1960er" \
        --comment_status=closed \
        --ping_status=closed \
        --porcelain \
        --post_content='<!-- wp:paragraph -->
<p>Es war im Frühjahr 1962, als mein Großvater beschloss, dass es Zeit war, die beiden alten Zugpferde in den wohlverdienten Ruhestand zu schicken. Die Nachbarn hielten ihn für verrückt — ein Traktor, das war etwas für die großen Betriebe im Flachland, nicht für einen kleinen Bergbauern in der Steiermark.</p>
<!-- /wp:paragraph -->

<!-- wp:paragraph -->
<p>Drei Monate lang fuhr er jeden Samstag mit dem Bus nach Graz, um sich bei verschiedenen Händlern umzusehen. Meine Großmutter erzählte später, dass er in dieser Zeit kaum geschlafen hat. Abends saß er am Küchentisch, den Bleistift in der Hand, und rechnete immer wieder dieselben Zahlen durch. Das Sparbuch war dünn, aber der Wille war stark.</p>
<!-- /wp:paragraph -->

<!-- wp:paragraph -->
<p>Am Ende wurde es ein gebrauchter Steyr 180, Baujahr 1958, mit einer kleinen Beule an der rechten Seite und einem Motor, der klang wie ein zufriedenes Brummen. Der Händler wollte eigentlich mehr, aber Opa — und das erzählte er bis zu seinem letzten Tag mit einem schelmischen Grinsen — hatte dem Mann so lange von den Schwierigkeiten der Berglandwirtschaft erzählt, bis dieser den Preis senkte, nur um endlich Ruhe zu haben.</p>
<!-- /wp:paragraph -->

<!-- wp:paragraph -->
<p>Die Heimfahrt mit dem Traktor dauerte fast vier Stunden. Als er endlich die Auffahrt zum Hof hinaufknatterte, stand die ganze Familie draußen. Mein Vater, damals erst sechs Jahre alt, durfte als Erster auf dem Beifahrersitz Platz nehmen. Er sagt, er könne sich noch heute an den Geruch von Diesel und warmem Metall erinnern. Es war der Geruch der Zukunft.</p>
<!-- /wp:paragraph -->' 2>/dev/null)
else
    POST1_ID="$POST1_EXISTS"
fi

POST2_EXISTS=$(wp post list --post_type=post --name="der-geheimnisvolle-koffer-auf-dem-dachboden" --field=ID 2>/dev/null || true)
POST2_ID=""
if [ -z "$POST2_EXISTS" ]; then
    POST2_ID=$(wp post create \
        --post_title="Der geheimnisvolle Koffer auf dem Dachboden" \
        --post_status=publish \
        --post_date="2026-05-12 14:30:00" \
        --post_category="${KURIOSES_ID:-1}" \
        --tags_input="Dachboden, Familiengeheimnis" \
        --comment_status=closed \
        --ping_status=closed \
        --porcelain \
        --post_content='<!-- wp:paragraph -->
<p>Jede Familie hat ihre Geheimnisse, und unsere bildet da keine Ausnahme. Eines der größten wurde an einem regnerischen Novembernachmittag im Jahr 1987 entdeckt, als mein Cousin Thomas und ich uns auf dem Dachboden des Großelternhauses langweilten.</p>
<!-- /wp:paragraph -->

<!-- wp:paragraph -->
<p>Hinter einem Stapel alter Zeitungen und einem kaputten Schaukelstuhl fanden wir einen schweren Lederkoffer, den wir noch nie gesehen hatten. Er war mit einem kleinen Vorhängeschloss versperrt, aber das Leder an den Scharnieren war so brüchig, dass wir ihn mit einem beherzten Ruck öffnen konnten. Was wir darin fanden, verschlug uns die Sprache.</p>
<!-- /wp:paragraph -->

<!-- wp:paragraph -->
<p>Dutzende von Briefen, sorgfältig mit Seidenbändern gebündelt, dazu Fotografien von Menschen, die wir nicht kannten, in Kleidung, die wir nur aus Geschichtsbüchern kannten. Ein kleines, in Leder gebundenes Tagebuch mit Einträgen auf Tschechisch. Eine silberne Taschenuhr, deren Deckel ein eingraviertes Monogramm trug: „J. K." — Initialen, die niemandem in unserer Familie gehörten. Oder so dachten wir zumindest.</p>
<!-- /wp:paragraph -->

<!-- wp:paragraph -->
<p>Es dauerte Jahre, bis wir die ganze Geschichte zusammensetzen konnten. Die Briefe stammten von einem Urgroßonkel, der nach dem Ersten Weltkrieg aus Südmähren nach Österreich gekommen war und dessen Existenz aus Gründen, die wir bis heute nicht ganz verstehen, aus dem Familiengedächtnis getilgt worden war. Die Taschenuhr war sein einziges Erbstück gewesen. Heute steht sie auf dem Kaminsims meiner Eltern — ein stiller Zeuge einer Geschichte, die beinahe für immer verloren gegangen wäre.</p>
<!-- /wp:paragraph -->' 2>/dev/null)
else
    POST2_ID="$POST2_EXISTS"
fi

# ---------------------------------------------------------------------------
# Placeholder images (generated via PHP/GD in the WordPress container)
# ---------------------------------------------------------------------------
echo "Erstelle Platzhalterbilder..."
docker compose exec -T wordpress php -r "
\$dir = '/var/www/html/wp-content/uploads/' . date('Y') . '/' . date('m') . '/';
if (!is_dir(\$dir)) mkdir(\$dir, 0755, true);

\$images = [
    ['bg' => [210, 200, 180], 'fg' => [100, 70, 50],  'label' => 'Platzhalterbild'],
    ['bg' => [180, 195, 210], 'fg' => [50, 70, 100],  'label' => 'Platzhalterbild'],
];

foreach (\$images as \$i => \$c) {
    \$img = imagecreatetruecolor(1200, 800);
    \$bg  = imagecolorallocate(\$img, \$c['bg'][0], \$c['bg'][1], \$c['bg'][2]);
    \$fg  = imagecolorallocate(\$img, \$c['fg'][0], \$c['fg'][1], \$c['fg'][2]);
    imagefill(\$img, 0, 0, \$bg);
    \$tw = imagefontwidth(5) * strlen(\$c['label']);
    imagestring(\$img, 5, (int)((1200 - \$tw) / 2), 395, \$c['label'], \$fg);
    imagejpeg(\$img, \$dir . 'placeholder-' . (\$i + 1) . '.jpg', 85);
    imagedestroy(\$img);
}
echo 'OK';
" || echo "  (Platzhalterbilder konnten nicht erstellt werden)"

YEAR=$(date +%Y)
MONTH=$(date +%m)

IMG1_ID=$(wp media import "/var/www/html/wp-content/uploads/$YEAR/$MONTH/placeholder-1.jpg" \
    --title="Platzhalterbild — Traktor" --porcelain 2>/dev/null || true)
IMG2_ID=$(wp media import "/var/www/html/wp-content/uploads/$YEAR/$MONTH/placeholder-2.jpg" \
    --title="Platzhalterbild — Koffer" --porcelain 2>/dev/null || true)

if [ -n "${IMG1_ID:-}" ] && [ -n "${POST1_ID:-}" ]; then
    wp post meta update "$POST1_ID" _thumbnail_id "$IMG1_ID" 2>/dev/null || true
fi
if [ -n "${IMG2_ID:-}" ] && [ -n "${POST2_ID:-}" ]; then
    wp post meta update "$POST2_ID" _thumbnail_id "$IMG2_ID" 2>/dev/null || true
fi

# ---------------------------------------------------------------------------
# Navigation menus
# ---------------------------------------------------------------------------
echo "Erstelle Navigationsmenus..."

MENU_EXISTS=$(wp menu list --fields=name --format=csv 2>/dev/null | grep -c "Hauptnavigation" || true)
if [ "$MENU_EXISTS" -eq 0 ]; then
    wp menu create "Hauptnavigation" 2>/dev/null || true
fi
wp menu location assign Hauptnavigation primary 2>/dev/null || true

MENU_ITEMS=$(wp menu item list Hauptnavigation --format=count 2>/dev/null || echo "0")
if [ "$MENU_ITEMS" -eq 0 ]; then
    wp menu item add-custom Hauptnavigation "Startseite" "http://localhost:8080/" 2>/dev/null || true

    UEBER_UNS_ID=$(wp post list --post_type=page --name=ueber-uns --field=ID 2>/dev/null || true)
    IMPRESSUM_ID=$(wp post list --post_type=page --name=impressum --field=ID 2>/dev/null || true)
    DATENSCHUTZ_ID=$(wp post list --post_type=page --name=datenschutz --field=ID 2>/dev/null || true)

    [ -n "${UEBER_UNS_ID:-}" ]  && wp menu item add-post Hauptnavigation "$UEBER_UNS_ID" 2>/dev/null || true
    [ -n "${IMPRESSUM_ID:-}" ]   && wp menu item add-post Hauptnavigation "$IMPRESSUM_ID" 2>/dev/null || true
    [ -n "${DATENSCHUTZ_ID:-}" ] && wp menu item add-post Hauptnavigation "$DATENSCHUTZ_ID" 2>/dev/null || true
fi

CAT_MENU_EXISTS=$(wp menu list --fields=name --format=csv 2>/dev/null | grep -c "Kategorien" || true)
if [ "$CAT_MENU_EXISTS" -eq 0 ]; then
    wp menu create "Kategorien" 2>/dev/null || true
fi
wp menu location assign Kategorien categories 2>/dev/null || true

CAT_MENU_ITEMS=$(wp menu item list Kategorien --format=count 2>/dev/null || echo "0")
if [ "$CAT_MENU_ITEMS" -eq 0 ]; then
    for slug in grosseltern eltern kindheit kurioses traditionen allgemein; do
        CAT_ID=$(wp term list category --slug="$slug" --field=term_id 2>/dev/null || true)
        if [ -n "${CAT_ID:-}" ]; then
            wp menu item add-term Kategorien category "$CAT_ID" 2>/dev/null || true
        fi
    done
fi

# ---------------------------------------------------------------------------
# Install plugins (downloads from wordpress.org)
# ---------------------------------------------------------------------------
echo "Installiere Plugins..."

echo "  Antispam Bee (Spam-Schutz, DSGVO-konform)..."
wp plugin install antispam-bee --activate 2>/dev/null || true

echo "  UpdraftPlus (Backups)..."
wp plugin install updraftplus --activate 2>/dev/null || true

echo "  Imagify (Bildoptimierung)..."
wp plugin install imagify --activate 2>/dev/null || true

echo "  WP Super Cache (Seiten-Caching)..."
wp plugin install wp-super-cache --activate 2>/dev/null || true

echo "  Yoast SEO (Suchmaschinenoptimierung)..."
wp plugin install wordpress-seo --activate 2>/dev/null || true

echo "  Limit Login Attempts Reloaded (Login-Schutz)..."
wp plugin install limit-login-attempts-reloaded --activate 2>/dev/null || true

echo "  Complianz (Cookie-Consent, DSGVO)..."
wp plugin install complianz-gdpr --activate 2>/dev/null || true

echo "  Statify (Datenschutzfreundliche Statistiken, deaktiviert)..."
wp plugin install statify 2>/dev/null || true

echo "  TablePress (Tabellen, deaktiviert)..."
wp plugin install tablepress 2>/dev/null || true

echo "  Entferne Akismet und Hello Dolly..."
wp plugin delete akismet 2>/dev/null || true
wp plugin delete hello 2>/dev/null || true

# ---------------------------------------------------------------------------
# Final flush
# ---------------------------------------------------------------------------
wp rewrite flush --hard 2>/dev/null || true

# ---------------------------------------------------------------------------
# Done
# ---------------------------------------------------------------------------
echo ""
echo "========================================"
echo "  Setup abgeschlossen!"
echo "========================================"
echo ""
echo "  Blog:     http://localhost:8080"
echo "  Admin:    http://localhost:8080/wp-admin"
echo ""
echo "  Administrator:"
echo "    Benutzer:  admin"
echo "    Passwort:  localdev_admin_pw"
echo ""
echo "  Redakteur (Vater):"
echo "    Benutzer:  vater"
echo "    Passwort:  localdev_editor_pw"
echo ""
echo "  Diese Passwoerter sind nur fuer die lokale Entwicklung!"
echo ""
echo "  Plugins (installiert und aktiviert):"
echo "    - Antispam Bee          Spam-Schutz ohne Cloud (DSGVO-konform)"
echo "    - UpdraftPlus           Geplante Backups"
echo "    - Imagify               Automatische Bildoptimierung"
echo "    - WP Super Cache        Seiten-Caching"
echo "    - Yoast SEO             SEO: Sitemaps, Meta-Beschreibungen"
echo "    - Limit Login Attempts  Brute-Force-Schutz"
echo "    - Complianz             Cookie-Consent-Banner (DSGVO/TKG)"
echo ""
echo "  Plugins (installiert, nicht aktiviert):"
echo "    - Statify               Datenschutzfreundliche Statistiken"
echo "    - TablePress            Tabellen fuer Familienzeitleisten etc."
echo ""
