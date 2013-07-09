# Copyright 1999-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/sys-power/phc-k8/phc-k8-0.4.4.ebuild,v 1.1 2011/11/18 08:45:18 xmw Exp $
EAPI=5

# Enforce Bash strictness.
set -e

inherit linux-info linux-mod

DESCRIPTION="Processor Hardware Control for AMD K8 CPUs"
HOMEPAGE="http://www.linux-phc.org"
SRC_URI="http://www.linux-phc.org/forum/download/file.php?id=143 -> ${P}.tar.gz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE=""

S="${WORKDIR}/${PN}_v${PV/_beta/b}"

# Basename of the module to be built.
MODULE_NAMES="phc-k8()"

# Makefile target to be executed, cleanly building such module.
BUILD_TARGETS="all"

pkg_setup() {
	linux-mod_pkg_setup

	# If the currently installed kernel (i.e., the target of symbolic link
	# "/usr/src/linux") has *NOT* been properly configured for "phc-k8", print a
	# nonfatal warning.
	if linux_config_exists; then
		if ! linux_chkconfig_module X86_POWERNOW_K8; then
			ewarn 'Kernel configuration option "X86_POWERNOW_K8" must be compiled as a'
			ewarn 'module rather than into the kernel itself.'
		fi
	else
		ewarn 'Your kernel is unconfigured (i.e., "'${KV_OUT_DIR}'/.config" not found).'
		ewarn 'Kernel configuration option "X86_POWERNOW_K8" must be compiled as a'
		ewarn 'module rather than into the kernel itself.'
	fi

	# The makefile assumes kernel sources to reside under
	# "/lib/modules/`uname -r`/build/", by default. Since such directory does
	# not necessarily correspond to that of the currently installed kernel,
	# replace such default with ${KERNEL_DIR}, the absolute path of such kernel
	# as set by eclass "linux-info". (Whew!)
	BUILD_PARAMS="KERNELSRC=\"${KERNEL_DIR}\" -j1"

	# If such kernel is a 2.x rather than 3.x kernel, such kernel provides no
	# files matching mperf.{c,h,ko,o}. In such case, instruct the makefile to
	# provide such files by setting ${BUILD_MPERF} to a non-empty string.
	if kernel_is le 2 6 32; then
		BUILD_PARAMS+=' BUILD_MPERF=1'
	fi
}

src_install() {
	linux-mod_src_install
	dodoc Changelog README
	newconfd "${FILESDIR}/conf" "${PN}"
	newinitd "${FILESDIR}/init" "${PN}"
}