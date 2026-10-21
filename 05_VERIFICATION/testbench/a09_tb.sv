// =====================================================================
//  A09 - TESTBENCH TU KIEM cho bo tinh tri tuyet doi va dau (bu 2) 8-bit
//  File: 05_VERIFICATION/testbench/a09_tb.sv
// ---------------------------------------------------------------------
//  DUT   : a09_abs_sign    (instance ten 'dut')
//  Chuan : a09_reference   - keo bai toan len mien 32 bit co dau
//
//  CAC LOP KIEM
//  ------------
//    [1a] 5 ca bat buoc cua Charter muc 8   (TC-001 .. TC-005)
//    [1b] 5 ca tu xay dung, co ca bien      (TC-006 .. TC-010)
//    [2]  QUET VET CAN toan bo 256 gia tri
//    [2b] Phep dem chot ha: DUNG MOT gia tri trong 256 lam ovf = 1
//    [3]  bat bien INV-1..INV-6 va INV-10 tren tung vector
//    [4]  TC-011 / INV-9 - khong phu thuoc lich su dau vao
//
//  Tong so vector = 10 (co ten) + 256 (vet can) = 266.
//  TC-011 la phep doi chieu hanh vi, khong phai vector moi, nen khong
//  duoc dem vao con so 266.
//
//  CA BIEN TRONG TAM: x = -128 (0x80)
//  ----------------------------------
//  |-128| = 128 khong bieu dien duoc trong 8 bit CO DAU. Quy uoc da chot
//  (functional_spec.md muc 5.2): GIU nguyen ket qua bu 2 0x80 - doc nhu
//  so KHONG DAU thi no dung bang 128 - va bat co tran ovf = 1.
//  TC-004 kiem ca ba dau ra cua ca nay; TC-005 va TC-006 la hai ca doi
//  chung chi khac 0x80 dung MOT bit, de chung minh ovf that su do mau
//  0x80 chu khong phai "cu am thi bat".
//
//  Cu phap: tranh nhung thu Icarus Verilog 12.0 chua ho tro - khong dung
//  'bind', 'string.getc()', 'assert property', nhan sau 'always @(...)
//  begin : ten', khai bao bien sau cau lenh trong 'initial', gan enum
//  qua toan tu '? :'. Moi bien deu khai bao o pham vi module.
// =====================================================================

