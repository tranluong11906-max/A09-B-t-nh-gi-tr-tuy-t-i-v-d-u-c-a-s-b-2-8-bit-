# A09 — Bộ tính giá trị tuyệt đối và dấu của số bù 2 8-bit · Ghi chú thực hiện

> **Lưu ý truy vết nguồn.** Gói mã nguồn nhận ban đầu (`A09_Counter_Implementation_Validation`)
> chứa một **bộ đếm 4-bit tuần tự**, thuộc danh mục đề cũ, **không phải** đề Charter này.
> Bản gốc đã đóng băng ở `08_ORIGINAL_SOURCE/`; RTL, mô hình chuẩn và testbench đã được viết
> lại đúng đề (giảng viên duyệt). Chẩn đoán: `05_VERIFICATION/known_issues.md`.
> Nhật ký thay thế: `08_ORIGINAL_SOURCE/PATCHLOG.md`.

---

## 1. Bài toán này thực chất là gì

Bề mặt: "bỏ dấu trừ đi". Nghe như một dòng code.

Thực chất, Charter chọn A09 vì nó là **ví dụ sạch nhất** để dạy một điều rất khó dạy:
**một hệ biểu diễn số có thể không đối xứng, và sự không đối xứng đó là tính chất toán học
chứ không phải lỗi của người thiết kế.**

Charter mục 10 nói thẳng chỗ hay tắc: *"Bỏ qua ca −128 vì 'hiếm gặp'. Đó đúng là ca đề ra
để kiểm."* Toàn bộ hồ sơ này tồn tại để biến câu đó từ một lời nhắc thành một **phép đếm**:
trên 256 giá trị vào, có **đúng 1** giá trị làm cờ tràn bật, và testbench `$fatal` nếu con
số đó khác 1.

Bối cảnh ứng dụng — chuẩn hoá tín hiệu lệch tâm trong bộ đo — không phải trang trí. Nó
quyết định câu trả lời cuối: tầng sau chỉ cần **so độ lớn với ngưỡng**, mà so không dấu thì
`0x80 = 128` là **đúng**. Ca `−128` vì vậy không làm hỏng ứng dụng; nó chỉ đòi hỏi hợp đồng
giao diện nói rõ `uo_out` đọc theo hệ không dấu.

## 2. Bản chất kỹ thuật — cơ chế hoạt động

### 2.1 Vì sao dải bù 2 lệch

Bù 2 `n` bit biểu diễn `[−2ⁿ⁻¹ … +2ⁿ⁻¹−1]`. Có `2ⁿ⁻¹` số âm nhưng chỉ `2ⁿ⁻¹−1` số dương,
vì mẫu bit `00…0` đã bị số 0 chiếm — **không có `−0`**. Chính việc "tiết kiệm" được `−0`
(ưu điểm lớn nhất của bù 2 so với dấu-độ lớn) là thứ tạo ra sự lệch.

Lấy trị tuyệt đối là ánh xạ tập âm (128 phần tử) vào tập dương (127 phần tử). Theo nguyên
lý chuồng bồ câu, **không tồn tại** ánh xạ giữ nguyên độ rộng mà không mất mát. `−128` là
phần tử bị dư ra. Điều này đúng với mọi hiện thực, phần cứng lẫn phần mềm.

### 2.2 Phép bù 2 trong phần cứng

```
−x = (~x) + 1
```

Hai bước, ánh xạ thẳng thành hai tầng phần cứng:

```
x_inv[i] = ~x[i]                          ← 8 INV, song song, độ sâu 1
neg[i]   = x_inv[i] ^ c[i]                ← 8 XOR
c[i+1]   = x_inv[i] & c[i] ,  c[0] = 1    ← 8 AND, chuỗi carry
```

Rồi chọn:

```
abs_val[i] = sign ? neg[i] : x[i]         ← 8 mux 2:1, sel = x[7]
```

### 2.3 Điểm mấu chốt: carry của bộ TĂNG không phải chuỗi thật

