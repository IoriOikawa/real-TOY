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
		logic [7:0] aaddr = r_intf[gi].addr;
		logic [7:0] baddr = state ? ptr : rw_intf.addr;
		logic [15:0] bdin = state ? 16'b0 : rw_intf.wdata;
		logic [15:0] adout, bdout;
		logic bwen = state || rw_intf.val && rw_intf.wen;
		logic aen = r_intf[gi].val;
		logic ben = state || rw_intf.val;

		logic [15:0] mem[0:255];
		always_ff @(posedge clk_i) begin
			if (ben) begin
				if (bwen) begin
					mem[baddr] <= bdin;
				end else begin
					bdout <= mem[baddr];
				end
			end
			if (aen) begin
				adout <= mem[aaddr];
			end
		end

		assign r_intf[gi].rdata = adout;
		assign rw_intf.rdata = bdout;
	end
	endgenerate

endmodule
