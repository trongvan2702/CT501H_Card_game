# BALANCE.md — Số cân bằng

> Tài liệu phụ của `GDD.md`. Ở đây chỉ chứa **con số**; luật chơi giải thích ở GDD.
> Khi đổi số trong code (`StageManager`, `ItemDB`, `ShopManager`, các `.tres`),
> cập nhật lại file này.

Cập nhật gần nhất: 2026-07-07

---

## 1. Target score theo stage

**Công thức (code):** `StageManager.get_current_target_score()`

```
target = base_target_score[stage / 3] × base_mult[stage % 3]
        (chia nguyên, index mảng 0-based)
```

`base_mult = [1.0, 1.5, 2.0]` → trong 3 stage của một nhóm, stage giữa nhóm nhân 1.5,
stage cuối nhóm nhân 2.0.

### 1.1. Bảng target đầy đủ

| Stage | Nhóm (`stage/3`) | Hệ số (`stage%3`) | Target |
|---|---|---|---|
| 1 | 0 | 1.0 | **1** |
| 2 | 0 | 1.5 | **1.5** |
| 3 | 0 | 2.0 | **2** (boss) |
| 4 | 1 | 1.0 | **300** |
| 5 | 1 | 1.5 | **450** |
| 6 | 1 | 2.0 | **600** (boss) |
| 7 | 2 | 1.0 | **800** |
| 8 | 2 | 1.5 | **1200** |
| 9 | 2 | 2.0 | **1600** (boss) |
| 10 | 3 | 1.0 | **2000** |
| 11 | 3 | 1.5 | **3000** |
| 12 | 3 | 2.0 | **4000** (boss) |
| 13 | 4 | 1.0 | **5000** |
| 14 | 4 | 1.5 | **7500** |
| 15 | 4 | 2.0 | **10000** (boss) |
| 16 | 5 | 1.0 | **1100** ⚠️ |
| 17 | 5 | 1.5 | **1650** |
| 18 | 5 | 2.0 | **2200** (boss) |
| 19 | 6 | 1.0 | **20000** |
| 20 | 6 | 1.5 | **30000** |
| 21 | 6 | 2.0 | **40000** (boss) |
| 22 | 7 | 1.0 | **35000** ⚠️ |
| 23 | 7 | 1.5 | **52500** |
| 24 | 7 | 2.0 | **70000** (boss) |
| 25 | 8 | 1.0 | **50000** ⚠️ |
| 26 | 8 | 1.5 | **75000** |
| 27 | 8 | 2.0 | **100000** (boss) |

⚠️ = nhóm có base **thấp hơn** nhóm trước (16–18 < 13–15; 22–24 < 19–21; 25–27 < 22–24).
Nghi vấn nhập liệu — xem GDD §9.

### 1.2. Stage 28 trở đi

`base_target_score` chỉ có 9 phần tử → code sẽ lỗi out-of-bounds từ stage 28.
Quyết định D-05: **nhân thêm hệ số** — giá trị hệ số **TBD**.

| Dự kiến | Giá trị |
|---|---|
| Hệ số mỗi nhóm mới (stage 28, 31, 34…) | TBD — đề xuất ×1.5 |
| Công thức dự kiến | `target = base_target_score[giá trị nhóm đã mở rộng] × base_mult[...]` |

Cần chốt: bảng target có nên tiếp tục tăng tuyến tính, hay nhân dần theo nhóm?

### 1.3. Ước lượng điểm mỗi lượt chơi (để hiệu chỉnh)

Điểm 1 lượt = `(Σ score pipeline) × final_mult` (một `final_mult` chung, xem §4.1) —
không cộng dồn "giá trị món" riêng cho từng món như bảng 5.1.

Tay 5 lá, dùng món đã unlock sẵn, **không item**:

| Tình huống | Pipeline: Σ score / Σ mult (gồm base 1.0) | Điểm |
|---|---|---|
| 5 lá → 1 món Super Disk + 1 lá rác | (55+80)=135 × (1+0.8)=1.8 | 243 |
| 5 lá → 2 món Salted Rice (rice+salt, rice+salt) | (16+16)+(12+12)=56 × (1+1.0+1.0)=3.0 | 432 |
| 5 lá → 1 món Grilled Chicken + 3 lá rác | (22+20+12)=54 × (1+0.5)=1.5 | 81 |

→ Nếu không có item, điểm/lượt ≈ **80–430** (cao hơn ước tính cũ vì 2 món cộng mult
cộng dồn). 4 lượt/stage: **320–1700 / stage** (trước item). Từ stage 19 (20000) trở đi
**không thể đạt được nếu không có item/nâng cấp** — khoảng cách còn lớn hơn trước.

---

## 2. Bộ bài & tay bài

