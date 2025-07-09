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