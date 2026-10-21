# A09 · Bảng yêu cầu (Requirements)

> 🔧 **ĐỀ NÀY ĐÃ ĐƯỢC THIẾT KẾ LẠI**
>
> Gói nguồn ban đầu chứa thiết kế của **một đề khác** (thuộc danh mục đề cũ).
> RTL, mô hình chuẩn và testbench đã được **viết mới** cho đúng đề Charter
> *Bộ tính giá trị tuyệt đối và dấu của số bù 2 8-bit*, và đã xác minh bằng công cụ thật.
>
> * Mã nguồn cũ: [`08_ORIGINAL_SOURCE/`](08_ORIGINAL_SOURCE/) — giữ nguyên, quay lui được
> * Nhật ký thay đổi: [`08_ORIGINAL_SOURCE/PATCHLOG.md`](08_ORIGINAL_SOURCE/PATCHLOG.md)
> * Sự cố và cách xử lý: [`05_VERIFICATION/known_issues.md`](05_VERIFICATION/known_issues.md)



Mọi yêu cầu đều **suy trực tiếp từ Project Charter — A09**. Cột *Nguồn* chỉ rõ mục nào
của Charter sinh ra yêu cầu đó. Không có yêu cầu nào do người soạn tự thêm.

Mức: **M** = bắt buộc · **S** = nên có · **O** = tuỳ chọn.

---

## 1. Yêu cầu chức năng và cấu trúc

| ID | Mức | Nội dung yêu cầu | Nguồn |
|---|---|---|---|
| REQ-A09-001 | M | Khối thực hiện đúng chức năng mô tả trong Charter mục 1: *Bộ tính giá trị tuyệt đối và dấu của số bù 2 8-bit*. | mục 1 |
| REQ-A09-002 | M | Giao diện đúng ánh xạ chân Charter mục 4 (xem `02_SPECIFICATION/interface.md`). | mục 4 |
| REQ-A09-003 | M | Loại mạch phải đúng phân loại Charter: **Tổ hợp** — nghĩa là **0 ô nhớ**. | mục 10 |
| REQ-A09-004 | M | Quy mô nằm trong khoảng hợp lý cho ô 1×1 tile (Charter ước lượng ~110–160 cell · 1×1 tile). | metadata |

## 2. Yêu cầu kiểm chứng

| ID | Mức | Nội dung yêu cầu | Nguồn |
|---|---|---|---|
| REQ-A09-010 | M | Chạy đủ các ca kiểm thử bắt buộc của Charter mục 8 (xem §4). | mục 8 |
| REQ-A09-011 | M | Bổ sung **ít nhất hai ca tự xây dựng**, trong đó có **ca biên**. | mục 8 |
| REQ-A09-012 | M | Mỗi khẳng định phải đi kèm **bằng chứng** và **điều kiện tạo ra bằng chứng**. | mục 6 |
| REQ-A09-013 | S | Thu một **artifact số có chú thích** và nêu điều kiện tạo ra nó. | mục 3, 5 |

## 3. Yêu cầu phân tích riêng (đặc thù của A09)

> Charter mục 9 — bắt buộc trả lời bằng số liệu của chính mình:
>
> Giải thích trong báo cáo vì sao trường hợp −128 là ngoại lệ toán học chứ không phải lỗi thiết kế, và chỉ ra phần logic nào trong báo cáo tổng hợp phục vụ riêng cho việc phát hiện nó.
> Bắt buộc trả lời bằng số liệu của chính mình. Mỗi đề một câu khác nhau.

| ID | Mức | Nội dung |
|---|---|---|
| REQ-A09-020 | M | Trả lời câu phân tích riêng ở trên bằng dữ liệu do chính mình sinh ra. |
| REQ-A09-021 | M | Trả lời các câu hỏi kỹ thuật Charter mục 2 (xem §5) bằng bằng chứng. |

## 4. Ca kiểm thử bắt buộc (Charter mục 8)

- 0 · +127 · −1 · −128 (cờ tràn) · −64
- Bổ sung ít nhất hai ca tự xây dựng, trong đó có ca biên.

Danh sách thực thi và kết quả: `05_VERIFICATION/test_matrix.csv`.

## 5. Câu hỏi kỹ thuật của Charter (mục 2)

1. **Vì sao −128 là trường hợp đặc biệt, và phần cứng phát hiện nó bằng cách nào?**
2. **Lấy giá trị tuyệt đối trong phần cứng là làm gì — và nó tốn bao nhiêu cell?**
3. **Cờ tràn ở đây khác cờ tràn của phép cộng ở chỗ nào?**

> Sinh viên được phép thay bằng câu hỏi của mình, miễn là cụ thể và trả lời được bằng bằng
> chứng — không viết "tìm hiểu về…". *(Charter mục 2)*

Câu trả lời kèm bằng chứng: `05_VERIFICATION/verification_report.md` và `06_GDSII/physical_report.md`.

## 6. Yêu cầu bàn giao (Charter mục 5)

- Hồ sơ phân tích đủ tám thành phần, có số phiên bản và ngày sửa.
- Bảng giao diện: tên tín hiệu, chiều, độ rộng, mức tích cực, giả định.
- Một artifact số có chú thích và nêu điều kiện tạo ra nó.
- Kết luận nêu rõ đã chứng minh được gì và chưa chứng minh được gì.

## 7. Mốc thực hiện (Charter mục 7)

- M1 · T7. Chốt đề và viết charter: ứng dụng, mục tiêu, 2–3 câu hỏi kỹ thuật.
- M2 · T8–9. Bảng hành vi suy từ đặc tả; đọc RTL và waveform; lập danh sách ca kiểm thử.
- M3 · T11–12. Sơ đồ khối hỗ trợ; thu artifact số, chú thích và đối chiếu bảng hành vi.
- M4 · T13–14. Hoàn thiện bảng giao diện, RTM-lite, sơ đồ vòng đời; rà từng khẳng định.
- M5 · T15. Nộp hồ sơ và trình bày; trả lời câu phân tích riêng bằng số của chính mình.

## 8. Rủi ro chính (Charter mục 10)

> Chỗ hay tắc: Bỏ qua ca −128 vì 'hiếm gặp'. Đó đúng là ca đề ra để kiểm.
> Dấu hiệu làm đúng: 0 ô nhớ. Cấu trúc = bộ đảo bit có điều kiện + bộ cộng +1 + logic phát hiện 0x80.

---

*Phiên bản: v1.0 · Ngày: 2026-09-24 · Nguồn chuẩn: `Project_Charter_80_De.docx`, mục A09.*