| Thông số | Giá trị | Nguồn |
|---|---|---|
| Bộ bài khởi đầu | 8 loại × 5 = 40 lá | `GameManager._build_starter_deck()` |
| Tay bài tối đa | 7 | `MatchManager.max_hand_size` |
| Chọn tối đa mỗi lượt | 5 | `HandManager.max_select` |
| Lượt Play / stage | 4 | `MatchManager.start_new_stage()` |
| Lượt Discard / stage | 3 | `MatchManager.start_new_stage()` |
| Rút bù sau mỗi lượt | tối đa 5 lá | `MatchManager.draw_cards_to_full()` |
| Lá bỏ | vào discard pile, **không dùng lại trong stage** | D-02 |

**Ghi chú thiết kế:** bộ bài 40 lá, tay 7, chọn 5 → xoay bộ bài 40 lá sau ~8 lượt.
Với 4 lượt/stage thì bộ bài hầu như không bao giờ cạn trong một stage → discard pile
chủ yếu có tác dụng "giảm số lá rác" chứ ít ảnh hưởng cân bằng.

---

## 3. Kinh tế

| Mục | Giá trị | Nguồn |
|---|---|---|
| Vàng khởi đầu | 100 | `GameManager.start_new_run()` |
| Thưởng thắng stage (base) | 5 | `MatchManager._win_stage()` |
| Lãi suất | `vàng ÷ 5` (làm tròn xuống) | `MatchManager._win_stage()` |
| Trần lãi | 5 (tăng bằng effect `max_interest_gold`) | `MatchManager.max_interest_gold` |

### 3.1. Bảng giá Shop

| Dịch vụ | Giá | Số lần / stage | Ghi chú |
|---|---|---|---|
| Item (kệ 3 ô) | 5 (mọi item hiện tại) | không giới hạn theo số lần, nhưng tối đa **5 item trang bị** | D-04 |
| Reroll kệ item | 5, +1 mỗi lần reroll | không giới hạn | `ShopManager.reroll_cost` |
| Gói Công thức | 5 | 1 | chọn 1/3 → mở khóa hoặc +1 cấp |
| Gói Nguyên liệu | 5 | 1 | chọn 1/3 lá → thêm vào bộ bài |
| Xóa lá | 5 | 1 | bộ bài phải > 3 lá |

### 3.2. Rarity & trọng số rơi

| Rarity | Giá trị | Trọng số | Xác suất (nếu chỉ có 1 rarity trong pool) |
|---|---|---|---|
| 1 — Common | 5 | 80 | 80% |
| 2 — Uncommon | (chưa định) | 15 | 15% |
| 3 — Rare | (chưa định) | 3 | 3% |
| 4 — Legendary | (chưa định) | 2 | 2% |

Nguồn: `ItemDB._get_rarity_weight()`.
**Hiện tại mọi item đều rarity 1** → kệ shop luôn ra item thường, không có biến thiên.
Cần thêm item rarity 2–4 để cơ chế này có ý nghĩa.

---

## 4. Công thức

### 4.1. Điểm lượt Play (pipeline chung)

Một lượt Play tính **một lần duy nhất** trên toàn bộ pipeline, không nhân riêng từng món:

```
Điểm lượt = ( Σ score mọi trigger ) × final_mult
final_mult = 1.0
  trigger x_mult = false → final_mult += trigger.mult
  trigger x_mult = true  → final_mult *= trigger.mult
```

Trigger trong pipeline gồm: `on_play` (đầu pipeline) → mỗi nguyên liệu được dùng
(score của lá) + item `on_ingredient_scored` → mỗi món (recipe score/mult) +
item `on_recipe_scored`.

**Hệ quả quan trọng:** nấu **nhiều món trong 1 lượt** làm các `mult` additive
cộng dồn lên cùng một `final_mult` → 2 món cùng lúc giá trị **cao hơn** tổng
giá trị đơn lẻ của 2 món (xem §1.3).

### 4.2. Cấp công thức (upgrade)

```
score món = base_score + (cấp - 1) × bonus_score_per_level
mult món  = base_mult  + (cấp - 1) × bonus_mult_per_level
```

Giá trị `bonus_*` hiện tại: xem bảng GDD §4.4.2 / các file `resources/recipes/*.tres`.

**Tỉ lệ tăng theo cấp (mẫu):**

| Món | lv1 | lv2 | +1 cấp tăng |
|---|---|---|---|
| Super Disk | (55 + Σ nguyên liệu 80) × 1.8 = 243 | (55+30 + 80) × 2.0 = 330 | +87 (+36%) |
| Salted Rice | (16 + 24) × 2.0 = 80 | (31 + 24) × 2.1 = 115.5 | +35.5 (+44%) |
| Beef Steak | (25 + 38) × 1.5 = 94.5 | (40 + 38) × 1.6 = 124.8 | +30 (+32%) |

