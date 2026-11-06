# DECISIONS.md — Quyết định đã chốt

> Mỗi quyết định ghi: **vấn đề → lựa chọn → lý do → hệ quả**.
> Khi một câu hỏi trong `GDD.md` §9 được chốt → chuyển sang đây và gạch khỏi §9.

Cập nhật gần nhất: 2026-07-07

---

### D-01 · Cơ chế ghép món: người chơi không chọn món

**Vấn đề:** Có nên thêm bước người chơi chọn món muốn nấu (như chọn Hand Type trong
Balatro), hay để hệ thống tự ghép?

**Quyết định:** Giữ như code hiện tại. Người chơi **chỉ chọn nguyên liệu**; hệ thống
tự quét các món đã mở khóa, chọn món có `score × (1 + mult)` cao nhất, tiêu thụ
nguyên liệu, lặp lại. Nguyên liệu không khớp món nào → bỏ, không tính điểm.

**Lý do:** Giữ đơn giản cho UI (chỉ 1 màn "chọn lá"), đúng tinh thần "nấu phải đọc
được" (P1) — người chơi tự suy ra món, game chỉ xác nhận.

**Hệ quả:**
- UI không cần màn chọn món → giảm 1 màn hình trong UI/UX.
- Nguyên liệu thừa = lãng phí → cần UI cảnh báo "lá này không vào món nào"
  để người chơi hiểu vì sao điểm thấp.
- Vì game tự chọn, món 2 lá trả điểm thấp hơn món 4 lá là hợp lý, nhưng khoảng cách
  phải cân lại (xem `BALANCE.md` §6.6).

---

### D-02 · Lá bỏ: vào discard pile, không dùng lại trong stage

**Vấn đề:** Lá bỏ (Discard) sẽ đi đâu? Balatro trộn discard pile vào draw pile khi
draw pile rỗng.

**Quyết định:** Lá bỏ vào **discard pile**, **không được dùng lại trong stage đó**.
Sang stage kế tiếp, bộ bài được xáo lại từ bộ bài gốc → lá bỏ xuất hiện trở lại.
**Không** trộn discard pile vào draw pile trong cùng stage.

**Lý do:** Giữ "quyết định bỏ lá" có hậu quả thật trong stage hiện tại, nhưng không
tạo cảm giác bộ bài bị cạn dần vô lý. Bộ bài 40 lá / 7 lá tay / 4 lượt cũng không
bao giờ cạn trong 1 stage.

**Hệ quả:**
- `DeckManager.discard_pile` phải được dùng thật (hiện chưa) và reset mỗi stage.
- Có thể hiển thị số lá mỗi pile trên UI (3 chỉ báo) để người chơi hiểu luật.

---

### D-03 · Boss: cứ 3 stage có 1 boss, không trùng trong 1 run

**Vấn đề:** Run vô hạn nhưng chỉ có 3 boss. Lặp lại hay thêm nội dung?

**Quyết định:** Mỗi stage chia hết cho 3 → 1 boss. Boss được roll ngẫu nhiên và
**không trùng trong cùng một run**.

**Lý do:** Tránh màn boss lặp lại cùng luật (chán), giữ được cảm giác "boss khác
nhau" khi leo stage.

**Hệ quả:**
- **Cần bổ sung nội dung boss**: 3 boss hiện tại chỉ đủ 9 stage. Cần thêm boss
  mới để chạy sâu hơn — nợ nội dung (GDD §6).
- Cần cơ chế an toàn khi pool cạn (fallback) — chưa chốt, xem GDD §9.

---

### D-04 · Tối đa 5 item trang bị

**Vấn đề:** `GameManager.max_active_items = 5` nhưng `ShopManager.buy_item()` không
kiểm tra → mua vô hạn.

**Quyết định:** Có giới hạn **5 item** đang trang bị (giá trị đã khai báo sẵn trong
code).

