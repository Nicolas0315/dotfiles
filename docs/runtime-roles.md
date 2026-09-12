# 開発・制作環境の担当

確認日: 2026-09-12。個別端末の観測はprivateな環境台帳へ置き、このpublic repoには共通の扱いだけを置きます。

| 目的 | 担当 | 維持する理由 |
|---|---|---|
| プロジェクトのNode/Python | mise、プロジェクトの設定・lock | repoが要求する版を優先し、対話shellでもshimを使う |
| Pythonライブラリ・実行環境 | uvと各repoの仮想環境 | プロジェクト間の依存を分離する |
| macOSの共通CLIとアプリ | Homebrew | miseとの重複だけでは削除しない。導入済みCLIの依存を確認する |
| Windowsの共通CLIとアプリ | winget、既存の導入管理元 | Scoop等の既存導入を別管理元で上書きしない |
| 既存fleet CLIと共有profile | katala-tooling | 稼働中の `~/work/katala-tooling` とsymlinkを保持する |
| 新しいソース取得 | ghq | 既存checkoutを移動せず、新規cloneの置き場所だけを統一する |

## Nodeの重複を判断する

`dot_config/mise/config.toml` はNode 24とPython 3.13を既定にします。プロジェクト固有のpinはそのrepoに置きます。
HomebrewのNodeは、Homebrewが管理するCLIの依存で残る場合があります。
2026-09-12の確認ではbirdclaw / mcporter / oracle / summarizeが該当し、4 CLIとも `--version` が成功しました。

削除を検討する前に `brew uses --installed node` と対象CLIの実行を確認します。
shimの先頭化は既存の `dot_zshrc` とshared profileが担当します。新たなPATH管理ファイルは追加しません。
pyenv等の旧ランタイムも、既存ジョブの参照がないと確認するまでは保持します。

## 確認

1. 実際の対話shellで `command -v node python3` とそれぞれの `--version` を確認する。
2. 対象repoの最小テストを、そのrepoの指定ランタイムで実行する。
3. Homebrew依存のCLIは別に起動を確認する。
4. 変更する場合だけ `scripts/verify.sh` と必要なローカル検証を行う。

外観上の数合わせ、全パッケージ更新、別の環境管理基盤への移行はこの整理の目的にしません。

公式: [miseのshim](https://mise.jdx.dev/dev-tools/shims.html)、[Homebrew manpage](https://docs.brew.sh/Manpage)、[uv projects](https://docs.astral.sh/uv/guides/projects/)。
