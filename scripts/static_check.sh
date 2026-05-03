#!/usr/bin/env bash
set -euo pipefail

failures=0

echo "Checking for SELECT * in SQL files..."
if grep -RInE 'select[[:space:]]+\*' db --include='*.sql'; then
    echo "Avoid SELECT * in exercise SQL. Select only required columns." >&2
    failures=$((failures + 1))
fi

echo "Checking for lower(email) without matching index artifact..."
if grep -RInE 'lower\\((u\\.)?email\\)' db/queries --include='*.sql' >/dev/null; then
    if ! grep -RInE 'lower\\(email\\)' db/indexes.sql db/queries/search_strategies.sql >/dev/null; then
        echo "lower(email) appears in queries but no expression index artifact was found." >&2
        failures=$((failures + 1))
    fi
fi

echo "Checking Terraform formatting if terraform is installed..."
if command -v terraform >/dev/null 2>&1; then
    terraform -chdir=infra/terraform fmt -check
else
    echo "terraform not installed; skipping terraform fmt."
fi

if [[ "$failures" -gt 0 ]]; then
    exit 1
fi

echo "Static checks passed."