**Hệ quả:**
- `ShopManager.buy_item()` phải kiểm tra giới hạn và chặn mua (nợ kỹ thuật, GDD §6.3).
- UI cần hiển thị "kệ item (n/5)" và disable nút mua khi đủ.
- Boss được trang bị **tạm** trong stage boss → không tính vào 5 item? Cần chốt:
  hiện `MatchManager` nối boss vào `equipped_items` sau khi copy `active_items`,
  nên boss **không** chiếm suất 5.

---

### D-05 · Target score vô hạn: bảng cố định rồi nhân hệ số

**Vấn đề:** Run vô hạn nhưng `base_target_score` chỉ 9 phần tử → lỗi out-of-bounds
từ stage 28.

**Quyết định:** 9 nhóm × 3 stage = **27 stage có số cụ thể** (phủ stage 1–27).
Từ stage 28 trở đi: **nhân thêm hệ số**. Giá trị hệ số **TBD**.

**Hệ quả:**
- Cần cơ chế mở rộng bảng hoặc công thức nhân ở `StageManager`.
- Đề xuất ban đầu: ×1.5 cho mỗi nhóm mới — chưa chốt, xem GDD §9.
- Bảng target hiện tại có chỗ bất thường (nhóm 16–18 = 1100 < nhóm 13–15 = 5000)
  → cần hiệu chỉnh, xem `BALANCE.md` §1.1.

---

### D-06 · Run vô hạn

**Vấn đề:** Run kết thúc ở đâu?

**Quyết định:** Run **vô hạn**. Không có stage cuối. Người chơi chơi tới khi thua
(hết lượt chưa đạt target) → Game Over.

**Hệ quả:**
- Cần màn Game Over (chưa làm — GDD §5).
- Leaderboard/score cuối run: xem xét sau.

---

### D-07 · Phạm vi GDD giai đoạn UI: chỉ liệt kê màn hình

**Vấn đề:** GDD mô tả UI ở mức nào trước khi làm UI?

**Quyết định:** GDD giai đoạn này **chỉ liệt kê các màn hình cần có** và quy tắc
khoá/mở input theo `MatchState`. Không spec layout chi tiết, không đụng hướng nghệ
thuật.

**Hệ quả:** Khi bắt tay vào UI, có thể bổ sung một mục "UI Spec" riêng (hoặc mở rộng
GDD §5) mà không phải sửa lại phần luật chơi.

---

### D-08 · Lần này chỉ viết tài liệu, không sửa code

**Quyết định:** Phạm vi công việc hiện tại = 3 file doc (`GDD.md`, `BALANCE.md`,
`DECISIONS.md`). Không sửa code trong lần này; toàn bộ phát hiện về bug được liệt kê
ở GDD §6.

**Hệ quả:** GDD §6 hiện có 14 nợ kỹ thuật cần xử lý ở lần sau (theo thứ tự ưu tiên
trong `BALANCE.md` §6 cho phần cân bằng).

---

### D-09 · Bố cục tài liệu: 3 file

**Quyết định:**
- `GDD.md` — tài liệu chuẩn: luật chơi, spec nội dung, UI, trạng thái phát triển.
- `BALANCE.md` — **mọi con số**: target score, giá shop, trọng số rarity, bảng
  nội dung đầy đủ.
- `DECISIONS.md` — các quyết định đã chốt kèm lý do (file này).

**Lý do:** GDD đọc dễ và không bị chìm trong số; số cân bằng cần cập nhật thường xuyên
nên tách riêng để không phá cấu trúc GDD.

---

### D-10 · Trong run, boss không chiếm suất item (giả định)

**Liên quan D-04.** Boss được nối vào `equipped_items` *sau* khi copy
`GameManager.active_items`, nên boss không bị tính vào giới hạn 5 item.

**Trạng thái:** giả định theo code hiện tại — **cần xác nhận** rằng đây là ý muốn
(thiếu boss có thể bị coi là "không mang item boss trong kệ" — chấp nhận được).
