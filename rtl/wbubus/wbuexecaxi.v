////////////////////////////////////////////////////////////////////////////////
//
// Filename:	wbuexecaxi.v
// {{{
// Project:	FPGA library
//
// Purpose:	This module replaces the wbuexec.v bus master with an AXI
//		version, allowing the debugging bus to drive an AXI bus using
//	the same basic bus command words.
//
// Creator:	Dan Gisselquist, Ph.D.
//		Gisselquist Technology, LLC
//
////////////////////////////////////////////////////////////////////////////////
// }}}
// Copyright (C) 2015-2022, Gisselquist Technology, LLC
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
`default_nettype none
// }}}
module	wbuexecaxi #(
		// {{{
		parameter			C_AXI_ID_WIDTH   = 1,
		parameter			C_AXI_ADDR_WIDTH = 34,
		parameter			C_AXI_DATA_WIDTH = 32,
		parameter [C_AXI_ID_WIDTH-1:0]	AXI_WRITE_ID = 0,
		parameter [C_AXI_ID_WIDTH-1:0]	AXI_READ_ID  = 0,
		parameter			LGMAXBURST   = 8
		// }}}
	) (
		// {{{
		input	wire		i_clk,
		input	wire		i_reset,
		input	wire		i_soft_reset,
		//
		// Incoming request channel
		// {{{
		input	wire		i_stb,
		input	wire	[35:0]	i_codword,
		output	reg		o_busy,
		// }}}
		//
		// Write address channel
		// {{{
		output	reg				M_AXI_AWVALID,
		input	wire				M_AXI_AWREADY,
		output	wire [C_AXI_ID_WIDTH-1:0]	M_AXI_AWID,
		output	reg  [C_AXI_ADDR_WIDTH-1:0]	M_AXI_AWADDR,
		output	wire	[7:0]			M_AXI_AWLEN,
		output	wire	[2:0]			M_AXI_AWSIZE,
		output	wire	[1:0]			M_AXI_AWBURST,
		output	wire				M_AXI_AWLOCK,
		output	wire	[3:0]			M_AXI_AWCACHE,
		output	wire	[2:0]			M_AXI_AWPROT,
		output	wire	[3:0]			M_AXI_AWQOS,
		// }}}
		//
		// Write data channel
		// {{{
		output	reg				M_AXI_WVALID,
		input	wire				M_AXI_WREADY,
		output	reg [C_AXI_DATA_WIDTH-1:0]	M_AXI_WDATA,
		output	wire [C_AXI_DATA_WIDTH/8-1:0]	M_AXI_WSTRB,
		output	wire 				M_AXI_WLAST,
		// }}}
		//
		// Write data channel
		// {{{
		input	wire				M_AXI_BVALID,
		output	wire				M_AXI_BREADY,
		input	wire [C_AXI_ID_WIDTH-1:0]	M_AXI_BID,
		input	wire	[1:0]			M_AXI_BRESP,
		// }}}
		//
		// Read address channel
		// {{{
		output	reg				M_AXI_ARVALID,
		input	wire				M_AXI_ARREADY,
		output	wire [C_AXI_ID_WIDTH-1:0]	M_AXI_ARID,
		output	reg  [C_AXI_ADDR_WIDTH-1:0]	M_AXI_ARADDR,
		output	reg	[7:0]			M_AXI_ARLEN,
		output	wire	[2:0]			M_AXI_ARSIZE,
		output	wire	[1:0]			M_AXI_ARBURST,
		output	wire				M_AXI_ARLOCK,
		output	wire	[3:0]			M_AXI_ARCACHE,
		output	wire	[2:0]			M_AXI_ARPROT,
		output	wire	[3:0]			M_AXI_ARQOS,
		// }}}
		//
		// Read data channel
		// {{{
		input	wire				M_AXI_RVALID,
		output	wire				M_AXI_RREADY,
		input	wire [C_AXI_ID_WIDTH-1:0]	M_AXI_RID,
		input	wire [C_AXI_DATA_WIDTH-1:0]	M_AXI_RDATA,
		input	wire 				M_AXI_RLAST,
		input	wire 	[1:0]			M_AXI_RRESP,
		output	wire				o_bus_active,
		// }}}
		//
		// Outgoing response codewords
		// {{{
		output	reg		o_stb,
		output	reg	[35:0]	o_codword
		// }}}
	// }}}
	);
	//
	// Design logic
	// {{{
	localparam		LSB = $clog2(C_AXI_DATA_WIDTH)-3;
	// localparam [5:0]	END_OF_WRITE = 6'h2e;
	// localparam [1:0]	WRITE_PREFIX = 2'b01;
	localparam		AW = C_AXI_ADDR_WIDTH - LSB;

	// Fixed AXI values
	// {{{
	assign	M_AXI_AWID   = AXI_WRITE_ID;
	assign	M_AXI_AWLEN  = 0;
	assign	M_AXI_AWSIZE = LSB[2:0];
	assign	M_AXI_AWLOCK = 0;
	assign	M_AXI_AWCACHE= 0;
	assign	M_AXI_AWPROT = 0;
	assign	M_AXI_AWQOS  = 0;
	// Write data channel
	assign	M_AXI_WSTRB  = -1;
	assign	M_AXI_WLAST  = 1'b1;
	// Read address channel
	assign	M_AXI_ARID   = AXI_READ_ID;
	assign	M_AXI_ARSIZE = LSB[2:0];
	assign	M_AXI_ARLOCK = 1'b0;
	assign	M_AXI_ARCACHE= 0;
	assign	M_AXI_ARPROT = 0;
	assign	M_AXI_ARQOS  = 0;
	// }}}

	// Signal delcarations
	// {{{
	localparam	LGMAXLEN = 11;
	localparam	LGMAXBURST_FIXED = (LGMAXBURST > 4) ? 4 : LGMAXBURST;
	wire	[31:0]	w_cod_data;
	reg		read_request, write_request, addr_request;

	reg		updated_addr, r_inc, read_idle, write_idle,
			no_additional_reads;
	reg	[9:0]	r_readlen;
	reg	[LGMAXLEN-1:0]	reads_outstanding, writes_outstanding;
	reg	[LGMAXBURST:0]	distance_to_boundary, initial_read_length;
	reg	[8:0]	next_read_length;
	reg	[AW-1:0]	axi_addr;
	reg	[10:0]	reads_left;
	reg		reset_flush;
	// }}}


	assign	w_cod_data={ i_codword[32:31], i_codword[29:0] };

	// x_request
	// {{{
	always @(*)
	begin
		read_request  = i_stb && i_codword[35:34] == 2'b11;
		write_request = i_stb && i_codword[35:34] == 2'b01;
		addr_request  = i_stb && i_codword[35:34] == 2'b00;

		if (i_soft_reset || reset_flush)
		begin
			read_request  = 1'b0;
			write_request = 1'b0;
			addr_request  = 1'b0;
		end
	end
	// }}}

	assign	o_bus_active = (!read_idle || !write_idle);

	// o_busy
	// {{{
	always @(*)
	begin
		o_busy = (M_AXI_RREADY || M_AXI_BREADY);
		// if (addr_request && read_idle && write_idle)
		//	o_busy = 1'b0;
		if (read_request && write_idle && !reads_outstanding[LGMAXLEN-1]
				&&((read_idle || no_additional_reads)
					   && !M_AXI_ARVALID))
			o_busy = 1'b0;
		if (write_request && read_idle && !writes_outstanding[LGMAXLEN-1]
				&&(write_idle
				|| (!M_AXI_AWVALID || M_AXI_AWREADY)
					&&(!M_AXI_WVALID || M_AXI_WREADY)))
			o_busy = 1'b0;
		if (reset_flush)
			o_busy = 1'b1;
	end
	// }}}

	// reads_left, no_additional_reads
	// {{{
	always @(*)
	if (!M_AXI_ARVALID)
		reads_left = 0;
	else
		// Verilator lint_off WIDTH
		reads_left = r_readlen - (M_AXI_ARLEN+1);
		// Verilator lint_on  WIDTH


	initial	no_additional_reads = 1;
	always @(posedge i_clk)
	if (i_reset || i_soft_reset)
		no_additional_reads <= 1;
	else if (read_request && !o_busy)
		no_additional_reads <= ({ 1'b0, initial_read_length } == i_codword[9:0]);
	else if (M_AXI_ARVALID && M_AXI_ARREADY) // && !no_additional_reads)
		no_additional_reads <= (reads_left == 0);

`ifdef	FORMAL
	always @(*)
	if (M_AXI_ARVALID)
	begin
		// assert(no_additional_reads == (reads_left == 0));
		assert(r_readlen > 0);
	end else if (!reset_flush)
		assert(no_additional_reads == (r_readlen == 0));

	always @(*)
	if (read_idle)
		assert(no_additional_reads);

	always @(*)
		assert(read_idle || write_idle);
