# A09 · Giản đồ thời gian (Timing Diagram)

> **Đọc trước:** A09 **không có clock**. Mọi mốc thời gian dưới đây là **độ trễ lan truyền**
> tổ hợp, đo bằng OpenSTA trên netlist sau tổng hợp với một **clock ảo** `vclk` chu kỳ 10 ns
> chỉ đóng vai trò mốc quy chiếu để tính slack. Con số 10 ns **không** là yêu cầu hệ thống,
> và **không** được diễn giải thành "khối chạy ở 100 MHz".

---

## 1. Ca xấu nhất — đường tới hạn `x[0] → abs_val[6]`, 0,96 ns

Đây là đường OpenSTA báo là tới hạn. Cần một đầu vào làm đổi `x[0]` và lan hết đường.
Ví dụ cụ thể: `x` chuyển từ `0x40` (+64) sang `0xC1` (−63).

```
 t (ns)   0.00      0.58            0.83        0.96
          │          │               │           │
 x[0]  ───┤‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾  (đổi tại t=0)
          │          │               │           │
 _01_  ───┼──────────┤▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔   or4_1  (+0,58 ns)
 (OR x[0..3])        │               │           │
          │          │               │           │
 _08_  ───┼──────────┼───────────────┤▔▔▔▔▔▔▔▔▔▔▔▔▔▔    o31ai_1 (+0,26 ns)
          │          │               │           │
 abs_val[6] ─────────┼───────────────┼───────────┤▔▔▔   xnor2_1 (+0,12 ns)
          │          │               │           │
          └──────────┴───────────────┴───────────┘
                 TỔNG: 0,96 ns · 3 cell
```

Chi tiết từng chặng (trích `06_GDSII/sta/timing_report_max.txt`):

| Chặng | Cell | Fanout | Trễ chặng | Mốc |
|---|---|---:|---:|---:|
| `x[0]` (in) | — | 5 | 0,00 | 0,00 |
| `_10_/X` | `sky130_fd_sc_hd__or4_1` | 5 | **0,58** | 0,58 |
| `_23_/Y` | `sky130_fd_sc_hd__o31ai_1` | 1 | 0,26 | 0,83 |
| `_24_/Y` | `sky130_fd_sc_hd__xnor2_1` | 1 | 0,12 | **0,96** |

> 🔎 **Chặng đầu chiếm 60 % tổng độ trễ.** `or4_1` mất 0,58 ns không phải vì nó là cổng
> chậm, mà vì nó **fanout 5** — tín hiệu `_01_` (OR của `x[0..3]`) được dùng lại cho bốn bit
> cao và cho cả `ovf`. Đây chính là cây prefix-OR mà công cụ tự dựng (`datapath.md` §4):
> nó đổi độ sâu lấy tải. Bài học: sau tổng hợp, **fanout** thường quan trọng hơn **số tầng**.

## 2. Ca tốt nhất — `x[7] → sign`, 0,00 ns

```
 t (ns)   0.00
          │
 x[7]  ───┤‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾
          │
 sign  ───┤‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾     cùng một net, 0 cell, 0,00 ns
```

Trong netlist: `assign sign = x[7];`. Trả lời được ngay một câu hỏi hay bị hỏi: *"tách bit
dấu ra tốn bao nhiêu?"* — **không tốn gì**.

Đường **ngắn nhất** (`-path_delay min`) của phần có cổng logic: `x[4] → abs_val[7]`, qua
đúng một `nor4_1`, **0,01 ns**. Lưu ý đây là đường *nhanh nhất tới* `abs_val[7]`, không phải
thời điểm bit đó ổn định — xem bảng đầy đủ ở §4.

## 3. So sánh hai ca

| | Đường tới hạn | Đường nhanh nhất |
|---|---|---|
| Từ → đến | `x[0] → abs_val[6]` | `x[7] → sign` |
| Số cell | 3 | **0** |
| Độ trễ | **0,96 ns** | **0,00 ns** |
| Slack (so `vclk` 10 ns) | 9,04 ns (MET) | 10,00 ns (MET) |

WNS = 0,00 · TNS = 0,00 — không có đường nào vi phạm mốc quy chiếu.

**Đối chiếu với A01 (cùng thư viện, cùng script, cùng góc PVT):** A01 là bộ cộng
ripple-carry 8 bit, đường tới hạn **1,34 ns qua 8 cell**. A09 mô tả cũng "8 tầng ripple"
trong RTL nhưng chỉ còn **3 cell / 0,96 ns**. Khác biệt không nằm ở kỹ năng viết mã mà ở
**bản chất hàm carry**: carry của bộ cộng là hàm đa số không khai triển được, carry của bộ
tăng là phép thu gọn AND trên đầu vào nên cây hoá được. Xem `datapath.md` §4.

