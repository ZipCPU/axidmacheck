////////////////////////////////////////////////////////////////////////////////
//
// Filename:	./regdefs.h
// {{{
// Project:	AXI DMA Check: A utility to measure AXI DMA speeds
//
// DO NOT EDIT THIS FILE!
// Computer Generated: This file is computer generated by AUTOFPGA. DO NOT EDIT.
// DO NOT EDIT THIS FILE!
//
// CmdLine:	/home/dan/work/rnd/opencores/autofpga/trunk/sw/autofpga /home/dan/work/rnd/opencores/autofpga/trunk/sw/autofpga -d autofpga.dbg -o ./ global.txt axibus.txt axiram.txt axidma.txt aximm2s.txt axis2mm.txt controlbus.txt streamsink.txt streamsrc.txt vibus.txt zipaxi.txt axiconsole.txt mem_bkram_only.txt mm2sperf.txt s2mmperf.txt
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
#ifndef	REGDEFS_H
#define	REGDEFS_H


//
// The @REGDEFS.H.INCLUDE tag
//
// @REGDEFS.H.INCLUDE for masters
// @REGDEFS.H.INCLUDE for peripherals
// And finally any master REGDEFS.H.INCLUDE tags
// End of definitions from REGDEFS.H.INCLUDE


//
// Register address definitions, from @REGS.#d
//
// CONSOLE registers
#define	R_CONSOLE_FIFO      	0x00800004	// 00800000, wbregs names: UFIFO
#define	R_CONSOLE_UARTRX    	0x00800008	// 00800000, wbregs names: RX
#define	R_CONSOLE_UARTTX    	0x0080000c	// 00800000, wbregs names: TX
#define	R_STREAMSINK_BEATS  	0x00800200	// 00800200, wbregs names: BEATS
#define	R_STREAMSINK_PACKETS	0x00800204	// 00800200, wbregs names: PACKETS
#define	R_STREAMSINK_CLOCKS 	0x00800208	// 00800200, wbregs names: CLOCKS
#define	R_AXIDMACTRL        	0x00800240	// 00800240, wbregs names: AXIDMACTRL
#define	R_AXIDMASRCLO       	0x00800248	// 00800240, wbregs names: AXIDMASRCLO
#define	R_AXIDMASRCHI       	0x0080024c	// 00800240, wbregs names: AXIDMASRCHI
#define	R_AXIDMADSTLO       	0x00800250	// 00800240, wbregs names: AXIDMADSTLO
#define	R_AXIDMADSTHI       	0x00800254	// 00800240, wbregs names: AXIDMADSTHI
#define	R_AXIDMALENLO       	0x00800258	// 00800240, wbregs names: AXIDMALENLO
#define	R_AXIDMALENHI       	0x0080025c	// 00800240, wbregs names: AXIDMALENHI
// AXI MM2S registers
#define	R_MM2SCTRL          	0x00800280	// 00800280, wbregs names: MM2SCTRL
#define	R_MM2SADDRLO        	0x00800288	// 00800280, wbregs names: MM2SADDRLO
#define	R_MM2SADDRHI        	0x0080028c	// 00800280, wbregs names: MM2SADDRHI
#define	R_MM2SLENLO         	0x00800298	// 00800280, wbregs names: MM2SLENLO
#define	R_MM2SLENHI         	0x0080029c	// 00800280, wbregs names: MM2SLENHI
#define	R_S2MMCTRL          	0x008002c0	// 008002c0, wbregs names: S2MMCTRL
#define	R_S2MMADDRLO        	0x008002d0	// 008002c0, wbregs names: S2MMADDRLO
#define	R_S2MMADDRHI        	0x008002d4	// 008002c0, wbregs names: S2MMADDRHI
#define	R_S2MMLENLO         	0x008002d8	// 008002c0, wbregs names: S2MMLENLO
#define	R_S2MMLENHI         	0x008002dc	// 008002c0, wbregs names: S2MMLENHI
//
// AXI Performance monitor for MM2SPERF
//

