#!/usr/bin/env bash
# Seed Ma3ak — lance le script Node (lit .env à la racine)
# Usage: ./scripts/seed.sh   ou   bash scripts/seed.sh

set -e
cd "$(dirname "$0")/.."
exec node scripts/seed.js
