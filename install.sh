#!/bin/bash

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Update package list and install Node.js if it's not installed
if ! command_exists node; then
    echo "Node.js not found. Installing Node.js..."
    curl -fsSL https://deb.nodesource.com/setup_16.x | sudo -E bash -
    sudo apt-get install -y nodejs
else
    echo "Node.js is already installed."
fi

# Create a directory for the bot (optional)
mkdir -p telegram-bot
cd telegram-bot || exit

# Install project dependencies
echo "Installing dependencies..."
npm install node-telegram-bot-api node-fetch

# Ask for the bot token and save it in an environment variable file
read -p "Enter your Telegram bot token: " BOT_TOKEN

# Save the bot token in a .env file
echo "Creating .env file..."
cat <<EOT > .env
BOT_TOKEN=$BOT_TOKEN
EOT

# Create a start script
echo "Creating start script..."
cat <<EOT > start.sh
#!/bin/bash
# Load environment variables
source .env

# Run the bot
node bot.js
EOT

# Make the start script executable
chmod +x start.sh

# Notify user
echo "Installation complete. To start your bot, run ./start.sh"
