#!/bin/bash

echo "=========================================="
echo " 🚀 Initializing Termux Minecraft Server"
echo "=========================================="

# 1. Ask for Android storage permissions
echo "--> Requesting Android Storage Access..."
termux-setup-storage
sleep 2

# 2. Update package repositories & install dependencies
echo "--> Updating system packages..."
pkg update -y && pkg upgrade -y

echo "--> Installing OpenJDK 21, Playit, and utilities..."
pkg install tur-repo -y
pkg install openjdk-21 playit-cli nano curl -y

# 3. Set up the directory structure
MC_DIR="$HOME/.mc-server"
mkdir -p "$MC_DIR/mods"

# 4. Create the default RAM configuration file
if [ ! -f "$MC_DIR/ram.txt" ]; then
    echo "2G" > "$MC_DIR/ram.txt"
    echo "--> Set default RAM allocation to 2G (Editable in ram.txt)."
fi

# 5. Automatically accept EULA
echo "eula=true" > "$MC_DIR/eula.properties"
echo "--> Accepted Minecraft EULA."

# 6. Generate the start.sh wrapper script
cat << 'EOF' > "$MC_DIR/start.sh"
#!/bin/bash
cd "$HOME/.mc-server"

# Read RAM limit (defaults to 2G if file is missing)
RAM=$(cat ram.txt 2>/dev/null || echo "2G")

echo "=========================================="
echo " Starting Minecraft Fabric Server (${RAM} RAM)"
echo "=========================================="

# Prevent Android CPU sleep
termux-wake-lock

# Launch Java server in background
java -Xms1G -Xmx${RAM} -jar fabric-server-launch.jar nogui &
JAVA_PID=$!

# Wait 15 seconds for JVM initialization, then trigger Playit tunnel
echo "--> Waiting for server initialization..."
sleep 15
playit &

# Wait on Java process
wait $JAVA_PID

# Release CPU lock when server stops
termux-wake-unlock
EOF

chmod +x "$MC_DIR/start.sh"

# 7. Add convenient shell aliases to ~/.bashrc
echo "--> Setting up shell aliases (mcstart & mcstop)..."

# Prevent duplicate aliases if setup.sh is run twice
sed -i '/alias mcstart=/d' ~/.bashrc 2>/dev/null
sed -i '/alias mcstop=/d' ~/.bashrc 2>/dev/null

echo "alias mcstart='bash ~/.mc-server/start.sh'" >> ~/.bashrc
echo "alias mcstop='pkill -f java && pkill -f playit && termux-wake-unlock'" >> ~/.bashrc

# Reload bash config
source ~/.bashrc 2>/dev/null

echo ""
echo "=========================================="
echo " 🎉 Setup Complete!"
echo "=========================================="
echo "Commands available:"
echo "  • Type 'mcstart' to launch the server"
echo "  • Type 'mcstop'  to shut it down safely"
echo "=========================================="
