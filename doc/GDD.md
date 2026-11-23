# Self_study — Game thẻ bài roguelike nấu ăn

> Một game thẻ bài lấy cảm hứng từ Balatro, nhưng thay poker bằng **nấu ăn**:
> ghép nguyên liệu thành món để gánh điểm, mua thẻ trợ giúp (Item/Joker) giữa các màn,
> đấu boss có luật riêng.

- Engine: Godot 4.4 (GDScript) | Thể loại: 2D, UI-driven
- Tài liệu chuẩn: file này. Phụ lục: `BALANCE.md` (số cân bằng), `DECISIONS.md` (quyết định đã chốt)
- Cập nhật gần nhất: 2026-07-07

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
Thêm 100 item / 50 recipe không được sửa `ScoringSystem` hay `MatchManager`. (Nếu cần thay đổi cần hỏi ý tôi trước)

### P5. Mỗi lượt chơi phải có lý do
Không có lượt chơi nào là "chơi cho xong". Có 1 món ngon → đáng chơi.

---

## 2. Core Loop

### 2.1. Mô tả tổng quan

Một dự án game Roguelite Deckbuilder nơi người chơi chế tạo món ăn từ thẻ nguyên liệu.
Từ bộ bài nguyên liệu, người chơi mỗi màn (stage) chọn tối đa 5 lá đánh ra, hệ thống
**tự động ghép** các lá đó thành các món (recipe) để tính điểm. Đạt điểm mục tiêu của
màn → vào Shop mua Item (trợ giúp kiểu Joker), mở khóa/nâng cấp công thức, thêm hoặc
bớt lá trong bộ bài, rồi chuyển sang stage tiếp theo với mục tiêu cao hơn. Cứ 3 stage
một boss xuất hiện kèm một quy tắc xấu (mất lượt, phạt thịt, đánh thuế món bò…).
Run vô hạn: càng đi xa, mục tiêu càng lớn; năng lực người chơi tăng nhờ item,
cấp công thức và chỉnh sửa bộ bài.

### 2.2. Sơ đồ vòng lặp

```
┌────────────────────────────── RUN (vô hạn) ──────────────────────────────┐
│                                                                          │
│   STAGE (stage N)                                                       │
│   ├─ Start: xáo bộ bài, rút 7 lá; nếu N % 3 == 0 → boss kích hoạt      │
│   ├─ 4 lượt Play: chọn ≤5 lá → "nấu" → điểm cộng dồn                  │
│   │        (3 lượt Discard: bỏ ≤5 lá, lá bỏ KHÔNG dùng lại trong stage)│
│   ├─ Điểm ≥ target → THẮNG ──────────┐                                  │
│   └─ Hết lượt chưa đủ điểm → THUA    │                                  │
│                                       ▼                                  │
│   SHOP (giữa các stage)                                                   │
│   ├─ Mua Item (3 ô ngẫu nhiên, reroll được)                              │
│   ├─ Mua 1 gói Công thức (chọn 1/3 → mở khóa hoặc +1 cấp)              │
│   ├─ Mua 1 gói Nguyên liệu (chọn 1/3 → thêm lá vào bộ bài)              │
│   ├─ Mua 1 lần Xóa lá (chọn 1/3 lá → bớt khỏi bộ bài vĩnh viễn)        │
│   └─ Nhận tiền thưởng → sang STAGE N+1 (quay đầu vòng)                  │
└──────────────────────────────────────────────────────────────────────────┘
```

### 2.3. Các chỉ số cốt lõi

| Chỉ số | Giá trị | Nguồn trong code |
|---|---|---|
| Bộ bài khởi đầu | 8 loại × 5 lá = 40 lá | `GameManager._build_starter_deck()` |
| Tay bài tối đa | 7 lá | `MatchManager.max_hand_size` |
| Số lá chọn được mỗi lượt | 5 | `HandManager.max_select` |
| Lượt Play / stage | 4 | khởi tạo `GameManager.plays_left`; reset + điều chỉnh qua `MatchManager` |
| Lượt Discard / stage | 3 | khởi tạo `GameManager.discards_left`; reset + điều chỉnh qua `MatchManager` |
| Rút bù mỗi lần | tối đa 5 lá | `MatchManager.draw_cards_to_full()` |
| Vàng khởi điểm | 100 | `GameManager.start_new_run()` |
| Item trang bị tối đa | 5 | `GameManager.max_active_items` |
| Boss | cứ mỗi stage thứ 3 | `StageManager._setup_stage_rules()` |

