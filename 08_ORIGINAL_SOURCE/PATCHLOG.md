# A09 · Nhật ký thay thế mã nguồn (PATCHLOG)

> **Không phải nhật ký vá lỗi.** Đây là nhật ký **thay thế**: mã nguồn trong gói giải một đề
> khác, nên nó được thay bằng thiết kế mới đúng đề Charter, chứ không phải được sửa lỗi.
> Chẩn đoán đầy đủ: `../05_VERIFICATION/known_issues.md`.

---

## 1. Lý do thay thế

Gói `A09_Counter_Implementation_Validation` chứa RTL `a09_counter` — bộ đếm 4-bit **tuần
tự**, thuộc một **danh mục đề cũ**. Charter A09 yêu cầu **Bộ tính giá trị tuyệt đối và dấu
của số bù 2 8-bit**, phân loại **Tổ hợp** (0 ô nhớ). Không có phần nào của mã cũ dùng lại
được: khác chức năng, khác giao diện, khác loại mạch.

**Giảng viên đã duyệt** phương án viết RTL mới đúng đề. Bản gốc đóng băng ở thư mục này nên
việc thay thế là **an toàn và quay lui được**.

## 2. Các file bị thay

| # | Đường dẫn | Trước | Sau | Lý do |
|---|---|---|---|---|
| 1 | `04_IMPLEMENTATION/rtl/` | `a09_counter.sv` (bộ đếm 4-bit, `always_ff`) | **`a09_abs_sign.sv`** (tổ hợp thuần, `assign` + `generate`) | Sai đề; sai loại mạch |
| 2 | `05_VERIFICATION/golden_model/a09_reference.sv` | bản sao gần như nguyên văn của RTL gốc | **viết lại** dùng `$signed` + phép `-` trong miền 32 bit | Sai đề; và mô hình chuẩn không được sao chép thiết kế |
| 3 | `05_VERIFICATION/golden_model/reference_model.py` | mô hình Python của bộ đếm | **viết lại** cho trị tuyệt đối, 10 ca có tên + 8 bất biến trên 256 giá trị | Sai đề |
| 4 | `05_VERIFICATION/testbench/a09_tb.sv` | testbench bộ đếm, có clock | **viết lại**: 5 ca Charter mục 8 + 5 ca tự xây + ca không phụ thuộc lịch sử + quét vét cạn 256 | Sai đề |

Tài liệu viết lại theo thiết kế mới: `02_SPECIFICATION/functional_spec.md`,
`02_SPECIFICATION/corner_cases.md`, toàn bộ 7 file `03_ARCHITECTURE/*.md`,
`implementation-notes_A09.md`, và file mới `05_VERIFICATION/known_issues.md`.

**Không đụng vào:** `08_ORIGINAL_SOURCE/rtl|golden_model|testbench/`, `01_REQUIREMENT/`,
`06_GDSII/`, `07_TRACEABILITY/`, `README.md`, `04_IMPLEMENTATION/scripts|constraints`,
`02_SPECIFICATION/{interface,timing,parameters}.md` — các file này được sinh lại tự động
với số liệu mới.

## 3. Thiết kế mới — tóm tắt

| Hạng mục | Nội dung |
|---|---|
| Module top | `a09_abs_sign` |
| Cổng | `x[7:0]` → `abs_val[7:0]`, `sign`, `ovf` |
| Ánh xạ Charter mục 4 | `ui_in[7:0]` / `uo_out[7:0]` / `uio_out[0]` / `uio_out[1]` |
| Kiến trúc | đảo bit (8 INV) → cộng +1 tường minh (8 half-adder, `c[0]=1`) → mux 2:1 × 8 theo `sign` → phát hiện `0x80` |
| Xử lý ca `−128` | giữ kết quả bù 2 `0x80` (= 128 khi đọc **không dấu**) + bật `ovf`; **không** bão hoà, **không** mở 9 bit (Charter mục 3 loại cả hai) |
| Loại mạch | Tổ hợp thuần — không `always_ff`, không `clk`/`rst` |

## 4. Kết quả xác minh — trước và sau

