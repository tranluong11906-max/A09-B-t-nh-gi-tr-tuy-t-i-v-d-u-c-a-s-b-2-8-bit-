# A09 · Sơ đồ hệ thống (System Diagram)

## 1. Sơ đồ khối hệ thống — bộ đo có khối chuẩn hoá tín hiệu lệch tâm

Bối cảnh ứng dụng theo Charter mục 1:

> *"Khối chuẩn hoá tín hiệu lệch tâm trong bộ đo: lấy độ lớn của sai số có dấu để so với
> ngưỡng, giữ riêng bit dấu để biết lệch về phía nào."*

```
   ┌──────────────┐   vị trí đo        ┌───────────────┐
   │  Cảm biến    │ ──────────────────▶│  Bộ trừ       │
   │  vị trí      │   (có dấu)         │  err = đo − đặt│
   └──────────────┘                    └───────┬───────┘
   ┌──────────────┐   vị trí đặt               │ err[7:0]  (bù 2, −128…+127)
   │  Thanh ghi   │ ──────────────────▶        │
   │  ngưỡng đặt  │                            ▼
   └──────────────┘                ╔═══════════════════════════╗
                                   ║        A09  (đề này)      ║
                                   ║   a09_abs_sign            ║
                                   ║   TỔ HỢP THUẦN · 0 ô nhớ  ║
                                   ╚═══╤══════════╤═════════╤══╝
                        abs_val[7:0]   │   sign   │   ovf   │
                       (độ lớn sai số, │ (lệch về │(sai số  │
                        KHÔNG DẤU)     │  phía nào)│ = −128) │
                                       ▼          ▼         ▼
                            ┌──────────────┐  ┌──────────────────────┐
                            │ Bộ so ngưỡng │  │ Logic điều khiển /   │
                            │ abs_val ≥ TH?│  │ chọn chiều bù        │
                            └──────┬───────┘  └──────────┬───────────┘
                                   │ cờ "vượt ngưỡng"    │ chiều hiệu chỉnh
                                   └──────────┬──────────┘
                                              ▼
                                   ┌──────────────────────┐
                                   │  Bộ điều khiển bù    │
                                   │  (có thanh ghi, FSM) │◀── clk, rst  ⟵ Ở ĐÂY mới có clock
                                   └──────────────────────┘
```

**Điểm cần nói khi bảo vệ:** ứng dụng giải thích **vì sao tách `abs_val` và `sign` thành hai
đầu ra riêng** thay vì để tầng sau tự xử lý số có dấu. So sánh độ lớn với ngưỡng bằng phép
so **không dấu** rẻ hơn hẳn phép so **có dấu** (không phải xử lý trường hợp khác dấu), còn
`sign` đi thẳng vào logic chọn chiều bù. Tách sớm ngay tại A09 làm đơn giản **cả hai** tầng
phía sau.

Đây cũng là lý do quy ước "`abs_val` đọc như số không dấu" (`functional_spec.md` §5.2) là
quy ước **tự nhiên** với ứng dụng này, chứ không phải một mẹo để né ca `−128`.

## 2. Ranh giới khối A09

| Nằm **trong** A09 | Nằm **ngoài** A09 |
|---|---|
| Bộ đảo bit 8 INV | Phép trừ sinh ra `err` (là khối khác) |
| Bộ cộng +1 tường minh (8 tầng) | Thanh ghi ngưỡng, bộ so ngưỡng |
| 8 mux 2:1 chọn theo `sign` | Mọi thanh ghi, mọi clock, mọi reset |
| Logic phát hiện `0x80` | Quyết định "làm gì khi `ovf = 1`" |
| — | Lớp vỏ 24 chân Tiny Tapeout (`tt_um_*`) |

Ranh giới này là lý do A09 có **0 ô nhớ**: mọi phần tử nhớ của hệ thống nằm ở bộ điều khiển
bù, phía sau A09.

## 3. Phân rã một tầng xuống dưới

