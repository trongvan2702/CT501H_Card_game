## ============================================
## ScoringSystem.gd
## Hệ thống tính điểm với Trigger System
## ============================================
## Flow:
## 1. on_play(cards) - Khi cards được đánh vào cooking area
## 2. on_ingredient_scored(ingredient) - Mỗi ingredient được tính điểm
## 3. on_recipe_scored(recipe) - Khi recipe được xác nhận
## 4. Kết thúc - Apply total effects
## ============================================
#
#extends Node
#
## ============================================
## SIGNALS
## ============================================
#
#signal score_calculated(final_score: int, dishes: Array, breakdown: Dictionary)
#signal score_added(amount: int, total_score: int)
#signal dish_scored(dish_name: String, score: int, effects: Array)
#signal trigger_fired(item_name: String, trigger_type: String, result: Dictionary)
#
## ============================================
## CONSTANTS
## ============================================
#
#const BASE_INGREDIENT_SCORE: int = 10
#const PER_INGREDIENT_BONUS: int = 5
#
## ============================================
## PROPERTIES
## ============================================
#
#var recipe_system: Node = null
#var equipped_items: Array = []  # Array[ItemInstance]
#
## Buffers cho current calculation
#var _current_played_cards: Array = []
#var _accumulated_results: Array = []  # Lưu TriggerResults
#var _meta_effects: Dictionary = {}  # Lưu meta effects
#
## ============================================
## LIFECYCLE
## ============================================
#
#func _ready() -> void:
	#print("ScoringSystem: Initialized with Trigger System")
	#recipe_system = get_parent().get_node_or_null("RecipeSystem")
#
## ============================================
## PUBLIC API
## ============================================
#
#func set_equipped_items(items: Array) -> void:
	#equipped_items = items
	#print("ScoringSystem: Equipped ", items.size(), " items")
	#for item in items:
		#print("  - ", item.get_display_name())
#
#func get_equipped_items() -> Array:
	#return equipped_items
#
## ============================================
## MAIN SCORING FUNCTION
## ============================================
#
#func calculate_dish_score(ingredients: Array) -> Dictionary:
	## Reset buffers
	#_reset_buffers()
#
	## Lưu cards đã đánh
	#_current_played_cards = ingredients.duplicate()
#
	## STEP 1: on_play()
	#_trigger_on_play(ingredients)
#
	## STEP 2: Tạo dishes và tính điểm
	#var dishes = _create_dishes_from_ingredients(ingredients)
#
	## STEP 3: Tính total
	#var total_score = _calculate_total(dishes)
	#var breakdown = _create_breakdown(dishes)
#
	#var result = {
		#"total_score": total_score,
		#"dishes": dishes,
		#"breakdown": breakdown,
		#"meta_effects": _meta_effects.duplicate()
	#}
#
	#emit_signal("score_calculated", total_score, dishes, breakdown)
#
	#return result
#
## ============================================
## TRIGGER METHODS
## ============================================
#
#func _reset_buffers() -> void:
	#_current_played_cards.clear()
	#_accumulated_results.clear()
	#_meta_effects = {
		#"extra_cook": 0,
		#"extra_discard": 0,
		#"extra_hand_size": 0,
		#"extra_currency": 0,
		#"free_reroll": false,
		#"trigger_logs": []
	#}
#
#func _trigger_on_play(cards: Array) -> void:
	#for item in equipped_items:
		#if not item.is_active:
			#continue
#
		#if item.has_method("on_play"):
			#var result = item.on_play(cards)
			#if result != null and result.triggered and result.has_effects():
				#_accumulated_results.append(result)
				#_apply_meta_effects(result)
				#_log_trigger(item.get_display_name(), "on_play", result)
#
#func _trigger_on_ingredient_scored(ingredient: IngredientData) -> TriggerResult:
	#var combined = TriggerResult.new()
#
	#for item in equipped_items:
		#if not item.is_active:
			#continue
#
		#if item.has_method("on_ingredient_scored"):
			#var result = item.on_ingredient_scored(ingredient)
			#if result != null and result.triggered:
				#combined = combined.combine(result)
				#_log_trigger(item.get_display_name(), "on_ingredient_scored", result)
#
	#return combined
