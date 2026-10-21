#!/usr/bin/env python3
# =====================================================================
#  A09 - Mo hinh chuan Python cho bo tinh tri tuyet doi va dau (bu 2)
#  File: 05_VERIFICATION/golden_model/reference_model.py
# ---------------------------------------------------------------------
#  De        : A09 . Nhom A - So hoc to hop
#  Loai mach : TO HOP THUAN (khong clock, khong trang thai)
#
#  VAI TRO
#  -------
#  CHUAN SO SANH DOC LAP, viet truoc va kiem truoc khi dong toi Verilog.
#
#  HAI MO HINH NGHI KHAC NHAU
#  --------------------------
#    model_math()  - keo bai toan len mien SO NGUYEN khong gioi han cua
#                    Python, dung dinh nghia toan hoc cua tri tuyet doi,
#                    roi moi ep ve 8 bit. Khong co bit nao, khong carry.
#    model_bits()  - lam dung nhu phan cung: dao bit roi cong 1 co lan
#                    truyen carry tung tang, mux chon theo bit dau.
#  Hai mo hinh phai trung khit tren ca 256 gia tri.
#
#  CA BIEN TRONG TAM: x = -128 (0x80)
#  ----------------------------------
#  |-128| = 128 KHONG bieu dien duoc trong 8 bit CO DAU. Quy uoc da chot
#  (functional_spec.md muc 5.2): GIU nguyen ket qua bu 2 0x80 - doc nhu
#  so KHONG DAU thi no dung bang 128 - va bat co tran ovf = 1.
#  Vi vay INV-1 (abs_val khong dau == |val(x)|) van dung tren CA 256 gia
#  tri, KHONG can ngoai le nao.
#
#  Chay:  python3 reference_model.py   -> in PASS/FAIL, thoat 0 khi dat
# =====================================================================

import sys

MASK8 = 0xFF


# =====================================================================
#  1. HAI MO HINH DOC LAP
# =====================================================================

def to_signed(v):
    """Doi mau bit 8 bit sang gia tri toan hoc trong dai [-128, +127]."""
    v &= MASK8
    return v - 256 if (v & 0x80) else v


def model_math(x):
    """Mo hinh 1 - dinh nghia toan hoc, khong co khai niem bit.

    Tra ve (abs_val, sign, ovf).
    """
    s = to_signed(x)
    mag = -s if s < 0 else s          # nam trong dai 0 .. 128
    return (mag & MASK8, 1 if s < 0 else 0, 1 if mag > 127 else 0)


def model_bits(x):
    """Mo hinh 2 - lam dung nhu phan cung, tung bit mot.

    dao bit -> cong 1 co lan truyen carry -> mux chon theo bit dau.
    Tra ve (abs_val, sign, ovf, so tang carry thuc su lan truyen).
    """
    x &= MASK8
    sign = (x >> 7) & 1

    # ---- tang 1: dao bit ----
    inv = [((~x) >> i) & 1 for i in range(8)]

    # ---- tang 2: cong +1 bang chuoi half adder noi tiep carry ----
    carry = 1                          # c[0] = 1, chinh la so 1 duoc cong vao
    neg = [0] * 8
    depth = 0                          # so tang ma carry thuc su con bang 1
    for i in range(8):
        neg[i] = inv[i] ^ carry
        if carry:
            depth += 1
        carry = inv[i] & carry

    negv = 0
    for i in range(8):
        negv |= neg[i] << i

    # ---- tang 3: mux 2:1 tung bit, chon theo bit dau ----
    abs_val = negv if sign else x

    # ---- tang 4: phat hien mau 0x80 ----
    low7_zero = 1 if (x & 0x7F) == 0 else 0
    ovf = sign & low7_zero

    return (abs_val, sign, ovf, depth)


# =====================================================================
#  2. HA TANG BAO CAO
# =====================================================================

class Report:
    def __init__(self):
        self.checks = 0
        self.fails = 0
        self.lines = []

    def check(self, ok, what):
        self.checks += 1
        if not ok:
            self.fails += 1
            self.lines.append("    [FAIL] " + what)

    def section(self, title):
        print("")
        print("-" * 72)
        print("  " + title)
        print("-" * 72)


R = Report()


# =====================================================================
#  3. HAI MO HINH PHAI TRUNG KHIT TREN TOAN BO 256 GIA TRI
# =====================================================================

