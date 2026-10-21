# A09 · Đánh đổi kiến trúc (Trade-off Analysis)

Mọi con số trong tài liệu này là **số đo thật**, sinh bằng cùng một quy trình: Yosys 0.33,
thư viện `sky130_fd_sc_hd` (`tt_025C_1v80`), cùng script tổng hợp, cùng máy. Các biến thể
được viết riêng để đo và đã được kiểm chứng **tương đương hàm** với mô hình chuẩn trên cả
256/256 giá trị trước khi lấy số liệu.

---

## 1. Câu hỏi trung tâm của đề

Charter mục 2 câu 2 hỏi thẳng: *"Lấy giá trị tuyệt đối trong phần cứng là làm gì — và nó
tốn bao nhiêu cell?"*

Trả lời ngắn: **18 cell · 118,864 µm² · 0 flip-flop**, trong đó phần **dấu** tốn **0 cell**
và phần **phát hiện −128** tốn **1 cell**.

## 2. Kiến trúc đã chọn

```
bù 2 vô điều kiện (đảo bit → cộng +1)  →  mux 2:1 chọn theo bit dấu  +  phát hiện 0x80
```

| Chỉ số | Giá trị |
|---|---:|
| Số cell | **18** |
| Flip-flop | **0** |
| Diện tích | **118,864 µm²** |
| Đường tới hạn | `x[0] → abs_val[6]`, **0,96 ns**, 3 cell |
| Công suất | 3,00 µW — 100 % tổ hợp, 0 % tuần tự |

Phân bố cell:

| Cell | Số lượng | Diện tích đơn vị (µm²) | Cộng |
|---|---:|---:|---:|
| `xnor2_1` | 5 | 8,7584 | 43,792 |
| `o21ai_0` | 3 | 5,0048 | 15,0144 |
| `o31ai_1` | 2 | 7,5072 | 15,0144 |
| `nor4_1` | 2 | 6,2560 | 12,512 |
| `a21o_1` | 1 | 7,5072 | 7,5072 |
| `or4_1` | 1 | 7,5072 | 7,5072 |
| `nand2b_1` | 1 | 6,2560 | 6,256 |
| `buf_1` | 1 | 3,7536 | 3,7536 |
| `clkinv_1` | 1 | 3,7536 | 3,7536 |
| `nand2_1` | 1 | 3,7536 | 3,7536 |
| **Tổng** | **18** | | **118,864** |

> 💡 **So với ước lượng của Charter (~110–160 cell).** Kết quả thật nhỏ hơn **6–9 lần**.
> Đây không phải lỗi của Charter: ước lượng đó mang tính "đặt chỗ" cho một ô 1×1 tile,
> còn số đo phản ánh mức độ mà `abc` rút gọn được một hàm 8 đầu vào rất thưa. Đúng cách
> báo cáo là nêu **cả hai** và nói rõ số nào là số đo.

## 3. Cờ tràn tốn bao nhiêu — đo bằng cách bỏ nó đi

Tổng hợp **hai bản cùng kiến trúc, cùng script**, chỉ khác có / không có đầu ra `ovf`:

| Phiên bản | Cell | Diện tích (µm²) |
|---|---:|---:|
| Không có `ovf` | 17 | 112,608 |
| **Có `ovf`** (bản nộp) | **18** | **118,864** |
| **Chênh lệch** | **+1** | **+6,256 (+5,56 %)** |

Chênh lệch đúng bằng **một cell `nor4_1`** (6,256 µm²). Trong netlist đó là cell `_12_`:

```verilog
sky130_fd_sc_hd__nor4_1 _12_ (.A(x[4]), .B(x[5]), .C(_01_), .D(_02_), .Y(ovf));
sky130_fd_sc_hd__nor4_1 _26_ (.A(x[4]), .B(x[5]), .C(_01_), .D(_02_), .Y(abs_val[7]));
```

**Hai cell giống hệt nhau về hàm và về chân vào.** Nói cách khác: toàn bộ chi phí của việc
phát hiện `−128` là **một bản sao của cell vốn đã có**, tồn tại chỉ vì mỗi cell lái được một
chân ra. Nếu hợp đồng giao diện cho phép nối `uio_out[1]` thẳng vào `uo_out[7]` thì chi phí
phát hiện `−128` sẽ là **0** (🟡 OPEN-3, `functional_spec.md` §5.3).

Đây là số liệu trả lời trực tiếp Charter mục 9 — xem `implementation-notes_A09.md` §8.

## 4. So bốn kiến trúc — số đo thật

| # | Kiến trúc | Cell | Diện tích (µm²) | So với bản chọn | Ghi chú |
|---|---|---:|---:|---:|---|
| **A** | **Bù 2 vô điều kiện + mux (đã chọn)** | **18** | **118,864** | — | Cấu trúc hiện rõ, đúng Charter mục 10 |
| B | Đảo bit **có điều kiện** (XOR với `sign`) + cộng carry-in = `sign` | 24 | 163,9072 | **+6 cell, +37,9 %** | Sách vở coi là "rẻ hơn" — thực đo **đắt hơn** |
| C | Viết tắt bằng toán tử `x[7] ? (~x+1) : x` | 18 | 118,864 | **±0** | **Cấm** trong RTL nộp bài |
| D | Bão hoà về `0x7F` khi tràn | 23 | 131,376 | +5 cell, +10,5 % | Charter mục 3: **ngoài phạm vi** |