---

## 3. Systems

> Mỗi hệ thống viết ở mức **luật chơi** — người đọc phải chơi được mà không mở code.

### 3.1. Ghép món (Recipe matching)

Người chơi **chỉ chọn nguyên liệu**, không chọn món. Hệ thống tự quyết định nấu thành
món nào. Đây là quyết định đã chốt (D-01 trong `DECISIONS.md`):

- Sau khi chọn ≤5 lá và bấm Play, hệ thống lấy danh sách **món đã mở khóa** (unlocked).
- Mỗi vòng lặp: thử khớp từng món với các nguyên liệu còn lại; chọn món cho điểm
  `score × (1 + mult)` lớn nhất; tiêu thụ đúng nguyên liệu món đó; lặp lại.
- Nguyên liệu không khớp được món nào → **bỏ, không tính điểm** (không có "món rác").
- Một món yêu cầu đúng số nguyên liệu liệt kê trong công thức (mỗi loại đúng 1).

**Bảng luật:**

| Điều kiện | Kết quả |
|---|---|
| Tay có đủ nguyên liệu của 1 món đã mở khóa | Nấu được món đó |
| Tay có đủ nguyên liệu của 2 món | Hệ thống chọn 2 món (nếu nguyên liệu không chồng nhau) hoặc 1 món cho điểm cao nhất |
| Nguyên liệu thừa không khớp món nào | Bỏ, không tính điểm |
| Món chưa mở khóa (locked) | Không được ghép — phải mở khóa ở Shop trước |

Ví dụ: tay `[Beef, Chicken, Cabbage, Rice, Salt]` với toàn bộ món đã mở khóa khởi đầu
→ hệ thống chọn **Super Disk** (beef+chicken+cabbage+rice), lá Salt còn lại bị bỏ.

> ⚠️ Chi tiết kỹ thuật: trường `min_ingredient` / `max_ingredient` trong `RecipeData`
> đang được khai báo nhưng **chưa được dùng** trong bộ ghép món — xem mục 6.

### 3.2. Điểm & hệ số

Mỗi lượt Play tạo **một pipeline duy nhất** chứa các trigger từ toàn bộ món được nấu và
các item. Sau khi pipeline hoàn tất, điểm của lượt được tính một lần:

```
Điểm lượt Play = (Σ score của tất cả trigger) × final_mult
final_mult khởi đầu = 1.0
   • Trigger thường (x_mult = false) → cộng dồn: final_mult += trigger.mult
   • Trigger nhân (x_mult = true)    → nhân dồn:  final_mult *= trigger.mult
```

**Quan trọng:** không tính `(score × mult)` riêng cho từng món rồi cộng các món lại.
Mọi score và mult từ ingredients, recipes và items cùng đóng góp vào một tổng score
và một `final_mult` chung cho lượt Play.

| Thành phần | Góp vào pipeline |
|---|---|
| Mỗi nguyên liệu được dùng trong món | `IngredientInstance.get_score()` = `base_score + state["bonus_score"]`; nguyên liệu thừa không vào pipeline |
| Mỗi món (recipe) | Score = `RecipeDB.calculate_score(recipe)`; mult = `RecipeDB.calculate_mult(recipe)`; đều cộng vào pipeline chung |
| Item (Joker) | Trigger từ `on_play`, `on_ingredient_scored`, `on_recipe_scored`; score/mult theo kết quả hook |

**Thứ tự pipeline trong lượt Play:**
1. `on_play` của các item, trước ghép món.
2. Với từng món theo thứ tự ghép: từng ingredient được dùng và hook `on_ingredient_scored` của item chạy ngay sau ingredient tương ứng.
3. Trigger recipe, rồi hook `on_recipe_scored` của item.
4. Sau khi pipeline xây xong, tính `(Σ score) × final_mult` một lần.

Recipe matching dùng `crafted_count` để ưu tiên món đã nấu nhiều; khi bằng nhau, ưu tiên
recipe mult cao hơn. Đây là quy tắc chọn món, độc lập với việc tính điểm cuối: recipe
được chọn vẫn góp trigger vào pipeline toàn lượt.

