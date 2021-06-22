////////////////////////////////////////////////////////////////////////////////
//
// Filename: 	axilconsole.v
// {{{
// Project:	ZBasic, a generic toplevel impl using the full ZipCPU
//
// Purpose:	Unlilke wbuart-insert.v, this is a full blown wishbone core
//		with integrated FIFO support to support the UART transmitter
//	and receiver found within here.  As a result, it's usage may be
//	heavier on the bus than the insert, but it may also be more useful.
//
// Creator:	Dan Gisselquist, Ph.D.
//		Gisselquist Technology, LLC
//
////////////////////////////////////////////////////////////////////////////////
// }}}
// Copyright (C) 2015-2021, Gisselquist Technology, LLC
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
module	axilconsole #(
		// {{{
		// LGFLEN: The log (based two) of our FIFOs size.  Maxes out
		// at 10, representing a FIFO length of 1024.
		parameter [3:0]	LGFLEN = 4,
		// Size of the AXI-lite bus.  These are fixed, since 1) AXI-lite
		// is fixed at a width of 32-bits by Xilinx def'n, and 2) since
		// we only ever have 4 configuration words.
		parameter	C_AXI_ADDR_WIDTH = 4,
		localparam	C_AXI_DATA_WIDTH = 32,
		parameter [0:0]	OPT_SKIDBUFFER = 1'b0,
		parameter [0:0]	OPT_LOWPOWER = 0,
		localparam	ADDRLSB = $clog2(C_AXI_DATA_WIDTH)-3
		// }}}
	) (
		// AXI-lite signaling
		// {{{
		input	wire					S_AXI_ACLK,
		input	wire					S_AXI_ARESETN,
		//
		input	wire					S_AXI_AWVALID,
		output	wire					S_AXI_AWREADY,
		input	wire	[C_AXI_ADDR_WIDTH-1:0]		S_AXI_AWADDR,
		input	wire	[2:0]				S_AXI_AWPROT,
		//
		input	wire					S_AXI_WVALID,
		output	wire					S_AXI_WREADY,
		input	wire	[C_AXI_DATA_WIDTH-1:0]		S_AXI_WDATA,
		input	wire	[C_AXI_DATA_WIDTH/8-1:0]	S_AXI_WSTRB,
		//
		output	wire					S_AXI_BVALID,
		input	wire					S_AXI_BREADY,
		output	wire	[1:0]				S_AXI_BRESP,
		//
		input	wire					S_AXI_ARVALID,
		output	wire					S_AXI_ARREADY,
		input	wire	[C_AXI_ADDR_WIDTH-1:0]		S_AXI_ARADDR,
		input	wire	[2:0]				S_AXI_ARPROT,
		//
		output	wire					S_AXI_RVALID,
		input	wire					S_AXI_RREADY,
		output	wire	[C_AXI_DATA_WIDTH-1:0]		S_AXI_RDATA,
		output	wire	[1:0]				S_AXI_RRESP,
		// }}}
		// TX
		// {{{
		output	wire		o_uart_stb,
		output	wire	[6:0]	o_uart_data,
		input	wire		i_uart_busy,
		// }}}
		// RX
		// {{{
		input	wire		i_uart_stb,
		input	wire	[6:0]	i_uart_data,
		// }}}
		// A series of outgoing interrupts to select from among
		// {{{
		output	wire		o_uart_rx_int, o_uart_tx_int,
					o_uart_rxfifo_int, o_uart_txfifo_int

		// }}}
		// }}}
	);

	////////////////////////////////////////////////////////////////////////
	//
	// Register/wire signal declarations
	// {{{
	////////////////////////////////////////////////////////////////////////
	//
	//

	// Perform a simple/quick bounds check on the log FIFO length, to make
	// sure its within the bounds we can support with our current
	// interface.
	localparam [3:0]	LCLLGFLEN = (LGFLEN > 4'ha)? 4'ha
					: ((LGFLEN < 4'h2) ? 4'h2 : LGFLEN);
	//
	//
	localparam	[1:0]	UART_SETUP = 2'b00,
				UART_FIFO  = 2'b01,
				UART_RXREG = 2'b10,
				UART_TXREG = 2'b11;
	wire	i_reset = !S_AXI_ARESETN;

	wire				axil_write_ready;
	wire	[C_AXI_ADDR_WIDTH-ADDRLSB-1:0]	awskd_addr;
	//
	wire	[C_AXI_DATA_WIDTH-1:0]	wskd_data;
	wire [C_AXI_DATA_WIDTH/8-1:0]	wskd_strb;
	reg				axil_bvalid;
	//
	wire				axil_read_ready;
	wire	[C_AXI_ADDR_WIDTH-ADDRLSB-1:0]	arskd_addr;
	reg	[C_AXI_DATA_WIDTH-1:0]	axil_read_data;
	reg				axil_read_valid;
	//
	//
	reg		rx_uart_reset;
	//
	wire		rx_empty_n, rx_fifo_err;
	wire	[6:0]	rxf_axil_data;
	wire	[15:0]	rxf_status;
	reg		rxf_axil_read;
	//
	wire	[31:0]	axil_rx_data;
	//
	wire		tx_empty_n, txf_err;
	wire	[15:0]	txf_status;
	reg		txf_axil_write, tx_uart_reset;
	reg	[6:0]	txf_axil_data;
	wire	[31:0]	axil_tx_data;
	wire	[31:0]	axil_fifo_data;
	//
	reg	[1:0]	r_axil_addr;
	reg		r_preread;

	// }}}
	////////////////////////////////////////////////////////////////////////
	//
	// AXI-lite signaling
	// {{{
	////////////////////////////////////////////////////////////////////////
	//
	//

	//
	// Write signaling
	//
	// {{{

	generate if (OPT_SKIDBUFFER)
	begin : SKIDBUFFER_WRITE
		// {{{
		wire	awskd_valid, wskd_valid;

		skidbuffer #(.OPT_OUTREG(0),
				.OPT_LOWPOWER(OPT_LOWPOWER),
				.DW(C_AXI_ADDR_WIDTH-ADDRLSB))
		axilawskid(//
			.i_clk(S_AXI_ACLK), .i_reset(i_reset),
			.i_valid(S_AXI_AWVALID), .o_ready(S_AXI_AWREADY),
			.i_data(S_AXI_AWADDR[C_AXI_ADDR_WIDTH-1:ADDRLSB]),
			.o_valid(awskd_valid), .i_ready(axil_write_ready),
			.o_data(awskd_addr));

		skidbuffer #(.OPT_OUTREG(0),
				.OPT_LOWPOWER(OPT_LOWPOWER),
				.DW(C_AXI_DATA_WIDTH+C_AXI_DATA_WIDTH/8))
		axilwskid(//
			.i_clk(S_AXI_ACLK), .i_reset(i_reset),
			.i_valid(S_AXI_WVALID), .o_ready(S_AXI_WREADY),
			.i_data({ S_AXI_WDATA, S_AXI_WSTRB }),
			.o_valid(wskd_valid), .i_ready(axil_write_ready),
			.o_data({ wskd_data, wskd_strb }));

		assign	axil_write_ready = awskd_valid && wskd_valid
				&& (!S_AXI_BVALID || S_AXI_BREADY);
		// }}}
	end else begin : SIMPLE_WRITES
		// {{{
		reg	axil_awready;

		initial	axil_awready = 1'b0;
		always @(posedge S_AXI_ACLK)
		if (!S_AXI_ARESETN)
			axil_awready <= 1'b0;
		else
			axil_awready <= !axil_awready
				&& (S_AXI_AWVALID && S_AXI_WVALID)
				&& (!S_AXI_BVALID || S_AXI_BREADY);

		assign	S_AXI_AWREADY = axil_awready;
		assign	S_AXI_WREADY  = axil_awready;

		assign 	awskd_addr = S_AXI_AWADDR[C_AXI_ADDR_WIDTH-1:ADDRLSB];
		assign	wskd_data  = S_AXI_WDATA;
		assign	wskd_strb  = S_AXI_WSTRB;

		assign	axil_write_ready = axil_awready;
		// }}}
	end endgenerate

	initial	axil_bvalid = 0;
	always @(posedge S_AXI_ACLK)
	if (i_reset)
		axil_bvalid <= 0;
	else if (axil_write_ready)
		axil_bvalid <= 1;
	else if (S_AXI_BREADY)
		axil_bvalid <= 0;

	assign	S_AXI_BVALID = axil_bvalid;
	assign	S_AXI_BRESP = 2'b00;
	// }}}

	//
	// Read signaling
	//
	// {{{

	generate if (OPT_SKIDBUFFER)
	begin : SKIDBUFFER_READ
		// {{{
		wire	arskd_valid;

		skidbuffer #(.OPT_OUTREG(0),
				.OPT_LOWPOWER(OPT_LOWPOWER),
				.DW(C_AXI_ADDR_WIDTH-ADDRLSB))
		axilarskid(//
			.i_clk(S_AXI_ACLK), .i_reset(i_reset),
			.i_valid(S_AXI_ARVALID), .o_ready(S_AXI_ARREADY),
			.i_data(S_AXI_ARADDR[C_AXI_ADDR_WIDTH-1:ADDRLSB]),
			.o_valid(arskd_valid), .i_ready(axil_read_ready),
			.o_data(arskd_addr));

		// High bandwidth reads
		assign	axil_read_ready = arskd_valid
				&& (!r_preread || !axil_read_valid
							|| S_AXI_RREADY);
		// }}}
	end else begin : SIMPLE_READS
		// {{{
		reg	axil_arready;

		initial	axil_arready = 1;
		always @(posedge S_AXI_ACLK)
		if (!S_AXI_ARESETN)
			axil_arready <= 1;
		else if (S_AXI_ARVALID && S_AXI_ARREADY)
			axil_arready <= 0;
		else if (S_AXI_RVALID && S_AXI_RREADY)
			axil_arready <= 1;

		assign	arskd_addr = S_AXI_ARADDR[C_AXI_ADDR_WIDTH-1:ADDRLSB];
		assign	S_AXI_ARREADY = axil_arready;
		assign	axil_read_ready = (S_AXI_ARVALID && S_AXI_ARREADY);
		// }}}
	end endgenerate

	initial	axil_read_valid = 1'b0;
	always @(posedge S_AXI_ACLK)
	if (i_reset)
		axil_read_valid <= 1'b0;
	else if (r_preread)
		axil_read_valid <= 1'b1;
	else if (S_AXI_RREADY)
		axil_read_valid <= 1'b0;

	assign	S_AXI_RVALID = axil_read_valid;
	assign	S_AXI_RDATA  = axil_read_data;
	assign	S_AXI_RRESP = 2'b00;
	// }}}

	// }}}
	////////////////////////////////////////////////////////////////////////
	//
	// AXI-lite register logic
	// {{{
	////////////////////////////////////////////////////////////////////////
	//
	//

	// We place it into a receiver FIFO.

	// And here's the FIFO proper.
	//
	// Note that the FIFO will be cleared upon any reset: either if there's
	// a UART break condition on the line, the receiver is in reset, or an
	// external reset is issued.
	//
	// The FIFO accepts strobe and data from the receiver.
	// We issue another wire to it (rxf_axil_read), true when we wish to
	// read from the FIFO, and we get our data in rxf_axil_data.  The FIFO
	// outputs four status-type values: 1) is it non-empty, 2) is the FIFO
	// over half full, 3) a 16-bit status register, containing info
	// regarding how full the FIFO truly is, and 4) an error indicator.
	ufifo	#(
		.LGFLEN(LCLLGFLEN), .BW(7), .RXFIFO(1)
	) rxfifo(
		// {{{
		S_AXI_ACLK, (!S_AXI_ARESETN)||(rx_uart_reset),
			i_uart_stb, i_uart_data,
			rx_empty_n,
			rxf_axil_read, rxf_axil_data,
			rxf_status, rx_fifo_err
		// }}}
	);

	assign	o_uart_rxfifo_int = rxf_status[1];

	// We produce four interrupts.  One of the receive interrupts indicates
	// whether or not the receive FIFO is non-empty.  This should wake up
	// the CPU.
	assign	o_uart_rx_int = rxf_status[0];

	// If the bus requests that we read from the receive FIFO, we need to
	// tell this to the receive FIFO.  Note that because we are using a 
	// clock here, the output from the receive FIFO will necessarily be
	// delayed by an extra clock.
	initial	rxf_axil_read = 1'b0;
	always @(posedge S_AXI_ACLK)
		rxf_axil_read<=(axil_read_ready)&&(arskd_addr[1:0]==UART_RXREG);


	initial	rx_uart_reset = 1'b1;
	always @(posedge S_AXI_ACLK)
	if ((!S_AXI_ARESETN)||((axil_write_ready)&&(awskd_addr[1:0]== UART_SETUP) && (&wskd_strb)))
		// The receiver reset, always set on a master reset
		// request.
		rx_uart_reset <= 1'b1;
	else if (axil_write_ready&&(awskd_addr[1:0]==UART_RXREG)&&wskd_strb[1])
		// Writes to the receive register will command a receive
		// reset anytime bit[12] is set.
		rx_uart_reset <= wskd_data[12];
	else
		rx_uart_reset <= 1'b0;

	// Finally, we'll construct a 32-bit value from these various wires,
	// to be returned over the bus on any read.  These include the data
	// that would be read from the FIFO, an error indicator set upon
	// reading from an empty FIFO, a break indicator, and the frame and
	// parity error signals.
	assign	axil_rx_data = { 16'h00,
				3'h0, rx_fifo_err,
				1'b0, 1'b0, 1'b0, !rx_empty_n,
				1'b0, rxf_axil_data};
	// }}}
	////////////////////////////////////////////////////////////////////////
	//
	// Then the UART transmitter
	// {{{
	////////////////////////////////////////////////////////////////////////
	//
	// Unlike the receiver which goes from RXUART -> UFIFO -> WB, the
	// transmitter basically goes WB -> UFIFO -> TXUART.  Hence, to build
	// support for the transmitter, we start with the command to write data
	// into the FIFO.  In this case, we use the act of writing to the 
	// UART_TXREG address as our indication that we wish to write to the 
	// FIFO.  Here, we create a write command line, and latch the data for
	// the extra clock that it'll take so that the command and data can be
	// both true on the same clock.
	initial	txf_axil_write = 1'b0;
	always @(posedge S_AXI_ACLK)
	begin
		txf_axil_write <= (axil_write_ready)&&(awskd_addr == UART_TXREG)
			&& wskd_strb[0];
		txf_axil_data  <= wskd_data[6:0];
	end

	// Transmit FIFO
	// {{{
	// Most of this is just wire management.  The TX FIFO is identical in
	// implementation to the RX FIFO (theyre both UFIFOs), but the TX
	// FIFO is fed from the WB and read by the transmitter.  Some key
	// differences to note: we reset the transmitter on any request for a
	// break.  We read from the FIFO any time the UART transmitter is idle.
	// and ... we just set the values (above) for controlling writing into
	// this.
	ufifo	#(
		.LGFLEN(LGFLEN), .BW(7), .RXFIFO(0)
	) txfifo(
		// {{{
		S_AXI_ACLK, (tx_uart_reset),
			txf_axil_write, txf_axil_data,
			tx_empty_n,
			(!i_uart_busy)&&(tx_empty_n), o_uart_data,
			txf_status, txf_err
		// }}}
	);
	// }}}

	assign	o_uart_stb = tx_empty_n;

	// Let's create two transmit based interrupts from the FIFO for the CPU.
	//	The first will be true any time the FIFO has at least one open
	//	position within it.
	assign	o_uart_tx_int = txf_status[0];
	//	The second will be true any time the FIFO is less than half
	//	full, allowing us a change to always keep it (near) fully 
	//	charged.
	assign	o_uart_txfifo_int = txf_status[1];

	// TX-Reset logic
	// {{{
	// This is nearly identical to the RX reset logic above.  Basically,
	// any time someone writes to bit [12] the transmitter will go through
	// a reset cycle.  Keep bit [12] low, and everything will proceed as
	// normal.
	initial	tx_uart_reset = 1'b1;
	always @(posedge S_AXI_ACLK)
	if ((!S_AXI_ARESETN)||((axil_write_ready)&&(awskd_addr == UART_SETUP)))
		tx_uart_reset <= 1'b1;
	else if ((axil_write_ready)&&(awskd_addr[1:0]== UART_TXREG) && wskd_strb[1])
		tx_uart_reset <= wskd_data[12];
	else
		tx_uart_reset <= 1'b0;
	// }}}

	// Now that we are done with the chain, pick some wires for the user
	// to read on any read of the transmit port.
	//
	// This port is different from reading from the receive port, since
	// there are no side effects.  (Reading from the receive port advances
	// the receive FIFO, here only writing to the transmit port advances the
	// transmit FIFO--hence the read values are free for ... whatever.)  
	// We choose here to provide information about the transmit FIFO
	// (txf_err, txf_half_full, txf_full_n), information about the current
	// voltage on the line (o_uart_tx)--and even the voltage on the receive
	// line, as well as our current setting of the break and
	// whether or not we are actively transmitting.
	assign	axil_tx_data = { 16'h00, 
				1'b0, txf_status[1:0], txf_err,
				1'b0, o_uart_stb, 1'b0,
				(i_uart_busy|tx_empty_n),
				1'b0,(i_uart_busy|tx_empty_n)?o_uart_data:7'h0};

