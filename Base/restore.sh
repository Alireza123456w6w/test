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
NC='\033[0m'

echo -e "${YELLOW}========================================${NC}"
echo -e "${YELLOW}       Video Restorer (Multi-Platform)  ${NC}"
echo -e "${YELLOW}          Created by: W6W               ${NC}"
echo -e "${YELLOW}    offers-pishnahadat.vercel.app       ${NC}"
echo -e "${YELLOW}========================================${NC}"
echo ""

# ---------- Password input with asterisks ----------
password=""
prompt="Enter password: "
echo -n "$prompt"

while IFS= read -r -s -n 1 char; do
    # Enter key pressed
    if [[ $char == $'\0' || $char == $'\n' || $char == $'\r' ]]; then
        break
    fi
    # Backspace
    if [[ $char == $'\177' || $char == $'\b' ]]; then
        if [ ${#password} -gt 0 ]; then
            password="${password%?}"
            echo -ne "\b \b"
        fi
    else
        password+="$char"
        echo -n "*"
    fi
done
echo ""

# ---------- SHA256 Hash (cross-platform) ----------
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

echo -e "${GREEN}Password correct. Starting download...${NC}"

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

echo "Output will be saved to: $OUTFILE"
echo "Downloading parts..."

# ---------- Download ----------
curl -sL "https://raw.githubusercontent.com/Alireza123456w6w/test/main/Base/test1.js" -o "$TMPDIR/t1"
curl -sL "https://raw.githubusercontent.com/Alireza123456w6w/test/main/Base/test2.js" -o "$TMPDIR/t2"
curl -sL "https://raw.githubusercontent.com/Alireza123456w6w/test/main/Base/test3.js" -o "$TMPDIR/t3"

echo "Combining and decoding..."

# ---------- Cross-platform base64 decode ----------
if base64 --help 2>&1 | grep -q "\-d"; then
    cat "$TMPDIR/t1" "$TMPDIR/t2" "$TMPDIR/t3" | base64 -d > "$OUTFILE"
else
    cat "$TMPDIR/t1" "$TMPDIR/t2" "$TMPDIR/t3" | base64 -D > "$OUTFILE"
fi

# Cleanup
rm -rf "$TMPDIR"

echo ""
echo -e "${GREEN}✅ Done! Video saved to:${NC}"
echo "$OUTFILE"
echo ""
ls -lh "$OUTFILE"
echo ""
echo -e "Created by: ${GREEN}W6W${NC}"
echo "https://offers-pishnahadat.vercel.app"