Khai triển `c[i+1]`:

```
c[i+1] = x_inv[i] & c[i] = ~x[i] & ~x[i−1] & … & ~x[0] = NOR(x[i], …, x[0])
```

Vế phải **chỉ chứa các bit đầu vào**. Nó là một phép **thu gọn AND kết hợp**, nên cây hoá
được: thay vì 8 mức nối tiếp, công cụ dựng cây sâu ~2 mức và dùng chung tín hiệu trung gian.

> **Đây là chỗ A09 khác hẳn A01.** Trong bộ cộng hai số (A01),
> `carry[i+1] = maj(a[i], b[i], carry[i])` — hàm đa số **không** khai triển được thành phép
> thu gọn trên đầu vào, nên chuỗi 8 tầng tồn tại thật (đo được: 1,34 ns / 8 cell). Trong
> A09, "ripple" là **cách viết**, không phải **cấu trúc cuối cùng** (đo được: 0,96 ns /
> 3 cell). Hai đề dùng cùng chữ "chuỗi carry" nhưng nói về hai hiện tượng khác nhau.

### 2.4 Phát hiện `−128`

```
ovf = x[7] & ~(x[6] | x[5] | x[4] | x[3] | x[2] | x[1] | x[0])
```

Tức "bit dấu bằng 1 **và** bảy bit thấp đều bằng 0" — đúng mẫu `0x80`.

Cách khác cũng đúng: `−x == x` (chỉ `0x00` và `0x80` thoả), nhưng phải loại thêm trường hợp
`x = 0`. Cách dùng mẫu bit là đặc tả trực tiếp, không cần loại trừ, và đếm được chi phí.

## 3. Đọc mã nguồn: RTL làm gì

Toàn bộ kiến trúc nằm trong bốn khối:

```systemverilog
assign sign = x[7];                                    // TẦNG 0 — 0 cổng

for (gi = 0; gi < 8; gi++)                             // TẦNG 1 — đảo bit
    assign x_inv[gi] = ~x[gi];

assign inc_c[0] = 1'b1;                                // TẦNG 2 — cộng +1
for (gi = 0; gi < 8; gi++) begin
    assign neg[gi]     = x_inv[gi] ^ inc_c[gi];
    assign inc_c[gi+1] = x_inv[gi] & inc_c[gi];
end

for (gi = 0; gi < 8; gi++)                             // TẦNG 3 — mux theo dấu
    assign abs_val[gi] = (sign & neg[gi]) | (~sign & x[gi]);

assign low7_zero = ~(x[6]|x[5]|x[4]|x[3]|x[2]|x[1]|x[0]);
assign ovf       = x[7] & low7_zero;                   // TẦNG 4 — phát hiện 0x80
```

Bốn điểm cần giảng kỹ:

1. **`generate for` là nhân bản KHÔNG GIAN.** Nó tạo 8 bản sao phần cứng tồn tại đồng thời,
   không phải 8 lần chạy tuần tự. Sinh viên quen lập trình phần mềm gần như luôn hiểu nhầm.
2. **`inc_c[0] = 1'b1` chính là số 1 được cộng vào.** Đây là chỗ "cộng 1" biến thành phần
   cứng: không có bộ cộng nào cả, chỉ có một carry-in bị đặt cứng.
3. **`inc_c[8]` khai báo nhưng không dùng.** Nó chỉ bằng 1 khi `x = 0x00`, mà khi đó mux đã
   chọn nhánh đi thẳng. Công cụ tổng hợp loại bỏ toàn bộ logic sinh nó — và đó là hành vi
   đúng, không phải cảnh báo cần sửa.
4. **Mux viết dạng tổng-của-tích, không dùng `? :`.** Mục đích là để cấu trúc hiện trong mã
   nguồn. (Sau tổng hợp mux biến mất — xem §6.)

### Điều tuyệt đối không được viết

```systemverilog
assign abs_val = x[7] ? -x : x;    // ❌ CẤM trong RTL nộp bài
```

