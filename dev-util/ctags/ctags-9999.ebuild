# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $
EAPI=5

# Enforce Bash strictness.
set -e

# While the official Subversion repository for Exuberant Ctags at
# http://sourceforge.net/p/ctags/code/HEAD/tree has yet to be updated since late
# 2012, fishman's unofficial git repository remains actively maintained.
EGIT_REPO_URI="https://github.com/fishman/ctags"
EGIT_BRANCH="deploy"

inherit autotools git-r3

DESCRIPTION="Exuberant Ctags creates tags files for code browsing in editors"
HOMEPAGE="http://ctags.sourceforge.net"

#FIXME: This should really just be submitted to the above git repository with a
#github pull request.
SRC_URI="ada? ( mirror://sourceforge/gnuada/ctags-ada-mode-4.3.11.tar.bz2 )"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~alpha ~amd64 ~arm ~hppa ~ia64 ~m68k ~mips ~ppc ~ppc64 ~s390 ~sh ~sparc ~x86 ~amd64-fbsd ~sparc-fbsd ~x86-fbsd"
IUSE="ada"

DEPEND="app-admin/eselect-ctags"
RDEPEND="${DEPEND}"

src_unpack() {
	git-r3_src_unpack
	unpack "${A}"
}

src_prepare() {
	epatch "${FILESDIR}/${PN}-5.6-ebuilds.patch"
	# Upstream fix for python variables starting with def
	epatch "${FILESDIR}/${PN}-5.8-python-vars-starting-with-def.patch"

	# Bug #273697
	epatch "${FILESDIR}/${PN}-5.8-f95-pointers.patch"

	# enabling Ada support
	if use ada; then
		cp "${WORKDIR}/${PN}-ada-mode-4.3.11/ada.c" "${S}"
		epatch "${FILESDIR}/${PN}-5.8-ada.patch"
	fi

	eautoreconf
}

src_configure() {
	econf \
		--with-posix-regex \
		--without-readlib \
		--disable-etags \
		--enable-tmpdir=/tmp
}

src_install() {
	emake prefix="${D}"/usr mandir="${D}"/usr/share/man install

	# namepace collision with X/Emacs-provided /usr/bin/ctags -- we
	# rename ctags to exuberant-ctags (Mandrake does this also).
	mv "${D}"/usr/bin/{ctags,exuberant-ctags}
	mv "${D}"/usr/share/man/man1/{ctags,exuberant-ctags}.1

	dodoc FAQ MAINTAINERS NEWS README
	dohtml -r EXTENDING.html index.html website/
}

pkg_postinst() {
	eselect ctags update

	# If this package is being installed for the first time (rather than
	# upgraded), print post-installation messages.
	if ! has_version "${CATEGORY}/${PN}"; then
		elog "You can set the version to be started by /usr/bin/ctags through"
		elog "the ctags eselect module. \"man ctags.eselect\" for details."
	fi
}

pkg_postrm() {
	eselect ctags update
}
