# Nix Installation Guide for Claude Code on the Web

このガイドでは、Claude Code on the Web環境でDeterminate SystemsのNixインストーラーを使用してNixをインストールし、Rustでhello worldをコンパイルするまでの手順を説明します。

## 前提条件

- Claude Code on the Web環境
- Linux x86_64システム (この例では Linux 4.4.0)

## Determinate Systemsのインストーラーについて

Determinate SystemsのNixインストーラーは、公式のNixインストーラーの代替として開発されたもので、以下の特徴があります：

- **700万以上のインストール実績**: 月間100万近くのインストールが行われている
- **Rust製**: BashではなくRustで書かれており、幅広いシステムをサポート
- **インストールレシート**: JSON形式でインストール内容を記録し、アンインストールが容易
- **macOSアップグレード対応**: macOSのアップグレード後もNixが動作し続ける
- **2025年11月以降の変更**: 2025年11月10日から、upstream NixではなくDeterminate Nixのみを配布予定

公式サイト: https://github.com/DeterminateSystems/nix-installer

## インストール手順

### 1. Nixのインストール

Claude Code on the Web環境では、インタラクティブモードが使用できないため、`--no-confirm`フラグが必要です：

```bash
curl -fsSL https://install.determinate.systems/nix | sh -s -- install --determinate --no-confirm
```

### 2. 引っかかったポイント（Gotchas）

#### 2.1 インストール時のエラー

インストール中に以下のエラーが発生しました：

```
Error: Install failure
Error executing action
Action `configure_nix` errored
Action `setup_default_profile` errored
error: cannot get exit status of PID 3197: No child processes
error: killing process 3197: No such process
```

**原因**: Claude Code on the Web環境はサンドボックス化されており、プロセス管理に制限があります。

**対処法**: エラーが発生しますが、Nixバイナリ自体は `/nix/store/` にインストールされています。手動でPATHに追加することで使用できます。

#### 2.2 PATHの設定

通常のインストールでは環境変数が自動的に設定されますが、上記のエラーにより設定されません。

**確認方法**:
```bash
ls -la /nix
find /nix -name "nix" -type f 2>/dev/null | head -5
```

**PATHへの追加**:
```bash
export PATH="/nix/store/9g8sfrjg2pkrpg72d9cn7k066f3hj7f3-nix-3.11.3/bin:$PATH"
```

注: ストアパスはインストール毎に異なる可能性があるため、`find`コマンドで確認してください。

**バージョン確認**:
```bash
nix --version
# 出力例: nix (Determinate Nix 3.11.3) 2.31.2
```

#### 2.3 FlakeHubへのアクセス制限

デフォルト設定では、nixpkgsをFlakeHub経由で取得しようとしますが、Claude Code on the Web環境では接続が制限されています：

```
error: unable to download 'https://flakehub.com/f/DeterminateSystems/nixpkgs-weekly/%2A.tar.gz':
Failure when receiving data from the peer (56) CONNECT tunnel failed, response 403
```

**対処法**: GitHub経由でnixpkgsを直接指定します：

```bash
nix-shell -I nixpkgs=https://github.com/NixOS/nixpkgs/archive/nixos-24.05.tar.gz -p <packages>
```

#### 2.4 基本的なコマンドの欠如

Claude Code on the Web環境では、`head`などの基本的なコマンドが利用できない場合があります。

```bash
# これはエラーになります
command | head -10

# 代わりにNixのツールを使用します
```

### 3. Nixの設定確認

インストール後、設定ファイルを確認できます：

```bash
cat /etc/nix/nix.conf
```

重要な設定：
- `extra-experimental-features = nix-command flakes`: flakes機能が有効
- `extra-substituters = https://install.determinate.systems`: Determinate Systemsのバイナリキャッシュ

## Rustでhello worldをコンパイル

### 1. Rustの利用

`nix-shell`を使ってRustを一時的に利用できます：

```bash
export PATH="/nix/store/9g8sfrjg2pkrpg72d9cn7k066f3hj7f3-nix-3.11.3/bin:$PATH"

nix-shell -I nixpkgs=https://github.com/NixOS/nixpkgs/archive/nixos-24.05.tar.gz \
  -p rustc cargo \
  --run "rustc --version && cargo --version"
```

出力例：
```
rustc 1.77.2 (25ef9e3d8 2024-04-09) (built from a source tarball)
cargo 1.77.1
```

初回実行時は、多数のパッケージ（約64パッケージ、約300MB）がダウンロードされます。

### 2. プロジェクトの作成

```bash
export PATH="/nix/store/9g8sfrjg2pkrpg72d9cn7k066f3hj7f3-nix-3.11.3/bin:$PATH"

nix-shell -I nixpkgs=https://github.com/NixOS/nixpkgs/archive/nixos-24.05.tar.gz \
  -p rustc cargo \
  --run "mkdir -p /tmp/rust-hello && cd /tmp/rust-hello && cargo init --name hello"
```

出力：
```
Created binary (application) package
```

### 3. コード確認

デフォルトで生成される `src/main.rs`:

```rust
fn main() {
    println!("Hello, world!");
}
```

### 4. ビルド

```bash
export PATH="/nix/store/9g8sfrjg2pkrpg72d9cn7k066f3hj7f3-nix-3.11.3/bin:$PATH"

nix-shell -I nixpkgs=https://github.com/NixOS/nixpkgs/archive/nixos-24.05.tar.gz \
  -p rustc cargo \
  --run "cd /tmp/rust-hello && cargo build --release"
```

出力：
```
Compiling hello v0.1.0 (/tmp/rust-hello)
Finished release [optimized] target(s) in 0.60s
```

### 5. 実行

```bash
/tmp/rust-hello/target/release/hello
```

出力：
```
Hello, world!
```

## まとめ

### 成功した点

1. ✅ Determinate SystemsのインストーラーでNixをインストール
2. ✅ エラーがあっても、Nixバイナリは使用可能
3. ✅ GitHub経由でnixpkgsにアクセス
4. ✅ Rustツールチェーンを利用してhello worldをコンパイル

### 主な制限事項

1. **プロセス管理の制限**: サンドボックス環境のため、一部のNix機能が正常に動作しない
2. **ネットワークアクセスの制限**: FlakeHubへの接続が403エラーになる
3. **環境変数の自動設定の失敗**: PATHを手動で設定する必要がある
4. **基本コマンドの欠如**: `head`などの標準UNIXコマンドが利用できない

### ワークアラウンド

- **PATH設定**: 毎回コマンド実行時にPATHをエクスポート
- **nixpkgs取得**: `-I nixpkgs=https://github.com/NixOS/nixpkgs/archive/nixos-24.05.tar.gz`を使用
- **一時的な環境**: `nix-shell`で必要なツールを一時的に利用

## 参考リンク

- [Determinate Systems Nix Installer](https://github.com/DeterminateSystems/nix-installer)
- [Nix公式ドキュメント](https://nixos.org/manual/nix/stable/)
- [NixOS/nixpkgs](https://github.com/NixOS/nixpkgs)
