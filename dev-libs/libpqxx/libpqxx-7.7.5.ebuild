# Copyright 1999-2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

PYTHON_COMPAT=( python3_{9..11} )
inherit python-any-r1

KEYWORDS="~alpha amd64 ~arm64 ~hppa ~ia64 ppc ppc64 sparc x86"

DESCRIPTION="Standard front-end for writing C++ programs that use PostgreSQL"
SRC_URI="https://github.com/jtv/${PN}/archive/${PV}.tar.gz -> ${P}.tar.gz"

HOMEPAGE="https://pqxx.org/development/libpqxx/"
LICENSE="BSD"
# SONAME version is equal to major.minor
SLOT="0/$(ver_cut 1-2)"
IUSE="doc static-libs"

RDEPEND="dev-db/postgresql:="
DEPEND="${RDEPEND}"
BDEPEND="${PYTHON_DEPS}
	doc? (
		app-doc/doxygen[dot]
		app-text/xmlto
	)
"

DOCS=( AUTHORS NEWS README.md )

src_configure() {
	econf \
		--enable-shared \
		$(use_enable doc documentation) \
		$(use_enable static-libs static)
}

src_test() {
	einfo "The tests need a running PostgreSQL server and an existing database."
	einfo "Test requires PGDATABASE and PGUSER to be set at a minimum. Optionally,"
	einfo "set PGPORT and PGHOST. Define them at the command line or in:"
	einfo "    ${BROOT}/etc/libpqxx_test_env"

	if [[ -z $PGDATABASE || -z $PGUSER ]] ; then
		if [[ -f ${BROOT}/etc/libpqxx_test_env ]] ; then
			source "${BROOT}/etc/libpqxx_test_env"
			[[ -n $PGDATABASE ]] && export PGDATABASE
			[[ -n $PGHOST ]] && export PGHOST
			[[ -n $PGPORT ]] && export PGPORT
			[[ -n $PGUSER ]] && export PGUSER
		fi
	fi

	if [[ -n $PGDATABASE && -n $PGUSER ]] ; then
		local server_version
		server_version=$(psql -Aqtc 'SELECT version();' 2> /dev/null)
		if [[ $? = 0 ]] ; then
			cd "${S}/test" || die
			emake check
		else
			eerror "Is the server running?"
			eerror "Verify role and database exist, and are permitted in pg_hba.conf for:"
			eerror "    Role: ${PGUSER}"
			eerror "    Database: ${PGDATABASE}"
			die "Couldn't connect to server."
		fi
	else
		eerror "PGDATABASE and PGUSER must be set to perform tests."
		eerror "Skipping tests."
	fi
}

src_install () {
	use doc && HTML_DOCS=( doc/html/. )
	default

	if ! use static-libs; then
		find "${D}" -name '*.la' -delete || die
	fi
}
