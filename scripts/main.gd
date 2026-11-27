extends Control
## Controlador da tela: monta a interface, repassa toques para a lógica,
## abre os painéis e cuida de som e transições. As regras ficam em scripts/game/.

const ThemeFactory := preload("res://scripts/ui/theme_factory.gd")
const Content := preload("res://scripts/game/content.gd")
const Hotspots := preload("res://scripts/game/hotspots.gd")
const Logic := preload("res://scripts/game/logic.gd")
const SceneArt := preload("res://scripts/ui/scene_art.gd")
const InventoryBar := preload("res://scripts/ui/inventory_bar.gd")
const Ripple := preload("res://scripts/ui/ripple.gd")
const Art := preload("res://scripts/ui/art.gd")
const Menus := preload("res://scripts/ui/menus.gd")
const LockPanel := preload("res://scripts/ui/panels/lock_panel.gd")
const DarkroomPanel := preload("res://scripts/ui/panels/darkroom_panel.gd")
const ListPanel := preload("res://scripts/ui/panels/list_panel.gd")
const ZoomPanel := preload("res://scripts/ui/panels/zoom_panel.gd")
const ItemPanel := preload("res://scripts/ui/panels/item_panel.gd")
const ClockSetPanel := preload("res://scripts/ui/panels/clock_set_panel.gd")
const SmokeTest := preload("res://scripts/debug/smoke_test.gd")

const MESSAGE_SECONDS := 6.0

var art: SceneArt
var hotspot_layer: Control
var fade: ColorRect
var era_label: Label
var left_button: Button
var right_button: Button
var photo_button: Button
var album_button: Button
var leave_button: Button
var inventory_bar: InventoryBar
var message_panel: PanelContainer
var message_label: Label
var message_timer: Timer
var modal_layer: Control
var menus: Menus
## Tipo do painel aberto: "", "title", "item", "chapter_end", "pause"...
var modal_kind := ""
var item_queue: Array = []
var _last_scene_key := ""


func _ready() -> void:
	theme = ThemeFactory.build(Settings.large_text)
	_build_ui()
	menus = Menus.new(self)
	GameState.changed.connect(refresh)
	GameState.message.connect(show_message)
	GameState.item_added.connect(_on_item_added)
	GameState.sound.connect(Audio.sfx)
	Settings.changed.connect(_on_settings_changed)
	if OS.get_cmdline_user_args().has("--smoke"):
		SmokeTest.run(self)
		return
	menus.show_title()


var _modal_over_title := false


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		on_back(true)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		on_back(false)


## Botão voltar do Android / Esc: fecha o painel aberto ou abre a pausa.
func on_back(from_android: bool) -> void:
	match modal_kind:
		"title":
			if from_android:
				get_tree().quit()
		"item":
			_close_item_panel()
		"chapter_end":
			pass
		"":
			menus.show_pause()
		_:
			if _modal_over_title:
				menus.show_title()
			else:
				close_modal()


# --- Montagem -------------------------------------------------------------

