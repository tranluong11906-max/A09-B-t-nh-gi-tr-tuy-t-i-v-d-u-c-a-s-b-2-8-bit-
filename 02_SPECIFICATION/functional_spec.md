# A09 · Đặc tả chức năng (Functional Specification)

> ## ⚠️ CẢNH BÁO TRUY VẾT NGUỒN — đọc trước
>
> Gói mã nguồn nhận ban đầu (`A09_Counter_Implementation_Validation`) **không hiện thực đề
> Charter này**. RTL trong gói là `a09_counter` — một **bộ đếm 4-bit tuần tự** (`clk`, `rst`,
> `en`, `q[3:0]`, 4 flip-flop), thuộc một **danh mục đề cũ**.
>
> | | Charter A09 yêu cầu | Gói nguồn ban đầu cung cấp |
> |---|---|---|
> | Chức năng | Trị tuyệt đối + dấu của số bù 2 8-bit | Bộ đếm 4-bit |
> | Loại mạch | **Tổ hợp** (0 ô nhớ) | **Tuần tự** (4 flip-flop) |
> | Giao diện | `x[7:0]` → `abs_val[7:0]`, `sign`, `ovf` | `clk`, `rst`, `en` → `q[3:0]` |
>
> **Đã xử lý:** bản gốc được đóng băng nguyên trạng ở `08_ORIGINAL_SOURCE/`; RTL, mô hình
> chuẩn và testbench được **viết lại từ đầu theo đúng đề Charter** (giảng viên đã duyệt).
> Chẩn đoán đầy đủ: `05_VERIFICATION/known_issues.md`. Nhật ký thay thế:
> `08_ORIGINAL_SOURCE/PATCHLOG.md`.
>
> Tài liệu này đặc tả **khối đúng đề** (`a09_abs_sign`). Trạng thái REQ-A09-001 sau khi
> thiết kế lại: ✅ **ĐÃ THOẢ** — bằng chứng ở §8.

---

## 1. Phương trình hành vi

Đầu vào `x[7:0]` được diễn giải là **số bù 2**, tức giá trị toán học:

```
val(x) = −128·x[7] + 64·x[6] + 32·x[5] + 16·x[4] + 8·x[3] + 4·x[2] + 2·x[1] + 1·x[0]
       ∈ [−128 … +127]
```

Ba đầu ra:

| Đầu ra | Phương trình | Ý nghĩa |
|---|---|---|
| `sign` | `sign = x[7]` | 1 khi `val(x) < 0` |
| `abs_val[7:0]` | `abs_val = sign ? ((~x) + 1) : x` — **đọc như số KHÔNG DẤU** | `abs_val = \|val(x)\|` |
| `ovf` | `ovf = x[7] & ~(x[6] \| x[5] \| x[4] \| x[3] \| x[2] \| x[1] \| x[0])` | 1 ⇔ `x = 0x80 = −128` |

**Quy ước đọc `abs_val` là điểm mấu chốt của đề.** Miền giá trị của `|val(x)|` là `0 … 128`.
Dải đó **nằm trọn** trong 8 bit **không dấu** (`0 … 255`) nhưng **vượt** dải 8 bit **có dấu**
(`−128 … +127`) đúng **một** giá trị: 128. Xem §5.

## 2. Đặc tả cấu trúc bắt buộc — bù 2 tường minh + mux

Charter mục 10 chốt thẳng cấu trúc phải nhìn thấy được:

> *"Dấu hiệu làm đúng: 0 ô nhớ. Cấu trúc = bộ đảo bit có điều kiện + bộ cộng +1 + logic
> phát hiện 0x80."*

Vì vậy RTL **bắt buộc** mô tả bốn tầng sau, và **cấm** viết tắt bằng toán tử:

| Tầng | Nội dung | Số cổng logic mức RTL |
|---|---|---|
| 0 | `sign = x[7]` | 0 (dây nối) |
| 1 | Bộ đảo bit: `x_inv[i] = ~x[i]` | 8 INV |
| 2 | Bộ cộng +1 tường minh: `neg[i] = x_inv[i] ^ c[i]`, `c[i+1] = x_inv[i] & c[i]`, `c[0] = 1` | 8 XOR + 8 AND |
| 3 | Mux 2:1 từng bit: `abs_val[i] = (sign & neg[i]) \| (~sign & x[i])` | 8 mux |
| 4 | Phát hiện `0x80`: `ovf = x[7] & NOR(x[6:0])` | 1 NOR7 + 1 AND |

```systemverilog
assign abs_val = x[7] ? -x : x;              // ❌ CẤM trong RTL nộp bài
assign abs_val = (x < 0) ? -$signed(x) : x;  // ❌ CẤM
```

