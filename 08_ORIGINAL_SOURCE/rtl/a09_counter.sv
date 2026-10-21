module a09_counter (
    input  logic       clk,
    input  logic       rst,
    input  logic       en,
    output logic [3:0] q
);
    always_ff @(posedge clk) begin
        if (rst)
            q <= 4'h0;
        else if (en)
            q <= q + 4'h1;
    end
endmodule
