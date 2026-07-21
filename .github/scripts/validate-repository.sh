#!/usr/bin/env bash
set -euo pipefail

if ! diff -u packages/debian.txt <(LC_ALL=C sort -u packages/debian.txt); then
  printf '%s\n' 'packages/debian.txt must be sorted and contain no duplicates.' >&2
  exit 1
fi

jq --exit-status . package.json package-lock.json \
  config/mermaid-puppeteer.json \
  template/document-repo/.devcontainer/devcontainer.json \
  template/document-repo/.vscode/settings.json >/dev/null

required_profile_settings=(
  'selected_scheme scheme-full'
  'instopt_letter 0'
  'tlpdbopt_install_docfiles 1'
  'tlpdbopt_install_srcfiles 0'
)

for setting in "${required_profile_settings[@]}"; do
  grep --fixed-strings --line-regexp "${setting}" texlive.profile >/dev/null
done

required_extensions=(
  James-Yu.latex-workshop
  streetsidesoftware.code-spell-checker
  streetsidesoftware.code-spell-checker-scientific-terms
  streetsidesoftware.code-spell-checker-medical-terms
  streetsidesoftware.code-spell-checker-german
  ltex-plus.vscode-ltex-plus
  DavidAnson.vscode-markdownlint
  yzhang.markdown-all-in-one
  bierner.markdown-mermaid
)

for extension in "${required_extensions[@]}"; do
  grep --fixed-strings "${extension}" Dockerfile >/dev/null
done

grep --fixed-strings 'FROM runtime AS test' Dockerfile >/dev/null
grep --fixed-strings 'FROM runtime AS final' Dockerfile >/dev/null
grep --fixed-strings "USER \${USERNAME}" Dockerfile >/dev/null
grep --fixed-strings 'CMD ["sleep", "infinity"]' Dockerfile >/dev/null
grep --fixed-strings --line-regexp '24.18.0' .nvmrc >/dev/null
grep --fixed-strings 'ARG NODE_VERSION=24.18.0' Dockerfile >/dev/null
grep --fixed-strings 'ARG NPM_VERSION=12.0.1' Dockerfile >/dev/null

mapfile -t provenance_disabled < <(
  grep --no-filename --fixed-strings 'provenance: false' .github/workflows/*.yml
)
mapfile -t sbom_disabled < <(
  grep --no-filename --fixed-strings 'sbom: false' .github/workflows/*.yml
)
test "${#provenance_disabled[@]}" -ge 2
test "${#sbom_disabled[@]}" -ge 2
grep --fixed-strings 'uses: actions/attest@' .github/workflows/publish.yml >/dev/null
attestation_digest_expression='subject-digest: $'
attestation_digest_expression+='{{ steps.manifest.outputs.digest }}'
grep --fixed-strings "${attestation_digest_expression}" \
  .github/workflows/publish.yml >/dev/null
grep --fixed-strings 'push-to-registry: true' .github/workflows/publish.yml >/dev/null

test ! -e rough_plan.md
test -s template/document-repo/project-words.txt

printf '%s\n' 'Repository structure OK'