#
#func _trigger_on_recipe_scored(recipe: RecipeData, base_score: int) -> TriggerResult:
	#var combined = TriggerResult.new()
#
	#for item in equipped_items:
		#if not item.is_active:
			#continue
#
		#if item.has_method("on_recipe_scored"):
			#var result = item.on_recipe_scored(recipe, base_score)
			#if result != null and result.triggered:
				#combined = combined.combine(result)
				#_log_trigger(item.get_display_name(), "on_recipe_scored", result)
#
	#return combined
#
#func _log_trigger(item_name: String, trigger_type: String, result: TriggerResult) -> void:
	#_meta_effects["trigger_logs"].append({
		#"item": item_name,
		#"trigger": trigger_type,
		#"text": result.text
	#})
	#emit_signal("trigger_fired", item_name, trigger_type, {
		#"score": result.score,
		#"mult": result.mult,
		#"text": result.text
	#})
#
#func _apply_meta_effects(result: TriggerResult) -> void:
	#_meta_effects["extra_cook"] += result.extra_cook
	#_meta_effects["extra_discard"] += result.extra_discard
	#_meta_effects["extra_hand_size"] += result.extra_hand_size
	#_meta_effects["extra_currency"] += result.extra_currency
	#if result.free_reroll:
		#_meta_effects["free_reroll"] = true
#
## ============================================
## DISH CREATION
## ============================================
#
#func _create_dishes_from_ingredients(ingredients: Array) -> Array:
	#var result: Array = []
	#var remaining = ingredients.duplicate()
#
	#var visible_recipes = RecipeDB.get_visible_recipes()
	#visible_recipes.sort_custom(func(a, b):
		#return b.base_multiplier > a.base_multiplier
	#)
#
	#var iterations = 0
	#var max_iterations = remaining.size() * 2
#
	#while not remaining.is_empty() and iterations < max_iterations:
		#iterations += 1
#
		#var best_match = _find_best_recipe_for_ingredients(remaining, visible_recipes)
#
		#if best_match.is_empty():
			#break
#
		#var recipe = best_match.get("recipe")
		#var used_ingredients = best_match.get("used_ingredients", [])
#
		#if recipe == null or used_ingredients.is_empty():
			#break
#
		#var dish = _create_dish_from_recipe(recipe, used_ingredients)
		#result.append(dish)
#
		#for ing in used_ingredients:
			#remaining.erase(ing)
#
	#if not remaining.is_empty():
		#var leftover_dish = _create_dish_from_ingredients(remaining)
		#result.append(leftover_dish)
#
	#return result
#
#func _find_best_recipe_for_ingredients(available: Array, recipes: Array) -> Dictionary:
	#var best_match: Dictionary = {}
	#var best_score = 0
#
	#for recipe in recipes:
		#var available_copy = available.duplicate()
		#var matched_ids = _try_match_recipe(recipe, available_copy)
#
		#if not matched_ids.is_empty():
			#var potential_score = _estimate_dish_score(recipe, matched_ids.size())
#
			#if potential_score > best_score:
				#best_score = potential_score
				#best_match = {
					#"recipe": recipe,
					#"used_ingredients": _extract_ingredients_by_id(recipe.required_ingredients, available)
				#}
#
	#return best_match
#
#func _try_match_recipe(recipe: RecipeData, available: Array) -> Array:
	#var required = recipe.required_ingredients.duplicate()
	#var matched_ids: Array = []
#
	#var available_count: Dictionary = {}
	#for ing in available:
		#var id = ing.ingredient_id
		#if not available_count.has(id):
			#available_count[id] = 0
		#available_count[id] += 1
#
	#for req_id in required:
		#if available_count.has(req_id) and available_count[req_id] > 0:
			#matched_ids.append(req_id)
			#available_count[req_id] -= 1
		#else:
			#return []
#
	#return matched_ids
#
#func _extract_ingredients_by_id(required_ids: Array, available: Array) -> Array:
	#var result: Array = []
	#var used_indices: Array = []
#
	#for req_id in required_ids:
		#for i in range(available.size()):
			#if i not in used_indices and available[i].ingredient_id == req_id:
				#result.append(available[i])
				#used_indices.append(i)
				#break