| Mục | Trước (`a09_counter`) | **Sau (`a09_abs_sign`)** |
|---|---|---|
| Mô hình chuẩn Python | PASS | **PASS** (10 ca + 8 bất biến / 256 giá trị) |
| Mô phỏng RTL | PASS | **PASS** — 266 vector, **0 lỗi**, **0 vi phạm bất biến**, vét cạn **256/256** |
| Tổng hợp | PASS | **PASS** |
| Số cell | 14 | **18** |
| **Flip-flop** | **4** 🔴 sai phân loại | **0** ✅ đúng phân loại Tổ hợp |
| Diện tích | 138,8832 µm² | **118,864 µm²** |
| Đường tới hạn | `en → _23_`, 1,34 ns | `x[0] → abs_val[6]`, **0,96 ns**, 3 cell |
| WNS / TNS | 0,00 / 0,00 | **0,00 / 0,00** |
| Công suất | 1,87e-05 W (tuần tự 93,8 %) | **3,00e-06 W (tổ hợp 100 %, tuần tự 0 %)** |

### Điều kiện tạo bằng chứng

| Hạng mục | Giá trị |
|---|---|
| Mô phỏng | Icarus Verilog 12.0 (`iverilog -g2012`) |
| Tổng hợp | Yosys 0.33 (git sha1 2584903a060) |
| Thư viện | `sky130_fd_sc_hd`, góc `tt_025C_1v80` |
| STA | OpenSTA, clock **ảo** `vclk` chu kỳ 10 ns, input/output delay 0 ns |
| Ngày chạy | 2026-09-24 |

> `vclk` chỉ là **mốc quy chiếu** để STA tính được slack trên đường tổ hợp. Con số 10 ns
> **không** là yêu cầu hệ thống và **không** được diễn giải thành "khối chạy ở 100 MHz".

## 5. Số liệu bổ sung đã đo (phục vụ Charter mục 9)

Tổng hợp thêm ba biến thể bằng **cùng script, cùng thư viện**, chỉ để lấy số so sánh; chúng
**không** nằm trong hồ sơ nộp:

| Biến thể | Cell | Diện tích (µm²) | Dùng để trả lời |
|---|---:|---:|---|
| Bản nộp (bù 2 + mux + `ovf`) | 18 | 118,864 | — |
| Bỏ đầu ra `ovf` | 17 | 112,608 | chi phí riêng của phát hiện `−128` = **+1 cell, +6,256 µm²** |
| Đảo bit có điều kiện + carry-in = `sign` | 24 | 163,9072 | kiến trúc thay thế B (đắt hơn 37,9 %) |
| Viết tắt bằng toán tử `x[7] ? (~x+1) : x` | 18 | 118,864 | kiến trúc C — cùng diện tích, nhưng mất khả năng truy vết |
| Bão hoà về `0x7F` | 23 | 131,376 | kiến trúc D — Charter mục 3 loại khỏi phạm vi |

Cả bốn biến thể đã được kiểm tương đương hàm với mô hình chuẩn trên 256/256 giá trị trước
khi lấy số liệu (trừ bản bão hoà, vốn cố ý khác tại đúng ca `x = −128`).

## 6. Cách quay lui

```bash
cd out/A09_Bo_tinh_gia_tri_tuyet_doi_va_dau_cua_so_bu_2_8bit
rm -f 04_IMPLEMENTATION/rtl/*.sv 05_VERIFICATION/golden_model/* 05_VERIFICATION/testbench/*
cp 08_ORIGINAL_SOURCE/rtl/*                 04_IMPLEMENTATION/rtl/
cp 08_ORIGINAL_SOURCE/golden_model/*        05_VERIFICATION/golden_model/
cp 08_ORIGINAL_SOURCE/testbench/*           05_VERIFICATION/testbench/
```

Sau khi quay lui phải đổi lại top module thành `a09_counter` trong
`04_IMPLEMENTATION/scripts/02_run_synth.sh` và `03_run_sta.tcl`, và lưu ý testbench gốc cần
sửa tên instance `ref` → `ref_i` mới chạy được với Icarus (xem `known_issues.md` §4.1).

## 7. Đối chiếu trước/sau

```bash
diff -u 08_ORIGINAL_SOURCE/rtl/a09_counter.sv 04_IMPLEMENTATION/rtl/a09_abs_sign.sv
```

Hai file **không có phần chung** — đây là thay thế toàn bộ, không phải vá.

---

## 8. Dựng lại mô hình chuẩn và testbench (2026-09-24)

