# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI="5"
GCONF_DEBUG="yes"

inherit gnome2
if [[ ${PV} = 9999 ]]; then
	inherit gnome2-live
fi

DESCRIPTION="GNOME framework for accessing online accounts"
HOMEPAGE="https://wiki.gnome.org/GnomeOnlineAccounts"

LICENSE="LGPL-2+"
SLOT="0/1"
IUSE="gnome +introspection kerberos telepathy"
if [[ ${PV} = 9999 ]]; then
	IUSE="${IUSE} doc"
	KEYWORDS=""
else
	KEYWORDS="~alpha ~amd64 ~arm ~ia64 ~ppc ~ppc64 ~sparc ~x86"
fi

# pango used in goaeditablelabel
# libsoup used in goaoauthprovider
# goa kerberos provider is incompatible with app-crypt/heimdal, see
# https://bugzilla.gnome.org/show_bug.cgi?id=692250
# json-glib-0.16 needed for bug #485092
RDEPEND="
	>=dev-libs/glib-2.35:2
	>=app-crypt/libsecret-0.5
	>=dev-libs/json-glib-0.16
	dev-libs/libxml2:2
	>=net-libs/libsoup-2.42:2.4
	net-libs/rest:0.7
	>=net-libs/webkit-gtk-2.1.90:3
	>=x11-libs/gtk+-3.5.1:3
	x11-libs/pango

	introspection? ( >=dev-libs/gobject-introspection-0.6.2 )
	kerberos? (
		app-crypt/gcr:0=
		app-crypt/mit-krb5 )
	telepathy? ( net-libs/telepathy-glib )
"
# goa-daemon can launch gnome-control-center
PDEPEND="gnome? ( >=gnome-base/gnome-control-center-3.2[gnome-online-accounts(+)] )"

DEPEND="${RDEPEND}
	dev-libs/libxslt
	>=dev-util/gtk-doc-am-1.3
	>=dev-util/gdbus-codegen-2.30.0
	>=dev-util/intltool-0.50
	sys-devel/gettext
	virtual/pkgconfig
"

# Due to sub-configure
QA_CONFIGURE_OPTIONS=".*"

if [[ ${PV} = 9999 ]]; then
	DEPEND="${DEPEND}
		doc? ( >=dev-util/gtk-doc-1.3 )"
fi

src_configure() {
	# TODO: Give users a way to set the G/Y!/FB/Twitter/Windows Live secrets
	gnome2_src_configure \
		--disable-static \
		--enable-documentation \
		--enable-exchange \
		--enable-facebook \
		--enable-flickr \
		--enable-twitter \
		--enable-yahoo \
		--enable-imap-smtp \
		--enable-owncloud \
		$(use_enable kerberos) \
		$(use_enable telepathy)
	# gudev & cheese from sub-configure is overriden
	# by top level configure, and disabled so leave it like that
}
