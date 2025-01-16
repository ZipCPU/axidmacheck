////////////////////////////////////////////////////////////////////////////////
//
// Filename:	sim/automaster_tb.cpp
// {{{
// Project:	AXI DMA Check: A utility to measure AXI DMA speeds
//
// Purpose:	This file calls and accesses the main.v function via the
//		MAIN_TB class found in main_tb.cpp.  When put together with
//	the other components here, this file will simulate (all of) the
//	host's interaction with the FPGA circuit board.
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
#include <signal.h>
#include <time.h>
#include <ctype.h>
#include <string.h>
#include <stdint.h>

#include "verilated.h"
#include "design.h"

#include "testb.h"
// #include "twoc.h"
// #include "port.h"
#include "main_tb.cpp"
#include "axi_tb.h"

#define	TBRAM	m_tb->m_core->AXIRAM

#define	MM2S_START_ADDR		0x24
#define	MM2S_LENGTH		32768 // 262144
#define	MM2S_START_ADDRW	(MM2S_START_ADDR/4)
#define	MM2S_LENGTHW		(MM2S_LENGTH/4)
#define	MM2S_START_CMD		0xc0000000
#define	MM2S_ABORT_CMD		0x6d000000
#define	MM2S_CONTINUOUS		0x10000000

#define	S2MM_START_ADDR		0x30
#define	S2MM_LENGTH		32768 // 262144
#define	S2MM_START_ADDRW	(MM2S_START_ADDR/4)
#define	S2MM_LENGTHW		(MM2S_LENGTH/4)
#define	S2MM_START_CMD		0xc0000000
#define	S2MM_ABORT_CMD		0x26000000

#define	DMA_START_CMD		0x00000011
#define	DMA_BUSY_BIT		0x00000001
// Extra realignment read (only)
// #define	DMA_SRC_ADDR		0x00000203
// #define	DMA_DST_ADDR		0x00008201
// #define	DMA_LENGTH		0x00000401
//
// Extra realignment write
#define	DMA_SRC_ADDR		0x00000201
#define	DMA_DST_ADDR		0x00008202
#define	DMA_LENGTH		0x00000403

void	usage(void) {
	fprintf(stderr, "USAGE: main_tb <options>\n");
	fprintf(stderr,
"\t-d\tSets the debugging flag\n"
"\t-t <filename>\n"
"\t\tTurns on tracing, sends the trace to <filename>--assumed to\n"
"\t\tbe a vcd file\n"
);
}

