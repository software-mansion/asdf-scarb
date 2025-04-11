#!/usr/bin/env bash

set -euo pipefail

GH_REPO="https://github.com/software-mansion/scarb"
GH_NIGHTLIES_REPO="https://github.com/software-mansion/scarb-nightlies"
TOOL_NAME="scarb"
TOOL_TEST="scarb --version"

fail() {
	echo -e "asdf-$TOOL_NAME: $*"
	exit 1
}

curl_opts=(-fsSL)

# NOTE: You might want to remove this if scarb is not hosted on GitHub releases.
if [ -n "${GITHUB_API_TOKEN:-}" ]; then
	curl_opts=("${curl_opts[@]}" -H "Authorization: token $GITHUB_API_TOKEN")
fi

sort_versions() {
	sed 'h; s/[+-]/./g; s/.p\([[:digit:]]\)/.z\1/; s/$/.z/; G; s/\n/ /' |
		LC_ALL=C sort -t. -k 1,1 -k 2,2n -k 3,3n -k 4,4n -k 5,5n | awk '{print $2}'
}

list_github_tags() {
	git ls-remote --tags --refs "$GH_REPO" |
		grep -o 'refs/tags/v.*' | cut -d/ -f3- |
		sed 's/^v//' # NOTE: You might want to adapt this sed to remove non-version strings from tags
}

list_all_versions() {
	# Change this function if scarb has other means of determining installable versions.
	list_github_tags
}

get_latest_nightly() {
	git ls-remote --tags --refs "$GH_NIGHTLIES_REPO" |
		grep -o 'refs/tags/.*' | cut -d/ -f3- |
		sort_versions | tail -n1 | xargs echo
}

download_release() {
	local version filename url
	version="$1"
	filename="$2"

	get_architecture || fail "Could not determine system architecture."
	local _arch="$RETVAL"

	local repository tag

	if grep -q -E "nightly|dev" <<<"$version"; then
		repository=$GH_NIGHTLIES_REPO
		tag=$version
	else
		repository=$GH_REPO
		tag="v$version"
	fi

	local _tarball="scarb-${tag}-${_arch}.tar.gz"
	url="${repository}/releases/download/${tag}/${_tarball}"

	echo "* Downloading $TOOL_NAME release $version..."
	curl "${curl_opts[@]}" -o "$filename" -C - "$url" || fail "Could not download $url"
}