def check_two_models():
    R.section("Mo hinh TUNG BIT == mo hinh TOAN HOC tren 256 gia tri")
    bad = 0
    for x in range(256):
        a1, s1, o1 = model_math(x)
        a2, s2, o2, _d = model_bits(x)
        if (a1, s1, o1) != (a2, s2, o2):
            bad += 1
            if bad <= 5:
                R.lines.append(
                    "    [FAIL] x=0x%02X math=(%02X,%d,%d) bits=(%02X,%d,%d)"
                    % (x, a1, s1, o1, a2, s2, o2))
    R.check(bad == 0, "hai mo hinh lech nhau %d gia tri" % bad)
    print("    da so khop : 256 gia tri")
    print("    lech       : %d" % bad)
    print("    ==> bu 2 tuong minh == dinh nghia toan hoc : %s"
          % ("DUNG" if bad == 0 else "SAI"))


# =====================================================================
#  4. MUOI CA CO TEN - Charter muc 8 + ca tu xay dung
# =====================================================================
#  Day la dung 10 vector co ten ma testbench SystemVerilog cung chay,
#  theo dung thu tu. Tong so vector mo phong = 10 + 256 = 266.
# ---------------------------------------------------------------------

NAMED = [
    # (ten ca,                          x,    abs,  sign, ovf)
    ("TC-001 so 0 - khong co -0",       0x00, 0x00, 0, 0),
    ("TC-002 bien duong lon nhat +127", 0x7F, 0x7F, 0, 0),
    ("TC-003 -1 - nhanh bu 2, carry nong", 0xFF, 0x01, 1, 0),
    ("TC-004 -128 - CA BIEN TRONG TAM", 0x80, 0x80, 1, 1),
    ("TC-005 -64 - so am binh thuong",  0xC0, 0x40, 1, 0),
    ("TC-006 BIEN -127 sat ca -128",    0x81, 0x7F, 1, 0),
    ("TC-007 BIEN +1 duong nho nhat",   0x01, 0x01, 0, 0),
    ("TC-008 +64 doi xung voi TC-005",  0x40, 0x40, 0, 0),
    ("TC-009 -86 mau bit xen ke",       0xAA, 0x56, 1, 0),
    ("TC-010 +85 mau bit xen ke nghich", 0x55, 0x55, 0, 0),
]


def check_named():
    R.section("Ca co ten . Charter muc 8 + ca tu xay dung (%d vector)" % len(NAMED))
    for name, x, e_abs, e_sign, e_ovf in NAMED:
        a1, s1, o1 = model_math(x)
        a2, s2, o2, depth = model_bits(x)
        ok = (a1, s1, o1) == (e_abs, e_sign, e_ovf) and (a2, s2, o2) == (e_abs, e_sign, e_ovf)
        R.check(ok, "%s: x=0x%02X ky vong (abs=%02X sign=%d ovf=%d), "
                    "math=(%02X,%d,%d) bits=(%02X,%d,%d)"
                % (name, x, e_abs, e_sign, e_ovf, a1, s1, o1, a2, s2, o2))
        print("    %-35s x=%s val=%5d | abs=%s (%3d) sign=%d ovf=%d | carry %d tang  [%s]"
              % (name, format(x, "08b"), to_signed(x), format(a1, "08b"), a1,
                 s1, o1, depth, "PASS" if ok else "FAIL"))
    return len(NAMED)


# =====================================================================
#  5. BAT BIEN INV-1 .. INV-8 TREN TOAN BO 256 GIA TRI
# =====================================================================