Toán tử `-` cho phép công cụ tự chọn kiến trúc, xoá mất chính thứ Charter mục 2 và mục 9
yêu cầu quan sát. Thực nghiệm cho thấy bản viết tắt ra **đúng cùng 18 cell / 118,864 µm²**
(`03_ARCHITECTURE/tradeoff.md` §4) — tức lệnh cấm này **không** vì lý do diện tích, mà vì
lý do **truy vết và dạy học**. Toán tử tắt chỉ được dùng trong
`05_VERIFICATION/golden_model/`, nơi chúng là chuẩn so sánh độc lập.

## 4. Vì sao chọn kiến trúc này

Không phải vì "bù 2 vô điều kiện + mux" là kiến trúc đẹp nhất trên giấy — mà vì:

| Tiêu chí | Kiến trúc đã chọn |
|---|---|
| Charter mục 10 đòi nhìn thấy "đảo bit + cộng +1 + phát hiện 0x80" | ✅ Ba tầng hiện rõ, đếm được |
| Đo được chi phí riêng của phần phát hiện `−128` (Charter mục 9) | ✅ Tách được: +1 cell, +6,256 µm² |
| Diện tích | ✅ 118,864 µm² — nhỏ nhất trong 4 kiến trúc đã đo |
| Độ trễ | ✅ 0,96 ns |
| 0 ô nhớ | ✅ 0 flip-flop |

Đáng nói: kiến trúc "tiết kiệm theo sách" (đảo bit **có điều kiện** + cộng carry-in = `sign`)
đo được **24 cell / 163,9 µm²**, tức **đắt hơn 37,9 %**. Lý do: carry-in là biến nên chuỗi
carry không rút gọn được thành phép thu gọn trên đầu vào. Phân tích đầy đủ:
`03_ARCHITECTURE/tradeoff.md` §4.

## 5. Cách thực hiện — lộ trình 8 bước

| # | Bước | Công cụ | Bằng chứng sinh ra | Trạng thái |
|---|---|---|---|---|
| 1 | Phát hiện gói nguồn thuộc đề khác, đóng băng bản gốc | `diff`, đọc RTL | `05_VERIFICATION/known_issues.md` | ✅ |
| 2 | Suy đặc tả từ Charter mục 1/2/4/8/9/10 | — | `02_SPECIFICATION/functional_spec.md` | ✅ |
| 3 | Viết mô hình chuẩn Python độc lập (8 bất biến) | CPython 3 | `python_reference_run.log` | ✅ PASS |
| 4 | Viết RTL với bù 2 và mux **tường minh** | — | `04_IMPLEMENTATION/rtl/a09_abs_sign.sv` | ✅ |
| 5 | Viết testbench tự kiểm + quét vét cạn 256 | Icarus Verilog 12.0 | `simulation.log` | ✅ 266 vector / 0 lỗi |
| 6 | Tổng hợp lên sky130, **kiểm 0 flip-flop** | Yosys 0.33 | `synth_stat.txt` | ✅ 18 cell, 0 FF |
| 7 | Đo chi phí riêng của cờ tràn (tổng hợp 2 bản) + so 4 kiến trúc | Yosys 0.33 | `03_ARCHITECTURE/tradeoff.md` §3–4 | ✅ +1 cell |
| 8 | STA với clock ảo, đọc đường tới hạn | OpenSTA | `06_GDSII/sta/` | ✅ 0,96 ns |
| — | Physical design RTL→GDSII | LibreLane + sky130A | `06_GDSII/` | ⬜ chưa chạy |

## 6. Số liệu thật đã đo được và cách đọc chúng