→ Nâng cấp món 2 lá tăng ~35–45% giá trị, món 4 lá tăng ~36%. **Không đồng đều theo
số nguyên liệu** — nếu muốn công bằng, chuẩn hoá `bonus_score_per_level` theo
số nguyên liệu (xem GDD §9 / câu hỏi về balance).

### 4.3. Giá trị nguyên liệu

| Ingredient | base_score |
|---|---|
| Beef | 30 |
| Chicken | 20 |
| Egg | 20 |
| Cabbage | 18 |
| Tomato | 15 |
| Rice | 12 |
| Salt | 12 |
| Pepper | 8 |

---

## 5. Bảng nội dung đầy đủ (tham chiếu nhanh)

### 5.1. Recipe

| id | Nguyên liệu | base_score | base_mult | bonus_score | bonus_mult | Giá trị lv1 | Unlock |
|---|---|---|---|---|---|---|---|
| salted_rice | rice+salt | 16 | 1.0 | 15 | 0.1 | 80 | ✅ |
| salt_pepper | salt+pepper | 20 | 1.0 | 15 | 0.1 | 80 | ✅ |
| kimchi | cabbage+pepper | 20 | 0.4 | 15 | 0.1 | 64.4 | ✅ |
| fresh_salad | tomato+cabbage | 20 | 0.4 | 15 | 0.1 | 74.2 | ✅ |
| grilled_chicken | chicken+salt | 22 | 0.5 | 15 | 0.1 | 81 | ✅ |
| beef_steak | beef+pepper | 25 | 0.5 | 15 | 0.1 | 94.5 | ✅ |
| omelette | egg+egg | 25 | 0.5 | 15 | 0.1 | 97.5 | ✅ |
| chicken_pepper | chicken+pepper | 30 | 0.8 | 15 | 0.1 | 104.4 | 🔒 |
| chicken_fried_rice | chicken+pepper+salt | 35 | 0.6 | 20 | 0.2 | 120 | 🔒 |
| beef_stew | beef+tomato+salt | 40 | 0.7 | 20 | 0.1 | 164.9 | 🔒 |
| garden_salad | tomato+beef+chicken+salt | 55 | 0.8 | 25 | 0.3 | 237.6 | 🔒 |
| super_disk | beef+chicken+cabbage+rice | 55 | 0.8 | 30 | 0.2 | 243 | ✅ |
| meat_meat | beef+chicken | 75 | 0.5 | 10 | 0.1 | 187.5 | 🔒 |

### 5.2. Item

| id | Rarity | Giá | Hook | Hiệu ứng |
|---|---|---|---|---|
| beef_lover | 1 | 5 | on_ingredient_scored | +8 score / lá Beef |
| beef_steak_master | 1 | 5 | on_recipe_scored | ×2 mult / món Beef Steak |
| meatt | 1 | 5 | on_recipe_scored | +2 mult / món Beef Steak |
| fork | 1 | 5 | on_stage_start | +1 Discard |
| spoon | 1 | 5 | on_stage_start | +1 Play |
| rice_accumlator | 1 | 5 | on_play *(chưa nối)* | +8.8 mult nếu ≥3 lá Rice trong lượt |
| goldtest1 | 1 | 5 | on_ingredient_scored | +1$ / lá Beef *(test)* |
| goldtest2 | 1 | 5 | on_recipe_scored | +3$ / món Beef Steak *(test)* |
| goldtest3 | 1 | 5 | after_match | +3$ / stage *(test)* |
| boss_fatigue | – | – | on_stage_start | −1 Play |
| boss_vegetarian | – | – | on_ingredient_scored | Beef/Chicken ×0 mult |
| boss_beefTax | – | – | on_recipe_scored | −5$ / món Beef Steak |

---

## 6. Số cần hiệu chỉnh (theo thứ tự ưu tiên)

1. **Bảng target stage 1–3 = 1–2 điểm** → không có ý nghĩa. Cần số thật.
2. **Nhóm 16–18 (1100) < nhóm 13–15 (5000)** → nghịch đường cong độ khó.
3. **Target stage 19+ (20000)** không đạt được với 4 lượt × ~250 điểm → cần item/nâng cấp,
   nhưng shop chỉ có 5 vàng/lần và item thường giá 5 → tăng trưởng quá chậm so với target.
4. **Hệ số stage 28+** — TBD (D-05).
5. **Mọi item đều price 5, rarity 1** → kệ shop không có biến thiên, không có "quyết định mua".
6. **Giá trị món lệch mạnh** (64–243) → 3–4 món 2 lá đã hấp dẫn hơn mọi món 3–4 lá.
7. **Nâng cấp công thức không đồng đều** theo số nguyên liệu (+32% vs +44%).
