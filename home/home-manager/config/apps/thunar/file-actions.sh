set -euo pipefail

action="${1:-}"
shift || true
[[ $# -gt 0 ]] || exit 0

case "$action" in
  copy-path)
    printf '%s\n' "$@" | wl-copy
    ;;
  copy-name)
    for file in "$@"; do basename -- "$file"; done | wl-copy
    ;;
  checksum)
    report="$(sha256sum -- "$@")"
    zenity --text-info --title="SHA-256 checksums" --width=760 --height=420 --filename=<(printf '%s\n' "$report")
    ;;
  archive)
    directory="$(dirname -- "$1")"
    names=()
    for file in "$@"; do
      if [[ "$(dirname -- "$file")" != "$directory" ]]; then
        zenity --error --title="Create archive" --text="Select files from the same folder." || true
        exit 2
      fi
      names+=("./$(basename -- "$file")")
    done
    format="$(zenity --list --radiolist --title="Create archive" --text="Choose an archive format:" --column="Select" --column="Format" TRUE ZIP FALSE "TAR.GZ" FALSE "TAR.XZ" --width=400 --height=280)" || exit 0
    [[ -n "$format" ]] || exit 0
    archive_name="$(zenity --entry --title="Create archive" --text="Archive name (saved beside the selected files):" --entry-text="archive")" || exit 0
    [[ -n "$archive_name" ]] || exit 0
    case "$archive_name" in */*|.*) zenity --error --title="Invalid name" --text="Enter a plain archive name without a path." || true; exit 2 ;; esac
    case "$format" in
      ZIP) extension="zip" ;;
      "TAR.GZ") extension="tar.gz" ;;
      "TAR.XZ") extension="tar.xz" ;;
      *) exit 2 ;;
    esac
    output="$directory/$archive_name.$extension"
    index=2
    while [[ -e "$output" ]]; do
      output="$directory/$archive_name-$index.$extension"
      ((index += 1))
    done
    case "$format" in
      ZIP) (cd -- "$directory" && zip -r "$output" -- "${names[@]}") ;;
      "TAR.GZ") tar -czf "$output" -C "$directory" -- "${names[@]}" ;;
      "TAR.XZ") tar -cJf "$output" -C "$directory" -- "${names[@]}" ;;
    esac
    ;;
  extract)
    for archive in "$@"; do
      [[ -f "$archive" ]] || continue
      directory="$(dirname -- "$archive")"
      name="$(basename -- "$archive")"
      lower="${name,,}"
      case "$lower" in
        *.tar.gz) stem="${name%.tar.gz}" ;;
        *.tgz) stem="${name%.tgz}" ;;
        *.tar.xz) stem="${name%.tar.xz}" ;;
        *.tar) stem="${name%.tar}" ;;
        *.zip) stem="${name%.*}" ;;
        *) zenity --error --title="Extract archive" --text="Unsupported archive: $name" || true; continue ;;
      esac
      target="$directory/$stem"
      index=2
      while [[ -e "$target" ]]; do
        target="$directory/$stem-$index"
        ((index += 1))
      done
      mkdir -p -- "$target"
      case "$lower" in
        *.zip) unzip -q "$archive" -d "$target" ;;
        *.tar.gz|*.tgz) tar -xzf "$archive" -C "$target" ;;
        *.tar.xz) tar -xJf "$archive" -C "$target" ;;
        *.tar) tar -xf "$archive" -C "$target" ;;
      esac
    done
    ;;
  *)
    zenity --error --title="File action" --text="Unknown file action: $action" || true
    exit 2
    ;;
esac
