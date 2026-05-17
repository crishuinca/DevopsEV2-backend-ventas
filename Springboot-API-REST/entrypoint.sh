#!/bin/sh
set -e

DB_HOST="${DB_HOST:-mysql}"
echo "Esperando MySQL en ${DB_HOST}:3306..."

until nc -z "$DB_HOST" 3306; do
  echo "MySQL no disponible aún..."
  sleep 3
done

echo "MySQL disponible, iniciando backend ventas..."
exec java -jar /app/app.jar