| Chỉ số | Giá trị | Công cụ |
|---|---:|---|
| Vector kiểm chứng | 266 chạy, **256/256** vét cạn khớp, 0 lỗi | Icarus Verilog 12.0 |
| Vi phạm bất biến | **0** | như trên |
| Số ca làm `ovf = 1` | **1 / 256** (đúng `x = −128`) | như trên |
| Số cell | **18** | Yosys 0.33 + `sky130_fd_sc_hd` |
| **Flip-flop** | **0** | như trên |
| Diện tích | **118,864 µm²** | như trên |
| Bản không có `ovf` | 17 cell · 112,608 µm² | như trên |
| Đường tới hạn | `x[0] → abs_val[6]`, 3 cell | OpenSTA |
| **Độ trễ tổ hợp** | **0,96 ns** (slack 9,04 ns so `vclk` 10 ns) | như trên |
| Đường nhanh nhất | `x[7] → sign`, **0,00 ns**, 0 cell | như trên |
| WNS / TNS | 0,00 / 0,00 | như trên |
| Công suất | **3,00 µW** — 100 % tổ hợp, 0 % tuần tự | như trên |

### Từng con số chứng minh gì — và KHÔNG chứng minh gì

| Con số | **Chứng minh** | **KHÔNG chứng minh** |
|---|---|---|
| 256/256 khớp | Hàm của DUT **tương đương** golden model trên toàn bộ không gian đầu vào | Kiến trúc là "bù 2 + mux". Bản viết tắt bằng toán tử cũng PASS 256/256 |
| 0 flip-flop | Đúng phân loại Tổ hợp của Charter, xác nhận bởi **ba nguồn độc lập** (bảng cell, công suất Sequential 0 %, TC-011) | Netlist tương đương RTL — cần mô phỏng gate-level |
| 18 cell · 118,864 µm² | Lấy trị tuyệt đối 8-bit là phép **rất rẻ** — nhỏ hơn 6–9 lần ước lượng 110–160 cell của Charter | Diện tích sau P&R (sẽ khác vì có dây và cell bị `dont_use`) |
| +1 cell cho `ovf` | Chi phí phát hiện `−128` ở mức sau tổng hợp | Chi phí sau P&R; và chi phí này có thể về 0 nếu cho phép nối chung chân |
| 0,96 ns | Độ trễ **ở mức sau tổng hợp**, góc `tt_025C_1v80` | Độ trễ thật sau routing (sẽ **lớn hơn**, chưa có RC dây) |
| 3,00 µW | Thứ tự độ lớn công suất | Công suất thật của ứng dụng — dùng activity mặc định, không lấy từ VCD |

## 7. Trả lời các câu hỏi kỹ thuật của Charter (mục 2)

### Câu 1 — Vì sao `−128` là trường hợp đặc biệt, và phần cứng phát hiện nó bằng cách nào?

**Vì sao đặc biệt:** dải bù 2 8 bit là `[−128 … +127]`, không đối xứng vì bù 2 không có
`−0`. `|−128| = +128` không nằm trong dải **có dấu**. Đây là tính chất của hệ biểu diễn,
không phải lỗi thiết kế (chi tiết §2.1 và §8).

**Phần cứng phát hiện bằng cách nào:** dò **mẫu bit** `0x80` —
`ovf = x[7] & NOR(x[6:0])`. Sau tổng hợp nó là **đúng một cell**
`_12_ sky130_fd_sc_hd__nor4_1`, và cell đó có bốn chân vào **giống hệt** cell `_26_` đang
lái `abs_val[7]`.

Một cách phát hiện tương đương, rất đáng nói khi bảo vệ: **`−128` là giá trị âm duy nhất mà
phép bù 2 trả về chính nó** (`−(−128) = −128` trong 8 bit). Nghĩa là `ovf` cũng có thể viết
là `sign & (neg == x)`. Hai cách cho cùng kết quả trên 256/256 — RTL dùng cách mẫu bit vì nó
đếm được chi phí rõ ràng hơn.

### Câu 2 — Lấy giá trị tuyệt đối trong phần cứng là làm gì, và tốn bao nhiêu cell?

**Làm gì:** đảo toàn bộ bit, cộng 1, rồi chọn giữa kết quả đó và số gốc theo bit dấu.

**Tốn bao nhiêu:** **18 cell · 118,864 µm² · 0 flip-flop**, chia ra:

