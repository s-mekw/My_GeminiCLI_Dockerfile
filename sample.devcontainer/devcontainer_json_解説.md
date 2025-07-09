# devcontainer.json 解説

このドキュメントでは、.devcontainer/devcontainer.json の各項目について詳しく解説します。

---

## name
- **内容**: DevContainerの名前（VSCodeなどで表示される）
- **例**: "Gemini CLI DevContainer"
- **効果**: 複数のDevContainerを使い分ける際に識別しやすくなる

---

## image
- **内容**: 利用するDockerイメージ名
- **例**: "gemini-cli-dev"
- **効果**: 既にビルド済みのイメージからコンテナを起動できる
- **補足**: buildセクションがない場合はこのimageが使われる

---

## workspaceFolder
- **内容**: DevContainer内での作業ディレクトリのパス
- **例**: "/workspace"
- **効果**: VSCodeやターミナルの初期ディレクトリがここになる

---

## mounts
- **内容**: ホストとコンテナ間でディレクトリやファイルをバインドマウントする設定
- **例**:
  - `source=${localWorkspaceFolder},target=/workspace,type=bind`
    - ローカルの作業ディレクトリをコンテナの /workspace にマウント
  - `source=${localEnv:USERPROFILE}\.gemini,target=/home/node/.gemini,type=bind`
    - ホストの .gemini ディレクトリをコンテナの /home/node/.gemini にマウント
  - `source=${localEnv:USERPROFILE}\.gitconfig,target=/home/node/.gitconfig,type=bind`
    - ホストの .gitconfig をコンテナの /home/node/.gitconfig にマウント
- **効果**: 設定や作業ファイルをホストとコンテナで共有できる

---

## settings
- **内容**: VSCodeのユーザー設定を上書きするためのオブジェクト
- **例**: `{}`（今回は空）
- **効果**: DevContainer内だけで有効なエディタ設定を指定できる

---

## extensions
- **内容**: DevContainer起動時に自動インストールするVSCode拡張機能のリスト
- **例**: `[]`（今回は空）
- **効果**: 必要な拡張機能を自動でセットアップできる

---

## postCreateCommand
- **内容**: DevContainer作成後に自動実行するコマンド
- **例**: `""`（今回は空）
- **効果**: 依存パッケージのインストールや初期化処理を自動化できる

---

## まとめ
このdevcontainer.jsonは、ビルド済みのgemini-cli-devイメージを使い、/workspaceを作業ディレクトリとしてホストと共有し、.geminiや.gitconfigも /home/node 配下にマウントする設定です。開発環境の再現性や利便性が高まります。 