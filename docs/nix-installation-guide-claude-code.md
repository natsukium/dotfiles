# Nix Installation Guide for Claude Code on the Web

このガイドは、Claude Code on the Web環境でNixをインストールする手順をまとめたものです。

## 環境の特徴

Claude Code on the Webのコンテナ環境には以下の特徴があります：

- OS: Ubuntu 24.04.3 LTS
- Kernel: Linux 4.4.0
- PID 1: `process_api` (systemdではない)
- ユーザー: root
- コンテナ環境

## 問題点

### 1. 公式インストーラーの問題

Nixの公式インストーラー（`curl -L https://nixos.org/nix/install | sh`）は以下の理由で動作しません：

- rootユーザーでの実行がサポートされていない
- systemdが使用できない（マルチユーザーインストールが不可）
- `--no-daemon`オプションを使用してもrootユーザーではインストールできない

### 2. コンテナ環境の制限

- サンドボックスが使用できない
- systemdのPIDが1ではない

## インストール手順

### ステップ1: Nixバイナリの手動インストール

```bash
# /nixディレクトリの作成
mkdir -p /nix
chown root:root /nix

# Nixバイナリのダウンロード
cd /tmp
curl -L https://releases.nixos.org/nix/nix-2.32.1/nix-2.32.1-x86_64-linux.tar.xz -o nix.tar.xz

# 展開
tar xf nix.tar.xz

# Nixストアのコピー
cp -r /tmp/nix-*/store /nix/
```

### ステップ2: サンドボックスの無効化

コンテナ環境ではサンドボックスが使用できないため、設定ファイルで無効化します：

```bash
mkdir -p /etc/nix
cat > /etc/nix/nix.conf << 'EOF'
sandbox = false
build-users-group =
filter-syscalls = false
EOF
```

**設定項目の説明：**
- `sandbox = false`: サンドボックスを無効化
- `build-users-group =`: ビルドユーザーグループを空に設定（シングルユーザーモード）
- `filter-syscalls = false`: システムコールフィルタリングを無効化

### ステップ3: Nixストアの登録

```bash
# Nixバイナリのパスを確認
export NIX_PATH=/nix/store/hlc00f4gn52nrpky7bgb762ia0llz98v-nix-2.32.1

# ストアパスの登録
$NIX_PATH/bin/nix-store --load-db < /tmp/nix-*/.reginfo
```

**注意**: ストアパスのハッシュ値（`hlc00f4gn52nrpky7bgb762ia0llz98v`）はバージョンによって異なる場合があります。以下のコマンドで確認してください：

```bash
find /nix/store -name "nix-2.32.1" -type d
# または
find /nix/store -name "nix" -type f -executable | grep bin/nix
```

### ステップ4: 環境変数の設定

```bash
# .bashrcに追加
cat >> ~/.bashrc << 'EOF'

# Nix
export PATH="/nix/store/hlc00f4gn52nrpky7bgb762ia0llz98v-nix-2.32.1/bin:$PATH"
export NIX_CONF_DIR="/etc/nix"
EOF

# 現在のシェルで有効化
export PATH="/nix/store/hlc00f4gn52nrpky7bgb762ia0llz98v-nix-2.32.1/bin:$PATH"
export NIX_CONF_DIR="/etc/nix"
```

### ステップ5: Nixの動作確認

```bash
nix --version
# 出力例: nix (Nix) 2.32.1
```

## パッケージのインストール

### Flakesを使用したインストール

従来の`nix-channel`方式ではI/Oエラーが発生するため、新しいFlakes機能を使用します：

```bash
# Rustのインストール例
nix profile install nixpkgs#rustc nixpkgs#cargo --extra-experimental-features "nix-command flakes"
```

**注意**: `nix-channel --update`はコンテナ環境のI/O制限により失敗します。代わりにFlakesを使用してください。

## Rustでhello worldをコンパイル

### 方法1: rustcを直接使用

```bash
# hello worldプログラムの作成
mkdir -p /tmp/rust-hello
cd /tmp/rust-hello
cat > main.rs << 'EOF'
fn main() {
    println!("Hello, world!");
}
EOF

# コンパイル
rustc main.rs

# 実行
./main
# 出力: Hello, world!
```

### 方法2: Cargoを使用（推奨）

```bash
# 新しいプロジェクトの作成
cd /tmp
cargo new hello-cargo
cd hello-cargo

# ビルド
cargo build

# 実行
cargo run
# 出力: Hello, world!
```

## 引っかかったポイント

### 1. rootユーザーでの実行

**問題**: 公式インストーラーはrootユーザーでの実行をサポートしていない

**解決策**: バイナリを手動で展開してインストール

### 2. I/Oエラー

**問題**: `nix-channel --update`や`nix-env -i`を実行すると以下のエラーが発生：

```
error: reading a line: Input/output error
```

**原因**: gVisor (runsc)のpipe実装の問題により、Nixのbuilderプロセスとの通信でEIOエラーが発生

**詳細**: [nix-build-limitation-analysis.md](./nix-build-limitation-analysis.md)を参照

**解決策**: Binary cache (substitutes)を利用する`nix profile install`を使用

### 3. サンドボックスの問題

**問題**: コンテナ内部ではサンドボックスが使用できない

**解決策**: `/etc/nix/nix.conf`で`sandbox = false`を設定

### 4. systemdの不在

**問題**: PID 1がsystemdではないため、マルチユーザーインストールができない

**解決策**: シングルユーザーモードで手動インストール、`build-users-group`を空に設定

## バージョン情報

このガイドで使用したバージョン：

- Nix: 2.32.1
- Rust: 1.89.0 / 1.90.0
- Cargo: 1.89.0 / 1.90.0

## 重要な制限事項

この環境では、**カスタムderivationのビルドができません**。以下の操作は失敗します：

- `nix-build` - カスタムパッケージのビルド
- `nix develop` - 開発環境の構築（withPackagesなど）
- `nix-shell -p 'python3.withPackages(...)'` - Pythonパッケージの結合

**使用可能な操作**：
- `nix profile install nixpkgs#<package>` - binary cacheからのインストール
- `nix shell nixpkgs#<package>` - 一時的な使用
- `nix run nixpkgs#<package>` - 直接実行

詳細は [nix-build-limitation-analysis.md](./nix-build-limitation-analysis.md) を参照してください。

## まとめ

Claude Code on the Web環境では、以下の対応が必要です：

1. 公式インストーラーではなく手動インストール
2. サンドボックスの無効化（`/etc/nix/nix.conf`）
3. **Binary cache (substitutes)を活用**したパッケージインストール
4. シングルユーザーモードでの運用
5. カスタムビルドは不可（gVisorの制限）

これらの制限を理解した上で、Nixを使用してRustなどの開発環境を構築できます。
