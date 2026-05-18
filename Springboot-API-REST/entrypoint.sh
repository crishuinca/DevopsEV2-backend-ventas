#!/bin/sh
set -e

DB_HOST="${DB_HOST:-mysql}"
DB_PORT="${DB_PORT:-3306}"
echo "Esperando MySQL en ${DB_HOST}:${DB_PORT}..."

until nc -z "$DB_HOST" "$DB_PORT"; do
  echo "MySQL no disponible aún..."
  sleep 3
done

echo "MySQL disponible, iniciando backend ventas..."
exec java -jar /app/app.jar
