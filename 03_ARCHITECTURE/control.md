# A09 · Phần điều khiển (Control)

---

## 1. Kết luận: **A09 không có phần điều khiển**

Không có cổng `clk`, `rst`, `en`, `start`, `valid`, `ready`, `op`, `mode`. Module chỉ có
**một** cổng vào (`x[7:0]`) và ba cổng ra. Không có tín hiệu nào do tầng ngoài đặt để thay
đổi *cách* khối tính.

Bằng chứng đọc thẳng từ khai báo module:

```systemverilog
module a09_abs_sign (
    input  logic [7:0] x,
    output logic [7:0] abs_val,
    output logic       sign,
    output logic       ovf
);
```

## 2. Nhưng `sign` lái mux — đó có phải điều khiển không?

Đây là câu hỏi bảo vệ gần như chắc chắn sẽ bị hỏi, và câu trả lời là **không**.

| Tiêu chí của một tín hiệu điều khiển | `sign` có thoả không? |
|---|---|
| Đến từ **ngoài** khối (tầng trên đặt) | ❌ Không — `sign = x[7]`, sinh ra từ chính dữ liệu |
| Có thể đổi **độc lập** với dữ liệu | ❌ Không — đổi `sign` nghĩa là đổi `x`, tức đổi bài toán |
| Chọn giữa các **chế độ hoạt động** khác nhau | ❌ Không — chỉ có một phép toán duy nhất: lấy trị tuyệt đối |
| Có trạng thái / lịch sử | ❌ Không |

Cách phát biểu đúng: **`sign` là một thuộc tính của dữ liệu, được dùng như tín hiệu chọn
trong một datapath**. Đây là dạng *data-dependent selection*, giống hệt việc bit cao nhất
của một số quyết định nhánh nào của mux dẫn — không giống việc một bộ điều khiển phát lệnh.

Bằng chứng mạnh nhất cho phát biểu này đến từ netlist: sau tổng hợp **không còn cell mux
nào**. Tầng chọn đã tan vào phép XOR (`block_diagram.md` §5). Một tín hiệu điều khiển thật
sự thì không thể "tan" như vậy — nó phải tồn tại như một đường chọn riêng.

## 3. Vì sao mạch tổ hợp không cần điều khiển

Điều khiển tồn tại để trả lời câu hỏi *"bây giờ làm bước nào?"*. Câu hỏi đó chỉ có nghĩa khi
phép tính được **chia thành nhiều bước theo thời gian**. A09 tính xong toàn bộ trong **một**
lần lan truyền tín hiệu:

```
x đổi  ──▶  (0,96 ns lan truyền)  ──▶  abs_val, sign, ovf ổn định
```

Không có bước nào để chọn, nên không có gì để điều khiển.

## 4. Điều khiển nằm ở đâu trong hệ thống

| Nhiệm vụ điều khiển | Ai làm | Ghi chú |
|---|---|---|
| Quyết định khi nào lấy mẫu `x` | Thanh ghi trước A09 | Ngoài phạm vi khối |
| Quyết định khi nào đọc `abs_val` | Thanh ghi / bộ so ngưỡng sau A09 | Phải đợi đủ 0,96 ns |
| Quyết định **làm gì khi `ovf = 1`** | Bộ điều khiển bù (có FSM) | 🟡 OPEN-2, xem `functional_spec.md` §5.3 |
| Chọn chiều hiệu chỉnh theo `sign` | Logic điều khiển tầng sau | |
| Lái `uio_oe` cho lớp vỏ Tiny Tapeout | Wrapper `tt_um_*` | Không nằm trong lõi này |

### Nghĩa vụ hợp đồng của tầng ngoài

1. Giữ `x` ổn định ít nhất **0,96 ns** (số sau tổng hợp; sau P&R sẽ lớn hơn) trước khi lấy
   mẫu đầu ra.
2. Không đưa `X`/`Z` vào `x`.
3. Đọc `abs_val` theo hệ **không dấu** — 🟡 OPEN-1.
4. Chấp nhận rằng trong khoảng lan truyền, `abs_val` có thể **glitch** — xem
   `timing_diagram.md` §4.

## 5. Nếu sau này phải thêm điều khiển

Chỉ có một tình huống hợp lý: khi khối được nhúng vào lớp vỏ Tiny Tapeout `tt_um_*`, lớp vỏ
đó **bắt buộc** có `clk`, `rst_n`, `ena` theo chuẩn khung. Khi đó:

* Lõi `a09_abs_sign` **giữ nguyên 0 ô nhớ**;
* Các cổng `clk`/`rst_n`/`ena` chỉ đi vào phần vỏ (nếu vỏ có thanh ghi chốt đầu ra), **không**
  đi vào lõi;
* Báo cáo tổng hợp phải tách hai con số: lõi (0 FF) và vỏ.

Cách làm này giữ đúng phân loại **Tổ hợp** của Charter cho khối được phân tích, đồng thời
vẫn lắp được vào khung vật lý.

---

*Phiên bản: v2.0 (thiết kế lại đúng đề Charter) · Ngày: 2026-09-24.*
