# A09 · Sự cố đã biết và cách xử lý (Known Issues)

---

## 1. Sự cố chính — gói mã nguồn thuộc một danh mục đề khác

| Hạng mục | Nội dung |
|---|---|
| **Mức nghiêm trọng** | 🔴 Nghiêm trọng — toàn bộ chức năng của khối |
| **Trạng thái** | ✅ Đã xử lý: thiết kế lại đúng đề, giảng viên đã duyệt |
| **Ảnh hưởng** | REQ-A09-001, AC-6, AC-7, AC-9 |
| **Phát hiện ngày** | 2026-09-24 |

### Nội dung

Gói zip nhận ban đầu tên `A09_Counter_Implementation_Validation` chứa RTL `a09_counter` —
một **bộ đếm 4-bit tuần tự** — trong khi Charter A09 yêu cầu **Bộ tính giá trị tuyệt đối và
dấu của số bù 2 8-bit**, phân loại **Tổ hợp**.

```systemverilog
// 08_ORIGINAL_SOURCE/rtl/a09_counter.sv — nguyên văn bản gốc
module a09_counter (
    input  logic       clk,
    input  logic       rst,
    input  logic       en,
    output logic [3:0] q
);
    always_ff @(posedge clk) begin
        if (rst)      q <= 4'h0;
        else if (en)  q <= q + 4'h1;
    end
endmodule
```

Đây **không** phải lỗi lập trình trong mã nguồn: mã đó tự nó đúng, mô phỏng PASS, tổng hợp
PASS. Vấn đề là nó **giải một đề khác**. Tên gói (`..._Counter_...`) cho thấy gói được đánh
số theo **một danh mục đề cũ**, trong đó vị trí A09 là "bộ đếm".

## 2. Phát hiện thế nào — ba manh mối độc lập

| # | Manh mối | Nguồn |
|---|---|---|
| 1 | **Tên gói** chứa chữ `Counter`, không liên quan đến trị tuyệt đối | tên file zip |
| 2 | **Giao diện lệch hoàn toàn** so với Charter mục 4 | Charter: `ui_in[7:0]=x`, `uo_out[7:0]=\|x\|`, `uio_out[0]=dấu`, `uio_out[1]=cờ tràn`. RTL: `clk`, `rst`, `en`, `q[3:0]` — **không có cổng nào khớp** |
| 3 | **Loại mạch lệch** | Charter phân loại **Tổ hợp**, mục 10 ghi *"dấu hiệu làm đúng: 0 ô nhớ"*. Tổng hợp bản gốc cho **4 flip-flop `dfxtp_1`**, công suất nhóm Sequential **93,8 %** |

Manh mối 3 là mạnh nhất vì nó là **số đo của công cụ**, không phải suy đoán từ tên gọi.
Một khối được Charter chốt là Tổ hợp mà tổng hợp ra 4 flip-flop thì không thể là khối đúng.

### Số đo của bản gốc (để đối chiếu, không dùng cho thiết kế mới)

| Mục | Bản gốc `a09_counter` |
|---|---|
| Mô phỏng | PASS |
| Tổng hợp | PASS |
| Số cell | 14 |
| **Flip-flop** | **4** 🔴 |
| Diện tích | 138,8832 µm² |
| Phân bố cell | `dfxtp_1`×4, `nor2_1`×3, `nor3_1`×2, `xnor2_1`×2, `a21oi_1`×1, `and3_1`×1, `and4_1`×1 |
| Công suất | 1,87e-05 W — tổ hợp 6,2 %, **tuần tự 93,8 %** |

## 3. Đã xử lý ra sao

1. **Đóng băng bản gốc.** Toàn bộ `rtl/`, `golden_model/`, `testbench/` của bản gốc được
   chép nguyên trạng vào `08_ORIGINAL_SOURCE/` và **không được sửa**.
2. **Xin duyệt.** Giảng viên đã duyệt phương án: viết RTL mới đúng đề Charter, vì mã trong
   gói thuộc danh mục đề cũ.
3. **Viết lại từ đầu** ba thành phần: RTL (`a09_abs_sign.sv`), mô hình chuẩn
   (`a09_reference.sv` + `reference_model.py`), testbench (`a09_tb.sv`).
