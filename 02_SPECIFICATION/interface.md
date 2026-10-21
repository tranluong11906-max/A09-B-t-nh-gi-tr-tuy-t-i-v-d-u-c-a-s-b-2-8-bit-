# A09 · Giao diện (Interface)

---

## 1. Ánh xạ chân theo Charter (mục 4)

> Theo danh mục đề: ui_in[7:0]=x (bù 2) · uo_out[7:0]=|x| · uio_out[0]=dấu · uio_out[1]=cờ tràn
> Ngân sách chân: 8 bit vào + 10 bit ra = 18 trên 24 chân.
## 2. Bảng giao diện đã CHỐT — module `a09_abs_sign`

Bảng giao diện được đối chiếu với các cổng khai báo trong
`04_IMPLEMENTATION/rtl/a09_abs_sign.sv`.

| Tín hiệu RTL | Chiều | Độ rộng (bit) | Vai trò | Ánh xạ Charter |
|---|---|---:|---|---|
| `x` | Input | 8 | Số đầu vào dạng bù 2 | `ui_in[7:0]` |
| `abs_val` | Output | 8 | Giá trị tuyệt đối trong 8 bit | `uo_out[7:0]` |
| `sign` | Output | 1 | `1` nếu đầu vào âm | `uio_out[0]` |
| `ovf` | Output | 1 | `1` khi đầu vào là `0x80` (-128) | `uio_out[1]` |

**Tổng hợp:** 8 bit vào + 10 bit ra = 18 bit logic.

**Không có clock** — khối tổ hợp thuần.

**Không có reset** — không có trạng thái để đặt lại.

## 3. Ngân sách chân Tiny Tapeout

| Hạng mục | Số bit |
|---|---:|
| `ui_in` — đầu vào | 8 |
| `uo_out` — đầu ra | 8 |
| `uio_out` — đầu ra dùng chân đa hướng | 2 |
| Tổng số chân logic được sử dụng | **18** |
| Số chân vật lý của một tile | 24 |
| Số chân còn dư theo phép tính ngân sách | **6** |






## 4. Điều kiện hợp lệ của đầu vào

| Điều kiện | Ai bảo đảm |
|---|---|
| Các cổng vào không chứa `X`/`Z` khi lấy mẫu | Tầng ngoài |
| Đầu ra được lấy mẫu sau khi mạch đã ổn định | Tầng ngoài, theo số liệu `06_GDSII/sta/` |


---

*Phiên bản: v1.0 · Ngày: 2026-09-24 · Truy vết: REQ-A09-002, AC-1.*
