#! /bin/sh
## Copyright (C) 2017 Jeremiah Orians
## Copyright (C) 2021 deesix <deesix@tuta.io>
## This file is part of M2-Planet.
##
## M2-Planet is free software: you can redistribute it and/or modify
## it under the terms of the GNU General Public License as published by
## the Free Software Foundation, either version 3 of the License, or
## (at your option) any later version.
##
## M2-Planet is distributed in the hope that it will be useful,
## but WITHOUT ANY WARRANTY; without even the implied warranty of
## MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
## GNU General Public License for more details.
##
## You should have received a copy of the GNU General Public License
## along with M2-Planet.  If not, see <http://www.gnu.org/licenses/>.

set -ex

TMPDIR="test/test1000/tmp-amd64"
mkdir -p ${TMPDIR}

# Build the test
./bin/M2-Planet \
	--architecture amd64 \
	-f M2libc/amd64/Linux/bootstrap.c \
	-f cc.h \
	-f M2libc/bootstrappable.c \
	-f cc_globals.c \
	-f cc_reader.c \
	-f cc_strings.c \
	-f cc_types.c \
	-f cc_core.c \
	-f cc_macro.c \
	-f cc.c \
	--debug \
	--bootstrap-mode \
	-o ${TMPDIR}/cc.M1 \
	|| exit 1

# Build debug footer
blood-elf \
	--64 \
	-f ${TMPDIR}/cc.M1 \
	--entry _start \
	-o ${TMPDIR}/cc-footer.M1 \
	|| exit 2

# Macro assemble with libc written in M1-Macro
M1 \
	-f M2libc/amd64/amd64_defs.M1 \
	-f M2libc/amd64/libc-core.M1 \
	-f ${TMPDIR}/cc.M1 \
	-f ${TMPDIR}/cc-footer.M1 \
	--little-endian \
	--architecture amd64 \
	-o ${TMPDIR}/cc.hex2 \
	|| exit 3

# Resolve all linkages
hex2 \
	-f M2libc/amd64/ELF-amd64-debug.hex2 \
	-f ${TMPDIR}/cc.hex2 \
	--little-endian \
	--architecture amd64 \
	--base-address 0x00600000 \
	-o test/results/test1000-amd64-binary \
	|| exit 4

# Ensure binary works if host machine supports test
if [ "$(get_machine ${GET_MACHINE_FLAGS})" = "amd64" ]
then
	# Verify that the resulting file works
	./test/results/test1000-amd64-binary \
		--architecture x86 \
		-f M2libc/x86/Linux/unistd.h \
		-f M2libc/stdlib.c \
		-f M2libc/x86/Linux/fcntl.h \
		-f M2libc/stdio.c \
		-f cc.h \
		-f M2libc/bootstrappable.c \
		-f cc_globals.c \
		-f cc_reader.c \
		-f cc_strings.c \
		-f cc_types.c \
		-f cc_core.c \
		-f cc_macro.c \
		-f cc.c \
		-o test/test1000/proof \
		|| exit 5

	. ./sha256.sh
	out=$(sha256_check test/test1000/proof.answer)
	[ "$out" = "test/test1000/proof: OK" ] || exit 6
	[ ! -e bin/M2-Planet ] && mv test/results/test1000-amd64-binary bin/M2-Planet
fi
exit 0
