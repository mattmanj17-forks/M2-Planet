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

TMPDIR="test/test0103/tmp-knight-posix"
mkdir -p ${TMPDIR}

# Build the test
./bin/M2-Planet \
	--architecture knight-posix \
	--expand-includes \
	-f test/test0103/get_machine.c \
	-o ${TMPDIR}/get_machine.M1 \
	|| exit 1

# Macro assemble with libc written in M1-Macro
M1 \
	-f M2libc/knight/knight_defs.M1 \
	-f M2libc/knight/libc-full.M1 \
	-f ${TMPDIR}/get_machine.M1 \
	--big-endian \
	--architecture knight-posix \
	-o ${TMPDIR}/get_machine.hex2 \
	|| exit 3

# Resolve all linkages
hex2 \
	-f M2libc/knight/ELF-knight.hex2 \
	-f ${TMPDIR}/get_machine.hex2 \
	--big-endian \
	--architecture knight-posix \
	--base-address 0x00 \
	-o test/results/test0103-knight-posix-binary \
	|| exit 4

# Ensure binary works if host machine supports test
if [ "$(get_machine ${GET_MACHINE_FLAGS})" = "knight" ] && [ ! -z "${KNIGHT_EMULATION}" ]
then
	# Verify that the resulting file works
	execve_image \
		./test/results/test0103-knight-posix-binary \
		${GET_MACHINE_FLAGS} \
		>| ${TMPDIR}/image || exit 5
	out=$(vm --POSIX-MODE --rom ${TMPDIR}/image --memory 2M)
	[ 0 = $? ] || exit 6
	[ "$out" = "knight" ] || exit 7

elif [ "$(get_machine ${GET_MACHINE_FLAGS})" = "knight" ]
then
	# Verify that the compiled program returns the correct result
	out=$(./test/results/test0103-knight-posix-binary ${GET_MACHINE_FLAGS} 2>&1 )
	[ 0 = $? ] || exit 6
	[ "$out" = "knight" ] || exit 7
fi
exit 0
