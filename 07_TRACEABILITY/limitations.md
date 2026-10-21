A09 — Giới hạn và phạm vi bằng chứng

1. Kiểm chứng chức năng

Mô hình chuẩn Python: báo cáo dự án ghi nhận PASS.

Mô phỏng RTL: báo cáo ghi nhận 266 vector, 0 sai lệch, 1.597 lần kiểm bất biến và 0 vi phạm.

Các kết quả trên là bằng chứng kiểm chứng chức năng; không tự chứng minh timing hoặc hoạt động sau place & route.

2. Tổng hợp logic (Synthesis)

Kết quả tổng hợp bằng Yosys với thư viện cell Sky130 HD:

Tổng số cell: 18.

Flip-flop/latch: 0.

Diện tích cell tổng hợp: 118,864 µm².

Phiên bản công cụ được kiểm tra: Yosys 0.52.

Diện tích trên là diện tích cell sau tổng hợp, không phải diện tích layout sau place & route.

3. Phân tích timing (STA)

STA được thực hiện trên netlist sau tổng hợp bằng OpenSTA 2.0.17, với ràng buộc trong 04_IMPLEMENTATION/constraints/design.sdc.

Đường max được báo cáo: x[0] → abs_val[6].

Data arrival time của đường này: 0,99 ns.

Slack của đường này: +9,01 ns.

Đường min được báo cáo: x[7] → sign, là kết nối trực tiếp với thời gian báo cáo 0 ns.

WNS/TNS báo cáo: 0,00 theo ràng buộc hiện tại.

Lưu ý: SDC dùng virtual clock 10 ns và input/output delay bằng 0. Đây là điều kiện tham chiếu cho phân tích hiện tại, không chứng minh thiết kế hoạt động ở 100 MHz. Các giá trị WNS/TNS cũng không nên được diễn giải độc lập thành bằng chứng sign-off timing.

4. Ước lượng công suất

Báo cáo OpenSTA hiện có:

Switching power: 8.65e-07 W (xấp xỉ 0,865 µW).

Leakage power: 3.17e-11 W (xấp xỉ 0,0317 nW).

Đây là ước lượng theo mô hình và điều kiện đầu vào hiện có. Chưa có bằng chứng cho thấy báo cáo sử dụng hoạt động chuyển mạch thực tế từ VCD/SAIF hoặc ký sinh sau routing; vì vậy không xem đây là kết quả công suất sign-off.

5. Các hạng mục chưa có bằng chứng

Tại thời điểm lập tài liệu này, chưa xác nhận có kết quả cho:

Place & route hoàn chỉnh.

GDSII cuối cùng sau routing.

Timing sau layout với ký sinh đã trích xuất.

Kiểm tra DRC và LVS.

Mô phỏng gate-level hoặc post-layout dùng SDF.

Không kết luận các hạng mục trên đã PASS khi chưa có log và kết quả tương ứng.

6. Cảnh báo công cụ

Trong lúc chạy OpenSTA, công cụ đưa ra cảnh báo liên quan đến default_operating_condition trong file Liberty. Cảnh báo này cần được xem xét trước khi sử dụng số liệu cho kết luận sign-off. Không sửa trực tiếp thư viện PDK dùng chung chỉ để loại bỏ cảnh báo.

7. Nguyên tắc báo cáo

Mọi số liệu phải đi kèm công cụ, đầu vào và điều kiện chạy. Phân biệt rõ kết quả mô phỏng chức năng, tổng hợp logic, STA trước layout và kết quả physical design sau routing.