#
	#return result
#
#func _estimate_dish_score(recipe: RecipeData, ingredient_count: int) -> int:
	#var score = recipe.base_score
	#var extra = ingredient_count - recipe.get_required_count()
	#if extra > 0:
		#score += extra * recipe.bonus_per_extra_ingredient
	#return int(score * recipe.base_multiplier)
#
## ============================================
## DISH CREATION
## ============================================
#
#func _create_dish_from_recipe(recipe: RecipeData, ingredients: Array) -> Dictionary:
	#var base_score = recipe.base_score
	#var extra = ingredients.size() - recipe.get_required_count()
	#if extra > 0:
		#base_score += extra * recipe.bonus_per_extra_ingredient
#
	## on_ingredient_scored() cho từng ingredient
	#var ingredient_bonus = 0
	#var effects_list: Array = []
#
	#for ing in ingredients:
		#var result = _trigger_on_ingredient_scored(ing)
		#if result.triggered and result.score != 0:
			#ingredient_bonus += result.score
			#if result.text != "":
				#effects_list.append({"item": ing.display_name, "text": result.text})
#
	#var subtotal = base_score + ingredient_bonus
#
	## on_recipe_scored()
	#var recipe_result = _trigger_on_recipe_scored(recipe, base_score)
#
	#if recipe_result.triggered and recipe_result.text != "":
		#effects_list.append({"item": "Recipe", "text": recipe_result.text})
#
	## KHÔNG nhân mult ở đây - sẽ tính tổng ở cuối
	#return {
		#"recipe": recipe,
		#"ingredients": ingredients,
		#"base_score": base_score,
		#"ingredient_bonus": ingredient_bonus,
		#"recipe_bonus": recipe_result.score,
		#"subtotal": subtotal,
		#"recipe_result": recipe_result,
		#"recipe_mult": recipe.base_multiplier,
		#"dish_name": recipe.display_name,
		#"is_recipe": true,
		#"effects": effects_list
	#}
#
#func _create_dish_from_ingredients(ingredients: Array) -> Dictionary:
	#var base_score = ingredients.size() * BASE_INGREDIENT_SCORE
	#var extra_bonus = max(0, ingredients.size() - 2) * PER_INGREDIENT_BONUS
	#base_score += extra_bonus
#
	#var ingredient_bonus = 0
	#var effects_list: Array = []
#
	#for ing in ingredients:
		#var result = _trigger_on_ingredient_scored(ing)
		#if result.triggered and result.score != 0:
			#ingredient_bonus += result.score
			#if result.text != "":
				#effects_list.append({"item": ing.display_name, "text": result.text})
#
	#var subtotal = base_score + ingredient_bonus
#
	#var ingredient_names: Array = []
	#for ing in ingredients:
		#ingredient_names.append(ing.display_name)
#
	## KHÔNG nhân mult ở đây - sẽ tính tổng ở cuối
	#return {
		#"recipe": null,
		#"ingredients": ingredients,
		#"base_score": base_score,
		#"ingredient_bonus": ingredient_bonus,
		#"recipe_bonus": 0,
		#"subtotal": subtotal,
		#"recipe_result": null,
		#"recipe_mult": 1.0,
		#"dish_name": " + ".join(ingredient_names),
		#"is_recipe": false,
		#"effects": effects_list
	#}
#
## ============================================
## SCORE CALCULATION (Old methods - kept for reference)
## ============================================
#
#func _get_effective_mult(recipe_result: TriggerResult, recipe: RecipeData = null) -> float:
	#var mult = 1.0
	#if recipe:
		#mult *= recipe.base_multiplier
	#mult += recipe_result.mult
	#for result in _accumulated_results:
		#mult += result.mult
	#return mult
#
#func _triggerresult_to_dict(result: TriggerResult) -> Dictionary:
	#return {
		#"score": result.score,
		#"mult": result.mult,
		#"set_mult": result.set_mult,
		#"mult_score": result.mult_score,
		#"text": result.text
	#}