install_version() {
	local install_type="$1"
	local version="$2"
	local install_path="${3%/bin}"

	if [ "$install_type" != "version" ]; then
		fail "asdf-$TOOL_NAME supports release installs only"
	fi

	(
		mkdir -p "$install_path"
		cp -r "$ASDF_DOWNLOAD_PATH"/* "$install_path"

		local tool_cmd
		tool_cmd="$(echo "$TOOL_TEST" | cut -d' ' -f1)"
		test -x "$install_path/bin/$tool_cmd" || fail "Expected $install_path/bin/$tool_cmd to be executable."

		echo "$TOOL_NAME $version installation was successful!"
	) || (
		rm -rf "$install_path"
		fail "An error occurred while installing $TOOL_NAME $version."
	)
}

# Following functions are used to resolve the system architecture and OS type.

# This function has been copied verbatim from rustup install script.
check_proc() {
	# Check for /proc by looking for the /proc/self/exe link
	# This is only run on Linux
	if ! test -L /proc/self/exe; then
		err "fatal: Unable to find /proc/self/exe.  Is /proc mounted?  Installation cannot proceed without /proc."
	fi
}

# This function has been copied verbatim from rustup install script.
get_bitness() {
	#	need_cmd head
	# Architecture detection without dependencies beyond coreutils.
	# ELF files start out "\x7fELF", and the following byte is
	#   0x01 for 32-bit and
	#   0x02 for 64-bit.
	# The printf builtin on some shells like dash only supports octal
	# escape sequences, so we use those.
	local _current_exe_head
	_current_exe_head=$(head -c 5 /proc/self/exe)
	if [ "$_current_exe_head" = "$(printf '\177ELF\001')" ]; then
		echo 32
	elif [ "$_current_exe_head" = "$(printf '\177ELF\002')" ]; then
		echo 64
	else
		err "unknown platform bitness"
	fi
}

# This function has been copied verbatim from rustup install script.
get_architecture() {
	local _ostype _cputype _bitness _arch _clibtype
	_ostype="$(uname -s)"
	_cputype="$(uname -m)"
	_clibtype="gnu"

	if [ "$_ostype" = Linux ]; then
		if [ "$(uname -o)" = Android ]; then
			_ostype=Android
		fi
		if ldd --_requested_version 2>&1 | grep -q 'musl'; then
			_clibtype="musl"
		fi
	fi

	if [ "$_ostype" = Darwin ] && [ "$_cputype" = i386 ]; then
		# Darwin `uname -m` lies
		if sysctl hw.optional.x86_64 | grep -q ': 1'; then
			_cputype=x86_64
		fi
	fi

	if [ "$_ostype" = SunOS ]; then
		# Both Solaris and illumos presently announce as "SunOS" in "uname -s"
		# so use "uname -o" to disambiguate.  We use the full path to the
		# system uname in case the user has coreutils uname first in PATH,
		# which has historically sometimes printed the wrong value here.
		if [ "$(/usr/bin/uname -o)" = illumos ]; then
			_ostype=illumos
		fi

		# illumos systems have multi-arch userlands, and "uname -m" reports the
		# machine hardware name; e.g., "i86pc" on both 32- and 64-bit x86
		# systems.  Check for the native (widest) instruction set on the
		# running kernel:
		if [ "$_cputype" = i86pc ]; then
			_cputype="$(isainfo -n)"
		fi
	fi

	case "$_ostype" in
	Android)
		_ostype=linux-android
		;;

	Linux)
		check_proc
		_ostype=unknown-linux-$_clibtype
		_bitness=$(get_bitness)
		;;

	FreeBSD)
		_ostype=unknown-freebsd
		;;

	NetBSD)
		_ostype=unknown-netbsd
		;;

	DragonFly)
		_ostype=unknown-dragonfly
		;;

	Darwin)
		_ostype=apple-darwin
		;;

	illumos)
		_ostype=unknown-illumos
		;;

	MINGW* | MSYS* | CYGWIN* | Windows_NT)
		_ostype=pc-windows-gnu
		;;

	*)
		err "unrecognized OS type: $_ostype"
		;;
	esac

	case "$_cputype" in
	i386 | i486 | i686 | i786 | x86)
		_cputype=i686
		;;

	xscale | arm)
		_cputype=arm
		if [ "$_ostype" = "linux-android" ]; then
			_ostype=linux-androideabi
		fi
		;;

	armv6l)
		_cputype=arm
		if [ "$_ostype" = "linux-android" ]; then
			_ostype=linux-androideabi
		else
			_ostype="${_ostype}eabihf"
		fi
		;;

	armv7l | armv8l)
		_cputype=armv7
		if [ "$_ostype" = "linux-android" ]; then
			_ostype=linux-androideabi
		else
			_ostype="${_ostype}eabihf"
		fi
		;;

	aarch64 | arm64)
		_cputype=aarch64
		;;

	x86_64 | x86-64 | x64 | amd64)
		_cputype=x86_64
		;;

	mips)
		_cputype=$(get_endianness mips '' el)
		;;

	mips64)
		if [ "$_bitness" -eq 64 ]; then
			# only n64 ABI is supported for now
			_ostype="${_ostype}abi64"
			_cputype=$(get_endianness mips64 '' el)
		fi
		;;

	ppc)
		_cputype=powerpc
		;;

	ppc64)
		_cputype=powerpc64
		;;

	ppc64le)
		_cputype=powerpc64le
		;;

	s390x)
		_cputype=s390x
		;;
	riscv64)
		_cputype=riscv64gc
		;;
	loongarch64)
		_cputype=loongarch64
		;;
	*)
		err "unknown CPU type: $_cputype"
		;;
	esac

	# Detect 64-bit linux with 32-bit userland
	if [ "${_ostype}" = unknown-linux-gnu ] && [ "${_bitness}" -eq 32 ]; then
		case $_cputype in
		x86_64)
			if [ -n "${RUSTUP_CPUTYPE:-}" ]; then
				_cputype="$RUSTUP_CPUTYPE"
			else {
				# 32-bit executable for amd64 = x32
				if is_host_amd64_elf; then
					err "x86_64 linux with x86 userland unsupported"
				else
					_cputype=i686
				fi
			}; fi
			;;
		mips64)
			_cputype=$(get_endianness mips '' el)
			;;
		powerpc64)
			_cputype=powerpc
			;;
		aarch64)
			_cputype=armv7
			if [ "$_ostype" = "linux-android" ]; then
				_ostype=linux-androideabi
			else
				_ostype="${_ostype}eabihf"
			fi
			;;
		riscv64gc)
			err "riscv64 with 32-bit userland unsupported"
			;;
		esac
	fi

	# Detect armv7 but without the CPU features Rust needs in that build,
	# and fall back to arm.
	# See https://github.com/rust-lang/rustup.rs/issues/587.
	if [ "$_ostype" = "unknown-linux-gnueabihf" ] && [ "$_cputype" = armv7 ]; then
		if ensure grep '^Features' /proc/cpuinfo | grep -q -v neon; then
			# At least one processor does not have NEON.
			_cputype=arm
		fi
	fi

	_arch="${_cputype}-${_ostype}"

	RETVAL="$_arch"
}