> 📌 **Đánh số.** Yêu cầu công việc gọi mục này là “§6”, nhưng §6 và §7 của tài liệu đã có
> sẵn (*Cách quay lui*, *Đối chiếu trước/sau*). Để không tạo mục trùng số, mục mới lấy số kế
> tiếp là **§8**; nội dung giữ nguyên như yêu cầu.

### 8.1 Vì sao phải dựng lại

Sau khi bản thiết kế lại ở §1–§7 đã xác minh xong, một bước sinh tài liệu tự động
(`generate2.py`) có lỗi: nó **chép mã nguồn cũ từ `runs/A09/work/` đè lên**
`04_IMPLEMENTATION/rtl/`, `05_VERIFICATION/golden_model/` và `05_VERIFICATION/testbench/`.
Các file bị ghi đè sau đó được dọn đi cùng với file cũ.

Hậu quả **không đồng đều**:

| Thư mục | Trạng thái sau sự cố |
|---|---|
| `04_IMPLEMENTATION/rtl/` | ✅ **Còn nguyên** — `a09_abs_sign.sv` không mất |
| `05_VERIFICATION/golden_model/` | ❌ **Mất trắng** |
| `05_VERIFICATION/testbench/` | ❌ **Mất trắng** |

Lỗi của bộ sinh **đã được sửa**. Vì RTL còn nguyên, công việc lần này **không phải thiết kế
lại**, mà là **dựng lại mô hình chuẩn và testbench cho khớp RTL hiện có**.

### 8.2 File đã dựng lại

| Đường dẫn | Nội dung |
|---|---|
| `05_VERIFICATION/golden_model/a09_reference.sv` | Module `a09_reference`: kéo bài toán lên **miền 32 bit có dấu** (`$signed`, phép `-`), suy ra cả ba đầu ra độc lập với cách RTL dò mẫu `0x80` — cờ tràn được định nghĩa là `\|val(x)\| > 127` |
| `05_VERIFICATION/golden_model/reference_model.py` | Python thuần: `model_math()` (định nghĩa toán học) + `model_bits()` (đảo bit → cộng +1 có carry → mux). 10 ca có tên + INV-1…INV-8 trên toàn bộ 256 giá trị + đo độ sâu chuỗi carry. In `PASS`, thoát mã 0 |
| `05_VERIFICATION/testbench/a09_tb.sv` | Instance DUT tên **`dut`**, cạnh đó là golden reference. 5 ca Charter mục 8 + 5 ca tự xây (có ca biên) + **quét vét cạn 256 giá trị** + phép đếm cờ tràn + đo độ sâu carry qua net `dut.inc_c` + TC-011 (không phụ thuộc lịch sử). Mọi sai lệch `$fatal(1, …)`. `$dumpoff` ngay trước vòng vét cạn |

**Ca biên −128 được dựng lại đúng vai trò trọng tâm.** Testbench kiểm ca `x = 0x80` ở **ba**
chỗ độc lập nhau:

1. **TC-004** — kiểm thẳng cả ba đầu ra: `abs_val = 0x80` (đọc không dấu = 128),
   `sign = 1`, **`ovf = 1`**, đúng như `functional_spec.md` §1 và §5.2 mô tả: **giữ** kết quả
   bù 2, **không** bão hoà, **không** mở 9 bit (Charter mục 3 loại cả hai).
2. **INV-3 trên mọi vector** — `ovf == (x == 0x80)`, tức cờ tràn phải bật **đúng** tại mẫu
   này và **tắt** ở 255 mẫu còn lại. Cặp đối chứng TC-005 (`0xC0` = −64) và TC-006
   (`0x81` = −127) chỉ khác `0x80` một bit, chứng minh `ovf` thật sự dò mẫu chứ không phải
   “cứ âm thì bật”.
3. **Phép đếm chốt hạ [2b]** — đếm số giá trị làm `ovf = 1` trên toàn bộ 256 vector và
   `$fatal` nếu khác **1**. Lời khẳng định “chỉ −128 mới tràn” nhờ đó thành một con số.

Bất biến **INV-1** (`abs_val` đọc **không dấu** bằng `|val(x)|`) được kiểm trên **cả 256/256**
giá trị **kể cả `x = −128`**, không cần ngoại lệ — đúng như `functional_spec.md` §5.2 khẳng
định. **INV-6** (`ovf == abs_val[7]`) cũng được kiểm trên mọi vector.

