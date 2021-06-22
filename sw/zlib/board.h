////////////////////////////////////////////////////////////////////////////////
//
// Filename:	./board.h
// {{{
// Project:	AXI DMA Check: A utility to measure AXI DMA speeds
//
// DO NOT EDIT THIS FILE!
// Computer Generated: This file is computer generated by AUTOFPGA. DO NOT EDIT.
// DO NOT EDIT THIS FILE!
//
// CmdLine:	/home/dan/work/rnd/opencores/autofpga/trunk/sw/autofpga /home/dan/work/rnd/opencores/autofpga/trunk/sw/autofpga -d autofpga.dbg -o ./ global.txt axibus.txt axiram.txt axidma.txt aximm2s.txt axis2mm.txt controlbus.txt streamsink.txt streamsrc.txt vibus.txt zipaxi.txt axiconsole.txt mem_bkram_only.txt mm2sperf.txt s2mmperf.txt dmaperf.txt cpuperf.txt ramperf.txt
//
// Creator:	Dan Gisselquist, Ph.D.
//		Gisselquist Technology, LLC
//
////////////////////////////////////////////////////////////////////////////////
// }}}
// Copyright (C) 2020-2021, Gisselquist Technology, LLC
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
#ifndef	BOARD_H
#define	BOARD_H

// And, so that we can know what is and isn't defined
// from within our main.v file, let's include:
#include <design.h>

#include <design.h>
#include <cpudefs.h>

#define	_HAVE_ZIPSYS
#define	PIC	_zip->z_pic

#ifdef	INCLUDE_ZIPCPU
#ifdef INCLUDE_ACCOUNTING_COUNTERS
#define	_HAVE_ZIPSYS_PERFORMANCE_COUNTERS
#endif	// INCLUDE_ACCOUNTING_COUNTERS
#endif // INCLUDE_ZIPCPU


#ifndef	AXIPERF_H
#define	AXIPERF_H

#define	AXIPERF_START		1
#define	AXIPERF_STOP		0
#define	AXIPERF_CLEAR		2
#define	AXIPERF_TRIGGERED	4

typedef struct	AXIPERF_S {
	unsigned	p_active, p_burstsz, p_wridles, p_awrbursts, p_wrbeats,
			p_awbytes, p_wbytes, p_wrslowd, p_wrstalls, p_wraddrlag,
			p_wrdatalag, p_awearly, p_wrearlyd, p_awstall,
			p_wr_early_stall, p_wrblags, p_wrbstall;
	unsigned	p_unused;
	unsigned	p_wrbias, p_awrcycles, p_wrcycles;
	unsigned	p_rdidles, p_rdmaxb, p_rdbursts, p_rdbeats, p_rdbytes,
			p_arcycles, p_arstalls, p_rdrstalls, p_rdlag, p_rdslow;
	unsigned	p_control;
} AXIPERF;

#endif


#ifndef	AXIPERF_H
#define	AXIPERF_H

#define	AXIPERF_START		1
#define	AXIPERF_STOP		0
#define	AXIPERF_CLEAR		2
#define	AXIPERF_TRIGGERED	4

typedef struct	AXIPERF_S {
	unsigned	p_active, p_burstsz, p_wridles, p_awrbursts, p_wrbeats,
			p_awbytes, p_wbytes, p_wrslowd, p_wrstalls, p_wraddrlag,
			p_wrdatalag, p_awearly, p_wrearlyd, p_awstall,
			p_wr_early_stall, p_wrblags, p_wrbstall;
	unsigned	p_unused;
	unsigned	p_wrbias, p_awrcycles, p_wrcycles;
	unsigned	p_rdidles, p_rdmaxb, p_rdbursts, p_rdbeats, p_rdbytes,
			p_arcycles, p_arstalls, p_rdrstalls, p_rdlag, p_rdslow;
	unsigned	p_control;
} AXIPERF;

#endif


#ifndef	AXIPERF_H
#define	AXIPERF_H

#define	AXIPERF_START		1
#define	AXIPERF_STOP		0
#define	AXIPERF_CLEAR		2
#define	AXIPERF_TRIGGERED	4

