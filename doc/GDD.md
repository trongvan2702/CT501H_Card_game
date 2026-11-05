# Self_study — Game thẻ bài roguelike nấu ăn

> Một game thẻ bài lấy cảm hứng từ Balatro, nhưng thay poker bằng **nấu ăn**:
> ghép nguyên liệu thành món để gánh điểm, mua thẻ trợ giúp (Item/Joker) giữa các màn,
> đấu boss có luật riêng.

- Engine: Godot 4.4 (GDScript) | Bậc: 2D, UI-driven
- Tài liệu chuẩn: file này. Tài liệu khác chỉ là phụ lục.
- Cập nhật gần nhất: <!-- điền ngày -->

---

## 0. Mục lục

- [1. Design Pillars](#1-design-pillars)
- [2. Core Loop](#2-core-loop)
- [3. Systems](#3-systems)
- [4. Content Spec](#4-content-spec)
- [5. UI/UX](#5-uiux)
- [6. Trạng thái phát triển](#6-trạng-thái-phát-triển)
- [7. Đường cong độ khó](#7-đường-cong-độ-khó)
- [8. Glossary](#8-glossary)
- [9. Câu hỏi đang treo](#9-câu-hỏi-đang-treo)

---

## 1. Design Pillars

<!--
Mỗi pillar gồm:
  - Tên pillar
  - Mô tả nguyên tắc (1-3 câu)
  - "Bài test": một câu hỏi/thử nghiệm để kiểm tra pillar có còn đúng không
Viết 3-5 pillar. Đây là mục quan trọng nhất — dùng để loại bỏ ý tưởng không thuộc về game này.
-->

### P1. "Nấu" phải đọc được, không phải may mắn
Người chơi phải nhìn 5 lá và **tự suy ra** ra món nào, không phải xoay vòng may mắn.
→ Bài test: nếu 2 người chơi cùng bộ bài 7 lá, họ có chọn giống nhau không? Nếu không → hỏng.

### P2. Lá rác không tồn tại
Mọi ingredient đều phải dùng được trong ít nhất 1 món **đang mở khóa từ đầu**.
→ Bài test: lá nào trong 7 lá không nằm trong bất kỳ món nào? Loại hoặc thêm món.

### P3. Chiến thuật đến từ *cách chơi lá*, không từ *con số may*
Mult cao trên lá giá trị thấp (Salt/Pepper) > điểm cao trên lá rẻ.
→ Bài test: nếu đổi toàn bộ base_score, game có đổi cách chơi không?

### P4. Mở rộng không được đụng code lõi
Thêm 100 item / 50 recipe không được sửa `ScoringSystem` hay `MatchManager`.
→ Bài test: item mới có cần viết `if/else` ở đâu đó không? Nếu có → hỏng.

### P5. Mỗi lượt chơi phải có lý do
Không có lượt chơi nào là "chơi cho xong". Có 1 món ngon → đáng chơi.

---

## 2. Core Loop

### 2.1. Mô tả tổng quan

Một dự án game Roguelite Deckbuilder nơi người chơi có thể chế tạo món ăn từ thẻ nguyên liệu. Từ những thẻ nguyên liệu gốc, người chơi có 

### 2.2. Sơ đồ vòng lặp

```
<!-- vẽ sơ đồ ở đây -->
```

### 2.3. Các chỉ số cốt lõi

| Chỉ số | Giá trị | Nguồn trong code |
|---|---|---|
| <!-- tên --> | <!-- giá trị --> | `<!-- file.gd: hàm -->` |

---

## 3. Systems

<!--
Mỗi hệ thống là một heading. Viết ở mức LUẬT CHƠI, không phải mức code.
Người đọc phải chơi được mà không cần mở code.
Dùng bảng khi có điều kiện / trạng thái. Tránh chép lại code.
-->

### 3.1. Ghép món (Recipe matching)

<!--

-->

**Bảng luật:**

| Điều kiện | Kết quả |
|---|---|
| <!-- --> | <!-- --> |

### 3.2. Điểm & hệ số

<!--

-->

### 3.3. Bộ bài, tay bài, lượt chơi

<!--

-->

### 3.4. Item (Joker)

<!--

-->

### 3.5. Boss

<!--

-->

### 3.6. Kinh tế (vàng, shop, reroll)

<!--

-->

### 3.7. Điều kiện thắng / thua & tiến trình màn

<!--

-->

---

## 4. Content Spec

<!--
Mục "đầu tư" nhất: biến việc thêm ingredient/recipe/item thành việc tự thực hiện được.
Mỗi lần thêm nội dung mới, đọc mục này là đủ.
Kèm bảng nội dung hiện tại — nên sinh tự động từ tools/dump_content.gd để không lệch.
-->

### 4.1. Thêm một Ingredient

**Bắt buộc:** <!-- liệt kê field -->

**Quy tắc số:**
<!-- ghi rõ khoảng giá trị và ý nghĩa của từng field -->

**Ràng buộc:**
<!-- ví dụ: không được có ingredient nào mà không món nào mở sẵn dùng -->

### 4.2. Thêm một Recipe

**Bắt buộc:** <!-- liệt kê field -->

**Quy tắc số:**
<!-- ghi rõ cách chọn base_score / base_mult theo số nguyên liệu -->

**Dải giá trị món:**
<!-- bảng hoặc link tới BALANCE.md -->

**Ràng buộc:**
<!-- -->

### 4.3. Thêm một Item

**Các bước:**
1. <!-- -->
2. <!-- -->
3. <!-- -->

**Ràng buộc:**
<!-- ví dụ: không được sửa ScoringSystem/MatchManager -->

### 4.4. Bảng nội dung hiện tại

<!--
Sinh tự động bằng tools/dump_content.gd, không ghi tay.
-->

### 4.4.1. Ingredient

| id | Tên | score | mult | rarity | Ghi chú |
|---|---|---|---|---|---|
| | | | | | |

### 4.4.2. Recipe

| id | Tên | Nguyên liệu yêu cầu | base_score | base_mult | Giá trị món | Mở khóa |
|---|---|---|---|---|---|---|
| | | | | | | |

### 4.4.3. Item

| id | Tên | Rarity | Giá | Hook được dùng | Hiệu ứng |
|---|---|---|---|---|---|
| | | | | | |

---

## 5. UI / UX

<!--
Bảng: màn hình | trạng thái (đã làm / đang làm / chưa làm) | cần có gì.
Kèm quy tắc trạng thái UI (khi nào khoá/mở input).
-->

| Màn | Trạng thái | Cần có |
|---|---|---|
| <!-- --> | <!-- --> | <!-- --> |

**Luật trạng thái UI:**

<!-- ví dụ: UI chỉ mở khoá ở MatchState.WAIT_FOR_INPUT -->

---

## 6. Trạng thái phát triển

<!--
Cập nhật mỗi khi làm xong một việc. Đây là phần trả lời "đang ở đâu"
mà không cần đoán. Giữ ngắn, không mô tả chi tiết kỹ thuật.
-->

### Đã xong ✅

- [ ] <!-- -->

### Đang làm 🚧

- [ ] <!-- -->

### Chưa làm 📋

- [ ] <!-- -->

### Bug / nợ kỹ thuật 🐛

- [ ] <!-- -->

---

## 7. Đường cong độ khó

<!--
Target theo từng stage + nguồn tăng trưởng người chơi.
Chi tiết công thức ở BALANCE.md.
-->

| Stage | Target | Lượt Play | Ghi chú |
|---|---|---|---|
| 1 | | | |
| 2 | | | |
| 3 | | | |
| 4 | | | |
| 5 | | | |

**Công thức:** <!-- -->

**Nguồn tăng trưởng của người chơi:**
<!-- item, nâng cấp món, gói nguyên liệu, thêm lượt chơi... -->

---

## 8. Glossary

<!--
Thuật ngữ riêng của dự án — những từ dùng trong code nhưng ý nghĩa có thể mơ hồ.
Ví dụ: "nấu", "lá", "món", "kệ", "xung modifier".
-->

| Thuật ngữ | Nghĩa |
|---|---|
| | |

---

## 9. Câu hỏi đang treo

<!--
Danh sách câu hỏi chưa có câu trả lời. Chuyển sang DECISIONS.md khi đã chốt.
-->

- [ ] <!-- -->

---

## Ghi chú bổ sung

<!--
Bất cứ thứ gì chưa có chỗ ở trên.
-->