## 4. Vùng glitch — vì sao `abs_val` có thể sai tạm thời

Trong khoảng `0 < t < 0,96 ns`, các bit của `abs_val` ổn định **không đồng thời**. Bảng dưới
là thời điểm ổn định xấu nhất của **từng** chân ra, đo bằng `report_checks -to <port>`
(arrival = 10,00 − slack):

| Chân ra | Startpoint xấu nhất | Slack (ns) | **Ổn định tại (ns)** |
|---|---|---:|---:|
| `sign` | `x[7]` | 10,00 | **0,00** |
| `abs_val[0]` | `x[0]` | 9,95 | 0,05 |
| `abs_val[2]` | `x[0]` | 9,65 | 0,35 |
| `abs_val[1]` | `x[0]` | 9,63 | 0,37 |
| `abs_val[3]` | `x[0]` | 9,62 | 0,38 |
| `abs_val[7]` | `x[0]` | 9,26 | 0,74 |
| `ovf` | `x[0]` | 9,26 | **0,74** |
| `abs_val[4]` | `x[0]` | 9,22 | 0,78 |
| `abs_val[5]` | `x[0]` | 9,10 | 0,90 |
| `abs_val[6]` | `x[0]` | 9,04 | **0,96** ← cuối cùng |

```
 t (ns)   0.00   0.05      0.38   0.74   0.78  0.90  0.96
          │       │          │      │      │     │     │
 x đổi ───┤       │          │      │      │     │     │
 sign  ───┤▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔  0,00
 abs[0]───────────┤▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔  0,05
 abs[1:3]─────────────────────┤▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔  0,35–0,38
 abs[7],ovf ─────────────────────────┤▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔  0,74  (cùng thời điểm!)
 abs[4]──────────────────────────────────┤▔▔▔▔▔▔▔▔▔▔▔▔▔  0,78
 abs[5]────────────────────────────────────────┤▔▔▔▔▔▔▔  0,90
 abs[6]──────────────────────────────────────────────┤▔  0,96
          │                                            │
          └────── VÙNG GLITCH: đọc ở đây ra giá trị ───┘
                          VÔ NGHĨA
```

Ba điều đọc ra được:

1. **`abs_val[7]` và `ovf` ổn định đúng cùng một mốc 0,74 ns.** Đây là bằng chứng **thời
   gian** cho INV-6 (`ovf ≡ abs_val[7]`), bổ sung cho bằng chứng cấu trúc (hai cell `nor4_1`
   giống hệt nhau) và bằng chứng hành vi (256/256).
2. **Thứ tự ổn định không theo thứ tự bit.** `abs_val[7]` (0,74 ns) xong **trước**
   `abs_val[4]`, `[5]`, `[6]` — vì hàm của bit 7 cực thưa (chỉ bằng 1 tại `x = 0x80`).
   Trực giác "bit càng cao càng chậm" **sai** ở khối này.
3. **`sign` ổn định ngay tại 0,00 ns**, tức nó đã đúng trong suốt vùng glitch. Nhưng
   **`ovf` thì không**: trong `0 < t < 0,74 ns` cờ tràn có thể nhấp nháy. **Không được**
   dùng `ovf` làm tín hiệu bất đồng bộ đi thẳng vào logic khác; phải chốt sau khi toàn khối
   ổn định.

Đây cũng là lý do nghĩa vụ hợp đồng ở `control.md` §4 yêu cầu tầng ngoài giữ `x` ổn định đủ
lâu trước khi lấy mẫu.

## 5. Waveform thật đã thu được

`05_VERIFICATION/` sinh file `a09_waves.vcd` cho **11 ca có tên**; vòng quét vét cạn 256
giá trị chạy sau `$dumpoff` nên không làm phình file.

> ⚠️ **Waveform hành vi là zero-delay.** Mở VCD sẽ thấy mọi tín hiệu đổi **tức thời** tại
> mốc `#1` của từng vector — không có vùng glitch nào nhìn thấy được. Waveform dùng để
> chứng minh **giá trị**, không dùng để chứng minh **độ trễ**. Mọi con số thời gian trong
> tài liệu này đến từ OpenSTA, không từ VCD. Muốn thấy glitch thật phải mô phỏng
> gate-level với SDF — chưa chạy, ghi ở `07_TRACEABILITY/limitations.md`.

---

*Phiên bản: v2.0 (thiết kế lại đúng đề Charter) · Ngày: 2026-09-24.*