#
#func _calculate_total(dishes: Array) -> float:
	## ════════════════════════════════════════════════════════════
	## CÔNG THỨC MỚI:
	## Total Score = Tổng(subtotal + recipe_bonus) × Tổng Mult
	## Trong đó:
	##   - Recipe mult = recipe.base_mult - 1 (VD: 1.3 → 0.3)
	##   - Non-recipe (leftover) mult = 0
	## ════════════════════════════════════════════════════════════
#
	#var total_subtotal: float = 0.0
	#var total_mult: float = 1.0
#
	#for dish in dishes:
		## Cộng dồn subtotal + recipe_bonus
		#total_subtotal += dish["subtotal"] + dish["recipe_bonus"]
#
		## Tính mult:
		## - Recipe: recipe.base_mult - 1
		## - Non-recipe: 0
		#var recipe_mult = dish["recipe_mult"]
		#if dish["is_recipe"]:
			#total_mult += (recipe_mult - 1.0)  # 1.3 → 0.3
		#else:
			#total_mult += 0.0  # Non-recipe = 0
#
	## Cộng thêm mult từ on_play triggers
	#for result in _accumulated_results:
		#total_mult += result.mult
		#if result.set_mult >= 0:
			#total_mult = result.set_mult - 1.0  # Giảm 1 để giữ base = 1
		#if result.mult_score:
			#total_mult *= result.mult
#
	## Đảm bảo mult không âm
	#if total_mult < 0:
		#total_mult = 0
#
	## Tính điểm cuối
	#var final_score = total_subtotal * total_mult
#
	## Gán final_score và mult cho từng dish (để hiển thị)
	#for dish in dishes:
		#dish["multiplier"] = total_mult
		#dish["final_score"] = final_score
		#emit_signal("dish_scored", dish["dish_name"], final_score, dish["effects"])
#
	#return final_score
#
#func _create_breakdown(dishes: Array) -> Dictionary:
	#var from_recipes = 0
	#var from_mixed = 0
	#var recipe_count = 0
	#var trigger_logs: Array = _meta_effects.get("trigger_logs", []).duplicate()
#
	#for dish in dishes:
		#if dish["is_recipe"]:
			#from_recipes += dish["final_score"]
			#recipe_count += 1
		#else:
			#from_mixed += dish["final_score"]
#
	#return {
		#"from_recipes": from_recipes,
		#"from_mixed": from_mixed,
		#"dish_count": dishes.size(),
		#"recipe_count": recipe_count,
		#"trigger_logs": trigger_logs,
		#"meta_effects": _meta_effects.duplicate()
	#}
#
## ============================================
## UTILITY
## ============================================
#
#func get_score_preview(ingredients: Array) -> Dictionary:
	#return calculate_dish_score(ingredients)
#
#func add_score_to_game(amount: int) -> void:
	#if has_node("/root/GameManager"):
		#GameManager.add_score(amount)
		#emit_signal("score_added", amount, GameManager.current_score)
#
## ============================================
## STAGE LIFECYCLE
## ============================================
#
#func on_stage_start() -> void:
	#print("ScoringSystem: Stage starting...")
	#_reset_buffers()
#
	#for item in equipped_items:
		#if not item.is_active:
			#continue
#
		#if item.has_method("on_stage_start"):
			#var result = item.on_stage_start()
			#if result != null and result.triggered and result.has_effects():
				#_apply_meta_effects(result)
				#print("  ", item.get_display_name(), ": ", result.text)
#
#func after_match() -> void:
	#print("ScoringSystem: Match ending...")
#
	#for item in equipped_items:
		#if not item.is_active:
			#continue
#
		#if item.has_method("after_match"):
			#item.after_match()
#
#func get_meta_effects() -> Dictionary:
	#return _meta_effects.duplicate()
#
## ============================================
## DEBUG
## ============================================
#
#func debug_print_dishes(dishes: Array) -> void:
	#print("=== DISHES BREAKDOWN ===")
#
	#for i in range(dishes.size()):
		#var dish = dishes[i]
		#var prefix = "[RECIPE]" if dish["is_recipe"] else "[MIXED]"
#
		#print("%s Dish %d: %s" % [prefix, i + 1, dish["dish_name"]])
		#print("   Base: %d" % dish["base_score"])
#
		#if dish["ingredient_bonus"] > 0:
			#print("   Ingredient Bonus: +%d" % dish["ingredient_bonus"])
