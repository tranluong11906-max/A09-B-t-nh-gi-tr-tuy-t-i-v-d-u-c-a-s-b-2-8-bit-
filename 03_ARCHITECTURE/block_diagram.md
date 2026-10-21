# A09 · Sơ đồ khối (Block Diagram)

Sơ đồ dưới đây vẽ **đúng theo RTL đã viết** (`04_IMPLEMENTATION/rtl/a09_abs_sign.sv`), không
phải vẽ theo ý tưởng chung. Mỗi khối trong hình ứng với một khối `generate` hoặc một dòng
`assign` cụ thể.

---

## 1. Toàn cảnh bốn tầng

```
                        x[7:0]  (bù 2)
        ┌──────────────────┬───────────────┬──────────────────────┐
        │                  │               │                      │
        │              x[7:0]           x[7]                   x[7:0]
        │                  │               │                      │
        │                  ▼               │                      ▼
        │        ┌──────────────────┐      │          ┌───────────────────────┐
        │        │ TẦNG 1           │      │          │ TẦNG 4                │
        │        │ Bộ ĐẢO BIT       │      │          │ Phát hiện 0x80        │
        │        │ 8 × INV          │      │          │                       │
        │        │ x_inv = ~x       │      │          │ low7_zero =           │
        │        └────────┬─────────┘      │          │   ~(x[6]|…|x[0])      │
        │                 │ x_inv[7:0]     │          │ ovf = x[7] & low7_zero│
        │                 ▼                │          └───────────┬───────────┘
        │        ┌──────────────────┐      │                      │
        │        │ TẦNG 2           │      │                      ▼
        │        │ Bộ CỘNG +1       │      │                    ovf
        │        │ 8 half-adder     │      │
        │        │ nối tiếp carry   │      │
        │        │ c[0] = 1         │      └──────────────▶  sign   (0 cổng)
        │        │ neg = x_inv + 1  │                          │
        │        └────────┬─────────┘                          │
        │                 │ neg[7:0] = −x                      │
        │                 │                                    │
        ▼                 ▼                                    │
   ┌────────────────────────────────┐                          │
   │ TẦNG 3 · MUX 2:1 × 8 bit       │◀─────── sel = sign ──────┘
   │ abs_val[i] = sign ? neg[i]:x[i]│
   └────────────────┬───────────────┘
                    ▼
               abs_val[7:0]   (độ lớn, đọc KHÔNG DẤU)
```

Ba đường xuất phát từ `x` chạy **song song**: đường dữ liệu chính (đảo → cộng 1 → mux),
đường dấu (dây nối thẳng), đường phát hiện tràn. Chỉ đường dữ liệu chính có độ sâu đáng kể.

## 2. Bên trong TẦNG 2 — bộ cộng +1 viết tường minh

Cộng hằng số 1 vào `x_inv` bằng chuỗi **half-adder**, không phải full-adder: mỗi tầng chỉ có
hai đầu vào (`x_inv[i]`, `c[i]`), vì toán hạng thứ hai là hằng số 0 ở mọi bit trừ bit 0.

```
  c[0]=1 ──┬──────────┐
           │          │
     x_inv[0] ──┬──[XOR]──▶ neg[0]
                │
                └──[AND]──▶ c[1] ──┬──────────┐
                                   │          │
                             x_inv[1] ──┬──[XOR]──▶ neg[1]
                                        │
                                        └──[AND]──▶ c[2] ── … ──▶ c[8] (bỏ, không dùng)
```

Một tầng half-adder:

```
          x_inv[i]        c[i]
              │             │
              ├──────┬──────┤
              │      │      │
           ┌──▼──────▼──┐ ┌─▼──────────┐
           │    XOR     │ │    AND     │
           └──────┬─────┘ └─────┬──────┘
                  ▼             ▼
               neg[i]         c[i+1]
```

**Đặc điểm quyết định của chuỗi này** — và là chỗ A09 khác hẳn A01:

```
c[i+1] = x_inv[i] & c[i]
       = x_inv[i] & x_inv[i−1] & … & x_inv[0]          ← khai triển hết
       = ~x[i] & ~x[i−1] & … & ~x[0]
       = NOR(x[i], x[i−1], …, x[0])                    ← chỉ phụ thuộc ĐẦU VÀO
```

Carry của bộ **tăng** (incrementer) là một phép **thu gọn AND thuần trên các bit đầu vào** —
**không** có phụ thuộc chuỗi thật sự. Trong bộ **cộng** hai số (A01) thì `carry[i+1]` là hàm
đa số của `a[i], b[i], carry[i]`, không khai triển được thành phép thu gọn một tầng. Đó là
lý do công cụ tổng hợp **làm phẳng được** chuỗi của A09 mà không làm phẳng được chuỗi của
A01. Số liệu đo ở `datapath.md` §4.

