#!/bin/bash
set -e

echo "Starting Satis build..."
/satis/bin/satis build /build/satis.json /build/output --ansi -vvv

echo "Starting cron for automatic rebuilds (every 6 hours)..."
crond -b -l 2

echo "Build complete. Starting nginx..."
exec nginx -c /etc/nginx/nginx.conf -g 'daemon off;'
