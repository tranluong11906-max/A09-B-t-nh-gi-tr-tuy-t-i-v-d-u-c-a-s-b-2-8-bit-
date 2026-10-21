# A09 · Đường dữ liệu (Datapath)

---

## 1. Toàn bộ khối A09 **là** datapath

A09 không có phần điều khiển. Có một tín hiệu **trông giống** tín hiệu điều khiển — `sign`
lái các mux — nhưng nó **được tính ra từ chính dữ liệu** (`sign = x[7]`), không đến từ đâu
khác. Đây là điểm dễ tranh luận nhất của đề, xử lý kỹ ở `control.md` §2.

```
  x[7:0] ═══▶ ┌──────────────────────────────────────┐ ═══▶ abs_val[7:0]  (dữ liệu chính)
              │  đảo bit → cộng +1 → mux theo dấu    │ ────▶ sign          (thuộc tính dữ liệu)
              │  + logic phát hiện 0x80              │ ────▶ ovf           (cờ)
              └──────────────────────────────────────┘
```

## 2. Bảng các đường dữ liệu

| Đường | Độ rộng | Từ | Đến | Bản chất |
|---|---:|---|---|---|
| `x[7:0]` | 8 | cổng vào | TẦNG 1, TẦNG 3 (nhánh đi thẳng), TẦNG 4 | Toán hạng duy nhất |
| `sign` | 1 | `x[7]` | 8 mux + cổng ra + TẦNG 4 | **Fanout cao nhất trong khối** |
| `x_inv[7:0]` | 8 | 8 INV | chuỗi cộng +1 | Bù 1 của `x` |
| `inc_c[8:0]` | 9 | nội bộ | nối tầng `i` → `i+1` | Chuỗi carry của bộ cộng +1 |
| `neg[7:0]` | 8 | chuỗi cộng +1 | nhánh "bù" của mux | `−x` (bù 2) |
| `abs_val[7:0]` | 8 | 8 mux | cổng ra | Kết quả, đọc **không dấu** |
| `low7_zero` | 1 | NOR(`x[6:0]`) | cổng AND của `ovf` | Trung gian phát hiện `0x80` |
| `ovf` | 1 | TẦNG 4 | cổng ra | Cờ |

Lưu ý `inc_c[8]` (carry ra của bộ cộng +1) **không được dùng**. Nó bằng 1 đúng khi
`x_inv = 0xFF`, tức `x = 0x00`; nhưng khi `x = 0` thì mux chọn nhánh đi thẳng nên giá trị
đó không bao giờ tới đầu ra. Công cụ tổng hợp loại bỏ toàn bộ logic sinh `inc_c[8]`.

## 3. Đồ thị phụ thuộc (dependency graph) — **theo RTL**

```
 mức 0    x[7] ──────────────────────────────────────▶ sign          (0 cổng)
          x[6:0] ─┐
          x[7] ───┴──▶ NOR7 ──▶ low7_zero ──▶ AND ──▶ ovf

 mức 0    x[0] ──▶ INV ──▶ x_inv[0] ─┬─▶ XOR (c[0]=1) ──▶ neg[0]
                                     └─▶ AND ──▶ inc_c[1]
 mức 1                                            │
          x[1] ──▶ INV ──▶ x_inv[1] ─┬────────────┴─▶ XOR ──▶ neg[1]
                                     └─▶ AND ──▶ inc_c[2]
 mức 2                                            │
                              …                   …
 mức 7    x[7] ──▶ INV ──▶ x_inv[7] ───────────────▶ XOR ──▶ neg[7]

 mức 8    neg[i] ─┬──▶ MUX(sel=sign) ──▶ abs_val[i]
          x[i]  ──┘
```

**Độ sâu logic theo RTL (trước tối ưu):**

| Đầu ra | Độ sâu tính từ đầu vào |
|---|---|
| `sign` | **0** — chỉ là dây |
| `ovf` | 2 (NOR7 → AND) |
| `abs_val[0]` | 3 (INV → XOR → MUX) — **nông nhất của đường dữ liệu** |
| `abs_val[i]` | ≈ `i` tầng carry + INV + XOR + MUX |
| `abs_val[7]` | 7 tầng carry + 3 — **sâu nhất theo RTL** |

> 🔎 **Dự đoán trước khi chạy STA:** endpoint tới hạn sẽ là một bit **cao** của `abs_val`
> (bit 6 hoặc 7), vì chỉ bit cao mới đứng cuối chuỗi carry. Dự đoán này **đúng một nửa** —
> xem §4.

## 4. Kết quả đo thật và chỗ dự đoán sai

Số liệu OpenSTA trên netlist sau tổng hợp (clock ảo 10 ns, góc `tt_025C_1v80`):