- **Cấp công thức**: mỗi lần mua gói Công thức mà ra đúng món đó (đã mở khóa) → +1 cấp.
- **Meta effects** (`add_money`, `add_plays`, `add_discards`, `max_interest_gold`) không
  phải điểm. ScoringSystem tổng hợp meta effects trong kết quả lượt; MatchManager áp dụng
  effect theo nhịp trigger trong lúc trình diễn pipeline. Hook lifecycle riêng như
  `on_stage_start` / `on_discard` cũng chuyển meta effects qua MatchManager, không đưa
  chúng vào pipeline tính điểm.

### 3.3. Bộ bài, tay bài, lượt chơi

- **Bộ bài (deck)**: danh sách lá sở hữu của người chơi (khởi điểm 40 lá, xem 2.3).
  Shop có thể thêm hoặc bớt lá vĩnh viễn.
- **Mỗi stage**: xáo bộ bài thành Draw pile. Rút 7 lá làm tay bài.
- **Play** (4 lượt): chọn ≤5 lá → hệ thống nấu (3.1) → cộng điểm vào màn. Tay bài
  được rút bù (tối đa 5 lá mỗi lần rút).
- **Discard** (3 lượt): chọn ≤5 lá bỏ đi. **Lá bỏ vào discard pile và KHÔNG được
  dùng lại trong stage đó**; sang stage sau bộ bài được xáo lại từ bộ bài gốc nên
  lá xuất hiện trở lại (D-02). Tay bài cũng được rút bù sau khi bỏ.
- Không có cơ chế trộn discard pile vào draw pile **trong cùng stage** (khác Balatro).
- Thắng: điểm màn ≥ target (3.7). Thua: hết lượt Play mà chưa đạt.

### 3.4. Item (Joker)

Item là thẻ trợ giúp, mua ở Shop, **tối đa 5 thẻ đang trang bị** (D-04). Mỗi item
được kích hoạt qua các **hook** (điểm cài vào pipeline) và trả về kết quả
(triggered hay không, score/mult/meta effect nào):

| Hook | Thời điểm kích hoạt | Vài vai trò |
|---|---|---|
| `on_stage_start` | Khi stage bắt đầu (1 lần) | meta effects qua `MatchManager`, không vào pipeline điểm |
| `on_play` | Mỗi lượt Play, **trước khi ghép món** (trigger nằm đầu pipeline) | score/mult vào pipeline điểm |
| `on_ingredient_scored` | Mỗi nguyên liệu được dùng vào món (lần lượt theo ingredient) | score/mult vào pipeline điểm |
| `on_recipe_scored` | Mỗi món được nấu ra | score/mult vào pipeline điểm |
| `after_match` | Kết thúc stage, **chỉ khi thắng** (`_win_stage`) | meta effects, không vào pipeline điểm |
| `on_discard` | Mỗi lần bấm Discard, sau khi giảm `GameManager.discards_left` | meta effects qua `MatchManager`, không vào pipeline điểm |

> `on_play`/`on_ingredient_scored`/`on_recipe_scored` là các hook **scoring** —
> kết quả của chúng (score, mult, x_mult) được tính trong pipeline của lượt Play.
> `on_stage_start`/`after_match`/`on_discard` là các hook **lifecycle** — chỉ chuyển
> meta effect (tiền, lượt, interest) qua `MatchManager.apply_meta_effects()`, không
> tác động trực tiếp đến điểm của lượt.

Item đặc biệt: **Boss** (mục 3.5) cũng là item nhưng chỉ trang bị tạm trong stage
boss, không mua ở Shop.

### 3.5. Boss

- Mỗi stage có số thứ chia hết cho 3 (stage 3, 6, 9, …) → boss xuất hiện (D-03).
- Boss được **roll ngẫu nhiên, không trùng trong cùng một run**. Nội dung boss hiện
  có 3 con (Fatigue, Vegetarian, Beef Tax) → chỉ đủ 9 stage; cần thêm boss mới để
  chạy dài hơn (nợ nội dung, mục 6).
- Boss = item đặc biệt gắn vào màn; luật của boss chạy qua hook như item thường.

| Boss | Luật |
|---|---|
| Fatigue | Bắt đầu stage: **-1 lượt Play** |
| Vegetarian | Mọi lá **Beef / Chicken** trong món bị nhân **×0 mult** (thịt = không ra điểm) |
| Beef Tax | Mỗi món Beef Steak nấu ra: **-5 vàng** |

### 3.6. Kinh tế (vàng, shop, reroll)