`endif
	// }}}

	// write_idle
	// {{{
	initial	write_idle = 1;
	always @(posedge i_clk)
	if (i_reset)
		write_idle <= 1;
	else if (write_request && !o_busy)
		write_idle <= 0;
	else if (M_AXI_BVALID && M_AXI_BREADY)
		write_idle <= (!M_AXI_AWVALID && !M_AXI_WVALID)
			&& (writes_outstanding <= 1);
	// }}}

	// writes_outstanding
	// {{{
	initial	writes_outstanding = 0;
	always @(posedge i_clk)
	if (i_reset)
		writes_outstanding <= 0;
	else case({(M_AXI_AWVALID && M_AXI_AWREADY),
			M_AXI_BVALID && M_AXI_BREADY})
	2'b00: begin end
	2'b01: writes_outstanding <= writes_outstanding - 1;
	2'b10: writes_outstanding <= writes_outstanding + 1;
	2'b11: begin end
	endcase
	// }}}

	// read_idle
	// {{{
	initial	read_idle = 1;
	always @(posedge i_clk)
	if (i_reset)
		read_idle <= 1;
	else if (read_request && !o_busy)
		read_idle <= 0;
	else if (M_AXI_RVALID && M_AXI_RREADY)
		read_idle <= !M_AXI_ARVALID
			&& (no_additional_reads
				|| (i_soft_reset && !M_AXI_ARVALID))
			&& (reads_outstanding <= 1);
	// }}}

	// reads_outstanding
	// {{{
	initial	reads_outstanding = 0;
	always @(posedge i_clk)
	if (i_reset)
		reads_outstanding <= 0;
	else case({(M_AXI_ARVALID && M_AXI_ARREADY),
			M_AXI_RVALID && M_AXI_RREADY})
	2'b00: begin end
	2'b01: reads_outstanding <= reads_outstanding - 1;
	2'b10: reads_outstanding <= reads_outstanding
				+ ({ {(11-8){1'b0}}, M_AXI_ARLEN }+1);
	2'b11: reads_outstanding <= reads_outstanding
				+ { {(11-8){1'b0}}, M_AXI_ARLEN };
	endcase
	// }}}

	// iniital_read_length, distance_to_boundary
	// {{{
	always @(*)
		distance_to_boundary = { 1'b1, {(LGMAXBURST){1'b0}} }
						- axi_addr[LGMAXBURST-1:0];

	always @(*)
	begin
		if (i_codword[30])
		begin
			initial_read_length = i_codword[LGMAXBURST:0];
			if (i_codword[9:0] > { {(9-LGMAXBURST){1'b0}},
						distance_to_boundary })
				initial_read_length = distance_to_boundary;
		end else if (i_codword[9:0] >= (1<<LGMAXBURST_FIXED))
			// FIXED bursts can not exceed LGMAXBURST_FIXED words
			// at a time
			initial_read_length = (1<<LGMAXBURST_FIXED);
		else
			initial_read_length = i_codword[8:0];
	end
	// }}}

	// next_read_length
	// {{{
	always @(*)
	begin
		// Verilator lint_off WIDTH
		next_read_length = r_readlen- (M_AXI_ARVALID?(M_AXI_ARLEN+1):0);
		// Verilator lint_on WIDTH
		if (r_inc && r_readlen >= (1<<LGMAXBURST))
			next_read_length = (1<<LGMAXBURST);
		else if (!r_inc && r_readlen > (1<<LGMAXBURST_FIXED))
			next_read_length = (1<<LGMAXBURST_FIXED);
	end
	// }}}

	// r_readlen
	// {{{
	initial	r_readlen = 0;
	always @(posedge i_clk)
	if (i_reset)
		r_readlen <= 0;
	else if (read_request && !o_busy)
		r_readlen <= i_codword[9:0];
	else begin
		if (M_AXI_ARVALID && M_AXI_ARREADY)
			r_readlen <= r_readlen
				- { {(10-8){1'b0}}, M_AXI_ARLEN } -1;

		if ((!M_AXI_ARVALID || M_AXI_ARREADY)
				&& (i_soft_reset || reset_flush))
			r_readlen <= 0;
	end
	// }}}

	// xVALID, r_inc, updated_addr, axi_addr
	// {{{
	initial	M_AXI_AWVALID = 0;
	initial	M_AXI_WVALID  = 0;
	initial	M_AXI_ARVALID = 0;
	always @(posedge i_clk)
	begin
		// xVALID
		// {{{
		if (M_AXI_AWREADY)
			M_AXI_AWVALID <= 1'b0;
		if (M_AXI_WREADY)
			M_AXI_WVALID <= 1'b0;
		if (M_AXI_ARREADY)
			M_AXI_ARVALID <= 1'b0;

		if (!i_soft_reset && !reset_flush)
		begin
			if (read_request && !o_busy)
				M_AXI_ARVALID <= 1'b1;
			else if (!M_AXI_ARVALID && !no_additional_reads)
				M_AXI_ARVALID <= 1'b1;
		end

		if (write_request && !o_busy)
		begin
			M_AXI_AWVALID <= 1'b1;
			M_AXI_WVALID  <= 1'b1;
		end
		// }}}

		if (!o_busy)
			r_inc <= i_codword[30];

		if (addr_request && !o_busy)
			updated_addr <= 1;
		else if (o_busy)
			updated_addr <= 0;

		// axi_addr
		// {{{
		if (addr_request && !o_busy)
		begin
			if (i_codword[35:32] == 4'h0)
				axi_addr <= i_codword[C_AXI_ADDR_WIDTH-3:0]; //w_cod_data
			else if (i_codword[35:33] == 3'h1)
				axi_addr <= axi_addr + w_cod_data[AW-1:0];
		end else if (r_inc)
		begin
			if (M_AXI_AWVALID && M_AXI_AWREADY)
				axi_addr <= axi_addr + 1;
			else if (M_AXI_ARVALID && M_AXI_ARREADY)
				axi_addr <= axi_addr
					+ { {(AW-8){1'b0}}, M_AXI_ARLEN } + 1;
		end
		// }}}

		// AxLEN
		// {{{
		if (!M_AXI_ARVALID || M_AXI_ARREADY)
		begin
			// Verilator lint_off WIDTH
			if (no_additional_reads)
				M_AXI_ARLEN <= initial_read_length-8'h1;
			else
				M_AXI_ARLEN <= next_read_length[7:0]-8'h1;
			// Verilator lint_on  WIDTH
		end
		// }}}

		if (i_reset)
		begin
			M_AXI_AWVALID <= 0;
			M_AXI_WVALID  <= 0;
			M_AXI_ARVALID <= 0;
		end
	end
	// }}}

	always @(*)
	begin
		M_AXI_AWADDR = 0;
		M_AXI_ARADDR = 0;

		M_AXI_AWADDR[C_AXI_ADDR_WIDTH-1:LSB] = axi_addr[AW-1:0];
		M_AXI_ARADDR[C_AXI_ADDR_WIDTH-1:LSB] = axi_addr[AW-1:0];
	end

	assign	M_AXI_BREADY = !write_idle;
	assign	M_AXI_RREADY = !read_idle;

	assign	M_AXI_ARBURST = { 1'b0, r_inc };
	assign	M_AXI_AWBURST = { 1'b0, r_inc };

	always @(posedge i_clk)
	if (!M_AXI_WVALID || M_AXI_WREADY)
		M_AXI_WDATA <= w_cod_data;

	// reset_flush
	// {{{
	initial	reset_flush = 1'b0;
	always @(posedge i_clk)
	if (i_reset)
		reset_flush <= 1'b0;
	else begin
		if (i_soft_reset)
			reset_flush <= 1'b1;
		if (!M_AXI_ARVALID && !M_AXI_AWVALID && !M_AXI_WVALID
			&& !M_AXI_RREADY && !M_AXI_BREADY)
			reset_flush <= 1'b0;
	end
	// }}}

	// o_stb, o_codword
	// {{{
	initial	begin
		o_stb = 0;
		o_codword = 0;
		o_codword[35:30] = 6'h3;
	end
	always @(posedge i_clk)
	begin
		o_stb <= 0;

		if ((read_request || write_request) && !o_busy)
			o_stb <= updated_addr;
		if (M_AXI_RVALID || M_AXI_BVALID)
			o_stb <= !reset_flush;

		o_codword <= { 3'h7, M_AXI_RDATA[31:30], r_inc, M_AXI_RDATA[29:0] };
		if (read_idle && write_idle)
			// Address
			o_codword <= { 4'h2, {(32-(C_AXI_ADDR_WIDTH-2)){1'b0}}, axi_addr };
		else if (M_AXI_BVALID)
			// Write response, was it a bus error?
			o_codword[35:30] <= M_AXI_BRESP[1] ? 6'h5 : 6'h2;
		else if (M_AXI_RRESP[1])
			// Read error
			o_codword[35:30] <= 6'h5;
		// otherwise if it's a read response, we leave it as it was
		// else
		//	o_codword[35:30] <= 6'h7;

		if (i_reset || i_soft_reset)
		begin
			o_stb <= 1'b1;
			o_codword[35:30] <= 6'h3;
		end
	end
	// }}}

	////////////////////////////////////////////////////////////////////////
	// Verilator lint_off UNUSED
	// {{{
	wire	unused;
	assign	unused = &{ 1'b0, M_AXI_RLAST, M_AXI_BID, M_AXI_RID,
			M_AXI_BRESP[0], M_AXI_RRESP[0],
			next_read_length[8] };
	// Verilator lint_on  UNUSED
	// }}}
	// }}}
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
//
// Formal properties
// {{{
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
`ifdef	FORMAL
	localparam	F_LGDEPTH=12;
	reg	f_past_valid;

	initial	f_past_valid = 0;
	always @(posedge i_clk)
		f_past_valid <= 1;

	////////////////////////////////////////////////////////////////////////
	//
	// Assumptions about our command interface
	// {{{
	////////////////////////////////////////////////////////////////////////
	//
	//

	always @(posedge i_clk)
	if (!f_past_valid || $past(i_reset))
	begin
		assume(!i_stb);
		assume(i_soft_reset);
	end

	always @(posedge i_clk)
	if (f_past_valid && $past(i_stb && o_busy))
		assume(i_stb && $stable(i_codword));

	always @(posedge i_clk)
	if (read_request)
	begin
		assume(i_codword[29:10] == 0);
		assume(i_codword[33:31] == 0);
		assume(i_codword[9:0] != 0);
		assume(i_codword[9:0] <= 10'd520);
	end
	// }}}
	////////////////////////////////////////////////////////////////////////
	//
	// AXI Bus properties
	// {{{
	////////////////////////////////////////////////////////////////////////
	//
	//

	wire	[F_LGDEPTH-1:0]		faxi_awr_nbursts,
					faxi_wrid_nbursts,
					faxi_rd_nbursts, faxi_rd_outstanding,
					faxi_rdid_nbursts,
					faxi_rdid_outstanding,
					faxi_rdid_ckign_nbursts,
					faxi_rdid_ckign_outstanding;
	wire [C_AXI_ID_WIDTH-1:0]	faxi_wr_checkid, faxi_rd_checkid;
	wire				faxi_wr_ckvalid, faxi_rd_ckvalid;
	wire	[9-1:0]			faxi_wr_pending;
	//
	wire	[C_AXI_ADDR_WIDTH-1:0]	faxi_wr_addr;
	wire	[7:0]			faxi_wr_incr;
	wire	[1:0]			faxi_wr_burst;
	wire	[2:0]			faxi_wr_size;
	wire	[7:0]			faxi_wr_len;
	wire				faxi_wr_lockd;
	//
	wire	[9-1:0]			faxi_rd_cklen;
	wire	[C_AXI_ADDR_WIDTH-1:0]	faxi_rd_ckaddr;
	wire	[7:0]			faxi_rd_ckincr;
	wire	[1:0]			faxi_rd_ckburst;
	wire	[2:0]			faxi_rd_cksize;
	wire	[7-1:0]			faxi_rd_ckarlen;
	wire				faxi_rd_cklockd;

	faxi_master #(
		.C_AXI_ID_WIDTH(C_AXI_ID_WIDTH),
		.C_AXI_ADDR_WIDTH(C_AXI_ADDR_WIDTH),
		.C_AXI_DATA_WIDTH(C_AXI_DATA_WIDTH),
		.OPT_EXCLUSIVE(1'b0),
		.OPT_NARROW_BURST(1'b0),
		.F_OPT_ASSUME_RESET(1'b1),
		.F_LGDEPTH(F_LGDEPTH)
	) faxi( .i_clk(i_clk),
		.i_axi_reset_n(!i_reset),
		//
		// Write address channel
		.i_axi_awvalid(M_AXI_AWVALID),
		.i_axi_awready(M_AXI_AWREADY),
		.i_axi_awid(   M_AXI_AWID),
		.i_axi_awaddr( M_AXI_AWADDR),
		.i_axi_awlen(  M_AXI_AWLEN),
		.i_axi_awsize( M_AXI_AWSIZE),
		.i_axi_awburst(M_AXI_AWBURST),
		.i_axi_awlock( M_AXI_AWLOCK),
		.i_axi_awcache(M_AXI_AWCACHE),
		.i_axi_awprot( M_AXI_AWPROT),
		.i_axi_awqos(  M_AXI_AWQOS),
		//
		// Write data channel
		.i_axi_wvalid(M_AXI_WVALID),
		.i_axi_wready(M_AXI_WREADY),
		.i_axi_wdata( M_AXI_WDATA),
		.i_axi_wstrb( M_AXI_WSTRB),
		.i_axi_wlast( M_AXI_WLAST),
		//
		// Write response channel
		.i_axi_bvalid(M_AXI_BVALID),
		.i_axi_bready(M_AXI_BREADY),
		.i_axi_bid(   M_AXI_BID),
		.i_axi_bresp( M_AXI_BRESP),
		//
		// Read address channel
		.i_axi_arvalid(M_AXI_ARVALID),
		.i_axi_arready(M_AXI_ARREADY),
		.i_axi_arid(   M_AXI_ARID),
		.i_axi_araddr( M_AXI_ARADDR),
		.i_axi_arlen(  M_AXI_ARLEN),
		.i_axi_arsize( M_AXI_ARSIZE),
		.i_axi_arburst(M_AXI_ARBURST),
		.i_axi_arlock( M_AXI_ARLOCK),
		.i_axi_arcache(M_AXI_ARCACHE),
		.i_axi_arprot( M_AXI_ARPROT),
		.i_axi_arqos(  M_AXI_ARQOS),
		//
		// Read response channel
		.i_axi_rvalid(M_AXI_RVALID),
		.i_axi_rready(M_AXI_RREADY),
		.i_axi_rid(   M_AXI_RID),
		.i_axi_rdata( M_AXI_RDATA),
		.i_axi_rlast( M_AXI_RLAST),
		.i_axi_rresp( M_AXI_RRESP),
		//
		// Induction values
		//
		.f_axi_awr_nbursts(faxi_awr_nbursts),
		.f_axi_wr_pending(faxi_wr_pending),
		.f_axi_rd_nbursts(faxi_rd_nbursts),
		.f_axi_rd_outstanding(faxi_rd_outstanding),
		//
		.f_axi_wr_checkid(faxi_wr_checkid),
		.f_axi_wr_ckvalid(faxi_wr_ckvalid),
		.f_axi_wrid_nbursts(faxi_wrid_nbursts),
		.f_axi_wr_addr(faxi_wr_addr),
		.f_axi_wr_incr(faxi_wr_incr),
		.f_axi_wr_burst(faxi_wr_burst),
		.f_axi_wr_size(faxi_wr_size),
		.f_axi_wr_len(faxi_wr_len),
		.f_axi_wr_lockd(faxi_wr_lockd),
		//
		//
		.f_axi_rd_checkid(  faxi_rd_checkid),
		.f_axi_rd_ckvalid(  faxi_rd_ckvalid),
		.f_axi_rd_ckaddr(   faxi_rd_ckaddr),
		.f_axi_rd_ckincr(   faxi_rd_ckincr),
		.f_axi_rd_ckburst(  faxi_rd_ckburst),
		.f_axi_rd_cksize(   faxi_rd_cksize),
		.f_axi_rd_ckarlen(  faxi_rd_ckarlen),
		.f_axi_rd_cklockd(  faxi_rd_cklockd),
		//
		.f_axi_rdid_nbursts(faxi_rdid_nbursts),
		.f_axi_rdid_outstanding(faxi_rdid_outstanding),
		.f_axi_rdid_ckign_nbursts(faxi_rdid_ckign_nbursts),
		.f_axi_rdid_ckign_outstanding(faxi_rdid_ckign_outstanding)
	);

	// }}}
	////////////////////////////////////////////////////////////////////////
	//
	// Assertions about our write interface
	// {{{
	////////////////////////////////////////////////////////////////////////
	//
	//

	always @(*)
	begin
		assume(faxi_wr_checkid == AXI_WRITE_ID);
		assert({ 1'b0, writes_outstanding } == faxi_awr_nbursts);
		if (writes_outstanding > 0)
			assert(read_idle);
		assert(faxi_awr_nbursts == faxi_wrid_nbursts);
		if (M_AXI_AWVALID || write_idle)
			assert(faxi_wr_pending == 0);
		else
			assert(faxi_wr_pending <= 1);

		if (faxi_wr_pending > 0)
			assert(M_AXI_WVALID);

		if (faxi_wr_ckvalid)
		begin
			assert(faxi_wr_size == M_AXI_AWSIZE);
			assert(!faxi_wr_burst[1]);
			assert(faxi_wr_len == 0);
			assert(!faxi_wr_lockd);
		end
	end
	// }}}
	////////////////////////////////////////////////////////////////////////
	//
	// Assertions about our read interface
	// {{{
	////////////////////////////////////////////////////////////////////////
	//
	//
	reg	[C_AXI_ADDR_WIDTH-1:0] f_next_read_address;
	reg		f_next_read_aligned;

	always @(*)
		f_next_read_address = M_AXI_ARADDR +((M_AXI_ARLEN+1) << LSB);
	always @(*)
		f_next_read_aligned = (f_next_read_address[LGMAXBURST+LSB-1:0] == 0);

	always @(*)
	begin
		assume(faxi_rd_checkid == AXI_READ_ID);
		assert(reads_outstanding == faxi_rd_outstanding);
		assert(reads_outstanding+{1'b0, r_readlen}
			< 10'h208 + (1<<(LGMAXLEN-1)));
		assert(reads_outstanding+(M_AXI_ARVALID ? (M_AXI_ARLEN + 1) : 0)
			< 10'h208 + (1<<(LGMAXLEN-1)));
		if (reads_outstanding > 0)
			assert(write_idle);
		if (faxi_rd_ckvalid)
		begin
			assert(faxi_rd_cksize == M_AXI_AWSIZE);
			assert(!faxi_rd_ckburst[1]);
			assert(!faxi_rd_cklockd);
			// cklen & ckarlen need to be checked
		end

		assert(faxi_rdid_outstanding == reads_outstanding);
		assert(r_readlen <= 10'd520); //

		if (M_AXI_ARVALID && !reset_flush)
		begin
			assert(r_readlen >= (M_AXI_ARLEN+1));
			if (r_inc && !f_next_read_aligned)
				assert(r_readlen == (M_AXI_ARLEN+1));
		end
	end

	always @(posedge i_clk)
	if (!f_past_valid || $past(i_reset) || $past(i_soft_reset))
	begin
		// Always return a reset strobe following a reset--either
		// hard or soft
		assert(o_stb == f_past_valid);
		assert(o_codword[35:30] == 6'h3);
	end else if ($past(reset_flush))
		assert(!o_stb);
	else if ($past(M_AXI_BVALID && M_AXI_BRESP[1])
			||$past(M_AXI_RVALID && M_AXI_RRESP[1]))
	begin
		// Bus error
		assert(o_stb);
		assert(o_codword[35:30] == 6'h5);
	end else if ($past(M_AXI_BVALID))
	begin
		assert(o_stb);
		assert(o_codword[35:30] == 6'h2);
	end else if ($past(M_AXI_RVALID))
	begin
		assert(o_stb);
	end else if ($past(updated_addr && !o_busy && (read_request || write_request)))
		assert(o_stb);
	else
		assert(!o_stb);

	always @(*)
	if (reset_flush)
		assert(o_busy);
	// }}}

	////////////////////////////////////////////////////////////////////////
	//
	// Cover checks
	// {{{
	////////////////////////////////////////////////////////////////////////
	//
	//
	reg	[3:0]	cvr_writes, cvr_reads, cvr_read_bursts;
	reg		cvr_write_flush, cvr_read_flush;
	reg	[3:0]	cvr_read_reqs;
	(* anyconst *) reg fcvr_read_burst_only;


	// Count write responses
	// {{{
	initial	cvr_writes = 0;
	always @(posedge i_clk)
	if (i_reset)
		cvr_writes <= 0;
	else if (M_AXI_BVALID && M_AXI_BREADY
			&& !M_AXI_BRESP[1] && !cvr_writes[3])
		cvr_writes <= cvr_writes  + 1;
	// }}}


	// Count read data returns
	// {{{
	initial	cvr_reads = 0;
	always @(posedge i_clk)
	if (i_reset)
		cvr_reads <= 0;
	else if (M_AXI_RVALID && M_AXI_RREADY
			&& M_AXI_RLAST && !M_AXI_RRESP[1] && !cvr_reads[3])
		cvr_reads <= cvr_reads  + 1;
	// }}}

	// Look for a flush in the middle of a write
	// {{{
	initial	cvr_write_flush = 0;
	always @(posedge i_clk)
	if (i_reset)
		cvr_write_flush <= 1'b0;
	else if (i_soft_reset && M_AXI_BREADY && !M_AXI_BVALID)
		cvr_write_flush <= 1'b1;
	// }}}

	// Look for a flush mid read
	// {{{
	initial	cvr_read_flush = 0;
	always @(posedge i_clk)
	if (i_reset)
		cvr_read_flush <= 1'b0;
	else if (i_soft_reset && M_AXI_RREADY && !M_AXI_RVALID
			&& reads_outstanding > 1)
		cvr_read_flush <= 1'b1;
	// }}}

	// If fcvr_read_burst_only, then only look for read bursts of len >= 4
	// {{{
	always @(*)
	if (fcvr_read_burst_only && M_AXI_ARVALID)
		assume(M_AXI_ARLEN >= 3);
	// }}}

	// Count the number of read requests (not responses)
	// {{{
	initial	cvr_read_reqs = 0;
	always @(posedge i_clk)
	if (i_reset || !fcvr_read_burst_only)
		cvr_read_reqs <= 0;
	else if (read_request && !o_busy)
		cvr_read_reqs <= cvr_read_reqs  + 1;
	// }}}

	// Count the number of RLAST values marking the end of read bursts
	// {{{
	initial	cvr_read_bursts = 0;
	always @(posedge i_clk)
	if (i_reset || !fcvr_read_burst_only)
		cvr_read_bursts <= 0;
	else if (M_AXI_RVALID && M_AXI_RREADY && M_AXI_RLAST
			&& !M_AXI_RRESP[1] && !cvr_read_bursts[3])
		cvr_read_bursts <= cvr_read_bursts  + 1;
	// }}}

	always @(*)
	if (!i_reset)
	begin
		// Cover one beat
		// {{{
		cover(cvr_writes ==1 && faxi_awr_nbursts == 0);
		cover(cvr_reads ==1 && faxi_rd_nbursts == 0);
		cover(cvr_read_bursts ==1 && faxi_rd_nbursts == 0);
		// }}}

		// Two write beats, or two read bursts
		// {{{
		cover(cvr_writes == 2 && faxi_awr_nbursts == 0);
		cover(cvr_reads == 2  && faxi_rd_nbursts == 0);
		cover(cvr_read_bursts == 2 && faxi_rd_nbursts == 0);
		cover(cvr_read_bursts == 2 && cvr_read_reqs == 1 && faxi_rd_nbursts == 0);
		cover(cvr_read_bursts == 2 && cvr_read_reqs  == 1 && faxi_rd_nbursts == 0);
		// }}}

		// More than two write beats, or more than two read bursts/beats
		// {{{
		cover(cvr_writes > 2 && faxi_awr_nbursts == 0);
		cover(cvr_reads > 2 && faxi_rd_nbursts == 0);
		cover(cvr_read_bursts > 2 && faxi_rd_nbursts == 0);

		cover(cvr_read_bursts > 2 && cvr_read_reqs  == 1 && faxi_rd_nbursts == 0);
		// }}}

		// Make sure we can flush the interface and return to idle
		// {{{
		cover(cvr_write_flush && read_idle && write_idle);
		cover(cvr_read_flush  && read_idle && write_idle);
		// }}}
	end
	// }}}
	////////////////////////////////////////////////////////////////////////
	//
	// Careless (constraining) assumptions
	// {{{
	////////////////////////////////////////////////////////////////////////
	//
	//

	// }}}
`endif // FORMAL
// }}}
endmodule