| Đường | Số cell trên đường | Độ trễ |
|---|---:|---:|
| `x[0] → abs_val[6]` | 3 (`or4_1` → `o31ai_1` → `xnor2_1`) | **0,96 ns** ← tới hạn |
| `x[0] → abs_val[5]` | 3 (`or4_1` → `o21ai_0` → `xnor2_1`) | 0,90 ns |
| `x[4] → abs_val[7]` | 1 (`nor4_1`) | 0,01 ns |
| `x[7] → sign` | **0** | **0,00 ns** |

Ba điều đọc ra được:

**① Endpoint tới hạn là `abs_val[6]`, không phải `abs_val[7]`.** Dự đoán "bit cao nhất chậm
nhất" **sai**. Lý do đọc được từ netlist: `abs_val[7] = ~( x[4] | x[5] | _01_ | _02_ )` —
đúng **một** cell `nor4_1`. Nó rẻ vì bit 7 của `|x|` chỉ bằng 1 trong đúng một trường hợp
(`x = 0x80`), nên hàm của nó cực kỳ thưa. Bit 6 thì ngược lại — hàm dày, cần ba mức.

**② Chuỗi ripple 8 tầng đã biến mất.** RTL mô tả 8 tầng carry nối tiếp, nhưng đường dài
nhất chỉ đi qua **3 cell**. Nguyên nhân là tính chất đại số đã nêu ở `block_diagram.md` §2:

```
inc_c[i+1] = ~x[i] & ~x[i−1] & … & ~x[0]       ← phép thu gọn AND trên ĐẦU VÀO
```

Carry của bộ **tăng** không có phụ thuộc chuỗi thật; nó là một phép thu gọn kết hợp
(associative) nên `abc` cân bằng được thành cây. Cell `_10_ or4_1` gom `x[0..3]` thành một
tín hiệu `_01_` dùng lại cho **cả bốn** bit cao — đây là một cây **prefix-OR** tự phát sinh.

> **Đây là khác biệt cốt lõi giữa A09 và A01.** Trong A01, `carry[i+1]` là hàm đa số của
> `a[i], b[i], carry[i]` — không khai triển được, nên chuỗi giữ nguyên 8 tầng và đường tới
> hạn dài 1,34 ns / 8 cell. Trong A09, "ripple" chỉ là **cách viết**, không phải **cấu trúc
> cuối cùng**. Viết ripple tường minh vẫn đúng và vẫn cần thiết (để Charter kiểm được cấu
> trúc), nhưng kết luận về độ trễ **bắt buộc** phải lấy từ netlist + STA, không suy từ RTL.

**③ `sign` tốn 0 cell và 0 ns.** `report_checks -path_delay min` cho đường `x[7] → sign` dài
**0,00 ns**, và trong netlist là `assign sign = x[7];` — hai tên gọi của cùng một net. Trả
lời trực tiếp một phần câu hỏi Charter mục 2 câu 2 ("lấy trị tuyệt đối tốn bao nhiêu cell"):
phần **dấu** tốn 0.

## 5. Vì sao không có thanh ghi trong datapath

| Câu hỏi | Trả lời |
|---|---|
| Dữ liệu có cần giữ qua chu kỳ không? | Không — A09 tính xong trong một lần lan truyền |
| Có pipeline không? | Không — Charter chốt loại mạch Tổ hợp |
| Sai số có dấu `err` được chốt ở đâu? | Ở thanh ghi **bên ngoài**, phía trước A09 — xem `system_diagram.md` §1 |
| Nếu thêm thanh ghi thì sao? | Vi phạm REQ-A09-003 và Charter mục 10 ("dấu hiệu làm đúng: 0 ô nhớ") |

Bằng chứng "0 ô nhớ" có **ba** nguồn độc lập:

1. `06_GDSII/synthesis/synth_stat.txt` — không có cell `__df*`/`__dl*`/`__sd*`.
2. `06_GDSII/sta/` — `report_power` cho nhóm Sequential **0 %**, Clock **0 %**.
3. `05_VERIFICATION/simulation.log` TC-011 — đầu ra không phụ thuộc lịch sử đầu vào.

## 6. Cơ hội pipeline (chỉ để thảo luận — **ngoài phạm vi**)

Với đường tới hạn 0,96 ns và **3** cell, pipeline ở đây là vô nghĩa: chèn thanh ghi vào giữa
một đường ba cổng sẽ tốn 8–9 flip-flop (mỗi cái ~20 µm², lớn hơn cả khối hiện tại) để cắt
một độ trễ vốn đã nhỏ hơn thời gian setup+clk-to-q của chính các flip-flop đó. Ghi ở đây chỉ
để trả lời câu "có cách nào nhanh hơn không" khi bảo vệ — và câu trả lời là **cách nhanh hơn
sẽ chậm hơn**.

---

*Phiên bản: v2.0 (thiết kế lại đúng đề Charter) · Ngày: 2026-09-24.*