`timescale 1ns / 1ps

module a09_tb;

    // -----------------------------------------------------------------
    // Tin hieu kich thich va quan sat
    // -----------------------------------------------------------------
    logic [7:0] x;

    logic [7:0] abs_val;       // tu DUT
    logic       sign;
    logic       ovf;

    logic [7:0] ref_abs;       // tu mo hinh chuan
    logic       ref_sign;
    logic       ref_ovf;

    // -----------------------------------------------------------------
    // Bo dem
    // -----------------------------------------------------------------
    integer n_vec;
    integer n_named;
    integer n_exh;
    integer n_err;
    integer n_inv;
    integer n_inv_bad;
    integer n_ovf;             // so gia tri lam ovf = 1 - phai dung bang 1

    // -----------------------------------------------------------------
    // Bien vong lap / tam
    // -----------------------------------------------------------------
    integer i, k;
    integer sx;                // gia tri co dau cua x
    integer mag;               // |val(x)| tinh o mien 32 bit
    integer depth;             // so tang carry con bang 1 cua bo cong +1
    integer worst_depth;
    reg [7:0] worst_x;
    reg [7:0] hold_abs;
    reg       hold_sign;
    reg       hold_ovf;

    // =================================================================
    // DUT - ten instance BAT BUOC la 'dut'
    // =================================================================
    a09_abs_sign dut (
        .x       (x),
        .abs_val (abs_val),
        .sign    (sign),
        .ovf     (ovf)
    );

    // =================================================================
    // Mo hinh chuan, dat NGAY CANH DUT, cung dau vao
    // =================================================================
    a09_reference u_ref (
        .x       (x),
        .abs_val (ref_abs),
        .sign    (ref_sign),
        .ovf     (ref_ovf)
    );

    // =================================================================
    // LOP 3 - kiem bat bien tren vector hien hanh
    // -----------------------------------------------------------------
    //  INV-1   abs_val doc KHONG DAU == |val(x)| voi MOI x, ke ca -128
    //  INV-2   sign == x[7]
    //  INV-3   ovf  == (x == 0x80)
    //  INV-4   sign = 0  =>  abs_val == x            (nhanh di thang)
    //  INV-5   sign = 1  =>  abs_val == (~x + 1)     (nhanh bu 2)
    //  INV-6   ovf  == abs_val[7]
    //  INV-10  khong bit X/Z tren bat ky dau ra nao
    //
    //  INV-7, INV-8 duoc kiem o mo hinh Python; INV-9 o buoc [4].
    // =================================================================
    task check_invariants;
        begin
            // ---------- INV-10 : khong X/Z ----------
            n_inv = n_inv + 1;
            if ((^abs_val) === 1'bx || sign === 1'bx || ovf === 1'bx) begin
                n_inv_bad = n_inv_bad + 1;
                $display("[FATAL] INV-10 vi pham: dau ra co bit X/Z");
                $fatal(1, "INV-10: x=%b abs=%b sign=%b ovf=%b", x, abs_val, sign, ovf);
            end

            // ---------- INV-1 : do lon dung o mien 32 bit ----------
            // Tinh lai |val(x)| mot cach DOC LAP voi ca DUT lan mo hinh
            // chuan, ngay trong testbench, bang so hoc 32 bit.
            n_inv = n_inv + 1;
            sx = $signed(x);
            if (sx < 0) mag = -sx;
            else        mag = sx;
            if (abs_val !== mag[7:0]) begin
                n_inv_bad = n_inv_bad + 1;
                $display("[FATAL] INV-1 vi pham: x=%0d, |x|=%0d, abs_val=%0d (khong dau)",
                         sx, mag, abs_val);
                $fatal(1, "INV-1: x=%02h abs_val=%02h", x, abs_val);
            end

            // ---------- INV-2 : sign chinh la bit dau ----------
            n_inv = n_inv + 1;
            if (sign !== x[7]) begin
                n_inv_bad = n_inv_bad + 1;
                $fatal(1, "INV-2: x=%02h x[7]=%b sign=%b", x, x[7], sign);
            end

            // ---------- INV-3 : chi mau 0x80 moi tran ----------
            n_inv = n_inv + 1;
            if (ovf !== (x == 8'h80)) begin
                n_inv_bad = n_inv_bad + 1;
                $display("[FATAL] INV-3 vi pham: x=%02h ovf=%b, ky vong %b",
                         x, ovf, (x == 8'h80));
                $fatal(1, "INV-3: co tran khong dung dac ta");
            end

            // ---------- INV-4 : nhanh "di thang" cua mux ----------
            if (sign === 1'b0) begin
                n_inv = n_inv + 1;
                if (abs_val !== x) begin
                    n_inv_bad = n_inv_bad + 1;
                    $fatal(1, "INV-4: x=%02h khong am ma abs_val=%02h", x, abs_val);
                end
            end

            // ---------- INV-5 : nhanh "bu 2" cua mux ----------
            if (sign === 1'b1) begin
                n_inv = n_inv + 1;
                if (abs_val !== ((~x) + 8'd1)) begin
                    n_inv_bad = n_inv_bad + 1;
                    $fatal(1, "INV-5: x=%02h abs_val=%02h, ky vong %02h",
                           x, abs_val, ((~x) + 8'd1));
                end
            end

            // ---------- INV-6 : ovf khong mang thong tin moi ----------
            n_inv = n_inv + 1;
            if (ovf !== abs_val[7]) begin
                n_inv_bad = n_inv_bad + 1;
                $display("[FATAL] INV-6 vi pham: x=%02h ovf=%b abs_val[7]=%b",
                         x, ovf, abs_val[7]);
                $fatal(1, "INV-6: ovf khac abs_val[7]");
            end
        end
    endtask

    // =================================================================
    // Ap mot vector va so voi mo hinh chuan
    // =================================================================
    task apply;
        input [7:0] v;
        begin
            x = v;
            #1;                     // cho mach to hop on dinh

            n_vec = n_vec + 1;

            if (abs_val !== ref_abs || sign !== ref_sign || ovf !== ref_ovf) begin
                n_err = n_err + 1;
                $display("[FATAL] Lech so voi mo hinh chuan");
                $display("        x   = %b (%02h)  val = %0d", v, v, $signed(v));
                $display("        DUT : abs=%b (%02h) sign=%b ovf=%b",
                         abs_val, abs_val, sign, ovf);
                $display("        REF : abs=%b (%02h) sign=%b ovf=%b",
                         ref_abs, ref_abs, ref_sign, ref_ovf);
                $fatal(1, "A09: DUT khac mo hinh chuan");
            end

            check_invariants;
        end
    endtask

    // =================================================================
    // Ap mot vector CO TEN: kiem them ca ba gia tri ky vong viet tay.
    // =================================================================
    task named_case;
        input [8*35-1:0] tag;
        input [7:0] v;
        input [7:0] e_abs;
        input       e_sign;
        input       e_ovf;
        begin
            apply(v);
            n_named = n_named + 1;

            if (abs_val !== e_abs || sign !== e_sign || ovf !== e_ovf) begin
                n_err = n_err + 1;
                $display("[FATAL] %0s", tag);
                $display("        ky vong: abs=%02h sign=%b ovf=%b", e_abs, e_sign, e_ovf);
                $display("        thuc te: abs=%02h sign=%b ovf=%b", abs_val, sign, ovf);
                $fatal(1, "A09: ca co ten sai ky vong");
            end

            $display("  %0s x=%b val=%4d | abs=%b (%3d) sign=%b ovf=%b  [PASS]",
                     tag, v, $signed(v), abs_val, abs_val, sign, ovf);
        end
    endtask

    // =================================================================
    // CHUONG TRINH CHINH
    // =================================================================
    initial begin
        n_vec     = 0;
        n_named   = 0;
        n_exh     = 0;
        n_err     = 0;
        n_inv     = 0;
        n_inv_bad = 0;
        n_ovf     = 0;
        x         = 8'h00;
        hold_abs  = 8'h00;
        hold_sign = 1'b0;
        hold_ovf  = 1'b0;

        $dumpfile("a09_waves.vcd");
        $dumpvars(0, a09_tb);

        $display("======================================================================");
        $display("  A09 . TESTBENCH - Tri tuyet doi va dau cua so bu 2 8-bit");
        $display("  DUT: a09_abs_sign   Chuan: a09_reference");
        $display("======================================================================");

        // -------------------------------------------------------------
        // [1a] NAM CA BAT BUOC CUA CHARTER MUC 8
        // -------------------------------------------------------------
        $display("");
        $display("[1a] Ca bat buoc cua Charter muc 8");
        $display("----------------------------------------------------------------------");

        // TC-001 . so 0: bu 2 KHONG co -0, mux phai chon nhanh di thang
        named_case("TC-001 so 0 - khong co -0         ", 8'h00, 8'h00, 1'b0, 1'b0);
        // TC-002 . bien duong lon nhat +127
        named_case("TC-002 bien duong lon nhat +127   ", 8'h7F, 8'h7F, 1'b0, 1'b0);
        // TC-003 . -1: nhanh bu 2 doi bit 0, chuoi carry chet ngay tang 0.
        //          Cung TC-007 (+1) tao cap +1 / -1 cung do lon nhung di
        //          hai nhanh mux khac nhau.
        named_case("TC-003 -1 nhanh bu 2, carry nong  ", 8'hFF, 8'h01, 1'b1, 1'b0);
        // TC-004 . -128: CA BIEN TRONG TAM cua de. |-128| = 128 khong
        //          bieu dien duoc trong 8 bit co dau => giu 0x80 (=128
        //          khi doc khong dau) va BAT co tran.
        named_case("TC-004 -128 CA BIEN TRONG TAM     ", 8'h80, 8'h80, 1'b1, 1'b1);
        // TC-005 . -64: so am binh thuong, carry dung som. Cung TC-004
        //          tao cap phan chung chi khac DUNG MOT bit (x[6]).
        named_case("TC-005 -64 so am binh thuong      ", 8'hC0, 8'h40, 1'b1, 1'b0);

        // -------------------------------------------------------------
        // [1b] NAM CA TU XAY DUNG (co ca bien)
        // -------------------------------------------------------------
        $display("");
        $display("[1b] Ca tu xay dung - co ca bien");
        $display("----------------------------------------------------------------------");

        // TC-006 . BIEN sat TC-004: -127 la so am lon nhat ve do lon ma
        //          VAN bieu dien duoc. Bat loi viet nham nguong.
        named_case("TC-006 BIEN -127 sat ca -128      ", 8'h81, 8'h7F, 1'b1, 1'b0);
        // TC-007 . BIEN phia duong: +1, cung TC-003 tao cap +1 / -1
        named_case("TC-007 BIEN +1 duong nho nhat     ", 8'h01, 8'h01, 1'b0, 1'b0);
        // TC-008 . +64: cung abs_val = 0x40 voi TC-005 nhung khac sign
        named_case("TC-008 +64 doi xung voi TC-005    ", 8'h40, 8'h40, 1'b0, 1'b0);
        // TC-009 . -86: mau xen ke, carry dung ngay tang 1
        named_case("TC-009 -86 mau bit xen ke         ", 8'hAA, 8'h56, 1'b1, 1'b0);
        // TC-010 . +85: mau xen ke nghich, nhanh duong
        named_case("TC-010 +85 mau bit xen ke nghich  ", 8'h55, 8'h55, 1'b0, 1'b0);

        $display("");
        $display("  Vector co ten da chay: %0d", n_named);

        // -------------------------------------------------------------
        // [2] QUET VET CAN
        // -------------------------------------------------------------
        // Tat ghi VCD TRUOC vong quet: 256 vector se lam file waveform
        // phinh to ma khong them thong tin nao doc duoc bang mat.
        // -------------------------------------------------------------
        $dumpoff;

        $display("");
        $display("[2] Quet vet can toan bo khong gian dau vao (2^8 = 256 gia tri)");
        $display("----------------------------------------------------------------------");

        for (i = 0; i < 256; i = i + 1) begin
            apply(i[7:0]);
            n_exh = n_exh + 1;
            if (ovf === 1'b1) n_ovf = n_ovf + 1;
        end

        $display("  Da quet: %0d/256 gia tri, sai lech: %0d", n_exh, n_err);

        // -------------------------------------------------------------
        // [2b] PHEP DEM CHOT HA - "chi -128 moi tran"
        // -------------------------------------------------------------
        $display("");
        $display("[2b] Phep dem co tran tren toan bo khong gian");
        $display("----------------------------------------------------------------------");
        $display("  So gia tri lam ovf = 1 : %0d", n_ovf);

        if (n_ovf !== 1) begin
            $fatal(1, "A09: so gia tri tran la %0d, phai dung bang 1 (tai x = 0x80)",
                   n_ovf);
        end
        $display("  ==> dung MOT gia tri trong 256, tai x = 0x80 (-128) : DUNG");
        $display("  (loi khang dinh \"chi -128 moi tran\" da thanh mot phep dem)");

        // -------------------------------------------------------------
        // [2c] DO DINH LUONG - do sau chuoi carry cua bo cong +1
        // -------------------------------------------------------------
        // Doc THANG net noi bo dut.inc_c[] de dem so tang ma carry thuc
        // su con bang 1. Quy luat: carry vao tang i bang ~x[0]&...&~x[i-1]
        // nen so tang lan = (vi tri bit 1 thap nhat cua x) + 1.
        // -------------------------------------------------------------
        $display("");
        $display("[2c] Do sau chuoi carry cua bo cong +1 (doc net dut.inc_c)");
        $display("----------------------------------------------------------------------");

        worst_depth = 0;
        worst_x     = 8'h00;
        for (i = 128; i < 256; i = i + 1) begin     // chi nhanh am dung bo cong
            x = i[7:0]; #1;
            depth = 0;
            for (k = 0; k < 8; k = k + 1) begin
                if (dut.inc_c[k] === 1'b1) depth = depth + 1;
            end
            if (depth > worst_depth) begin
                worst_depth = depth;
                worst_x     = i[7:0];
            end
        end

        $display("  Do sau carry sau nhat : %0d tang, tai x = 0x%02h (%0d)",
                 worst_depth, worst_x, $signed(worst_x));
        if (worst_depth !== 8 || worst_x !== 8'h80) begin
            $fatal(1, "A09: chuoi carry sau nhat phai la 8 tang tai x = 0x80");
        end
        $display("  ==> ca -128 vua QUAN TRONG NHAT ve ngu nghia, vua SAU NHAT");
        $display("      ve chuoi carry. Hai ca NONG nhat cua nhanh am la -1 (0xFF)");
        $display("      va -127 (0x81), moi ca 1 tang.");

        // -------------------------------------------------------------
        // [4] TC-011 / INV-9 - KHONG PHU THUOC LICH SU DAU VAO
        // -------------------------------------------------------------
        // Bang chung HANH VI cho "0 o nho": ap cung x = 0x80 sau HAI lich
        // su khac nhau, ca ba dau ra phai trung khit. Bang chung CAU TRUC
        // la 0 flip-flop trong synth_stat.txt.
        // Day la phep doi chieu, KHONG dem vao tong so vector.
        // -------------------------------------------------------------
        $display("");
        $display("[4] TC-011 / INV-9 - khong phu thuoc lich su dau vao");
        $display("----------------------------------------------------------------------");

        x = 8'h00; #1;
        x = 8'h80; #1;
        hold_abs  = abs_val;
        hold_sign = sign;
        hold_ovf  = ovf;
        $display("  x=0x80 sau lich su 0x00 -> abs=%02h sign=%b ovf=%b",
                 hold_abs, hold_sign, hold_ovf);

        x = 8'h7F; #1;
        x = 8'h80; #1;
        $display("  x=0x80 sau lich su 0x7F -> abs=%02h sign=%b ovf=%b",
                 abs_val, sign, ovf);

        n_inv = n_inv + 1;
        if (abs_val !== hold_abs || sign !== hold_sign || ovf !== hold_ovf) begin
            n_inv_bad = n_inv_bad + 1;
            $display("[FATAL] INV-9 vi pham: cung x=0x80 cho hai ket qua khac nhau");
            $fatal(1, "INV-9: mach co nho trang thai");
        end
        $display("  ==> trung khit : DUNG (mach to hop thuan, 0 o nho)");

        // -------------------------------------------------------------
        // TONG KET
        // -------------------------------------------------------------
        $display("");
        $display("======================================================================");
        $display("  TONG KET A09");
        $display("======================================================================");
        $display("  Vector co ten            : %0d", n_named);
        $display("  Vector quet vet can      : %0d/256", n_exh);
        $display("  TONG SO VECTOR           : %0d", n_vec);
        $display("  Sai lech so voi chuan    : %0d", n_err);
        $display("  Lan kiem bat bien        : %0d", n_inv);
        $display("  Vi pham bat bien         : %0d", n_inv_bad);
        $display("  Gia tri lam ovf = 1      : %0d (x = 0x80 = -128)", n_ovf);
        $display("  Flip-flop trong RTL      : 0 (khong co always_ff, khong co clk/rst)");

        if (n_err != 0 || n_inv_bad != 0 || n_exh != 256 || n_ovf != 1) begin
            $display("");
            $display("  KET QUA A09: FAIL");
            $fatal(1, "A09: testbench that bai");
        end

        $display("");
        $display("  KET QUA A09: PASS - %0d vector, 0 sai lech, %0d lan kiem bat bien, 0 vi pham",
                 n_vec, n_inv);
        $finish;
    end

endmodule
