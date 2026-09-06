# Mac / Windows development environment contract

共通化するのはツールの役割と検証方法です。OS固有のシェル、配置、認証ストア、常駐方式は別管理にします。

| 領域 | macOS | Windows |
| --- | --- | --- |
| シェル | zsh、既存の共有profile | PowerShell 7、既存のユーザーprofile |
| ランタイム | mise、Node 24 / Python 3.13 | mise、同じmajor/minor。shimはLOCALAPPDATA配下 |
| パッケージ | Homebrew + mise | 既存winget / mise / npm。管理元を重複させない |
| エージェント | Claude / Codex / agy | 同じ役割。CLI版数成功と認証・prompt成功は別 |
| ターミナル | Herdr、必要に応じtmux | Herdr native。WSLはLinux固有の用途のみ |
| リポジトリ | 新規はghq、既存workを維持 | 同左。Git Bashとnative pathを混同しない |
| 履歴・秘密 | ホスト固有 | ホスト固有。dotfilesに複製しない |

パッチ版を揃えるだけの一括更新は行いません。プロジェクトのロック・mise設定・必要機能から変更を決めます。`rec`の未導入は用途判断が必要です。Herdrを使っている環境へ別のmultiplexerを機械的に追加しません。

## 検証

- Windows: `pwsh -NoProfile -File windows/dev-doctor.ps1 -Json`。全行を検証してから実行し、各コマンドに15秒の期限を設けます。`ok`, `missing`, `failed`, `timed_out`, `wsl_not_checked`を区別します。
- exit 0は必須・AI CLIのバージョン実行成功だけを意味します。推奨ツール、WSL、認証、MCP、実プロンプトは別です。
- Mac: `scripts/doctor.sh`。Homebrew/mise/chezmoiの非ゼロ終了を空出力の成功に変換しません。chezmoiの状態確認はscripts/encryptedを除外し、秘密を含みうる差分本文を取得しません。
- `scripts/verify.sh`は全bash/zshファイルを個別に構文検証し、Mac診断のオフライン回帰テストを実行します。Windows CIはPowerShell構文と実プロセスを使う回帰テストを実行します。
- Windows setupはdry-runが既定です。インストール失敗、管理ツール欠落、インストール後の実行確認失敗を非ゼロ終了にします。新しいPATHが必要なら新規シェルで再検証します。

## 適用と復元

既存のdirtyや作業ブランチは保持します。クリーンな配布checkoutだけをfast-forwardし、既存profile・chezmoi全体を一括上書きしません。更新前のHEADをホスト固有の証拠に残し、必要な場合は旧HEADの別worktreeから診断スクリプトを実行できます。今回は新しいstartup、同期daemon、WSL起動を追加しません。

生成JSONには実行ファイルのローカルパスが入るため、公開リポジトリへコミットせずローカル証拠として保管します。保管は直近3世代を目安にし、旧世代削除は所有権と復元不要を確認して行います。

## 根拠

- [miseのshimとOS別配置](https://mise.jdx.dev/dev-tools/shims.html)
- [chezmoi statusと除外指定](https://www.chezmoi.io/reference/commands/status/)
- [Antigravity CLIのMac/Windows対応](https://antigravity.google/docs/cli/install/)
- [PowerShellの終了コード](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_automatic_variables)

Google担当は既存のfleet-env-manifestとBrewfileに合わせて`agy`を正典にします。旧Gemini CLIを不足として自動再導入しません。
