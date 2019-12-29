# Copyright 2019+ Maxim "Sheridan" Gorlov
# Distributed under the terms of the GNU General Public License v3

EAPI=6
EGIT_REPO_URI="https://github.com/nshttpd/mikrotik-exporter"
inherit git-r3

DESCRIPTION="Exporting MikroTik metrics"
HOMEPAGE="https://github.com/nshttpd/mikrotik-exporter"
LICENSE="GPL-3"
SLOT="0"
DEPEND="dev-lang/go"
KEYWORDS="~amd64 ~ppc ~x86 ~arm"

src_unpack() {
        git-r3_src_unpack
        cd "${S}"
        go get -v .
}

src_compile() {
        make build
}

src_install() {
        newbin mikrotik-exporter mikrotik_exporter
        dodoc "README.md"
}