typedef struct	AXIPERF_S {
	unsigned	p_active, p_burstsz, p_wridles, p_awrbursts, p_wrbeats,
			p_awbytes, p_wbytes, p_wrslowd, p_wrstalls, p_wraddrlag,
			p_wrdatalag, p_awearly, p_wrearlyd, p_awstall,
			p_wr_early_stall, p_wrblags, p_wrbstall;
	unsigned	p_unused;
	unsigned	p_wrbias, p_awrcycles, p_wrcycles;
	unsigned	p_rdidles, p_rdmaxb, p_rdbursts, p_rdbeats, p_rdbytes,
			p_arcycles, p_arstalls, p_rdrstalls, p_rdlag, p_rdslow;
	unsigned	p_control;
} AXIPERF;

#endif


#ifndef	AXIPERF_H
#define	AXIPERF_H

#define	AXIPERF_START		1
#define	AXIPERF_STOP		0
#define	AXIPERF_CLEAR		2
#define	AXIPERF_TRIGGERED	4

typedef struct	AXIPERF_S {
	unsigned	p_active, p_burstsz, p_wridles, p_awrbursts, p_wrbeats,
			p_awbytes, p_wbytes, p_wrslowd, p_wrstalls, p_wraddrlag,
			p_wrdatalag, p_awearly, p_wrearlyd, p_awstall,
			p_wr_early_stall, p_wrblags, p_wrbstall;
	unsigned	p_unused;
	unsigned	p_wrbias, p_awrcycles, p_wrcycles;
	unsigned	p_rdidles, p_rdmaxb, p_rdbursts, p_rdbeats, p_rdbytes,
			p_arcycles, p_arstalls, p_rdrstalls, p_rdlag, p_rdslow;
	unsigned	p_control;
} AXIPERF;

#endif


#define	SYSPIC(A)	(1<<(A))


typedef	struct	S2MM_S {
	unsigned	a_control;
	unsigned	a_unused1[3];
	unsigned	*a_dest;
	unsigned	a_unused2;
	unsigned	a_len;
	unsigned	a_unused3;
} S2MM;



#define	ALTPIC(A)	(1<<(A))



#define DMA_START_CMD           0x00000011
#define DMA_BUSY_BIT            0x00000001

typedef struct  AXIDMA_S {
        unsigned	a_control;
        unsigned	a_unused1;
        char		*a_src;
        unsigned	a_unused2;
        char		*a_dest;
        unsigned	a_unused3;
        unsigned	a_len;
        unsigned	a_unused4;
} AXIDMA;



#ifndef	AXIPERF_H
#define	AXIPERF_H

#define	AXIPERF_START		1
#define	AXIPERF_STOP		0
#define	AXIPERF_CLEAR		2
#define	AXIPERF_TRIGGERED	4

typedef struct	AXIPERF_S {
	unsigned	p_active, p_burstsz, p_wridles, p_awrbursts, p_wrbeats,
			p_awbytes, p_wbytes, p_wrslowd, p_wrstalls, p_wraddrlag,
			p_wrdatalag, p_awearly, p_wrearlyd, p_awstall,
			p_wr_early_stall, p_wrblags, p_wrbstall;
	unsigned	p_unused;
	unsigned	p_wrbias, p_awrcycles, p_wrcycles;
	unsigned	p_rdidles, p_rdmaxb, p_rdbursts, p_rdbeats, p_rdbytes,
			p_arcycles, p_arstalls, p_rdrstalls, p_rdlag, p_rdslow;
	unsigned	p_control;
} AXIPERF;

#endif


typedef struct  CONSOLE_S {
	unsigned	u_setup;
	unsigned	u_fifo;
	unsigned	u_rx, u_tx;
} CONSOLE;

#define	_uart_txbusy	((_uart->u_fifo & 0x10000)==0)
#define	_uart_txidle	((_uart->u_tx   & 0x100)  ==0)


#ifndef	AXIPERF_H
#define	AXIPERF_H

#define	AXIPERF_START		1
#define	AXIPERF_STOP		0
#define	AXIPERF_CLEAR		2
#define	AXIPERF_TRIGGERED	4