func _build_ui() -> void:
	art = SceneArt.new()
	art.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(art)

	hotspot_layer = _ignore(Control.new())
	hotspot_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(hotspot_layer)

	fade = ColorRect.new()
	fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fade.color = Color(0, 0, 0, 0)
	add_child(fade)

	var margin := _ignore(MarginContainer.new())
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 24)
	add_child(margin)
	var column := _ignore(VBoxContainer.new())
	margin.add_child(column)

	var top := _ignore(HBoxContainer.new())
	top.add_theme_constant_override("separation", 16)
	column.add_child(top)
	# Fundo escuro para o rótulo continuar legível sobre cenas claras (1899).
	var era_panel := PanelContainer.new()
	era_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	era_panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	era_panel.add_theme_stylebox_override("panel", ThemeFactory.box(ThemeFactory.PANEL, ThemeFactory.LINE, 2, 12))
	top.add_child(era_panel)
	era_label = ThemeFactory.label("", 30)
	era_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	era_panel.add_child(era_label)
	var top_spacer := _ignore(Control.new())
	top_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(top_spacer)
	top.add_child(_action_button("Caderno", open_notebook))
	var hint_button := _action_button("Dica", ask_hint)
	var bird := Art.load_art("bemtevi")
	if bird != null:
		hint_button.icon = bird
		hint_button.expand_icon = true
		hint_button.custom_minimum_size = Vector2(230, 96)
	top.add_child(hint_button)
	top.add_child(_action_button("Menu", func(): menus.show_pause()))

	var middle := _ignore(HBoxContainer.new())
	middle.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(middle)
	left_button = _arrow_button("‹", "prev")
	middle.add_child(left_button)
	var spacer := _ignore(Control.new())
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	middle.add_child(spacer)
	right_button = _arrow_button("›", "next")
	middle.add_child(right_button)

	var message_row := _ignore(CenterContainer.new())
	column.add_child(message_row)
	message_panel = PanelContainer.new()
	message_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	message_panel.visible = false
	message_row.add_child(message_panel)
	message_label = ThemeFactory.label("")
	message_label.custom_minimum_size = Vector2(1300, 0)
	message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message_panel.add_child(message_label)
	message_timer = Timer.new()
	message_timer.one_shot = true
	message_timer.timeout.connect(func(): message_panel.visible = false)
	add_child(message_timer)

	var bottom := _ignore(HBoxContainer.new())
	bottom.add_theme_constant_override("separation", 14)
	column.add_child(bottom)
	inventory_bar = InventoryBar.new()
	inventory_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	inventory_bar.item_pressed.connect(_on_inventory_pressed)
	bottom.add_child(inventory_bar)
	photo_button = _action_button("Fotografar", func(): Logic.take_photo(GameState))
	album_button = _action_button("Álbum", open_album)
	leave_button = _action_button("Sair da foto", leave_photo)
	for b in [photo_button, album_button, leave_button]:
		b.custom_minimum_size = Vector2(0, 120)
		bottom.add_child(b)

	modal_layer = _ignore(Control.new())
	modal_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(modal_layer)


func _ignore(c: Control) -> Control:
	# Contêineres de layout não podem engolir os toques destinados à cena.
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return c


func _action_button(text: String, callback: Callable) -> Button:
	var b := ThemeFactory.button(text, Vector2(0, 96))
	b.pressed.connect(callback)
	return b


func _arrow_button(text: String, direction: String) -> Button:
	var b := ThemeFactory.button(text, Vector2(110, 200))
	b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	b.add_theme_font_size_override("font_size", 80)
	b.pressed.connect(func(): Logic.go_view(GameState, direction))
	return b


# --- Atualização ----------------------------------------------------------

func refresh() -> void:
	var gs := GameState
	var past := gs.is_past()
	art.show_view(_art_name(), gs.view, gs.era, _scene_extras(), _overlays())
	_rebuild_hotspots()
	_transition()
	era_label.text = "%s · %s · %s" % [
		Content.chapter_title(gs.chapter).split(" — ")[0], Content.view_title(gs.view),
		"1899, dentro da foto" if past else "1924"]
	left_button.visible = not past
	right_button.visible = not past
	photo_button.visible = gs.has_item("camera") and not past
	photo_button.text = "Fotografar (%d)" % gs.plates
	photo_button.disabled = gs.plates <= 0
	album_button.visible = not gs.photos.is_empty() and not past
	leave_button.visible = past
	inventory_bar.refresh(gs.inventory, gs.selected_item)
	if modal_kind != "title" and modal_kind != "chapter_end":
		Audio.bed("amb_%d" % gs.era)


func _art_name() -> String:
	for v in Hotspots.ART_VARIANTS:
		if v["view"] == GameState.view and v["era"] == GameState.era and GameState.has_flag(v["flag"]):
			if Art.load_art(v["art"]) != null:
				return v["art"]
	return "%s_%d" % [GameState.view, GameState.era]


