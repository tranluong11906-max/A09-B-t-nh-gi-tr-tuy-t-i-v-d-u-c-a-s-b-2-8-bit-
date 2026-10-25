# A09 - Activity Log

Nhat ky qua trinh thuc hien de tai:
"Bo tinh gia tri tuyet doi va dau cua so bu 2 8-bit"

## 1. Khoi tao du an va RTL
- Tao repository va cau truc thu muc cho du an A09.
- Xay dung khoi RTL tinh gia tri tuyet doi va dau cua so bu 2 8-bit.
- Xac dinh giao dien dau vao, dau ra va co bao tran cho truong hop -128.

## 2. Kiem chung thiet ke
- Chay mo hinh tham chieu Python.
- Kiem chung RTL voi 266 vector, ghi nhan 0 sai khac.
- Kiem tra cac bat bien cua thiet ke.
- Cap nhat bao cao verification va bang truy vet yeu cau.

## 3. Tong hop va phan tich
- Su dung Yosys de tong hop RTL.
- Ghi lai netlist, thong ke tong hop va phien ban cong cu.
- Su dung OpenSTA de phan tich timing doc lap.
- Luu bao cao timing va uoc luong cong suat.

## 4. Thuc hien RTL-to-GDSII voi OpenLane
- Chay quy trinh physical design bang OpenLane voi PDK Sky130A.
- Tao cac ket qua implementation va netlist sau routing.
- Tao layout GDSII cho thiet ke A09.
- Luu bao cao physical design va cac bao cao lien quan.

## 5. Kiem tra physical design
- Kiem tra bao cao DRC: COUNT = 0.
- Kiem tra bao cao LVS: Total errors = 0, khong co sai khac net, device, pin hoac property.
- Ghi nhan cac gioi han va can than trong khi dien giai ket qua timing.

## 6. Xem layout va quan ly ma nguon
- Mo file GDSII bang KLayout de xem layout.
- Luu anh layout vao `06_GDSII/a09_klayout.png`.
- Cap nhat tai lieu physical design va day cac commit len GitHub.

## 7. Cac commit da ghi nhan
- `299004b` - Initial commit: A09 absolute value and sign unit
- `a3a98b5` - Update A09 verification and implementation evidence
- `f6e499d` - Add A09 OpenLane RTL-to-GDSII results
- `8db11b9` - Add A09 physical design report
- `12ea2ed` - Add KLayout screenshot of A09 physical layout

## 8. Luu y
Nhat ky nay tom tat cac moc cong viec da thuc hien.
Cac ket qua cu the can doi chieu voi cac bao cao va tep dau ra
trong repository. Khong xem timing doc lap hoac timing global-route
la bang chung thay the cho timing signoff cuoi cung sau routing.