Cả bốn đều đã kiểm tương đương hàm trên 256/256 giá trị (trừ D, vốn cố ý khác ở đúng ca
`x = −128`).

### Vì sao B — kiến trúc "tiết kiệm" theo sách — lại đắt hơn 38 %

Kiến trúc B là thủ thuật kinh điển: `|x| = (x ⊕ sign) + sign`, dùng **một** bộ cộng với
carry-in bằng `sign`, khỏi cần mux. Lập luận "ít phần cứng hơn" đúng ở mức **sơ đồ**, nhưng
sai ở mức **tổng hợp**, vì:

* Trong kiến trúc A, chuỗi cộng +1 có **carry-in là hằng số 1**, nên carry tầng `i` rút gọn
  thành `NOR(x[i−1..0])` — một phép thu gọn trên **đầu vào gốc**, cây hoá được và **dùng
  chung** giữa nhiều bit (tín hiệu `_01_` phục vụ 5 nơi).
* Trong kiến trúc B, carry-in là `sign` — một **biến**. Chuỗi carry trở thành hàm của cả
  `x` lẫn `sign` ở mọi tầng, không rút gọn thành phép thu gọn thuần trên đầu vào, nên
  `abc` phải dựng chuỗi thật: 5 × `xor2_1` + 4 × `xnor2_1` + nhiều cổng phụ.
* Bản B còn kéo vào một cell `lpflow_isobufsrc_1` — loại cell thường nằm trong danh sách
  `dont_use` của nhiều dòng chảy vật lý, tức số liệu của B còn có thể xấu thêm khi cấm cell.

**Bài học rút ra:** "ít phép toán trên sơ đồ" không đồng nghĩa "ít cell sau tổng hợp".
Hằng số hoá đầu vào (carry-in = 1) mở ra cơ hội rút gọn mà một toán hạng biến không có.
Đây là kết quả **trái với trực giác sách vở** và là số liệu riêng của hồ sơ này.

### Vì sao C — viết tắt bằng toán tử — ra **đúng cùng diện tích**

Cả A và C đều cho 18 cell · 118,864 µm² (phân bố cell hơi khác: C có thêm `o21a_1`,
`o22ai_1`, bớt một `xnor2_1`). Nghĩa là **mô tả tường minh không phải trả giá** ở đề này.

Vậy tại sao vẫn cấm C? Vì mục tiêu của đề **không phải** tối ưu diện tích, mà là **quan sát
được cấu trúc**. Với C:

* không đếm được số tầng của bộ cộng +1;
* không chỉ ra được "logic phát hiện 0x80" là phần nào (Charter mục 9 bắt buộc);
* không chứng minh được với mentor rằng mình hiểu phép bù 2, vì công cụ làm hộ.

Nói cách khác: A và C **giống nhau về netlist, khác nhau về giá trị dạy học và về khả năng
truy vết**. Charter mục 10 chốt cấu trúc phải nhìn thấy được, nên A là bản nộp.

### Vì sao D — bão hoà — không được dùng

Bão hoà (`x = −128` → `abs_val = 0x7F = 127`) làm đầu ra **luôn** là số bù 2 hợp lệ, nghe
rất tiện. Nhưng:

* Charter mục 3 đặt *"Giá trị tuyệt đối bão hoà"* **ngoài phạm vi** — dùng là vi phạm phạm vi đề;
* nó **cố ý trả sai** 1 đơn vị tại đúng ca mà đề đặt ra để kiểm;
* đo được: **+5 cell, +12,512 µm² (+10,5 %)**;
* và nó **phá** bất biến INV-1: `abs_val` không còn bằng `|x|` trên toàn miền.

## 5. Đánh đổi không được phép trong đề này

| Đánh đổi | Vì sao không |
|---|---|
| Mở rộng `abs_val` thành 9 bit | Charter mục 3: *"số rộng hơn 8 bit"* ngoài phạm vi; và **không cần** — `\|x\| ≤ 128` vừa khít 8 bit không dấu |
| Bão hoà về `0x7F` | Charter mục 3 loại (đo ở §4, kiến trúc D) |
| Bỏ `ovf` cho gọn | Charter mục 4 chỉ định `uio_out[1]` = cờ tràn; bỏ là sai giao diện |
| Thêm thanh ghi chốt đầu ra vào **lõi** | Đổi loại mạch sang Tuần tự, vi phạm Charter mục 10 |
| Viết `assign abs_val = x[7] ? -x : x;` | Mất khả năng quan sát cấu trúc (§4, kiến trúc C) |
| Tự sửa netlist bằng tay để bỏ cell `_12_` trùng lặp | Charter mục 3: tự tối ưu netlist bằng tay ngoài phạm vi |

---

*Phiên bản: v2.0 (thiết kế lại đúng đề Charter) · Ngày: 2026-09-24.*
