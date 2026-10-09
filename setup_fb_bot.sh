#!/bin/bash
set -e

echo "=========================================================="
echo "🚀 Встановлення Facebook Automation Suite для Hermes Agent"
echo "=========================================================="

# 1. Підготовка каталогів
mkdir -p "$HOME/.local/bin"
mkdir -p "$HOME/.config/facebook"
mkdir -p "$HOME/cdn"

# 2. Завантаження та розпакування кодової бази
echo "📦 Завантаження модулів fb_* у ~/.local/bin/..."
TAR_URL="https://raw.githubusercontent.com/Finchua12/cdn/main/fb_suite.tar.gz"
curl -sL "$TAR_URL" -o /tmp/fb_suite.tar.gz
tar -xzf /tmp/fb_suite.tar.gz -C "$HOME/.local/bin/"
rm -f /tmp/fb_suite.tar.gz
chmod +x "$HOME/.local/bin"/fb_*.py
echo "✓ Скрипти успішно встановлено в ~/.local/bin/"

# 3. Перевірка Python залежностей (Pillow)
echo "🐍 Перевірка Python бібліотек..."
if ! python3 -c "import PIL" &>/dev/null; then
    echo "Встановлення python3-pil / Pillow..."
    sudo apt-get update -qq && sudo apt-get install -y -qq python3-pil python3-pip || pip3 install --quiet pillow
fi
echo "✓ Python середовище готове."

# 4. Встановлення systemd-юнітів
echo "⚙️ Створення systemd-юнітів у /etc/systemd/system/..."

sudo tee /etc/systemd/system/fb-bot.service > /dev/null << 'EOF'
[Unit]
Description=VasylAI Facebook Telegram Bot Daemon
After=network.target

[Service]
Type=simple
User=ubuntu
WorkingDirectory=/home/ubuntu
EnvironmentFile=/home/ubuntu/.config/facebook/.env
Environment=PYTHONUNBUFFERED=1
ExecStart=/usr/bin/python3 /home/ubuntu/.local/bin/fb_bot.py
Restart=always
RestartSec=5
MemoryMax=120M
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

sudo tee /etc/systemd/system/fb-autopost.service > /dev/null << 'EOF'
[Unit]
Description=VasylAI Facebook Autopost Worker
After=network.target

[Service]
Type=oneshot
User=ubuntu
WorkingDirectory=/home/ubuntu
EnvironmentFile=/home/ubuntu/.config/facebook/.env
Environment=PYTHONUNBUFFERED=1
ExecStart=/usr/bin/python3 /home/ubuntu/.local/bin/fb_autopost.py --now
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

sudo tee /etc/systemd/system/fb-autopost.timer > /dev/null << 'EOF'
[Unit]
Description=VasylAI Facebook Autopost 9-times Daily Timer (3 OpenSource + 3 AI News + 3 Text)

[Timer]
OnCalendar=*-*-* 08:00:00 Europe/Kyiv
OnCalendar=*-*-* 09:45:00 Europe/Kyiv
OnCalendar=*-*-* 11:30:00 Europe/Kyiv
OnCalendar=*-*-* 13:15:00 Europe/Kyiv
OnCalendar=*-*-* 15:00:00 Europe/Kyiv
OnCalendar=*-*-* 16:45:00 Europe/Kyiv
OnCalendar=*-*-* 18:30:00 Europe/Kyiv
OnCalendar=*-*-* 20:15:00 Europe/Kyiv
OnCalendar=*-*-* 22:00:00 Europe/Kyiv
Persistent=true

[Install]
WantedBy=timers.target
EOF

sudo tee /etc/systemd/system/fb-engage.service > /dev/null << 'EOF'
[Unit]
Description=VasylAI Facebook Comment Engagement Worker
After=network.target

[Service]
Type=oneshot
User=ubuntu
WorkingDirectory=/home/ubuntu
EnvironmentFile=/home/ubuntu/.config/facebook/.env
Environment=PYTHONUNBUFFERED=1
ExecStart=/usr/bin/python3 /home/ubuntu/.local/bin/fb_engage.py
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

sudo tee /etc/systemd/system/fb-engage.timer > /dev/null << 'EOF'
[Unit]
Description=VasylAI Facebook Comment Engagement Timer (every 45min)

[Timer]
OnBootSec=5min
OnUnitActiveSec=45min
Persistent=true

[Install]
WantedBy=timers.target
EOF

sudo systemctl daemon-reload
echo "✓ Systemd-юніти зареєстровано."

echo "=========================================================="
echo "🎉 ВСТАНОВЛЕННЯ ЗАВЕРШЕНО!"
echo "Файли скриптів: $HOME/.local/bin/fb_*.py"
echo "Юніти: fb-bot.service, fb-autopost.timer, fb-engage.timer"
echo "=========================================================="
