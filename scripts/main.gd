extends Control
## Controlador da tela: monta a interface, repassa toques para a lógica
## e abre os painéis. As regras ficam em scripts/game/logic.gd.

const ThemeFactory := preload("res://scripts/ui/theme_factory.gd")
const Content := preload("res://scripts/game/content.gd")
const Logic := preload("res://scripts/game/logic.gd")
const SceneArt := preload("res://scripts/ui/scene_art.gd")
const InventoryBar := preload("res://scripts/ui/inventory_bar.gd")
const LockPanel := preload("res://scripts/ui/panels/lock_panel.gd")
const DarkroomPanel := preload("res://scripts/ui/panels/darkroom_panel.gd")
const ListPanel := preload("res://scripts/ui/panels/list_panel.gd")
const ZoomPanel := preload("res://scripts/ui/panels/zoom_panel.gd")
const TitleScreen := preload("res://scripts/ui/panels/title_screen.gd")
const EndingPanel := preload("res://scripts/ui/panels/ending_panel.gd")
const SmokeTest := preload("res://scripts/debug/smoke_test.gd")
const Art := preload("res://scripts/ui/art.gd")

const MESSAGE_SECONDS := 6.0

var art: SceneArt
var hotspot_layer: Control
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


func _ready() -> void:
	theme = ThemeFactory.build()
	_build_ui()
	GameState.changed.connect(refresh)
	GameState.message.connect(show_message)
	if OS.get_cmdline_user_args().has("--smoke"):
		SmokeTest.run(self)
		return
	show_title()


# --- Montagem -------------------------------------------------------------

func _build_ui() -> void:
	art = SceneArt.new()
	art.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(art)

	hotspot_layer = _ignore(Control.new())
	hotspot_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(hotspot_layer)

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
	era_label = ThemeFactory.label("", 30, ThemeFactory.INK)
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
	top.add_child(_action_button("Menu", show_title))

	var middle := _ignore(HBoxContainer.new())
	middle.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(middle)
	left_button = _arrow_button("‹")
	middle.add_child(left_button)
	var spacer := _ignore(Control.new())
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	middle.add_child(spacer)
	right_button = _arrow_button("›")
	middle.add_child(right_button)

	var message_row := _ignore(CenterContainer.new())
	column.add_child(message_row)
	message_panel = PanelContainer.new()
	message_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	message_panel.visible = false
	message_row.add_child(message_panel)
	message_label = ThemeFactory.label("")
	message_label.custom_minimum_size = Vector2(1200, 0)
	message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message_panel.add_child(message_label)
	message_timer = Timer.new()
	message_timer.one_shot = true
	message_timer.timeout.connect(func(): message_panel.visible = false)
	add_child(message_timer)

	var bottom := _ignore(HBoxContainer.new())
	bottom.add_theme_constant_override("separation", 16)
	column.add_child(bottom)
	inventory_bar = InventoryBar.new()
	inventory_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	inventory_bar.item_pressed.connect(func(id): Logic.select_item(GameState, id))
	bottom.add_child(inventory_bar)
	photo_button = _action_button("Fotografar", func(): Logic.take_photo(GameState))
	album_button = _action_button("Álbum", open_album)
	leave_button = _action_button("Sair da foto", leave_photo)
	for b in [photo_button, album_button, leave_button]:
		b.custom_minimum_size = Vector2(0, 110)
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


func _arrow_button(text: String) -> Button:
	var b := ThemeFactory.button(text, Vector2(110, 200))
	b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	b.add_theme_font_size_override("font_size", 80)
	b.pressed.connect(func(): Logic.go_next_view(GameState))
	return b


# --- Atualização ----------------------------------------------------------

