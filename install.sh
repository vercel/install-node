#!/bin/sh
set -e

BOLD="\033[1m"
UNDERLINE="\033[4m"
RED="\033[31m"
BLUE="\033[34m"
CYAN="\033[36m"
GREEN="\033[32m"
MAGENTA="\033[35m"
NO_COLOR="\033[0m"

info() {
  printf "${CYAN}*${NO_COLOR} $@\n"
}

error() {
  printf "${RED}x${NO_COLOR} $@\n" >&2
}

complete() {
  printf "${GREEN}!${NO_COLOR} $@\n"
}

fetch() {
  if hash curl 2>/dev/null; then
    curl --silent "$1"
  else
    if hash wget 2>/dev/null; then
      wget -O- -q "$1"
    else
      error "No HTTP download program (curl, wget) found…"
      exit 1
    fi
  fi
}

resolve_node_version() {
  local tag="$1"
  if [ "${tag}" = "latest" ]; then
    tag=
  fi
  fetch "https://resolve-node.now.sh/$tag"
}

# Currently known to support:
#   - darwin
#   - linux
#   - linux_musl
detect_platform() {
  local platform="$(uname -s | tr '[:upper:]' '[:lower:]')"

  # check for MUSL
  if [ "$platform" = "linux" ]; then
    if ldd /bin/sh | grep -i musl >/dev/null; then
      platform="linux_musl"
    fi
  fi

  echo "${platform}"
}

# Currently known to support:
#   - x64
detect_arch() {
  # TODO: add arm, ppc, etc. support
  local arch="$(uname -m | tr '[:upper:]' '[:lower:]')"

  if [ "${arch}" = "x86_64" ]; then
    arch=x64
  fi

  echo "${arch}"
}

confirm() {
  printf "${MAGENTA}?${NO_COLOR} $@ ${BOLD}[yN]${NO_COLOR} "
  read yn
  if [ "$yn" != "y" ] && [ "$yn" != "yes" ]; then
    error "Aborting (please answer \"yes\" to continue)…"
    exit 1
  fi
}

# defaults
printf "   ${UNDERLINE}Configuration${NO_COLOR}\n"
if [ -z "${VERSION}" ]; then
  VERSION=latest
fi
info "${BOLD}Version${NO_COLOR}:  ${VERSION}"

if [ -z "${PREFIX}" ]; then
  PREFIX=/usr/local
fi
info "${BOLD}Prefix${NO_COLOR}:   ${PREFIX}"

if [ -z "${PLATFORM}" ]; then
  PLATFORM="$(detect_platform)"
fi
info "${BOLD}Platform${NO_COLOR}: ${PLATFORM}"

if [ -z "${ARCH}" ]; then
  ARCH="$(detect_arch)"
fi
info "${BOLD}Arch${NO_COLOR}:     ${ARCH}"

if [ -z "${BASE_URL}" ]; then
  BASE_URL="https://nodejs.org/dist"
fi

# non-empty VERBOSE enabled verbose untarring
if [ ! -z "${VERBOSE}" ]; then
  VERBOSE=v
  info "${BOLD}Verbose${NO_COLOR}: yes"
fi

echo

# Alpine Linux binaries get downloaded from `nodejs-binaries.zeit.sh`
# TODO: we can download Windows v5.12.0 .zip file from here too
if [ "$PLATFORM" = "linux_musl" ]; then
  BASE_URL="https://nodejs-binaries.zeit.sh"
fi

# Resolve the requested version tag into an existing Node.js version
RESOLVED="$(resolve_node_version "$VERSION")"
if [ -z "${RESOLVED}" ]; then
  error "Could not resolve Node.js version \"${VERSION}\""
  exit 1
fi
if [ "$VERSION" != "$RESOLVED" ]; then
  info "Resolved \"$VERSION\" to \"$RESOLVED\""
fi

URL="${BASE_URL}/${RESOLVED}/node-${RESOLVED}-${PLATFORM}-${ARCH}.tar.gz"
info "Tarball URL: ${UNDERLINE}${BLUE}${URL}${NO_COLOR}"

confirm "Install Node.js ${GREEN}${RESOLVED}${NO_COLOR} to ${GREEN}${PREFIX}${NO_COLOR}?"

fetch "${URL}" \
  | tar xzf${VERBOSE} - \
    --exclude CHANGELOG.md \
    --exclude LICENSE \
    --exclude README.md \
    --strip-components 1 \
    -C "${PREFIX}"

complete "Done"
