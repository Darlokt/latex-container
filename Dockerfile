# syntax=docker/dockerfile:1

ARG DEBIAN_BASE=debian:trixie-slim@sha256:020c0d20b9880058cbe785a9db107156c3c75c2ac944a6aa7ab59f2add76a7bd
FROM ${DEBIAN_BASE} AS runtime

ARG DEBIAN_BASE
ARG TEXLIVE_YEAR=2026
ARG TEXLIVE_REPOSITORY=https://mirror.ctan.org/systems/texlive/tlnet
ARG TEXLIVE_SNAPSHOT=development
ARG NODE_VERSION=24.18.0
ARG NODE_SHA256_AMD64=55aa7153f9d88f28d765fcdad5ae6945b5c0f98a36881703817e4c450fa76742
ARG NODE_SHA256_ARM64=58c9520501f6ae2b52d5b210444e24b9d0c029a58c5011b797bc1fe7105886f6
ARG NPM_VERSION=12.0.1
ARG USERNAME=vscode
ARG USER_UID=1000
ARG USER_GID=1000
ARG BUILD_DATE=unknown
ARG VCS_REF=unknown
ARG VERSION=edge
ARG TARGETARCH=unknown

ENV DEBIAN_FRONTEND=noninteractive \
    LANG=en_US.UTF-8 \
    LC_ALL=en_US.UTF-8 \
    TZ=Etc/UTC \
    PATH=/usr/local/texlive/bin:/opt/authoring-tools/node_modules/.bin:${PATH} \
    NODE_PATH=/opt/authoring-tools/node_modules \
    PUPPETEER_EXECUTABLE_PATH=/usr/bin/chromium \
    PUPPETEER_SKIP_DOWNLOAD=true

LABEL org.opencontainers.image.title="LaTeX Dev Container" \
      org.opencontainers.image.description="Full TeX Live scientific authoring environment for VS Code Dev Containers" \
      org.opencontainers.image.source="https://github.com/OWNER/latex-container" \
      org.opencontainers.image.documentation="https://github.com/OWNER/latex-container#readme" \
      org.opencontainers.image.licenses="MIT" \
      org.opencontainers.image.created="${BUILD_DATE}" \
      org.opencontainers.image.revision="${VCS_REF}" \
      org.opencontainers.image.version="${VERSION}" \
      devcontainer.metadata='[{"remoteUser":"vscode","containerUser":"vscode","updateRemoteUserUID":true,"init":true,"customizations":{"vscode":{"extensions":["James-Yu.latex-workshop","streetsidesoftware.code-spell-checker","streetsidesoftware.code-spell-checker-scientific-terms","streetsidesoftware.code-spell-checker-medical-terms","streetsidesoftware.code-spell-checker-german","ltex-plus.vscode-ltex-plus","DavidAnson.vscode-markdownlint","yzhang.markdown-all-in-one","bierner.markdown-mermaid"]}}}]'

COPY packages/debian.txt /tmp/debian-packages.txt

