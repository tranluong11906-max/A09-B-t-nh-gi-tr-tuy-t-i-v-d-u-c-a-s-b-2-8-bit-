# A09 · Báo cáo kiểm chứng (Verification Report)

> 🔧 **ĐỀ NÀY ĐÃ ĐƯỢC THIẾT KẾ LẠI**
>
> Gói nguồn ban đầu chứa thiết kế của **một đề khác** (thuộc danh mục đề cũ).
> RTL, mô hình chuẩn và testbench đã được **viết mới** cho đúng đề Charter
> *Bộ tính giá trị tuyệt đối và dấu của số bù 2 8-bit*, và đã xác minh bằng công cụ thật.
>
> * Mã nguồn cũ: [`08_ORIGINAL_SOURCE/`](08_ORIGINAL_SOURCE/) — giữ nguyên, quay lui được
> * Nhật ký thay đổi: [`08_ORIGINAL_SOURCE/PATCHLOG.md`](08_ORIGINAL_SOURCE/PATCHLOG.md)
> * Sự cố và cách xử lý: [`05_VERIFICATION/known_issues.md`](05_VERIFICATION/known_issues.md)



**Ngày chạy:** 2026-09-24 · **Phiên bản:** v1.0

---

## 1. Điều kiện tạo ra bằng chứng

> Charter mục 6: *"Mỗi khẳng định đi kèm bằng chứng **và điều kiện tạo ra bằng chứng đó**."*

| Hạng mục | Giá trị |
|---|---|
| Hệ điều hành | Ubuntu 22.04 LTS (x86-64) |
| Công cụ mô phỏng | **Icarus Verilog 12.0 (stable)** (cờ `-g2012`) |
| Top module | `a09_abs_sign` |
| RTL | `04_IMPLEMENTATION/rtl/` |
| Mô hình chuẩn | `05_VERIFICATION/golden_model/` |
| Testbench | `05_VERIFICATION/testbench/` |
| Lệnh chạy | `bash 04_IMPLEMENTATION/scripts/01_run_sim.sh` |
| Nguồn gốc gói | `A09_Counter_Implementation_Validation` |

## 2. Kết quả tổng hợp

| Lớp | Nội dung | Kết quả |
|---|---|---|
| L0 | Mô hình chuẩn Python | ✅ **PASS** |
| L2 | Mô phỏng RTL | ✅ PASS — testbench chạy hết, không có assertion nào vi phạm |
| L3 | Kiểm cấu trúc — số flip-flop | ✅ đo được **0** FF, phân loại Charter là **Tổ hợp** |
| L4 | Mô phỏng gate-level | ⬜ chưa chạy |
| L5 | Mô phỏng post-layout (SDF) | ⬜ chưa chạy |

## 3. Trích log mô phỏng

```
  Vi pham bat bien         : 0
  Gia tri lam ovf = 1      : 1 (x = 0x80 = -128)
  Flip-flop trong RTL      : 0 (khong co always_ff, khong co clk/rst)

  KET QUA A09: PASS - 266 vector, 0 sai lech, 1597 lan kiem bat bien, 0 vi pham
05_VERIFICATION/testbench/a09_tb.sv:428: $finish called at 398000 (1ps)
```

Log đầy đủ: [`simulation.log`](simulation.log)

## 4. Kiểm cấu trúc — số flip-flop

Trích `../06_GDSII/synthesis/synth_stat.txt` (Yosys 0.33 (git sha1 2584903a060) + `sky130_fd_sc_hd`):

| Chỉ số | Giá trị |
|---|---:|
| Tổng số cell | **18** |
| Cell tuần tự (flip-flop / latch) | **0** |
| Diện tích | 118,864 µm² |

✅ Đúng phân loại **Tổ hợp** của Charter — 0 ô nhớ (dấu hiệu làm đúng, Charter mục 10).



## 5. Trả lời câu hỏi kỹ thuật của Charter (mục 2)

> 1. Vì sao −128 là trường hợp đặc biệt, và phần cứng phát hiện nó bằng cách nào?
> 2. Lấy giá trị tuyệt đối trong phần cứng là làm gì — và nó tốn bao nhiêu cell?
> 3. Cờ tràn ở đây khác cờ tràn của phép cộng ở chỗ nào?
> Sinh viên được phép thay bằng câu hỏi của mình, miễn là cụ thể và trả lời được bằng bằng chứng — không viết “tìm hiểu về…”.

Phần trả lời dựa trên số liệu đo được nằm ở:

- Câu về **giao diện / tín hiệu**: `02_SPECIFICATION/interface.md`
- Câu về **thời gian / tần số**: `06_GDSII/sta/` và `06_GDSII/physical_report.md`
- Câu về **diện tích / tài nguyên**: `06_GDSII/physical_report.md` §2
- Phân tích bản chất và cơ chế: `implementation-notes_A09.md`

## 6. Những gì báo cáo này **chưa** chứng minh

| Chưa chứng minh | Vì sao |
|---|---|
| Kiến trúc bên trong đúng như mô tả | Kiểm chứng chức năng mù về cấu trúc — phải đọc RTL và netlist |
| Độ trễ lan truyền đạt yêu cầu | Mô phỏng hành vi là zero-delay |
| Mạch đúng sau place & route | Chưa chạy P&R |
| Không có glitch gây hại | Mô phỏng zero-delay không sinh glitch |

Danh sách đầy đủ: `07_TRACEABILITY/limitations.md`.

---

*Truy vết: REQ-A09-001, REQ-A09-003, REQ-A09-010…013.*
