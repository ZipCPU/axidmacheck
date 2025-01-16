////////////////////////////////////////////////////////////////////////////////
//
// Filename:	sim/main_tb.cpp
// {{{
// Project:	AXI DMA Check: A utility to measure AXI DMA speeds
//
// Computer Generated: This file is computer generated by AUTOFPGA. DO NOT EDIT.
// DO NOT EDIT THIS FILE!
//
// CmdLine:	/home/dan/work/rnd/opencores/autofpga/trunk/sw/autofpga -d autofpga.dbg -o ./ global.txt axibus.txt axiram.txt axidma.txt aximm2s.txt axis2mm.txt controlbus.txt streamsink.txt streamsrc.txt vibus.txt noconsole.txt
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
// with this program.  (It's in the $(ROOT)/doc directory.  Run make with no
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
//
// SIM.INCLUDE
//
// Any SIM.INCLUDE tags you define will be pasted here.
// This is useful for guaranteeing any include functions
// your simulation needs are called.
//
#include "verilated.h"
#include "Vmain.h"
#define	BASECLASS	Vmain

#include "design.h"
#include "regdefs.h"
#include "testb.h"
#include "byteswap.h"
//
// SIM.DEFINES
//
// This tag is useful fr pasting in any #define values that
// might then control the simulation following.
//

// Compatibility definitions for Verilator 3.8 to 3.9
#ifndef	VVAR
#ifdef	ROOT_VERILATOR
#include "Vmain___024root.h"

#define	VVAR(A)	rootp->main__DOT_ ## A
#elif	defined(NEW_VERILATOR)
#define	VVAR(A)	main__DOT_ ## A
#else
#define	VVAR(A)	v__DOT_ ## A
#endif
#endif


#ifdef	ROOT_VERILATOR
#define	AXIRAM	VVAR(_axiram_mem.m_storage)
#else
#define	AXIRAM	VVAR(_axiram_mem)
#endif

#ifndef	RAMSIZE
#define	RAMSIZE	(1<<24)
#endif

#define	block_ram	VVAR(_axiram_mem)
class	MAINTB : public TESTB<Vmain> {
public:
		// SIM.DEFNS
		//
		// If you have any simulation components, create a
		// SIM.DEFNS tag to have those components defined here
		// as part of the main_tb.cpp function.
	MAINTB(void) {
		// SIM.INIT
		//
		// If your simulation components need to be initialized,
		// create a SIM.INIT tag.  That tag's value will be pasted
		// here.
		//
	}

	void	reset(void) {
		// SIM.SETRESET
		// If your simulation component needs logic before the
		// tick with reset set, that logic can be placed into
		// the SIM.SETRESET tag and thus pasted here.
		//
		TESTB<Vmain>::reset();
		// SIM.CLRRESET
		// If your simulation component needs logic following the
		// reset tick, that logic can be placed into the
		// SIM.CLRRESET tag and thus pasted here.
		//
	}

	void	trace(const char *vcd_trace_file_name) {
		fprintf(stderr, "Opening TRACE(%s)\n",
				vcd_trace_file_name);
		opentrace(vcd_trace_file_name);
		m_time_ps = 0;
	}

	void	close(void) {
		m_done = true;
	}

	void	tick(void) {
		TESTB<Vmain>::tick(); // Clock.size = 1
	}


	// Evaluating clock clk

	// sim_clk_tick() will be called from TESTB<Vmain>::tick()
	//   following any falling edge of clock clk
	virtual	void	sim_clk_tick(void) {
		// Default clock tick
		//
		// SIM.TICK tags go here for SIM.CLOCK=clk
		//
		// No SIM.TICK tags defined
		m_changed = false;
	}
	inline	void	tick_clk(void) {	tick();	}

	//
	// The load function
	//
	// This function is required by designs that need the flash or memory
	// set prior to run time.  The test harness should be able to call
	// this function to load values into any (memory-type) location
	// on the bus.
	//
	bool	load(uint32_t addr, const char *buf, uint32_t len) {
		uint32_t	start, offset, wlen, base, adrln;

		//
		// Loading the axiram component
		//
		base  = 0x01000000; // in octets
		adrln = 0x01000000;

		if ((addr >= base)&&(addr < base + adrln)) {
			// If the start access is in axiram
			start = (addr > base) ? (addr-base) : 0;
			offset = (start + base) - addr;
			wlen = (len-offset > adrln - start)
				? (adrln - start) : len - offset;
			// FROM axiram.SIM.LOAD
			start = start & (-4);
			wlen = (wlen+3)&(-4);

			// Need to byte swap data to get it into the memory
			char	*bswapd = new char[len+8];
			memcpy(bswapd, &buf[offset], wlen);
			byteswapbuf(len>>2, (uint32_t *)bswapd);
			memcpy(&m_core->block_ram[start], bswapd, wlen);
			delete	bswapd;
			// AUTOFPGA::Now clean up anything else
			// Was there more to write than we wrote?
			if (addr + len > base + adrln)
				return load(base + adrln, &buf[offset+wlen], len-wlen);
			return true;
		//
		// End of components with a SIM.LOAD tag, and a
		// non-zero number of addresses (NADDR)
		//
		}

		return false;
	}

	//
	// KYSIM.METHODS
	//
	// If your simulation code will need to call any of its own function
	// define this tag by those functions (or other sim code), and
	// it will be pasated here.
	//

};
