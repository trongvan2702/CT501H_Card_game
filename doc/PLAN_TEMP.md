# Plan: Cập nhật tài liệu về scoring và item

## Context

`GDD.md` và `BALANCE.md` đang có nội dung cũ về tính điểm: mô tả điểm theo từng dish thay vì một pipeline theo toàn bộ lượt Play, khẳng định sai rằng `on_play` chưa nối, và không ghi nhận state `plays_left`/`discards_left` được đưa sang `GameManager`. `MatchManager` hiện cũng có hook `on_discard` riêng chạy ngoài pipeline điểm. Người dùng muốn **chỉ cập nhật phần tính điểm**, ưu tiên chính xác theo code, và chỉ sửa hai file `GDD.md` + `BALANCE.md`; không cập nhật bảng item / các tài liệu khác.

## Approach

1. **GDD.md — cập nhật luật, không thay đổi phạm vi nội dung item**
   - §2.3: nguồn số lượt Play/Discard chuyển từ `MatchManager.start_new_stage()` sang state `GameManager.plays_left` / `GameManager.discards_left` được reset và điều chỉnh bởi MatchManager.
   - §3.2: ghi đúng công thức cuối cho toàn bộ lượt Play: `total_score = (sum tất cả trigger.score) × final_mult`, `final_mult` khởi đầu 1.0; trigger additive cộng mult, trigger x_mult nhân mult. Bao gồm score từ ingredients (`IngredientInstance.get_score()` = base_score + state bonus) + recipe score từ `RecipeDB.calculate_score()` + item triggers; làm rõ recipe matching xếp theo `crafted_count` rồi multiplier, nhưng contribution recipe được cộng vào global total (không tính riêng/nhân từng dish). Meta effects được gom trong ScoringSystem result rồi MatchManager thi hành theo nhịp pipeline.
   - §3.4: sửa hook table `on_play` thành đang hoạt động, thêm `on_discard` là hook phụ riêng do MatchManager gọi sau khi giảm discards, không tham gia scoring pipeline và không sửa `ScoringSystem`; `after_match` chỉ được gọi khi thắng stage (xác nhận trong `_win_stage`, không nói thắng hoặc thua).
   - §4.3 / P4 wording: giữ quy tắc không sửa scoring/match lõi cho item thông thường, nhưng ghi chú `on_discard` hiện là exception/hook MatchManager-only phải có đăng ký tường minh; meta effect mới cần handler.
   - §6 debt list: bỏ các mục đã lỗi thời về `on_play` chưa kết nối và kết quả `on_play` bị bỏ; ghi nhận rõ không lỗi nếu đã xử lý/hiện không tồn tại. Không sửa nợ kỹ thuật ngoài scope scoring nếu không liên quan.
   - Glossary hook: thêm `on_discard` và phân biệt scoring hooks vs MatchManager-only lifecycle hooks.
   - Không sửa bảng item §4.4.3 theo scope đã chọn.

2. **BALANCE.md — đồng bộ mô hình scoring**
   - §1.3: đổi cách diễn giải từ mỗi dish tự nhân riêng thành toàn lượt Play: tổng contribution của ingredients, recipes, items rồi nhân một final mult chung; diễn đạt lại các ước lượng để không vô tình cộng các dish đã nhân riêng.
   - §4.1: thay công thức cũ bằng pipeline/global formula, giải thích `RecipeDB.calculate_mult()` trả phần mult recipe và trigger recipe góp trực tiếp vào cùng `final_mult` (khởi đầu 1.0), nên phần recipe cho 1.0 vẫn thành final multiplier 2.0 trước item.
   - §4.3: sửa giá trị ingredient là `IngredientInstance.get_score()` và có thể tăng qua `state["bonus_score"]` (kiểm chứng hiện trường; nếu helper tương ứng tồn tại thì nêu rõ, không thêm spec ngoài scope).
   - §5.2 item table không sửa, theo lựa chọn người dùng.
   - Cập nhật ngày sửa ở hai đầu file nếu cần dùng ngày hiện tại từ environment.

## Critical files

- `doc/GDD.md`
- `doc/BALANCE.md`

Code đã đối chiếu: `scripts/system/ScoringSystem.gd` (pipeline, hooks, total), `scripts/system/MatchManager.gd` (lifecycle, hooks, custom effects), `scripts/autoloads/GameManager.gd` (lượt stage), `scripts/resources/IngredientInstance.gd` (base + bonus score), `scripts/resources/TriggerResult.gd` (fields và defaults), `scripts/resources/Item/ItemInstance.gd` (hook signatures).

## Verification

- Đọc lại phần đã sửa để xác nhận công thức và thời điểm hook khớp từng code path hiện tại.
- Tìm các tuyên bố mâu thuẫn còn lại trong hai doc (`on_play chưa kết nối`, `per-dish multiplication`, `after_match thắng hoặc thua`, variable ownership) bằng content search.
- Không chạy game/test vì chỉ sửa tài liệu; báo các phần doc ngoài scoring cố ý để nguyên, đặc biệt bảng item chưa được cập nhật theo phạm vi đã chọn.