**Không** sửa bất kỳ file nào khác. `04_IMPLEMENTATION/rtl/`, `08_ORIGINAL_SOURCE/{rtl,
golden_model,testbench}/`, `01_`, `02_`, `03_`, `06_`, `07_`, `README.md`,
`implementation-notes_A09.*` giữ nguyên.

### 8.3 Kết quả xác minh lần này

Cùng công cụ, cùng thư viện với §4: Icarus Verilog 12.0 · Yosys 0.33 ·
`sky130_fd_sc_hd` (`sky130hd.lib`).

| Hạng mục | Ghi ở §4 | **Đo lại 2026-09-24** | Khớp? |
|---|---|---|:--:|
| Mô hình chuẩn Python | PASS — 10 ca + 8 bất biến / 256 giá trị | **PASS (thoát 0)** — 10 ca + INV-1…INV-8, 21/21 phép kiểm | ✅ |
| Biên dịch Icarus | — | **PASS, 0 cảnh báo** | — |
| Mô phỏng RTL | PASS — 266 vector, 0 lỗi, 0 vi phạm bất biến | **PASS — 266 vector, 0 lỗi, 1 597 lần kiểm bất biến, 0 vi phạm** | ✅ |
| Quét vét cạn | 256/256 | **256/256** | ✅ |
| Số giá trị làm `ovf = 1` | 1 (đúng `x = 0x80`) | **1 (đúng `x = 0x80`)** | ✅ |
| Tổng hợp | PASS | **PASS** | ✅ |
| **Số cell** | 18 | **18** | ✅ |
| **Flip-flop** | 0 | **0** | ✅ |
| **Diện tích** | 118,864 µm² | **118,864 µm²** | ✅ |

Phân bố cell đo lại:

```
xnor2_1 ×5   o21ai_0 ×3   nor4_1 ×2   o31ai_1 ×2
a21o_1  ×1   buf_1   ×1   clkinv_1×1  nand2_1 ×1   nand2b_1 ×1   or4_1 ×1
                                                      ------------------------
                                                      tong 18 cell · 118,864 µm²
```

Hai cell `nor4_1` chính là bằng chứng netlist cho **INV-6** đã nêu ở
`functional_spec.md` §8: `ovf` và `abs_val[7]` là **cùng một hàm logic**, công cụ giữ hai
cell chỉ vì mỗi cell lái một chân ra riêng. Không có cell họ `df*`/`sdf*`/`dl*`/`sedf*`
⟹ **0 flip-flop, 0 latch**.

> ✅ **Kết luận.** RTL không đổi nên số liệu tổng hợp phải y nguyên — và đúng là y nguyên.
> Con số 266 vector (10 ca có tên + 256 vét cạn) cũng khớp tuyệt đối với §4. TC-011 là phép
> đối chiếu hành vi, không phải vector mới, nên không cộng vào 266.

### 8.4 🟡 Chênh lệch phát hiện trong tài liệu — `corner_cases.md` §3.1

Khi dựng lại phép đo độ sâu chuỗi carry, bảng ở `02_SPECIFICATION/corner_cases.md` §3.1
(*“Theo độ sâu lan truyền của bộ cộng +1”*) **mâu thuẫn với chính công thức nằm ngay trên
nó**. Công thức viết:

> *“Carry vào tầng `i` của bộ cộng +1 bằng `~x[0] & ~x[1] & … & ~x[i−1]`.”*

Từ đó suy ra: carry chỉ lan tiếp khi các bit **thấp** của `x` bằng 0, nên
**số tầng carry lan = (vị trí bit 1 thấp nhất của `x`) + 1**. Đo thật trên net `dut.inc_c[]`
của RTL cho đúng như vậy:

| Ca | `x` | Bảng §3.1 ghi | **Đo thật trên RTL** | |
|---|---|---:|---:|---|
| TC-003 | `0xFF` (−1) | 8 — *“sâu nhất”* | **1** | ❌ ngược |
| TC-004 | `0x80` (−128) | 1 — *“nông”* | **8 — sâu nhất** | ❌ ngược |
| TC-005 | `0xC0` (−64) | 2 | **7** | ❌ |
| TC-006 | `0x81` (−127) | 8 | **1** | ❌ |
| TC-009 | `0xAA` (−86) | 2 | **2** | ✅ |
| TC-001 | `0x00` (0) | 8 | **8** | ✅ |

