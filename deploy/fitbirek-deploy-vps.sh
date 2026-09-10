#!/bin/bash
printf '%s\n' 'RETIRED: use /opt/fit/DEPLOY.md and the Docker/Caddy deployment.' >&2
exit 2
# Historical implementation below is unreachable; retained for reference only.
# =====================================================================
# Skrypt wdrożenia FitBirek (Flutter Web) na własny VPS
# Uruchom NA VPS (nie w sandboxie!), jako root lub z sudo.
#
# Zakłada:
#   - Ubuntu/Debian z apt (jeśli inna dystrybucja, dostosuj instalację nginx/certbot)
#   - Domena fit.birek.online już wskazuje przez A/AAAA rekord na IP tego VPS
#     (DNS propagacja może zająć do 24h, ale zwykle 5-15 min)
#   - Plik fitbirek-web-release.tar.gz jest już wgrany na VPS (np. przez scp)
# =====================================================================
set -e

TARBALL="${1:-fitbirek-web-release.tar.gz}"
DOMAIN="fit.birek.online"
WEBROOT="/var/www/fitbirek"

if [ ! -f "$TARBALL" ]; then
    echo "❌ Nie znaleziono $TARBALL w bieżącym katalogu."
    echo "   Wgraj go najpierw np.: scp fitbirek-web-release.tar.gz user@twoj-vps:~/"
    exit 1
fi

echo "🚀 FitBirek — wdrożenie na VPS ($DOMAIN)"
echo ""

# 1. Instalacja nginx + certbot (jeśli nie ma)
if ! command -v nginx &> /dev/null; then
    echo "📦 Instaluję nginx..."
    sudo apt update && sudo apt install -y nginx
fi

if ! command -v certbot &> /dev/null; then
    echo "📦 Instaluję certbot (Let's Encrypt SSL)..."
    sudo apt install -y certbot python3-certbot-nginx
fi

# 2. Rozpakowanie aplikacji
echo "📂 Rozpakowuję aplikację do $WEBROOT..."
sudo mkdir -p "$WEBROOT"
sudo tar -xzf "$TARBALL" -C "$WEBROOT"
# tarball ma strukturę web/... - jeśli chcesz web/ jako podkatalog to jest już OK,
# WEBROOT/web/ będzie root'em w konfiguracji nginx (zgodnie z fitbirek-nginx.conf)
sudo chown -R www-data:www-data "$WEBROOT"

# 3. Konfiguracja nginx
echo "⚙️  Konfiguruję nginx..."
if [ ! -f "fitbirek-nginx.conf" ]; then
    echo "⚠️  Brak fitbirek-nginx.conf w bieżącym katalogu — wgraj go razem z tarballem."
    exit 1
fi
sudo cp fitbirek-nginx.conf "/etc/nginx/sites-available/$DOMAIN"
sudo ln -sf "/etc/nginx/sites-available/$DOMAIN" "/etc/nginx/sites-enabled/$DOMAIN"

# usuń domyślny site jeśli kolidowałby (opcjonalnie, odkomentuj jeśli potrzebne)
# sudo rm -f /etc/nginx/sites-enabled/default

echo "🔍 Testuję konfigurację nginx..."
sudo nginx -t

echo "🔄 Restartuję nginx..."
sudo systemctl restart nginx

# 4. SSL (Let's Encrypt) — wymaga że DNS już wskazuje na ten VPS!
echo ""
echo "🔒 Konfiguruję SSL (Let's Encrypt)..."
echo "   UWAGA: to zadziała tylko jeśli DNS dla $DOMAIN już wskazuje na ten serwer!"
read -p "   Czy DNS jest już skonfigurowany i propagowany? (t/n): " dns_ready

if [ "$dns_ready" = "t" ] || [ "$dns_ready" = "T" ]; then
    sudo certbot --nginx -d "$DOMAIN" --non-interactive --agree-tos -m twoj-email@example.com --redirect
    echo "✅ SSL skonfigurowany! Certyfikat auto-odnawia się przez certbot timer."
else
    echo "⏭️  Pomijam SSL na razie. Po propagacji DNS uruchom:"
    echo "   sudo certbot --nginx -d $DOMAIN"
fi

echo ""
echo "✅ Wdrożenie zakończone!"
echo "🔗 Sprawdź: http://$DOMAIN (lub https:// jeśli SSL skonfigurowany)"
