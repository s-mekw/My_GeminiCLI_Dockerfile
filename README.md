# Gemini CLI Dockerfile リポジトリ

このリポジトリは、Google Gemini CLI をDocker上で手軽に動かすためのDockerfileと、その使い方をまとめたものです。

## 概要
- 公式Dockerfileを参考に、npmレジストリから直接Gemini CLIをインストールできるDockerfileを用意
- VSCodeやCursorのdevcontainerにも対応し、開発効率を高める工夫を追加

## 前提条件
- Docker Desktopがインストールされていること
- インターネット接続

## 使い方

### 1. Dockerイメージのビルド

```sh
docker build -t gemini-cli-dev .
```

- `-t gemini-cli-dev` はイメージ名です。任意で変更可能です。

### 2. コンテナの起動

```sh
docker run --rm -it \
  -v "${PWD}:/workspace" \
  -v "${USERPROFILE}\\.gemini:/home/node/.gemini" \
  -v "${USERPROFILE}\\.gitconfig:/home/node/.gitconfig" \
  gemini-cli-dev
```

- `${PWD}` を `/workspace` にマウントし、ローカルの .gemini や .gitconfig も `${USERPROFILE}` を使って引き継ぎます。
- コマンド履歴の永続化やコンテナ名指定も可能です（詳細は `Docker_で_GeminiCLI.md` 参照）。

### 3. VSCodeからの利用（任意）
- Remote - Containers拡張機能で、起動中のコンテナにアタッチ可能
- `sample.devcontainer` ディレクトリにサンプル設定あり

### 4. Gemini CLIの動作確認

```zsh
gemini --version
gemini
```

## トラブルシューティング
- 権限エラー: ホスト側ディレクトリの権限を確認
- 履歴永続化: `-v gemini-cli-history:/commandhistory` でコマンド履歴を保持

## コンテナ・イメージの削除
- コンテナ: `exit` または `docker rm <コンテナ名>`
- イメージ: `docker rmi <イメージ名>`

## 参考
- 詳細な手順や補足は `Docker_De_GeminiCLI.md` を参照してください。

---

ご自身のプロジェクトに合わせてカスタマイズしてご利用ください。
