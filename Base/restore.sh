#!/data/data/com.termux/files/usr/bin/bash
# ============================================================
#  Video Restorer
#  Created by: W6W
#  Website: https://offers-pishnahadat.vercel.app
# ============================================================

set -e

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}========================================${NC}"
echo -e "${YELLOW}         Video Restorer                 ${NC}"
echo -e "${YELLOW}      Created by: W6W                   ${NC}"
echo -e "${YELLOW}  offers-pishnahadat.vercel.app         ${NC}"
echo -e "${YELLOW}========================================${NC}"
echo ""

# Password check (SHA256 hashed)
read -s -p "Enter password: " pass
echo ""

HASH=$(echo -n "$pass" | sha256sum | cut -d' ' -f1)
CORRECT="d12599ce879e0e131a4a748bb89362fa4bba4725a9fc5e4b3c25371d53ca22b9"

if [ "$HASH" != "$CORRECT" ]; then
    echo -e "${RED}Incorrect password.${NC}"
    exit 1
fi

echo -e "${GREEN}Password correct. Starting download...${NC}"

cd /sdcard/Download

# Download the 3 parts
curl -sL "https://raw.githubusercontent.com/Alireza123456w6w/test/main/Base/test1.js" -o t1
curl -sL "https://raw.githubusercontent.com/Alireza123456w6w/test/main/Base/test2.js" -o t2
curl -sL "https://raw.githubusercontent.com/Alireza123456w6w/test/main/Base/test3.js" -o t3

echo "Combining and decoding..."

cat t1 t2 t3 | base64 -d > test.mp4

# Cleanup
rm -f t1 t2 t3

echo ""
echo -e "${GREEN}✅ Done! Video saved to:${NC}"
echo "/sdcard/Download/test.mp4"
echo ""
ls -lh /sdcard/Download/test.mp4
echo ""
echo -e "Created by: ${GREEN}W6W${NC}"
echo "https://offers-pishnahadat.vercel.app"
