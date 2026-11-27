#!/usr/bin/env bash
# ============================================================
#  Video Restorer Pro (Multi-Platform)
#  Created by: W6W
#  Website: https://offers-pishnahadat.vercel.app
# ============================================================
#  Supports: Android (Termux), Linux, macOS
#  Usage:    ./video_restorer.sh [-o DIR] [-f NAME] [-h]
# ============================================================

set -euo pipefail

# ---------- Config ----------
VERSION="2.0"
BASE_URL="https://raw.githubusercontent.com/Alireza123456w6w/test/main/Base"
PARTS=(test1.js test2.js test3.js)
OUT_NAME="test.mp4"
CORRECT_HASH="d12599ce879e0e131a4a748bb89362fa4bba4725a9fc5e4b3c25371d53ca22b9"
EXPECTED_SHA256=""        # optional: SHA-256 of the final video (leave empty to skip)
MAX_ATTEMPTS=3
OUTDIR="${OUTDIR:-}"
PLATFORM=""
REPLY_PW=""
TMPDIR_W=""
PARTFILE=""

# ---------- Colors (disabled when output is not a terminal) ----------
if [ -t 1 ]; then
    GREEN=$'\033[0;32m'; RED=$'\033[0;31m'; YELLOW=$'\033[1;33m'
    CYAN=$'\033[0;36m'; NC=$'\033[0m'
else
    GREEN=""; RED=""; YELLOW=""; CYAN=""; NC=""
fi

info() { printf '%s[i]%s %s\n' "$CYAN" "$NC" "$*"; }
ok()   { printf '%s[✓]%s %s\n' "$GREEN" "$NC" "$*"; }
warn() { printf '%s[!]%s %s\n' "$YELLOW" "$NC" "$*"; }
err()  { printf '%s[✗]%s %s\n' "$RED" "$NC" "$*" >&2; }

usage() {
    cat <<EOF
Usage: $(basename "$0") [options]
  -o DIR    Output directory (default: auto-detect)
  -f NAME   Output file name (default: $OUT_NAME)
  -h        Show this help
EOF
}

# ---------- Cleanup (always runs: Ctrl-C, errors, normal exit) ----------
cleanup() {
    local code=$?
    { stty echo </dev/tty; } 2>/dev/null || true
    if [ -n "$TMPDIR_W" ] && [ -d "$TMPDIR_W" ]; then rm -rf "$TMPDIR_W"; fi
    if [ -n "$PARTFILE" ] && [ -f "$PARTFILE" ]; then rm -f "$PARTFILE"; fi
    exit "$code"
}
trap cleanup EXIT
trap 'printf "\n"; err "Interrupted."; exit 130' INT TERM

# ---------- Helpers ----------
banner() {
    clear 2>/dev/null || true
    printf '%s' "$YELLOW"
    echo "========================================"
    echo "      Video Restorer Pro v$VERSION"
    echo "   Multi-Platform  |  Created by: W6W"
    echo "      offers-pishnahadat.vercel.app"
    echo "========================================"
    printf '%s\n' "$NC"
}

detect_platform() {
    if [ -n "${TERMUX_VERSION:-}" ] || [ -d /data/data/com.termux ]; then
        PLATFORM="Android (Termux)"
    else
        case "$(uname -s)" in
            Linux*)  PLATFORM="Linux" ;;
            Darwin*) PLATFORM="macOS" ;;
            *)       PLATFORM="$(uname -s)" ;;
        esac
    fi
}

check_deps() {
    local missing=() c
    for c in curl base64 awk tr mktemp df; do
        command -v "$c" >/dev/null 2>&1 || missing+=("$c")
    done
    if ! command -v sha256sum >/dev/null 2>&1 \
       && ! command -v shasum >/dev/null 2>&1 \
       && ! command -v openssl >/dev/null 2>&1; then
        missing+=("sha256sum")
    fi
    if [ "${#missing[@]}" -gt 0 ]; then
        err "Missing tools: ${missing[*]}"
        if [ "$PLATFORM" = "Android (Termux)" ]; then
            warn "Install with: pkg install curl coreutils"
        fi
        exit 1
    fi
}