#define	R_MM2SPERFACTIVE    	0x00800300	// 00800300, wbregs names: MM2SPERFACTIVE
#define	R_MM2SPERFBURSTSZ   	0x00800304	// 00800300, wbregs names: MM2SPERFBURSTSZ
#define	R_MM2SPERFWRIDLES   	0x00800308	// 00800300, wbregs names: MM2SPERFWRIDLES
#define	R_MM2SPERFAWRBURSTS 	0x0080030c	// 00800300, wbregs names: MM2SPERFAWRBURSTS
#define	R_MM2SPERFWRBEATS   	0x00800310	// 00800300, wbregs names: MM2SPERFWRBEATS
#define	R_MM2SPERFAWBYTES   	0x00800314	// 00800300, wbregs names: MM2SPERFAWBYTES
#define	R_MM2SPERFWBYTES    	0x00800318	// 00800300, wbregs names: MM2SPERFWBYTES
#define	R_MM2SPERFWRSLOWD   	0x0080031c	// 00800300, wbregs names: MM2SPERFWRSLOWD
#define	R_MM2SPERFWRSTALLS  	0x00800320	// 00800300, wbregs names: MM2SPERFWRSTALLS
#define	R_MM2SPERFWRADDRLAG 	0x00800324	// 00800300, wbregs names: MM2SPERFWRADDRLAG
#define	R_MM2SPERFWRDATALAG 	0x00800328	// 00800300, wbregs names: MM2SPERFWRDATALAG
#define	R_MM2SPERFWRBEATSD  	0x0080032c	// 00800300, wbregs names: MM2SPERFWRBEATSD
#define	R_MM2SPERFAWBURSTB  	0x00800330	// 00800300, wbregs names: MM2SPERFAWBURSTB
#define	R_MM2SPERFAWADDRST  	0x00800334	// 00800300, wbregs names: MM2SPERFAWADDRST
#define	R_MM2SPERFAWWSTALL  	0x00800338	// 00800300, wbregs names: MM2SPERFAWWSTALL
#define	R_MM2SPERFAWWSLOW   	0x0080033c	// 00800300, wbregs names: MM2SPERFAWWSLOW
#define	R_MM2SPERFAWWNODATA 	0x00800340	// 00800300, wbregs names: MM2SPERFAWWNODATA
#define	R_MM2SPERFAWWBEATS  	0x00800344	// 00800300, wbregs names: MM2SPERFAWWBEATS
#define	R_MM2SPERFWRBLAGS   	0x00800348	// 00800300, wbregs names: MM2SPERFWRBLAGS
#define	R_MM2SPERFWRBSTALL  	0x0080034c	// 00800300, wbregs names: MM2SPERFWRBSTALL
#define	R_MM2SPERFRDIDLES   	0x00800358	// 00800300, wbregs names: MM2SPERFRDIDLES
#define	R_MM2SPERFRDMAXB    	0x0080035c	// 00800300, wbregs names: MM2SPERFRDMAXB
#define	R_MM2SPERFRDBURSTS  	0x00800360	// 00800300, wbregs names: MM2SPERFRDBURSTS
#define	R_MM2SPERFRDBEATS   	0x00800364	// 00800300, wbregs names: MM2SPERFRDBEATS
#define	R_MM2SPERFRDBYTES   	0x00800368	// 00800300, wbregs names: MM2SPERFRDBYTES
#define	R_MM2SPERFRDARSTALLS	0x0080036c	// 00800300, wbregs names: MM2SPERFRDARSTALLS
#define	R_MM2SPERFRDRSTALLS 	0x00800370	// 00800300, wbregs names: MM2SPERFRDRSTALLS
#define	R_MM2SPERFRDLAG     	0x00800374	// 00800300, wbregs names: MM2SPERFRDLAG
#define	R_MM2SPERFRDSLOW    	0x00800378	// 00800300, wbregs names: MM2SPERFRDSLOW
#define	R_MM2SPERFCONTROL   	0x0080037c	// 00800300, wbregs names: MM2SPERFCONTROL
//
// AXI Performance monitor for S2MMPERF
//

