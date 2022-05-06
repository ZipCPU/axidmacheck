////////////////////////////////////////////////////////////////////////////////
//
// Filename:	axiuartbus.v
// {{{
// Project:	FPGA library
//
// Purpose:	This is the top level file for the entire JTAG-USB to Wishbone
//		bus conversion.  (It's also the place to start debugging, should
//	things not go as planned.)  Bytes come into this routine, bytes go out,
//	and the wishbone bus (external to this routine) is commanded in between.
//
//	You may find some strong similarities between this module and the
//	wbubus module.  They two are essentially the same, with the exception
//	that this version will also multiplex a serial port together with
//	the JTAG-USB->wishbone conversion.  Graphically:
//
//	devbus  -> TCP/IP	\			/ -> WB master
//				MUXED over USB -> UART
//	console -> TCP/IP	/			\ -> wbuconsole
//
//	Doing this, however, also entails stripping the 8th bit from the UART
//	port, so the serial port so contrived can only handle 7-bit data. 
//
// Creator:	Dan Gisselquist, Ph.D.
//		Gisselquist Technology, LLC
//
////////////////////////////////////////////////////////////////////////////////
// }}}
// Copyright (C) 2015-2022, Gisselquist Technology, LLC
// {{{
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
// }}}
// License:	GPL, v3, as defined and found on www.gnu.org,
// {{{
//		http://www.gnu.org/licenses/gpl.html
//
////////////////////////////////////////////////////////////////////////////////
//
`default_nettype	none
// }}}
module	axiuartbus #(
		// {{{
		parameter	C_AXI_ID_WIDTH=2,
		parameter	C_AXI_ADDR_WIDTH=32,
		parameter	C_AXI_DATA_WIDTH=32,
		parameter	LGINPUT_FIFO=6,
				LGOUTPUT_FIFO=10,
		parameter [0:0] CMD_PORT_OFF_UNTIL_ACCESSED = 1'b1
		// }}}
	) (
		// {{{
		input	wire		S_AXI_ACLK,
		input	wire		S_AXI_ARESETN,
		// RX
		// {{{
		input	wire		i_rx_stb,
		input	wire	[7:0]	i_rx_data,
		// }}}
		// AXI master
		// {{{
		// AXI Write address channel
		output	wire				M_AXI_AWVALID,
		input	wire				M_AXI_AWREADY,
		output	wire	[C_AXI_ID_WIDTH-1:0]	M_AXI_AWID,
		output	wire	[C_AXI_ADDR_WIDTH-1:0]	M_AXI_AWADDR,
		output	wire	[7:0]			M_AXI_AWLEN,
		output	wire	[2:0]			M_AXI_AWSIZE,
		output	wire	[1:0]			M_AXI_AWBURST,
		output	wire				M_AXI_AWLOCK,
		output	wire	[3:0]			M_AXI_AWCACHE,
		output	wire	[2:0]			M_AXI_AWPROT,
		output	wire	[3:0]			M_AXI_AWQOS,
		//
		// AXI Write data channel
		output	wire				M_AXI_WVALID,
		input	wire				M_AXI_WREADY,
		output	wire	[C_AXI_DATA_WIDTH-1:0]	M_AXI_WDATA,
		output	wire [C_AXI_DATA_WIDTH/8-1:0]	M_AXI_WSTRB,
		output	wire	M_AXI_WLAST,
		//
		// AXI Write data channel
		input	wire				M_AXI_BVALID,
		output	wire				M_AXI_BREADY,
		input	wire	[C_AXI_ID_WIDTH-1:0]	M_AXI_BID,
		input	wire	[1:0]			M_AXI_BRESP,
		//
		// AXI Read address channel
		output	wire				M_AXI_ARVALID,
		input	wire				M_AXI_ARREADY,
		output	wire	[C_AXI_ID_WIDTH-1:0]	M_AXI_ARID,
		output	wire	[C_AXI_ADDR_WIDTH-1:0]	M_AXI_ARADDR,
		output	wire	[7:0]			M_AXI_ARLEN,
		output	wire	[2:0]			M_AXI_ARSIZE,
		output	wire	[1:0]			M_AXI_ARBURST,
		output	wire				M_AXI_ARLOCK,
		output	wire	[3:0]			M_AXI_ARCACHE,
		output	wire	[2:0]			M_AXI_ARPROT,
		output	wire	[3:0]			M_AXI_ARQOS,
		//
		// AXI Read data channel
		input	wire				M_AXI_RVALID,
		output	wire				M_AXI_RREADY,
		input	wire	[C_AXI_ID_WIDTH-1:0]	M_AXI_RID,
		input	wire	[C_AXI_DATA_WIDTH-1:0]	M_AXI_RDATA,
		input	wire				M_AXI_RLAST,
		input	wire	[1:0]			M_AXI_RRESP,
		// }}}
		input	wire				i_interrupt,
		// TX
		// {{{
		output	wire		o_tx_stb,
		output	wire	[7:0]	o_tx_data,
		input	wire		i_tx_busy,
		// }}}
		// CONSOLE
		// {{{
		input	wire		i_console_stb,
		input	wire	[6:0]	i_console_data,
		output	wire		o_console_busy,
		//
		output	reg		o_console_stb,
		output	reg	[6:0]	o_console_data
		// }}}
		// }}}
	);

	// Local declarations
	// {{{
	wire		i_clk = S_AXI_ACLK;
	wire		i_reset = !S_AXI_ARESETN;
	wire		soft_reset;
	wire		cmd_port_active;
	wire		in_stb, in_active, in_busy;
	wire	[35:0]	in_word;
	wire		w_bus_busy, fifo_in_stb, exec_stb, w_bus_reset;
	wire	[35:0]	fifo_in_word, exec_word, ofifo_word;
	reg		ps_full;
	reg	[7:0]	ps_data;
	wire		wbu_tx_stb, wbu_tx_active, out_busy;
	wire	[7:0]	wbu_tx_data;
	wire		bus_active;

	wire		ofifo_empty_n, ofifo_err, ofifo_wr, ofifo_rd;
	// }}}
	////////////////////////////////////////////////////////////////////////
	//
	// Forward console inputs to the console
	// {{{
	////////////////////////////////////////////////////////////////////////
	//
	//
	initial	o_console_stb = 1'b0;
	always @(posedge i_clk)
		o_console_stb <= (i_rx_stb)&&(i_rx_data[7] == 1'b0);

	always @(posedge i_clk)
		o_console_data <= i_rx_data[6:0];
	// }}}

	// cmd_port_active
	// {{{
	generate if (CMD_PORT_OFF_UNTIL_ACCESSED)
	begin

		reg	r_cmd_port_active;

		initial	r_cmd_port_active = 1'b0;
		always @(posedge i_clk)
		if (i_rx_stb && i_rx_data[7])
			r_cmd_port_active <= 1'b1;

		assign	cmd_port_active = r_cmd_port_active;

	end else begin

		assign	cmd_port_active = 1'b1;

	end endgenerate
	// }}}

	////////////////////////////////////////////////////////////////////////
	//
	// Decode ASCII input requests into bus cycle requests
	// {{{
	////////////////////////////////////////////////////////////////////////
	//
	//
	wbuinput
	getinput(
		// {{{
		.i_clk(i_clk), .i_reset(i_reset),
		.i_stb(i_rx_stb && i_rx_data[7]), .o_busy(in_busy),
			.i_byte({ 1'b0, i_rx_data[6:0] }),
		.o_soft_reset(soft_reset),
		.o_stb(in_stb), .i_busy(1'b0),
			.o_codword(in_word), .o_active(in_active)
		// }}}
	);
	// }}}
	////////////////////////////////////////////////////////////////////////
	//
	// The input FIFO
	// {{{
	////////////////////////////////////////////////////////////////////////
	//
	//
	generate if (LGINPUT_FIFO < 2)
	begin : NO_INPUT_FIFO

		assign	fifo_in_stb = in_stb;
		assign	fifo_in_word = in_word;
		assign	w_bus_reset = soft_reset;

	end else begin : INPUT_FIFO

		wire		ififo_empty_n, ififo_err;

		assign	fifo_in_stb = ififo_empty_n;
		assign	w_bus_reset = soft_reset;

		wbufifo	#(
			// {{{
			.BW(36),.LGFLEN(LGINPUT_FIFO)
			// }}}
		) padififo(
			// {{{
			.i_clk(i_clk), .i_reset(w_bus_reset),
			.i_wr(in_stb), .i_data(in_word),
			.i_rd(fifo_in_stb && !w_bus_busy),
				.o_data(fifo_in_word),
			.o_empty_n(ififo_empty_n), .o_err(ififo_err)
			// }}}
		);

		// verilator lint_off UNUSED
		wire	gen_unused;
		assign	gen_unused = ififo_err;
		// verilator lint_on  UNUSED
	end endgenerate
	// }}}
	////////////////////////////////////////////////////////////////////////
	//
	// Run the bus
	// {{{
	////////////////////////////////////////////////////////////////////////
	//
	//

	// Take requests in, Run the bus, send results out
	// This only works if no requests come in while requests
	// are pending.
	wbuexecaxi #(
		// {{{
		.C_AXI_ADDR_WIDTH(C_AXI_ADDR_WIDTH),
		.C_AXI_DATA_WIDTH(C_AXI_DATA_WIDTH),
		.C_AXI_ID_WIDTH(C_AXI_ID_WIDTH)
		// }}}
	) runaxi(
		// {{{
		.i_clk(S_AXI_ACLK), .i_reset(!S_AXI_ARESETN),
			.i_soft_reset(soft_reset),
		.i_stb(fifo_in_stb), .i_codword(fifo_in_word),
				.o_busy(w_bus_busy),
		//
		// AXI Write address channel
		// {{{
		.M_AXI_AWVALID(M_AXI_AWVALID), .M_AXI_AWREADY(M_AXI_AWREADY),
			.M_AXI_AWID(M_AXI_AWID), .M_AXI_AWADDR(M_AXI_AWADDR),
			.M_AXI_AWLEN(M_AXI_AWLEN), .M_AXI_AWSIZE(M_AXI_AWSIZE),
			.M_AXI_AWBURST(M_AXI_AWBURST),
			.M_AXI_AWLOCK(M_AXI_AWLOCK),
			.M_AXI_AWCACHE(M_AXI_AWCACHE),
			.M_AXI_AWPROT(M_AXI_AWPROT),
			.M_AXI_AWQOS(M_AXI_AWQOS),
		// }}}
		// AXI Write data channel
		// {{{
		.M_AXI_WVALID(M_AXI_WVALID), .M_AXI_WREADY(M_AXI_WREADY),
			.M_AXI_WDATA(M_AXI_WDATA), .M_AXI_WSTRB(M_AXI_WSTRB),
			.M_AXI_WLAST(M_AXI_WLAST),
		// }}}
		// AXI Write data channel
		// {{{
		.M_AXI_BVALID(M_AXI_BVALID), .M_AXI_BREADY(M_AXI_BREADY),
			.M_AXI_BID(M_AXI_BID), .M_AXI_BRESP(M_AXI_BRESP),
		// }}}
		// AXI Read address channel
		// {{{
		.M_AXI_ARVALID(M_AXI_ARVALID), .M_AXI_ARREADY(M_AXI_ARREADY),
			.M_AXI_ARID(M_AXI_ARID), .M_AXI_ARADDR(M_AXI_ARADDR),
			.M_AXI_ARLEN(M_AXI_ARLEN), .M_AXI_ARSIZE(M_AXI_ARSIZE),
			.M_AXI_ARBURST(M_AXI_ARBURST),
			.M_AXI_ARLOCK(M_AXI_ARLOCK),
			.M_AXI_ARCACHE(M_AXI_ARCACHE),
			.M_AXI_ARPROT(M_AXI_ARPROT),
			.M_AXI_ARQOS(M_AXI_ARQOS),
		// }}}
		// AXI Read data channel
		// {{{
		.M_AXI_RVALID(M_AXI_RVALID), .M_AXI_RREADY(M_AXI_RREADY),
			.M_AXI_RID(M_AXI_RID), .M_AXI_RDATA(M_AXI_RDATA),
			.M_AXI_RLAST(M_AXI_RLAST), .M_AXI_RRESP(M_AXI_RRESP),
		// }}}
		.o_bus_active(bus_active),
		.o_stb(exec_stb), .o_codword(exec_word)
		// }}}
	);


	// }}}
	////////////////////////////////////////////////////////////////////////
	//
	// Output FIFO
	// {{{
	////////////////////////////////////////////////////////////////////////
	//
	//

	assign	ofifo_wr    = ofifo_empty_n;
	assign	ofifo_rd    = ofifo_empty_n && !out_busy;
		// .i_stb(exec_stb), .o_busy(out_busy), .i_codword(exec_word),
	assign	w_bus_reset = soft_reset;

	wbufifo	#(
		// {{{
		.BW(36),.LGFLEN(LGOUTPUT_FIFO)
		// }}}
	) ofifo (
		// {{{
		.i_clk(i_clk), .i_reset(w_bus_reset),
		.i_wr(exec_stb), .i_data(exec_word),
		.i_rd(ofifo_rd),
			.o_data(ofifo_word),
		.o_empty_n(ofifo_empty_n), .o_err(ofifo_err)
		// }}}
	);

	// }}}
	////////////////////////////////////////////////////////////////////////
	//
	// Encode the outputs
	// {{{
	////////////////////////////////////////////////////////////////////////
	//
	//

	wbuoutput #(
		.OPT_COMPRESSION(1'b1), .OPT_IDLES(1'b1)
	) wroutput(
		// {{{
		.i_clk(i_clk), .i_reset(i_reset), .i_soft_reset(w_bus_reset),
		.i_stb(ofifo_rd), .o_busy(out_busy), .i_codword(ofifo_word),
		.i_wb_cyc(bus_active), .i_int(i_interrupt), .i_bus_busy(exec_stb),
		.o_stb(wbu_tx_stb), .o_active(wbu_tx_active),
		.o_char(wbu_tx_data), .i_tx_busy(ps_full)
		// }}}
	);
	// }}}
	////////////////////////////////////////////////////////////////////////
	//
	// Arbitrate between the two outputs, console and dbg bus
	// {{{
	////////////////////////////////////////////////////////////////////////
	//
	//
	initial	ps_full = 1'b0;
	always @(posedge i_clk)
	if (!ps_full)
	begin
		if (cmd_port_active && wbu_tx_stb)
		begin
			ps_full <= 1'b1;
			ps_data <= { 1'b1, wbu_tx_data[6:0] };
		end else if (i_console_stb)
		begin
			ps_full <= 1'b1;
			ps_data <= { 1'b0, i_console_data[6:0] };
		end
	end else if (!i_tx_busy)
		ps_full <= 1'b0;

	assign	o_tx_stb = ps_full;
	assign	o_tx_data = ps_data;
	assign	o_console_busy = (wbu_tx_stb && cmd_port_active)||(ps_full);
	// }}}

	// Make verilator happy
	// {{{
	// verilator lint_off UNUSED
	wire	unused;
	assign	unused = &{ 1'b0, wbu_tx_data[7], in_active,
				out_busy, wbu_tx_active };
	// verilator lint_on  UNUSED
	// }}}
endmodule

