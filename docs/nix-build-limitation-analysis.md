# Nix Build Limitation Analysis on Claude Code on the Web

Claude Code on the Web環境でのNixビルドの制限について詳細に調査した結果をまとめます。

## 環境情報

- **OS**: Ubuntu 24.04.3 LTS
- **Kernel**: Linux 4.4.0
- **コンテナランタイム**: gVisor (runsc)
- **PID 1**: process_api (systemdではない)
- **ユーザー**: root

## 問題の症状

Nixでカスタムderivationをビルドしようとすると、以下のエラーが発生します：

```
error:
       … while waiting for the build environment for '/nix/store/...' to initialize (succeeded, previous messages: )

       error: reading a line: Input/output error
```

### 発生するケース

1. `nix-env -i <package>` - derivationのビルドが必要な場合
2. `nix-channel --update` - channelの展開時
3. `nix develop` - 開発環境の構築時（withPackagesなど）
4. `nix-build` - カスタムderivationのビルド時

### 成功するケース

1. `nix profile install nixpkgs#<package>` - binary cache (substitutes)が利用可能な場合
2. `nix shell nixpkgs#<package>` - binary cacheが利用可能な場合
3. すでにダウンロード済みのパッケージの使用

## 根本原因の分析

### straceによる調査結果

詳細な調査により、以下の動作フローが判明しました：

#### 1. Pipe作成

```
29233 pipe2([17, 18], O_CLOEXEC) = 0
```

親プロセス（nix-build）が、builderプロセスとの通信用にpipeを作成します。
- fd 17: 読み取り側
- fd 18: 書き込み側
- `O_CLOEXEC`: execve()時に自動的にクローズされるフラグ

#### 2. Builderプロセスの起動

```
29233 clone(...) = 29267
```

親プロセスがbuilderプロセス（PID 29267）を起動します。

#### 3. Builderプロセスの実行

```
29267 write(2, "\2\n", 2) = 2
29267 execve("/nix/store/...-nix-2.32.1/bin/nix-store", ["nix-store", "--version"], ...) = 0
29267 write(1, "nix-store (Nix) 2.32.1\n", 23) = 23
29267 +++ exited with 0 +++
```

Builderプロセスは：
1. fd 2（stderr）に制御文字を書き込み
2. `execve()`で nix-store を実行（このとき、O_CLOEXECによりfd 18は自動的に閉じられる）
3. 正常に実行され、終了コード0で終了

#### 4. I/Oエラーの発生

```
29233 read(17, 0x7ee0b797ea4e, 1) = -1 EIO (Input/output error)
```

親プロセスがfd 17（pipeの読み取り側）から読み取ろうとすると、**EIO (Input/output error)** が返されます。

### 問題点

**通常の動作との違い**：
- 通常のLinux環境では、pipeの書き込み側が全て閉じられた状態で読み取りを行うと、EOF（read() = 0）が返されます
- しかし、この環境では **EIO (Input/output error)** が返されています

**原因**：
- **gVisor (runsc) のpipe実装の問題**と考えられます
- gVisorはGoogleが開発したコンテナサンドボックスで、Linuxカーネルの一部をユーザースペースで再実装しています
- gVisorのpipe実装が、特定の条件下で標準的なLinuxと異なる動作をしている可能性があります

## 検証実験

### 標準的なpipe2の動作確認

以下のテストプログラムで、pipe2自体は正常に動作することを確認しました：

```c
#include <unistd.h>
#include <stdio.h>
#include <fcntl.h>
#include <sys/wait.h>

int main() {
    int pipefd[2];
    pipe2(pipefd, O_CLOEXEC);

    pid_t pid = fork();
    if (pid == 0) {
        write(pipefd[1], "test\n", 5);
        close(pipefd[1]);
        return 0;
    } else {
        char buf[100];
        close(pipefd[1]);
        ssize_t n = read(pipefd[0], buf, sizeof(buf));
        // 成功: n = 5
    }
}
```

結果: **正常に動作**（EIOは発生しない）

### Nixのビルドプロセスとの違い

Nixのbuilderプロセスは：
1. Pipeを作成
2. **Builderプロセスをfork()**
3. Builderプロセスで**execve()を実行**
4. **O_CLOEXECによりpipeの書き込み側が自動的に閉じられる**
5. 親プロセスがpipeから読み取ろうとしてEIOが発生

このフローの特殊性がgVisorの問題を引き起こしていると推測されます。

## コンテナ環境の制約

### Capabilities

```bash
$ cat /proc/self/status | grep Cap
CapInh:	00000000a82c35fb
CapPrm:	00000000a82c35fb
CapEff:	00000000a82c35fb
CapBnd:	00000000200404e1
```

一部のCapabilityが制限されています。

### Seccomp

```bash
Seccomp: 0
```

Seccompは無効化されています。

### Namespaces

```bash
$ ls -la /proc/self/ns/
ipc -> ipc:[2]
mnt -> mnt:[5]
net -> net:[1]
pid -> pid:[4]
user -> user:[43691]
uts -> uts:[3]
```