| Phần | Chi phí đo được |
|---|---|
| Tách bit dấu (`sign`) | **0 cell** — `assign sign = x[7];`, 0,00 ns |
| Bù 2 + mux (`abs_val`) | 17 cell · 112,608 µm² |
| Phát hiện `−128` (`ovf`) | **1 cell** `nor4_1` · 6,256 µm² (+5,56 %) |

Cách đo: tổng hợp hai bản cùng script, chỉ khác có/không có `ovf`, rồi trừ.

### Câu 3 — Cờ tràn ở đây khác cờ tràn của phép cộng ở chỗ nào?

Khác về **bản chất thông tin**, không chỉ khác công thức.

| | Cờ `V` của phép cộng (A01) | Cờ `ovf` của A09 |
|---|---|---|
| Nguyên nhân | Kết quả thật cần **9 bit**, bit thứ 9 bị mất | Kết quả thật là `+128`, vừa **8 bit không dấu** |
| Dữ liệu ra | **Sai** — không khôi phục được từ 8 bit còn lại | **Đúng** — `0x80` đọc không dấu đúng bằng 128 |
| Ý nghĩa cờ | "Con số này hỏng, đừng dùng" | "Đừng đọc con số này theo hệ có dấu nữa" |
| Số ca kích hoạt | Phụ thuộc cả hai toán hạng, rất nhiều tổ hợp | **Đúng 1 / 256** giá trị vào |
| Có thể tránh bằng cách nới độ rộng? | Có — cộng trong 9 bit là hết tràn | Không cần — 8 bit **không dấu** đã đủ |

Nói gọn: `V` là cờ **mất mát dữ liệu**; `ovf` của A09 là cờ **đổi hệ diễn giải**. Bằng chứng
định lượng cho vế "không mất dữ liệu": bất biến INV-1 (`unsigned(abs_val) == |x|`) đúng
**256/256**, kể cả tại `x = −128` — không cần ngoại lệ.

## 8. Trả lời câu phân tích riêng (Charter mục 9)

> *"Giải thích vì sao trường hợp −128 là ngoại lệ toán học chứ không phải lỗi thiết kế, và
> chỉ ra phần logic nào trong báo cáo tổng hợp phục vụ riêng cho việc phát hiện nó."*

### ① Vì sao là ngoại lệ toán học

Đếm phần tử: bù 2 8 bit có **128** giá trị âm và **127** giá trị dương. Trị tuyệt đối là
ánh xạ từ tập 128 phần tử vào tập 127 phần tử — **không tồn tại** ánh xạ đơn ánh nào giữ
nguyên độ rộng và hệ biểu diễn. Sự lệch này sinh ra từ việc bù 2 không có `−0`, tức từ
chính ưu điểm của hệ. Không có cách viết RTL nào xoá được nó.

Bằng chứng nó **không** phải lỗi thiết kế: kết quả `0x80` vẫn **đúng** về số học khi đọc
không dấu (`= 128`). Đo được: INV-1 đúng 256/256, **không loại trừ ca nào**. Nếu đây là
lỗi thiết kế thì phải có ít nhất một giá trị cho kết quả sai — không có giá trị nào như vậy.

### ② Phần logic phục vụ riêng cho việc phát hiện

Đo bằng cách tổng hợp hai bản cùng script, chỉ khác có/không có đầu ra `ovf`:

| Phiên bản | Cell | Diện tích (µm²) |
|---|---:|---:|
| Không có `ovf` | 17 | 112,608 |
| Có `ovf` | **18** | **118,864** |
| **Chênh** | **+1 cell** | **+6,256 µm² (+5,56 % ; 5,26 % tổng diện tích)** |

Cell đó là `_12_` trong `06_GDSII/synthesis/netlist.v`:

