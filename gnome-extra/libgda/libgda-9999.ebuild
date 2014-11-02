# Copyright 1999-2014 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI="5"
GNOME2_LA_PUNT="yes"
GCONF_DEBUG="yes"
PYTHON_COMPAT=( python2_7 )
VALA_MIN_API_VERSION="0.18"
VALA_USE_DEPEND="vapigen"

inherit autotools db-use eutils flag-o-matic gnome2 java-pkg-opt-2 python-single-r1 vala
if [[ ${PV} = 9999 ]]; then
	inherit gnome2-live
fi

DESCRIPTION="GNOME database access library"
HOMEPAGE="http://www.gnome-db.org/"
LICENSE="GPL-2+ LGPL-2+"

IUSE="berkdb bindist canvas firebird gtk graphviz http +introspection json ldap libsecret mdb mysql oci8 postgres reports sourceview ssl vala"
REQUIRED_USE="
	reports? ( ${PYTHON_REQUIRED_USE} )
	canvas? ( gtk )
	firebird? ( !bindist )
	graphviz? ( gtk )
	sourceview? ( gtk )
	vala? ( introspection )
"
# firebird license is not GPL compatible

SLOT="5/4" # subslot = libgda-5.0 soname version
if [[ ${PV} = 9999 ]]; then
	IUSE="${IUSE} doc"
	KEYWORDS=""
else
	KEYWORDS="~alpha ~amd64 ~ia64 ~ppc ~ppc64 ~sparc ~x86 ~x86-fbsd"
fi

RDEPEND="
	app-text/iso-codes
	>=dev-libs/glib-2.32:2
	>=dev-libs/libxml2-2
	dev-libs/libxslt
	sys-libs/readline:=
	sys-libs/ncurses:=
	berkdb?   ( sys-libs/db )
	!bindist? ( firebird? ( dev-db/firebird ) )
	gtk? (
		>=x11-libs/gtk+-3.0.0:3
		canvas? ( x11-libs/goocanvas:2.0= )
		sourceview? ( x11-libs/gtksourceview:3.0 )
		graphviz? ( media-gfx/graphviz )
	)
	http? ( >=net-libs/libsoup-2.24:2.4 )
	introspection? ( >=dev-libs/gobject-introspection-1.30 )
	json?     ( dev-libs/json-glib )
	ldap?     ( net-nds/openldap:= )
	libsecret? ( app-crypt/libsecret )
	mdb?      ( >app-office/mdbtools-0.5:= )
	mysql?    ( virtual/mysql:= )
	postgres? ( dev-db/postgresql-base:= )
	reports? (
		${PYTHON_DEPS}
		dev-java/fop
		dev-python/reportlab[${PYTHON_USEDEP}] )
	ssl?      ( dev-libs/openssl:= )
	>=dev-db/sqlite-3.6.22:3=
"
DEPEND="${RDEPEND}
	>=app-text/gnome-doc-utils-0.9
	dev-util/gtk-doc-am
	>=dev-util/intltool-0.40.6
	virtual/pkgconfig
	java? ( virtual/jdk:1.6 )
	vala? ( $(vala_depend) )
"
if [[ ${PV} = 9999 ]]; then
	DEPEND="${DEPEND}
		app-text/yelp-tools
		doc? ( >=dev-util/gtk-doc-1.14 )
		vala? ( $(vala_depend) )"
fi

pkg_setup() {
	java-pkg-opt-2_pkg_setup
	use reports && python-single-r1_pkg_setup
}

src_prepare() {
	use reports ||
		sed -e '/SUBDIRS =/ s/trml2html//' \
			-e '/SUBDIRS =/ s/trml2pdf//' \
			-i libgda-report/RML/Makefile.{am,in} || die

	# Prevent file collisions with libgda:4
	epatch "${FILESDIR}/${PN}-4.99.1-gda-browser-doc-collision.patch"
	epatch "${FILESDIR}/${PN}-4.99.1-control-center-icon-collision.patch"
	# Move files with mv (since epatch can't handle rename diffs) and
	# update pre-generated gtk-doc files (for non-git versions of libgda)
	local f
	for f in tools/browser/doc/gda-browser* ; do
		mv ${f} ${f/gda-browser/gda-browser-5.0} || die "mv ${f} failed"
	done
	if [[ ${PV} != 9999 ]] ; then
		for f in tools/browser/doc/html/gda-browser.devhelp* ; do
			sed -e 's:name="gda-browser":name="gda-browser-5.0":' \
				-i ${f} || die "sed ${f} failed"
			mv ${f} ${f/gda-browser/gda-browser-5.0} || die "mv ${f} failed"
		done
	fi
	for f in control-center/data/*_gda-control-center.png ; do
		mv ${f} ${f/_gda-control-center.png/_gda-control-center-5.0.png} ||
			die "mv ${f} failed"
	done

	[[ ${PV} = 9999 ]] || eautoreconf
	gnome2_src_prepare
	java-pkg-opt-2_src_prepare
	use vala && vala_src_prepare
}

src_configure() {
	use berkdb && append-cppflags "-I$(db_includedir)"

	gnome2_src_configure \
		--with-help \
		--disable-static \
		--enable-system-sqlite \
		$(use_with berkdb bdb /usr) \
		$(use_with canvas goocanvas) \
		$(use_with firebird firebird /usr) \
		$(use_with graphviz) \
		$(use_with gtk ui) \
		$(use_with http libsoup) \
		$(use_enable introspection) \
		"$(use_with java java $JAVA_HOME)" \
		$(use_enable json) \
		$(use_with ldap) \
		$(use_with libsecret) \
		$(use_with mdb mdb /usr) \
		$(use_with mysql mysql /usr) \
		$(use_with oci8 oracle) \
		$(use_with postgres postgres /usr) \
		$(use_enable ssl crypto) \
		$(use_with sourceview gtksourceview) \
		--disable-default-binary \
		--disable-vala
	# vala bindings fail to build
}

pkg_preinst() {
	gnome2_pkg_preinst
	java-pkg-opt-2_pkg_preinst
}

src_install() {
	gnome2_src_install
	if use reports; then
		for t in trml2{html,pdf}; do
			python_scriptinto /usr/share/libgda-5.0/gda_${t}
			python_doscript libgda-report/RML/${t}/${t}.py
		done
	fi
}