int	main(int argc, char **argv) {
	const	char *trace_file = NULL; // "trace.vcd";
	bool	debug_flag = false;
	bool	fail = false;
	Verilated::commandArgs(argc, argv);
	AXI_TB<MAINTB>	*tb = new AXI_TB<MAINTB>;
	unsigned long	start_counts;

	for(int argn=1; argn < argc; argn++) {
		if (argv[argn][0] == '-') for(int j=1;
					(j<512)&&(argv[argn][j]);j++) {
			switch(tolower(argv[argn][j])) {
			case 'd': debug_flag = true;
				if (trace_file == NULL)
					trace_file = "trace.vcd";
				break;
			case 't': trace_file = argv[++argn]; j=1000; break;
			case 'h': usage(); exit(0); break;
			default:
				fprintf(stderr, "ERR: Unexpected flag, -%c\n\n",
					argv[argn][j]);
				usage();
				break;
			}
		} else {
			fprintf(stderr, "ERR: Cannot read %s\n", argv[argn]);
			perror("O/S Err:");
			exit(EXIT_FAILURE);
		}
	}

	if (debug_flag) {
		printf("Opening Bus-master with\n");
		// printf("\tDebug Access port = %d\n", FPGAPORT);
		printf("\tVCD File         = %s\n", trace_file);
	} if (trace_file)
		tb->opentrace(trace_file);

	tb->reset();

	//
	// Test the AXIMM2S
	//
	memset(tb->TBRAM, -1, RAMSIZE);
	for(int k=0; k<MM2S_LENGTHW; k++)
		tb->TBRAM[k+MM2S_START_ADDRW] = k;
	tb->write64(R_MM2SADDRLO, (uint64_t)MM2S_START_ADDR + R_AXIRAM);
	tb->write64(R_MM2SLENLO,  (uint64_t)MM2S_LENGTH);
	tb->writeio(R_STREAMSINK_BEATS, 0);
	start_counts = tb->tickcount();
	tb->writeio(R_MM2SCTRL, MM2S_START_CMD);
	while((tb->readio(R_MM2SCTRL) & 0x80000000)==0)
		;
	while(tb->readio(R_MM2SCTRL) & 0x80000000)
		;
	printf("AXIMM2S Check:\n");
	printf("\tBEATS:  0x%08x\n", tb->readio(R_STREAMSINK_BEATS));
	printf("\tCLOCKS: 0x%08x\n", tb->readio(R_STREAMSINK_CLOCKS));
	printf("\tCOUNTS: 0x%08lx\n", tb->tickcount()-start_counts);

	// Try aborting an AXIMM2S transaction
	memset(tb->TBRAM, -1, RAMSIZE);
	for(int k=0; k<MM2S_LENGTHW; k++)
		tb->TBRAM[k+MM2S_START_ADDRW] = k;
	tb->write64(R_MM2SADDRLO, (uint64_t)MM2S_START_ADDR + R_AXIRAM);
	tb->write64(R_MM2SLENLO,  (uint64_t)MM2S_LENGTH);
	tb->writeio(R_STREAMSINK_BEATS, 0);
	start_counts = tb->tickcount();
	tb->writeio(R_MM2SCTRL, MM2S_START_CMD);
	while((tb->readio(R_MM2SCTRL) & 0x80000000)==0)
		;
	tb->idle(425);
	tb->writeio(R_MM2SCTRL, MM2S_ABORT_CMD);

	while(tb->readio(R_MM2SCTRL) & 0x80000000)
		;
	printf("AXIMM2S (abort) Check:\n");
	printf("\tBEATS:  0x%08x\n", tb->readio(R_STREAMSINK_BEATS));
	printf("\tCLOCKS: 0x%08x\n", tb->readio(R_STREAMSINK_CLOCKS));
	printf("\tCOUNTS: 0x%08lx\n", tb->tickcount()-start_counts);

	// Try an unaligned AXIMM2S transaction
	memset(tb->TBRAM, -1, RAMSIZE);
	for(int k=0; k<MM2S_LENGTHW; k++)
		tb->TBRAM[k+MM2S_START_ADDRW] = k;
	tb->write64(R_MM2SADDRLO, (uint64_t)MM2S_START_ADDR + R_AXIRAM + 3);
	if ((tb->readio(R_MM2SADDRLO) & 0x03)==3) {
		tb->write64(R_MM2SLENLO,  (uint64_t)MM2S_LENGTH);
		tb->writeio(R_STREAMSINK_BEATS, 0);
		start_counts = tb->tickcount();
		tb->writeio(R_MM2SCTRL, MM2S_START_CMD);
		while((tb->readio(R_MM2SCTRL) & 0x80000000)==0)
			;
		while(tb->readio(R_MM2SCTRL) & 0x80000000)
			;
		printf("AXIMM2S (unaligned) Check:\n");
		printf("\tBEATS:  0x%08x\n", tb->readio(R_STREAMSINK_BEATS));
		printf("\tCLOCKS: 0x%08x\n", tb->readio(R_STREAMSINK_CLOCKS));
		printf("\tCOUNTS: 0x%08lx\n", tb->tickcount()-start_counts);
	} else
		printf("AXIMM2S (unaligned) Check: No unaligned support (0x%08x)\n", tb->readio(R_MM2SADDRLO));

	// Try a continuous transaction
	memset(tb->TBRAM, -1, RAMSIZE);
	for(int k=0; k<MM2S_LENGTHW; k++)
		tb->TBRAM[k+MM2S_START_ADDRW] = k;
	tb->write64(R_MM2SADDRLO, (uint64_t)MM2S_START_ADDR + R_AXIRAM);
	tb->write64(R_MM2SLENLO, (uint64_t) MM2S_LENGTH);
	tb->writeio(R_STREAMSINK_BEATS, 0);
	start_counts = tb->tickcount();
	tb->writeio(R_MM2SCTRL, MM2S_START_CMD | MM2S_CONTINUOUS);
	while((tb->readio(R_MM2SCTRL) & 0x80000000)==0)
		;
	while(tb->readio(R_MM2SCTRL) & 0x80000000)
		;
	printf("AXIMM2S (continuous) Midway:\n");
	printf("\tBEATS:  0x%08x\n", tb->readio(R_STREAMSINK_BEATS));
	printf("\tCLOCKS: 0x%08x\n", tb->readio(R_STREAMSINK_CLOCKS));
	printf("\tCOUNTS: 0x%08lx\n", tb->tickcount()-start_counts);
	for(int k=0; k<MM2S_LENGTHW; k++)
		tb->TBRAM[k+MM2S_START_ADDRW] = k + 0x100;
	tb->idle(425);
	tb->write64(R_MM2SADDRLO, (uint64_t)MM2S_START_ADDR + R_AXIRAM);
	tb->write64(R_MM2SLENLO, (uint64_t)MM2S_LENGTH);
	// tb->writeio(R_STREAMSINK_BEATS, 0);
	tb->writeio(R_MM2SCTRL, MM2S_START_CMD | MM2S_CONTINUOUS);
	while((tb->readio(R_MM2SCTRL) & 0xc0000000)==0)
		;
	while(tb->readio(R_MM2SCTRL) & 0x80000000)
		;
	printf("AXIMM2S (continuous) Midway:\n");
	printf("\tSTATUS: 0x%08x\n", tb->readio(R_MM2SCTRL));
	printf("\tBEATS:  0x%08x\n", tb->readio(R_STREAMSINK_BEATS));
	printf("\tCLOCKS: 0x%08x\n", tb->readio(R_STREAMSINK_CLOCKS));
	printf("\tCOUNTS: 0x%08lx\n", tb->tickcount()-start_counts);



	//
	// Test the AXIS2MM
	//
	memset(tb->TBRAM, -1, RAMSIZE);
	tb->write64(R_S2MMADDRLO, (uint64_t)S2MM_START_ADDR + R_AXIRAM);
	tb->write64(R_S2MMLENLO,  (uint64_t)S2MM_LENGTH);
	start_counts = tb->tickcount();
	tb->writeio(R_S2MMCTRL, S2MM_START_CMD);
	while((tb->readio(R_S2MMCTRL) & 0x80000000)==0)
		;
	while(tb->readio(R_S2MMCTRL) & 0x80000000)
		;
	printf("AXIS2MM Check:\n");
	// printf("\tBEATS:  0x%08x\n", tb->readio(R_STREAMSINK_BEATS));
	// printf("\tCLOCKS: 0x%08x\n", tb->readio(R_STREAMSINK_CLOCKS));
	printf("\tCOUNTS: 0x%08lx\n", tb->tickcount()-start_counts);
	printf("\tERR-CODE: %d\n", (tb->readio(R_S2MMCTRL)>>23)&0x07);
	for(unsigned k=0; k<0x30>>2; k++)
		if (tb->TBRAM[k] != (unsigned)(-1)) {
			printf("Pre-corruption: AXIRAM[%d] = 0x%08x\n", k, tb->TBRAM[k]);
			fail = true;
		}
	for(unsigned k=1 +(0x30>>2); k<(0x30>>2)+(16384>>2); k++)
		if (tb->TBRAM[k] != tb->TBRAM[k-1]+1) {
			printf("Result: AXIRAM[%d] = 0x%08x != 0x%08x + 1\n", k, tb->TBRAM[k], tb->TBRAM[k-1]);
			fail = true;
		}

	// Try it again--this time aborting the transaction midway
	start_counts = tb->tickcount();
	memset(tb->TBRAM, -1, RAMSIZE);
	tb->write64(R_S2MMADDRLO, (uint64_t)S2MM_START_ADDR + R_AXIRAM);
	tb->write64(R_S2MMLENLO,  (uint64_t)S2MM_LENGTH);
	start_counts = tb->tickcount();
	tb->writeio(R_S2MMCTRL, S2MM_START_CMD);
	while((tb->readio(R_S2MMCTRL) & 0x80000000)==0)
		;
	tb->idle(425);
	tb->writeio(R_S2MMCTRL, S2MM_ABORT_CMD);

	while(tb->readio(R_S2MMCTRL) & 0x80000000)
		;
	printf("AXIS2MM (abort) Check:\n");
	printf("\tCOUNTS: 0x%08lx\n", tb->tickcount()-start_counts);
	printf("\tERR-CODE: %d\n", (tb->readio(R_S2MMCTRL)>>23)&0x07);

	// Try it again--this time writing to non-existant memory
/*
 * Doesn't work: all addresses are mapped
	start_counts = tb->tickcount();
	memset(tb->TBRAM, -1, RAMSIZE);
	tb->writeio(R_S2MMADDR, R_AXIRAM /2);
	tb->writeio(R_S2MMLEN,  S2MM_LENGTH);
	start_counts = tb->tickcount();
	tb->writeio(R_S2MMCTRL, S2MM_START_CMD);
	while((tb->readio(R_S2MMCTRL) & 0x80000000)==0)
		;
	while(tb->readio(R_S2MMCTRL) & 0x80000000)
		;
	printf("AXIS2MM (err) Check:\n");
	printf("\tCOUNTS: 0x%08lx\n", tb->tickcount()-start_counts);
	printf("\tERR-CODE: %d\n", (tb->readio(R_S2MMCTRL)>>23)&0x07);
*/


	//
	// Test the AXIDMA
	//
	printf("Running AXI DMA test\n");
	memset(tb->TBRAM, -1, RAMSIZE);
	tb->write64(R_AXIDMASRCLO,  (uint64_t)DMA_SRC_ADDR + R_AXIRAM);
	tb->write64(R_AXIDMADSTLO,  (uint64_t)DMA_DST_ADDR + R_AXIRAM);
	tb->write64(R_AXIDMALENLO,  (uint64_t)DMA_LENGTH);
	tb->writeio(R_AXIDMACTRL, DMA_START_CMD);
	while((tb->readio(R_AXIDMACTRL) & DMA_BUSY_BIT)==0)
		;
	printf("Test has begin\n");
	while(tb->readio(R_AXIDMACTRL) & DMA_BUSY_BIT) {
		{
			static int throttle = 0;
			if (throttle++ > 2000)
				printf("TICKCOUNT = %ld\n", tb->tickcount());
		}
		if (tb->tickcount() >= 400000)
			return EXIT_FAILURE;
	}
	printf("AXIDMA Check:\n");

	VerilatedCov::write("logs/coverage.dat");
	tb->close();
	delete tb;

	if (fail) {
		printf("TEST FAIL!\n");
		return EXIT_FAILURE;
	}
	printf("SUCCESS!\n");
	return	EXIT_SUCCESS;
}