#
		#if dish["recipe_bonus"] > 0:
			#print("   Recipe Bonus: +%d" % dish["recipe_bonus"])
#
		#print("   Multiplier: x%.2f" % dish["multiplier"])
		#print("   Final: %d" % dish["final_score"])
#
		#if dish["effects"].size() > 0:
			#print("   Effects:")
			#for effect in dish["effects"]:
				#print("     - ", effect.get("text", ""))
#
	#var total = 0
	#for dish in dishes:
		#total += dish["final_score"]
	#print("TOTAL: %d" % total)


# ============================================
# ScoringSystem.gd
# Hệ thống tính điểm với Trigger System
# ============================================
# Flow:
# 1. on_play(cards) - Khi cards được đánh vào cooking area
# 2. on_ingredient_scored(ingredient) - Mỗi ingredient được tính điểm
# 3. on_recipe_scored(recipe) - Khi recipe được xác nhận
# 4. Kết thúc - Apply total effects
# ============================================

extends Node

# ============================================
# SIGNALS
# ============================================

signal score_calculated(final_score: int, dishes: Array, breakdown: Dictionary)
signal score_added(amount: int, total_score: int)
signal dish_scored(dish_name: String, score: int, effects: Array)
signal trigger_fired(item_name: String, trigger_type: String, result: Dictionary)

# ============================================
# CONSTANTS
# ============================================

const BASE_INGREDIENT_SCORE: int = 10
const PER_INGREDIENT_BONUS: int = 5
const BASE_MULT: float = 1.0

# ============================================
# PROPERTIES
# ============================================

var recipe_system: Node = null
var equipped_items: Array = []

# Buffers cho current calculation
var _current_played_cards: Array = []
var _accumulated_results: Array = []
var _meta_effects: Dictionary = {}

# ============================================
# LIFECYCLE
# ============================================

func _ready() -> void:
	print("ScoringSystem: Initialized with Trigger System")
	recipe_system = get_parent().get_node_or_null("RecipeSystem")

# ============================================
# PUBLIC API
# ============================================

func set_equipped_items(items: Array) -> void:
	equipped_items = items
	print("ScoringSystem: Equipped ", items.size(), " items")
	for item in items:
		print("  - ", item.get_display_name())

func get_equipped_items() -> Array:
	return equipped_items

# ============================================
# MAIN SCORING FUNCTION
# ============================================

func calculate_dish_score(ingredients: Array) -> Dictionary:
	_reset_buffers()

	_current_played_cards = ingredients.duplicate()

	# STEP 1: on_play()
	_trigger_on_play(ingredients)

	# STEP 2: Tạo dishes và tính điểm
	var dishes = _create_dishes_from_ingredients(ingredients)

	# STEP 3: Tính total
	var total_score = _calculate_total(dishes)
	var breakdown = _create_breakdown(dishes)

	var result = {
		"total_score": total_score,
		"dishes": dishes,
		"breakdown": breakdown,
		"meta_effects": _meta_effects.duplicate()
	}

	emit_signal("score_calculated", total_score, dishes, breakdown)

	return result

# ============================================
# TRIGGER METHODS
# ============================================

func _reset_buffers() -> void:
	_current_played_cards.clear()
	_accumulated_results.clear()
	_meta_effects = {
		"extra_cook": 0,
		"extra_discard": 0,
		"extra_hand_size": 0,
		"extra_currency": 0,
		"free_reroll": false,
		"trigger_logs": []
	}

func _trigger_on_play(cards: Array) -> void:
	for item in equipped_items:
		if not item.is_active:
			continue

		if item.has_method("on_play"):
			var result = item.on_play(cards)
			if result != null and result.triggered and result.has_effects():
				_accumulated_results.append(result)
				_apply_meta_effects(result)
				_log_trigger(item.get_display_name(), "on_play", result)

func _trigger_on_ingredient_scored(ingredient: IngredientData) -> TriggerResult:
	var combined = TriggerResult.new()

	for item in equipped_items:
		if not item.is_active:
			continue

		if item.has_method("on_ingredient_scored"):
			var result = item.on_ingredient_scored(ingredient)
			if result != null and result.triggered:
				combined = combined.combine(result)
				_log_trigger(item.get_display_name(), "on_ingredient_scored", result)

	return combined

