
このドキュメントでは、Dockerを使ってGemini CLIを動かす方法を紹介します。

Gemini CLIの公式GitHubにはDockerfileが用意されていますが、その内容を見ると「独自にビルドしたtgzパッケージ」を使ってGemini CLIをインストールする方式になっています。

つまり、公式のDockerfileを利用する場合は、
1. Gemini CLIのソースコードをクローン
2. ビルドしてtgzファイルを生成
3. そのディレクトリでDockerビルドを実行
という手順が必要です。

Dockerなどの仮想コンテナ技術を仕様せず、ローカル環境でGeminiCLIをインストールしたときに、多くの方は`npm install -g @google/gemini-cli`コマンドでインストールしたはずです。

そこで今回は、公式のDockerfileを参考にしつつ、npmレジストリから直接Gemini CLIをインストールできるDockerfileを作成しました。
さらに、VSCodeやCursorなどのエディタで快適に開発できるよう、公式Dockerfileにいくつか便利な機能を追加しています。

---
## 1. 前提条件
- Docker Desktopがインストールされていること
- インターネット接続

では早速今回作成したDockerfileを見てみましょう。

GitHubはこちら（https://github.com/s-mekw/My_GeminiCLI_Dockerfile）


```Dockerfile
FROM docker.io/library/node:20-slim

ARG SANDBOX_NAME="gemini-cli-sandbox"
ARG CLI_VERSION_ARG
ENV SANDBOX="$SANDBOX_NAME"
ENV CLI_VERSION=$CLI_VERSION_ARG

# 必要なパッケージのインストール
RUN apt-get update && apt-get install -y --no-install-recommends \
  python3 \
  make \
  g++ \
  man-db \
  curl \
  dnsutils \
  less \
  jq \
  bc \
  gh \
  git \
  unzip \
  rsync \
  ripgrep \
  procps \
  psmisc \
  lsof \
  socat \
  ca-certificates \
  zsh \
  fzf \
  sudo \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

# npmグローバルディレクトリの作成と権限設定
RUN mkdir -p /usr/local/share/npm-global \
  && chown -R node:node /usr/local/share/npm-global
ENV NPM_CONFIG_PREFIX=/usr/local/share/npm-global
ENV PATH=$PATH:/usr/local/share/npm-global/bin

# /workspaceディレクトリの作成
RUN mkdir -p /workspace \
  && chown -R node:node /workspace

# zsh履歴の永続化
ARG USERNAME=node
RUN SNIPPET="export HISTFILE=/commandhistory/.zsh_history" \
  && mkdir /commandhistory \
  && touch /commandhistory/.zsh_history \
  && chown -R $USERNAME /commandhistory

# devcontainer環境フラグ
ENV DEVCONTAINER=true

# デフォルトシェルをzshに
ENV SHELL=/bin/zsh

# 非rootユーザーへの切り替え
USER node

# Gemini CLIをnpmから直接インストール
RUN npm install -g @google/gemini-cli \
  && npm cache clean --force

# zshとfzfのセットアップ（fzfキーバインドなど）
RUN echo "source /usr/share/doc/fzf/examples/key-bindings.zsh" >> ~/.zshrc \
  && echo "source /usr/share/doc/fzf/examples/completion.zsh" >> ~/.zshrc \
  && echo "export HISTFILE=/commandhistory/.zsh_history" >> ~/.zshrc

# 作業ディレクトリを /workspace に設定
WORKDIR /workspace

# デフォルトエントリポイント
CMD ["zsh"] 
```

## 公式との違い
- **追加パッケージ**: `Dockerfile_geminiOfficial/Dockerfile`はzsh, fzf, sudoなどもインストール。
- **作業ディレクトリ**: `Dockerfile_geminiOfficial/Dockerfile`は`/workspace`を作成し、WORKDIRに設定。
- **シェル**: `Dockerfile_geminiOfficial/Dockerfile`はzshをデフォルトシェルに。
- **履歴永続化**: zshの履歴を永続化する工夫あり。
- **devcontainer対応**: 以下のような開発環境向けの設定が含まれている。
  - `ENV DEVCONTAINER=true` でdevcontainer環境であることを明示
  - `/workspace`ディレクトリの作成と権限設定（VS Codeのdevcontainerでホストのファイルをマウントするための標準的な場所）
  - 履歴永続化（`/commandhistory/.zsh_history`）により、コンテナ再起動後もコマンド履歴が保持される
  - zshやfzf、sudoなど開発効率を高めるツールの導入、およびfzfのキーバインド設定
  これらの工夫により、VS Codeのdevcontainer機能で快適に開発できる環境が整っている

## 実際の使い方
　最初からVScodeやcursorのDevContainerを使用する方法もありますが、今回は純粋にDockerを用いてイメージを作成、コンテナを立ち上げ、VScodeでコンテナ内に入り込む方法を紹介します（筆者は実際にはDockerimageは作りますが、VScodeで開発するときには、devcontainer.jsonを記述しておき、そちらからコンテナを起動させています。）

---
## 2. Dockerイメージのビルド

任意の作業ディレクトリに、先ほど紹介したDockerfileを保存してください。  
そのディレクトリで以下のコマンドを実行し、Dockerイメージをビルドします。

```sh
docker build -t gemini-cli-dev .
```

