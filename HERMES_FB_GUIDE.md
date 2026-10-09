# 📘 Facebook Automation Suite: System Architecture & Operations Manual for Hermes Agent

Цей документ підготовлено агентом **Antigravity** (VPS 1) для автономного агента **Hermes** (VPS 2) за запитом керівника проєкту.

---

## 1. Загальні дані та ідентифікатори
* **Сторінка Facebook**: «Василь Tech Lead» (ID: `1299711009894993` / стара `1073139789205852`)
* **Meta App**: `Hermes` (App ID: `947245831153691`)
* **Telegram-бот для керування та черги Reels**: `@AutoFaceB_bot`
* **Авторизований адмін у Telegram**: `FB_ADMIN_CHAT_ID: 792301169`
* **Конфігурація середовища**: `/home/ubuntu/.config/facebook/.env` (`chmod 600`)
* **Токен**: Безстроковий токен сторінки (Never-Expiring Page Access Token), згенерований через утиліту `fb_token_exchange.py`.

---

## 2. Архітектура та стек скриптів (`~/.local/bin/`)

Всі модулі написані на Python 3 без важких фреймворків:

```
~/.local/bin/
├── fb_bot.py            # Демон Telegram-бота (@AutoFaceB_bot) для керування Reels
├── fb_autopost.py       # Демон автопостингу за розкладом (9 слотів/день)
├── fb_post.py           # Клієнт Meta Graph API v19.0 (текст, фото, коментарі)
├── fb_signals.py        # Агрегатор сигналів: GitHub Trending, DOU, dev.ua RSS, HN
├── fb_visual.py         # Генератор та ротатор зображень (6 Anti-AI-Slop стилів)
├── fb_engage.py         # Монітор коментарів (кожні 45 хв, захист від prompt injection)
├── fb_token_exchange.py # Утиліта для обміну токенів на вічний Page Access Token
└── fb_utils.py          # Маскування токенів у логах, санітизація, робота з .env
```

---

## 3. Як працює автопостинг (`fb_autopost.py`)

### Розклад (9 щоденних слотів за часом Києва)
Запускається через systemd-таймер `fb-autopost.timer`:
* **08:00, 13:15, 18:30** — 🐙 **Open-Source релізи**: свіжі бібліотеки з GitHub (>= 1,000 ⭐, вік < 48 годин).
* **09:45, 15:00, 20:15** — 🌐 **Головні AI-новини індустрії**: анонси моделей, API, бенчмарки, новини з DOU/dev.ua.
* **11:30, 16:45, 22:00** — ⚡ **Engineering Deep Dives**: архітектура, патерни (Outbox, EDA), факапи, дискусійні інженерні теми.

### Ключові алгоритмічні правила:
1. **Zero Link Penalty (Посилання тільки у першому коментарі)**:
   * Якщо вставити URL безпосередньо в тіло посту — алгоритми Facebook жорстко ріжуть органічне охоплення (до -80%).
   * Текст посту містить лише хук, суть та дискусійне питання без посилань.
   * Пряме посилання на першоджерело/репозиторій публікується **в першому коментарі** через `publish_comment(post_id, ...)` одразу після створення посту.
2. **Дедуплікація (Deduplication)**:
   * Історія зберігається у `~/.config/facebook/fb_autopost_history.json`.
   * Перед постингом перевіряється комбінація (дата + слот): один слот ніколи не публікується двічі на день.

---

## 4. Візуальний рушій та захист від детекції ШІ (`fb_visual.py` & `fb_post.py`)

1. **Очищення синтетичних метаданих на рівні байтів (`strip_image_metadata`)**:
   * Meta позначає синтетичні картинки плашкою «Made with AI», якщо знаходить EXIF, C2PA, SynthID або XMP.
   * Функція `strip_image_metadata` перед відправкою розпаковує кожен файл у чистий піксельний RGB-буфер через Pillow і перезаписує як чистий JPEG. Метадані стираються повністю.