func _trigger_on_recipe_scored(recipe: RecipeData, base_score: int) -> TriggerResult:
	var combined = TriggerResult.new()

	for item in equipped_items:
		if not item.is_active:
			continue

		if item.has_method("on_recipe_scored"):
			var result = item.on_recipe_scored(recipe, base_score)
			if result != null and result.triggered:
				combined = combined.combine(result)
				_log_trigger(item.get_display_name(), "on_recipe_scored", result)

	# LƯU Ý: Thêm recipe_result vào accumulated để tính mult
	if combined.has_effects():
		_accumulated_results.append(combined)

	return combined

func _log_trigger(item_name: String, trigger_type: String, result: TriggerResult) -> void:
	_meta_effects["trigger_logs"].append({
		"item": item_name,
		"trigger": trigger_type,
		"text": result.text
	})
	emit_signal("trigger_fired", item_name, trigger_type, {
		"score": result.score,
		"mult": result.mult,
		"text": result.text
	})

func _apply_meta_effects(result: TriggerResult) -> void:
	_meta_effects["extra_cook"] += result.extra_cook
	_meta_effects["extra_discard"] += result.extra_discard
	_meta_effects["extra_hand_size"] += result.extra_hand_size
	_meta_effects["extra_currency"] += result.extra_currency
	if result.free_reroll:
		_meta_effects["free_reroll"] = true

# ============================================
# DISH CREATION
# ============================================

func _create_dishes_from_ingredients(ingredients: Array) -> Array:
	var result: Array = []
	var remaining = ingredients.duplicate()

	var visible_recipes = RecipeDB.get_visible_recipes()
	visible_recipes.sort_custom(func(a, b):
		return b.base_multiplier > a.base_multiplier
	)

	var iterations = 0
	var max_iterations = remaining.size() * 2

	while not remaining.is_empty() and iterations < max_iterations:
		iterations += 1

		var best_match = _find_best_recipe_for_ingredients(remaining, visible_recipes)

		if best_match.is_empty():
			break

		var recipe = best_match.get("recipe")
		var used_ingredients = best_match.get("used_ingredients", [])

		if recipe == null or used_ingredients.is_empty():
			break

		var dish = _create_dish_from_recipe(recipe, used_ingredients)
		result.append(dish)

		for ing in used_ingredients:
			remaining.erase(ing)

	if not remaining.is_empty():
		var leftover_dish = _create_dish_from_ingredients(remaining)
		result.append(leftover_dish)

	return result

func _find_best_recipe_for_ingredients(available: Array, recipes: Array) -> Dictionary:
	var best_match: Dictionary = {}
	var best_score = 0

	for recipe in recipes:
		var available_copy = available.duplicate()
		var matched_ids = _try_match_recipe(recipe, available_copy)

		if not matched_ids.is_empty():
			var potential_score = _estimate_dish_score(recipe, matched_ids.size())

			if potential_score > best_score:
				best_score = potential_score
				best_match = {
					"recipe": recipe,
					"used_ingredients": _extract_ingredients_by_id(recipe.required_ingredients, available)
				}

	return best_match

func _try_match_recipe(recipe: RecipeData, available: Array) -> Array:
	var required = recipe.required_ingredients.duplicate()
	var matched_ids: Array = []

	var available_count: Dictionary = {}
	for ing in available:
		var id = ing.ingredient_id
		if not available_count.has(id):
			available_count[id] = 0
		available_count[id] += 1

	for req_id in required:
		if available_count.has(req_id) and available_count[req_id] > 0:
			matched_ids.append(req_id)
			available_count[req_id] -= 1
		else:
			return []

	return matched_ids

func _extract_ingredients_by_id(required_ids: Array, available: Array) -> Array:
	var result: Array = []
	var used_indices: Array = []

	for req_id in required_ids:
		for i in range(available.size()):
			if i not in used_indices and available[i].ingredient_id == req_id:
				result.append(available[i])
				used_indices.append(i)
				break

	return result