Lý do cấm: toán tử `-` ở mức toàn từ cho phép công cụ tổng hợp tự chọn kiến trúc, xoá mất
chính thứ Charter mục 2 câu 2 yêu cầu đo (*"lấy giá trị tuyệt đối trong phần cứng là làm gì
— và nó tốn bao nhiêu cell?"*). Toán tử tắt **chỉ** được dùng trong
`05_VERIFICATION/golden_model/`, nơi chúng đóng vai trò chuẩn so sánh độc lập.

## 3. Bảng hành vi — 5 ca bắt buộc của Charter mục 8

| Ca | `x` (hex) | `val(x)` | `abs_val` (hex) | `abs_val` (không dấu) | `sign` | `ovf` |
|---|---|---:|---|---:|:-:|:-:|
| TC-001 | `0x00` | 0 | `0x00` | 0 | 0 | 0 |
| TC-002 | `0x7F` | +127 | `0x7F` | 127 | 0 | 0 |
| TC-003 | `0xFF` | −1 | `0x01` | 1 | 1 | 0 |
| **TC-004** | **`0x80`** | **−128** | **`0x80`** | **128** | **1** | **1** |
| TC-005 | `0xC0` | −64 | `0x40` | 64 | 1 | 0 |

## 4. Ánh xạ cổng ↔ Charter mục 4

Charter mục 4 dùng tên chân Tiny Tapeout (`ui_in`, `uo_out`, `uio_out`). RTL dùng tên gợi
nhớ; bảng dưới là hợp đồng ánh xạ giữa hai cách gọi.

| Chân Charter mục 4 | Cổng RTL | Chiều | Rộng | Vai trò |
|---|---|---|---:|---|
| `ui_in[7:0]` | `x[7:0]` | input | 8 | Số vào, định dạng bù 2 |
| `uo_out[7:0]` | `abs_val[7:0]` | output | 8 | `\|x\|`, đọc như **số không dấu** |
| `uio_out[0]` | `sign` | output | 1 | Bit dấu (1 = âm) |
| `uio_out[1]` | `ovf` | output | 1 | Cờ tràn (1 ⇔ `x = −128`) |
| `uio_out[7:2]` | — | — | 6 | Không dùng, buộc `0`; `uio_oe` tương ứng đặt `0` |

**Ngân sách chân:** 8 bit vào + 10 bit ra = **18 / 24 chân**. Charter ghi rõ *"ánh xạ chân
đã khả thi, không phải đổi gì"* — đề này **không** có bài toán ngân sách chân.

Khối `a09_abs_sign` là **lõi thuần**, không chứa lớp vỏ Tiny Tapeout. Lớp vỏ
(`tt_um_*` với `ena`, `clk`, `rst_n`) nếu cần sẽ là một wrapper riêng; xem
`03_ARCHITECTURE/control.md` §4.

## 5. Ca −128 — quy ước đã chốt và phần còn để mở

### 5.1 Vì sao −128 là ngoại lệ **toán học**, không phải lỗi thiết kế

Dải bù 2 `n` bit là `[−2ⁿ⁻¹ … +2ⁿ⁻¹−1]` — **không đối xứng**: có đúng `2ⁿ⁻¹` số âm nhưng chỉ
`2ⁿ⁻¹−1` số dương. Phép lấy trị tuyệt đối là ánh xạ từ tập số âm vào tập số dương; vì tập
đích **nhỏ hơn tập nguồn một phần tử**, không tồn tại ánh xạ nào giữ nguyên độ rộng mà không
mất mát. Giá trị bị dư ra là `−128`.

Đây là tính chất của **hệ biểu diễn**, đúng với mọi hiện thực phần cứng lẫn phần mềm (trong C,
`abs(INT_MIN)` là hành vi không xác định vì cùng lý do). Không có cách viết RTL nào làm nó
biến mất trong 8 bit có dấu.

### 5.2 Quy ước đã chốt

Charter mục 3 đặt **ra ngoài phạm vi**: *"Giá trị tuyệt đối bão hoà, số rộng hơn 8 bit."*
Hai lối thoát quen thuộc — bão hoà về `0x7F`, hoặc mở rộng đầu ra thành 9 bit — đều bị loại
trừ. Charter mục 4 lại cấp sẵn `uio_out[1] = cờ tràn`. Vậy quy ước bắt buộc là:

> **Giữ nguyên kết quả bù 2 (`0x80`) và bật `ovf = 1`.**

Và đây là chỗ đáng nói nhất của đề: **`0x80` đọc như số KHÔNG DẤU đúng bằng 128 — tức là
kết quả vẫn ĐÚNG về số học.** Không có bit nào bị mất. Thứ "tràn" là **cách diễn giải**:
mẫu bit `0x80` không còn đọc được như số bù 2 dương. Cờ `ovf` vì vậy là **cờ chuyển hệ diễn
giải**, không phải cờ báo sai số — khác hẳn cờ `V` của phép cộng (xem
`implementation-notes_A09.md` §7 câu 3).

Hệ quả kiểm chứng được: **bất biến INV-1 (`abs_val` không dấu == `|val(x)|`) đúng trên cả
256/256 giá trị vào, kể cả `x = −128`** — không cần ngoại lệ. Bằng chứng: `simulation.log`.

### 5.3 🟡 ĐIỂM MỞ — cần giảng viên chốt

| # | Điểm mở | Phương án đã hiện thực | Lý do chọn | Cần chốt gì |
|---|---|---|---|---|
| OPEN-1 | Tầng tiêu thụ đọc `uo_out` theo hệ nào? | **Không dấu** (`0 … 128`) | Chỉ cách đọc này mới làm `abs_val` đúng với mọi `x`; nếu đọc có dấu thì `x = −128` cho `−128`, sai dấu | Ghi vào hợp đồng giao diện: `uo_out` là **unsigned magnitude** |
| OPEN-2 | Khi `ovf = 1`, tầng ngoài phải làm gì? | Khối chỉ **báo**, không tự xử lý | Bão hoà nằm ngoài phạm vi Charter mục 3 | Tầng ngoài kẹp ngưỡng, bỏ mẫu, hay chấp nhận 128? |
| OPEN-3 | Có nên bỏ hẳn `ovf` vì nó trùng `abs_val[7]`? | **Giữ** `ovf` như Charter mục 4 chỉ định | Charter chốt ánh xạ chân; và bằng chứng trùng nhau chính là kết quả cần báo cáo | Xác nhận giữ chân `uio_out[1]` dù tốn thêm 1 cell |

Cả ba điểm đều **không** cản trở việc kiểm chứng: thiết kế hiện tại thoả mọi ca Charter mục 8.

## 6. Tính chất bất biến (invariants) — dùng làm assertion

| ID | Bất biến | Kiểm ở đâu |
|---|---|---|
| INV-1 | `unsigned(abs_val) == \|val(x)\|` với **mọi** `x` | Python + testbench (256/256) |
| INV-2 | `sign == x[7]` | testbench, mọi vector |
| INV-3 | `ovf == (x == 0x80)` | testbench, mọi vector |
| INV-4 | `sign == 0` ⟹ `abs_val == x` (nhánh "đi thẳng" của mux) | testbench |
| INV-5 | `sign == 1` ⟹ `abs_val == (~x + 1) mod 256` (nhánh "bù 2" của mux) | testbench |
| INV-6 | `ovf == abs_val[7]` | testbench + **netlist** (§8) |
| INV-7 | `ovf == 0` ⟹ `abs_val ≤ 127` | Python |
| INV-8 | `\|x\| == \|−x\|` với mọi `x ≠ −128` | Python |
| INV-9 | Đầu ra không phụ thuộc lịch sử đầu vào (mạch tổ hợp) | testbench TC-011 |
| INV-10 | Không có `X`/`Z` trên đầu ra với mọi đầu vào hợp lệ | testbench |

INV-6 đáng chú ý: nó nói `ovf` **không mang thông tin mới** so với `abs_val[7]`. Điều đó
được xác nhận lại ở mức netlist trong §8.

## 7. Điều kiện biên và hành vi không xác định

| Tình huống | Hành vi đặc tả |
|---|---|
| `x` chứa `X`/`Z` | **Không đặc tả.** Tầng ngoài bảo đảm đầu vào hợp lệ. |
| Lấy mẫu đầu ra trước khi mạch ổn định | **Không đặc tả.** Có thể đọc phải glitch — xem `03_ARCHITECTURE/timing_diagram.md` §4. |
| `x = 0` | `abs_val = 0`, `sign = 0`, `ovf = 0`. Lưu ý `−0` không tồn tại trong bù 2. |
| `x = 0x80` | `abs_val = 0x80 (=128 không dấu)`, `sign = 1`, `ovf = 1`. |

**Không gian đầu vào:** 8 bit ⟹ **256 tổ hợp**. Testbench quét **vét cạn** toàn bộ, nên
không còn ca hành vi nào chưa kiểm.

## 8. Bằng chứng đã đo được

| Mục | Kết quả | Công cụ |
|---|---|---|
| Mô hình chuẩn Python | PASS — 10 ca có tên + 8 bất biến trên 256/256 | CPython 3 |
| Mô phỏng RTL | **PASS** — 266 vector, **0 lỗi**, **0 vi phạm bất biến** | Icarus Verilog 12.0 |
| Quét vét cạn | 256/256 khớp golden model | như trên |
| Tổng hợp | PASS | Yosys 0.33 + `sky130_fd_sc_hd` |
| Số cell | **18** | như trên |
| **Flip-flop** | **0** ✅ đúng phân loại Tổ hợp (REQ-A09-003) | như trên |
| Diện tích | **118,864 µm²** | như trên |

**Bằng chứng netlist cho INV-6.** Trong `06_GDSII/synthesis/netlist.v`, cell `_12_` (tính
`ovf`) và cell `_26_` (tính `abs_val[7]`) là **hai cell `nor4_1` có bốn chân vào giống hệt
nhau**. Công cụ không hợp nhất chúng chỉ vì mỗi cell lái một chân ra riêng. Đây là bằng
chứng cấu trúc — mạnh hơn bằng chứng mô phỏng — rằng `ovf` và `abs_val[7]` là **cùng một
hàm logic**.

---

*Phiên bản: v2.0 (thiết kế lại đúng đề Charter) · Ngày: 2026-09-24 · Truy vết: REQ-A09-001,
REQ-A09-002, REQ-A09-003, REQ-A09-010, REQ-A09-011.*
