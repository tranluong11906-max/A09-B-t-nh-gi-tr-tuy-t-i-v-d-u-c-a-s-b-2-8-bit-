# A09 · Máy trạng thái (FSM)

---

## 1. Kết luận: **A09 KHÔNG có FSM** — và đây là câu trả lời đúng

Charter phân loại A09 là mạch **Tổ hợp** và ghi ở mục 10: *"Dấu hiệu làm đúng: 0 ô nhớ."*
Một FSM cần ít nhất một thanh ghi trạng thái. Có FSM ⟹ có ô nhớ ⟹ **sai phân loại**.

Vì vậy mục này không phải chỗ để "cố vẽ ra một FSM cho đủ mục". Nó là chỗ để **chứng minh
không có**, và giải thích vì sao đó là kết quả mong muốn.

## 2. Bốn bằng chứng A09 không có trạng thái

| # | Bằng chứng | Nguồn | Kết quả |
|---|---|---|---|
| 1 | RTL không có `always_ff`, không có `clk`/`rst` | `04_IMPLEMENTATION/rtl/a09_abs_sign.sv` | chỉ `assign` và `generate` |
| 2 | Netlist không có cell tuần tự | `06_GDSII/synthesis/synth_stat.txt` | **0 flip-flop / 18 cell** |
| 3 | Công suất nhóm Sequential và Clock | `06_GDSII/sta/` `report_power` | **0 %** và **0 %** |
| 4 | Đầu ra không phụ thuộc lịch sử đầu vào | `05_VERIFICATION/simulation.log` TC-011 | cùng `x = 0x80` sau hai lịch sử khác nhau ⟹ đầu ra trùng khít |

Bằng chứng 1 là **ý định**, 2 và 3 là **kết quả công cụ**, 4 là **hành vi quan sát được**.
Ba loại bằng chứng khác nguồn cùng chỉ một kết luận.

> Phân biệt quan trọng: bằng chứng 4 mạnh hơn người ta tưởng, vì nó bắt được cả trường hợp
> "latch bị suy ra ngoài ý muốn" — lỗi kinh điển khi viết `always_comb` thiếu nhánh gán.
> RTL của A09 tránh hẳn rủi ro đó bằng cách **không dùng `always_comb`**: toàn bộ khối viết
> bằng `assign` liên tục, nên về nguyên tắc không thể sinh latch.

## 3. So sánh: khi nào một đề mới có FSM

| Dấu hiệu | A09 | Một đề có FSM |
|---|---|---|
| Cổng `clk` | không | bắt buộc |
| Cổng `rst` | không | bắt buộc |
| Thanh ghi trạng thái | không | có |
| Đầu ra phụ thuộc lịch sử | không | có |
| Khái niệm "chu kỳ tiếp theo" | vô nghĩa | trung tâm |
| Cell `__dfxtp` trong netlist | 0 | ≥ 1 |

Đáng nói: **mã nguồn ban đầu của gói này (`a09_counter`) ĐÚNG là một mạch có trạng thái** —
bộ đếm 4-bit, 4 flip-flop `dfxtp_1`, công suất tuần tự 93,8 %. Chính sự lệch pha giữa
"Charter nói Tổ hợp" và "netlist có 4 flip-flop" là **manh mối đầu tiên** phát hiện gói
nguồn thuộc danh mục đề khác. Xem `05_VERIFICATION/known_issues.md` §2.

## 4. Nếu buộc phải mô tả A09 bằng ngôn ngữ FSM

Có thể viết A09 dưới dạng một máy **không trạng thái** (0-state machine) — tức một hàm
chuyển trạng thái tầm thường:

```
        ┌───────────────────────────────┐
        │  S0  (trạng thái duy nhất)    │
        │  ────────────────────────     │
        │  luôn ở đây, không có cạnh    │
        │  chuyển nào                   │
        └───────────────────────────────┘
        Đầu ra kiểu Mealy thuần:
            abs_val = f(x)
            sign    = g(x)
            ovf     = h(x)
```

Mô tả này **đúng về hình thức nhưng vô dụng về thông tin**: một FSM một trạng thái, đầu ra
Mealy thuần, chính là định nghĩa của mạch tổ hợp. Nói "A09 là FSM một trạng thái" không sai,
nhưng cũng không thêm hiểu biết nào — và dễ làm người đọc tưởng khối có ô nhớ.

**Cách diễn đạt nên dùng khi bảo vệ:** *"A09 không có FSM vì nó không có trạng thái; toàn bộ
trạng thái của hệ thống nằm ở bộ điều khiển bù phía sau."*

## 5. Trường hợp FSM sẽ xuất hiện

| Tình huống | FSM xuất hiện ở đâu |
|---|---|
| Xử lý chuỗi mẫu sai số liên tiếp, tính trung bình động | Ở khối tích luỹ phía sau, không ở A09 |
| Vòng điều khiển bù có nhiều pha (dò → bù → giữ) | Ở bộ điều khiển bù |
| Nạp `x` nhiều nhịp vì thiếu chân | **Không áp dụng** — A09 chỉ dùng 18/24 chân |
| Lớp vỏ Tiny Tapeout cần chốt đầu ra | Ở wrapper, lõi vẫn 0 FF — xem `control.md` §5 |

## 6. Câu hỏi bảo vệ liên quan

| Câu hỏi | Đáp án |
|---|---|
| Mục FSM trống, có phải làm thiếu không? | Không. Trống là **kết quả đúng** cho mạch Tổ hợp, và có 4 bằng chứng ở §2. |
| `sign` chọn nhánh mux — đó có phải trạng thái không? | Không. `sign` tính từ `x` ngay trong cùng lần lan truyền, không lưu lại gì. Xem `control.md` §2. |
| Làm sao chắc không có latch ẩn? | RTL không dùng `always_comb`/`always @*` nào; toàn bộ là `assign` liên tục. Netlist cũng không có cell `__dl*`. |
| Bộ đếm trong `08_ORIGINAL_SOURCE/` thì sao? | Đó là mã của **đề khác**, đã đóng băng làm bằng chứng truy vết, không thuộc thiết kế hiện tại. |

---

*Phiên bản: v2.0 (thiết kế lại đúng đề Charter) · Ngày: 2026-09-24.*