`ifndef	VERILATOR
	always @(posedge S_AXI_ACLK)
	if (S_AXI_ARESETN && !tx_uart_reset && o_uart_stb && !i_uart_busy)
	begin
		$write("%c", o_uart_data);
	end
`endif
	// }}}
	////////////////////////////////////////////////////////////////////////
	//
	// FIFO return
	// {{{
	////////////////////////////////////////////////////////////////////////
	//
	// Each of the FIFO's returns a 16 bit status value.  This value tells
	// us both how big the FIFO is, as well as how much of the FIFO is in 
	// use.  Let's merge those two status words together into a word we
	// can use when reading about the FIFO.
	assign	axil_fifo_data = { txf_status, rxf_status };

	// }}}
	////////////////////////////////////////////////////////////////////////
	//
	// Final read register
	// {{{
	////////////////////////////////////////////////////////////////////////
	//
	// You may recall from above that reads take two clocks.  Hence, we
	// need to delay the address decoding for a clock until the data is 
	// ready.  We do that here.
	initial	r_preread = 0;
	always @(posedge S_AXI_ACLK)
	if (!S_AXI_ARESETN)
		r_preread <= 0;
	else if (axil_read_ready)
		r_preread   <= 1;
	else if (!S_AXI_RVALID || S_AXI_RREADY)
		r_preread   <= 0;

	always @(posedge S_AXI_ACLK)
	if (axil_read_ready)
		r_axil_addr <= arskd_addr;

	// Finally, set the return data.  This data must be valid on the same
	// clock S_AXI_RVALID is high.  On all other clocks, it is
	// irrelelant--since no one cares, no one is reading it, it gets lost
	// in the mux in the interconnect, etc.  For this reason, we can just
	// simplify our logic.
	always @(posedge S_AXI_ACLK)
	if (!S_AXI_RVALID || S_AXI_RREADY)
	begin
		casez(r_axil_addr)
		UART_SETUP: axil_read_data <= 32'h0;
		UART_FIFO:  axil_read_data <= axil_fifo_data;
		UART_RXREG: axil_read_data <= axil_rx_data;
		UART_TXREG: axil_read_data <= axil_tx_data;
		endcase

		if (OPT_LOWPOWER && !r_preread)
			axil_read_data <= 0;
	end
	// }}}
	////////////////////////////////////////////////////////////////////////
	//
	// Veri1ator lint-check
	// {{{
	// Verilator lint_off UNUSED
	wire	unused;
	assign	unused = &{ 1'b0, S_AXI_AWPROT, S_AXI_ARPROT,
			wskd_data[31:13], wskd_data[11:7],
			S_AXI_ARADDR[ADDRLSB-1:0],
			S_AXI_AWADDR[ADDRLSB-1:0] };
	// Verilator lint_on  UNUSED
	// }}}
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
//
// Formal properties used in verfiying this core
// {{{
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
`ifdef	FORMAL
	reg	f_past_valid;
	initial	f_past_valid = 0;
	always @(posedge S_AXI_ACLK)
		f_past_valid <= 1;

	////////////////////////////////////////////////////////////////////////
	//
	// The AXI-lite control interface
	//
	////////////////////////////////////////////////////////////////////////
	//
	// {{{
	localparam	F_AXIL_LGDEPTH = 4;
	wire	[F_AXIL_LGDEPTH-1:0]	faxil_rd_outstanding,
					faxil_wr_outstanding,
					faxil_awr_outstanding;

	faxil_slave #(
		// {{{
		.C_AXI_DATA_WIDTH(C_AXI_DATA_WIDTH),
		.C_AXI_ADDR_WIDTH(C_AXI_ADDR_WIDTH),
		.F_LGDEPTH(F_AXIL_LGDEPTH),
		.F_AXI_MAXWAIT(4),
		.F_AXI_MAXDELAY(4),
		.F_AXI_MAXRSTALL(3),
		.F_OPT_COVER_BURST(4)
		// }}}
	) faxil(
		// {{{
		.i_clk(S_AXI_ACLK), .i_axi_reset_n(S_AXI_ARESETN),
		//
		.i_axi_awvalid(S_AXI_AWVALID),
		.i_axi_awready(S_AXI_AWREADY),
		.i_axi_awaddr( S_AXI_AWADDR),
		.i_axi_awcache(4'h0),
		.i_axi_awprot( S_AXI_AWPROT),
		//
		.i_axi_wvalid(S_AXI_WVALID),
		.i_axi_wready(S_AXI_WREADY),
		.i_axi_wdata( S_AXI_WDATA),
		.i_axi_wstrb( S_AXI_WSTRB),
		//
		.i_axi_bvalid(S_AXI_BVALID),
		.i_axi_bready(S_AXI_BREADY),
		.i_axi_bresp( S_AXI_BRESP),
		//
		.i_axi_arvalid(S_AXI_ARVALID),
		.i_axi_arready(S_AXI_ARREADY),
		.i_axi_araddr( S_AXI_ARADDR),
		.i_axi_arcache(4'h0),
		.i_axi_arprot( S_AXI_ARPROT),
		//
		.i_axi_rvalid(S_AXI_RVALID),
		.i_axi_rready(S_AXI_RREADY),
		.i_axi_rdata( S_AXI_RDATA),
		.i_axi_rresp( S_AXI_RRESP),
		//
		.f_axi_rd_outstanding(faxil_rd_outstanding),
		.f_axi_wr_outstanding(faxil_wr_outstanding),
		.f_axi_awr_outstanding(faxil_awr_outstanding)
		// }}}
		);

	always @(*)
	if (OPT_SKIDBUFFER)
	begin
		assert(faxil_awr_outstanding== (S_AXI_BVALID ? 1:0)
			+(S_AXI_AWREADY ? 0:1));
		assert(faxil_wr_outstanding == (S_AXI_BVALID ? 1:0)
			+(S_AXI_WREADY ? 0:1));

		assert(faxil_rd_outstanding == (S_AXI_RVALID ? 1:0)
			+ (r_preread ? 1:0) +(S_AXI_ARREADY ? 0:1));
	end else begin
		assert(faxil_wr_outstanding == (S_AXI_BVALID ? 1:0));
		assert(faxil_awr_outstanding == faxil_wr_outstanding);

		assert(faxil_rd_outstanding == (S_AXI_RVALID ? 1:0)
			+ (r_preread ? 1:0));

		assert(S_AXI_ARREADY == (!S_AXI_RVALID && !r_preread));
	end

`ifdef	VERIFIC
	assert property (@(posedge S_AXI_ACLK)
		disable iff (!S_AXI_ARESETN || (S_AXI_RVALID && !S_AXI_RREADY))
		S_AXI_ARVALID && S_AXI_ARREADY && S_AXI_ARADDR[3:2] == UART_FIFO
		|=> r_preread && r_axil_addr == UART_FIFO
		##1 S_AXI_RVALID && axil_read_data == $past(axil_fifo_data));
			
	assert property (@(posedge S_AXI_ACLK)
		disable iff (!S_AXI_ARESETN || (S_AXI_RVALID && !S_AXI_RREADY))
		S_AXI_ARVALID && S_AXI_ARREADY && S_AXI_ARADDR[3:2]== UART_RXREG
		|=> r_preread && r_axil_addr == UART_RXREG
		##1 S_AXI_RVALID && axil_read_data == $past(axil_rx_data));

	assert property (@(posedge S_AXI_ACLK)
		disable iff (!S_AXI_ARESETN || (S_AXI_RVALID && !S_AXI_RREADY))
		S_AXI_ARVALID && S_AXI_ARREADY && S_AXI_ARADDR[3:2]== UART_TXREG
		|=> r_preread && r_axil_addr == UART_TXREG
		##1 S_AXI_RVALID && axil_read_data == $past(axil_tx_data));

`endif
	//
	// Check that our low-power only logic works by verifying that anytime
	// S_AXI_RVALID is inactive, then the outgoing data is also zero.
	//
	always @(*)
	if (OPT_LOWPOWER && !S_AXI_RVALID)
		assert(S_AXI_RDATA == 0);

	// }}}
	////////////////////////////////////////////////////////////////////////
	//
	// Cover checks
	//
	////////////////////////////////////////////////////////////////////////
	//
	// {{{

	// While there are already cover properties in the formal property
	// set above, you'll probably still want to cover something
	// application specific here

	// }}}
`endif
// }}}
endmodule
