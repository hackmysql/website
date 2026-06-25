#!/bin/bash

set -eu

if [[ ! -d ".git" ]]; then
  echo "Run from repo root directory" >&2
  exit 1
fi

rm -rf public/*
hugo server \
  --minify \
  --disableKinds rss,taxonomy,term \
  --baseURL http://localhost:1313