| Nguồn / Chi | Số | Ghi chú |
|---|---|---|
| Vàng khởi điểm | 100 | `GameManager` |
| Thưởng thắng stage | 5 | cố định |
| Lãi (interest) | `vàng ÷ 5`, trần 5 | trần tăng được bằng effect `max_interest_gold` |
| Item (thẻ trợ giúp) | 3 ô / stage, giá theo bảng Shop | không mua trùng item đang có |
| Reroll kệ Item | 5, +1 mỗi lần reroll | trong cùng stage |
| Gói Công thức | 5, 1 lần / stage | chọn 1/3 món → mở khóa hoặc +1 cấp |
| Gói Nguyên liệu | 5, 1 lần / stage | chọn 1/3 lá → thêm vào bộ bài |
| Xóa lá | 5, 1 lần / stage | chọn 1/3 lá trong bộ bài → bớt vĩnh viễn; bộ bài phải >3 lá |

Rarity (xác suất ra ở kệ item): Common 80%, Uncommon 15%, Rare 3%, Legendary 2%.

### 3.7. Điều kiện thắng / thua & tiến trình màn

- **Thắng stage**: điểm màn ≥ target → nhận tiền (3.6) → chuyển màn Shop.
- **Thua run**: hết lượt Play chưa đạt target → Game Over (chưa có màn hình, mục 5).
- **Vô hạn**: không có "stage cuối". Target mỗi stage lấy theo bảng 9 nhóm trong
  `BALANCE.md` (phủ stage 1–27); từ stage 28 trở đi nhân thêm hệ số (D-05, giá trị TBD).

---

## 4. Content Spec

> Mục "đầu tư" nhất: biến việc thêm ingredient/recipe/item thành việc tự thực hiện được.

### 4.1. Thêm một Ingredient

Tạo file `.tres` trong `resources/ingredients/` (type `IngredientData`).

**Bắt buộc:**
`ingredient_id` (snake_case, dùng làm key ghép món), `display_name`, `base_score`,
`icon_texture`.

**Quy tắc số:**
- `base_score` khởi điểm hiện hành: 8–30 (xem bảng 4.4.1). Lá "gia vị" thấp
  (Salt/Pepper/Rice ≈ 8–12), lá "chính" cao (Beef = 30).
- `rarity`: khai báo cho tương lai, hiện chưa dùng ở đâu (ingredient không có rarity
  thực tế — gói nguyên liệu chọn đều như nhau).

**Ràng buộc:**
- Không được có ingredient mà **không một món đã mở khóa nào** dùng đến (Pillar P2).
- ID phải khớp với chỗ dùng trong `RecipeData.required_ingredients`.

### 4.2. Thêm một Recipe

Tạo file `.tres` trong `resources/recipes/` (type `RecipeData`).

**Bắt buộc:**
`recipe_id`, `recipe_name`, `required_ingredients` (mảng IngredientData, mỗi loại 1),
`base_score`, `base_mult`, `bonus_score_per_level`, `bonus_mult_per_level`,
`default_unlocked`.

**Quy tắc số:**
- `base_score` tăng theo số nguyên liệu: 2 nguyên liệu ≈ 16–35, 3 ≈ 35–40, 4 ≈ 55–75.
- `base_mult` ≈ 0.4–1.0; món ít nguyên liệu thường mult cao hơn (compensate).
- Giá trị món ước tính = `(base_score + Σ base_score nguyên liệu) × (1 + base_mult)`
  — xem bảng "Giá trị món (lv1)" trong `BALANCE.md`.
- `default_unlocked = true` chỉ cho món khởi đầu (hiện có 8); món sau phải mở ở Shop.

**Ràng buộc:**
- Chỉ dùng ingredient đã tồn tại trong `resources/ingredients/`.
- Phải cân bằng được với mục tiêu stage đang mở (stage 1–3 với 8 món unlock sẵn).

### 4.3. Thêm một Item

**Các bước:**
1. Tạo `.tres` trong `resources/items/` (type `ItemData`): `item_id`, `display_name`,
   `description`, `rarity`, `price`, và trỏ `logic_script` tới script dưới đây.
   Item boss thêm `is_boss = true`.
2. Viết script ở `scripts/items/`, `extends ItemInstance`, override các hook cần
   (3.4) và trả `TriggerResult` (đã `triggered = false` khi không kích hoạt).
3. Xong. `ItemDB` tự nạp item mới khi game khởi động (quét thư mục `.tres`).

**Ràng buộc:**
- Không được sửa `ScoringSystem` / `MatchManager` (Pillar P4). Effect mới cho hệ thống
  → thêm vào `effect_handlers` của MatchManager (nơi duy nhất đăng ký effect).