sha256_stdin() {
    if command -v sha256sum >/dev/null 2>&1; then
        sha256sum | awk '{print $1}'
    elif command -v shasum >/dev/null 2>&1; then
        shasum -a 256 | awk '{print $1}'
    else
        openssl dgst -sha256 | awk '{print $NF}'
    fi
}

decode_b64() {
    # GNU/Termux use -d, older macOS uses -D
    if printf 'dGVzdA==' | base64 -d >/dev/null 2>&1; then
        base64 -d
    else
        base64 -D
    fi
}

human_size() { ls -lh "$1" | awk '{print $5}'; }

pick_outdir() {
    if [ -n "$OUTDIR" ]; then
        mkdir -p "$OUTDIR" 2>/dev/null || true
        if [ ! -d "$OUTDIR" ] || [ ! -w "$OUTDIR" ]; then
            err "Output directory is not writable: $OUTDIR"
            exit 1
        fi
        return
    fi
    local d
    for d in "/sdcard/Download" "$HOME/storage/downloads" "$HOME/Downloads" "$HOME/Download"; do
        if [ -d "$d" ] && [ -w "$d" ]; then
            OUTDIR="$d"
            return
        fi
    done
    OUTDIR="$PWD"
    if [ "$PLATFORM" = "Android (Termux)" ]; then
        warn "Download folder not accessible. Run: termux-setup-storage"
    fi
}

unique_path() {
    local dir="$1" name="$2" base ext n=1 path
    base="${name%.*}"
    ext="${name##*.}"
    path="$dir/$name"
    if [ "$base" = "$name" ]; then   # no extension
        while [ -e "$path" ]; do path="$dir/${name}_$n"; n=$((n + 1)); done
    else
        while [ -e "$path" ]; do path="$dir/${base}_$n.$ext"; n=$((n + 1)); done
    fi
    printf '%s' "$path"
}

# ---------- Password with asterisks ----------
# Reads from /dev/tty so it also works with:  curl ... | bash
# Supports: backspace, Ctrl-U (clear line), paste, arrow keys ignored.
read_password() {
    local prompt="$1" pw="" ch rest
    printf '%s' "$prompt" >&2
    while true; do
        IFS= read -rsn1 ch </dev/tty || break
        case "$ch" in
            ""|$'\r')
                break ;;
            $'\177'|$'\b')
                if [ -n "$pw" ]; then
                    pw="${pw%?}"
                    printf '\b \b' >&2
                fi ;;
            $'\025')
                while [ -n "$pw" ]; do
                    pw="${pw%?}"
                    printf '\b \b' >&2
                done ;;
            $'\033')
                IFS= read -rsn2 -t 1 rest </dev/tty || true ;;
            [[:cntrl:]])
                ;;
            *)
                pw+="$ch"
                printf '*' >&2 ;;
        esac
    done
    printf '\n' >&2
    REPLY_PW="$pw"
}

authenticate() {
    if ! ( : </dev/tty ) 2>/dev/null; then
        err "No interactive terminal available for the password prompt."
        exit 1
    fi
    local attempt=1 hash left
    while [ "$attempt" -le "$MAX_ATTEMPTS" ]; do
        read_password "Enter password: "
        if [ -z "$REPLY_PW" ]; then
            warn "Password cannot be empty."
            continue
        fi
        hash="$(printf '%s' "$REPLY_PW" | sha256_stdin)"
        REPLY_PW=""
        if [ "$hash" = "$CORRECT_HASH" ]; then
            ok "Password correct"
            echo ""
            return 0
        fi
        left=$((MAX_ATTEMPTS - attempt))
        err "Incorrect password. ${left} attempt(s) left."
        attempt=$((attempt + 1))
        sleep 1
    done
    err "Too many failed attempts."
    exit 1
}

