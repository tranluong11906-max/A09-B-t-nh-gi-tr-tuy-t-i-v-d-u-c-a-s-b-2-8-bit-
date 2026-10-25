# A09 — Báo cáo kết quả thiết kế vật lý (Physical Design Report)

## 1. Phạm vi

Thiết kế: Bộ tính giá trị tuyệt đối và dấu của số bù 2 8-bit (`a09_abs_sign`).

Công cụ thiết kế vật lý: OpenLane 1, sử dụng PDK Sky130A và thư viện standard cell Sky130 HD.

Báo cáo này tổng hợp bằng chứng từ lần chạy OpenLane 1 tại:
`04_IMPLEMENTATION/openlane1/runs/a09_run1/`.

## 2. Kết quả đầu ra vật lý

| Hạng mục | Đường dẫn / kết quả |
|---|---|
| GDSII cuối cùng | `04_IMPLEMENTATION/openlane1/runs/a09_run1/results/signoff/a09_abs_sign.gds` |
| Báo cáo DRC | `04_IMPLEMENTATION/openlane1/runs/a09_run1/reports/signoff/drc.rpt` |
| Báo cáo LVS | `04_IMPLEMENTATION/openlane1/runs/a09_run1/reports/signoff/47-a09_abs_sign.lvs.rpt` |

## 3. Kiểm tra DRC

Báo cáo DRC ghi nhận `COUNT: 0`.

Kết luận: Báo cáo DRC hiện có ghi nhận 0 lỗi. Kết luận này dựa trên báo cáo của lần chạy đã lưu.

## 4. Kiểm tra LVS

Báo cáo LVS ghi nhận không có sai lệch về kết nối, linh kiện, chân hoặc thuộc tính; tổng số lỗi là 0.

Kết luận: LVS khớp theo báo cáo hiện có.

## 5. Giới hạn về timing và mô phỏng sau layout

Chưa có đủ bằng chứng trong hồ sơ đã kiểm tra để kết luận timing sign-off sau layout đã PASS.

Chưa xác nhận có kết quả mô phỏng gate-level hoặc post-layout sử dụng SDF.

Các kết quả STA trước layout được trình bày riêng và không thay thế cho timing sign-off sau layout.

## 6. Kết luận

Đã tìm thấy file GDSII cuối cùng cùng báo cáo DRC và LVS của lần chạy OpenLane 1. Báo cáo DRC ghi nhận 0 lỗi; báo cáo LVS ghi nhận 0 sai lệch.

Không kết luận timing sign-off sau layout hoặc mô phỏng post-layout đã PASS khi chưa có bằng chứng tương ứng.