RUN set -eux; \
    apt-get update; \
    xargs -r apt-get install -y --no-install-recommends < /tmp/debian-packages.txt; \
    sed -i 's/^# \(en_US.UTF-8 UTF-8\)/\1/' /etc/locale.gen; \
    locale-gen; \
    git lfs install --system; \
    fc-cache -f; \
    rm -rf /var/lib/apt/lists/* /tmp/debian-packages.txt

RUN set -eux; \
    groupadd --gid "${USER_GID}" "${USERNAME}"; \
    useradd --uid "${USER_UID}" --gid "${USER_GID}" --create-home --shell /bin/bash "${USERNAME}"; \
    printf '%s ALL=(ALL) NOPASSWD:ALL\n' "${USERNAME}" > "/etc/sudoers.d/${USERNAME}"; \
    chmod 0440 "/etc/sudoers.d/${USERNAME}"; \
    install -d -o "${USER_UID}" -g "${USER_GID}" /workspace

RUN set -eux; \
    case "${TARGETARCH}" in \
      amd64) NODE_ARCH=x64; NODE_SHA256="${NODE_SHA256_AMD64}" ;; \
      arm64) NODE_ARCH=arm64; NODE_SHA256="${NODE_SHA256_ARM64}" ;; \
      *) printf 'Unsupported Node.js architecture: %s\n' "${TARGETARCH}" >&2; exit 1 ;; \
    esac; \
    NODE_ARCHIVE="node-v${NODE_VERSION}-linux-${NODE_ARCH}.tar.xz"; \
    curl --fail --location --show-error --silent \
      "https://nodejs.org/dist/v${NODE_VERSION}/${NODE_ARCHIVE}" \
      --output "/tmp/${NODE_ARCHIVE}"; \
    printf '%s  %s\n' "${NODE_SHA256}" "/tmp/${NODE_ARCHIVE}" \
      > /tmp/node-sha256; \
    sha256sum --check /tmp/node-sha256; \
    tar --extract --xz --file="/tmp/${NODE_ARCHIVE}" \
      --directory=/usr/local --strip-components=1; \
    rm "/tmp/${NODE_ARCHIVE}" /tmp/node-sha256; \
    npm install --global "npm@${NPM_VERSION}"; \
    node --version; \
    npm --version

COPY texlive.profile /tmp/texlive.profile

# TEXLIVE_SNAPSHOT deliberately invalidates this layer for dated rolling snapshots.
RUN set -eux; \
    printf 'Installing TeX Live snapshot %s\n' "${TEXLIVE_SNAPSHOT}"; \
    install -d /tmp/install-tl; \
    curl --fail --location --show-error --silent \
      "${TEXLIVE_REPOSITORY}/install-tl-unx.tar.gz" \
      --output /tmp/install-tl.tar.gz; \
    curl --fail --location --show-error --silent \
      "${TEXLIVE_REPOSITORY}/install-tl-unx.tar.gz.sha512" \
      --output /tmp/install-tl.tar.gz.sha512; \
    sed -i 's#\([ *]\)install-tl-unx.tar.gz$#\1/tmp/install-tl.tar.gz#' /tmp/install-tl.tar.gz.sha512; \
    sha512sum --check /tmp/install-tl.tar.gz.sha512; \
    tar --extract --gzip --file=/tmp/install-tl.tar.gz --directory=/tmp/install-tl --strip-components=1; \
    TL_PLATFORM="$(/tmp/install-tl/install-tl --print-platform)"; \
    /tmp/install-tl/install-tl \
      --profile=/tmp/texlive.profile \
      --repository="${TEXLIVE_REPOSITORY}" \
      --strict; \
    ln -s "/usr/local/texlive/${TEXLIVE_YEAR}/bin/${TL_PLATFORM}" /usr/local/texlive/bin; \
    printf '%s\n' "${TL_PLATFORM}" > /usr/local/texlive/platform; \
    rm -rf /tmp/install-tl /tmp/install-tl.tar.gz /tmp/install-tl.tar.gz.sha512 /tmp/texlive.profile; \
    mktexlsr; \
    fmtutil-sys --all; \
    updmap-sys

WORKDIR /opt/authoring-tools
COPY package.json package-lock.json ./

RUN set -eux; \
    npm ci --omit=dev --ignore-scripts; \
    npm cache clean --force; \
    ln -s /opt/authoring-tools/node_modules/.bin/mmdc /usr/local/bin/mmdc-real

COPY config/mermaid-puppeteer.json /etc/mermaid/puppeteer.json
COPY --chmod=0755 scripts/mmdc /usr/local/bin/mmdc
COPY --chmod=0755 scripts/check-latex-environment /usr/local/bin/check-latex-environment

RUN set -eux; \
    install -d /usr/local/share/latex-container; \
    dpkg-query -W -f='${binary:Package}\t${Version}\n' \
      > /usr/local/share/latex-container/debian-packages.tsv; \
    tlmgr info --only-installed \
      > /usr/local/share/latex-container/texlive-packages.txt; \
    python3 -m pip list --format=freeze \
      > /usr/local/share/latex-container/python-packages.txt; \
    npm ls --omit=dev --depth=0 --json \
      > /usr/local/share/latex-container/node-packages.json; \
    Rscript -e 'write.csv(installed.packages()[,c("Package","Version")], "/usr/local/share/latex-container/r-packages.csv", row.names=FALSE)'; \
    jq --null-input \
      --arg base_image "${DEBIAN_BASE}" \
      --arg build_date "${BUILD_DATE}" \
      --arg revision "${VCS_REF}" \
      --arg node_version "$(node --version)" \
      --arg npm_version "$(npm --version)" \
      --arg target_arch "${TARGETARCH}" \
      --arg texlive_repository "${TEXLIVE_REPOSITORY}" \
      --arg texlive_snapshot "${TEXLIVE_SNAPSHOT}" \
      --arg texlive_year "${TEXLIVE_YEAR}" \
      --arg version "${VERSION}" \
      '{base_image:$base_image,build_date:$build_date,node_version:$node_version,npm_version:$npm_version,revision:$revision,target_arch:$target_arch,texlive_repository:$texlive_repository,texlive_snapshot:$texlive_snapshot,texlive_year:$texlive_year,version:$version}' \
      > /usr/local/share/latex-container/build-info.json; \
    chmod -R a+rX /usr/local/share/latex-container /etc/mermaid

USER ${USERNAME}
WORKDIR /workspace

CMD ["sleep", "infinity"]

FROM runtime AS test

USER root
COPY --chmod=0755 tests/smoke/run-smoke-tests /usr/local/bin/run-smoke-tests
COPY --chown=vscode:vscode tests/fixtures /tmp/latex-container-tests
USER vscode
WORKDIR /tmp/latex-container-tests
RUN check-latex-environment && run-smoke-tests

FROM runtime AS final