## 3. Bên trong TẦNG 3 — mux 2:1 viết dạng tổng-của-tích

```
                 sign           neg[i]        x[i]
                   │              │             │
          ┌────────┴───┐          │             │
          │            │          │             │
          │        ┌───▼───┐  ┌───▼───┐     ┌───▼───┐
          │        │  AND  │◀─┘       │     │  AND  │
          │        └───┬───┘          │  ┌─▶└───┬───┘
          │            │              │  │      │
       ┌──▼──┐         │              │  │      │
       │ INV │─────────┼──────────────┼──┘      │
       └─────┘         │              │         │
                       └──────┬───────┴─────────┘
                           ┌──▼──┐
                           │ OR  │
                           └──┬──┘
                              ▼
                          abs_val[i]
```

`sign = 0` ⟹ nhánh dưới dẫn ⟹ `abs_val[i] = x[i]` (đi thẳng).
`sign = 1` ⟹ nhánh trên dẫn ⟹ `abs_val[i] = neg[i]` (lấy bù 2).

Viết dạng tổng-của-tích thay vì `? :` để **mux hiện rõ trong mã nguồn** — Charter mục 10
yêu cầu nhìn thấy cấu trúc, không chỉ nhìn thấy kết quả.

## 4. TẦNG 4 — logic phục vụ RIÊNG cho ca −128

```
   x[6] ─┐
   x[5] ─┤
   x[4] ─┤
   x[3] ─┼──▶ ┌──────────┐
   x[2] ─┤    │  NOR 7   │──▶ low7_zero ──┐
   x[1] ─┤    └──────────┘                ├──▶ ┌─────┐
   x[0] ─┘                                │    │ AND │──▶ ovf
                              x[7] ───────┘    └─────┘
```

Đây chính là "logic phát hiện 0x80" mà Charter mục 10 liệt kê, và là phần Charter mục 9 bắt
phải chỉ ra trong báo cáo tổng hợp. **Sau tổng hợp nó co lại còn đúng một cell**:
`_12_ = sky130_fd_sc_hd__nor4_1`, 6,256 µm². Chi tiết và cách đo: `tradeoff.md` §3.

## 5. Ánh xạ RTL → phần cứng → netlist

| Dòng RTL | Phần cứng mức cổng | Sau tổng hợp (`netlist.v`) |
|---|---|---|
| `assign sign = x[7];` | dây nối | `assign sign = x[7];` — **0 cell** |
| `GEN_INV` 8 × `~x[i]` | 8 INV | bị **hấp thụ** vào các cell AOI/OAI kế tiếp |
| `GEN_INC` chuỗi half-adder | 8 XOR + 8 AND | thu gọn thành `or4_1`, `o21ai_0`, `o31ai_1`, `nand2*` + 5 × `xnor2_1` |
| `GEN_MUX` 8 mux 2:1 | 8 mux | **hợp nhất** với tầng 2 — xem ghi chú dưới |
| `low7_zero`, `ovf` | NOR7 + AND | `_11_ nand2b_1` + `_12_ nor4_1` |

> 🔎 **Ghi chú quan trọng: tầng 2 và tầng 3 bị hợp nhất.**
> Trong netlist không còn cell nào "là mux". Lý do đại số:
>
> ```
> abs_val[i] = x[i] ⊕ ( sign & ( x[i−1] | x[i−2] | … | x[0] ) )
> ```
>
> — chọn theo dấu và cộng 1 gộp được thành **một** phép XOR với một tín hiệu điều kiện.
> Đối chiếu thẳng với netlist cho bit 3:
> `_05_ = o31ai(x[0],x[1],x[2] ; x[7]) = ~((x[0]|x[1]|x[2]) & x[7])`, rồi
> `abs_val[3] = xnor2(x[3], _05_) = x[3] ⊕ ((x[0]|x[1]|x[2]) & x[7])` — **khớp đúng công
> thức**. Năm cell `xnor2_1` chính là năm phép XOR đó (ba bit còn lại rẻ hơn nữa).
> **Điều này KHÔNG có nghĩa RTL viết sai.** RTL mô tả cấu trúc để người đọc hiểu và để
> Charter kiểm được; `abc` có quyền tìm dạng rẻ hơn miễn là tương đương. Bằng chứng tương
> đương: 256/256 vector khớp golden model.
>
> Hệ quả thú vị đọc ngay ra từ netlist: `abs_val[0]` được lái bởi `_25_ buf_1` từ `x[0]` —
> tức **bit 0 của |x| luôn bằng bit 0 của x**, vì phép lấy bù 2 không bao giờ đổi bit thấp
> nhất.

---

*Phiên bản: v2.0 (thiết kế lại đúng đề Charter) · Ngày: 2026-09-24.*