# ---------- Download with progress + retry ----------
download_file() {
    local url="$1" output="$2" label="$3"
    printf '%s[↓] Downloading %s ...%s\n' "$YELLOW" "$label" "$NC"
    if ! curl -fL --retry 3 --retry-delay 2 --connect-timeout 15 \
              --progress-bar "$url" -o "$output"; then
        err "Failed to download $label"
        return 1
    fi
    if [ ! -s "$output" ]; then
        err "$label is empty"
        return 1
    fi
    ok "$label finished ($(human_size "$output"))"
    echo ""
}

# ---------- Main ----------
main() {
    banner
    detect_platform
    check_deps
    pick_outdir

    info "Platform : $PLATFORM"
    info "Output   : $OUTDIR"
    echo ""

    authenticate
    SECONDS=0

    local outfile i=1 total=${#PARTS[@]} total_bytes=0 p
    local part_files=()
    outfile="$(unique_path "$OUTDIR" "$OUT_NAME")"
    info "Output file: ${CYAN}${outfile}${NC}"
    echo ""

    TMPDIR_W="$(mktemp -d 2>/dev/null || mktemp -d -t vrestore)"

    for p in "${PARTS[@]}"; do
        download_file "$BASE_URL/$p" "$TMPDIR_W/part$i" "Part $i/$total"
        part_files+=("$TMPDIR_W/part$i")
        total_bytes=$((total_bytes + $(wc -c < "$TMPDIR_W/part$i")))
        i=$((i + 1))
    done

    # Free space check (decoded size is about 3/4 of the Base64 size)
    local free_kb need_kb
    free_kb="$(df -Pk "$OUTDIR" 2>/dev/null | awk 'NR==2{print $4}')"
    need_kb=$((total_bytes * 3 / 4 / 1024 + 1024))
    if [[ "$free_kb" =~ ^[0-9]+$ ]] && [ "$free_kb" -lt "$need_kb" ]; then
        err "Not enough free space in $OUTDIR (need ~$((need_kb / 1024)) MB)."
        exit 1
    fi

    info "Combining and decoding... please wait"
    PARTFILE="$outfile.part"
    if ! cat "${part_files[@]}" | tr -d '[:space:]' | decode_b64 > "$PARTFILE"; then
        err "Decoding failed: downloaded data is not valid Base64."
        exit 1
    fi
    if [ ! -s "$PARTFILE" ]; then
        err "Decoded file is empty."
        exit 1
    fi

    # Integrity checks
    if head -c 12 "$PARTFILE" | LC_ALL=C grep -aq 'ftyp'; then
        ok "Video signature verified (MP4/MOV)"
    else
        warn "File has no MP4/MOV header. It may be corrupted."
    fi
    if [ -n "$EXPECTED_SHA256" ]; then
        local actual
        actual="$(sha256_stdin < "$PARTFILE")"
        if [ "$actual" != "$EXPECTED_SHA256" ]; then
            err "Checksum mismatch. The file is corrupted or was changed."
            exit 1
        fi
        ok "Checksum verified"
    fi

    mv -f "$PARTFILE" "$outfile"
    PARTFILE=""

    # Make it show up in the Android gallery
    if [ "$PLATFORM" = "Android (Termux)" ] && command -v termux-media-scan >/dev/null 2>&1; then
        termux-media-scan "$outfile" >/dev/null 2>&1 || true
    fi

    echo ""
    printf '%s========================================%s\n' "$GREEN" "$NC"
    printf '%s  ✅  DONE! Video restored successfully %s\n' "$GREEN" "$NC"
    printf '%s========================================%s\n' "$GREEN" "$NC"
    echo ""
    echo "Saved to : ${outfile}"
    echo "Size     : $(human_size "$outfile")"
    echo "Time     : ${SECONDS}s"
    echo ""
    printf 'Created by: %sW6W%s\n' "$GREEN" "$NC"
    echo "https://offers-pishnahadat.vercel.app"
}

while getopts ":o:f:h" opt; do
    case "$opt" in
        o) OUTDIR="$OPTARG" ;;
        f) OUT_NAME="$(basename "$OPTARG")" ;;
        h) usage; exit 0 ;;
        :) err "Option -$OPTARG needs a value"; exit 2 ;;
        *) err "Unknown option: -$OPTARG"; usage; exit 2 ;;
    esac
done

main
