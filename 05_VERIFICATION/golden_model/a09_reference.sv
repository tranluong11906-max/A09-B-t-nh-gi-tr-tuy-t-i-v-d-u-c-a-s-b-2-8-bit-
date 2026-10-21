// =====================================================================
//  A09 - MO HINH CHUAN (golden model) cho bo tinh tri tuyet doi + dau
//  File: a09_reference.sv
// ---------------------------------------------------------------------
//  De        : A09 . Nhom A - So hoc to hop
//  Vai tro   : CHUAN SO SANH DOC LAP voi RTL o 04_IMPLEMENTATION/rtl/.
//  Loai mach : TO HOP THUAN (khong clock, khong reset)
//
//  VI SAO FILE NAY DUOC PHEP DUNG TOAN TU TAT
//  ------------------------------------------
//  RTL nop bai BI CAM viet `x[7] ? -x : x` vi Charter muc 10 chot cau
//  truc phai THAY DUOC trong ma nguon: bo dao bit + bo cong +1 + mux
//  chon theo bit dau + logic phat hien 0x80.
//
//  Mot CHUAN SO SANH thi nguoc lai: no chi co gia tri khi duoc NGHI THEO
//  CACH KHAC. Vi vay o day KHONG co bo dao bit nao, KHONG co chuoi carry
//  nao, KHONG co mux nao. Thay vao do bai toan duoc keo len MIEN SO
//  NGUYEN 32 BIT co dau cua ngon ngu, giai bang dung dinh nghia toan hoc
//  cua tri tuyet doi, roi moi ep tro ve 8 bit.
//
//  Diem mau chot cua de - ca x = -128:
//     |-128| = 128 KHONG bieu dien duoc trong 8 bit CO DAU.
//     Trong mien 32 bit thi 128 hoan toan binh thuong, nen mo hinh chuan
//     TINH DUOC gia tri dung, roi tu do suy ra co tran mot cach doc lap
//     voi cach RTL do mau 0x80:
//         ovf = (|val(x)| > 127)
//     Hai cach nay tuong duong nhung KHONG giong nhau ve cach nghi - do
//     moi la dieu lam cho phep doi chieu co y nghia.
//
//  KHONG duoc chep bat ky dong nao tu RTL sang day, va nguoc lai.
// =====================================================================

module a09_reference (
    input  logic [7:0] x,        // So vao, dinh dang bu 2
    output logic [7:0] abs_val,  // |x| doc nhu so KHONG DAU (0 .. 128)
    output logic       sign,     // 1 = x am
    output logic       ovf       // 1 khi |x| khong vua 8 bit co dau
);

    // -----------------------------------------------------------------
    // Doi mau bit 8 bit sang GIA TRI TOAN HOC trong mien 32 bit co dau.
    //     val(x) = -128*x[7] + 64*x[6] + ... + 1*x[0]   thuoc [-128, +127]
    // -----------------------------------------------------------------
    function integer to_signed;
        input [7:0] v;
        begin
            to_signed = $signed(v);
        end
    endfunction

    // -----------------------------------------------------------------
    // Tri tuyet doi TRONG MIEN 32 BIT - dung dung dinh nghia toan hoc.
    // Ket qua nam trong dai 0 .. 128, khong he bi cat, khong he tran.
    // -----------------------------------------------------------------
    function integer magnitude;
        input [7:0] v;
        integer s;
        begin
            s = to_signed(v);
            if (s < 0) magnitude = -s;
            else       magnitude = s;
        end
    endfunction

    // -----------------------------------------------------------------
    // Ep do lon ve 8 bit KHONG DAU. Vi do lon toi da la 128 va 128 nam
    // tron trong dai khong dau 0 .. 255, phep ep nay KHONG mat bit nao.
    // Thu "tran" o de nay la cach DIEN GIAI, khong phai mat du lieu -
    // xem functional_spec.md muc 5.2.
    // -----------------------------------------------------------------
    function [7:0] magnitude8;
        input [7:0] v;
        integer m;
        begin
            m = magnitude(v);
            magnitude8 = m[7:0];
        end
    endfunction

    // -----------------------------------------------------------------
    // Ba dau ra, moi cai duoc suy ra DOC LAP tu gia tri toan hoc.
    // -----------------------------------------------------------------
    assign sign    = (to_signed(x) < 0);
    assign abs_val = magnitude8(x);
    assign ovf     = (magnitude(x) > 127);

endmodule