Lý do kiểm tra được bằng tay: `~0xFF = 0x00`, cộng 1 thì carry **chết ngay** ở tầng 0 (chỉ
bit 0 đổi, `abs = 0x01`). Ngược lại `~0x80 = 0x7F`, cộng 1 thì carry phải **đi hết 8 tầng**
(`abs = 0x80`). Bốn hàng TC-003/004/005/006 của bảng đã bị ghi ngược chiều; hai hàng
TC-009 và TC-001 đúng.

Theo nguyên tắc *“nếu tài liệu mô tả một điều bạn thấy sai, cứ làm theo hướng đúng và ghi rõ
chênh lệch”*, mô hình chuẩn và testbench **đo theo con số đúng**, và testbench `$fatal` nếu
độ sâu sâu nhất không phải **8 tầng tại `x = 0x80`**. Nhãn của TC-003 trong testbench cũng
được sửa từ *“carry lan hết 8 tầng”* thành *“nhánh bù 2, carry nông”*.

Chênh lệch này **không** ảnh hưởng tới chức năng, tới số cell, tới diện tích hay tới bất kỳ
kết luận nào ở §4 — nó chỉ là một nhận định **định tính** về độ trễ trong tài liệu ca biên.
`corner_cases.md` nằm ngoài phạm vi được sửa của công việc lần này nên **chưa được sửa**;
cần sửa bốn hàng đó khi sinh lại tài liệu.

> ✅ **Đã xử lý ở §9** (cùng ngày). Bảng §3.1 và dòng `TC-003` của `corner_cases.md` đã được
> sửa đúng chiều. Lưu ý §9 đếm theo `k` (số tầng **thực sự phải chờ** carry) còn bảng ngay
> trên đây đếm theo `k + 1` như testbench — xem §9.3 về chênh lệch quy ước này.

> 📌 Nhận xét đi kèm vẫn **đúng về tinh thần** nhưng ngược về ví dụ: *“ca biên” và “ca chậm
> nhất” là hai khái niệm khác nhau*. Đúng là khác nhau — chỉ có điều ở đề này chúng **trùng
> nhau**: `x = −128` vừa là ca quan trọng nhất về ngữ nghĩa, vừa là ca sâu nhất về chuỗi
> carry.

### 8.5 Không dựng lại được cái gì

Bản mô hình chuẩn và testbench cũ **không còn tồn tại** để so từng dòng. Những gì bảo đảm
được là **hành vi quan sát được** trùng khít (số vector, độ phủ vét cạn, số giá trị tràn).
Cách viết bên trong có thể khác bản cũ.

### 8.6 Cách quay lui

Mục này chỉ **thêm file** vào hai thư mục đang rỗng, không sửa gì sẵn có:

```bash
cd out/A09_Bo_tinh_gia_tri_tuyet_doi_va_dau_cua_so_bu_2_8bit
rm -f 05_VERIFICATION/golden_model/* 05_VERIFICATION/testbench/*
```

---

## 9. Sửa bảng độ sâu chuỗi carry trong tài liệu (2026-09-24)

> 📌 **Đây là lỗi TÀI LIỆU, không phải lỗi mã nguồn.** RTL
> (`04_IMPLEMENTATION/rtl/a09_abs_sign.sv`), mô hình chuẩn
> (`05_VERIFICATION/golden_model/`) và testbench (`05_VERIFICATION/testbench/a09_tb.sv`)
> **không đổi một ký tự**. Không có vector kiểm thử nào bị thêm, bớt hay sửa. Mọi số liệu
> mô phỏng, tổng hợp, STA và công suất ở §4, §5 và trong `06_GDSII/` giữ nguyên.

### 9.1 Lỗi là gì

Mục §8.4 đã **phát hiện và ghi nhận** chênh lệch này, nhưng lúc đó `corner_cases.md` nằm
ngoài phạm vi được sửa nên chỉ dừng ở mức cảnh báo. Lần này chênh lệch được **sửa thật**.

Bảng ở `02_SPECIFICATION/corner_cases.md` §3.1 (*"Theo độ sâu lan truyền của bộ cộng +1"*)
bị **đảo ngược hoàn toàn**: ca nông nhất bị ghi là sâu nhất và ngược lại. Dòng mô tả
`TC-003` ở §1 cũng mang cùng lỗi đó, gọi `0xFF` là *"ca lan truyền carry dài nhất … cộng 1
phải đi qua cả 8 tầng"*.

