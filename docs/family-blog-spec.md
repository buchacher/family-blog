# Family History Blog — Project Specification

## Purpose

This document specifies a WordPress-based family history blog. It is intended as a handoff to an AI coding assistant (Claude Code) for building and deploying the site. Follow every section; ask for clarification only if a requirement is contradictory.

---

## 1. Project Overview

**Goal:** A public-facing blog where a single author (the site owner's father) publishes stories about family members and family history. The audience is family, friends, and potentially distant relatives who discover the site via search.

**Language:** All content will be in **German**. The WordPress admin interface must also be set to German (`de_DE` locale).

**Key constraint:** The primary author is not tech-savvy. Every editorial workflow must be achievable through the WordPress block editor (Gutenberg) without touching code, the file system, or the command line.

---

## 2. Hosting & Infrastructure

### Target Environment: AWS (learning project)

The site owner is a developer using this project to learn AWS fundamentals. Optimise for educational value and low cost over production-grade resilience.

### Development Workflow

Development happens in two phases:

1. **Local development** (Section 2.1) — build and refine the blog on the developer's machine using Docker Compose. Show it to the father for approval. Iterate until he's happy with the look, feel, and editing workflow.
2. **AWS deployment** (Section 2.2) — once approved, deploy to EC2 and migrate the local content.

### 2.1 Local Development Environment (Docker Compose)

The local setup uses Docker Compose to run WordPress + MySQL with zero host dependencies beyond Docker itself. All configuration, theme, plugin, and content work happens here first.

#### Prerequisites

- Docker and Docker Compose installed on the developer's machine
- A modern browser
- No PHP, MySQL, or Apache/Nginx installation needed locally

#### `docker-compose.yml`

Create a project directory (e.g. `~/family-blog/`) with the following `docker-compose.yml`:

```yaml
version: "3.9"

services:
  db:
    image: mysql:8.0
    restart: unless-stopped
    environment:
      MYSQL_ROOT_PASSWORD: localdev_root_pw
      MYSQL_DATABASE: wordpress
      MYSQL_USER: wp_user
      MYSQL_PASSWORD: localdev_wp_pw
    volumes:
      - db_data:/var/lib/mysql
    ports:
      - "3306:3306"

  wordpress:
    image: wordpress:latest
    restart: unless-stopped
    depends_on:
      - db
    ports:
      - "8080:80"
    environment:
      WORDPRESS_DB_HOST: db:3306
      WORDPRESS_DB_USER: wp_user
      WORDPRESS_DB_PASSWORD: localdev_wp_pw
      WORDPRESS_DB_NAME: wordpress
      WORDPRESS_CONFIG_EXTRA: |
        define('WPLANG', 'de_DE');
        define('DISALLOW_FILE_EDIT', true);
    volumes:
      - wp_data:/var/www/html
      - ./wp-content/themes:/var/www/html/wp-content/themes
      - ./wp-content/plugins:/var/www/html/wp-content/plugins
      - ./wp-content/uploads:/var/www/html/wp-content/uploads

volumes:
  db_data:
  wp_data:
```

#### Usage

```bash
cd ~/family-blog/
docker compose up -d          # Start containers
# WordPress available at http://localhost:8080
# Run the WordPress installer (choose German), create admin + editor accounts

docker compose down            # Stop containers (data persists in volumes)
docker compose down -v         # Stop AND delete all data (fresh start)
```

#### Local Development Notes

- The site will be accessible at **`http://localhost:8080`** — show this to the father on the same machine, or use the developer's local network IP (e.g. `http://192.168.1.x:8080`) to show it on the father's phone/tablet
- Theme and plugin files are bind-mounted from `./wp-content/` so they persist outside the container and can be version-controlled
- The `uploads/` directory is also bind-mounted so uploaded images survive container restarts
- Database data persists in a Docker volume (`db_data`)
- **Passwords are for local use only** — never reuse these in production
- Install all plugins and configure all settings listed in Sections 3–6 locally before deploying to AWS

#### Migration from Local to AWS

Once the father approves the local version:

1. **Export the database** from the local MySQL container:
   ```bash
   docker compose exec db mysqldump -u wp_user -plocaldev_wp_pw wordpress > local_export.sql
   ```
2. **Copy theme, plugin, and upload files** from the local `./wp-content/` to the EC2 instance
3. **Import the database** on the EC2 instance:
   ```bash
   mysql -u wp_user -p wordpress < local_export.sql
   ```
4. **Run a search-and-replace** on the database to update URLs from `http://localhost:8080` to `https://[production-domain]` — use WP-CLI:
   ```bash
   wp search-replace 'http://localhost:8080' 'https://yourdomain.at' --all-tables
   ```
5. Verify everything works on the live domain

### 2.2 AWS Production Environment

#### Architecture — Phase 1 (Minimal)

| Component       | AWS Service / Setup                                                              |
|-----------------|----------------------------------------------------------------------------------|
| Compute         | Single **EC2 instance**, `t3.micro` or `t4g.micro` (ARM/Graviton, cheaper)       |
| OS              | Ubuntu 24.04 LTS (or latest LTS at time of build)                               |
| Web server      | Nginx as reverse proxy + PHP-FPM                                                 |
| Database        | MySQL 8 or MariaDB, installed locally on the same EC2 instance                   |
| SSL             | Let's Encrypt via Certbot, auto-renewing                                         |
| Media backups   | Nightly sync of `wp-content/uploads/` to an **S3 bucket**                        |
| DB backups      | Nightly `mysqldump` compressed and uploaded to the same S3 bucket                |
| Firewall        | AWS **Security Group**: allow inbound 80, 443, and 22 (SSH, IP-restricted)       |
| DNS             | Initially point the existing World4You domain via **A record** to the EC2 Elastic IP |

#### Architecture — Phase 2 (optional future improvements)

These are out of scope for initial build but noted here for the owner's learning roadmap:

- Move the database to **RDS** (managed MySQL)
- Offload media to **S3 + CloudFront** via a WordPress plugin (e.g. WP Offload Media Lite)
- Transfer DNS to **Route 53**
- Add **CloudFront** as a CDN in front of the EC2 instance
- Set up **CloudWatch** alarms for CPU/memory

#### Cost Management

- Enable **AWS Billing Alerts**: email notification if monthly cost exceeds **$10 USD**
- Use the **AWS Free Tier** where applicable (first 12 months)
- Expected steady-state cost after free tier: **~$5–10 USD/month** (t3.micro + S3 storage)

---

## 3. WordPress Configuration

### Core Settings

| Setting              | Value                                      |
|----------------------|--------------------------------------------|
| WordPress language   | `de_DE` (German)                           |
| Timezone             | `Europe/Vienna`                            |
| Date format          | `j. F Y` (e.g. "14. Mai 2026")            |
| Permalink structure  | `/%postname%/` (readable URLs)             |
| Comments             | **Disabled globally** (public, read-only blog) |
| User registrations   | **Disabled**                               |
| Search engine visibility | Visible (allow indexing)               |
| Default post category | Create a default category "Allgemein"     |

### User Accounts

| Account       | Role          | Purpose                          |
|---------------|---------------|----------------------------------|
| Admin (owner) | Administrator | Full site management, setup      |
| Father        | Editor        | Write, edit, publish posts only  |

The father's account should use the **Editor** role (not Administrator) to reduce the chance of accidentally breaking site settings.

---

## 4. Theme

### Requirements

- Clean, readable, **journal/magazine aesthetic** — warm and inviting, not corporate
- **Large base font size** (18px+) for readability (older audience)
- Generous line height (1.6–1.8)
- Strong support for **featured images** on posts
- Photo-friendly layouts: images should be displayable at full-width or in simple galleries
- Fully **responsive** (mobile-first; family will read on phones)
- Fast-loading and lightweight
- Compatible with the block editor (Gutenberg)
- Free (no premium theme purchase required)

### Recommended Themes (evaluate in this order)

1. **flavor** — Minimalist blog theme, clean typography
2. **flavor flavor flavor flavor flavor flavor flavor** — Well-supported, good photo handling
3. **flavor flavor flavor flavor flavor flavor** — WordPress default theme, reliable, block-editor native

> The builder should install the top candidate, evaluate its appearance with sample German content, and proceed if it meets the requirements above. If not, try the next.

### Customisation

- Set a **site title** placeholder: "Unsere Familiengeschichte" (the owner will change this)
- Set a **tagline** placeholder: "Geschichten, Erinnerungen und Anekdoten aus unserer Familie"
- Upload a placeholder **favicon** (a simple generic icon is fine; the owner will replace it)

---

## 5. Content Structure

### Post Categories

Create the following categories in German:

| Category (slug)     | Display Name         | Description                              |
|---------------------|----------------------|------------------------------------------|
| `grosseltern`       | Großeltern           | Stories about grandparents               |
| `eltern`            | Eltern               | Stories about parents                    |
| `kindheit`          | Kindheit             | Childhood memories                       |
| `kurioses`          | Kurioses             | Astonishing, funny, or unusual stories   |
| `traditionen`       | Traditionen          | Family traditions and customs            |
| `allgemein`         | Allgemein            | General / uncategorised                  |

### Post Tags

Do not pre-create tags. The author will add them organically as he writes (e.g. family member names, locations, decades).

### Pages (static)

Create the following pages:

1. **Startseite (Home)** — A welcoming landing page. Should display the most recent blog posts in reverse chronological order. A short introductory text block at the top: *"Willkommen! Hier erzählen wir die Geschichten unserer Familie — von den Großeltern bis heute."* (placeholder, editable by the owner).
2. **Über uns** — An "About" page. Placeholder text: *"Diese Seite erzählt die Geschichte der Familie [Nachname]. Wir sammeln Erinnerungen, Anekdoten und Fotos, damit sie nicht verloren gehen."*
3. **Impressum** — Required by Austrian law (Impressumspflicht). Create the page with a placeholder structure:
   ```
   Impressum

   Angaben gemäß § 25 Mediengesetz:
   [Vor- und Nachname]
   [Adresse]
   [E-Mail-Adresse]

   Haftungsausschluss:
   [Platzhalter — der Betreiber wird dies selbst ausfüllen]
   ```
4. **Datenschutz** — Privacy policy page. Placeholder noting this needs to be filled in with a GDPR-compliant privacy policy for Austria.

### Navigation Menu

Create a primary navigation menu with:

```
Startseite | Über uns | Impressum | Datenschutz
```

The category archive pages should be accessible via a secondary menu or sidebar widget, not the primary nav.

---

## 6. Plugins

Install and activate only essential plugins. Keep the installation lean.

### Required Plugins

| Plugin                        | Purpose                                                     |
|-------------------------------|-------------------------------------------------------------|
| **Antispam Bee**              | Spam protection without cloud services (GDPR-friendly, replaces Akismet) |
| **UpdraftPlus** (free)        | Scheduled backups to S3 (supplements the cron-based backup) |
| **Compressor.io / ShortPixel / Imagify** (pick one free option) | Automatic image optimisation on upload (old scanned photos can be large) |
| **WP Super Cache** or **W3 Total Cache** | Page caching for performance                    |
| **Yoast SEO** (free)         | Basic SEO: sitemaps, meta descriptions, readability hints    |

### Optional (install but keep deactivated — for the owner to enable later)

| Plugin                        | Purpose                                                     |
|-------------------------------|-------------------------------------------------------------|
| **Statify**                   | Privacy-friendly analytics (no cookies, GDPR-compliant)     |
| **TablePress**                | For occasional tabular content (family timelines, etc.)     |
| **NextGEN Gallery** or **flavor flavor flavor flavor flavor** | Dedicated photo gallery if built-in gallery block isn't enough |

### Explicitly Avoid

- Akismet (sends data to US servers — GDPR concern)
- Jetpack (heavy, unnecessary features, GDPR concerns)
- Any plugin that adds cookie-based tracking without consent

---

## 7. GDPR & Legal Compliance (Austria)

This is critical for an Austrian website, even a personal blog.

### Cookie Consent

- Install a **cookie consent banner** plugin that is GDPR-compliant. Recommended: **flavor flavor flavor flavor flavor flavor flavor flavor flavor** or **flavor flavor flavor flavor flavor flavor** (both free).
- Default behaviour: **no cookies until consent** (opt-in, not opt-out)
- The blog itself should set minimal or no cookies. WordPress session cookies are exempt (strictly necessary).

### Privacy Policy

- The Datenschutz page must exist (created in Section 5)
- The owner must fill it in with details about: what data is collected (server logs, cookies if any), hosting provider (AWS), contact information, rights of data subjects
- Consider linking to a German-language privacy policy generator (e.g. e-recht24.de or oesterreich.gv.at resources) in a comment on the page for the owner's reference

### Impressum

- Required under Austrian Mediengesetz § 25 for any website with editorial content
- Page structure provided in Section 5; owner fills in personal details

---

## 8. Security Hardening

### WordPress Level

- Change the default **database table prefix** from `wp_` to something custom (e.g. `fam_`)
- **Disable XML-RPC** (not needed; attack vector)
- **Disable file editing** in wp-admin: add `define('DISALLOW_FILE_EDIT', true);` to `wp-config.php`
- **Limit login attempts**: install **Limit Login Attempts Reloaded** or configure Nginx rate limiting on `/wp-login.php`
- **Hide WordPress version** number from HTML source
- Set strong passwords for both user accounts (generate and provide to owner securely)

### Server Level

- Keep Ubuntu and all packages updated (`unattended-upgrades` enabled)
- Configure **fail2ban** for SSH and WordPress login brute-force protection
- SSH access via **key-based authentication only** (disable password auth)
- Restrict SSH inbound to the owner's IP address(es) in the Security Group
- Nginx: disable directory listing, hide server version header

---

## 9. Backup Strategy

Backups are critical — the stories are irreplaceable.

| What                 | How                                        | Frequency  | Retention     |
|----------------------|--------------------------------------------|------------|---------------|
| Database             | `mysqldump` → gzip → upload to S3          | Daily      | 30 days       |
| Media files          | `aws s3 sync wp-content/uploads/ s3://...`  | Daily      | Versioned (S3 versioning enabled) |
| Full site (plugins, themes, config) | UpdraftPlus scheduled backup to S3 | Weekly | 4 weeks       |

- All backups stored in a dedicated S3 bucket with **versioning enabled**
- S3 lifecycle policy: transition to **S3 Glacier** after 90 days, delete after 365 days
- Set up a cron job on the EC2 instance for the database and media sync
- Test restore procedure after initial setup to verify backups work

---

## 10. Performance

- **Caching**: WP Super Cache or W3 Total Cache (see Plugins section)
- **Image optimisation**: automatic on upload via plugin; also consider serving WebP where supported
- **Gzip compression**: enable in Nginx config
- **Browser caching**: set appropriate `Cache-Control` and `Expires` headers in Nginx for static assets
- **PHP OPcache**: enable and configure in `php.ini`
- **Target**: homepage loads in under 3 seconds on a 4G mobile connection

---

## 11. Sample Content

Create **2 sample posts** in German so the father can see how the blog looks with real-ish content and understand the workflow. These will serve as templates he can reference.

### Sample Post 1

- **Title:** "Wie Opa seinen ersten Traktor kaufte"
- **Category:** Großeltern
- **Tags:** Opa, Landwirtschaft, 1960er
- **Content:** 3–4 paragraphs of placeholder German text telling a fictional but realistic family anecdote about a grandfather buying his first tractor. Include a placeholder for a featured image (use a royalty-free stock photo or a simple placeholder image).
- **Featured image:** yes (placeholder)

### Sample Post 2

- **Title:** "Der geheimnisvolle Koffer auf dem Dachboden"
- **Category:** Kurioses
- **Tags:** Dachboden, Familiengeheimnis
- **Content:** 3–4 paragraphs about discovering a mysterious suitcase in an attic. Demonstrate use of an **image gallery block** (with 2–3 placeholder images) within the post.
- **Featured image:** yes (placeholder)

---

## 12. Post-Deployment Checklist

After the site is live, verify:

- [ ] WordPress admin loads at `https://[domain]/wp-admin` and is in German
- [ ] Father's Editor account can log in, create a draft, add images, and publish
- [ ] Published posts display correctly on desktop and mobile
- [ ] Images upload, resize, and display without errors
- [ ] SSL certificate is valid and HTTP redirects to HTTPS
- [ ] Cookie consent banner appears on first visit
- [ ] Impressum and Datenschutz pages are accessible
- [ ] Comments are disabled on all posts and pages
- [ ] Search engines can access the site (check `robots.txt` and sitemap)
- [ ] Backups run on schedule and files appear in S3
- [ ] Billing alert is configured in AWS
- [ ] `wp-login.php` is protected against brute-force
- [ ] SSH is key-only and IP-restricted
- [ ] Sample posts display correctly with categories, tags, and images

---

## 13. Python Utility Scripts

The WordPress application runs on PHP (this is non-negotiable — it's what WordPress is built on). However, the site owner is most comfortable with Python, so all custom tooling, automation, and scripting around the blog should be written in **Python 3.10+**.

All scripts live in a dedicated directory on the EC2 instance: `/home/ubuntu/blog-tools/`. Each script should include a docstring, argument parsing via `argparse`, and logging to stdout. Use a shared `requirements.txt` in the `blog-tools/` directory. Install dependencies in a **virtualenv** (`/home/ubuntu/blog-tools/.venv/`).

### 13.1 Backup Scripts (Day 1 — required)

#### `backup_database.py`

- Runs `mysqldump` for the WordPress database, compresses the output with gzip
- Uploads the resulting `.sql.gz` file to the S3 backup bucket under the key pattern `backups/db/YYYY-MM-DD_HH-MM.sql.gz`
- Deletes local dump after successful upload
- Retains the last 30 daily backups in S3 (deletes older ones, or rely on S3 lifecycle policy)
- Dependencies: `boto3`, `subprocess` (stdlib)
- Scheduled via **cron**: daily at 03:00 Vienna time

#### `backup_media.py`

- Syncs `wp-content/uploads/` to the S3 backup bucket under `backups/media/` using `boto3`'s S3 transfer utilities (equivalent to `aws s3 sync`)
- Only uploads new or modified files (compare by size/mtime)
- Logs the number of files synced
- Dependencies: `boto3`
- Scheduled via **cron**: daily at 03:30 Vienna time

#### `backup_verify.py`

- Checks that today's database backup exists in S3 and is non-zero size
- Checks that the media backup prefix contains a reasonable number of objects
- Sends a simple notification on failure (initially: writes to a log file; future enhancement: SNS email alert)
- Scheduled via **cron**: daily at 04:00 Vienna time

### 13.2 Image Processing Scripts (Day 1 — required)

#### `prepare_photos.py`

- Batch-processes scanned family photos before upload to WordPress
- Takes an input directory and output directory as arguments
- For each image:
  - Auto-rotates based on EXIF orientation
  - Strips EXIF metadata except date taken (privacy: removes GPS, camera serial, etc.)
  - Resizes to a maximum dimension of 2400px on the longest side (preserving aspect ratio) — large enough for full-width display but not wastefully huge
  - Converts to JPEG at 85% quality if not already JPEG
  - Optionally converts to WebP as an additional output (`--webp` flag)
- Logs original vs. output file sizes
- Dependencies: `Pillow`

### 13.3 Content Management Scripts (Day 1 — nice to have)

#### `import_posts.py`

- Reads a CSV or JSON file containing post data (title, content, category, tags, date) and creates WordPress posts via the **WordPress REST API** (`/wp-json/wp/v2/posts`)
- Authenticates using **Application Passwords** (WordPress built-in feature, no plugin needed)
- Supports a `--draft` flag to create posts as drafts (default) or `--publish` to publish immediately
- Handles image uploads: if a row references a local image path, uploads it via the REST API media endpoint and sets it as the featured image
- Dependencies: `requests`

### 13.4 Monitoring & Maintenance Scripts (Phase 2 — future)

These are not required for initial deployment but should be built over time as learning exercises:

#### `health_check.py`

- Pings the blog's homepage and checks for HTTP 200
- Checks SSL certificate expiry date and warns if < 14 days
- Checks disk usage on the EC2 instance and warns if > 80%
- Checks that WordPress cron (wp-cron) is running
- Future: send results to CloudWatch custom metrics or SNS
- Dependencies: `requests`, `subprocess` (stdlib)

#### `update_check.py`

- Queries the WordPress REST API or uses `wp-cli` to check for available updates (WordPress core, plugins, themes)
- Outputs a summary of what needs updating
- Does NOT auto-apply updates (the owner should review and apply manually)
- Dependencies: `requests` or `subprocess` (for wp-cli)

### 13.5 AWS Learning Scripts (Phase 2 — future)

#### `infra_status.py`

- Uses `boto3` to display a summary of the blog's AWS resources: EC2 instance state, S3 bucket size and object count, estimated monthly cost (via Cost Explorer API)
- Intended as a learning exercise for the AWS SDK
- Dependencies: `boto3`

### 13.6 Cron Schedule Summary

| Time (Europe/Vienna) | Script                | Purpose                    |
|----------------------|-----------------------|----------------------------|
| 03:00                | `backup_database.py`  | Daily database backup      |
| 03:30                | `backup_media.py`     | Daily media sync to S3     |
| 04:00                | `backup_verify.py`    | Verify today's backups     |

Cron entries should be installed under the `ubuntu` user's crontab. The virtualenv must be activated in the cron command (use the full path to the venv's Python interpreter).

---

## 14. Out of Scope (Future Enhancements)

The following are explicitly **not** part of the initial build but may be added later:

- Newsletter / email subscription for new posts
- Multi-author setup (other family members writing)
- Interactive family tree (genealogy plugin or custom page)
- Migration to RDS, CloudFront, or Route 53
- Custom theme development
- Multilingual support (e.g. English translations)
- Video or audio embedding

---

## 15. Constraints & Assumptions

- The EC2 instance will be provisioned manually by the owner as a learning exercise; this spec does not include Terraform/CloudFormation templates (but the builder may suggest them)
- The World4You domain is already registered; DNS records will be pointed manually
- The owner will provide the actual family name, real content, and personal details for the Impressum after deployment
- All placeholder content should be clearly marked as such so the owner knows what to replace
- No budget for premium plugins or themes in the initial build