def check_invariants():
    R.section("Bat bien INV-1..INV-8 tren toan bo 256 gia tri dau vao")

    n = {k: 0 for k in range(1, 9)}
    bad = {k: 0 for k in range(1, 9)}
    n_ovf = 0

    for x in range(256):
        abs_val, sign, ovf = model_math(x)
        s = to_signed(x)
        mag = -s if s < 0 else s
        if ovf:
            n_ovf += 1

        # INV-1 : abs_val doc KHONG DAU phai bang |val(x)| voi MOI x,
        #         ke ca x = -128. Day la bat bien manh nhat cua de.
        n[1] += 1
        if abs_val != mag:
            bad[1] += 1

        # INV-2 : sign == x[7]
        n[2] += 1
        if sign != ((x >> 7) & 1):
            bad[2] += 1

        # INV-3 : ovf == (x == 0x80)
        n[3] += 1
        if ovf != (1 if x == 0x80 else 0):
            bad[3] += 1

        # INV-4 : sign == 0  =>  abs_val == x   (nhanh "di thang" cua mux)
        if sign == 0:
            n[4] += 1
            if abs_val != x:
                bad[4] += 1

        # INV-5 : sign == 1  =>  abs_val == (~x + 1) mod 256 (nhanh bu 2)
        if sign == 1:
            n[5] += 1
            if abs_val != (((~x) + 1) & MASK8):
                bad[5] += 1

        # INV-6 : ovf == abs_val[7]  - ovf khong mang thong tin moi
        n[6] += 1
        if ovf != ((abs_val >> 7) & 1):
            bad[6] += 1

        # INV-7 : ovf == 0  =>  abs_val <= 127
        n[7] += 1
        if ovf == 0 and abs_val > 127:
            bad[7] += 1

        # INV-8 : |x| == |-x| voi moi x khac -128
        if x != 0x80:
            n[8] += 1
            negx = (-to_signed(x)) & MASK8
            if model_math(negx)[0] != abs_val:
                bad[8] += 1

    table = [
        (1, "abs_val (khong dau) == |val(x)| voi MOI x"),
        (2, "sign == x[7]"),
        (3, "ovf == (x == 0x80)"),
        (4, "sign=0 => abs_val == x"),
        (5, "sign=1 => abs_val == (~x + 1) mod 256"),
        (6, "ovf == abs_val[7]"),
        (7, "ovf=0 => abs_val <= 127"),
        (8, "|x| == |-x| voi moi x khac -128"),
    ]
    total = 0
    for k, desc in table:
        total += n[k]
        R.check(bad[k] == 0, "INV-%d vi pham %d lan" % (k, bad[k]))
        print("    INV-%d  %-46s %4d lan, %d vi pham" % (k, desc, n[k], bad[k]))

    # Phep dem chot ha: "chi -128 moi tran" duoc bien thanh MOT con so.
    R.check(n_ovf == 1, "so gia tri lam ovf=1 la %d, phai dung bang 1" % n_ovf)
    print("")
    print("    So gia tri lam ovf = 1 : %d  (phai dung bang 1, tai x = 0x80)" % n_ovf)
    print("    %-53s %4d lan" % ("TONG so lan kiem bat bien", total))
    return total


# =====================================================================
#  6. DO DINH LUONG - do sau lan truyen carry cua bo cong +1
# =====================================================================

def measure_carry_depth():
    R.section("Do dinh luong . do sau lan truyen carry cua bo cong +1")
    worst = 0
    worst_x = []
    for x in range(256):
        if (x >> 7) & 1:                       # chi nhanh am moi dung bo cong
            _a, _s, _o, d = model_bits(x)
            if d > worst:
                worst = d
                worst_x = [x]
            elif d == worst:
                worst_x.append(x)
    R.check(worst == 8, "do sau carry sau nhat = %d, ly thuyet = 8" % worst)
    print("    Do sau carry sau nhat  : %d tang" % worst)
    print("    Xay ra tai             : %s"
          % ", ".join("0x%02X" % v for v in worst_x[:4]))
    print("")
    print("    Quy luat do duoc: carry vao tang i bang ~x[0] & ... & ~x[i-1], nen")
    print("    so tang carry THUC SU lan = (vi tri bit 1 thap nhat cua x) + 1.")
    for v in (0xFF, 0x81, 0xAA, 0xC0, 0x80):
        _a, _s, _o, d = model_bits(v)
        print("      x = 0x%02X (%5d) -> carry lan %d tang" % (v, to_signed(v), d))
    print("")
    print("    Ghi chu: ca -128 (0x80) vua la ca QUAN TRONG NHAT ve ngu nghia,")
    print("    vua la ca SAU NHAT ve chuoi carry (8 tang). Hai ca NONG nhat cua")
    print("    nhanh am la -1 (0xFF) va -127 (0x81), moi ca chi 1 tang.")
    print("    (Bang o corner_cases.md muc 3.1 ghi nguoc chieu o bon hang")
    print("     TC-003/004/005/006 - xem PATCHLOG muc 8.)")


# =====================================================================
#  7. CHUONG TRINH CHINH
# =====================================================================

def main():
    print("=" * 72)
    print("  A09 . MO HINH CHUAN PYTHON - tri tuyet doi va dau cua so bu 2 8-bit")
    print("  Khong gian dau vao: 2^8 = 256 gia tri  => quet VET CAN duoc")
    print("=" * 72)

    check_two_models()
    n_named = check_named()
    n_inv = check_invariants()
    measure_carry_depth()

    print("")
    print("=" * 72)
    print("  TONG KET")
    print("=" * 72)
    print("  Gia tri da quet vet can  : 256")
    print("  Vector co ten            : %d" % n_named)
    print("  Lan kiem bat bien        : %d" % n_inv)
    print("  So phep kiem             : %d" % R.checks)
    print("  So phep kiem that bai    : %d" % R.fails)

    if R.fails:
        for line in R.lines[:40]:
            print(line)
        print("")
        print("  A09 REFERENCE MODEL: FAIL")
        return 1

    print("")
    print("  A09 REFERENCE MODEL: PASS - %d/%d phep kiem dat, 0 sai lech"
          % (R.checks, R.checks))
    return 0


if __name__ == "__main__":
    sys.exit(main())