```verilog
sky130_fd_sc_hd__nor4_1 _12_ (.A(x[4]), .B(x[5]), .C(_01_), .D(_02_), .Y(ovf));
sky130_fd_sc_hd__nor4_1 _26_ (.A(x[4]), .B(x[5]), .C(_01_), .D(_02_), .Y(abs_val[7]));
//  _01_ = or4(x[0],x[1],x[2],x[3])   ;   _02_ = nand2b(A_N=x[6], B=x[7])
//  => Y = ~(x4|x5|(x0|x1|x2|x3)|~(~x6 & x7)) = (x == 8'h80)
```

### ③ Ba kết quả đáng nói

**① Logic phát hiện `−128` là bản SAO của logic đã có sẵn.** `_12_` và `_26_` cùng hàm,
cùng chân vào, khác đúng chân ra. Nghĩa là `ovf ≡ abs_val[7]` — bit cao nhất của kết quả
**chính là** cờ tràn. Chi phí 6,256 µm² tồn tại **chỉ vì** hai chân ra vật lý khác nhau;
về mặt logic, phát hiện `−128` **miễn phí**. Đây là bằng chứng cấu trúc (đọc netlist),
mạnh hơn bằng chứng mô phỏng, và khớp đúng với bất biến INV-6 đã đặt ra **trước** khi tổng hợp.

STA còn cho bằng chứng thứ ba, độc lập với cả hai: `report_checks -to` cho `ovf` và
`abs_val[7]` **đúng cùng một arrival 0,74 ns** và cùng startpoint `x[0]` — hai chân ra của
hai cell tương đương thì không thể khác nhau về thời gian. Bảng đầy đủ từng chân:
`03_ARCHITECTURE/timing_diagram.md` §4.

**② Chuỗi ripple 8 tầng trong RTL không tồn tại trong netlist.** Đường tới hạn chỉ 3 cell /
0,96 ns, vì carry của bộ **tăng** rút gọn thành `NOR(x[i−1..0])` — phép thu gọn trên đầu
vào, cây hoá được. So sánh trực tiếp với A01 (bộ cộng hai số, cùng thư viện, cùng script):
**8 cell / 1,34 ns**. Kết luận về độ sâu **bắt buộc** đọc từ netlist + STA, không suy từ RTL.

**③ Công suất xác nhận lại "0 ô nhớ" một cách độc lập.** `report_power` cho **100 %** công
suất thuộc nhóm Combinational, **0 %** Sequential, **0 %** Clock — nguồn bằng chứng khác với
bảng cell của Yosys, cùng một kết luận.

## 9. Những chỗ sinh viên hay sai và cách phát hiện

| # | Sai lầm | Hậu quả | Phát hiện bằng bằng chứng nào |
|---|---|---|---|
| 1 | Bỏ qua ca `−128` vì "hiếm gặp" | Trượt đúng ca Charter mục 10 nêu tên | Testbench đếm số ca tràn và `$fatal` nếu khác 1 |
| 2 | Viết `assign abs_val = x[7] ? -x : x;` | Mất khả năng quan sát cấu trúc; không trả lời được mục 9 | Đọc RTL; và không tách được chi phí của `ovf` |
| 3 | Tưởng `abs_val = 0x80` là **sai** | Kết luận ngược: coi ngoại lệ toán học thành lỗi | INV-1 đúng 256/256 khi đọc không dấu |
| 4 | Đọc `uo_out` theo hệ **có dấu** | Ra `−128` thay vì `+128`, sai dấu ngay tại ca cần đúng | 🟡 OPEN-1 trong `functional_spec.md` §5.3 |
| 5 | Bão hoà về `0x7F` cho "an toàn" | Vi phạm Charter mục 3 (ngoài phạm vi), phá INV-1, +10,5 % diện tích | `tradeoff.md` §4 kiến trúc D |
| 6 | Mở rộng đầu ra thành 9 bit | Vi phạm Charter mục 3; và **không cần** vì `\|x\| ≤ 128` vừa 8 bit không dấu | `tradeoff.md` §5 |
| 7 | Viết `ovf = sign` (cứ âm là tràn) | Sai 127/128 số âm | TC-005 (`−64`) vs TC-004 (`−128`) — chỉ khác 1 bit |
| 8 | Tin rằng "8 tầng ripple trong RTL ⟹ 8 tầng trong chip" | Ước lượng độ trễ sai gấp ~3 lần | STA: 3 cell / 0,96 ns, không phải 8 |
| 9 | Kết luận "mô phỏng PASS ⟹ kiến trúc đúng" | Kiểm chứng chức năng mù về cấu trúc | Bản viết tắt bằng toán tử cũng PASS 256/256 |
| 10 | Coi `sign` là tín hiệu **điều khiển** | Hiểu sai phân loại mạch | `control.md` §2 — `sign` sinh từ dữ liệu; netlist không còn cell mux |
| 11 | Đặt thanh ghi chốt đầu ra **vào lõi** | Đổi loại mạch sang Tuần tự, vi phạm Charter mục 10 | `synth_stat.txt` sẽ có cell `__dfxtp`; `report_power` có Sequential ≠ 0 % |
| 12 | So số cell của A09 với đề khác | Hai đề có thể chạy môi trường khác | `02_SPECIFICATION/parameters.md` — điều kiện tạo bằng chứng |

