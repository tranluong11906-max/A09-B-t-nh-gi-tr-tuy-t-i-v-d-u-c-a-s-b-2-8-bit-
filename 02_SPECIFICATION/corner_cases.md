# A09 · Ca biên và ca góc (Corner Cases)

Đề A09 có một đặc điểm hiếm: **không gian đầu vào chỉ 256 giá trị**, nên quét vét cạn là
khả thi tuyệt đối. Vì vậy các ca có tên dưới đây **không** nhằm tăng độ phủ — độ phủ đã là
100 %. Chúng tồn tại để **đặt tên cho các hiện tượng**, để khi bảo vệ có thể chỉ vào một
dòng log cụ thể thay vì nói "mọi thứ đều đúng".

---

## 1. Năm ca bắt buộc theo Charter mục 8

| Ca | `x` | `val(x)` | Kết quả | Charter chọn ca này để kiểm điều gì |
|---|---|---:|---|---|
| TC-001 | `0x00` | 0 | `abs=0x00 sign=0 ovf=0` | Số 0 **không có** `−0` trong bù 2; mux phải chọn nhánh "đi thẳng" |
| TC-002 | `0x7F` | +127 | `abs=0x7F sign=0 ovf=0` | Biên dương lớn nhất — nhánh "đi thẳng" với mọi bit dữ liệu bằng 1 |
| TC-003 | `0xFF` | −1 | `abs=0x01 sign=1 ovf=0` | **Ca lan truyền carry ngắn nhất** của bộ cộng +1: `~0xFF = 0x00`, cộng 1 ra `0x01` — carry chết ngay tại tầng 0, không tầng nào phải chờ. Ca **dài nhất** là TC-004 (`0x80`) |
| **TC-004** | **`0x80`** | **−128** | **`abs=0x80 sign=1 ovf=1`** | **Ca trọng tâm của đề** — ngoại lệ toán học, cờ tràn phải bật. Đồng thời là **ca lan truyền carry dài nhất** (xem §3.1) |
| TC-005 | `0xC0` | −64 | `abs=0x40 sign=1 ovf=0` | Số âm "bình thường"; carry lan **6 tầng** — ca sâu nhất trong các ca **không tràn**; đối chứng trực tiếp với TC-004 |

TC-004 và TC-005 **chỉ khác nhau một bit** (`x[6]`). Đây là cặp phản chứng đắt giá nhất của
hồ sơ: nó chứng minh `ovf` không phải là "cứ âm thì bật", mà thật sự dò mẫu `0x80`.

## 2. Năm ca tự xây dựng (đáp ứng REQ-A09-011)

| Ca | `x` | `val(x)` | Kết quả | Vì sao thêm ca này |
|---|---|---:|---|---|
| TC-006 | `0x81` | **−127** | `abs=0x7F sign=1 ovf=0` | **Ca biên sát TC-004.** Số âm lớn nhất về độ lớn mà **vẫn** biểu diễn được. Nếu logic phát hiện viết nhầm thành `x[7] & (x[6:0] != 0x7F)` hoặc `x <= 0x80`, ca này bắt lỗi ngay. |
| TC-007 | `0x01` | +1 | `abs=0x01 sign=0 ovf=0` | **Ca biên phía dương.** Giá trị dương nhỏ nhất; cùng với TC-003 tạo cặp `+1 / −1` có cùng độ lớn nhưng đi hai nhánh mux khác nhau. |
| TC-008 | `0x40` | +64 | `abs=0x40 sign=0 ovf=0` | Đối xứng với TC-005: **cùng `abs_val = 0x40`, khác `sign`**. Chứng minh `abs_val` thật sự bỏ dấu. |
| TC-009 | `0xAA` | −86 | `abs=0x56 sign=1 ovf=0` | Mẫu bit xen kẽ `1010_1010` — carry của bộ cộng +1 dừng ngay tầng 1, một ca "nông" của nhánh âm (nông nhất là TC-003 / TC-006, 0 tầng). |
| TC-010 | `0x55` | +85 | `abs=0x55 sign=0 ovf=0` | Mẫu bit xen kẽ ngược `0101_0101`, nhánh dương. Cùng TC-009 phủ hai mẫu bit nghịch đảo. |
| TC-011 | `0x80` ×2 | −128 | giống hệt nhau | **Ca không phụ thuộc lịch sử.** Đặt `x = 0x80` sau hai lịch sử khác nhau (`0x00 → 0x80` và `0x7F → 0x80`); đầu ra phải trùng khít. Đây là bằng chứng **hành vi** cho "0 ô nhớ", bổ trợ cho bằng chứng **cấu trúc** (0 flip-flop trong `synth_stat.txt`). |

