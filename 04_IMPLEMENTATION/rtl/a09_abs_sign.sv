// =====================================================================
//  A09 - Bo tinh gia tri tuyet doi va dau cua so bu 2 8-bit
// ---------------------------------------------------------------------
//  De         : A09 . Nhom A - So hoc to hop
//  Loai mach  : TO HOP THUAN (khong clock, khong reset, 0 flip-flop)
//  Nguon      : Project Charter A09, muc 4 (giao dien), muc 8 (ca kiem
//               thu), muc 9 (phan tich rieng), muc 10 (dau hieu lam dung)
//  Truy vet   : REQ-A09-001 ... REQ-A09-007
//
//  RANG BUOC KIEN TRUC BAT BUOC
//  ----------------------------
//  KHONG duoc viet `assign abs_val = x[7] ? -x : x;`
//  KHONG duoc viet `assign abs_val = (x < 0) ? -$signed(x) : x;`
//  Charter muc 10 chot cau truc phai thay duoc trong RTL:
//      bo dao bit  +  bo cong +1  +  mux chon theo bit dau
//                  +  logic phat hien 0x80
//  Toan tu '-' va '+' o muc toan tu (full-word) cho phep cong cu tong hop
//  tu chon kien truc, lam mat chinh thu Charter muc 2 yeu cau dem va do.
//  Chung CHI duoc dung trong golden model o 05_VERIFICATION/golden_model/.
//
//  CA BIEN TRONG TAM: x = -128 (0x80)
//  ----------------------------------
//  |-128| = +128 khong bieu dien duoc trong 8 bit CO DAU (dai -128..+127).
//  Charter muc 3 dat "gia tri tuyet doi bao hoa" va "so rong hon 8 bit"
//  RA NGOAI pham vi, nen khoi nay KHONG bao hoa va KHONG mo rong ra 9 bit.
//  Khoi giu nguyen ket qua bu 2 (0x80) va bat co tran ovf = 1.
//  Doc 0x80 nhu so KHONG DAU thi no dung bang 128 - tuc la dung so hoc.
//  Xem 02_SPECIFICATION/functional_spec.md muc 5 va corner_cases.md TC-004.
// =====================================================================

module a09_abs_sign (
    input  logic [7:0] x,        // So vao, dinh dang bu 2   (Charter: ui_in[7:0])
    output logic [7:0] abs_val,  // |x| doc nhu KHONG DAU    (Charter: uo_out[7:0])
    output logic       sign,     // 1 = x am                 (Charter: uio_out[0])
    output logic       ovf       // 1 khi x == -128 (0x80)   (Charter: uio_out[1])
);

    // =================================================================
    // TANG 0 - Tach bit dau
    // -----------------------------------------------------------------
    // Trong bu 2, bit trong so cao nhat mang trong so AM (-128), nen no
    // vua la bit so hang vua la bit dau. Lay dau KHONG ton cong nao:
    // day la mot day noi thang ra chan.
    // =================================================================
    assign sign = x[7];

    // =================================================================
    // TANG 1 - Bo dao bit (one's complement)
    // -----------------------------------------------------------------
    // 8 cong INV doc lap, chay SONG SONG, do sau logic = 1.
    // =================================================================
    logic [7:0] x_inv;

    genvar gi;
    generate
        for (gi = 0; gi < 8; gi = gi + 1) begin : GEN_INV
            assign x_inv[gi] = ~x[gi];
        end
    endgenerate

    // =================================================================
    // TANG 2 - Bo cong +1 (incrementer) viet TUONG MINH
    // -----------------------------------------------------------------
    // Cong 1 vao x_inv bang chuoi 8 HALF-ADDER noi tiep carry:
    //     neg[i]    = x_inv[i] XOR inc_c[i]
    //     inc_c[i+1]= x_inv[i] AND inc_c[i]
    // voi inc_c[0] = 1 (chinh la so 1 duoc cong vao).
    //
    // Day la mat xich NOI TIEP duy nhat cua khoi: inc_c[i+1] phai cho
    // inc_c[i] on dinh. Do la phu thuoc DU LIEU, khong phai phu thuoc
    // chu ky - khoi nay khong co clock.
    //
    // Ket hop tang 1 va tang 2: neg = (~x) + 1 = bu 2 cua x.
    // =================================================================
    logic [8:0] inc_c;   // inc_c[0] = carry vao = 1 ; inc_c[8] = carry ra
    logic [7:0] neg;     // neg = -x  (bu 2, co quan quanh trong 8 bit)

    assign inc_c[0] = 1'b1;

    generate
        for (gi = 0; gi < 8; gi = gi + 1) begin : GEN_INC
            assign neg[gi]     = x_inv[gi] ^ inc_c[gi];
            assign inc_c[gi+1] = x_inv[gi] & inc_c[gi];
        end
    endgenerate

    // =================================================================
    // TANG 3 - Mux 2:1 tren tung bit, chon theo bit dau
    // -----------------------------------------------------------------
    //     sign = 0  ->  lay x   nguyen ban   (x >= 0, |x| = x)
    //     sign = 1  ->  lay neg = -x         (x <  0, |x| = -x)
    // Viet o dang tong-cua-tich de mux hien ro trong ma nguon; cong cu
    // tong hop se anh xa moi bit thanh mot cell mux/AOI cua thu vien.
    // =================================================================
    generate
        for (gi = 0; gi < 8; gi = gi + 1) begin : GEN_MUX
            assign abs_val[gi] = (sign & neg[gi]) | (~sign & x[gi]);
        end
    endgenerate

    // =================================================================
    // TANG 4 - Logic phat hien 0x80 (ca -128)
    // -----------------------------------------------------------------
    // x == 0x80  <=>  bit dau bang 1  VA  bay bit thap deu bang 0.
    // Viet tuong minh bang NOR cua 7 bit thap AND voi bit dau, thay vi
    // so sanh ca tu, de dem duoc chinh xac phan logic phuc vu RIENG cho
    // viec phat hien ca -128 (Charter muc 9 yeu cau chi ra phan logic do).
    //
    // Tai sao dung phep so sanh nay ma khong dung "neg == x"? Ca hai
    // tuong duong (chi 0x00 va 0x80 thoa -v == v), nhung 0x00 KHONG tran.
    // Mau 0x80 la dac ta truc tiep, khong can loai tru them truong hop 0.
    // =================================================================
    logic low7_zero;

    assign low7_zero = ~(x[6] | x[5] | x[4] | x[3] | x[2] | x[1] | x[0]);
    assign ovf       = x[7] & low7_zero;

endmodule
