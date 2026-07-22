# LaTeX Dev Container

A single, batteries-included development container for writing and rendering
LaTeX and Markdown documents in VS Code. It combines full upstream TeX Live
2026 with LaTeX Workshop, Pandoc, scientific runtimes, diagram generators, PDF
inspection tools, and scientific/medical writing assistance.

The image is intentionally large. TeX Live's full scheme alone occupies about
9.4 GB before the scientific, browser, and authoring layers are added. Pull it
once and reuse it across document repositories.

## Use it in a document repository

Copy [`template/document-repo/.devcontainer/devcontainer.json`](template/document-repo/.devcontainer/devcontainer.json)
to `.devcontainer/devcontainer.json` in the paper, thesis, or report repository:

```json
{
  "name": "LaTeX document",
  "image": "ghcr.io/darlokt/latex-container:tl2026",
  "remoteUser": "vscode",
  "updateRemoteUserUID": true,
  "init": true
}
```

The `tl2026` alias follows the newest stable TeX Live 2026 release. For fully
reproducible builds, replace it with an immutable release tag and digest from
the published GHCR package.

Open that repository in VS Code and choose **Dev Containers: Reopen in
Container**. VS Code bind-mounts the repository automatically, normally under
`/workspaces/<repository-name>`; no custom volume or Docker socket is required.
The image metadata installs these extensions in the remote VS Code environment:

- LaTeX Workshop
- Code Spell Checker with scientific, medical, and German dictionaries
- LTeX+ grammar and style checking
- Markdownlint, Markdown All in One, and Mermaid Markdown preview

The full consumer template also supplies safe LaTeX Workshop recipes and a
project terminology file. Copy the files you want from
[`template/document-repo`](template/document-repo).

## Included authoring stack

| Area | Included tools |
| --- | --- |
| TeX | TeX Live 2026 `scheme-full`, documentation, Latexmk, Biber/BibTeX, PythonTeX, Minted, Arara, Asymptote, `latexindent`, `latexdiff`, ChkTeX |
| Markdown | Pandoc and Mermaid CLI; Markdownlint through its VS Code extension |
| Figures | Mermaid, Graphviz, Gnuplot, PlantUML, Inkscape, librsvg, ImageMagick, Ghostscript |
| PDF | Poppler tools, QPDF, Ghostscript |
| Languages | Python/Pygments, R/Knitr/R Markdown, Java, C/C++/Fortran build tools |
| Fonts | DejaVu, Liberation, and broad Noto families including CJK and emoji |
| Development | Node.js 24 LTS, npm 12, Git, Git LFS, `prek`, SSH client, Make, ShellCheck, jq, rsync, sudo |

The container deliberately excludes SageMath, Octave, Julia, Conda,
proprietary fonts, complete CRAN/Bioconductor collections, desktop
applications, and host Docker access. A document with specialized analysis
requirements can use a small project-local Dockerfile with the published image
as its `FROM` line.

## Build documents and figures

The safe default does not enable unrestricted shell execution:

```bash
latexmk -pdf -synctex=1 -interaction=nonstopmode -halt-on-error \
  -file-line-error -outdir=build main.tex
```

Select the separate shell-escape recipe only for a trusted document that needs
tools such as `gnuplottex` or automated SVG conversion:

```bash
latexmk -pdf -shell-escape -synctex=1 -interaction=nonstopmode \
  -halt-on-error -file-line-error -outdir=build main.tex
```

Generate diagrams in formats that LaTeX can embed:

```bash
mmdc -i figures/workflow.mmd -o figures/workflow.svg
mmdc -i figures/workflow.mmd -o figures/workflow.png
mmdc -i figures/workflow.mmd -o figures/workflow.pdf
dot -Tpdf figures/model.dot -o figures/model.pdf
plantuml -tsvg figures/sequence.puml
inkscape figures/source.svg --export-type=pdf
```

Mermaid uses the system Chromium through a container-safe Puppeteer
configuration. Override it with `MERMAID_PUPPETEER_CONFIG=/path/to/config.json`
when a document needs different browser flags.

Pandoc can render Markdown with Zotero-exported citations:

```bash
pandoc manuscript.md --citeproc --bibliography=references.bib \
  --pdf-engine=lualatex -o build/manuscript.pdf
```

## Zotero bibliography workflow

Run Zotero and Better BibTeX on the host, not in the container. Configure a
Zotero collection for **Better BibLaTeX** auto-export to `references.bib`
inside the document repository. Because the repository is an ordinary host
directory mounted by VS Code, changes appear immediately in the container.

Use BibLaTeX/Biber for new work when the publisher permits it. TeX Live also
contains classic BibTeX for journal templates that require it. Avoid fetching
the Zotero localhost API during a build: it couples compilation to host
networking and makes CI non-reproducible.

## Proofing

Proofing is editor-based. Code Spell Checker runs locally in the VS Code
extension host and receives the scientific, medical, and German dictionary
extensions from the image metadata. LTeX+ adds LaTeX/Markdown-aware grammar and
style diagnostics. Document-specific terms belong in a tracked
`project-words.txt`; see the template settings.

## Git hooks

`prek` 0.4.10 is installed as a fast, pre-commit-compatible Git hook runner.
Document repositories can keep either a `prek.toml` or an existing
`.pre-commit-config.yaml`, then enable and run the hooks inside the container:

```bash
prek install
prek run --all-files
```

The consumer Makefile exposes the same commands as `make hooks` and
`make hooks-run`. Hook installation remains explicit because it writes into
the document repository's Git metadata.

## Image tags and reproducibility

| Tag | Meaning |
| --- | --- |
| `edge` | Latest successful manual publication; mutable |
| `tl2026-snapshot-YYYYMMDD` | Suggested immutable tag for a manual snapshot |
| `tl2026-debian13-rN` | Manually promoted immutable release |
| `tl2026`, `latest` | Aliases updated by a GitHub Release or an explicit manual option |

TeX Live's yearly network repository changes during the year. Source alone
cannot recreate an earlier network installation. Pin document repositories to
an immutable image digest. Every image records Debian, TeX Live, npm, Python,
and R inventories under `/usr/local/share/latex-container/`.

Both `linux/amd64` and `linux/arm64` are published. The native runners used for
these builds must provide enough free disk space for the complete TeX Live
installation and Docker build cache.

Publishing never runs on a branch push or schedule. Use the **Build and publish
image** workflow with an explicit unused tag, or publish a GitHub Release tagged
`tl2026-debian13-rN`. Release publication also advances `tl2026` and `latest`.

## Maintainer commands

```bash
make check    # fast repository checks
make build    # build latex-container:local
make test     # build and run the complete smoke-test stage
make inspect  # inspect and verify the local image
```

Override `IMAGE`, `PLATFORM`, `TEXLIVE_SNAPSHOT`, or other Make variables as
needed. A clean build downloads the complete TeX distribution and can take a
long time.

## License

The repository-authored files are MIT licensed. Bundled software and VS Code
extensions retain their own licenses, which are not changed by this project.
