# n8n + GigaChat Docker Starter Kit 🚀

> **Готовый шаблон для безопасного подключения Sberbank GigaChat API в self-hosted n8n (Docker) с поддержкой сертификатов Минцифры РФ.**

[![n8n](https://img.shields.io/badge/n8n-Workflow-FF6D5A?logo=n8n&logoColor=white)](https://n8n.io)
[![Docker](https://img.shields.io/badge/Docker-Compose-2496ED?logo=docker&logoColor=white)](https://www.docker.com)
[![GigaChat](https://img.shields.io/badge/Sber-GigaChat_API-21A038)](https://developers.sber.ru)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

---

## 🛑 В чем проблема?

При попытке сделать HTTP-запрос к API Сбербанка (`https://ngw.devices.sberbank.ru:9443` или `https://gigachat.devices.sberbank.ru`) из чистого Docker-контейнера n8n, нода падает с ошибкой:

```text
Error: unable to verify the first certificate
code: 'UNABLE_TO_VERIFY_LEAF_SIGNATURE'
```

### Почему так происходит?
GigaChat использует SSL-сертификаты, выпущенные Национальным удостоверяющим центром (НУЦ) **Минцифры РФ**. 
Стандартное хранилище доверенных сертификатов Node.js (на котором работает n8n) основано на Mozilla NSS и **не содержит** корневой сертификат Минцифры. Node.js буквально не доверяет подписи Сбера.

### ⚠️ Почему НЕЛЬЗЯ использовать `NODE_TLS_REJECT_UNAUTHORIZED=0`?
Самый частый вредный совет на форумах — прописать в `docker-compose.yml`:
```yaml
environment:
  - NODE_TLS_REJECT_UNAUTHORIZED=0
```
**Это фатальная дыра в безопасности:**
1. Отключается проверка SSL **для ВСЕХ** внешних запросов n8n (Telegram, Google, внешние CRM, платежные шлюзы, вебхуки).
2. Любой перехват трафика (MITM) позволит злоумышленникам подменять ответы или перехватывать ваши API-ключи и данные пользователей.

---

## ✅ Правильное решение (Этот репозиторий)

Node.js штатно поддерживает переменную окружения `NODE_EXTRA_CA_CERTS`. Она позволяет добавить сертификат Минцифры к стандартному хранилищу, **сохраняя 100% строгую проверку SSL для всех остальных сервисов**.

---

## ⚡ Быстрый старт (За 3 шага)

### Шаг 1. Скачайте и соберите бандл сертификатов на сервере
Скрипт автоматически скачает официальный корневой и выпускающий сертификаты с Госуслуг и объединит их в `/opt/certs/russian_trusted_root_ca.crt`:

```bash
chmod +x setup-certs.sh
sudo ./setup-certs.sh
```

*(Либо просто выполните команды из скрипта `setup-certs.sh` вручную в консоли вашего VPS).*

### Шаг 2. Запустите n8n через Docker Compose
В `docker-compose.yml` уже прописано безопасное монтирование сертификата:

```yaml
services:
  n8n:
    image: n8nio/n8n:latest
    environment:
      - NODE_EXTRA_CA_CERTS=/home/node/certs/russian_trusted_root_ca.crt
    volumes:
      - n8n_data:/home/node/.n8n
      - /opt/certs/russian_trusted_root_ca.crt:/home/node/certs/russian_trusted_root_ca.crt:ro
```

Запустите контейнер:
```bash
docker compose up -d
```

### Шаг 3. Проверьте валидацию SSL
Выполните однострочник внутри контейнера n8n:
```bash
docker exec -it n8n-gigachat node -e "require('https').get('https://gigachat.devices.sberbank.ru', (r) => console.log('SSL OK! Status:', r.statusCode)).on('error', console.error)"
```
Если в ответе статус `403` или `200` — поздравляем! TLS-соединение с защитой Минцифры РФ установлено штатно и безопасно.

---

## 📦 Готовый шаблон воркфлоу (`workflows/gigachat-basic-chat.json`)

Вы можете просто скопировать содержимое файла `workflows/gigachat-basic-chat.json` и нажать **Ctrl+V** прямо на холсте вашего n8n.

* **Что делает шаблон:**
  1. Автоматически запрашивает OAuth-токен на защищенном шлюзе `https://ngw.devices.sberbank.ru:9443/api/v2/oauth`.
  2. Передает токен и запрос пользователя в `https://gigachat.devices.sberbank.ru/api/v1/chat/completions`.
  3. Извлекает чистый ответ модели в удобный JSON-формат.

---

## 👨‍💻 Об авторе

Разработано командой **[Samartsev AI](https://samartsev.tech)** — внедрение ИИ-агентов, LLM и автоматизации бизнес-процессов.

* 🌐 **Сайт:** [samartsev.tech](https://samartsev.tech)
* 📢 **Telegram-канал:** [@samartsev_blog](https://t.me/samartsev_blog) — реальный опыт внедрения ИИ в российский бизнес без глянца.
* 📝 **Статья на Хабре:** [Подружили n8n с GigaChat в Docker: корневой сертификат Минцифры, NODE_TLS и 3 дня боли](https://habr.com)

---

## 📄 Лицензия

MIT License — используйте свободно в своих коммерческих и личных проектах.
