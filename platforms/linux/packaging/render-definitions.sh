#!/usr/bin/env bash
# 按一个已发布的 linux-vVERSION 渲染各发行版的包定义，供维护者拿去发布到各自的仓库（步骤见 platforms/linux/README.md「包管理器」）。本脚本只产出文件，不向任何外部仓库推送。
#
# 用法：platforms/linux/packaging/render-definitions.sh VERSION OUTDIR
#   在 linux-vVERSION 那个提交的检出里运行：RPM 规格、debian/、PKGBUILD 与 ebuild 模板都取自当前检出，Gentoo 的 CRATES 取自当前检出的 Cargo.lock。release-linux.yml 的 package-definitions job 在发布之后以同一提交调用它。
#   需要 docker 与网络。每一步在各自发行版的官方容器里跑，OUTDIR 下得到：
#     rpm/      渲染好的 lingyao.spec、lingyao-rpmlintrc 与 lingyao-VERSION-1.src.rpm（COPR 直接构建它；OBS 用 spec 加两个 tarball）
#     debian/   lingyao_VERSION-1.dsc 与 lingyao_VERSION-1.debian.tar.xz（orig tarball 就是发布页上的 lingyao-VERSION.tar.xz 与 lingyao-VERSION-vendor.tar.xz 改名）
#     arch/     lingyao/ 与 lingyao-bin/，各含 PKGBUILD、.SRCINFO 与 lingyao.install，原样复制到 AUR 仓库
#     gentoo/   一个完整的 overlay：版本 ebuild、live ebuild、metadata.xml、Manifest、metadata/ 与 profiles/
#
# 环境变量：
#   LINGYAO_DEFINITIONS   要渲染的部分，逗号分隔，默认 rpm,debian,arch,gentoo。
#   LINGYAO_RELEASE_DIR   本地目录，里面放 SHA256SUMS 与发布资产；给了就不从发布页下载。用于在发布前验证，或复用刚构建出的文件。Gentoo 生成 Manifest 时，这里有的 lingyao-VERSION-frontend.tar.xz 直接当作 distfile，不再下载。
set -euo pipefail