### 9.2 Vì sao nó sai

Bảng **mâu thuẫn với chính công thức nằm ngay trên nó**, vốn đã viết đúng:

> *"Carry vào tầng `i` của bộ cộng +1 bằng `~x[0] & ~x[1] & … & ~x[i−1]`."*

Bộ tăng cộng `1` vào `y = ~x`. Carry chỉ lan tiếp khi `y[j] = 1`, tức `x[j] = 0`, nên chuỗi
**dừng ở bit 1 thấp nhất của `x`**. Suy ra số tầng thực sự lan truyền `= k` (vị trí bit 1
thấp nhất), **không** phải nghịch đảo của nó. Tài liệu cũ đã đọc công thức theo chiều ngược.

Kiểm chứng bằng số (khớp với phép đo trên net `dut.inc_c[]` ở testbench mục `[2c]`):

| `x` | nhị phân | `k` | `~x` | `~x + 1` | Số tầng lan (`= k`) | Bảng cũ ghi | |
|---|---|---:|---|---|---:|---:|---|
| `0xFF` (−1) | `1111_1111` | 0 | `0000_0000` | `0000_0001` | **0** — nông nhất | 8 "sâu nhất" | ❌ ngược |
| `0x81` (−127) | `1000_0001` | 0 | `0111_1110` | `0111_1111` | **0** — nông nhất | 8 "sâu" | ❌ ngược |
| `0xAA` (−86) | `1010_1010` | 1 | `0101_0101` | `0101_0110` | 1 | 2 | ⚠️ lệch quy ước |
| `0xC0` (−64) | `1100_0000` | 6 | `0011_1111` | `0100_0000` | 6 | 2 "nông" | ❌ ngược |
| `0x80` (−128) | `1000_0000` | 7 | `0111_1111` | `1000_0000` | **7** — sâu nhất | 1 "nông" | ❌ ngược |
| `0x00` (0) | `0000_0000` | — | — | — | **không áp dụng** | 8 | ❌ |

Cách tự kiểm nhanh nhất: `~0xFF = 0x00`, cộng 1 ra `0x01` — chỉ bit 0 đổi, **không một tầng
nào phải chờ carry**. Còn `~0x80 = 0x7F`, cộng 1 ra `0x80` — **cả 7 tầng trên đều phải chờ
carry từ tầng 0**.

Hai điểm phụ đi kèm cũng đã sửa:

* **Ca `x = 0`.** Khi `x = 0` mạch đi nhánh dương, bộ tăng **không được dùng**, nên ô này
  phải ghi là **không áp dụng**, không phải "8 tầng". (Vòng quét `[2c]` của testbench chỉ
  chạy `x = 128…255` nên vốn đã không đếm ca này.)
* **"Bài học" sai kèm theo bảng.** Ghi chú 🔎 cũ dựng lên kết luận rằng "ca biên" và "ca
  chậm nhất" *luôn* tách nhau ở đề này. Thực tế ngược lại: `0x80` (−128) **vừa** là ca biên
  ngữ nghĩa (tràn, `abs` không biểu diễn được trong 8 bit có dấu ⟹ `ovf = 1`) **vừa** là ca
  sâu nhất về độ trễ — hai khái niệm **trùng nhau** ở A09. Ca sâu nhất **không tràn** là
  `0xC0` (−64) với 6 tầng; đó mới là cặp đối chứng đúng.

### 9.3 Chênh lệch quy ước đếm — đã ghi rõ, không phải lỗi

Testbench mục `[2c]` đếm số net `inc_c[0..7]` còn bằng 1, tức có tính **cả** carry-in hằng
số `inc_c[0] = 1`. Con số nó in ra (và `$fatal` kiểm) là **`k + 1`**: *"8 tầng tại
`x = 0x80`"*, *"1 tầng tại `0xFF` / `0x81`"* — xem `05_VERIFICATION/simulation.log` dòng 37.
Bảng §3.1 sau khi sửa đếm theo `k` (số tầng **thực sự phải chờ** carry của tầng trước), nên
con số nhỏ hơn đúng 1 đơn vị. Đây là **cùng một hiện tượng, hai cách đếm**, không phải mâu
thuẫn — và §3.1 nay có một đoạn ghi rõ quy ước để không ai đọc log rồi tưởng tài liệu sai.
Vì lý do này, testbench **không cần sửa**: cả phần đo lẫn phần chú thích của nó vốn đã đúng
chiều (`TC-003 … carry nong`, `chuoi carry chet ngay tang 0`).