func _scene_extras() -> Array:
	var extras: Array = []
	if not GameState.is_past():
		return extras
	if GameState.view == "estacao" and not GameState.has_flag("bilhete_pego"):
		extras.append("bilhete")
	if GameState.view == "bilheteria" and not GameState.has_flag("chave_pega"):
		extras.append("chave")
	return extras


func _overlays() -> Array:
	var result: Array = []
	for o in Hotspots.OVERLAYS:
		if o["view"] != GameState.view or o["era"] != GameState.era:
			continue
		if o.has("flag") and not GameState.has_flag(o["flag"]):
			continue
		if o.has("unless") and GameState.has_flag(o["unless"]):
			continue
		result.append(o)
	return result


func _transition() -> void:
	var key := "%s_%d" % [GameState.view, GameState.era]
	var previous := _last_scene_key
	_last_scene_key = key
	if previous == "" or previous == key:
		return
	var era_changed := previous.right(4) != key.right(4)
	fade.color = Color(1, 0.97, 0.9, 1.0) if era_changed else Color(0, 0, 0, 0.85)
	var tween := create_tween()
	tween.tween_property(fade, "color:a", 0.0, 0.9 if era_changed else 0.35)


func _rebuild_hotspots() -> void:
	for child in hotspot_layer.get_children():
		child.queue_free()
	for h in Content.hotspots_for(GameState.view, GameState.era):
		var b := Button.new()
		b.theme_type_variation = "Hotspot"
		b.focus_mode = Control.FOCUS_NONE
		b.position = h["rect"].position
		b.size = h["rect"].size
		b.tooltip_text = h["label"]
		if Settings.show_hotspots:
			b.add_theme_stylebox_override("normal", ThemeFactory.hotspot_hint_style())
		b.pressed.connect(on_hotspot.bind(h["id"]))
		hotspot_layer.add_child(b)


func show_message(text: String) -> void:
	message_label.text = text
	message_panel.visible = true
	message_timer.start(MESSAGE_SECONDS)


func _on_settings_changed() -> void:
	theme = ThemeFactory.build(Settings.large_text)
	if modal_kind != "title":
		_rebuild_hotspots()


# --- Ações ----------------------------------------------------------------

func on_hotspot(id: String) -> void:
	var ripple := Ripple.new()
	ripple.position = get_local_mouse_position()
	add_child(ripple)
	handle_result(Logic.interact(GameState, id))


func handle_result(result: Dictionary) -> void:
	match result.get("open", ""):
		"lock":
			open_lock(result["id"], result["digits"], result["title"])
		"zoom":
			open_zoom(result)
		"name":
			open_name(result["index"], result["where"])
		"clock_set":
			open_clock_set()
		"hint":
			ask_hint()
	check_chapter_end()


func _on_inventory_pressed(id: String) -> void:
	if GameState.selected_item == id:
		open_item(id, false)
		return
	Logic.select_item(GameState, id)
	show_message("%s na mão. Toque na cena para usar, ou toque de novo no item para examinar." % Content.item_name(id))


func ask_hint() -> void:
	show_message(Logic.next_hint(GameState))


func leave_photo() -> void:
	Logic.leave_photo(GameState)
	check_chapter_end()


func check_chapter_end() -> void:
	if not Logic.chapter_complete(GameState):
		return
	if not item_queue.is_empty() or modal_kind in ["item", "name", "chapter_end"]:
		return
	menus.show_chapter_end()


# --- Painéis --------------------------------------------------------------

## opaque: fundo sólido, para menus abertos a partir do menu principal.
func open_modal(panel: Control, kind: String, opaque: bool = false) -> void:
	close_modal()
	modal_kind = kind
	# Painéis abertos a partir do título cobrem a tela; o "voltar" deve levar ao título.
	_modal_over_title = opaque
	var dim := ColorRect.new()
	dim.color = Color("1b140f") if opaque else ThemeFactory.DIM
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	modal_layer.add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	modal_layer.add_child(center)
	center.add_child(panel)


