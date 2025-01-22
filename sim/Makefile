################################################################################
##
## Filename:	sim/Makefile
## {{{
## Project:	AXI DMA Check: A utility to measure AXI DMA speeds
##
## Purpose:	To coordinate the build of a cycle accurate, Verilator based,
##		simulation of the main module.  Access to the simulation is
##	provided via the same software commands that will access the board, save
##	that the parameters are a touch different.  (See the access software for
##	more information ...)
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
.PHONY: all
# Make certain the "all" target is the first and therefore the default target
all:
CXX	:= g++
OBJDIR	:= obj-pc
RTLD	:= ../rtl
VOBJDR	:= $(RTLD)/obj_dir
VERILATOR_ROOT ?= $(shell bash -c 'verilator -V|grep VERILATOR_ROOT | head -1 | sed -e " s/^.*=\s*//"')
VROOT	:= $(VERILATOR_ROOT)
VDEFS   := $(shell bash -c ./vversion.sh)
VINCD   := $(VROOT)/include
VINC	:= -I$(VINCD) -I$(VINCD)/vltstd -I$(VOBJDR)
INCS	:= -I../sw -I$(RTLD) $(VINC)
VOBJS   := $(OBJDIR)/verilated.o $(OBJDIR)/verilated_vcd_c.o $(OBJDIR)/verilated_cov.o $(OBJDIR)/verilated_threads.o
CFLAGS	:= -Og -g -Wall $(INCS) $(VDEFS) -DVM_COVERAGE=1 -D__WORDSIZE=64

SOURCES := $(SIMSOURCES) main_tb.cpp automaster_tb.cpp
HEADERS := $(foreach header,$(subst .cpp,.h,$(SOURCES)),$(wildcard $(header)))
#
PROGRAMS := main_tb
# Now the return to the "all" target, and fill in some details
all:	$(PROGRAMS)

$(OBJDIR)/%.o: %.cpp
	$(mk-objdir)
	$(CXX) $(CFLAGS) $(VDEFS) $(INCS) -c $< -o $@

$(OBJDIR)/%.o: $(VINCD)/%.cpp
	$(mk-objdir)
	$(CXX) $(CFLAGS) $(INCS) -c $< -o $@

MAINOBJS := $(OBJDIR)/automaster_tb.o
$(OBJDIR)/automaster_tb.o: automaster_tb.cpp main_tb.cpp axi_tb.h testb.h ../rtl/obj_dir/Vmain.h

main_tb: $(MAINOBJS) $(VOBJS) $(VOBJDR)/Vmain__ALL.a
	$(CXX) $(CFLAGS) $(INCS) $(VDEFS) $^ $(VOBJDR)/Vmain__ALL.a -lpthread -o $@

.PHONY: clean
clean:
	rm -f *.vcd
	rm -f $(PROGRAMS)
	rm -rf $(OBJDIR)/

#
# The "depends" target, to know what files things depend upon.  The depends
# file itself is kept in $(OBJDIR)/depends.txt
#
define build-depends
	$(mk-objdir)
	@echo "Building dependency file"
	@$(CXX) $(CFLAGS) $(INCS) -MM $(SOURCES) > $(OBJDIR)/xdepends.txt
	@sed -e 's/^.*.o: /$(OBJDIR)\/&/' < $(OBJDIR)/xdepends.txt > $(OBJDIR)/depends.txt
	@rm $(OBJDIR)/xdepends.txt
endef

.PHONY: depends
depends: tags
	$(build-depends)

.PHONY: test
test: logs/coverage.dat
logs/coverage.dat: main_tb
	./main_tb -d

COVTOOL=verilated_cov_2_lcov.py
logs/annotated/main.v: logs/coverage.dat
	cd ../rtl; verilator_coverage --annotate ../sim/logs/annotated ../sim/logs/coverage.dat

logs/lcov.dat: logs/coverage.dat
	python $(COVTOOL) $^	\
		| sed -e 's/^SF:...wb2axip/SF:..\/..\/wb2axip/' \
		| sed -e 's/SF:m/SF:..\/..\/rtl\/m/'	\
		| sed -e 's/SF:s/SF:..\/..\/rtl\/s/'  \
		> $@

logs/index.html: logs/lcov.dat
	cd logs/; genhtml lcov.dat

.PHONY: coverage
coverage: logs/index.html

# lcov -a logs/lcov.dat
# lcov -c -d appdir -o app_test.info ??
#
# -z -c -a -e -r -l --dif --summary
#	-c captures coverage data (I should have this already)
#	-e extracts particular data from the tracefile
#	-l lists the contents of the tracefile
#	-r removes trace file
#	-z resets execution counts to zero


$(OBJDIR)/depends.txt: depends

#
define	mk-objdir
	@bash -c "if [ ! -e $(OBJDIR) ]; then mkdir -p $(OBJDIR); fi"
endef


#
# The "tags" target
#
tags:	$(SOURCES) $(HEADERS)
	@echo "Generating tags"
	@ctags $(SOURCES) $(HEADERS)


ifneq ($(MAKECMDGOALS),clean)
-include $(OBJDIR)/depends.txt
endif
