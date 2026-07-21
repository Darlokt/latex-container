# Contributing

Run `make check` before opening a pull request. Changes to the image should also
run `make test` when local disk and time permit. The full build is large, so a
pull request may rely on CI for the first complete TeX installation.

Keep `packages/debian.txt` sorted, pin Node dependencies exactly, commit the
updated lock file, and avoid adding project-specific scientific packages to the
shared image. Add or update a smoke fixture whenever a toolchain behavior
changes.

Release tags use `tl2026-debian13-rN`. Publishing is started only through a
manual workflow dispatch or a published GitHub Release. Do not move or recreate
release or snapshot tags after publication.
