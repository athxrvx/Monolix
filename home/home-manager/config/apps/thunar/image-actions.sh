set -euo pipefail

action="${1:-}"
shift || true

if [[ $# -eq 0 ]]; then
  exit 0
fi

output_for() {
  local file="$1" suffix="$2" extension="${3:-}" name stem directory output index
  name="$(basename -- "$file")"
  directory="$(dirname -- "$file")"
  if [[ "$name" == *.* ]]; then
    stem="${name%.*}"
    [[ -n "$extension" ]] || extension="${name##*.}"
  else
    stem="$name"
    [[ -n "$extension" ]] || extension="png"
  fi
  output="${directory}/${stem}-${suffix}.${extension}"
  index=2
  while [[ -e "$output" ]]; do
    output="${directory}/${stem}-${suffix}-${index}.${extension}"
    ((index += 1))
  done
  printf '%s\n' "$output"
}

wallpaper_directory() {
  local configured tilde
  configured=""
  if [[ -f "$HOME/.cache/kuro/theme.json" ]]; then
    configured="$(jq -r '.apps.wallpaperDir // empty' "$HOME/.cache/kuro/theme.json")"
  fi
  tilde="$(printf '\176')"
  [[ -n "$configured" ]] || configured="$tilde/Pictures/Wallpaper"
  if [[ "$configured" == "$tilde" ]]; then
    configured="$HOME"
  elif [[ "${configured:0:2}" == "${tilde}/" ]]; then
    configured="$HOME/${configured:2}"
  elif [[ "$configured" != /* ]]; then
    configured="$HOME/$configured"
  fi
  printf '%s\n' "$configured"
}

add_to_wallpapers() {
  local directory file name stem extension target index
  directory="$(wallpaper_directory)"
  mkdir -p -- "$directory"
  for file in "$@"; do
    [[ -f "$file" ]] || continue
    [[ "$(dirname -- "$file")" == "$directory" ]] && continue
    name="$(basename -- "$file")"
    target="$directory/$name"
    if [[ -e "$target" ]]; then
      if [[ "$name" == *.* ]]; then
        stem="${name%.*}"
        extension=".${name##*.}"
      else
        stem="$name"
        extension=""
      fi
      index=2
      target="$directory/${stem}-${index}${extension}"
      while [[ -e "$target" ]]; do
        ((index += 1))
        target="$directory/${stem}-${index}${extension}"
      done
    fi
    mv -- "$file" "$target"
  done
}

resize_images() {
  local geometry
  geometry="$(zenity --entry --title="Resize images" --text="Enter a percentage (50%) or maximum dimensions (1600x1200):" --entry-text="50%")" || return 0
  if [[ ! "$geometry" =~ ^[0-9]+([.][0-9]+)?%$ && ! "$geometry" =~ ^[0-9]+x[0-9]+$ ]]; then
    zenity --error --title="Invalid size" --text="Use a percentage such as 50% or dimensions such as 1600x1200." || true
    return 2
  fi
  for file in "$@"; do
    [[ -f "$file" ]] || continue
    output="$(output_for "$file" resized)"
    magick "$file" -auto-orient -resize "$geometry" "$output"
  done
}

convert_images() {
  local format extension file output
  format="$(zenity --list --radiolist --title="Convert images" --text="Choose an output format:" --column="Select" --column="Format" TRUE PNG FALSE JPEG FALSE WebP --width=400 --height=280)" || return 0
  [[ -n "$format" ]] || return 0
  case "$format" in
    PNG) extension="png" ;;
    JPEG) extension="jpg" ;;
    WebP) extension="webp" ;;
    *) return 2 ;;
  esac
  for file in "$@"; do
    [[ -f "$file" ]] || continue
    output="$(output_for "$file" converted "$extension")"
    case "$format" in
      JPEG) magick "$file" -auto-orient -background white -alpha remove -alpha off -quality 88 "$output" ;;
      WebP) magick "$file" -auto-orient -quality 88 "$output" ;;
      PNG) magick "$file" -auto-orient "$output" ;;
    esac
  done
}

case "$action" in
  rotate-left)
    for file in "$@"; do
      [[ -f "$file" ]] || continue
      magick "$file" -auto-orient -rotate -90 "$(output_for "$file" rotated-left)"
    done
    ;;
  rotate-right)
    for file in "$@"; do
      [[ -f "$file" ]] || continue
      magick "$file" -auto-orient -rotate 90 "$(output_for "$file" rotated-right)"
    done
    ;;
  flip-horizontal)
    for file in "$@"; do
      [[ -f "$file" ]] || continue
      magick "$file" -auto-orient -flop "$(output_for "$file" flipped-horizontal)"
    done
    ;;
  flip-vertical)
    for file in "$@"; do
      [[ -f "$file" ]] || continue
      magick "$file" -auto-orient -flip "$(output_for "$file" flipped-vertical)"
    done
    ;;
  resize) resize_images "$@" ;;
  convert) convert_images "$@" ;;
  add-wallpaper) add_to_wallpapers "$@" ;;
  details)
    details=""
    for file in "$@"; do
      [[ -f "$file" ]] || continue
      details+="$(identify -format '%f  ·  %m  ·  %wx%h  ·  %b\n' "$file")"$'\n'
    done
    [[ -n "$details" ]] && zenity --info --title="Image details" --text="$details" --width=620 || true
    ;;
  strip-metadata)
    for file in "$@"; do
      [[ -f "$file" ]] || continue
      magick "$file" -auto-orient -strip "$(output_for "$file" metadata-free)"
    done
    ;;
  *)
    zenity --error --title="Image action" --text="Unknown image action: $action" || true
    exit 2
    ;;
esac