#define	R_S2MMPERFACTIVE    	0x00800380	// 00800380, wbregs names: S2MMPERFACTIVE
#define	R_S2MMPERFBURSTSZ   	0x00800384	// 00800380, wbregs names: S2MMPERFBURSTSZ
#define	R_S2MMPERFWRIDLES   	0x00800388	// 00800380, wbregs names: S2MMPERFWRIDLES
#define	R_S2MMPERFAWRBURSTS 	0x0080038c	// 00800380, wbregs names: S2MMPERFAWRBURSTS
#define	R_S2MMPERFWRBEATS   	0x00800390	// 00800380, wbregs names: S2MMPERFWRBEATS
#define	R_S2MMPERFAWBYTES   	0x00800394	// 00800380, wbregs names: S2MMPERFAWBYTES
#define	R_S2MMPERFWBYTES    	0x00800398	// 00800380, wbregs names: S2MMPERFWBYTES
#define	R_S2MMPERFWRSLOWD   	0x0080039c	// 00800380, wbregs names: S2MMPERFWRSLOWD
#define	R_S2MMPERFWRSTALLS  	0x008003a0	// 00800380, wbregs names: S2MMPERFWRSTALLS
#define	R_S2MMPERFWRADDRLAG 	0x008003a4	// 00800380, wbregs names: S2MMPERFWRADDRLAG
#define	R_S2MMPERFWRDATALAG 	0x008003a8	// 00800380, wbregs names: S2MMPERFWRDATALAG
#define	R_S2MMPERFWRBEATSD  	0x008003ac	// 00800380, wbregs names: S2MMPERFWRBEATSD
#define	R_S2MMPERFAWBURSTB  	0x008003b0	// 00800380, wbregs names: S2MMPERFAWBURSTB
#define	R_S2MMPERFAWADDRST  	0x008003b4	// 00800380, wbregs names: S2MMPERFAWADDRST
#define	R_S2MMPERFAWWSTALL  	0x008003b8	// 00800380, wbregs names: S2MMPERFAWWSTALL
#define	R_S2MMPERFAWWSLOW   	0x008003bc	// 00800380, wbregs names: S2MMPERFAWWSLOW
#define	R_S2MMPERFAWWNODATA 	0x008003c0	// 00800380, wbregs names: S2MMPERFAWWNODATA
#define	R_S2MMPERFAWWBEATS  	0x008003c4	// 00800380, wbregs names: S2MMPERFAWWBEATS
#define	R_S2MMPERFWRBLAGS   	0x008003c8	// 00800380, wbregs names: S2MMPERFWRBLAGS
#define	R_S2MMPERFWRBSTALL  	0x008003cc	// 00800380, wbregs names: S2MMPERFWRBSTALL
#define	R_S2MMPERFRDIDLES   	0x008003d8	// 00800380, wbregs names: S2MMPERFRDIDLES
#define	R_S2MMPERFRDMAXB    	0x008003dc	// 00800380, wbregs names: S2MMPERFRDMAXB
#define	R_S2MMPERFRDBURSTS  	0x008003e0	// 00800380, wbregs names: S2MMPERFRDBURSTS
#define	R_S2MMPERFRDBEATS   	0x008003e4	// 00800380, wbregs names: S2MMPERFRDBEATS
#define	R_S2MMPERFRDBYTES   	0x008003e8	// 00800380, wbregs names: S2MMPERFRDBYTES
#define	R_S2MMPERFRDARSTALLS	0x008003ec	// 00800380, wbregs names: S2MMPERFRDARSTALLS
#define	R_S2MMPERFRDRSTALLS 	0x008003f0	// 00800380, wbregs names: S2MMPERFRDRSTALLS
#define	R_S2MMPERFRDLAG     	0x008003f4	// 00800380, wbregs names: S2MMPERFRDLAG
#define	R_S2MMPERFRDSLOW    	0x008003f8	// 00800380, wbregs names: S2MMPERFRDSLOW
#define	R_S2MMPERFCONTROL   	0x008003fc	// 00800380, wbregs names: S2MMPERFCONTROL
#define	R_AXIRAM            	0x01000000	// 01000000, wbregs names: AXIRAM, RAM
// ZipCPU control/debug registers
#define	R_ZIPCTRL           	0x02000080	// 02000000, wbregs names: CPU, ZIPCTRL
#define	R_ZIPREGS           	0x02000000	// 02000000, wbregs names: ZIPREGS
#define	R_ZIPS0             	0x02000000	// 02000000, wbregs names: SR0
#define	R_ZIPS1             	0x02000004	// 02000000, wbregs names: SR1
#define	R_ZIPS2             	0x02000008	// 02000000, wbregs names: SR2
#define	R_ZIPS3             	0x0200000c	// 02000000, wbregs names: SR3
#define	R_ZIPS4             	0x02000010	// 02000000, wbregs names: SR4
#define	R_ZIPS5             	0x02000014	// 02000000, wbregs names: SR5
#define	R_ZIPS6             	0x02000018	// 02000000, wbregs names: SR6
#define	R_ZIPS7             	0x0200001c	// 02000000, wbregs names: SR7
#define	R_ZIPS8             	0x02000020	// 02000000, wbregs names: SR8
#define	R_ZIPS9             	0x02000024	// 02000000, wbregs names: SR9
#define	R_ZIPS10            	0x02000028	// 02000000, wbregs names: SR10
#define	R_ZIPS11            	0x0200002c	// 02000000, wbregs names: SR11
#define	R_ZIPS12            	0x02000030	// 02000000, wbregs names: SR12
#define	R_ZIPSSP            	0x02000034	// 02000000, wbregs names: SSP, SR13
#define	R_ZIPCC             	0x02000038	// 02000000, wbregs names: ZIPCC, CC, SCC, SR14
#define	R_ZIPPC             	0x0200003c	// 02000000, wbregs names: ZIPPC, PC, SPC, SR15
#define	R_ZIPUSER           	0x02000040	// 02000000, wbregs names: ZIPUSER
#define	R_ZIPU0             	0x02000040	// 02000000, wbregs names: UR0
#define	R_ZIPU1             	0x02000044	// 02000000, wbregs names: UR1
#define	R_ZIPU2             	0x02000048	// 02000000, wbregs names: UR2
#define	R_ZIPU3             	0x0200004c	// 02000000, wbregs names: UR3
#define	R_ZIPU4             	0x02000050	// 02000000, wbregs names: UR4
#define	R_ZIPU5             	0x02000054	// 02000000, wbregs names: UR5
#define	R_ZIPU6             	0x02000058	// 02000000, wbregs names: UR6
#define	R_ZIPU7             	0x0200005c	// 02000000, wbregs names: UR7
#define	R_ZIPU8             	0x02000060	// 02000000, wbregs names: UR8
#define	R_ZIPU9             	0x02000064	// 02000000, wbregs names: UR9
#define	R_ZIPU10            	0x02000068	// 02000000, wbregs names: SR10
#define	R_ZIPU11            	0x0200006c	// 02000000, wbregs names: SR11
#define	R_ZIPU12            	0x02000070	// 02000000, wbregs names: SR12
#define	R_ZIPUSP            	0x02000074	// 02000000, wbregs names: USP, UR13
#define	R_ZIPUCC            	0x02000078	// 02000000, wbregs names: ZIPUCC, UCC
#define	R_ZIPUPC            	0x0200007c	// 02000000, wbregs names: ZIPUPC, UPC
#define	R_ZIPSYSTEM         	0x02000100	// 02000000, wbregs names: ZIPSYSTEM, ZIPSYS