- Item thường phải để `rarity` trong 1–4 và giá theo bảng Shop; boss để `is_boss`.

### 4.4. Bảng nội dung hiện tại

> Sinh tay từ các file `.tres` lúc 2026-07-07. Khi thêm nội dung, cập nhật bảng này
> (đề xuất: làm `tools/dump_content.gd` để sinh tự động — mục 6).

#### 4.4.1. Ingredient (8)

| id | Tên | score | mult | rarity | Ghi chú |
|---|---|---|---|---|---|
| beef | Beef | 30 | – | 1 | lá "chính" đắt nhất |
| cabbage | Cabbage | 18 | – | 1 | |
| chicken | Chicken | 20 | – | 1 | bò + gà = 2 "thịt" (liên quan boss Vegetarian) |
| egg | Egg | 20 | – | 1 | duy nhất có món 2 trứng (Omelette) |
| pepper | Pepper | 8 | – | 1 | lá gia vị |
| rice | Rice | 12 | – | 1 | |
| salt | Salt | 12 | – | 1 | |
| tomato | Tomato | 15 | – | 1 | |

#### 4.4.2. Recipe (13)

| id | Tên | Nguyên liệu | base_score | base_mult | Giá trị món (lv1) | Mở khóa |
|---|---|---|---|---|---|---|
| salted_rice | Salted Rice | rice+salt | 16 | 1.0 | 80 | ✅ |
| salt_pepper | Salt Pepper | salt+pepper | 20 | 1.0 | 80 | ✅ |
| grilled_chicken | Grilled Chicken | chicken+salt | 22 | 0.5 | 81 | ✅ |
| omelette | Omelette | egg+egg | 25 | 0.5 | 97.5 | ✅ |
| beef_steak | Beef Steak | beef+pepper | 25 | 0.5 | 94.5 | ✅ |
| kimchi | Kimchi | cabbage+pepper | 20 | 0.4 | 64.4 | ✅ |
| fresh_salad | Fresh Salad | tomato+cabbage | 20 | 0.4 | 74.2 | ✅ |
| super_disk | Super Disk | beef+chicken+cabbage+rice | 55 | 0.8 | 243 | ✅ |
| chicken_fried_rice | Chicken Fried Rice | chicken+pepper+salt | 35 | 0.6 | 120 | 🔒 |
| chicken_pepper | Chicken Pepper | chicken+pepper | 30 | 0.8 | 104.4 | 🔒 |
| beef_stew | Beef Stew | beef+tomato+salt | 40 | 0.7 | 164.9 | 🔒 |
| garden_salad | Garden Salad | tomato+beef+chicken+salt | 55 | 0.8 | 237.6 | 🔒 |
| meat_meat | Meat Meat | beef+chicken | 75 | 0.5 | 187.5 | 🔒 |

> ("Giá trị món (lv1)" = `(base_score + Σ nguyên liệu) × (1 + base_mult)`.
> Chênh lệch giữa các món đã unlock khá lớn: Super Disk = 243 vs Kimchi = 64 — xem 4.5.)

#### 4.4.3. Item (9 thường + 3 boss)

> *(10 item mới chưa cập nhật vào bảng: 8 item +3 Mult theo nguyên liệu
> (Butcher's Charm–beef, Savoy's Secret–cabbage, Coop Keeper–chicken,
> Scrambled Soul–egg, Peppercorn Perk–pepper, Grain of Fortune–rice,
> Salt of the Earth–salt, Vine Ripened–tomato; hook `on_ingredient_scored`),
> Deck Thinner (`on_play`, +30×số lượt discard còn lại) và Last Chance
> (`on_play`, +15 Mult khi không còn lượt discard). Cả 10 đều rarity 1, giá 5.)*

