#!/bin/bash
# libinput declares a lua54 dependency that Arch satisfies with plain `lua`.
# Without a package providing the name, the desktop transaction cannot resolve.

if pacman -Q lua54 &>/dev/null; then
    log_info "lua54 compatibility package already present"
    return 0 2>/dev/null || exit 0
fi

log_info "Creating the lua54 compatibility package required by libinput..."
build_dir=$(mktemp -d -t lua54-build.XXXXXX)
cat > "$build_dir/PKGBUILD" <<'PKGEOF'
pkgname=lua54
pkgver=5.4.0
pkgrel=1
pkgdesc="Lua 5.4 compatibility shim providing lua54 virtual package"
arch=('any')
provides=('lua54')
depends=('lua')
build() { true; }
package() { true; }
PKGEOF
(
    cd "$build_dir"
    makepkg -si --noconfirm
)
rm -rf "$build_dir"
