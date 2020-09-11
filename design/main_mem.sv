module main_mem (
   input clk_i,
   input rst_ni, // wipe out all data

   mem_rwport.slave rw_intf,
   mem_rport.slave r_intf[0:`MEM_RPORTS-1]
);

	logic state;
	logic [7:0] ptr;
	always_ff @(posedge clk_i, posedge rst_ni) begin
		if (rst_ni) begin
			state <= 0;
			ptr <= 8'b0;
		end else begin
			state <= 1;
			ptr <= ptr + 1;
		end
	end

	genvar gi;
	generate
	for (gi = 0; gi < MEM_RPORTS; gi++) begin : g
		RAMB18E1 #(
			.RAM_MODE ("TDP"),
			.WRITE_MODE_A ("READ_FIRST")
		) i_mem (
			.DIADI (16'b0),
			.DIPADIP (2'b0),
			.DIBDI (state ? 16'b0 : rw_intf.wdata),
			.DIPBDIP (2'b0),
			.ADDRARDADDR ({2'b0,r_intf[gi].addr,4'b0}),
			.ADDRBWRADDR ({2'b0,state ? ptr : rw_intf.addr,4'b0}),
			.WEA (0),
			.WEBWE (state || rw_intf.val),
			.ENARDEN (r_intf[gi].val),
			.ENBWREN (state || rw_intf.val),
			.RSTREGARSTREG (0),
			.RSTREGB (0),
			.RSTRAMARSTRAM (0),
			.RSTRAMB (0),
			.CLKARDCLK (clk_i),
			.CLKBWRCLK (clk_i),
			.REGCEAREGCE (0),
			.REGCEB (0),
			.DOADO (r_intf[gi].rdata),
			.DOPADOP (),
			.DOBDO (rw_intf.rdata),
			.DOPBDOP ()
		);
	end
	endgenerate

endmodule
