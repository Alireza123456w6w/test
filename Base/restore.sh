#!/usr/bin/env bash
# ============================================================
#  Video Restorer (Multi-Platform)
#  Created by: W6W
#  Website: https://offers-pishnahadat.vercel.app
# ============================================================
#  Supports: Android (Termux), Linux, macOS
# ============================================================

set -e

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

clear
echo -e "${YELLOW}========================================${NC}"
echo -e "${YELLOW}       Video Restorer (Multi-Platform)  ${NC}"
echo -e "${YELLOW}          Created by: W6W               ${NC}"
echo -e "${YELLOW}    offers-pishnahadat.vercel.app       ${NC}"
echo -e "${YELLOW}========================================${NC}"
echo ""

# ---------- Password with asterisks ----------
password=""
echo -n "Enter password: "

# Save terminal settings
if command -v stty >/dev/null 2>&1; then
    old_stty=$(stty -g)
    stty -echo -icanon min 1 time 0
fi

while true; do
    # Read one character
    char=$(dd bs=1 count=1 2>/dev/null)
    
    # Enter key
    if [[ "$char" == $'\n' || "$char" == $'\r' || -z "$char" ]]; then
        break
    fi
    
    # Backspace (ASCII 127 or 8)
    if [[ $(printf "%d" "'$char") -eq 127 || $(printf "%d" "'$char") -eq 8 ]]; then
        if [ ${#password} -gt 0 ]; then
            password="${password%?}"
            printf "\b \b"
        fi
    else
        password+="$char"
        printf "*"
    fi
done

# Restore terminal
if command -v stty >/dev/null 2>&1; then
    stty "$old_stty"
fi
echo ""
echo ""

# ---------- SHA256 ----------
if command -v sha256sum >/dev/null 2>&1; then
    HASH=$(printf '%s' "$password" | sha256sum | awk '{print $1}')
elif command -v shasum >/dev/null 2>&1; then
    HASH=$(printf '%s' "$password" | shasum -a 256 | awk '{print $1}')
else
    echo -e "${RED}Error: No SHA256 tool found.${NC}"
    exit 1
fi

CORRECT="d12599ce879e0e131a4a748bb89362fa4bba4725a9fc5e4b3c25371d53ca22b9"

if [ "$HASH" != "$CORRECT" ]; then
    echo -e "${RED}Incorrect password.${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Password correct${NC}"
echo ""

# ---------- Detect Output Directory ----------
if [ -d "/sdcard/Download" ]; then
    OUTDIR="/sdcard/Download"
elif [ -d "$HOME/Downloads" ]; then
    OUTDIR="$HOME/Downloads"
elif [ -d "$HOME/Download" ]; then
    OUTDIR="$HOME/Download"
else
    OUTDIR="."
fi

OUTFILE="$OUTDIR/test.mp4"
TMPDIR=$(mktemp -d 2>/dev/null || mktemp -d -t restore)

echo -e "Output file : ${CYAN}$OUTFILE${NC}"
echo ""

# ---------- Download with progress ----------
download_file() {
    local url="$1"
    local output="$2"
    local name="$3"

    echo -e "${YELLOW}Downloading $name ...${NC}"
    curl -L --progress-bar "$url" -o "$output"
    echo -e "${GREEN}✓ $name finished${NC}"
    echo ""
}

download_file "https://raw.githubusercontent.com/Alireza123456w6w/test/main/Base/test1.js" "$TMPDIR/t1" "Part 1/3"
download_file "https://raw.githubusercontent.com/Alireza123456w6w/test/main/Base/test2.js" "$TMPDIR/t2" "Part 2/3"
download_file "https://raw.githubusercontent.com/Alireza123456w6w/test/main/Base/test3.js" "$TMPDIR/t3" "Part 3/3"

echo -e "${YELLOW}Combining and decoding... please wait${NC}"

# ---------- Decode ----------
if base64 --help 2>&1 | grep -q "\-d"; then
    cat "$TMPDIR/t1" "$TMPDIR/t2" "$TMPDIR/t3" | base64 -d > "$OUTFILE"
else
    cat "$TMPDIR/t1" "$TMPDIR/t2" "$TMPDIR/t3" | base64 -D > "$OUTFILE"
fi

# Cleanup
rm -rf "$TMPDIR"

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  ✅  DONE! Video restored successfully ${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "Saved to: ${CYAN}$OUTFILE${NC}"
ls -lh "$OUTFILE"
echo ""
echo -e "Created by: ${GREEN}W6W${NC}"
echo "https://offers-pishnahadat.vercel.app"