if [ $# -ne 2 ]; then
  echo "usage: $0 VERSION OUTDIR" >&2
  exit 2
fi
version=$1
[[ "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || {
  echo "version must be MAJOR.MINOR.PATCH: $version" >&2
  exit 2
}
here=$(cd "$(dirname "$0")" && pwd)
repo_root=$(cd "$here/../../.." && pwd)
mkdir -p "$2"
out=$(cd "$2" && pwd)
parts=",${LINGYAO_DEFINITIONS:-rpm,debian,arch,gentoo},"
release_url="https://github.com/Lcy040109/msime/releases/download/linux-v$version"
want() { [[ "$parts" == *",$1,"* ]]; }
# 容器以 root 往 OUTDIR 写文件；结束时（包括失败时）交回给调用者，免得 OUTDIR 删不掉。
reclaim() { docker run --rm -v "$out":/out debian:sid chown -R "$(id -u):$(id -g)" /out 2>/dev/null || true; }
trap reclaim EXIT

# 发布资产：本地目录优先，否则下载到 OUTDIR/.release。凡是 SHA256SUMS 列出的文件都对着它核对，校验值只认发布时算的那一份。
release=${LINGYAO_RELEASE_DIR:-$out/.release}
mkdir -p "$release"
release=$(cd "$release" && pwd)
asset() {
  if [ ! -f "$release/$1" ]; then
    [ -z "${LINGYAO_RELEASE_DIR:-}" ] || { echo "$1 is not in LINGYAO_RELEASE_DIR ($release)" >&2; exit 1; }
    curl -fsSL --retry 3 -o "$release/$1.part" "$release_url/$1"
    mv "$release/$1.part" "$release/$1"
  fi
  if [ "$1" != SHA256SUMS ] && grep -qE "^[0-9a-f]{64} [ *]$1\$" "$release/SHA256SUMS"; then
    (cd "$release" && grep -E "^[0-9a-f]{64} [ *]$1\$" SHA256SUMS | sha256sum -c --quiet -)
  fi
}
asset SHA256SUMS

if want rpm || want debian; then
  asset "lingyao-$version.tar.xz"
  asset "lingyao-$version-vendor.tar.xz"
fi

if want rpm; then
  echo "== rpm"
  rm -rf "$out/rpm"
  mkdir -p "$out/rpm"
  python3 "$here/render-sources.py" --version "$version" --spec-out "$out/rpm/lingyao.spec"
  cp "$here/rpm/lingyao-rpmlintrc" "$out/rpm/"
  # 只打源码包，不构建：rpmbuild -bs 只要规格文件与各个 Source 在 _sourcedir 里，tarball 用符号链接，不复制一份。dist 置空，SRPM 不带 .fc44 这类标记，COPR 按各 chroot 重新构建。
  docker run --rm -v "$out/rpm":/d -v "$release":/release:ro fedora:44 bash -euo pipefail -c '
    dnf -y -q install rpm-build >/dev/null
    mkdir /sources
    ln -s /release/lingyao-'"$version"'.tar.xz /release/lingyao-'"$version"'-vendor.tar.xz /sources/
    cp /d/lingyao-rpmlintrc /sources/
    rpmbuild -bs --define "_sourcedir /sources" --define "_srcrpmdir /d" --define "dist %{nil}" /d/lingyao.spec
    test -f /d/lingyao-'"$version"'-1.src.rpm
  '
fi

if want debian; then
  echo "== debian"
  rm -rf "$out/debian"
  mkdir -p "$out/debian"
  python3 "$here/render-sources.py" --version "$version" --changelog-out "$out/debian/changelog"
  docker run --rm -v "$out/debian":/d -v "$release":/release:ro debian:sid bash -euo pipefail -c '
    v='"$version"'
    export DEBIAN_FRONTEND=noninteractive
    apt-get update -qq && apt-get install -y -qq --no-install-recommends dpkg-dev xz-utils >/dev/null
    mkdir /work && cd /work
    cp /release/lingyao-$v.tar.xz lingyao_$v.orig.tar.xz
    cp /release/lingyao-$v-vendor.tar.xz lingyao_$v.orig-vendor.tar.xz
    tar xf lingyao_$v.orig.tar.xz
    mkdir lingyao-$v/vendor
    tar xf lingyao_$v.orig-vendor.tar.xz -C lingyao-$v/vendor --strip-components=1
    cp -a lingyao-$v/platforms/linux/packaging/debian lingyao-$v/debian
    mv /d/changelog lingyao-$v/debian/changelog
    dpkg-source -b lingyao-$v
    cp lingyao_$v-1.dsc lingyao_$v-1.debian.tar.xz /d/
  '
fi

if want arch; then
  echo "== arch"
  rm -rf "$out/arch"
  mkdir -p "$out/arch"
  # makepkg --printsrcinfo 拒绝以 root 运行，render.py 原地改写 PKGBUILD，所以把 arch 目录复制给一个普通用户再渲染。archlinux 官方镜像只有 x86_64。
  docker run --rm --platform linux/amd64 -v "$here/arch":/arch:ro -v "$release":/release:ro -v "$out/arch":/out archlinux:latest bash -euo pipefail -c '
    # pacman 7 的下载沙箱要 seccomp 与 Landlock，跨架构模拟的容器里两者都用不了。
    sed -i "/^\[options\]/a DisableSandbox" /etc/pacman.conf
    pacman -Syu --noconfirm --needed base-devel python >/dev/null
    useradd -m builder
    cp -r /arch /home/builder/arch
    chown -R builder: /home/builder/arch
    su builder -c "python3 /home/builder/arch/render.py '"$version"' --sha256sums /release/SHA256SUMS"
    for pkg in lingyao lingyao-bin; do
      mkdir -p /out/$pkg
      cp /home/builder/arch/$pkg/PKGBUILD /home/builder/arch/$pkg/.SRCINFO /home/builder/arch/$pkg/lingyao.install /out/$pkg/
    done
  '
fi

if want gentoo; then
  echo "== gentoo"
  rm -rf "$out/gentoo"
  mkdir -p "$out/gentoo" "$out/.gentoo-distfiles"
  # 发布前验证时前端归档还不在发布页上，从 LINGYAO_RELEASE_DIR 预先放进 distfiles，Portage 生成 Manifest 时就不再下载它。
  if [ -f "$release/lingyao-$version-frontend.tar.xz" ]; then
    cp "$release/lingyao-$version-frontend.tar.xz" "$out/.gentoo-distfiles/"
  fi
  image="lingyao-gentoo-tools:$(printf %s "$repo_root" | shasum | cut -c1-12)"
  docker pull -q gentoo/stage3:latest >/dev/null
  docker pull -q gentoo/portage:latest >/dev/null
  docker build -q -t "$image" - >/dev/null < "$here/gentoo/tools.Dockerfile"
  docker run --rm --init -v "$repo_root":/src:ro -v "$out/gentoo":/var/db/repos/lingyao -v "$out/.gentoo-distfiles":/var/cache/distfiles \
    "$image" bash -euo pipefail -c '
      v='"$version"'
      overlay=/var/db/repos/lingyao
      cp -r /src/platforms/linux/packaging/gentoo/metadata /src/platforms/linux/packaging/gentoo/profiles "$overlay/"
      # pycargoebuild 读 Cargo.lock 时会在检出里写文件，在副本里渲染。
      mkdir /tmp/source
      tar -C /src --exclude=./target --exclude=./node_modules --exclude=./.git -cf - . | tar -C /tmp/source -xf -
      python3 /tmp/source/platforms/linux/packaging/gentoo/render.py "$v" --out "$overlay"
      cp /tmp/source/platforms/linux/packaging/gentoo/app-i18n/lingyao/lingyao-9999.ebuild "$overlay/app-i18n/lingyao/"
      mkdir -p /etc/portage/repos.conf
      printf "[DEFAULT]\nmain-repo = gentoo\n\n[gentoo]\nlocation = /var/db/repos/gentoo\n" > /etc/portage/repos.conf/gentoo.conf
      printf "[lingyao]\nlocation = %s\n" "$overlay" > /etc/portage/repos.conf/lingyao.conf
      # Manifest 记下每个 distfile 的校验值：Portage 下载 SRC_URI 里还没有的文件，已在 distfiles 里的直接计算。下载以 portage 用户进行（userfetch），挂进来的目录要让它可写。这些文件不在 Gentoo 的镜像上，清空 GENTOO_MIRRORS 直接取上游地址，免得每个文件先在镜像上 404 一次。
      chown portage:portage /var/cache/distfiles
      GENTOO_MIRRORS="" ebuild "$overlay/app-i18n/lingyao/lingyao-$v.ebuild" manifest
      cd "$overlay"
      pkgcheck scan --exit error app-i18n/lingyao
    '
  reclaim
  rm -rf "$out/.gentoo-distfiles"
  docker rmi -f "$image" >/dev/null
fi

[ -n "${LINGYAO_RELEASE_DIR:-}" ] || rm -rf "$out/.release"
find "$out" -maxdepth 4 -type f ! -path "*/.release/*" | sort
echo "package definitions for $version are in $out"
