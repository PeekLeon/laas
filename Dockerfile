# syntax=docker/dockerfile:1.4
FROM ubuntu:24.04 AS builder

# Installer les prérequis de base
RUN apt-get update && apt-get install -y \
    curl wget gnupg lsb-release ca-certificates git unzip zip sudo \
    && rm -rf /var/lib/apt/lists/*

# Copier le fichier de versions
COPY /.laas-config/versions.laas /tmp/versions.laas

ARG TARGETARCH

# Installer jq
RUN set -a && . /tmp/versions.laas && set +a \
    && if [ "$TARGETARCH" = "amd64" ]; then \
            curl -Lo /usr/local/bin/jq https://github.com/stedolan/jq/releases/download/$JQ_VERSION/jq-linux-amd64; \
       else \
            curl -Lo /usr/local/bin/jq https://github.com/stedolan/jq/releases/download/$JQ_VERSION/jq-linux-arm64; \
       fi \
    && chmod +x /usr/local/bin/jq

# Installer yq
RUN set -a && . /tmp/versions.laas && set +a \
    && if [ "$TARGETARCH" = "amd64" ]; then \
           wget https://github.com/mikefarah/yq/releases/download/${YQ_VERSION}/yq_linux_amd64 -O /usr/local/bin/yq; \
       else \
           wget https://github.com/mikefarah/yq/releases/download/${YQ_VERSION}/yq_linux_arm64 -O /usr/local/bin/yq; \
       fi \
    && chmod +x /usr/local/bin/yq

# Installer helm
RUN set -a && . /tmp/versions.laas && set +a \
    && if [ "$TARGETARCH" = "amd64" ]; then \
           curl -Lo helm.tar.gz https://get.helm.sh/helm-$HELM_VERSION-linux-amd64.tar.gz; \
       else \
           curl -Lo helm.tar.gz https://get.helm.sh/helm-$HELM_VERSION-linux-arm64.tar.gz; \
       fi \
    && tar -zxvf helm.tar.gz \
    && mv linux-*/helm /usr/local/bin/helm \
    && chmod +x /usr/local/bin/helm

# Installer starship
RUN set -a && . /tmp/versions.laas && set +a \
    && curl -fsSL https://starship.rs/install.sh | sh -s -- -y --version $STARSHIP_VERSION

# Installer oh-my-zsh
RUN set -a && . /tmp/versions.laas && set +a \
    && git clone https://github.com/ohmyzsh/ohmyzsh.git /opt/oh-my-zsh \
    && cd /opt/oh-my-zsh && git checkout $OHMYZSH_VERSION

# Installer kubectl
RUN set -a && . /tmp/versions.laas && set +a \
    && if [ "$TARGETARCH" = "amd64" ]; then \
           curl -LO "https://dl.k8s.io/release/$KUBECTL_VERSION/bin/linux/amd64/kubectl"; \
       else \
           curl -LO "https://dl.k8s.io/release/$KUBECTL_VERSION/bin/linux/arm64/kubectl"; \
       fi \
    && install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl \
    && rm kubectl

# Installer kubeconform
RUN set -a && . /tmp/versions.laas && set +a \
    && if [ "$TARGETARCH" = "amd64" ]; then \
           curl -Lo kubernetes-conform.tar.gz https://github.com/yannh/kubeconform/releases/download/$KUBECONFORM_VERSION/kubeconform-linux-amd64.tar.gz; \
       else \
           curl -Lo kubernetes-conform.tar.gz https://github.com/yannh/kubeconform/releases/download/$KUBECONFORM_VERSION/kubeconform-linux-arm64.tar.gz; \
       fi \
    && tar -zxvf kubernetes-conform.tar.gz \
    && mv kubeconform /usr/local/bin/kubeconform \
    && chmod +x /usr/local/bin/kubeconform

# Installer mc
RUN set -a && . /tmp/versions.laas && set +a \
    && if [ "$TARGETARCH" = "amd64" ]; then \
           curl -sSLo /usr/local/bin/mc "https://dl.min.io/client/mc/release/linux-amd64/mc.${MC_VERSION}"; \
       else \
           curl -sSLo /usr/local/bin/mc "https://dl.min.io/client/mc/release/linux-arm64/mc.${MC_VERSION}"; \
       fi \
    && chmod +x /usr/local/bin/mc

# Installer code-server
RUN set -a && . /tmp/versions.laas && set +a \
    && if [ "$TARGETARCH" = "amd64" ]; then \
           curl -Lo code-server.tar.gz https://github.com/coder/code-server/releases/download/${CODE_SERVER_VERSION}/code-server-${CODE_SERVER_VERSION#v}-linux-amd64.tar.gz; \
       else \
           curl -Lo code-server.tar.gz https://github.com/coder/code-server/releases/download/${CODE_SERVER_VERSION}/code-server-${CODE_SERVER_VERSION#v}-linux-arm64.tar.gz; \
       fi \
    && tar -xzf code-server.tar.gz \
    && mv code-server-${CODE_SERVER_VERSION#v}-linux-* /usr/lib/code-server \
    && chmod +x /usr/lib/code-server/bin/code-server

COPY ./tools/kube/* /usr/local/bin/.
COPY ./tools/laas /usr/local/bin/laas

CMD [ "bash" ]

# ---- Final Stage ----
FROM ubuntu:24.04 AS final

COPY .laas-config /.laas-config

RUN set -eux \
    && set -a && . /.laas-config/versions.laas && set +a \
    && apt-get update -y \
    && apt-get upgrade -y \
    && apt-get install -y --no-install-recommends \
        wget curl netcat-traditional git vim sudo tmux \
        inetutils-ping dnsutils rsync zsh openssh-client \
        ca-certificates gnupg lsb-release \
    && chsh -s /usr/bin/zsh \
    && mkdir -p /etc/apt/keyrings \
    && curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" > /etc/apt/sources.list.d/docker.list \
    && apt-get update \
    && apt-get install -y --no-install-recommends docker-ce-cli=${DOCKER_VERSION} docker-compose-plugin docker-buildx-plugin \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

COPY --from=builder /usr/lib/code-server /usr/lib/code-server
COPY --chmod=755 --from=builder /usr/local/bin/* /usr/local/bin/
COPY --from=builder /opt/oh-my-zsh /opt/oh-my-zsh
COPY --chmod=755 ./git/.git-hooks /usr/share/.git-hooks
COPY --chmod=755 ./entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
