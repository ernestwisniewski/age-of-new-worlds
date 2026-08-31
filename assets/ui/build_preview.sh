#!/usr/bin/env bash
set -euo pipefail

ui_directory="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
preview_directory="$ui_directory/preview"

if ! command -v cwebp >/dev/null 2>&1; then
  echo "cwebp is required (install the WebP tools package)." >&2
  exit 1
fi
if ! command -v jq >/dev/null 2>&1; then
  echo "jq is required to read FreeTexturePacker JSON files." >&2
  exit 1
fi

mkdir -p "$preview_directory"
find "$preview_directory" -type f -name '*.webp' -delete

count=0
shopt -s nullglob
json_files=("$ui_directory"/[0-9]*.json)
if ((${#json_files[@]} == 0)); then
  echo "No FreeTexturePacker JSON files found in $ui_directory." >&2
  exit 1
fi

for data in "${json_files[@]}"; do
  sheet="$(basename -- "$data" .json)"
  image="$(jq -er '.meta.image' "$data")"
  if [[ ! "$sheet" =~ ^[0-9]+$ || "$image" != "$sheet.webp" ]]; then
    echo "Invalid atlas metadata: data=$data image=$image" >&2
    exit 1
  fi

  source="$ui_directory/$image"
  output_directory="$preview_directory/$sheet"
  if [[ ! -f "$source" ]]; then
    echo "Missing atlas sheet: $source" >&2
    exit 1
  fi

  while IFS=$'\t' read -r frame_name x y width height; do
    region="${frame_name%.webp}"
    if [[ "$frame_name" != "$region.webp" || ! "$region" =~ ^[a-z0-9._-]+$ || \
      ! "$x" =~ ^[0-9]+$ || ! "$y" =~ ^[0-9]+$ || \
      ! "$width" =~ ^[0-9]+$ || ! "$height" =~ ^[0-9]+$ ]]; then
      echo "Invalid FreeTexturePacker frame: sheet=$sheet frame=$frame_name" >&2
      exit 1
    fi

    output="$output_directory/$frame_name"
    mkdir -p "$output_directory"
    cwebp \
      -quiet \
      -lossless \
      -exact \
      -z 6 \
      -crop "$x" "$y" "$width" "$height" \
      "$source" \
      -o "$output"
    ((count += 1))
  done < <(
    jq -er '
      .frames
      | to_entries[]
      | [.key, .value.frame.x, .value.frame.y, .value.frame.w, .value.frame.h]
      | @tsv
    ' "$data"
  )
done

if ((count == 0)); then
  echo "FreeTexturePacker JSON files do not contain any frames." >&2
  exit 1
fi

find "$preview_directory" -type d -empty -delete
echo "Generated $count lossless WebP previews in $preview_directory"
