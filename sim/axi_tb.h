////////////////////////////////////////////////////////////////////////////////
//
// Filename:	axi_tb.cpp
//
// Project:	AXI DMA Check: A utility to measure AXI DMA speeds
//
// Purpose:	To provide a fairly generic interface wrapper to an AXI bus,
//		that can then be used to create a test-bench class.
//
// Creator:	Dan Gisselquist, Ph.D.
//		Gisselquist Technology, LLC
//
////////////////////////////////////////////////////////////////////////////////
//
// Copyright (C) 2020, Gisselquist Technology, LLC
//
// This program is free software (firmware): you can redistribute it and/or
// modify it under the terms of  the GNU General Public License as published
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
//
// License:	GPL, v3, as defined and found on www.gnu.org,
//		http://www.gnu.org/licenses/gpl.html
//
//
////////////////////////////////////////////////////////////////////////////////
//
//
#include <stdio.h>
#include <stdlib.h>

#include <verilated.h>
#include <verilated_vcd_c.h>
#include "testb.h"
#include "devbus.h"

const int	BOMBCOUNT = 32;

template <class VA>	class	AXI_TB : public DEVBUS {
	bool	m_buserr;
#ifdef	INTERRUPTWIRE
	bool	m_interrupt;
#endif
	VerilatedVcdC	*m_trace;
	unsigned long	m_tickcount;
public:
	VA		*m_tb;
	typedef	uint32_t	BUSW;
	
	bool	m_bomb;

	AXI_TB(void) {
		m_tb = new VA;
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

	virtual	~AXI_TB(void) {
		// if (m_trace) {
			// m_trace->close();
			// delete m_trace;
		// }
		// delete m_core;
		// m_core  = NULL;
		// m_trace = NULL;
	}

	virtual	void	opentrace(const char *vcdname) {
		// m_trace = new VerilatedVcdC;
		// m_core->trace(m_trace, 99);
		// m_trace->open(vcdname);
		m_tb->opentrace(vcdname);
	}

	virtual	void	closetrace(void) {
		m_tb->closetrace();
		// if (m_trace) {
		//	m_trace->close();
		//	m_trace = NULL;
		//}
	}

	virtual	void	close(void) {
		// TESTB<VA>::closetrace();
		m_tb->close();
	}

	virtual	void	kill(void) {
		close();
	}

	virtual	void	eval(void) {
		m_tb->m_core->eval();
	}

#define	TICK	m_tb->tick
	/*
	virtual	void	tick(void) {
		m_tickcount++

		eval();
		if (m_trace) m_trace->dump(10*m_tickcount-2);
		m_core->S_AXI_ACLK = 1;
		eval();
		if (m_trace) m_trace->dump(10*m_tickcount);
		m_core->S_AXI_ACLK = 0;
		eval();
		if (m_trace) {
			m_trace->dump(10*m_tickcount+5);
			m_trace->flush();
		}
#ifdef	INTERRUPTWIRE
		if (TESTB<VA>::m_core->INTERRUPTWIRE)
			m_interrupt = true;
#endif
	}
	*/

	virtual	void	reset(void) {
		// m_tb->m_core->S_AXI_ARESETN = 0;
		m_tb->m_core->i_reset = 1;
		m_tb->m_core->S_AXI_AWVALID = 0;
		m_tb->m_core->S_AXI_WVALID  = 0;
		m_tb->m_core->S_AXI_ARVALID = 0;

		for(int k=0; k<16; k++)
			TICK();

		m_tb->m_core->i_reset = 0;
	}

	unsigned long	tickcount(void) {
		return m_tickcount;
	}

	void	idle(const unsigned counts = 1) {
		m_tb->m_core->S_AXI_AWVALID = 0;
		m_tb->m_core->S_AXI_WVALID  = 0;
		m_tb->m_core->S_AXI_BREADY  = 0;
		m_tb->m_core->S_AXI_ARVALID = 0;
		m_tb->m_core->S_AXI_RREADY  = 0;
		for(unsigned k=0; k<counts; k++) {
			this->tick();
			assert(!m_tb->m_core->S_AXI_RVALID);
			assert(!m_tb->m_core->S_AXI_BVALID);
		}
	}

	BUSW readio(BUSW a) {
		BUSW		result;

		// printf("AXI-READM(%08x)\n", a);

		m_tb->m_core->S_AXI_ARVALID = 1;
		m_tb->m_core->S_AXI_ARADDR  = a;
		m_tb->m_core->S_AXI_RREADY  = 1;

		while(!m_tb->m_core->S_AXI_ARREADY)
			TICK();

		TICK();

		m_tb->m_core->S_AXI_ARVALID = 0;

		while(!m_tb->m_core->S_AXI_RVALID || !m_tb->m_core->S_AXI_RREADY)
			TICK();

		result = m_tb->m_core->S_AXI_RDATA;
		if (m_tb->m_core->S_AXI_RRESP & 2)
			m_buserr = true;
		assert(m_tb->m_core->S_AXI_RRESP == 0);

		TICK();
		// printf("AXI-READM -> 0x%08x\n", result);

		return result;
	}

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
			TICK();
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
			TICK();
			if ((m_tb->m_core->S_AXI_RVALID)&&(m_tb->m_core->S_AXI_RREADY))
				buf[rdidx++] = m_tb->m_core->S_AXI_RDATA;
			if (m_tb->m_core->S_AXI_RVALID && m_tb->m_core->S_AXI_RRESP != 0)
				m_buserr = true;
		}

		TICK();
		m_tb->m_core->S_AXI_RREADY = 0;
		assert(!m_tb->m_core->S_AXI_BVALID);
		assert(!m_tb->m_core->S_AXI_RVALID);
	}

	void	readi(const BUSW a, const int len, BUSW *buf) {
		return readv(a, len, buf, 1);
	}

	void	readz(const BUSW a, const int len, BUSW *buf) {
		return readv(a, len, buf, 0);
	}

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

			TICK();

			if (awready)
				m_tb->m_core->S_AXI_AWVALID = 0;
			if (wready)
				m_tb->m_core->S_AXI_WVALID = 0;
		}

		m_tb->m_core->S_AXI_BREADY = 1;

		while(!m_tb->m_core->S_AXI_BVALID)
			TICK();

		if (m_tb->m_core->S_AXI_BRESP & 2)
			m_buserr = true;
		TICK();
	}

	void	writev(const BUSW a, const int ln, const BUSW *buf, const int inc=1) {
		unsigned nacks = 0;

		// printf("AXI-WRITEM(%08x, %d, ...)\n", a, ln);
		m_tb->m_core->S_AXI_AWVALID = 1;
		m_tb->m_core->S_AXI_AWADDR  = a & -4;
		m_tb->m_core->S_AXI_WVALID = 1;
		m_tb->m_core->S_AXI_WSTRB  = 0x0f;
		m_tb->m_core->S_AXI_WDATA  = buf[0];
		m_tb->m_core->S_AXI_BREADY = 1;
		m_tb->m_core->S_AXI_RREADY = 0;

		for(int sm_tbcnt=0; sm_tbcnt<ln; sm_tbcnt++) {
			// m_core->i_wb_addr= a+sm_tbcnt;
			m_tb->m_core->S_AXI_WDATA = buf[sm_tbcnt];

			m_tb->m_core->S_AXI_AWVALID = 1;
			m_tb->m_core->S_AXI_WVALID  = 1;

			while((m_tb->m_core->S_AXI_AWVALID
				&& !m_tb->m_core->S_AXI_AWREADY)
				||(m_tb->m_core->S_AXI_WVALID
					&& !m_tb->m_core->S_AXI_WREADY)) {
				bool	awready, wready;

				awready = m_tb->m_core->S_AXI_AWREADY;
				wready = m_tb->m_core->S_AXI_WREADY;

				TICK();
				if (awready)
					m_tb->m_core->S_AXI_AWVALID = 0;
				if (wready)
					m_tb->m_core->S_AXI_WVALID = 0;

				if (m_tb->m_core->S_AXI_BVALID) {
					nacks++;
					if (m_tb->m_core->S_AXI_BRESP & 2)
						m_buserr = true;
				}
			} TICK();

			m_tb->m_core->S_AXI_AWVALID = 0;
			m_tb->m_core->S_AXI_WVALID = 0;

			if (m_tb->m_core->S_AXI_BVALID) {
				nacks++;
				if (m_tb->m_core->S_AXI_BRESP & 2)
					m_buserr = true;
			}

			// Now update the address
			m_tb->m_core->S_AXI_AWADDR += (inc)?4:0;
		}

		while(nacks < (unsigned)ln) {
			TICK();
			if (m_tb->m_core->S_AXI_BVALID) {
				nacks++;
				if (m_tb->m_core->S_AXI_BRESP & 2)
					m_buserr = true;
			}
		}

		TICK();

		// Release the bus
		m_tb->m_core->S_AXI_BREADY = 0;
		m_tb->m_core->S_AXI_RREADY = 0;

		assert(!m_tb->m_core->S_AXI_BVALID);
		assert(!m_tb->m_core->S_AXI_RVALID);
	}

	void	writei(const BUSW a, const int ln, const BUSW *buf) {
		writev(a, ln, buf, 1);
	}

	void	writez(const BUSW a, const int ln, const BUSW *buf) {
		writev(a, ln, buf, 0);
	}


	bool	bombed(void) const { return m_bomb; }

	// bool	debug(void) const	{ return m_debug; }
	// bool	debug(bool nxtv)	{ return m_debug = nxtv; }

	bool	poll(void) {
#ifdef	INTERRUPTWIRE
		return (m_interrupt)||(m_tb->m_core->INTERRUPTWIRE != 0);
#else
		return false;
#endif
	}

	bool	bus_err(void) const {
#ifdef	AXIERR
		return m_buserr;
#else
		return false;
#endif
	}

	void	reset_err(void) {
#ifdef	AXIERR
		m_buserr = false;;
#endif
	}

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
			TICK();
	}

	void	clear(void) {
#ifdef	INTERRUPTWIRE
		m_interrupt = false;
#endif
	}

	void	wait(void) {
#ifdef	INTERRUPTWIRE
		while(!poll())
			TICK();
#else
		assert(("No interrupt defined",0));
#endif
	}
};