| id | Tên | Rarity | Giá | Hook | Hiệu ứng |
|---|---|---|---|---|---|
| beef_lover | Beef Lover | 1 | 5 | on_ingredient_scored | +8 score cho mỗi lá Beef trong món |
| beef_steak_master | Beef Steak Master | 1 | 5 | on_recipe_scored | **×2 mult** cho mỗi món Beef Steak |
| meatt | Meatt | 1 | 5 | on_recipe_scored | +2 mult (cộng) cho mỗi món Beef Steak |
| fork | Fork | 1 | 5 | on_stage_start | +1 lượt Discard |
| spoon | Spoon | 1 | 5 | on_stage_start | +1 lượt Play |
| rice_accumulator | Rice Accumulator | 1 | 5 | on_play (hook đã nối, nhưng script đang ghi `_on_play` nên chưa chạy — xem mục 6) | +8.8 mult nếu lượt vừa rồi chơi ≥3 lá Rice |
| goldtest1 | Gold1 (test) | 1 | 5 | on_ingredient_scored | +1$ mỗi lá Beef *(nội dung thử)* |
| goldtest2 | Gold2 (test) | 1 | 5 | on_recipe_scored | +3$ mỗi món Beef Steak *(nội dung thử)* |
| goldtest3 | Gold3 (test) | 1 | 5 | after_match | +3$ khi hết stage *(nội dung thử)* |
| boss_fatigue | Fatigue (boss) | – | – | on_stage_start | -1 lượt Play |
| boss_vegetarian | Vegetarian (boss) | – | – | on_ingredient_scored | Beef/Chicken ×0 mult |
| boss_beefTax | Beef Tax (boss) | – | – | on_recipe_scored | -5$ mỗi món Beef Steak |

#### 4.5. Ghi chú cân bằng nhanh

- 8 món đã unlock có dải giá trị rất rộng (64–243): Super Disk áp đảo các món 2 lá.
- `meatt` và `beef_steak_master` gần trùng ý (cùng target món Beef Steak, khác +2 vs ×2).
- 3 item `goldtest*` là nội dung thử — cân nhắc loại khỏi kệ shop chính thức (mục 9).

---

## 5. UI/UX

> Theo quyết định D-07: ở giai đoạn này GDD **chỉ liệt kê màn hình cần có**,
> chưa spec layout chi tiết.

| Màn | Trạng thái | Cần có |
|---|---|---|
| Màn chơi (Match) | 🔧 khung logic xong, UI đồ hoạ chưa làm | Tay bài, nút Play/Discard (hiện đếm lượt), mục tiêu & điểm hiện tại, stage hiện tại, khu hiển thị hiệu ứng "đang nấu", kệ 5 item đang mang, banner boss, chỉ báo 3 pile (deck / draw / discard + số lá) |
| Màn Shop | 🔧 logic xong, UI đồ hoạ chưa làm | Hiển thị vàng, kệ 3 item (giá + nút mua + nút reroll với giá tăng dần), 3 nút gói (Công thức / Nguyên liệu / Xóa lá, mỗi gói 1 lần/stage), panel chọn 1/3 khi mở gói, nút sang stage tiếp theo |
| Màn kết stage (thắng) | 📋 chưa làm | Tổng kết điểm stage, tiền thưởng (base + lãi + item), hiệu ứng item after-match |
| Màn thua (Game Over) | 📋 chưa làm | Lý do thua, điểm/stage đã qua, nút chơi lại |
| Màn chủ động (Main Menu) | 📋 chưa làm | Bắt đầu run mới (hiện tự chạy `start_new_run` khi game mở) |

**Luật trạng thái UI:**
- Input chọn lá / bấm Play / Discard chỉ mở ở `MatchState.WAIT_FOR_INPUT`;
  các state khác (DRAWING, PROCESSING, GAME_OVER) khoá input — `MatchManager`
  đã chặn phía logic, UI cần tự disable theo state.
- Shop: bấm được "mua/reroll" chỉ ở state `BROWSING`; mở gói → state `DRAFTING_*`
  (chọn hoặc bỏ qua) rồi về `BROWSING`.

---

## 6. Trạng thái phát triển

### Đã xong ✅

- [x] Data layer: 3 autoload DB (Ingredient/Recipe/Item) tự nạp `.tres`
- [x] Nội dung khởi điểm: 8 ingredient, 13 recipe, 9 item + 3 boss
- [x] `DeckManager` (xáo/rút), `HandManager` (chọn/extract)
- [x] `ScoringSystem`: pipeline trigger, ghép món tự động, score×mult
- [x] `MatchManager`: vòng đời stage, thắng/thua, meta effect
- [x] `StageManager`: tiến stage, roll boss, target theo bảng
- [x] `ShopManager`: kệ item, reroll, 3 gói, xóa lá

### Đang làm 🚧

- [ ] UI đồ hoạ màn chơi & màn Shop (mục 5)
- [ ] Bàn luận cân bằng: bảng target 9 nhóm, gap Super Disk (mục 4.5)

### Chưa làm 📋