typedef struct	AXIPERF_S {
	unsigned	p_active, p_burstsz, p_wridles, p_awrbursts, p_wrbeats,
			p_awbytes, p_wbytes, p_wrslowd, p_wrstalls, p_wraddrlag,
			p_wrdatalag, p_awearly, p_wrearlyd, p_awstall,
			p_wr_early_stall, p_wrblags, p_wrbstall;
	unsigned	p_unused;
	unsigned	p_wrbias, p_awrcycles, p_wrcycles;
	unsigned	p_rdidles, p_rdmaxb, p_rdbursts, p_rdbeats, p_rdbytes,
			p_arcycles, p_arstalls, p_rdrstalls, p_rdlag, p_rdslow;
	unsigned	p_control;
} AXIPERF;

#endif


typedef struct	AXILP_S {
	unsigned	z_pic, z_wdt, z_apic, z_unused0;
	unsigned	z_tma, z_tmb, z_tmc, z_jiffies;
	unsigned	z_mac_ck, z_mac_mem, z_mac_pf, z_mac_icnt;
	unsigned	z_uac_ck, z_uac_mem, z_uac_pf, z_uac_icnt;
} AXILP;



typedef	struct	MM2S_S {
	unsigned	a_control;
	unsigned	a_unused1;
	unsigned	*a_src;
	unsigned	a_unused2[3];
	unsigned	a_len;
	unsigned	a_unused3;
} MM2S;



#define	_BOARD_HAS_RAMPERF
static volatile AXIPERF * const _ramperf=((AXIPERF *)0x00800700);
#define	_BOARD_HAS_CPUIPERF
static volatile AXIPERF * const _cpuiperf=((AXIPERF *)0x00800580);
#define	_BOARD_HAS_MM2SPERF
static volatile AXIPERF * const _mm2sperf=((AXIPERF *)0x00800680);
#define	_BOARD_HAS_DMAPERF
static volatile AXIPERF * const _dmaperf=((AXIPERF *)0x00800600);
#define	_BOARD_HAS_S2MM
static volatile S2MM * const _s2mm=((S2MM *)0x008004c0);
#define	_BOARD_HAS_AXIDMA
static volatile AXIDMA * const _dma=((AXIDMA *)0x00800440);
#define	_BOARD_HAS_S2MMPERF
static volatile AXIPERF * const _s2mmperf=((AXIPERF *)0x00800780);
#ifdef	BUSCONSOLE_ACCESS
#define	_BOARD_HAS_BUSCONSOLE
static volatile CONSOLE *const _uart = ((CONSOLE *)0x00800000);
#endif	// BUSCONSOLE_ACCESS
#define	_BOARD_HAS_CPUDPERF
static volatile AXIPERF * const _cpudperf=((AXIPERF *)0x00800500);
#define	_BOARD_HAS_AXILP
static volatile AXILP * const _axilp=((AXILP *)0x00800200);
#define	_BOARD_HAS_MM2S
static volatile MM2S * const _mm2s=((MM2S *)0x00800480);
//
// Interrupt assignments (2 PICs)
//
// PIC: syspic
#define	SYSPIC_DMAC	SYSPIC(0)
#define	SYSPIC_JIFFIES	SYSPIC(1)
#define	SYSPIC_TMC	SYSPIC(2)
#define	SYSPIC_TMB	SYSPIC(3)
#define	SYSPIC_TMA	SYSPIC(4)
#define	SYSPIC_ALT	SYSPIC(5)
#define	SYSPIC_UARTRXF	SYSPIC(6)
#define	SYSPIC_UARTTXF	SYSPIC(7)
// PIC: altpic
#define	ALTPIC_UIC	ALTPIC(0)
#define	ALTPIC_UOC	ALTPIC(1)
#define	ALTPIC_UPC	ALTPIC(2)
#define	ALTPIC_UTC	ALTPIC(3)
#define	ALTPIC_MIC	ALTPIC(4)
#define	ALTPIC_MOC	ALTPIC(5)
#define	ALTPIC_MPC	ALTPIC(6)
#define	ALTPIC_MTC	ALTPIC(7)
#define	ALTPIC_UARTTX	ALTPIC(8)
#define	ALTPIC_UARTRX	ALTPIC(9)
#endif	// BOARD_H
