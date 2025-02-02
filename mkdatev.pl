#!/usr/bin/perl
################################################################################
##
## Filename:	mkdatev.pl
## {{{
## Project:	AXI DMA Check: A utility to measure AXI DMA speeds
##
## Purpose:	This file creates a file containing a `define DATESTAMP
##		which can be used to tell when the build took place.
##
##
## Creator:	Dan Gisselquist, Ph.D.
##		Gisselquist Technology, LLC
##
################################################################################
## }}}
## Copyright (C) 2020-2025, Gisselquist Technology, LLC
## {{{
## This program is free software (firmware): you can redistribute it and/or
## modify it under the terms of the GNU General Public License as published
## by the Free Software Foundation, either version 3 of the License, or (at
## your option) any later version.
##
## This program is distributed in the hope that it will be useful, but WITHOUT
## ANY WARRANTY; without even the implied warranty of MERCHANTIBILITY or
## FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
## for more details.
##
## You should have received a copy of the GNU General Public License along
## with this program.  (It's in the $(ROOT)/doc directory.  Run make with no
## target there if the PDF file isn't present.)  If not, see
## <http://www.gnu.org/licenses/> for a copy.
## }}}
## License:	GPL, v3, as defined and found on www.gnu.org,
## {{{
##		http://www.gnu.org/licenses/gpl.html
##
################################################################################
##
## }}}

$now = time;
($sc,$mn,$nhr,$ndy,$nmo,$nyr,$nwday,$nyday,$nisdst) = localtime($now);
$nyr = $nyr+1900; $nmo = $nmo+1;

# And just because perl doesn't like my dollars signs ...
$doc = '$(ROOT)/doc';

print <<"EOM";
////////////////////////////////////////////////////////////////////////////////
//
// Filename: 	builddate.v
// {{{
// Project:	AXI DMA Check: A utility to measure AXI DMA speeds
//
// Purpose:	This file records the date of the last build.  Running "make"
//		in the main directory will create this file.  The `define found
//	within it then creates a version stamp that can be used to tell which
//	configuration is within an FPGA and so forth.
//
// Creator:	Dan Gisselquist, Ph.D.
//		Gisselquist Technology, LLC
//
////////////////////////////////////////////////////////////////////////////////
// }}}
// Copyright (C) 2020-2025, Gisselquist Technology, LLC
// {{{
// This program is free software (firmware): you can redistribute it and/or
// modify it under the terms of the GNU General Public License as published
// by the Free Software Foundation, either version 3 of the License, or (at
// your option) any later version.
//
// This program is distributed in the hope that it will be useful, but WITHOUT
// ANY WARRANTY; without even the implied warranty of MERCHANTIBILITY or
// FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
// for more details.
//
// You should have received a copy of the GNU General Public License along
// with this program.  (It's in the $doc directory.  Run make with no
// target there if the PDF file isn't present.)  If not, see
// <http://www.gnu.org/licenses/> for a copy.
// }}}
// License:	GPL, v3, as defined and found on www.gnu.org,
// {{{
//		http://www.gnu.org/licenses/gpl.html
//
////////////////////////////////////////////////////////////////////////////////
//
// }}}
EOM

print "`define DATESTAMP 32\'h";
printf("%04d%02d%02d\n", $nyr, $nmo, $ndy);
print "`define BUILDTIME 32\'h";
printf("%04d%02d%02d\n", $nhr, $mn, $sc);

