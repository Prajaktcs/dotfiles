#!/bin/bash

# Deployment script for Dactyl keyboard
# This script updates side.py and copies files to the controller

set -e

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}================================${NC}"
echo -e "${BLUE}Dactyl Keyboard Deployment Script${NC}"
echo -e "${BLUE}================================${NC}\n"

# Get the directory where the script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

# Step 1: Select side
echo -e "${YELLOW}Select keyboard side:${NC}"
echo "1) LEFT"
echo "2) RIGHT"
read -p "Enter choice (1 or 2): " side_choice

case $side_choice in
    1)
        SIDE="LEFT"
        ;;
    2)
        SIDE="RIGHT"
        ;;
    *)
        echo -e "${RED}Invalid choice. Exiting.${NC}"
        exit 1
        ;;
esac

echo -e "${GREEN}✓ Selected side: $SIDE${NC}\n"

# Step 2: Update side.py
echo -e "${YELLOW}Updating side.py...${NC}"
cat > side.py << EOF
from kmk.modules.split import SplitSide

split_side = SplitSide.$SIDE
EOF

echo -e "${GREEN}✓ side.py updated to SplitSide.$SIDE${NC}\n"

# Step 3: Find controller mount point
echo -e "${YELLOW}Looking for controller mount point...${NC}"

# Common mount points for CircuitPython/KMK controllers
POSSIBLE_MOUNTS=(
    "/Volumes/CIRCUITPY"
    "/Volumes/RPI-RP2"
    "/media/$USER/CIRCUITPY"
    "/media/CIRCUITPY"
    "/run/media/$USER/CIRCUITPY"
)

MOUNT_POINT=""
for mount in "${POSSIBLE_MOUNTS[@]}"; do
    if [ -d "$mount" ]; then
        MOUNT_POINT="$mount"
        echo -e "${GREEN}✓ Found controller at: $MOUNT_POINT${NC}"
        break
    fi
done

if [ -z "$MOUNT_POINT" ]; then
    echo -e "${YELLOW}Controller not auto-detected.${NC}"
    read -p "Enter controller mount point (e.g., /Volumes/CIRCUITPY): " MOUNT_POINT

    if [ ! -d "$MOUNT_POINT" ]; then
        echo -e "${RED}Error: Mount point '$MOUNT_POINT' not found.${NC}"
        echo -e "${YELLOW}Please ensure:${NC}"
        echo "  1. Controller is connected via USB"
        echo "  2. Controller is in bootloader mode or running CircuitPython"
        exit 1
    fi
fi

# Step 4: Verify files exist
echo -e "\n${YELLOW}Verifying files...${NC}"
FILES_TO_COPY=("code.py" "side.py")

for file in "${FILES_TO_COPY[@]}"; do
    if [ ! -f "$file" ]; then
        echo -e "${RED}Error: $file not found!${NC}"
        exit 1
    fi
    echo -e "${GREEN}✓ Found $file${NC}"
done

# Step 5: Copy files
echo -e "\n${YELLOW}Copying files to controller...${NC}"

for file in "${FILES_TO_COPY[@]}"; do
    cp "$file" "$MOUNT_POINT/"
    echo -e "${GREEN}✓ Copied $file${NC}"
done

# Step 6: Check if KMK directory exists
if [ ! -d "$MOUNT_POINT/kmk" ]; then
    echo -e "\n${YELLOW}⚠ Warning: KMK library not found on controller!${NC}"
    echo -e "${YELLOW}You need to install KMK on the controller.${NC}"
    echo -e "${YELLOW}Visit: https://github.com/KMKfw/kmk_firmware${NC}"
fi

# Done
echo -e "\n${GREEN}================================${NC}"
echo -e "${GREEN}Deployment complete!${NC}"
echo -e "${GREEN}================================${NC}"
echo -e "\n${BLUE}Configuration:${NC}"
echo -e "  Side: ${GREEN}$SIDE${NC}"
echo -e "  Location: ${GREEN}$MOUNT_POINT${NC}"
echo -e "\n${YELLOW}Next steps:${NC}"
echo "  1. Safely eject the controller"
echo "  2. The keyboard will restart automatically"
echo "  3. Repeat this process for the other side (select opposite side)"
echo ""
