////////////////////////////////////////////////////////////////////////////////
//
// Filename:	sim/axi_tb.h
// {{{
// Project:	AXI DMA Check: A utility to measure AXI DMA speeds
//
// Purpose:	To provide a fairly generic interface wrapper to an AXI bus,
//		that can then be used to create a test-bench class.
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
#include <stdio.h>
#include <stdlib.h>

#include <verilated.h>
#include <verilated_vcd_c.h>
#include "testb.h"
#include "devbus.h"

//
// Number of clocks before deciding a peripheral is broken
const int	BOMBCOUNT = 32;

template <class TB>	class	AXI_TB : public DEVBUS {
	// {{{
	bool	m_buserr;
#ifdef	INTERRUPTWIRE
	bool	m_interrupt;
#endif
	VerilatedVcdC	*m_trace;
public:
	TB		*m_tb;
	typedef	uint32_t	BUSW;
	
	bool	m_bomb;

	// AXI_TB() constructor
	// {{{
	AXI_TB(void) {
		m_tb = new TB;
		Verilated::traceEverOn(true);

		m_bomb = false;

		m_tb->m_core->S_AXI_AWVALID = 0;
		m_tb->m_core->S_AXI_WVALID = 0;
		m_tb->m_core->S_AXI_BREADY = 0;

		m_tb->m_core->S_AXI_ARVALID = 0;
		m_tb->m_core->S_AXI_RREADY = 0;
		m_buserr = false;
#ifdef	INTERRUPTWIRE
		m_interrupt = false;
#endif
	}
	// }}}

	// AXI_TB deconstructor
	// {{{

	virtual	~AXI_TB(void) {
		delete m_tb;
	}
	// }}}

	// opentrace()
	// {{{
	virtual	void	opentrace(const char *vcdname) {
		m_tb->opentrace(vcdname);
	}
	// }}}

	// closetrace()
	// {{{
	virtual	void	closetrace(void) {
		m_tb->closetrace();
	}
	// }}}

	// close()
	// {{{
	virtual	void	close(void) {
		m_tb->close();
	}
	// }}}

	// kill()
	// {{{
	virtual	void	kill(void) {
		close();
	}
	// }}}

	// eval()
	// {{{
	virtual	void	eval(void) {
		m_tb->m_core->eval();
	}
	// }}}

	// tick()
	// {{{
#define	TICK	m_tb->tick
	void	tick(void) {
		m_tb->tick_clk();
#ifdef	INTERRUPTWIRE
		if (m_tb->m_core->INTERRUPTWIRE)
			m_interrupt = true;
#endif
	}
	// }}}

	// reset()
	// {{{
	virtual	void	reset(void) {
		// m_tb->m_core->S_AXI_ARESETN = 0;
		m_tb->m_core->i_reset = 1;
		m_tb->m_core->S_AXI_AWVALID = 0;
		m_tb->m_core->S_AXI_WVALID  = 0;
		m_tb->m_core->S_AXI_ARVALID = 0;

		for(int k=0; k<16; k++)
			tick();

		m_tb->m_core->i_reset = 0;
		tick();
	}
	// }}}

	// tickcount()
	// {{{
	unsigned long	tickcount(void) {
		return m_tb->m_time_ps / 10000l;
	}
	// }}}

	// idle() -- pass a tick w/o doing anything
	// {{{
	void	idle(const unsigned counts = 1) {
		m_tb->m_core->S_AXI_AWVALID = 0;
		m_tb->m_core->S_AXI_WVALID  = 0;
		m_tb->m_core->S_AXI_BREADY  = 0;
		m_tb->m_core->S_AXI_ARVALID = 0;
		m_tb->m_core->S_AXI_RREADY  = 0;
		for(unsigned k=0; k<counts; k++) {
			tick();
			assert(!m_tb->m_core->S_AXI_RVALID);
			assert(!m_tb->m_core->S_AXI_BVALID);
		}
	}
	// }}}

	////////////////////////////////////////////////////////////////////////
	//
	// Routines to read from the bus
	// {{{
	////////////////////////////////////////////////////////////////////////
	//
	// readio()
	// {{{
	BUSW readio(BUSW a) {
		BUSW		result;

		// printf("AXI-READM(%08x)\n", a);

		m_tb->m_core->S_AXI_ARVALID = 1;
		m_tb->m_core->S_AXI_ARADDR  = a;
		m_tb->m_core->S_AXI_RREADY  = 1;

		while(!m_tb->m_core->S_AXI_ARREADY)
			tick();

		tick();

		m_tb->m_core->S_AXI_ARVALID = 0;

		while(!m_tb->m_core->S_AXI_RVALID) // || !RVALID
			tick();

		result = m_tb->m_core->S_AXI_RDATA;
		if (m_tb->m_core->S_AXI_RRESP & 2)
			m_buserr = true;
		assert(m_tb->m_core->S_AXI_RRESP == 0);

		tick();

		return result;
	}
	// }}}

	// read64()
	// {{{
	uint64_t read64(BUSW a) {
		uint64_t	result;
		int32_t		buf[2];

		readv(a, 2, buf);
		result = buf[1];
		result = (result << 32) | (uint64_t)buf[0];
		return result;
	}
	// }}}

	// readv()
	// {{{
	void	readv(const BUSW a, int len, BUSW *buf, const int inc=1) {
		int		cnt, rdidx;

		printf("AXI-READM(%08x, %d)\n", a, len);
		m_tb->m_core->S_AXI_ARVALID = 1;
		m_tb->m_core->S_AXI_ARADDR  = a & -4;
		//
		m_tb->m_core->S_AXI_RREADY = 1;

		rdidx =0; cnt = 0;

		do {
			int	s;

			m_tb->m_core->S_AXI_ARVALID = 1;
			s = ((m_tb->m_core->S_AXI_ARVALID)
				&&(m_tb->m_core->S_AXI_ARREADY==0))?0:1;
			tick();
			m_tb->m_core->S_AXI_ARADDR += (inc&(s^1))?4:0;
			cnt += (s^1);
			if (m_tb->m_core->S_AXI_RVALID)
				buf[rdidx++] = m_tb->m_core->S_AXI_RDATA;
			if (m_tb->m_core->S_AXI_RVALID
					&& m_tb->m_core->S_AXI_RRESP != 0)
				m_buserr = true;
		} while(cnt < len);

		m_tb->m_core->S_AXI_ARVALID = 0;

		while(rdidx < len) {
			tick();
			if ((m_tb->m_core->S_AXI_RVALID)&&(m_tb->m_core->S_AXI_RREADY))
				buf[rdidx++] = m_tb->m_core->S_AXI_RDATA;
			if (m_tb->m_core->S_AXI_RVALID && m_tb->m_core->S_AXI_RRESP != 0)
				m_buserr = true;
		}

		tick();
		m_tb->m_core->S_AXI_RREADY = 0;
		assert(!m_tb->m_core->S_AXI_BVALID);
		assert(!m_tb->m_core->S_AXI_RVALID);
	}
	// }}}

	// readi()
	// {{{
	void	readi(const BUSW a, const int len, BUSW *buf) {
		readv(a, len, buf, 1);
	}
	// }}}

	// readz()
	// {{{
	void	readz(const BUSW a, const int len, BUSW *buf) {
		readv(a, len, buf, 0);
	}
	// }}}
	// }}}
	////////////////////////////////////////////////////////////////////////
	//
	// Routines to write to the bus
	// {{{
	////////////////////////////////////////////////////////////////////////
	//
	// writeio()
	// {{{
	void	writeio(const BUSW a, const BUSW v) {
		// printf("AXI-WRITEM(%08x) <= %08x\n", a, v);
		m_tb->m_core->S_AXI_ARVALID = 0;
		m_tb->m_core->S_AXI_RREADY  = 0;

		m_tb->m_core->S_AXI_AWVALID = 1;
		m_tb->m_core->S_AXI_WVALID  = 1;
		m_tb->m_core->S_AXI_AWADDR  = a & (-4);
		m_tb->m_core->S_AXI_WDATA   = v;
		m_tb->m_core->S_AXI_WSTRB   = 0x0f;

		while((m_tb->m_core->S_AXI_AWVALID)
			&&(m_tb->m_core->S_AXI_WVALID)) {
			int	awready = m_tb->m_core->S_AXI_AWREADY;
			int	wready = m_tb->m_core->S_AXI_WREADY;

			tick();

			if (awready)
				m_tb->m_core->S_AXI_AWVALID = 0;
			if (wready)
				m_tb->m_core->S_AXI_WVALID = 0;
		}

		m_tb->m_core->S_AXI_BREADY = 1;

		while(!m_tb->m_core->S_AXI_BVALID)
			tick();

		if (m_tb->m_core->S_AXI_BRESP & 2)
			m_buserr = true;
		tick();
	}
	// }}}

	// write64()
	// {{{
	void	write64(const BUSW a, const uint64_t v) {
		uint32_t	buf[2];
		// printf("AXI-WRITE64(%08x) <= %016lx\n", a, v);
		buf[0] = (uint32_t)v;
		buf[1] = (uint32_t)(v >> 32);
		writei(a, 2, buf);
	}
	// }}}

	// writev()
	// {{{
	void	writev(const BUSW a, const int ln, const BUSW *buf, const int inc=1) {
		unsigned nacks = 0, awcnt = 0, wcnt = 0;

		// printf("AXI-WRITEM(%08x, %d, ...)\n", a, ln);
		m_tb->m_core->S_AXI_AWVALID = 1;
		m_tb->m_core->S_AXI_AWADDR  = a & -4;
		m_tb->m_core->S_AXI_WVALID = 1;
		m_tb->m_core->S_AXI_WSTRB  = 0x0f;
		m_tb->m_core->S_AXI_WDATA  = buf[0];
		m_tb->m_core->S_AXI_BREADY = 1;
		m_tb->m_core->S_AXI_RREADY = 0;

		do {
			int	awready, wready;

			m_tb->m_core->S_AXI_WDATA   = buf[wcnt];

			m_tb->m_core->S_AXI_AWVALID = (awcnt < (unsigned)ln);
			m_tb->m_core->S_AXI_WVALID  = (wcnt < (unsigned)ln);

			awready = m_tb->m_core->S_AXI_AWREADY;
			wready  = m_tb->m_core->S_AXI_WREADY;

			tick();
			if (m_tb->m_core->S_AXI_AWVALID && awready) {
				awcnt++;
				// Update the address
				m_tb->m_core->S_AXI_AWADDR += (inc)?4:0;
			}

			if (m_tb->m_core->S_AXI_WVALID && wready)
				wcnt++;

			if (m_tb->m_core->S_AXI_BVALID) {
				nacks++;

				// Check for any bus errors
				if (m_tb->m_core->S_AXI_BRESP & 2)
					m_buserr = true;
			}

		} while((awcnt<(unsigned)ln)||(wcnt<(unsigned)ln));

		m_tb->m_core->S_AXI_AWVALID = 0;
		m_tb->m_core->S_AXI_WVALID  = 0;
		while(nacks < (unsigned)ln) {
			tick();
			if (m_tb->m_core->S_AXI_BVALID) {
				nacks++;
				if (m_tb->m_core->S_AXI_BRESP & 2)
					m_buserr = true;
			}
		}

		tick();

		// Release the bus
		m_tb->m_core->S_AXI_BREADY = 0;
		m_tb->m_core->S_AXI_RREADY = 0;

		assert(!m_tb->m_core->S_AXI_BVALID);
		assert(!m_tb->m_core->S_AXI_RVALID);
		assert(!m_tb->m_core->S_AXI_AWVALID);
		assert(!m_tb->m_core->S_AXI_WVALID);
	}
	// }}}

	// writei()
	// {{{
	void	writei(const BUSW a, const int ln, const BUSW *buf) {
		writev(a, ln, buf, 1);
	}
	// }}}

	// writez()
	// {{{
	void	writez(const BUSW a, const int ln, const BUSW *buf) {
		writev(a, ln, buf, 0);
	}
	// }}}
	// }}}
	////////////////////////////////////////////////////////////////////////
	//
	// Interrupt / error processing
	// {{{
	////////////////////////////////////////////////////////////////////////
	//
	//
	bool	bombed(void) const { return m_bomb; }

	// bool	debug(void) const	{ return m_debug; }
	// bool	debug(bool nxtv)	{ return m_debug = nxtv; }

	// poll()
	// {{{
	bool	poll(void) {
#ifdef	INTERRUPTWIRE
		return (m_interrupt)||(m_tb->m_core->INTERRUPTWIRE != 0);
#else
		return false;
#endif
	}
	// }}}

	// bus_err()
	// {{{
	bool	bus_err(void) const {
#ifdef	AXIERR
		return m_buserr;
#else
		return false;
#endif
	}
	// }}}

	// reset_err()
	// {{{
	void	reset_err(void) {
#ifdef	AXIERR
		m_buserr = false;;
#endif
	}
	// }}}

	// usleep()
	// {{{
	void	usleep(unsigned msec) {
#ifdef	CLKRATEHZ
		unsigned count = CLKRATEHZ / 1000 * msec;
#else
		// Assume 100MHz if no clockrate is given
		unsigned count = 1000*100 * msec;
#endif
		while(count-- != 0)
#ifdef	INTERRUPTWIRE
			if (poll()) return; else
#endif
			tick();
	}
	// }}}

	// clear()
	// {{{
	void	clear(void) {
#ifdef	INTERRUPTWIRE
		m_interrupt = false;
#endif
	}
	// }}}

	// wait()
	// {{{
	void	wait(void) {
#ifdef	INTERRUPTWIRE
		while(!poll())
			tick();
#else
		assert("No interrupt defined");
#endif
	}
	// }}}
	// }}}
// }}}
};