全ての標準的なnamespaceが使用可能です。

### unshare

```bash
$ unshare -r -n true
（成功）
```

新しいnamespaceの作成も可能です。

## 回避策

### 方法1: Binary Cache (Substitutes)のみを使用

最も確実な方法は、ビルドを避けてbinary cacheから直接パッケージを取得することです：

```bash
# 成功する
nix profile install nixpkgs#rustc nixpkgs#cargo --extra-experimental-features "nix-command flakes"

# 成功する
nix shell nixpkgs#python313 nixpkgs#python313Packages.numpy --extra-experimental-features "nix-command flakes"
```

### 方法2: 既にダウンロード済みのパッケージを直接使用

```bash
# NumPy の例
export PYTHONPATH="/nix/store/rlijkw6gnwkd6gx7q3hnbm52rk4fxvas-python3.13-numpy-2.3.2/lib/python3.13/site-packages:$PYTHONPATH"
/nix/store/62fdlzq1x1ak2lsxp4ij7ip5k9nia3hc-python3-3.13.7/bin/python3.13 -c "import numpy; print(numpy.__version__)"
```

### 方法3: 別の環境でビルド

ローカルマシンやCI環境でderivationをビルドし、binary cacheにプッシュしてから、Claude Code on the Web環境で取得します。

## できないこと

以下の操作は、この環境では**実行できません**：

1. **カスタムderivationのビルド**
   ```bash
   # 失敗する
   nix-build my-package.nix
   ```

2. **開発環境の構築（withPackagesを使用）**
   ```bash
   # 失敗する
   nix develop -c bash
   nix-shell -p 'python3.withPackages(ps: [ ps.numpy ])'
   ```

3. **nix-channelの使用**
   ```bash
   # 失敗する
   nix-channel --update
   ```

4. **nix-envでのパッケージインストール**
   ```bash
   # 失敗する（derivationのビルドが必要な場合）
   nix-env -i hello
   ```

## 推奨される使い方

Claude Code on the Web環境でNixを使用する場合：

1. **パッケージの検索**
   ```bash
   nix search nixpkgs <package-name> --extra-experimental-features "nix-command flakes"
   ```

2. **パッケージのインストール**
   ```bash
   nix profile install nixpkgs#<package> --extra-experimental-features "nix-command flakes"
   ```

3. **一時的な使用**
   ```bash
   nix shell nixpkgs#<package> --extra-experimental-features "nix-command flakes"
   ```

4. **実行**
   ```bash
   nix run nixpkgs#<package> --extra-experimental-features "nix-command flakes"
   ```

## まとめ

### 根本原因

- **gVisor (runsc)** のpipe実装における、execve()後のO_CLOEXECフラグ付きpipeの処理の問題
- 標準的なLinuxではEOFが返されるべき状況で、EIO (Input/output error)が返される

### 影響範囲

- カスタムderivationのビルドが必要な全ての操作
- Binary cache (substitutes)が利用できない場合のパッケージインストール

### 実用的な解決策

- Binary cache (substitutes)を活用する
- `nix profile install`、`nix shell`、`nix run`を使用する
- カスタムビルドが必要な場合は、別の環境でビルドしてcacheに格納する

## gVisorの既存Issue調査

2025年10月時点で、この具体的な問題（O_CLOEXECフラグ付きpipeでexecve()後にEOFではなくEIOが返される）について、gVisorのGitHubリポジトリに報告されている既存のissueは**見つかりませんでした**。

### 調査した関連Issue

以下のissueを確認しましたが、本問題とは異なります：

- **Issue #101**: "failed to generate root mount point: broken pipe" - goferプロセスとの通信の問題
- **Issue #161**: "Send SIGPIPE when writing to a closed pipe/socket" - SIGPIPEシグナルの動作に関する議論
- **Issue #6796**: "Container exits with IO exception" - Javaプログラムの一般的なIOエラー
- **Issue #11064**: "checkpoint restored guest process stuck on write syscall to stdout" - checkpointに関する問題

### 新規Issue報告の推奨

この問題は、以下の理由から**gVisorプロジェクトに新規issueとして報告する価値がある**と考えられます：

1. **POSIX標準との不整合**: 標準的なLinuxではEOFが返されるべき状況でEIOが返される
2. **実用的な影響**: Nixなどのビルドシステムが動作しなくなる
3. **再現性**: straceで明確に再現・確認できる

### 報告時に含めるべき情報

- **環境情報**: runsc バージョン、カーネルバージョン
- **再現手順**: 最小限のderivationでの再現例
- **期待される動作**: 標準Linuxでの動作（EOF）
- **実際の動作**: gVisorでの動作（EIO）
- **straceログ**: pipe2()からread()までの詳細なトレース

## 関連情報

- [gVisor](https://gvisor.dev/)
- [gVisor GitHub Issues](https://github.com/google/gvisor/issues)
- [Nix Package Manager](https://nixos.org/)
- [Nix Binary Cache](https://nixos.org/manual/nix/stable/command-ref/conf-file.html#conf-substituters)