func refresh() -> void:
	var past := GameState.is_past()
	art.show_view(GameState.view, GameState.era, _scene_extras())
	_rebuild_hotspots()
	if past:
		era_label.text = "%s · 14 de agosto de 1899 (dentro da foto)" % Content.view_title(GameState.view)
	else:
		era_label.text = "%s · julho de 1924" % Content.view_title(GameState.view)
	left_button.visible = not past
	right_button.visible = not past
	photo_button.visible = GameState.has_item("camera") and not past
	photo_button.text = "Fotografar (%d)" % GameState.plates
	album_button.visible = not GameState.photos.is_empty() and not past
	leave_button.visible = past
	inventory_bar.refresh(GameState.inventory, GameState.selected_item)


func _scene_extras() -> Array:
	var extras: Array = []
	if not GameState.is_past():
		return extras
	if GameState.view == "estacao" and not GameState.has_flag("bilhete_pego"):
		extras.append("bilhete")
	if GameState.view == "bilheteria":
		extras.append("fogo")
		if not GameState.has_flag("chave_pega"):
			extras.append("chave")
	return extras


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
		b.pressed.connect(on_hotspot.bind(h["id"]))
		hotspot_layer.add_child(b)


func show_message(text: String) -> void:
	message_label.text = text
	message_panel.visible = true
	message_timer.start(MESSAGE_SECONDS)


# --- Ações ----------------------------------------------------------------

func on_hotspot(id: String) -> void:
	var result := Logic.interact(GameState, id)
	match result.get("open", ""):
		"lock":
			open_lock()
		"zoom_relogio":
			open_zoom("relogio", "Os ponteiros pararam às 3h17. Uma pena amarela presa sob o aro.", Content.CLOCK_TIME[1924])
		"hint":
			ask_hint()
	_check_ending()


func ask_hint() -> void:
	show_message(Logic.next_hint(GameState))


func leave_photo() -> void:
	Logic.leave_photo(GameState)
	_check_ending()


func _check_ending() -> void:
	if Logic.ending_ready(GameState):
		open_ending()


# --- Painéis --------------------------------------------------------------

func open_modal(panel: Control) -> void:
	close_modal()
	var dim := ColorRect.new()
	dim.color = ThemeFactory.DIM
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	modal_layer.add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	modal_layer.add_child(center)
	center.add_child(panel)


func close_modal() -> void:
	for child in modal_layer.get_children():
		child.queue_free()


func open_lock() -> void:
	var panel := LockPanel.new()
	panel.closed.connect(close_modal)
	panel.submitted.connect(func(code):
		if Logic.try_code(GameState, code):
			close_modal())
	open_modal(panel)


func open_zoom(art_name: String, caption: String, clock_time: Array = []) -> void:
	var panel := ZoomPanel.new()
	panel.setup(art_name, caption, clock_time)
	panel.closed.connect(close_modal)
	open_modal(panel)


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
	open_modal(panel)


func open_darkroom(view: String) -> void:
	var panel := DarkroomPanel.new()
	panel.setup(Content.view_title(view), view)
	panel.closed.connect(close_modal)
	panel.developed.connect(func():
		Logic.develop(GameState, view)
		open_album())
	open_modal(panel)


func open_notebook() -> void:
	var rows: Array = []
	for note in GameState.notes:
		rows.append({"text": "• " + note})
	var panel := ListPanel.new()
	panel.setup("Caderno de Lúcia", rows, "Ainda não anotei nada.")
	panel.closed.connect(close_modal)
	open_modal(panel)


func open_ending() -> void:
	var panel := EndingPanel.new()
	panel.menu_requested.connect(show_title)
	panel.restart_requested.connect(start_new_game)
	open_modal(panel)


func show_title() -> void:
	close_modal()
	var screen := TitleScreen.new()
	screen.setup(GameState.has_save())
	screen.continue_requested.connect(continue_game)
	screen.new_game_requested.connect(start_new_game)
	modal_layer.add_child(screen)


func start_new_game() -> void:
	close_modal()
	GameState.new_game()
	show_message("Uma estação vazia. Minha mala. Lá fora, um pássaro insiste: bem-te-vi.")


func continue_game() -> void:
	close_modal()
	if not GameState.load_game():
		GameState.new_game()
	if Logic.ending_ready(GameState):
		open_ending()