Riêng dòng `0xAA` của bảng cũ ghi "2" — trùng với con số của testbench chứ không ngược
chiều; nó chỉ lệch quy ước, nên §8.4 đã đánh dấu ✅. Bảng mới ghi `1` cho nhất quán với cột
`k`.

### 9.4 File đã sửa

| File | Số chỗ sửa | Nội dung |
|---|---:|---|
| `02_SPECIFICATION/corner_cases.md` | **4** | §1: dòng `TC-003` (đổi "dài nhất" → "ngắn nhất", chỉ ra ca dài nhất là TC-004), dòng `TC-004` (bổ sung: đồng thời là ca carry dài nhất), dòng `TC-005` (bỏ "carry dừng sớm" → 6 tầng, sâu nhất trong các ca không tràn); §2: dòng `TC-009` (bỏ "nông nhất" → "một ca nông"); §3.1: viết lại bảng độ sâu + đoạn 🔎 |
| `08_ORIGINAL_SOURCE/PATCHLOG.md` | 1 | Thêm chính mục §9 này |

### 9.5 Các file đã rà nhưng **không** phải sửa

| File | Kết luận sau khi rà |
|---|---|
| `03_ARCHITECTURE/datapath.md` | ✅ Đúng. §3 nói về **độ sâu cấu trúc theo bit** (`abs_val[7]` đứng cuối chuỗi ⟹ sâu nhất theo RTL), không phải về giá trị `x` nào chậm nhất — hai khái niệm khác nhau, không mâu thuẫn. §4 ②: phát biểu *"carry của bộ **tăng** là phép thu gọn `NOR(x[i−1..0])` nên cây hoá được"* là **đúng**, giữ nguyên. |
| `implementation-notes_A09.md` | ✅ Đúng. §2.3, §8 ②, §9 mục 8 và §10 câu 8 đều chỉ nói "8 tầng ripple trong RTL không còn trong netlist" — phát biểu về **cấu trúc**, đúng; không chỗ nào nêu sai ca nào nông / ca nào sâu. |
| `03_ARCHITECTURE/timing_diagram.md` | ✅ Đúng. "Ca xấu nhất" ở đây là **đường tới hạn STA** (`x[0] → abs_val[6]`, 0,96 ns) — khái niệm sau tổng hợp, không vector, không liên quan tới độ sâu ripple theo giá trị `x`. |
| `02_SPECIFICATION/functional_spec.md` | ✅ Không nhắc tới chuỗi carry ở bất kỳ đâu. |
| `03_ARCHITECTURE/block_diagram.md`, `control.md`, `fsm.md`, `system_diagram.md`, `tradeoff.md` | ✅ Chỉ nói về **cấu trúc** chuỗi (8 tầng half-adder) và về tính thu gọn được của carry bộ tăng — đều đúng. |
| `05_VERIFICATION/testbench/a09_tb.sv` | ✅ **Không sửa.** Phép đo và mọi chú thích vốn đã đúng chiều (xem §9.3). |

### 9.6 Cách quay lui

Mục này chỉ sửa văn bản trong hai file `.md`. Không có bước build, mô phỏng hay tổng hợp nào
cần chạy lại — nhưng nếu muốn tự xác nhận rằng mã nguồn không đổi:

```bash
cd out/A09_Bo_tinh_gia_tri_tuyet_doi_va_dau_cua_so_bu_2_8bit
bash 04_IMPLEMENTATION/scripts/01_run_sim.sh     # vẫn 266 vector / 0 loi
```

`implementation-notes_A09.html` **chưa** được cập nhật trong bước này; nó sẽ được sinh lại
tự động từ file `.md` tương ứng.

---

*Phiên bản: v1.2 · Ngày: 2026-09-24 (v1.0: thiết kế lại · v1.1: dựng lại mô hình chuẩn và
testbench sau sự cố bộ sinh ghi đè · v1.2: sửa bảng độ sâu chuỗi carry trong
`corner_cases.md` — lỗi tài liệu, mã nguồn không đổi).*
