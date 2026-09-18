#!/bin/bash
# setup-certs.sh
# Скрипт автоматической установки корневых сертификатов Минцифры РФ для Docker / Node.js / n8n
# Автор: Samartsev AI (https://samartsev.ru | https://t.me/samartsev_blog)

set -e

CERTS_DIR="/opt/certs"
BUNDLE_FILE="${CERTS_DIR}/russian_trusted_root_ca.crt"

echo "=== 1. Создание директории для сертификатов: ${CERTS_DIR} ==="
mkdir -p "${CERTS_DIR}"

echo "=== 2. Скачивание официальных сертификатов НУЦ Минцифры РФ (Госуслуги) ==="
# Корневой сертификат (Russian Trusted Root CA)
curl -k -s -o "${CERTS_DIR}/root_ca.cer" "https://gu-st.ru/content/Other/doc/russian_trusted_root_ca.cer"

# Выпускающий/промежуточный сертификат (Russian Trusted Sub CA)
curl -k -s -o "${CERTS_DIR}/sub_ca.cer" "https://gu-st.ru/content/Other/doc/russian_trusted_sub_ca.cer"

echo "=== 3. Сборка единого PEM-бандла ==="
cat "${CERTS_DIR}/root_ca.cer" > "${BUNDLE_FILE}"
echo "" >> "${BUNDLE_FILE}"
cat "${CERTS_DIR}/sub_ca.cer" >> "${BUNDLE_FILE}"

# Удаляем временные файлы
rm -f "${CERTS_DIR}/root_ca.cer" "${CERTS_DIR}/sub_ca.cer"

echo "=== 4. Настройка прав доступа (чтение для контейнера) ==="
chmod 644 "${BUNDLE_FILE}"

CERT_COUNT=$(grep -c 'BEGIN CERTIFICATE' "${BUNDLE_FILE}" || true)
echo "✅ Успешно! Бандл создан: ${BUNDLE_FILE}"
echo "В сертификате найдено корневых/промежуточных подписей: ${CERT_COUNT}"
echo ""
echo "Теперь прокиньте файл в docker-compose.yml:"
echo "  volumes:"
echo "    - /opt/certs/russian_trusted_root_ca.crt:/home/node/certs/russian_trusted_root_ca.crt:ro"
echo "  environment:"
echo "    - NODE_EXTRA_CA_CERTS=/home/node/certs/russian_trusted_root_ca.crt"
