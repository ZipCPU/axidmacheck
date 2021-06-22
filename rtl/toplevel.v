////////////////////////////////////////////////////////////////////////////////
//
// Filename:	./toplevel.v
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
`default_nettype	none


//
// Here we declare our toplevel.v (toplevel) design module.
// All design logic must take place beneath this top level.
//
// The port declarations just copy data from the @TOP.PORTLIST
// key, or equivalently from the @MAIN.PORTLIST key if
// @TOP.PORTLIST is absent.  For those peripherals that don't need
// any top level logic, the @MAIN.PORTLIST should be sufficent,
// so the @TOP.PORTLIST key may be left undefined.
//
// The only exception is that any clocks with CLOCK.TOP tags will
// also appear in this list
//
module	toplevel(
		// UART/host to wishbone interface
		i_wbu_uart_rx, o_wbu_uart_tx,
		// A reset wire for the ZipCPU
		i_cpu_resetn,
		//
		// Drive the AXI bus from an AXI-lite control
		//
		S_AXI_AWVALID,
		S_AXI_AWREADY,
		S_AXI_AWADDR,
		//
		S_AXI_WVALID,
		S_AXI_WREADY,
		S_AXI_WDATA,
		S_AXI_WSTRB,
		//
		S_AXI_BVALID,
		S_AXI_BREADY,
		S_AXI_BRESP,
		//
		S_AXI_ARVALID,
		S_AXI_ARREADY,
		S_AXI_ARADDR,
		//
		S_AXI_RVALID,
		S_AXI_RREADY,
		S_AXI_RDATA,
		S_AXI_RRESP);
	//
	// Declaring our input and output ports.  We listed these above,
	// now we are declaring them here.
	//
	// These declarations just copy data from the @TOP.IODECLS key,
	// or from the @MAIN.IODECL key if @TOP.IODECL is absent.  For
	// those peripherals that don't do anything at the top level,
	// the @MAIN.IODECL key should be sufficient, so the @TOP.IODECL
	// key may be left undefined.
	//
	// We start with any @CLOCK.TOP keys
	//
	input	wire		i_wbu_uart_rx;
	output	wire		o_wbu_uart_tx;
	// A reset wire for the ZipCPU
	input	wire		i_cpu_resetn;
	//
	// Drive the AXI bus from an AXI-lite control
	// {{{
	input	wire				S_AXI_AWVALID;
	output	wire				S_AXI_AWREADY;
	input	wire [26-1:0]	S_AXI_AWADDR;
	//
	input	wire				S_AXI_WVALID;
	output	wire				S_AXI_WREADY;
	input	wire [32-1:0]	S_AXI_WDATA;
	input wire [32/8-1:0]	S_AXI_WSTRB;
	//
	output	wire				S_AXI_BVALID;
	input	wire				S_AXI_BREADY;
	output	wire	[1:0]			S_AXI_BRESP;
	//
	input	wire				S_AXI_ARVALID;
	output	wire				S_AXI_ARREADY;
	input	wire [26-1:0]	S_AXI_ARADDR;
	//
	output	wire					S_AXI_RVALID;
	input	wire					S_AXI_RREADY;
	output	wire	[32-1:0]	S_AXI_RDATA;
	output	wire	[1:0]				S_AXI_RRESP;
	// }}}


	//
	// Declaring component data, internal wires and registers
	//
	// These declarations just copy data from the @TOP.DEFNS key
	// within the component data files.
	//


	//
	// Time to call the main module within main.v.  Remember, the purpose
	// of the main.v module is to contain all of our portable logic.
	// Things that are Xilinx (or even Altera) specific, or for that
	// matter anything that requires something other than on-off logic,
	// such as the high impedence states required by many wires, is
	// kept in this (toplevel.v) module.  Everything else goes in
	// main.v.
	//
	// We automatically place s_clk, and s_reset here.  You may need
	// to define those above.  (You did, didn't you?)  Other
	// component descriptions come from the keys @TOP.MAIN (if it
	// exists), or @MAIN.PORTLIST if it does not.
	//

	main	thedesign(s_clk, s_reset,
		// UART/host to wishbone interface
		i_wbu_uart_rx, o_wbu_uart_tx,
		// Reset wire for the ZipCPU
		(!i_cpu_resetn),
		//
		// Drive the AXI bus from an AXI-lite control
		//
		S_AXI_AWVALID,
		S_AXI_AWREADY,
		S_AXI_AWADDR,
		//
		S_AXI_WVALID,
		S_AXI_WREADY,
		S_AXI_WDATA,
		S_AXI_WSTRB,
		//
		S_AXI_BVALID,
		S_AXI_BREADY,
		S_AXI_BRESP,
		//
		S_AXI_ARVALID,
		S_AXI_ARREADY,
		S_AXI_ARADDR,
		//
		S_AXI_RVALID,
		S_AXI_RREADY,
		S_AXI_RDATA,
		S_AXI_RRESP);


	//
	// Our final section to the toplevel is used to provide all of
	// that special logic that couldnt fit in main.  This logic is
	// given by the @TOP.INSERT tag in our data files.
	//




endmodule // end of toplevel.v module definition