## 10. Câu hỏi mentor nên đặt khi bảo vệ

| # | Câu hỏi | Đáp án mong đợi |
|---|---|---|
| 1 | Vì sao `−128` là ca đặc biệt? | Dải bù 2 không đối xứng (128 số âm, 127 số dương) vì không có `−0`. `+128` không nằm trong dải có dấu. Là tính chất hệ biểu diễn, không phải lỗi. |
| 2 | Vậy khối này trả về gì khi `x = −128`, và có sai không? | Trả `0x80` và bật `ovf`. **Không sai**: `0x80` đọc không dấu đúng bằng 128. INV-1 đúng 256/256, không loại trừ ca nào. |
| 3 | Vì sao không bão hoà về `0x7F` cho gọn? | Charter mục 3 đặt bão hoà ngoài phạm vi; nó cố ý trả sai 1 đơn vị tại đúng ca cần kiểm; và tốn thêm 5 cell (+10,5 %). |
| 4 | Vì sao không mở đầu ra thành 9 bit? | Charter mục 3 loại; và **không cần** — `\|x\| ∈ [0,128]` vừa khít 8 bit không dấu. 9 bit chỉ cần nếu muốn kết quả vẫn là số **có dấu** hợp lệ. |
| 5 | Chỉ ra trong báo cáo tổng hợp phần logic phát hiện `−128`. | Cell `_12_ sky130_fd_sc_hd__nor4_1`, 6,256 µm², = +1 cell so với bản không có `ovf`. Nó là bản sao của `_26_` đang lái `abs_val[7]`. |
| 6 | `ovf` có mang thông tin gì mà `abs_val` chưa có không? | Không. `ovf ≡ abs_val[7]` — chứng minh ở netlist (hai cell cùng hàm, cùng chân vào) và ở INV-6 (256/256). |
| 7 | Cờ tràn ở đây khác cờ `V` của bộ cộng thế nào? | `V` báo **mất dữ liệu** (kết quả cần 9 bit); `ovf` báo **đổi hệ diễn giải** (dữ liệu vẫn đúng khi đọc không dấu). |
| 8 | RTL viết 8 tầng ripple — chip có 8 tầng không? | Không. STA cho 3 cell / 0,96 ns. Carry của bộ **tăng** là `NOR(x[i−1..0])`, phép thu gọn trên đầu vào nên cây hoá được. Khác hẳn carry của bộ **cộng** (A01: 8 cell / 1,34 ns). |
| 9 | `sign` lái mux — đó có phải tín hiệu điều khiển không? | Không. Nó tính từ chính dữ liệu (`x[7]`), không đến từ ngoài, không có trạng thái. Sau tổng hợp mux còn tan vào XOR. |
| 10 | Lấy bit dấu tốn bao nhiêu cell? | **0**. Netlist ghi `assign sign = x[7];`, STA cho đường `x[7] → sign` dài 0,00 ns. |
| 11 | 256/256 PASS — đã chứng minh kiến trúc đúng chưa? | Chưa. Kiểm chứng chức năng mù về cấu trúc; bản viết tắt bằng toán tử cũng PASS và còn ra **đúng cùng diện tích**. Bằng chứng kiến trúc phải đọc từ RTL và netlist. |
| 12 | Làm sao chắc khối không có ô nhớ? | Ba nguồn độc lập: bảng cell (0 FF), công suất (Sequential 0 %), và TC-011 (đầu ra không phụ thuộc lịch sử). |
| 13 | Con số 0,96 ns có phải độ trễ thật của chip không? | Không. Độ trễ **sau tổng hợp**, chưa có RC dây, một góc PVT. Sau routing sẽ lớn hơn. |
| 14 | Charter ước lượng 110–160 cell, bạn đo 18 — ai sai? | Không ai sai. Ước lượng là "đặt chỗ" cho ô 1×1 tile; 18 là số đo thật với `sky130_fd_sc_hd` và Yosys 0.33. Phải báo cáo cả hai và nói rõ số nào là số đo. |

