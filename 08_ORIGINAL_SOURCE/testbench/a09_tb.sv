module a09_tb;
    logic clk,rst,en;
    logic [3:0] q,qr;

    a09_counter dut(.clk(clk),.rst(rst),.en(en),.q(q));
    a09_reference ref_i(.clk(clk),.rst(rst),.en(en),.q(qr));

    always #5 clk=~clk;

    task automatic cycle(
        input logic rr,
        input logic ee,
        input logic [3:0] expected
    );
        begin
            rst=rr; en=ee;
            @(posedge clk); #1;
            assert(q===expected) else $fatal(1,"Q mismatch");
            assert(qr===expected) else $fatal(1,"reference Q mismatch");
        end
    endtask

    initial begin
        clk=0; rst=1; en=0;
        cycle(1,0,4'h0);

        cycle(0,1,4'h1);
        cycle(0,1,4'h2);
        cycle(0,0,4'h2);
        cycle(0,1,4'h3);

        // Force wrap-around by 12 enabled cycles from 3 -> 15 -> 0.
        cycle(0,1,4'h4);
        cycle(0,1,4'h5);
        cycle(0,1,4'h6);
        cycle(0,1,4'h7);
        cycle(0,1,4'h8);
        cycle(0,1,4'h9);
        cycle(0,1,4'hA);
        cycle(0,1,4'hB);
        cycle(0,1,4'hC);
        cycle(0,1,4'hD);
        cycle(0,1,4'hE);
        cycle(0,1,4'hF);
        cycle(0,1,4'h0);

        // Reset priority over enable.
        cycle(1,1,4'h0);
        cycle(0,0,4'h0);
        cycle(0,1,4'h1);

        $display("A09 counter validation PASS");
        $finish;
    end
endmodule