- [ ] Màn kết stage, Game Over, Main Menu
- [ ] Hiển thị chi tiết điểm (breakdown món/trigger) khi nấu
- [ ] Boss nội dung thêm (hiện chỉ đủ 3 con cho 9 stage)
- [ ] Hệ số target từ stage 28 (TBD — D-05)
- [ ] Asset art thật (hiện item/recipe dùng ảnh Apple Green giữ chỗ)
- [ ] Âm thanh

### Bug / nợ kỹ thuật 🐛

> Chỉ liệt kê, **chưa sửa** (theo D-08: lần này chỉ viết tài liệu).

1. `StageManager`: run vô hạn nhưng `base_target_score` chỉ 9 phần tử → **lỗi
   out-of-bounds từ stage 28**. Xử lý: hệ số nhân (D-05, TBD).
2. `StageManager`: `boss_pool` bị `erase` sau khi roll → hết 3 boss rồi
   `pick_random()` trên mảng rỗng. Xử lý theo D-03: boss không trùng cần thêm
   nội dung; trước mắt cần fallback (ví dụ roll lại từ đầu / random có trùng khi
   pool cạn — chưa chốt).
3. `ShopManager.buy_item()`: **không kiểm tra `max_active_items = 5`** → mua vô hạn
   (vi phạm D-04).
4. `RiceAccumulator.gd`: định nghĩa `_on_play` (có gạch đầu dòng) → **không bao giờ
   được gọi**; hook đúng phải là `on_play` (hook `on_play` hiện đã nối vào pipeline
   của `ScoringSystem` — chỉ cần sửa tên hàm trong item).
5. (Đã khắc phục — `ScoringSystem._trigger_on_play` hiện có push trigger
   `on_play` vào pipeline; giữ lại ở đây để tránh nhầm khi đọc bản cũ)
6. `RecipeDB.get_ingredient_by_id` không liên quan, nhưng
   `IngredientDB.get_ingredient_by_id(id)` trả về default `1` (int) thay vì `null`
   → nhánh "không tìm thấy" không bao giờ chạy đúng, và fallback trỏ tới
   `test.tres` không tồn tại.
7. `RecipeDB.select_recipe_choice`: truy cập `recipes[chosen_id]` trực tiếp → crash
   nếu id lạ (thay bằng `get()`).
8. `DeckManager.discard_pile` khai báo nhưng chưa dùng; lá bỏ hiện "mất" (vô tình
   đúng luật D-02 vì stage sau xáo lại bộ bài gốc) — cần làm cho đúng tên gọi:
   lá bỏ vào discard pile, pile reset mỗi stage.
9. `RecipeData.min_ingredient/max_ingredient`: khai báo, chưa dùng trong matching.
10. `ItemData.price`: khai báo (mọi item = 5) nhưng Shop tự nhận giá từ UI —
    chưa có nơi nào đọc `price` để định giá.
11. `meatt` / `beef_steak_master` trùng ý; 3 item `goldtest*` là nội dung thử.
12. `control.gd` / `control.tscn` ở root: bản viết tay lặp lại logic
    MatchManager, dễ nhầm — cân nhắc xoá hoặc dùng làm playground riêng.
13. `old_code/ScoringSystem_old.gd`: bản cũ hơn bị comment hết, giữ làm tham khảo.
14. Đề xuất: thêm `tools/dump_content.gd` sinh bảng mục 4.4 tự động để không lệch.

---

## 7. Đường cong độ khó

> Chi tiết số: `BALANCE.md`. Mục này chỉ ghi nguyên tắc.

| Stage (nhóm) | Target nhóm | Lượt Play | Ghi chú |
|---|---|---|---|
| 1–3 (boss ở 3) | 1 × [1.5, 2.0, 1.0] | 4 (boss -1) | dạy cơ bản; mục tiêu gần như cho |
| 4–6 (boss ở 6) | 300 × [1.5, 2.0, 1.0] | 4 | bước nhảy lớn đầu tiên |
| 7–9 (boss ở 9) | 800 | 4 | |
| 10–12 | 2000 | 4 | cần item / nâng cấp món |
| 13–15 | 5000 | 4 | |
| 16–18 | 1100 ⚠️ | 4 | thấp hơn nhóm trước — xem câu hỏi 9 |
| 19–21 | 20000 | 4 | |
| 22–24 | 35000 | 4 | |
| 25–27 | 50000 | 4 | |
| 28+ | TBD (hệ số nhân) | 4 | D-05 |