## 3. Phân loại theo tiêu chí kỹ thuật của đề

### 3.1 Theo độ sâu lan truyền của bộ cộng +1

Bộ tăng cộng `1` vào `y = ~x`. Carry vào tầng `i` bằng `y[0] & y[1] & … & y[i−1]`, tức
`~x[0] & ~x[1] & … & ~x[i−1]`. Chuỗi **dừng** ở tầng đầu tiên có `y[j] = 0`, tức `x[j] = 1`.
Suy ra: số tầng thực sự lan truyền = **vị trí bit 1 thấp nhất của `x`** (ký hiệu `k`).
`k` nhỏ ⟹ chuỗi **nông**; `k` lớn ⟹ chuỗi **sâu**.

| Ca | `x` (nhị phân) | Bit 1 thấp nhất `k` | `~x` | `~x + 1` | Số tầng carry lan | Phân loại |
|---|---|---:|---|---|---:|---|
| TC-003 `−1` | `1111_1111` | 0 | `0000_0000` | `0000_0001` | **0** | 🟢 **Nông nhất** |
| TC-006 `−127` | `1000_0001` | 0 | `0111_1110` | `0111_1111` | **0** | 🟢 Nông nhất |
| TC-009 `−86` | `1010_1010` | 1 | `0101_0101` | `0101_0110` | 1 | 🟢 Nông |
| TC-005 `−64` | `1100_0000` | 6 | `0011_1111` | `0100_0000` | 6 | 🟠 Sâu — **sâu nhất trong các ca không tràn** |
| TC-004 `−128` | `1000_0000` | 7 | `0111_1111` | `1000_0000` | **7** | 🔴 **Sâu nhất** |
| TC-001 `0` | `0000_0000` | — | — | — | **không áp dụng** | ⚪ Nhánh dương — bộ tăng không được dùng |

Kiểm lại bằng tay cho hai đầu của bảng: `~0xFF = 0x00`, cộng 1 ra `0x01` — chỉ bit 0 đổi,
**không một tầng nào phải chờ carry**. Còn `~0x80 = 0x7F`, cộng 1 ra `0x80` — **cả 7 tầng
trên đều phải chờ carry từ tầng 0**.

> 🔎 **Chỗ dễ hiểu sai:** TC-004 (`−128`) **vừa** là ca quan trọng nhất về ngữ nghĩa (ca duy
> nhất bật `ovf`) **vừa** là ca sâu nhất về chuỗi carry ở mức RTL. Ở đề này hai khái niệm
> "ca biên" và "ca chuỗi dài nhất" **trùng nhau** — đừng lấy A09 làm ví dụ cho việc chúng
> luôn tách nhau. Ca sâu nhất mà **không** tràn là TC-005 (`−64`, 6 tầng); đó mới là cặp
> đối chứng đúng khi muốn tách "biên ngữ nghĩa" khỏi "biên độ trễ".
>
> **Quy ước đếm.** Testbench mục `[2c]` đo độ sâu bằng cách đếm số net `inc_c[0..7]` còn
> bằng 1, tức có tính **cả** carry-in hằng số `inc_c[0] = 1`. Con số nó in ra vì vậy là
> `k + 1`: **8 tầng tại `x = 0x80`**, **1 tầng tại `x = 0xFF` / `0x81`**. Hai cách đếm mô tả
> cùng một hiện tượng, chỉ khác ở chỗ có tính tầng 0 hay không; bảng trên đếm số tầng **thực
> sự phải chờ** carry của tầng trước. Vòng quét `[2c]` chỉ chạy nhánh âm nên ca `x = 0`
> không xuất hiện ở đó — khớp với ô "không áp dụng" của bảng.
>
> Số liệu STA sau tổng hợp còn cho thấy điều bất ngờ hơn: **không ca nào lan qua 7 tầng cả**,
> vì công cụ đã biến chuỗi ripple thành cây OR. Xem `03_ARCHITECTURE/datapath.md` §4.

