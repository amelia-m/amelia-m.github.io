#!/bin/bash
# Install what `quarto render` needs. Claude Code on the web starts from a bare
# container, so without this a session cannot build the site at all.
#
# Everything here comes from the Ubuntu archive except Quarto itself, which has
# no Ubuntu package. R packages are the distro's r-cran-* builds rather than
# install.packages(): they are precompiled, so this takes seconds instead of
# compiling knitr and its dependencies from source.
#
# Needs these hosts reachable under the environment's network policy:
#   - the Ubuntu archive (apt)
#   - github.com and release-assets.githubusercontent.com (the Quarto .deb)
# Set them under Allowed domains in the cloud environment's settings if the
# Quarto step fails with a proxy 403.
set -euo pipefail

# Local machines already have their own toolchain; only build out the container.
if [ "${CLAUDE_CODE_REMOTE:-}" != "true" ]; then
  exit 0
fi

QUARTO_VERSION="1.10.19"

# The container's locale is POSIX, under which R writes non-ASCII characters as
# literal <U+2013> text and the render still succeeds. R/site.R switches the
# locale for every page that sources it; this covers the rest, such as a blog
# post with its own R chunks. CLAUDE_ENV_FILE exists only while this hook runs,
# and its lines are applied to the session's later commands.
if [ -n "${CLAUDE_ENV_FILE:-}" ] && locale -a 2>/dev/null | grep -qix 'c\.utf-\?8'; then
  echo 'export LANG=C.UTF-8 LC_CTYPE=C.UTF-8' >> "$CLAUDE_ENV_FILE"
fi

# Site helpers: R/site.R uses jsonlite for _data/*.json and yaml for links.yml
# and likes.yml. knitr executes the chunks in the .qmd files and rmarkdown is
# what Quarto drives it through.
APT_PACKAGES=(
  pandoc
  r-base-core
  r-cran-knitr
  r-cran-rmarkdown
  r-cran-jsonlite
  r-cran-yaml
)

have_r_packages() {
  Rscript -e 'q(status = !all(c("knitr","rmarkdown","jsonlite","yaml") %in% rownames(installed.packages())))' \
    >/dev/null 2>&1
}

# The container image is cached once this finishes, so a warm start should do
# no work at all.
if command -v quarto >/dev/null 2>&1 &&
   command -v pandoc >/dev/null 2>&1 &&
   command -v Rscript >/dev/null 2>&1 &&
   have_r_packages; then
  echo "session-start: toolchain already present ($(quarto --version)); nothing to do"
  exit 0
fi

export DEBIAN_FRONTEND=noninteractive

if ! command -v pandoc >/dev/null 2>&1 || ! command -v Rscript >/dev/null 2>&1 || ! have_r_packages; then
  echo "session-start: installing pandoc and R from the Ubuntu archive"
  apt-get update -qq
  apt-get install -y -qq --no-install-recommends "${APT_PACKAGES[@]}"
fi

if ! command -v quarto >/dev/null 2>&1; then
  echo "session-start: installing Quarto ${QUARTO_VERSION}"
  base="https://github.com/quarto-dev/quarto-cli/releases/download/v${QUARTO_VERSION}"
  deb="quarto-${QUARTO_VERSION}-linux-amd64.deb"
  tmp="$(mktemp -d)"
  trap 'rm -rf "$tmp"' EXIT

  curl -fsSL --retry 3 -o "$tmp/$deb" "$base/$deb"

  # Verify against the checksum file published with this release, so a
  # truncated or substituted download fails loudly instead of installing.
  curl -fsSL --retry 3 -o "$tmp/checksums.txt" "$base/quarto-${QUARTO_VERSION}-checksums.txt"
  ( cd "$tmp" && grep " $deb\$" checksums.txt | sha256sum -c - )

  dpkg -i "$tmp/$deb" >/dev/null
fi

echo "session-start: ready"
quarto --version
