# EN→JA Translation Glossary

Mandatory terminology mappings for translating this literate Nix configuration.
Derived from existing translations in `po/ja.po` and standard Nix/Emacs community usage.

## Keep in English (do not translate)

These terms are proper nouns or have no widely accepted Japanese equivalent in the
Nix ecosystem. Use them as-is (no katakana transliteration).

| English             | Notes                                      |
|---------------------|--------------------------------------------|
| Nix                 | Package manager / language name            |
| NixOS               | Operating system                           |
| nixpkgs             | Package repository                         |
| flake               | Nix flake (the feature)                    |
| flake.nix           | File name                                  |
| flake.lock          | File name                                  |
| derivation          | Nix build unit                             |
| overlay             | Nixpkgs extension mechanism                |
| home-manager        | Tool name (Home Manager when at sentence start) |
| nix-darwin          | Tool name                                  |
| Hercules CI         | CI service name                            |
| po4a                | Tool name                                  |
| Org mode            | Emacs major mode name                      |
| Emacs               | Editor name                                |
| Git                 | VCS name                                   |
| GitHub              | Service name                               |
| treefmt             | Tool name                                  |
| niri                | Wayland compositor name                    |
| Zen Browser         | Browser name                               |
| Starship            | Prompt tool name                           |
| fish                | Shell name                                 |
| direnv              | Tool name                                  |

## Translate to Japanese

| English                    | Japanese                   | Notes                                    |
|----------------------------|----------------------------|------------------------------------------|
| literate programming       | 文芸的プログラミング       | Established term (Knuth)                 |
| literate configuration     | 文芸的設定                 | From existing translations               |
| declarative                | 宣言的                     | 宣言的な when used as adjective          |
| configuration              | 設定                       |                                          |
| system configuration       | システム設定               | From existing translations               |
| package manager            | パッケージマネージャー     |                                          |
| package                    | パッケージ                 |                                          |
| module                     | モジュール                 |                                          |
| option                     | オプション                 |                                          |
| repository                 | リポジトリ                 |                                          |
| build                      | ビルド                     |                                          |
| input (flake input)        | 入力 / input               | Use "入力" in prose, "input" in technical context |
| output (flake output)      | 出力 / output              | Same as above                            |
| shell                      | シェル                     |                                          |
| environment                | 環境                       |                                          |
| development environment    | 開発環境                   |                                          |
| plugin                     | プラグイン                 |                                          |
| extension                  | 拡張機能                   |                                          |
| keybinding                 | キーバインド               |                                          |
| workaround                 | 回避策                     |                                          |
| upstream                   | アップストリーム           |                                          |
| downstream                 | ダウンストリーム           |                                          |
| dependency                 | 依存関係                   |                                          |
| pinning (version)          | ピン留め / 固定            |                                          |
| reproducible               | 再現可能な                 |                                          |
| pure evaluation            | 純粋な評価                 |                                          |
| impure                     | impure                     | Keep English in Nix context              |
| tangle (Org)               | タングル                   | Org mode term                            |
| weave (Org)                | ウィーブ                   | Org mode term                            |
| translation                | 翻訳                       | From existing translations               |
| documentation              | ドキュメント               |                                          |
| desktop environment        | デスクトップ環境           |                                          |
| window manager             | ウィンドウマネージャー     |                                          |
| search engine              | 検索エンジン               |                                          |
| file manager               | ファイルマネージャー       |                                          |
| terminal emulator          | ターミナルエミュレーター   |                                          |
| theme                      | テーマ                     |                                          |
| font                       | フォント                   |                                          |
| enable / disable           | 有効にする / 無効にする    |                                          |
| default                    | デフォルト                 |                                          |

## Sentence-Level Patterns

| English pattern                         | Japanese pattern                         |
|-----------------------------------------|------------------------------------------|
| "X is configured to..."                 | "Xは...に設定されています"               |
| "This enables..."                       | "これにより...が有効になります"           |
| "We use X because..."                   | "...のため、Xを使用しています"           |
| "Rather than X, we chose Y because..."  | "Xではなく、...のためYを選択しました"    |
| "The reason for X is..."               | "Xの理由は...です"                        |
