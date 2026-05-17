#!/bin/bash

# Define colors using ANSI codes
BLUE='\033[0;34m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color
BOLD='\033[1m'

echo -e "${BLUE}${BOLD}====================================================${NC}"
echo -e "${CYAN}${BOLD}     ⚡ Flutter Emulator & App Launcher ⚡${NC}"
echo -e "${BLUE}${BOLD}====================================================${NC}"
echo ""

# Get the list of available emulators
echo -e "${YELLOW}Fetching available emulators...${NC}"
EMULATORS_RAW=$(flutter emulators)

# Parse emulators
# The format of flutter emulators output:
# apple_ios_simulator • iOS Simulator  • Apple        • ios
# Pixel_4             • Pixel 4        • Google       • android
# Pixel_9_Pro_XL      • Pixel 9 Pro XL • Google       • android
# Pixel_Tablet        • Pixel Tablet   • Google       • android

# Create arrays to store emulator IDs and names
ids=()
names=()
platforms=()

while IFS= read -r line; do
    # Skip header and empty lines
    if [[ "$line" == *"•"* ]]; then
        id=$(echo "$line" | cut -d'•' -f1 | xargs)
        name=$(echo "$line" | cut -d'•' -f2 | xargs)
        platform=$(echo "$line" | cut -d'•' -f4 | xargs)
        ids+=("$id")
        names+=("$name")
        platforms+=("$platform")
    fi
done <<< "$EMULATORS_RAW"

num_emulators=${#ids[@]}

if [ $num_emulators -eq 0 ]; then
    echo -e "${RED}Error: No emulators found. Please create an emulator in Android Studio or Xcode first.${NC}"
    exit 1
fi

echo -e "${GREEN}Available Emulators:${NC}"
for ((i=0; i<num_emulators; i++)); do
    echo -e "  [${CYAN}$((i+1))${NC}] ${BOLD}${names[i]}${NC} (${platforms[i]} | ID: ${ids[i]})"
done
echo ""

# Prompt the user to select an emulator
read -p "Select an emulator (1-$num_emulators) [default: 1]: " selection
selection=${selection:-1}

# Validate selection
if ! [[ "$selection" =~ ^[0-9]+$ ]] || [ "$selection" -lt 1 ] || [ "$selection" -gt "$num_emulators" ]; then
    echo -e "${RED}Invalid selection. Exiting.${NC}"
    exit 1
fi

selected_index=$((selection-1))
selected_id="${ids[selected_index]}"
selected_name="${names[selected_index]}"
selected_platform="${platforms[selected_index]}"

echo -e "\n${YELLOW}Launching ${BOLD}$selected_name${NC} ($selected_id)...${NC}"

# Launch emulator in the background
flutter emulators --launch "$selected_id" &
LAUNCH_PID=$!

echo -e "${YELLOW}Waiting for emulator to start and connect...${NC}"

# Wait loop
max_attempts=30
attempt=1
device_connected=false

if [ "$selected_platform" == "ios" ]; then
    # For iOS simulator, wait until booted
    echo -e "${YELLOW}Waiting for iOS Simulator to boot...${NC}"
    sleep 5
    device_connected=true
else
    # For Android, use adb to check status
    while [ $attempt -le $max_attempts ]; do
        # Check if adb shows any online device
        adb_status=$(/opt/homebrew/bin/adb devices | grep -E "emulator-|device" | grep -v "List of devices")
        if [ ! -z "$adb_status" ]; then
            echo -e "${GREEN}✓ Emulator is online!${NC}"
            device_connected=true
            break
        fi
        echo -ne "Waiting... ($attempt/$max_attempts)\r"
        sleep 2
        attempt=$((attempt+1))
    done
    echo ""
fi

if [ "$device_connected" = true ]; then
    echo -e "${GREEN}${BOLD}Success! Running the Flutter app...${NC}"
    echo -e "${CYAN}Executing: flutter run${NC}\n"
    flutter run
else
    echo -e "${RED}Warning: Emulator took too long to connect, but launching the app anyway...${NC}"
    flutter run
fi