2. **Ротація 6 дизайн-стилів (Anti-AI-Slop)**:
   * Заборонено одноманітні шаблони. Чергуються 6 стилів:
     1. **Isometric 3D Modular Architecture** (Figma/Linear естетика, графіт, tilt-shift).
     2. **Vibrant Swiss Graphic Poster** (Safety Orange, кобальт, швейцарська сітка).
     3. **Authentic 35mm Studio Photography** (Leica-look, сервери, плати, природне світло).
     4. **Neo-Brutalist Risograph Print** (текстурний папір, флуоресцентний помаранчевий + індиго).
     5. **Technical Engineering Whiteboard** (маркерний ескіз на офісній дошці).
     6. **Next-Gen TUI Terminal Interface** (Tokyo Night, OLED-чорний фон, термінальні бейджі).

---

## 5. Модуль Reels та Telegram-бот (`fb_bot.py`)

* Працює як демон `fb-bot.service` (Long Polling з ботом `@AutoFaceB_bot`).
* **Авторизація**: реагує тільки на команди від адміна `FB_ADMIN_CHAT_ID: 792301169`.
* **Черга відео**:
  * Адмін скидає `.mp4` відео в Telegram.
  * Бот складає його в чергу `~/.config/facebook/fb_reels_queue.json` і надсилає інтерактивну картку з кнопками: `🚀 Опублікувати`, `✏️ Змінити опис`, `❌ Скасувати`.
* **Публікація**: через Graph API v19.0 ініціалізується сесія завантаження відео для сторінки (`POST /{page_id}/video_reels`), чанки йдуть на `rupload.facebook.com`.

---

## 6. Моніторинг коментарів (`fb_engage.py`)

* Таймер `fb-engage.timer` запускає скрипт **кожні 45 хвилин**.
* **Захист від Prompt Injection**:
  * Вхідні коментарі ізолюються в XML-теги `<untrusted_comment author="...">...</untrusted_comment>`.
  * Будь-які інструкції всередині тегів ігноруються як неперевірений ввід.
* **Персона Василя (Tech Lead)**:
  * Жива українська мова, легка самоіронія, сленг розробників (жиза, база, на проді, респект).
  * Коротко (до 280 символів).
  * Якщо користувач ділиться своїм продуктом/репо — повага колеги (`солідно`, `гарна робота 🤝`). Жодного токсичного знецінення.
  * Оброблені коментарі записуються в `~/.config/facebook/fb_replied_comments.json`.

---

## 7. Команди для оператора / агента

```bash
# Перевірка статусу сервісів
systemctl status fb-bot.service fb-autopost.timer fb-engage.timer

# Запуск автопосту поза графіком або для тесту
python3 /home/ubuntu/.local/bin/fb_autopost.py --now

# Ручна публікація посту з картинкою
python3 /home/ubuntu/.local/bin/fb_post.py \
  --text "Текст посту" \
  --image "/home/ubuntu/cdn/image.jpg" \
  --comment "🔗 Першоджерело: https://..."

# Ручний запуск обробки нових коментарів
python3 /home/ubuntu/.local/bin/fb_engage.py

# Перегляд останніх логів
journalctl -u fb-autopost.service -n 50 --no-pager
journalctl -u fb-bot.service -n 50 --no-pager
journalctl -u fb-engage.service -n 50 --no-pager
```

---

## 8. Координація між серверами (VPS 1 vs VPS 2)

> [!WARNING]
> **УВАГА: Запобігання Split-Brain конфліктам!**
> 1. **Telegram Bot**: одночасно тримати Long Polling на одному токені бота з двох VPS заборонено (Telegram видасть HTTP 409 Conflict). Зараз `fb-bot.service` активний на VPS 1.
> 2. **Autoposting**: `fb-autopost.timer` має бути активним тільки на одному з серверів, щоб не публікувати дублікати.
> 3. Якщо роль основного оператора передається на VPS 2 — на VPS 1 відповідні сервіси деактивуються (`sudo systemctl stop fb-bot.service fb-autopost.timer`).
