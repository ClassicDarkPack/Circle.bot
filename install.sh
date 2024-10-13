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

# Create a directory for the bot if it doesn't exist
mkdir -p Circle.bot
cd Circle.bot || exit

# Install project dependencies
echo "Installing dependencies..."
npm install node-telegram-bot-api node-fetch

# Create bot.js and insert your bot code
cat <<EOT > bot.js
const TelegramBot = require('node-telegram-bot-api');
const fetch = require('node-fetch');
const fs = require('fs');

// Your bot token from BotFather
const botToken = process.env.BOT_TOKEN; // Get the token from the environment variable

// Create a bot that uses 'polling' to fetch updates
const bot = new TelegramBot(botToken, { polling: true });

// Base URL for your script
const baseUrl = "https://api.adsgram.ai/event?type=reward&trackingtypeid=14&record=";

let chatId = "";
let uniqueUsers = new Set();
let errorCount = 0;
const maxErrors = 5;
let userIntervals = {};
let userTokens = {};

// Token format validation using regex
function isValidToken(token) {
    const tokenPattern = /^[A-Za-z0-9\-:.*]+$/;
    return tokenPattern.test(token);
}

// Function to call the API
function makeMoney(token, chatId) {
    if (token) {
        const url = baseUrl + token;
        fetch(url)
            .then(res => {
                const statusMessage = res.status === 200 ? "Success" : "Failed";
                console.log(statusMessage);

                if (res.status === 200) {
                    errorCount = 0;
                }

                if (chatId) {
                    bot.sendMessage(chatId, \`Request to API: \${statusMessage}\`);
                }
            })
            .catch(error => {
                console.error('Error:', error);
                errorCount += 1;
                if (errorCount >= maxErrors) {
                    console.log(\`Maximum error limit reached (\${maxErrors}). Stopping bot...\`);
                    if (chatId) {
                        bot.sendMessage(chatId, \`Error limit reached (\${maxErrors}). Stopping the bot.\`);
                    }
                    bot.stopPolling();
                } else {
                    if (chatId) {
                        bot.sendMessage(chatId, \`Error occurred: \${error.message}. Error count: \${errorCount}\`);
                    }
                }
            });
    } else {
        console.log("No token provided");
        if (chatId) {
            bot.sendMessage(chatId, "No token provided. Please send a token.");
        }
    }
}

// Handle commands and messages...
// (Include the rest of your bot code here)

// Initial log to indicate the bot has started
console.log("Bot is running...");
EOT

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