4. **Viết lại tài liệu** `02_SPECIFICATION/` và `03_ARCHITECTURE/` theo thiết kế mới.
5. **Chạy lại toàn bộ chuỗi xác minh** và ghi số liệu mới:

| Mục | Bản gốc (đề sai) | **Bản thiết kế lại (đúng đề)** |
|---|---|---|
| Module top | `a09_counter` | **`a09_abs_sign`** |
| Loại mạch | Tuần tự | **Tổ hợp** ✅ |
| Mô hình chuẩn Python | PASS | **PASS** |
| Mô phỏng | PASS | **PASS — 266 vector, 0 lỗi, 256/256 vét cạn** |
| Tổng hợp | PASS | **PASS** |
| Số cell | 14 | **18** |
| **Flip-flop** | **4** 🔴 | **0** ✅ |
| Diện tích | 138,8832 µm² | **118,864 µm²** |
| Công suất tuần tự | 93,8 % | **0 %** ✅ |

Nhật ký thay thế từng file: `08_ORIGINAL_SOURCE/PATCHLOG.md`.

## 4. Sự cố phụ — đã ghi nhận trong bản gốc

### 4.1 `ref` là từ khoá SystemVerilog

Testbench gốc đặt tên instance của mô hình chuẩn là `ref`:

```systemverilog
a09_reference ref(.clk(clk), .rst(rst), .en(en), .q(qr));   // Icarus từ chối
```

`ref` là **từ khoá SystemVerilog** (kiểu truyền đối số tham chiếu), nên Icarus Verilog báo
lỗi cú pháp. Đã đổi thành `ref_i` khi chạy bản gốc để lấy số liệu đối chiếu ở §2. Đây là
sửa **tối thiểu** để chạy được, không đổi hành vi.

Testbench mới **không** mắc lại lỗi này: instance mô hình chuẩn đặt tên `ref_m`.

### 4.2 Golden model gốc **sao chép** RTL gốc

`08_ORIGINAL_SOURCE/golden_model/a09_reference.sv` có nội dung gần như **giống hệt**
`a09_counter.sv` (chỉ khác `4'h1` / `4'd1`). Một mô hình chuẩn sao chép thiết kế thì **không
kiểm được gì**: nếu thiết kế sai, mô hình chuẩn sai theo cùng một kiểu.

Bản viết lại tránh hẳn bẫy này bằng cách làm cho mô hình chuẩn **khác cách nghĩ** với RTL:

| | RTL `a09_abs_sign` | Golden `a09_reference` |
|---|---|---|
| Cách tính `abs` | đảo bit + cộng 1 + mux (mức bit) | `$signed`, phép `-` trong miền số nguyên 32 bit |
| Cách sinh `ovf` | dò **mẫu bit** `x == 0x80` | dò **điều kiện dải** `mag > 127` |
| Ngôn ngữ thứ ba | — | `reference_model.py` — Python thuần, số nguyên không giới hạn |

Việc `ovf` được sinh từ **mẫu bit** ở một bên và từ **điều kiện dải** ở bên kia, rồi khớp
nhau 256/256, chính là bằng chứng hai cách diễn đạt tương đương.

## 5. Rủi ro còn lại

| # | Rủi ro | Mức | Giảm thiểu |
|---|---|---|---|
| 1 | Các đề khác trong cùng bộ nộp có thể cũng thuộc danh mục cũ | 🟡 | Kiểm chéo tên gói ↔ Charter mục 1 và loại mạch ↔ số flip-flop cho từng đề |
| 2 | Hợp đồng đọc `uo_out` (không dấu) chưa được chốt chính thức | 🟡 | 🟡 OPEN-1, `02_SPECIFICATION/functional_spec.md` §5.3 |
| 3 | Số liệu trong `06_GDSII/` phải được sinh lại cho thiết kế mới | 🟢 | Chạy lại `04_IMPLEMENTATION/scripts/02_run_synth.sh` và `03_run_sta.tcl` với top `a09_abs_sign` |
| 4 | Chưa mô phỏng gate-level, chưa P&R/DRC/LVS/GDS | 🟢 | Ghi rõ ở `07_TRACEABILITY/limitations.md`; không khẳng định vượt mức |

---

*Phiên bản: v1.0 · Ngày: 2026-09-24 · Truy vết: REQ-A09-001, AC-6, AC-7, AC-9.*
