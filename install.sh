#!/bin/sh
# `install-node.now.sh` is a simple one-liner shell script to
# install official Node.js binaries from `nodejs.org/dist` or other
# blessed sources (i.e. Alpine Linux builds are not on nodejs.org)
#
# For `latest` Node.js version:
#
#   $ curl -sL install-node.now.sh | sh
#
# Install a specific version (ex: v8.9.0):
#
#   $ curl -sL install-node.now.sh/8.9.0 | sh
#
# Semver also works (ex: v4.x.x):
#
#   $ curl -sL install-node.now.sh/4 | sh
#
# Options may be passed to the shell script with `-s --`:
#
#   $ curl -sL install-node.now.sh | sh -s -- --prefix=$HOME --version=8 --verbose
#   $ curl -sL install-node.now.sh | sh -s -- -P $HOME -v 8 -V
#
# Patches welcome!
# https://github.com/zeit/install-node
# Nathan Rajlich <nate@zeit.co>

set -e

BOLD="$(tput bold 2>/dev/null || echo '')"
UNDERLINE="$(tput smul 2>/dev/null || echo '')"
RED="$(tput setaf 1 2>/dev/null || echo '')"
GREEN="$(tput setaf 2 2>/dev/null || echo '')"
BLUE="$(tput setaf 4 2>/dev/null || echo '')"
MAGENTA="$(tput setaf 5 2>/dev/null || echo '')"
CYAN="$(tput setaf 6 2>/dev/null || echo '')"
NO_COLOR="$(tput sgr0 2>/dev/null || echo '')"

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
  local command
  if hash curl 2>/dev/null; then
    set +e
    command="curl --silent --fail $1"
    curl --silent --fail "$1"
    rc=$?
    set -e
  else
    if hash wget 2>/dev/null; then
      set +e
      command="wget -O- -q $1"
      wget -O- -q "$1"
      rc=$?
      set -e
    else
      error "No HTTP download program (curl, wget) found…"
      exit 1
    fi
  fi

  if [ $rc -ne 0 ]; then
    error "Command failed (exit code $rc): ${BLUE}${command}${NO_COLOR}"
    exit $rc
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
#   - linux_musl (Alpine)
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
#   - x64 (x86_64)
#   - armv7l (Raspbian on Pi 3)
detect_arch() {
  local arch="$(uname -m | tr '[:upper:]' '[:lower:]')"

  if [ "${arch}" = "x86_64" ]; then
    arch=x64
  fi

  echo "${arch}"
}

confirm() {
  printf "${MAGENTA}?${NO_COLOR} $@ ${BOLD}[yN]${NO_COLOR} "
  set +e
  read yn < /dev/tty 2>/dev/null
  rc=$?
  set -e
  if [ $rc -ne 0 ]; then
    error "Error reading from prompt (please re-run with the \`--yes\` option)"
    exit 1
  fi
  if [ "$yn" != "y" ] && [ "$yn" != "yes" ]; then
    error "Aborting (please answer \"yes\" to continue)"
    exit 1
  fi
}

# defaults
if [ -z "${VERSION}" ]; then
  VERSION=latest
fi

if [ -z "${PREFIX}" ]; then
  PREFIX=/usr/local
fi

if [ -z "${PLATFORM}" ]; then
  PLATFORM="$(detect_platform)"
fi

if [ -z "${ARCH}" ]; then
  ARCH="$(detect_arch)"
fi

if [ -z "${BASE_URL}" ]; then
  BASE_URL="https://nodejs.org/dist"
fi

# parse argv variables
while [ "$#" -gt 0 ]; do
  case "$1" in
    -v) VERSION="$2"; shift 2;;
    -p) PLATFORM="$2"; shift 2;;
    -P) PREFIX="$2"; shift 2;;
    -a) ARCH="$2"; shift 2;;
    -b) BASE_URL="$2"; shift 2;;

    --version=*) VERSION="${1#*=}"; shift 1;;
    --verbose=*) VERBOSE="${1#*=}"; shift 1;;
    --platform=*) PLATFORM="${1#*=}"; shift 1;;
    --prefix=*) PREFIX="${1#*=}"; shift 1;;
    --base-url=*) BASE_URL="${1#*=}"; shift 1;;
    --version|--prefix|--platform|--arch|--base-url) echo "$1 requires an argument" >&2; exit 1;;

    --verbose|-V) VERBOSE=1; shift 1;;
    --force|--yes|-f|-y) FORCE=1; shift 1;;

    *) errror "Unknown option: $1" >&2; exit 1;;
  esac
done

printf "   ${UNDERLINE}Configuration${NO_COLOR}\n"
info "${BOLD}Version${NO_COLOR}:  ${VERSION}"
info "${BOLD}Prefix${NO_COLOR}:   ${PREFIX}"
info "${BOLD}Platform${NO_COLOR}: ${PLATFORM}"
info "${BOLD}Arch${NO_COLOR}:     ${ARCH}"

# non-empty VERBOSE enables verbose untarring
if [ ! -z "${VERBOSE}" ]; then
  VERBOSE=v
  info "${BOLD}Verbose${NO_COLOR}: yes"
fi

echo

# Resolve the requested version tag into an existing Node.js version
RESOLVED="$(resolve_node_version "$VERSION")"
if [ -z "${RESOLVED}" ]; then
  error "Could not resolve Node.js version ${MAGENTA}${VERSION}${NO_COLOR}"
  exit 1
fi
if [ "$VERSION" != "$RESOLVED" ]; then
  info "Resolved ${MAGENTA}${VERSION}${NO_COLOR} to ${BOLD}${MAGENTA}${RESOLVED}${NO_COLOR}"
fi

# Alpine Linux binaries get downloaded from `nodejs-binaries.zeit.sh`
if [ "$PLATFORM" = "linux_musl" -o \( "$PLATFORM" = "win" -a "$RESOLVED" = "v5.12.0" \) ]; then
  BASE_URL="https://nodejs-binaries.zeit.sh"
fi

URL="${BASE_URL}/${RESOLVED}/node-${RESOLVED}-${PLATFORM}-${ARCH}.tar.gz"
info "Tarball URL: ${UNDERLINE}${BLUE}${URL}${NO_COLOR}"

if [ -z "${FORCE}" ]; then
  confirm "Install Node.js ${GREEN}${RESOLVED}${NO_COLOR} to ${BOLD}${GREEN}${PREFIX}${NO_COLOR}?"
fi

info "Installing Node.js, please wait…"

fetch "${URL}" \
  | tar xzf${VERBOSE} - \
    --exclude CHANGELOG.md \
    --exclude LICENSE \
    --exclude README.md \
    --strip-components 1 \
    -C "${PREFIX}"

complete "Done"