//
// The @REGDEFS.H.DEFNS tag
//
// @REGDEFS.H.DEFNS for masters
#define	BAUDRATE	1000000
// @REGDEFS.H.DEFNS for peripherals
// @REGDEFS.H.DEFNS at the top level
// End of definitions from REGDEFS.H.DEFNS
//
// The @REGDEFS.H.INSERT tag
//
// @REGDEFS.H.INSERT for masters
// @REGDEFS.H.INSERT for peripherals

#define	CPU_GO		0x0000
#define	CPU_RESET	0x0040
#define	CPU_INT		0x0080
#define	CPU_STEP	0x0100
#define	CPU_STALL	0x0200
#define	CPU_HALT	0x0400
#define	CPU_CLRCACHE	0x0800

#define	RESET_ADDRESS	0x01000000

// @REGDEFS.H.INSERT from the top level
typedef	struct {
	unsigned	m_addr;
	const char	*m_name;
} REGNAME;

extern	const	REGNAME	*bregs;
extern	const	int	NREGS;
// #define	NREGS	(sizeof(bregs)/sizeof(bregs[0]))

extern	unsigned	addrdecode(const char *v);
extern	const	char *addrname(const unsigned v);
// End of definitions from REGDEFS.H.INSERT


#endif	// REGDEFS_H
