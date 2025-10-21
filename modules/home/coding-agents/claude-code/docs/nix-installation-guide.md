# Claude Code on the Web での Nix インストールガイド

このガイドでは、Claude Code on the Web 環境で Determinate Systems の Nix インストーラーを使用して Nix をインストールし、Rust で Hello World をコンパイルするまでの手順を説明します。

## 環境情報

- **プラットフォーム**: Linux (runsc kernel 4.4.0)
- **PID 1**: `process_api` (systemd ではない)
- **環境**: サンドボックス化された Claude Code on the Web

## インストール手順

### 1. 環境の確認

まず、現在の環境を確認します：

```bash
# PID 1 の確認
ps -p 1 -o comm=
# 出力: process_api

# システム情報の確認
uname -a
# 出力: Linux runsc 4.4.0 #1 SMP Sun Jan 10 15:06:54 PST 2016 x86_64 x86_64 x86_64 GNU/Linux
```

### 2. Nix のインストール

Determinate Systems のインストーラーを使用します（`--determinate` フラグなし）：

```bash
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | \
  sh -s -- install linux --init none --no-confirm
```

### 3. 発生した問題と解決方法

#### 問題: PID 管理エラー

インストール時に以下のエラーが発生します：

```
Error: Action `setup_default_profile` errored
Failed to run the nix command: cannot get exit status of PID XXXXX: No child processes
```

**原因**:
- systemd が PID 1 で動作していない環境
- Nix のサンドボックスビルドがプロセス管理に失敗

**解決方法**: サンドボックスを無効化

```bash
# Nix 設定ファイルにサンドボックス無効化を追加
echo "sandbox = false" | tee -a /etc/nix/nix.conf
```

### 4. 環境変数の設定

インストール後、環境変数を設定します：

```bash
# Nix バイナリのパスを確認
ls -la /nix/store/*-nix-*/bin/nix

# PATH を設定（例: nix-2.32.0 の場合）
export PATH="/nix/store/52i4qf8kbnxnw7j0q90sxlvjqpmccq61-nix-2.32.0/bin:$PATH"

# プロファイルも PATH に追加
export PATH="$HOME/.nix-profile/bin:$PATH"

# Nix の動作確認
nix --version
```

### 5. テストインストール

Hello パッケージをインストールしてテスト：

```bash
# パッケージのインストール
nix profile install nixpkgs#hello

# 実行
hello
# 出力: Hello, world!
```

### 6. Rust のインストール

```bash
# Rust ツールチェーンのインストール
nix profile install nixpkgs#rustc nixpkgs#cargo

# バージョン確認
rustc --version
# 出力: rustc 1.89.0 (29483883e 2025-08-04) (built from a source tarball)

cargo --version
# 出力: cargo 1.89.0 (c24e10642 2025-06-23)
```

### 7. Rust Hello World のコンパイル

#### 方法 1: rustc を直接使用

```bash
# ディレクトリ作成
mkdir -p /tmp/rust-hello
cd /tmp/rust-hello

# ソースコード作成
cat > main.rs << 'EOF'
fn main() {
    println!("Hello, world from Rust!");
}
EOF

# コンパイル
rustc main.rs

# 実行
./main
# 出力: Hello, world from Rust!
```

#### 方法 2: Cargo プロジェクト

```bash
# 新規プロジェクト作成
cd /tmp
cargo new hello-cargo
cd hello-cargo

# ビルド
cargo build
# 出力: Finished `dev` profile [unoptimized + debuginfo] target(s) in 0.65s

# 実行
./target/debug/hello-cargo
# 出力: Hello, world!
```

## 引っかかったポイント

### 1. `--init none` フラグの位置

最初は `--init none` を間違った位置で指定していました：

```bash
# ❌ 誤り
install --no-confirm --init none

# ✅ 正しい
install linux --init none --no-confirm
```

### 2. サンドボックスビルドの失敗

systemd が PID 1 ではない環境では、Nix のデフォルトのサンドボックスビルドがプロセス管理に失敗します。`/etc/nix/nix.conf` に `sandbox = false` を追加することで解決しました。

### 3. プロファイルの PATH 設定

インストール後、自動的に PATH が設定されないため、手動で以下を設定する必要があります：

```bash
export PATH="$HOME/.nix-profile/bin:/nix/store/<nix-hash>-nix-<version>/bin:$PATH"
```

### 4. インストーラーの部分的な成功

インストーラーはエラーを報告しますが、実際には以下が完了しています：
- `/nix` ディレクトリの作成
- Nix バイナリのダウンロードと配置
- ビルドユーザーの作成
- 設定ファイルの生成

プロファイルのセットアップだけが失敗しているため、手動で PATH を設定すれば使用可能です。

## まとめ

Claude Code on the Web 環境での Nix インストールは、以下の手順で可能です：

1. Determinate Systems インストーラーを実行（エラーは無視）
2. `/etc/nix/nix.conf` に `sandbox = false` を追加
3. PATH を手動で設定
4. 通常通り Nix を使用可能

主な制限事項：
- サンドボックスビルドが使用できない
- プロファイルの自動セットアップが失敗
- 環境変数の手動設定が必要

これらの制限にもかかわらず、Nix の主要な機能（パッケージ管理、ビルド、開発環境）は正常に動作します。

## 参考情報

- Determinate Systems Nix Installer: https://github.com/DeterminateSystems/nix-installer
- インストールされた Nix バージョン: 2.32.0
- テスト済み Rust バージョン: 1.89.0