**Công thức (code hiện tại):** `target = base_target_score[(stage-1)/3] ×
base_mult[(stage-1)%3]` (chỉ số mảng thực tế trong code là `stage/3` — khác nhau
1 ô, cần chốt; xem câu hỏi 9).

**Nguồn tăng trưởng của người chơi:** item (kệ shop), nâng cấp công thức
(gói công thức), thêm nguyên liệu (gói nguyên liệu), xoá lá rác, lãi suất vàng.

---

## 8. Glossary

| Thuật ngữ | Nghĩa |
|---|---|
| Lá / Thẻ (card) | Một bản của Ingredient trong bộ bài (Instance) |
| Nguyên liệu (ingredient) | Loại lá (Beef, Rice, …) — `IngredientData` |
| Bộ bài (deck) | Toàn bộ lá sở hữu của người chơi — `GameManager.player_deck` |
| Tay bài (hand) | Lá đang trên tay (tối đa 7) |
| Nấu / Play | Chọn ≤5 lá đánh ra, hệ thống ghép món và cộng điểm |
| Món (recipe / dish) | Công thức nguyên liệu; "dish" = một lần món được nấu ra trong lượt |
| Pipeline | Danh sách trigger (góp điểm) của một dish |
| Trigger | Một kết quả góp điểm: `score`, `mult`, `x_mult`, meta effect |
| Item (Joker) | Thẻ trợ giúp; kích hoạt qua hook, tối đa 5 |
| Hook | Scoring: `on_play / on_ingredient_scored / on_recipe_scored`; lifecycle: `on_stage_start / after_match / on_discard` (xem 3.4) |
| Meta effect | Effect không phải điểm món: `add_money`, `add_plays`, `add_discards`, `max_interest_gold` |
| Boss | Item đặc biệt (is_boss) chỉ kích hoạt trong stage boss |
| Stage / Màn | Một vòng "cooking" có mục tiêu điểm + 4 lượt play; giữa các stage là Shop |
| Run | Cả trận chơi (vô hạn stage), bắt đầu bằng bộ bài + 100 vàng |
| Gói (pack) | Cơ chế Shop 1-lần/stage: Công thức / Nguyên liệu / Xóa lá |
| Reroll | Xay lại 3 ô item ở kệ, giá tăng dần mỗi lần |

---

## 9. Câu hỏi đang treo

> Khi chốt → chuyển vào `DECISIONS.md` và xoá khỏi đây.

- [ ] **Hệ số target từ stage 28** (D-05: "có hệ số, giá trị TBD"). Đề xuất ban đầu:
      nhân ×1.5 cho mỗi nhóm mới; hoặc dùng công thức khác?
- [ ] **Chỉ số mảng trong `get_current_target_score`** (GDD §7): code dùng
      `stage/3` (integer div) → stage 1 lấy ô 0; GDD ghi `[(stage-1)/3]` để
      nhóm 1 bắt đầu đúng stage 1. Hai cách lệch nhau 1 ô — chốt cách nào?
      (Hiện tại: stage 1–3 dùng nhóm 0, đúng như tính trong bảng §7.)
- [ ] **Nhóm 16–18 (base 1100) thấp hơn nhóm 13–15 (base 5000)** — cố ý (dễ thở
      sau giai đoạn khó) hay nhập liệu sai?
- [ ] Xử lý khi **boss pool cạn** (chỉ 3 con, run vô hạn): thêm nội dung boss mới
      (chốt: cần thêm) — trước khi có, fallback: random có trùng hay vòng lại?
- [ ] Ba item `goldtest1/2/3`: xoá khỏi kệ shop, hay đổi tên/thuộc item thật?
- [x] Hook `on_play` (Rice Accumulator đang chờ nó): **đã kết nối vào pipeline**
      (ScoringSystem._trigger_on_play, trigger nằm đầu pipeline mỗi lượt Play).
      Việc còn lại chỉ là sửa tên hàm `_on_play` → `on_play` trong RiceAccumulator.gd (mục 6.4).
- [ ] Giá item: hiện "mọi item = 5" nhưng `ItemData.price` chưa ai đọc — chốt:
      giá theo rarity hay theo từng item?

---

## Ghi chú bổ sung

- `old_code/ScoringSystem_old.gd`: tham khảo cách thiết kế pipeline thế hệ trước
  (signal, breakdown) khi làm UI hiển thị chi tiết điểm.
- `control.gd`/`control.tscn`: bản test viết tay, không phải dòng chính (dòng chính
  là `MatchManager` scene — xem project setting main scene).