### 3.2 Theo nhánh mux và tổ hợp cờ

| Nhánh mux | `sign` | `ovf` | Các ca | Có xảy ra? |
|---|:-:|:-:|---|---|
| Đi thẳng (`x ≥ 0`) | 0 | 0 | TC-001, 002, 007, 008, 010 | ✅ 128/256 giá trị |
| Bù 2 (`x < 0`), không tràn | 1 | 0 | TC-003, 005, 006, 009 | ✅ 127/256 giá trị |
| Bù 2, **tràn** | 1 | **1** | **TC-004** | ✅ **đúng 1/256 giá trị** |
| `sign = 0, ovf = 1` | 0 | 1 | — | ❌ **không thể xảy ra** |

Ô cuối là một bất biến ngầm: `ovf ⟹ sign`. Testbench đếm số ca tràn trên toàn bộ 256 giá
trị và **bắt buộc kết quả phải đúng bằng 1** (`$fatal` nếu khác). Đây là cách biến "chỉ có
−128 mới tràn" từ một lời khẳng định thành một phép đếm.

### 3.3 Ca **không** áp dụng cho A09

| Ca thường gặp ở đề khác | Vì sao không áp dụng |
|---|---|
| Reset / power-up | Không có ô nhớ, không có trạng thái khởi tạo |
| Đầu vào đổi cùng lúc cạnh clock | Không có clock |
| Ca setup/hold | Không có phần tử nhớ nào để vi phạm setup/hold |
| Tràn không dấu (`C`) | Đầu vào chỉ có **một** toán hạng, không có phép cộng hai số |
| `−0` | Bù 2 không có `−0` — đây là lý do dải bị lệch và sinh ra ca `−128` |
| Bão hoà về `0x7F` | Charter mục 3 đặt **ngoài phạm vi** (đo thử trong `tradeoff.md` §5) |

## 4. Quét vét cạn — vì sao đây là ca mạnh nhất

| | Con số |
|---|---:|
| Không gian đầu vào | `2⁸ = 256` |
| Vector đã chạy (kể cả ca có tên) | **266** |
| Sai lệch so với golden model | **0** |
| Vi phạm bất biến | **0** |
| Số giá trị làm `ovf = 1` | **1** (đúng `x = 0x80`) |

Vét cạn 256 giá trị **đóng hoàn toàn** không gian hành vi: không tồn tại đầu vào hợp lệ nào
chưa được thử. Nhưng phải nói rõ giới hạn của nó:

> Vét cạn chứng minh **hàm** đúng. Nó **không** chứng minh **kiến trúc** đúng. Một bản viết
> `assign abs_val = x[7] ? -x : x;` cũng PASS 256/256 — thực nghiệm ở
> `03_ARCHITECTURE/tradeoff.md` §4 cho thấy nó còn ra **đúng cùng diện tích**. Bằng chứng
> kiến trúc phải đọc từ RTL và netlist, không từ log mô phỏng.

## 5. Ca cần bổ sung khi chuyển sang gate-level / post-layout

| Ca | Vì sao chưa làm được bây giờ |
|---|---|
| Mô phỏng gate-level với SDF | Cần netlist + file SDF sau P&R — chưa chạy LibreLane |
| Đo glitch trên `abs_val` khi `x` đổi nhiều bit cùng lúc | Mô phỏng hành vi là zero-delay, không sinh glitch |
| Ca `x` đổi từ `0x7F` sang `0x80` (1 bit, nhưng đảo cả `sign` lẫn `ovf`) ở mức gate | Đây là ca chuyển mạch tốn công suất nhất; cần VCD gate-level mới đo được |
| Quét PVT nhiều góc | Mới chạy `tt_025C_1v80` |

---

*Phiên bản: v2.0 (thiết kế lại đúng đề Charter) · Ngày: 2026-09-24 · Truy vết: REQ-A09-010,
REQ-A09-011.*
