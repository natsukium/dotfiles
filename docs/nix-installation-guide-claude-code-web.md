# Nix Installation Guide for Claude Code on the Web

このガイドは、Claude Code on the Web環境でNixをインストールする手順をまとめたものです。

## 環境の特徴

Claude Code on the Webはコンテナ環境であり、以下の制約があります：

- **systemdがPID 1ではない**: 代わりに`/process_api`がPID 1として動作
- **sandboxが利用できない**: コンテナ内部ではNixのsandbox機能が制限される
- **ビルド環境の初期化に失敗する**: I/Oエラーが発生し、derivationのビルドができない

## 試行錯誤の記録

### 失敗したアプローチ

#### 1. Determinate Systemsのインストーラー（推奨オプション使用）

```bash
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install linux \
  --extra-conf "sandbox = false" \
  --no-start-daemon \
  --no-confirm
```

**結果**: `setup_default_profile`ステップでI/Oエラーが発生

```
error:
       … while waiting for the build environment for '/nix/store/...-user-environment.drv' to initialize (succeeded, previous messages: )

       error: reading a line: Input/output error
```

#### 2. `--init none`オプション追加

```bash
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install linux \
  --extra-conf "sandbox = false" \
  --init none \
  --no-start-daemon \
  --no-confirm
```

**結果**: 同じI/Oエラーが発生

#### 3. 公式Nixインストーラー（シングルユーザーモード）

```bash
curl -L https://nixos.org/nix/install | sh -s -- --no-daemon
```

**結果**: 同様のビルド環境エラーが発生

#### 4. `nix-channel`と`nix-env`の使用

手動でプロファイルを作成後、`nix-channel --update`や`nix-env -i`を試行。

**結果**: これらもderivationのビルドを必要とするため、同じI/Oエラーが発生

## 成功したアプローチ

### Flakesを使用した方法

コンテナ環境では、ビルド環境を必要としない**Flakes（`nix shell`）**を使用することで成功しました。

### インストール手順

#### 1. 公式Nixインストーラーの実行

```bash
curl -L https://nixos.org/nix/install | sh -s -- --no-daemon
```

インストール中にエラーが出ますが、Nixストアとバイナリは配置されます。

#### 2. 設定ファイルの作成

```bash
mkdir -p /etc/nix
cat > /etc/nix/nix.conf << 'EOF'
sandbox = false
build-users-group =
max-jobs = auto
experimental-features = nix-command flakes
EOF
```

**重要な設定**:
- `sandbox = false`: コンテナ環境ではsandboxを無効化
- `build-users-group =`: ビルドユーザーグループを空に設定（シングルユーザーモード）
- `experimental-features = nix-command flakes`: Flakes機能を有効化

#### 3. プロファイルの手動作成

```bash
# Nixバイナリのパスを確認
NIX_BIN=$(find /nix/store -name "nix-2.*" -type d | head -1)

# プロファイルへのシンボリックリンク作成
ln -sf "$NIX_BIN" /nix/var/nix/profiles/per-user/root/profile
```

#### 4. 環境変数の設定

```bash
# .bashrcに追加
echo 'export PATH="$HOME/.nix-profile/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc

# バージョン確認
nix --version
```

#### 5. Flakesを使ったパッケージの使用

**重要**: `nix-env`や`nix-channel`は使用できません。代わりに`nix shell`を使用します。

```bash
# Rustをインストールして使用
nix shell nixpkgs#rustc --command rustc --version
```

### Rustでのサンプル

#### Hello Worldプログラムの作成

```bash
# ディレクトリ作成
mkdir -p ~/rust-hello
cd ~/rust-hello

# ソースコード作成
cat > hello.rs << 'EOF'
fn main() {
    println!("Hello, World from Nix + Rust!");
}
EOF
```

#### コンパイルと実行

```bash
# Rustcを使ってコンパイルし、実行
nix shell nixpkgs#rustc --command rustc hello.rs
./hello
```

**出力**:
```
Hello, World from Nix + Rust!
```

## 引っかかったポイントと解決策

### 問題1: ビルド環境の初期化エラー

**エラー内容**:
```
error: reading a line: Input/output error
```

**原因**: コンテナ環境の制限により、Nixのビルドサンドボックスが正しく動作しない

**解決策**: Flakesを使用し、バイナリキャッシュから直接パッケージをダウンロード

### 問題2: `nix-channel`が使えない

**原因**: チャンネルの更新もderivationのビルドを必要とする

**解決策**: `nixpkgs#パッケージ名`の形式でFlakes経由で直接パッケージを指定

### 問題3: 環境の永続化

**課題**: Flakesで起動するたびにパッケージをダウンロードする必要がある

**解決策**:
- 頻繁に使うパッケージは`nix profile install`を試す（ただしビルドが必要な場合は失敗する可能性あり）
- または、シェルスクリプトやaliasでFlakesコマンドをラップする

```bash
# .bashrcに追加
alias rust-shell='nix shell nixpkgs#rustc nixpkgs#cargo'
```

## よく使うパッケージ

### 開発ツール

```bash
# Rust開発環境
nix shell nixpkgs#rustc nixpkgs#cargo

# Node.js
nix shell nixpkgs#nodejs

# Python
nix shell nixpkgs#python3

# Go
nix shell nixpkgs#go

# 複数パッケージの同時使用
nix shell nixpkgs#git nixpkgs#vim nixpkgs#ripgrep
```

### シェルの起動

対話的なシェルを起動する場合：

```bash
nix shell nixpkgs#rustc nixpkgs#cargo
# このシェル内でrustcやcargoが使える
```

## まとめ

Claude Code on the Web環境では：

1. ✅ **Flakesは動作する**: `nix shell nixpkgs#パッケージ名`
2. ❌ **従来のチャンネルは動作しない**: `nix-channel --update`
3. ❌ **nix-envは動作しない**: derivationのビルドが必要
4. ✅ **バイナリキャッシュは利用可能**: ビルド済みパッケージを直接ダウンロード

**推奨アプローチ**: Flakesを積極的に活用し、バイナリキャッシュから直接パッケージを使用する。

## 参考情報

- コンテナ環境: PID 1は`/process_api`
- Nixバージョン: 2.32.1
- 利用可能な機能: `nix shell`, `nix run`, `nix develop`（ビルド不要な範囲）
- 制限される機能: `nix-env`, `nix-channel`, derivationのビルド
