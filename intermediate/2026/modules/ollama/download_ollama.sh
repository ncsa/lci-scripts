#!/bin/bash

if [ -z "$1" ]; then
  echo "Usage: $0 <<versionversion>"
  exit 1
fi

VERSION=$1
DIR="$VERSION"
URL="https://github.com/ollama/ollama/releases/download/v${VERSION}/ollama-linux-amd64.tar.zst"
FILE="ollama-linux-amd64.tar.zst"

mkdir -p "$DIR"
cd "$DIR" || exit 1

echo "Downloading Ollama v${VERSION}..."
curl -L "$URL" -o "$FILE"

echo "Extracting..."
zstd -dc "$FILE" | tar -xf -

rm "$FILE"

echo "Done. Ollama v${VERSION} extracted to ${DIR}/"
