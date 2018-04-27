## Copyright (C) 2016 Jeremiah Orians
## This file is part of stage0.
##
## stage0 is free software: you an redistribute it and/or modify
## it under the terms of the GNU General Public License as published by
## the Free Software Foundation, either version 3 of the License, or
## (at your option) any later version.
##
## stage0 is distributed in the hope that it will be useful,
## but WITHOUT ANY WARRANTY; without even the implied warranty of
## MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
## GNU General Public License for more details.
##
## You should have received a copy of the GNU General Public License
## along with stage0.  If not, see <http://www.gnu.org/licenses/>.
// CONSTANT EXIT_FAILURE 1
// CONSTANT EXIT_SUCCESS 0

void exit(int value)
{
	asm("POP_ebx"
	"POP_ebx"
	"LOAD_IMMEDIATE_eax %1"
	"INT_80");
}