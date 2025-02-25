## Windows Settings

### Setup

#### WSLの導入

基本的にNixOS WSLのQuick Startに従う
https://github.com/nix-community/NixOS-WSL/tree/2411.6.0

1. WSLをインストールする
```pwsh
wsl --install --no-distribution
```

2. 最新のNixOS WSLを取得する
```pwsh
Invoke-RestMethod -Uri https://api.github.com/repos/nix-community/nixos-wsl/releases/latest | Select-Object -ExpandProperty assets | Where-Object { $_.name -eq "nixos.wsl" } | ForEach-Object { Invoke-WebRequest -Uri $_.browser_download_url -OutFile $_.name }
```

3. ファイルを展開する
```pwsh
./nixos.wsl
```

4. NixOS WSLを起動する
```pwsh
wsl -d NixOS
```

5. プロファイルのインストール
```bash
sudo nixos-rebuild switch --flake github:natsukium/dotfiles#arusha
```

#### CLIツールのインストール

24H2ではsudoコマンドが使えるようになっているため、wingetはsudoで実行するとUACの確認が入らずに済む

