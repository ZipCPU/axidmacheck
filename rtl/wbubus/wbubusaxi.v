////////////////////////////////////////////////////////////////////////////////
//
// Filename:	wbubusaxi.v
//
// Project:	FPGA library
//
// Purpose:	This is the top level file for the entire JTAG-USB to bus
//		conversion.  (It's also the place to start debugging, should
//	things not go as planned.)  Bytes come into this routine, bytes go out,
//	and the bus (external to this routine) is commanded in between.
//
//	This particular version of, what was originally called a "Wishbone
//	to UART" bridge, has been modified to issue AXI transactions based
//	upon the same character interface the Wishbone version used.  The
//	only real difference is the type of bus the design drives.
//
//
// Creator:	Dan Gisselquist, Ph.D.
//		Gisselquist Technology, LLC
//
////////////////////////////////////////////////////////////////////////////////
//
// Copyright (C) 2015-2020, Gisselquist Technology, LLC
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
`default_nettype	none
//
module	wbubusaxi(i_clk, i_reset, i_rx_stb, i_rx_data, 
		//
		// AXI Write address channel
		M_AXI_AWVALID, M_AXI_AWREADY, M_AXI_AWID, M_AXI_AWADDR,
			M_AXI_AWLEN, M_AXI_AWSIZE, M_AXI_AWBURST,
			M_AXI_AWLOCK, M_AXI_AWCACHE, M_AXI_AWPROT, M_AXI_AWQOS,
		//
		// AXI Write data channel
		M_AXI_WVALID, M_AXI_WREADY, M_AXI_WDATA, M_AXI_WSTRB,
			M_AXI_WLAST,
		//
		// AXI Write data channel
		M_AXI_BVALID, M_AXI_BREADY, M_AXI_BID, M_AXI_BRESP,
		//
		// AXI Read address channel
		M_AXI_ARVALID, M_AXI_ARREADY, M_AXI_ARID, M_AXI_ARADDR,
			M_AXI_ARLEN, M_AXI_ARSIZE, M_AXI_ARBURST,
			M_AXI_ARLOCK, M_AXI_ARCACHE, M_AXI_ARPROT, M_AXI_ARQOS,
		//
		// AXI Read data channel
		M_AXI_RVALID, M_AXI_RREADY, M_AXI_RID, M_AXI_RDATA,
			M_AXI_RLAST, M_AXI_RRESP,
		i_interrupt,
		o_tx_stb, o_tx_data, i_tx_busy);
	parameter	C_AXI_ADDR_WIDTH = 32,
			C_AXI_DATA_WIDTH =32,
			C_AXI_ID_WIDTH = 1;
	parameter	LGINPUT_FIFO=6,
			LGOUTPUT_FIFO=10;
	input	wire		i_clk;
	input	wire		i_reset;	// AXI *REQUIRES* a reset
	input	wire		i_rx_stb;
	input	wire	[7:0]	i_rx_data;
	//
	//
	// Write address channel
	output	wire				M_AXI_AWVALID;
	input	wire				M_AXI_AWREADY;
	output	wire [C_AXI_ID_WIDTH-1:0]	M_AXI_AWID;
	output	wire  [C_AXI_ADDR_WIDTH-1:0]	M_AXI_AWADDR;
	output	wire	[7:0]			M_AXI_AWLEN;
	output	wire	[2:0]			M_AXI_AWSIZE;
	output	wire	[1:0]			M_AXI_AWBURST;
	output	wire				M_AXI_AWLOCK;
	output	wire	[3:0]			M_AXI_AWCACHE;
	output	wire	[2:0]			M_AXI_AWPROT;
	output	wire	[3:0]			M_AXI_AWQOS;
	//
	// Write data channel
	output	wire				M_AXI_WVALID;
	input	wire				M_AXI_WREADY;
	output	wire [C_AXI_DATA_WIDTH-1:0]	M_AXI_WDATA;
	output	wire [C_AXI_DATA_WIDTH/8-1:0]	M_AXI_WSTRB;
	output	wire 				M_AXI_WLAST;
	//
	// Write data channel
	input	wire				M_AXI_BVALID;
	output	wire				M_AXI_BREADY;
	input	wire [C_AXI_ID_WIDTH-1:0]	M_AXI_BID;
	input	wire	[1:0]			M_AXI_BRESP;
	//
	// Read address channel
	output	wire				M_AXI_ARVALID;
	input	wire				M_AXI_ARREADY;
	output	wire [C_AXI_ID_WIDTH-1:0]	M_AXI_ARID;
	output	wire  [C_AXI_ADDR_WIDTH-1:0]	M_AXI_ARADDR;
	output	wire	[7:0]			M_AXI_ARLEN;
	output	wire	[2:0]			M_AXI_ARSIZE;
	output	wire	[1:0]			M_AXI_ARBURST;
	output	wire				M_AXI_ARLOCK;
	output	wire	[3:0]			M_AXI_ARCACHE;
	output	wire	[2:0]			M_AXI_ARPROT;
	output	wire	[3:0]			M_AXI_ARQOS;
	//
	// Read data channel
	input	wire				M_AXI_RVALID;
	output	wire				M_AXI_RREADY;
	input	wire [C_AXI_ID_WIDTH-1:0]	M_AXI_RID;
	input	wire [C_AXI_DATA_WIDTH-1:0]	M_AXI_RDATA;
	input	wire 				M_AXI_RLAST;
	input	wire 	[1:0]			M_AXI_RRESP;
	//
	input	wire		i_interrupt;
	output	wire		o_tx_stb;
	output	wire	[7:0]	o_tx_data;
	input	wire		i_tx_busy;
	// output	wire		o_dbg;

	wire	soft_reset;

	// Decode ASCII input requests into WB bus cycle requests
	wire		in_stb;
	wire	[35:0]	in_word;
	wbuinput	getinput(i_clk, i_reset, i_rx_stb, i_rx_data,
				soft_reset, in_stb, in_word);

	wire		w_bus_busy, fifo_in_stb, exec_stb, bus_active;
	wire	[35:0]	fifo_in_word, exec_word;

	generate
	if (LGINPUT_FIFO < 2)
	begin : NO_INPUT_FIFO

	assign	fifo_in_stb = in_stb;
	assign	fifo_in_word = in_word;

	end else begin : INPUT_FIFO

		wire		ififo_empty_n, ififo_err;
		assign	fifo_in_stb = ififo_empty_n;
		wbufifo	#(36,LGINPUT_FIFO) padififo(i_clk, soft_reset,
				in_stb, in_word,
				(!w_bus_busy), fifo_in_word,
				ififo_empty_n, ififo_err);

		// verilator lint_off UNUSED
		wire	gen_unused;
		assign	gen_unused = ififo_err;
		// verilator lint_on  UNUSED
	end endgenerate

	// Take requests in, Run the bus, send results out
	// This only works if no requests come in while requests
	// are pending.
	wbuexecaxi #(
		.C_AXI_ADDR_WIDTH(C_AXI_ADDR_WIDTH),
		.C_AXI_DATA_WIDTH(C_AXI_DATA_WIDTH),
		.C_AXI_ID_WIDTH(C_AXI_ID_WIDTH)
	) runaxi(i_clk, i_reset, soft_reset,
		fifo_in_stb, fifo_in_word, w_bus_busy,
		//
		// AXI Write address channel
		M_AXI_AWVALID, M_AXI_AWREADY, M_AXI_AWID, M_AXI_AWADDR,
			M_AXI_AWLEN, M_AXI_AWSIZE, M_AXI_AWBURST,
			M_AXI_AWLOCK, M_AXI_AWCACHE, M_AXI_AWPROT, M_AXI_AWQOS,
		//
		// AXI Write data channel
		M_AXI_WVALID, M_AXI_WREADY, M_AXI_WDATA, M_AXI_WSTRB,
			M_AXI_WLAST,
		//
		// AXI Write data channel
		M_AXI_BVALID, M_AXI_BREADY, M_AXI_BID, M_AXI_BRESP,
		//
		// AXI Read address channel
		M_AXI_ARVALID, M_AXI_ARREADY, M_AXI_ARID, M_AXI_ARADDR,
			M_AXI_ARLEN, M_AXI_ARSIZE, M_AXI_ARBURST,
			M_AXI_ARLOCK, M_AXI_ARCACHE, M_AXI_ARPROT, M_AXI_ARQOS,
		//
		// AXI Read data channel
		M_AXI_RVALID, M_AXI_RREADY, M_AXI_RID, M_AXI_RDATA,
			M_AXI_RLAST, M_AXI_RRESP,
		bus_active,
		exec_stb, exec_word);

	wire		ofifo_err;
	// wire	[30:0]	out_dbg;
	wbuoutput #(LGOUTPUT_FIFO) wroutput(i_clk, i_reset, soft_reset,
			exec_stb, exec_word,
			bus_active, i_interrupt, exec_stb,
			o_tx_stb, o_tx_data, i_tx_busy, ofifo_err);
	// verilator lint_off UNUSED
	wire	ofifo_unused;
	assign	ofifo_unused = ofifo_err;
	// verilator lint_on  UNUSED

endmodule