func _estimate_dish_score(recipe: RecipeData, ingredient_count: int) -> int:
	var score = recipe.base_score
	var extra = ingredient_count - recipe.get_required_count()
	if extra > 0:
		score += extra * recipe.bonus_per_extra_ingredient
	return int(score * recipe.base_multiplier)

# ============================================
# DISH CREATION
# ============================================

func _create_dish_from_recipe(recipe: RecipeData, ingredients: Array) -> Dictionary:
	var base_score = recipe.base_score
	var extra = ingredients.size() - recipe.get_required_count()
	if extra > 0:
		base_score += extra * recipe.bonus_per_extra_ingredient

	# on_ingredient_scored() cho từng ingredient
	var ingredient_bonus = 0
	var effects_list: Array = []

	for ing in ingredients:
		var result = _trigger_on_ingredient_scored(ing)
		if result.triggered:
			# Cộng score
			if result.score != 0:
				ingredient_bonus += result.score
			# THÊM: Cộng mult vào accumulated
			if result.mult != 0 or result.mult_score:
				_accumulated_results.append(result)
			# Log effects
			if result.text != "":
				effects_list.append({"item": ing.display_name, "text": result.text})

	var subtotal = base_score + ingredient_bonus

	# on_recipe_scored() - LƯU Ý: Kết quả đã được thêm vào _accumulated_results
	_trigger_on_recipe_scored(recipe, base_score)

	var ingredient_names: Array = []
	for ing in ingredients:
		ingredient_names.append(ing.display_name)

	return {
		"recipe": recipe,
		"ingredients": ingredients,
		"base_score": base_score,
		"ingredient_bonus": ingredient_bonus,
		"recipe_bonus": 0,  # Sẽ được tính trong _calculate_total
		"subtotal": subtotal,
		"recipe_mult": recipe.base_multiplier,
		"dish_name": recipe.display_name,
		"is_recipe": true,
		"effects": effects_list
	}

func _create_dish_from_ingredients(ingredients: Array) -> Dictionary:
	var base_score = ingredients.size() * BASE_INGREDIENT_SCORE
	var extra_bonus = max(0, ingredients.size() - 2) * PER_INGREDIENT_BONUS
	base_score += extra_bonus

	var ingredient_bonus = 0
	var effects_list: Array = []

	for ing in ingredients:
		var result = _trigger_on_ingredient_scored(ing)
		if result.triggered:
			# Cộng score
			if result.score != 0:
				ingredient_bonus += result.score
			# THÊM: Cộng mult vào accumulated
			if result.mult != 0 or result.mult_score:
				_accumulated_results.append(result)
			# Log effects
			if result.text != "":
				effects_list.append({"item": ing.display_name, "text": result.text})

	var subtotal = base_score + ingredient_bonus

	var ingredient_names: Array = []
	for ing in ingredients:
		ingredient_names.append(ing.display_name)

	return {
		"recipe": null,
		"ingredients": ingredients,
		"base_score": base_score,
		"ingredient_bonus": ingredient_bonus,
		"recipe_bonus": 0,
		"subtotal": subtotal,
		"recipe_mult": 1.0,
		"dish_name": " + ".join(ingredient_names),
		"is_recipe": false,
		"effects": effects_list
	}

# ============================================
# SCORE CALCULATION - CÔNG THỨC MỚI
# ============================================

func _calculate_total(dishes: Array) -> float:
	# ═════════════════════════════════════════════════════════════════════
	# CÔNG THỨC:
	# Total Score = (Tổng subtotal) × (Base Mult + Recipe Mult + Item Mult)
	#
	# Trong đó:
	#   - Base Mult = 1.0
	#   - Recipe Mult = recipe.base_mult - 1 (chỉ cho recipes, không trừ cho non-recipe)
	#   - Item Mult: CỘNG (+), hoặc NHÂN (×) nếu mult_score = true
	# ═════════════════════════════════════════════════════════════════════

	#var total_subtotal: float = 0.0
#
	## Tính tổng subtotal
	#for dish in dishes:
		#total_subtotal += dish["subtotal"] + dish["recipe_bonus"]
#
	## Tính tổng mult
	#var total_mult: float = BASE_MULT  # Bắt đầu từ 1.0
