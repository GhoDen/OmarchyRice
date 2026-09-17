#!/usr/bin/env bash
set -euo pipefail

DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
MODELS_DIR="$DATA_HOME/com.ticklab.biopass/models"
BASE_URL="https://github.com/TickLabVN/biopass/releases/latest/download"
DOWNLOAD_TIMEOUT=4

MODELS=(
  yolov8n-face.onnx
  edgeface_s_gamma_05.onnx
  edgeface_xs_gamma_06.onnx
  mobilenetv3_antispoof.onnx
  minifas_v2.onnx
)

download_model() {
  local filename="$1" destination temporary etag
  destination="$MODELS_DIR/$filename"
  temporary="$(mktemp "$MODELS_DIR/.${filename}.XXXXXX")"
  etag="$destination.etag"

  if timeout --kill-after=1s "${DOWNLOAD_TIMEOUT}s" curl --fail --location --silent --show-error \
    --retry 3 --retry-delay 2 \
    --etag-compare "$etag" --etag-save "$etag" \
    --output "$temporary" "$BASE_URL/$filename"; then
    if [[ -s "$temporary" ]]; then
      mv -- "$temporary" "$destination"
      echo "Biopass: updated $filename"
    else
      rm -f -- "$temporary"
      echo "Biopass: $filename is already current"
    fi
  else
    local status=$?
    rm -f -- "$temporary"
    if [[ "$status" -eq 124 || "$status" -eq 137 ]]; then
      echo "Biopass: Skipping $filename (download timed out after ${DOWNLOAD_TIMEOUT}s)"
      return 0
    fi
    echo "Biopass: failed to download $filename" >&2
    return 1
  fi
}

mkdir -p "$MODELS_DIR"
for model in "${MODELS[@]}"; do
  download_model "$model"
done
