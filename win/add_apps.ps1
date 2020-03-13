$addApps = @(
    "alacritty"
    "autohotkey"
    "docker-desktop --pre"  # for wsl2
    "git"
    "google-backup-and-sync"
    "googlechrome"
    "hackfont"
    "keypirinha"
    "kindle"
    "line"
    "typora"
    "ultravnc"
    "vivaldi"
    "vscode"
    "winscreenfetch"
)

foreach ($app in $addApps) {
    choco install -y $app
}