#
	## Thêm recipe mult (recipe.base_mult - 1)
	#for dish in dishes:
		#if dish["is_recipe"]:
			#var recipe_mult = dish["recipe_mult"]
			#if recipe_mult > BASE_MULT:
				#total_mult += (recipe_mult - BASE_MULT)  # 1.3 - 1.0 = 0.3
#
	## Thêm item mult từ accumulated results
	#for result in _accumulated_results:
		#if result.mult_score:
			## NHÂN: total_mult = total_mult × (1 + result.mult)
			## VD: mult=2.0 có nghĩa là ×2, nên (1 + 2) = 3
			#total_mult = total_mult * (result.mult)
		#else:
			## CỘNG: total_mult += result.mult
			#total_mult += result.mult
#
		## Xử lý set_mult
		#if result.set_mult >= 0:
			#total_mult = result.set_mult
#
	## Đảm bảo mult không âm
	#if total_mult < 0:
		#total_mult = 0
#
	## Tính điểm cuối
	#var final_score = total_subtotal * total_mult
#
	## Gán final_score và mult cho từng dish (để hiển thị)
	#for dish in dishes:
		#dish["multiplier"] = total_mult
		#dish["final_score"] = final_score
		#emit_signal("dish_scored", dish["dish_name"], final_score, dish["effects"])
#
	#return final_score
#
#func _create_breakdown(dishes: Array) -> Dictionary:
	#var from_recipes = 0
	#var from_mixed = 0
	#var recipe_count = 0
	#var trigger_logs: Array = _meta_effects.get("trigger_logs", []).duplicate()
#
	#for dish in dishes:
		#if dish["is_recipe"]:
			#from_recipes += dish["final_score"]
			#recipe_count += 1
		#else:
			#from_mixed += dish["final_score"]
#
	#return {
		#"from_recipes": from_recipes,
		#"from_mixed": from_mixed,
		#"dish_count": dishes.size(),
		#"recipe_count": recipe_count,
		#"trigger_logs": trigger_logs,
		#"meta_effects": _meta_effects.duplicate()
	#}
#
## ============================================
## UTILITY
## ============================================
#
#func get_score_preview(ingredients: Array) -> Dictionary:
	#return calculate_dish_score(ingredients)
#
#func add_score_to_game(amount: int) -> void:
	#if has_node("/root/GameManager"):
		#GameManager.add_score(amount)
		#emit_signal("score_added", amount, GameManager.current_score)
#
## ============================================
## STAGE LIFECYCLE
## ============================================
#
#func on_stage_start() -> void:
	#print("ScoringSystem: Stage starting...")
	#_reset_buffers()
#
	#for item in equipped_items:
		#if not item.is_active:
			#continue
#
		#if item.has_method("on_stage_start"):
			#var result = item.on_stage_start()
			#if result != null and result.triggered and result.has_effects():
				#_apply_meta_effects(result)
				#print("  ", item.get_display_name(), ": ", result.text)
#
#func after_match() -> void:
	#print("ScoringSystem: Match ending...")
#
	#for item in equipped_items:
		#if not item.is_active:
			#continue
#
		#if item.has_method("after_match"):
			#item.after_match()
#
#func get_meta_effects() -> Dictionary:
	#return _meta_effects.duplicate()
#
## ============================================
## DEBUG
## ============================================
#
#func debug_print_dishes(dishes: Array) -> void:
	#print("=== DISHES BREAKDOWN ===")
#
	#for i in range(dishes.size()):
		#var dish = dishes[i]
		#var prefix = "[RECIPE]" if dish["is_recipe"] else "[MIXED]"
#
		#print("%s Dish %d: %s" % [prefix, i + 1, dish["dish_name"]])
		#print("   Base: %d" % dish["base_score"])
#
		#if dish["ingredient_bonus"] > 0:
			#print("   Ingredient Bonus: +%d" % dish["ingredient_bonus"])
#
		#if dish["recipe_bonus"] > 0:
			#print("   Recipe Bonus: +%d" % dish["recipe_bonus"])
#
		#print("   Multiplier: x%.2f" % dish["multiplier"])
		#print("   Final: %d" % dish["final_score"])
#
	#var total = 0
	#for dish in dishes:
		#total += dish["final_score"]
	#print("TOTAL: %d" % total)
