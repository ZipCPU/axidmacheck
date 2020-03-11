////////////////////////////////////////////////////////////////////////////////
//
// Filename:	automaster_tb.cpp
//
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
//
// Copyright (C) 2017-2019, Gisselquist Technology, LLC
//
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
//
// License:	GPL, v3, as defined and found on www.gnu.org,
//		http://www.gnu.org/licenses/gpl.html
//
//
////////////////////////////////////////////////////////////////////////////////
//
//
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

void	usage(void) {
	fprintf(stderr, "USAGE: main_tb <options>\n");
	fprintf(stderr,
"\t-d\tSets the debugging flag\n"
"\t-t <filename>\n"
"\t\tTurns on tracing, sends the trace to <filename>--assumed to\n"
"\t\tbe a vcd file\n"
);
}

#define	TBRAM	m_tb->m_core->AXIRAM

int	main(int argc, char **argv) {
	const	char *trace_file = NULL; // "trace.vcd";
	bool	debug_flag = false;
	bool	fail = false;
	Verilated::commandArgs(argc, argv);
	AXI_TB<MAINTB>	*tb = new AXI_TB<MAINTB>;

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
#define	MM2S_START_ADDR	0x24
#define	MM2S_LENGTH	262144

#define	MM2S_START_ADDRW	(MM2S_START_ADDR/4)
#define	MM2S_LENGTHW		(MM2S_LENGTH/4)

	memset(tb->TBRAM, -1, RAMSIZE);
	for(int k=0; k<MM2S_LENGTHW; k++)
		tb->TBRAM[k+MM2S_START_ADDRW] = k;
	tb->writeio(R_MM2SADDR, MM2S_START_ADDR + R_AXIRAM);
	tb->writeio(R_MM2SLEN,  MM2S_LENGTH);
	tb->writeio(R_STREAMSINK_BEATS, 0);
#define	MM2S_START	0xc0000000
	tb->writeio(R_MM2SCTRL, MM2S_START);
	while((tb->readio(R_MM2SCTRL) & 0x80000000)==0)
		;
	while(tb->readio(R_MM2SCTRL) & 0x80000000)
		;
	printf("AXIMM2S Check:\n");
	printf("\tBEATS:  0x%08x\n", tb->readio(R_STREAMSINK_BEATS));
	printf("\tCLOCKS: 0x%08x\n", tb->readio(R_STREAMSINK_CLOCKS));

	//
	// Test the AXIS2MM
	//
#define	S2MM_START_ADDR	0x30
#define	S2MM_LENGTH	262144

#define	S2MM_START_ADDRW	(MM2S_START_ADDR/4)
#define	S2MM_LENGTHW		(MM2S_LENGTH/4)
#define	S2MM_START_CMD		0xc0000000

	memset(tb->TBRAM, -1, RAMSIZE);
	tb->writeio(R_S2MMADDR, S2MM_START_ADDR + R_AXIRAM);
	tb->writeio(R_S2MMLEN,  S2MM_LENGTH);
	tb->writeio(R_S2MMCTRL, S2MM_START_CMD);
	while((tb->readio(R_S2MMCTRL) & 0x80000000)==0)
		;
	while(tb->readio(R_S2MMCTRL) & 0x80000000)
		;
	printf("AXIS2MM Check:\n");
	// printf("\tBEATS:  0x%08x\n", tb->readio(R_STREAMSINK_BEATS));
	// printf("\tCLOCKS: 0x%08x\n", tb->readio(R_STREAMSINK_CLOCKS));
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

//	while(!tb->done())
//		tb->tick();

	tb->close();
	delete tb;

	if (fail) {
		printf("TEST FAIL!\n");
		return EXIT_FAILURE;
	}
	printf("SUCCESS!\n");
	return	EXIT_SUCCESS;
}