## 11. Giới hạn: đã chứng minh được gì, chưa chứng minh được gì

### Đã chứng minh

1. Hàm của A09 đúng trên **toàn bộ** không gian đầu vào (256/256, 0 lỗi, 0 vi phạm bất biến).
2. Mười bất biến của đặc tả luôn giữ, trong đó INV-1 (`unsigned(abs_val) == |x|`) đúng **kể
   cả tại `x = −128`**.
3. Ba hiện thực độc lập (Python, SV reference, RTL) đồng ý với nhau.
4. **0 ô nhớ** — xác nhận bởi ba bằng chứng độc lập (bảng cell, báo cáo công suất, TC-011).
5. Lấy trị tuyệt đối 8-bit là phép **rất rẻ**: 18 cell · 118,864 µm², nhỏ hơn 6–9 lần ước
   lượng 110–160 cell của Charter.
6. Phần **dấu** tốn **0 cell**; phần **phát hiện `−128`** tốn **1 cell** (6,256 µm²) và là
   bản sao của cell lái `abs_val[7]`.
7. Chuỗi ripple trong RTL **không** tồn tại trong netlist: 3 cell / 0,96 ns, so với A01
   8 cell / 1,34 ns trên cùng thư viện.
8. Kiến trúc "đảo bit có điều kiện" đắt hơn **37,9 %** so với kiến trúc đã chọn.

### Chưa chứng minh

1. Netlist tương đương RTL về chức năng — cần mô phỏng gate-level.
2. Độ trễ **thật sau routing** — 0,96 ns chưa tính ký sinh dây.
3. Biên an toàn qua các góc PVT — mới chạy `tt_025C_1v80`.
4. Công suất thật của ứng dụng — 3,00 µW dùng activity mặc định, không lấy từ VCD.
5. Hành vi glitch thật trên `abs_val` — cần gate-level + SDF.
6. Layout tuân thủ quy tắc chế tạo (DRC), khớp netlist (LVS), và có file GDSII.

### Còn để mở — chờ giảng viên chốt

| # | Điểm mở | Xem |
|---|---|---|
| OPEN-1 | `uo_out` đọc theo hệ **không dấu** — cần ghi vào hợp đồng giao diện | `functional_spec.md` §5.3 |
| OPEN-2 | Tầng ngoài xử lý thế nào khi `ovf = 1` | như trên |
| OPEN-3 | Có giữ chân `ovf` riêng không, khi nó trùng `abs_val[7]` | như trên |

### Ngoài phạm vi — không được khẳng định

"Đã sign-off", "đã tape-out", "đã chế tạo", "đã kiểm tra sau chế tạo", "chạy được ở XXX MHz".
Charter mục 3 loại tất cả khỏi phạm vi đề tài.

---

*Phiên bản: v2.0 (thiết kế lại đúng đề Charter) · Ngày: 2026-09-24*