- `-t gemini-cli-dev` はイメージ名を指定しています。お好みで変更可能です。
- `-f` オプションでDockerfileのファイル名やパスを指定したい場合は、`-f ./パス/Dockerfile` のように記述してください。

---
## 3. コンテナの起動

作業ディレクトリでターミナルを開き、以下のコマンドを実行してください。  
この例では、現在のディレクトリ（`${PWD}`）をコンテナの`/workspace`にマウントします。

```sh
docker run --rm -it \
  -v "${PWD}:/workspace" \
  -v "${USERPROFILE}\\.gemini:/home/node/.gemini" \
  -v "${USERPROFILE}\\.gitconfig:/home/node/.gitconfig" \
  gemini-cli-dev
```

- `-v "${PWD}:/workspace"` で現在の作業ディレクトリをコンテナにマウント
- `-v "${USERPROFILE}\\.gemini:/home/node/.gemini"` でローカルのGemini CLI認証情報をコンテナに引き継ぎ
- `-v "${USERPROFILE}\\.gitconfig:/home/node/.gitconfig"` でgitの設定も引き継ぎ

> すでにローカルでGemini CLIにログイン済みの場合、`.gemini`ディレクトリをマウントすることで、
> コンテナ内でもすぐに認証済みの状態で利用できます。

---
### 補足：コマンド履歴の永続化やコンテナ名の指定

さらに、コマンド履歴を永続化したい場合や、コンテナ名を指定したい場合は、  
以下のようなオプションも追加できます。

```sh
  -v gemini-cli-history:/commandhistory \
  --name gemini-cli-container \
```

---
## 4. VSCodeからコンテナにアタッチ（任意）

VSCodeの「Remote - Containers」拡張機能を使うと、今動かしているコンテナの中に直接入って開発ができます。
たとえば、VSCodeやCursorの左側にあるファイルエクスプローラで、コンテナ内の/workspaceフォルダの中身が見えるようになります。
また、ターミナルを開くと、コンテナの中でzsh（シェル）が起動します。
このように、VSCodeやCursorを使えば、コンテナの中の仮想環境を、まるで自分のパソコンのように簡単に操作できます。

1. コマンドパレット（`Ctrl+Shift+P`）で「Remote-Containers: Attach to Running Container...」を選択
2. `gemini-cli-container` を選択

これで、VSCode上でコンテナ内の `/workspace` を操作できます。

### （補足）Dockerのマウント（-v オプション）について

`-v` オプション（マウント）は、ホスト（自分のパソコン）のフォルダと、コンテナ内のフォルダを「つなぐ」ための機能です。

たとえば、

```
-v "${PWD}:/workspace"
```

と指定すると、ローカルの作業ディレクトリ（`${PWD}`）とコンテナ内の`/workspace`がリンクされます。

この状態では、
- ローカルでファイルを編集すると、コンテナ内の`/workspace`にもすぐに反映されます。
- 逆に、コンテナ内でファイルを作成・編集すると、ローカルの作業ディレクトリにも反映されます。

つまり、ローカルとコンテナ内の作業場が「同期」されているイメージです。

この仕組みにより、VSCodeやエディタでローカルのファイルを編集しつつ、コンテナ内でコマンドを実行して開発を進めることができます。また、GeminiCLIで生成・編集したファイルも即座にローカルに反映されます。GeminiCLI自体はコンテナ内で動作しているため、ローカル環境に影響を与える心配もありません。

---
## 5. Gemini CLIの動作確認

コンテナ内で以下のコマンドを実行し、Gemini CLIが正しく動作するか確認します。

バージョン確認：
```zsh
gemini --version
```

正常に表示されればセットアップ完了です。

```zsh
gemini
```
これでgeminiCLIを起動しましょう！



---
## 6. 補足・トラブルシューティング
- **パーミッションエラー**  
  マウント先のディレクトリがWindowsの場合、権限エラーが出ることがあります。その場合は、ホスト側のディレクトリの権限設定を見直してください。
- **履歴の永続化**  
  `-v gemini-cli-history:/commandhistory` を付けることで、コンテナを再起動してもコマンド履歴が残ります。

---
## 7. コンテナやイメージの終了・削除方法

### コンテナを閉じる（終了する）

コンテナ内で作業が終わったら、ターミナルで `exit` と入力するか、`Ctrl+D` を押すことでコンテナを終了できます。

### コンテナを削除する

今回の例のように `--rm` オプションを付けてコンテナを起動していれば、コンテナを終了した時点で自動的に削除されます。

もし `--rm` を付けずに起動した場合や、停止中のコンテナが残っている場合は、以下のコマンドで削除できます。

```sh
docker rm <コンテナ名またはID>
```

停止中のコンテナ一覧は次のコマンドで確認できます：

```sh
docker ps -a
```

### イメージを削除する

もう使わないDockerイメージを削除したい場合は、以下のコマンドを使います。

```sh
docker rmi <イメージ名またはID>
```

イメージ一覧は次のコマンドで確認できます：

```sh
docker images
```

> ※ イメージを削除する前に、そのイメージを使っているコンテナがすべて削除・停止されている必要があります。

---
## まとめ

このように、公式Dockerfileをベースにしつつnpmから直接インストールすることで、より手軽にGemini CLIの開発環境を構築できます。  
VSCodeのdevcontainerやRemote-Containers機能と組み合わせることで、快適な開発体験が得られます。  
ぜひご自身のプロジェクトに合わせてカスタマイズしてみてください。

---