```
a09_abs_sign
├── TẦNG 0 · tách dấu        sign = x[7]                     ← 0 cổng (dây nối)
├── TẦNG 1 · đảo bit         x_inv[i] = ~x[i]                ← 8 INV, song song
├── TẦNG 2 · cộng +1         neg[i]   = x_inv[i] ^ c[i]      ← 8 XOR
│                            c[i+1]   = x_inv[i] & c[i]      ← 8 AND, c[0] = 1
├── TẦNG 3 · mux theo dấu    abs_val[i] = sign ? neg[i] : x[i] ← 8 mux 2:1
└── TẦNG 4 · phát hiện 0x80  ovf = x[7] & NOR(x[6:0])        ← 1 NOR7 + 1 AND
```

Tầng 1+2 gộp lại chính là phép **bù 2** (`neg = ~x + 1`). Tách làm hai tầng trong tài liệu
vì Charter mục 10 yêu cầu **nhìn thấy** cả hai phần, và vì tầng 2 là nơi duy nhất có phụ
thuộc dữ liệu nối tiếp ở mức RTL.

## 4. Phân loại analog / digital / mixed

**Digital thuần, tổ hợp thuần.** Không có phần tử analog, không có phần tử nhớ, không có
clock. Bằng chứng: `06_GDSII/synthesis/synth_stat.txt` — **0 flip-flop / 18 cell**; và
`06_GDSII/sta/` — báo cáo công suất cho nhóm Sequential **0 %**, Clock **0 %**, Combinational
**100 %**.

## 5. Sơ đồ vòng đời RTL → GDSII — trạng thái thật

```
 ┌─────────────┐   ┌─────────────┐   ┌─────────────┐   ┌─────────────┐
 │ 1. Đặc tả   │──▶│ 2. RTL      │──▶│ 3. Mô phỏng │──▶│ 4. Tổng hợp │
 │ Charter→spec│   │ SystemVerilog│   │ Icarus 12.0 │   │ Yosys 0.33  │
 │     ✅      │   │     ✅      │   │ ✅ 266/0 lỗi│   │ ✅ 18 cell  │
 └─────────────┘   └─────────────┘   └─────────────┘   │    0 FF     │
                                                       └──────┬──────┘
                                                              ▼
 ┌─────────────┐   ┌─────────────┐   ┌─────────────┐   ┌─────────────┐
 │ 8. GDSII    │◀──│ 7. DRC/LVS  │◀──│ 6. P&R      │◀──│ 5. STA      │
 │    ⬜ chưa  │   │    ⬜ chưa  │   │ LibreLane   │   │ OpenSTA     │
 │             │   │             │   │   ⬜ chưa   │   │ ✅ 0,96 ns  │
 └─────────────┘   └─────────────┘   └─────────────┘   └─────────────┘
```

| Bước | Trạng thái | Bằng chứng |
|---|---|---|
| 1 · Đặc tả | ✅ | `02_SPECIFICATION/functional_spec.md` |
| 2 · RTL | ✅ | `04_IMPLEMENTATION/rtl/a09_abs_sign.sv` |
| 3 · Mô phỏng | ✅ PASS, 266 vector, 0 lỗi | `05_VERIFICATION/simulation.log` |
| 4 · Tổng hợp | ✅ 18 cell · 0 FF · 118,864 µm² | `06_GDSII/synthesis/synth_stat.txt` |
| 5 · STA | ✅ 0,96 ns (clock ảo 10 ns, slack 9,04 ns) | `06_GDSII/sta/` |
| 6 · P&R | ⬜ chưa chạy — cần PDK sky130A + LibreLane | — |
| 7 · DRC / LVS | ⬜ chưa chạy | — |
| 8 · GDSII | ⬜ chưa có | — |

**Không được khẳng định** "đã sign-off", "đã tape-out", "đã chế tạo" — Charter mục 3 loại
tất cả khỏi phạm vi.

---

*Phiên bản: v2.0 (thiết kế lại đúng đề Charter) · Ngày: 2026-09-24.*