func close_modal() -> void:
	modal_kind = ""
	for child in modal_layer.get_children():
		child.queue_free()


func _on_item_added(id: String) -> void:
	item_queue.append(id)
	if modal_kind != "item":
		call_deferred("_show_next_item")


func _show_next_item() -> void:
	if item_queue.is_empty() or modal_kind == "item":
		return
	open_item(item_queue[0], true)


func open_item(id: String, is_new: bool) -> void:
	var panel := ItemPanel.new()
	panel.setup_item(id, is_new)
	panel.closed.connect(_close_item_panel)
	panel.use_requested.connect(func(item_id):
		close_modal()
		GameState.selected_item = item_id
		GameState.commit()
		show_message("%s pronto para usar. Toque no lugar certo da cena." % Content.item_name(item_id)))
	open_modal(panel, "item")
	if not is_new:
		GameState.play("page")


func _close_item_panel() -> void:
	if not item_queue.is_empty():
		item_queue.pop_front()
	else:
		# Examinar pelo inventário: fechar também desmarca o item.
		GameState.selected_item = ""
		GameState.commit()
	close_modal()
	if not item_queue.is_empty():
		open_item(item_queue[0], true)
		return
	check_chapter_end()


func open_name(index: int, where: String) -> void:
	var panel := ItemPanel.new()
	panel.setup_name(index, where)
	panel.closed.connect(func():
		close_modal()
		check_chapter_end())
	open_modal(panel, "name")


func open_lock(lock_id: String, digits: int, title_text: String) -> void:
	var panel := LockPanel.new()
	panel.setup(digits, title_text)
	panel.closed.connect(close_modal)
	panel.submitted.connect(func(code):
		if Logic.try_code(GameState, lock_id, code):
			if modal_kind == "lock":
				close_modal())
	open_modal(panel, "lock")


func open_zoom(params: Dictionary) -> void:
	var panel := ZoomPanel.new()
	panel.setup(params)
	panel.closed.connect(close_modal)
	panel.action.connect(func(action_id):
		close_modal()
		Logic.zoom_action(GameState, action_id))
	open_modal(panel, "zoom")


func open_clock_set() -> void:
	var panel := ClockSetPanel.new()
	panel.closed.connect(close_modal)
	panel.submitted.connect(func(hour, minute):
		if Logic.set_clock(GameState, hour, minute) and modal_kind == "clock":
			close_modal())
	open_modal(panel, "clock")


func open_album() -> void:
	var rows: Array = []
	for view in GameState.photos:
		var developed: bool = GameState.photos[view] == "developed"
		rows.append({
			"text": Content.view_title(view) + (" · revelada" if developed else " · não revelada"),
			"action": "Entrar na foto" if developed else "Revelar",
			"id": view,
			"kind": "enter" if developed else "develop",
		})
	var panel := ListPanel.new()
	panel.setup("Álbum · %d chapa(s) livre(s)" % GameState.plates, rows, "Nenhuma foto ainda.")
	panel.closed.connect(close_modal)
	panel.action.connect(func(view, kind):
		if kind == "develop":
			open_darkroom(view)
		else:
			close_modal()
			Logic.enter_photo(GameState, view))
	open_modal(panel, "album")


func open_darkroom(view: String) -> void:
	var panel := DarkroomPanel.new()
	panel.setup(Content.view_title(view), view)
	panel.closed.connect(close_modal)
	panel.developed.connect(func():
		Logic.develop(GameState, view)
		open_album())
	open_modal(panel, "darkroom")


func open_notebook() -> void:
	var rows: Array = []
	for i in range(GameState.notes.size() - 1, -1, -1):
		rows.append({"text": "• " + GameState.notes[i]})
	var panel := ListPanel.new()
	panel.setup("Caderno de Lúcia · nomes encontrados: %d de 31" % GameState.names_found.size(), rows, "Ainda não anotei nada.")
	panel.closed.connect(close_modal)
	open_modal(panel, "notebook")
	GameState.play("page")
