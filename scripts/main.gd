extends Control
## タイトル → 選択 → エピソード → 「タイトルへ戻る」。
## 検証用の起動引数（godot --path . -- <引数>）:
##   --ep=N            N番(0〜9)のエピソードを即再生    --all   全エピソードを順に再生して所要時間を出す
##   --fast=X          演出の速度                          --quit  終わったら終了
##   --shots=<dir> --at=1,2,3   演出開始から（演出時間で）その秒に画面を保存（窓あり）
##   --select / --title  その画面を保存して終了           --seen=all  全部「済」にして起動（保存しない）
##   --mute            音を出さない

const ITEMS := [
	{"id": "knife", "name": "ナイフ"},
	{"id": "lighter", "name": "ライター"},
	{"id": "rod", "name": "釣り竿"},
	{"id": "tent", "name": "テント"},
	{"id": "phone", "name": "スマートフォン"},
	{"id": "book", "name": "本"},
	{"id": "food", "name": "食料一年分"},
	{"id": "satphone", "name": "衛星電話"},
	{"id": "gold", "name": "金塊"},
	{"id": "gun", "name": "一発だけ実弾の\n入った拳銃"},
]
const SAVE_PATH := "user://mujintou.cfg"

var S: Stage
var eps: Episodes
var seen: Array = []
var state := "title"
var cur := -1
var args := {"ep": -1, "all": false, "shots": "", "at": [], "quit": false, "select": false, "title": false, "seen_all": false, "anim": false, "wait": 0.8}

var title_ui: Control
var select_ui: Control
var ep_ui: Control
var end_ui: Control
var q1: Label
var q2: Label
var grid: GridContainer
var item_btns: Array = []
var title_label: Label
var reset_btn: Button
var end_label: Label
var _all_token := 0


func _ready() -> void:
	Art.font = load("res://fonts/NotoSansJP-Bold-subset.ttf")
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for i in ITEMS.size():
		seen.append(false)
	_parse_args()
	_load()
	S = Stage.new()
	add_child(S)
	S.opts.fast = args.get("fast", 1.0)
	S.opts.mute = args.get("mute", false)
	eps = Episodes.new(S)
	_build_ui()
	if args.seen_all:
		for i in seen.size():
			seen[i] = true
	if args.ep >= 0 or args.all:
		_auto()
	elif args.select:
		_show_select(args.anim)
		await get_tree().create_timer(float(args.wait)).timeout
		_shot("select")
		get_tree().quit()
	elif args.title:
		_show_title()
		await get_tree().create_timer(0.8).timeout
		_shot("title")
		get_tree().quit()
	else:
		_show_title()


func _parse_args() -> void:
	args["fast"] = 1.0
	args["mute"] = false
	for a in OS.get_cmdline_user_args():
		var v := a.get_slice("=", 1)
		if a.begins_with("--ep="):
			args["ep"] = int(v)
		elif a == "--all":
			args["all"] = true
		elif a.begins_with("--fast="):
			args["fast"] = float(v)
		elif a == "--quit":
			args["quit"] = true
		elif a.begins_with("--shots="):
			args["shots"] = v
		elif a.begins_with("--at="):
			var ts: Array = []
			for s in v.split(","):
				ts.append(float(s))
			args["at"] = ts
		elif a == "--anim":
			args["anim"] = true
		elif a.begins_with("--wait="):
			args["wait"] = float(v)
		elif a == "--select":
			args["select"] = true
		elif a == "--title":
			args["title"] = true
		elif a == "--seen=all":
			args["seen_all"] = true
		elif a == "--mute":
			args["mute"] = true


func _load() -> void:
	var cf := ConfigFile.new()
	if cf.load(SAVE_PATH) == OK:
		for i in seen.size():
			seen[i] = cf.get_value("seen", str(i), false)


func _save() -> void:
	if args.seen_all or args.ep >= 0 or args.all:
		return
	var cf := ConfigFile.new()
	for i in seen.size():
		cf.set_value("seen", str(i), seen[i])
	cf.save(SAVE_PATH)


func _all_seen() -> bool:
	for s in seen:
		if not s:
			return false
	return true


func _any_seen() -> bool:
	for s in seen:
		if s:
			return true
	return false


# ------------------------------------------------------------------ UI
func _style(col: Color, rad: int = 16, border: Color = Color(0, 0, 0, 0)) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = col
	sb.set_corner_radius_all(rad)
	sb.border_color = border
	sb.set_border_width_all(3 if border.a > 0.0 else 0)
	sb.content_margin_left = 24
	sb.content_margin_right = 24
	sb.content_margin_top = 8
	sb.content_margin_bottom = 10
	return sb


func _button(text: String, size: int) -> Button:
	var b := Button.new()
	b.text = text
	b.add_theme_font_size_override("font_size", size)
	b.add_theme_color_override("font_color", Color("3a2a10"))
	b.add_theme_color_override("font_hover_color", Color("3a2a10"))
	b.add_theme_color_override("font_pressed_color", Color("3a2a10"))
	b.add_theme_stylebox_override("normal", _style(Color(1, 0.95, 0.75, 0.95), 18, Color("e0a030")))
	b.add_theme_stylebox_override("hover", _style(Color(1, 0.88, 0.45, 1.0), 18, Color("e0a030")))
	b.add_theme_stylebox_override("pressed", _style(Color(1, 0.8, 0.3, 1.0), 18, Color("e0a030")))
	b.focus_mode = Control.FOCUS_NONE
	return b


func _label(size: int, col: Color = Color.WHITE, outline: int = 10) -> Label:
	var l := Label.new()
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", col)
	l.add_theme_color_override("font_outline_color", Color(0.05, 0.2, 0.35, 0.95))
	l.add_theme_constant_override("outline_size", outline)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


func _build_ui() -> void:
	# --- タイトル
	title_ui = Control.new()
	title_ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	title_ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(title_ui)
	title_label = _label(104, Color.WHITE, 16)
	title_label.text = "無人島に\n持っていくもの"
	title_label.add_theme_constant_override("line_spacing", -6)
	title_label.position = Vector2(140, 22)
	title_label.size = Vector2(1000, 260)
	title_ui.add_child(title_label)
	var sub := _label(32, Color("fff6c8"), 8)
	sub.text = "― 何を渡しても、この人はまともに使わない ―"
	sub.position = Vector2(140, 300)
	sub.size = Vector2(1000, 50)
	title_ui.add_child(sub)
	var start := _button("はじめる", 54)
	start.position = Vector2(470, 580)
	start.size = Vector2(340, 90)
	start.pressed.connect(_on_start)
	start.mouse_entered.connect(func(): S.sfx("blip", -6.0))
	title_ui.add_child(start)
	reset_btn = _button("最初から", 22)
	reset_btn.position = Vector2(1090, 660)
	reset_btn.size = Vector2(170, 46)
	reset_btn.pressed.connect(_on_reset)
	title_ui.add_child(reset_btn)

	# --- 選択
	select_ui = Control.new()
	select_ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	select_ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(select_ui)
	q1 = _label(50, Color.WHITE, 12)
	q1.text = "無人島に、ひとつだけ持っていけるとしたら？"
	q1.position = Vector2(40, 22)
	q1.size = Vector2(1200, 70)
	select_ui.add_child(q1)
	q2 = _label(36, Color("fff6c8"), 9)
	q2.text = "ただ一つだけ選んでください"
	q2.position = Vector2(40, 96)
	q2.size = Vector2(1200, 50)
	select_ui.add_child(q2)
	grid = GridContainer.new()
	grid.columns = 5
	grid.add_theme_constant_override("h_separation", 14)
	grid.add_theme_constant_override("v_separation", 14)
	grid.position = Vector2(112, 436)
	select_ui.add_child(grid)
	for i in ITEMS.size():
		var b := _item_button(i)
		grid.add_child(b)
		item_btns.append(b)

	# --- 演出中
	ep_ui = Control.new()
	ep_ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ep_ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(ep_ui)
	var quit_b := _button("やめる", 22)
	quit_b.position = Vector2(1120, 16)
	quit_b.size = Vector2(140, 44)
	quit_b.pressed.connect(func(): S.aborted = true)
	ep_ui.add_child(quit_b)
	var hint := _label(20, Color(1, 1, 1, 0.85), 5)
	hint.text = "押し続けで早送り"
	hint.position = Vector2(1000, 690)
	hint.size = Vector2(270, 28)
	ep_ui.add_child(hint)

	# --- 終了後
	end_ui = Control.new()
	end_ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	end_ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(end_ui)
	end_label = _label(64, Color.WHITE, 0)
	end_label.position = Vector2(140, 230)
	end_label.size = Vector2(1000, 100)
	end_ui.add_child(end_label)
	var back := _button("タイトルへ戻る", 44)
	back.position = Vector2(420, 400)
	back.size = Vector2(440, 84)
	back.pressed.connect(_on_back)
	end_ui.add_child(back)
	_hide_all()


func _hide_all() -> void:
	title_ui.visible = false
	select_ui.visible = false
	ep_ui.visible = false
	end_ui.visible = false


func _item_button(i: int) -> Button:
	var b := Button.new()
	b.custom_minimum_size = Vector2(200, 124)
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_stylebox_override("normal", _style(Color(1, 1, 1, 0.8), 14, Color(1, 1, 1, 0.9)))
	b.add_theme_stylebox_override("hover", _style(Color(1, 0.93, 0.6, 0.97), 14, Color("e0a030")))
	b.add_theme_stylebox_override("pressed", _style(Color(1, 0.85, 0.4, 1.0), 14, Color("e0a030")))
	b.draw.connect(_draw_item_button.bind(b, i))
	b.pressed.connect(_pick.bind(i))
	b.mouse_entered.connect(func(): S.sfx("blip", -6.0))
	return b


func _draw_item_button(b: Button, i: int) -> void:
	var it: Dictionary = ITEMS[i]
	Art.item(b, it.id, Vector2(100, 46), 0.62)
	var lines: PackedStringArray = String(it.name).split("\n")
	for k in lines.size():
		var fs := 22 if lines.size() == 1 else 17
		Art.ctext(b, lines[k], Vector2(100, 104 + k * 18 - (lines.size() - 1) * 7), fs, Color("3a2a10"), 0, Color.BLACK, 190.0)
	if seen[i]:
		b.draw_set_transform(Vector2(172, 24), 0.25, Vector2.ONE)
		b.draw_circle(Vector2.ZERO, 17.0, Color(1, 1, 1, 0.9))
		b.draw_arc(Vector2.ZERO, 17.0, 0.0, TAU, 24, Color("d03030"), 3.0)
		Art.ctext(b, "済", Vector2(0, 9), 24, Color("d03030"), 0, Color.BLACK, 40.0)
		Art.reset_tf(b)


# ------------------------------------------------------------------ 画面遷移
func _show_title() -> void:
	state = "title"
	_all_token += 1
	_hide_all()
	S.active = false
	S.reset("day")
	S.h.p = Vector2(640, 520)
	S.h.expr = "smile"
	S.tick_fn = _idle_tick
	title_ui.visible = true
	reset_btn.visible = _any_seen()


func _idle_tick(_dt: float) -> void:
	S.h.arm_r = 150.0 + sin(S.t * 3.0) * 20.0 if state == "title" else 8.0


func _on_start() -> void:
	S.sfx("ok")
	S.play_music()
	_show_select(false)


func _on_reset() -> void:
	S.sfx("boing")
	for i in seen.size():
		seen[i] = false
	_save()
	reset_btn.visible = false


func _show_select(from_ep: bool) -> void:
	state = "select"
	_all_token += 1
	_hide_all()
	S.active = false
	S.reset("day")
	S.h.p = Vector2(640, 428)
	S.h.s = 0.78
	S.h.expr = "think"
	S.tick_fn = Callable()
	q1.text = "無人島に、ひとつだけ持っていけるとしたら？"
	q2.text = "ただ一つだけ選んでください"
	q2.visible = true
	select_ui.visible = true
	for b in item_btns:
		(b as Button).queue_redraw()
	if _all_seen():
		if from_ep:
			_all_clear_show()
		else:
			_all_clear_final()


func _all_clear_final() -> void:
	q1.text = "すべてのアイテムを選びました"
	q2.text = "※ひとつだけ選んでください。"
	S.h.expr = "smug"


func _all_clear_show() -> void:
	var tok := _all_token
	await get_tree().create_timer(1.4).timeout
	if tok != _all_token:
		return
	S.sfx("ding")
	q1.text = "すべてのアイテムを選びました"
	q2.visible = false
	S.h.expr = "blank"
	await get_tree().create_timer(2.4).timeout
	if tok != _all_token:
		return
	S.sfx("boing")
	q2.text = "※ひとつだけ選んでください。"
	q2.visible = true
	S.h.expr = "smug"


func _pick(i: int) -> void:
	if state != "select":
		return
	state = "episode"
	cur = i
	S.sfx("ok")
	_run_episode(i)


func _run_episode(i: int) -> void:
	_hide_all()
	ep_ui.visible = true
	S.active = true
	S.aborted = false
	var t0 := S.clock
	await eps.run(i)
	S.active = false
	var done: bool = not S.aborted
	S.aborted = false
	if args.ep >= 0 or args.all:
		print("episode %d done in %.1fs (clock)" % [i, S.clock - t0])
		return
	if done:
		seen[i] = true
		_save()
		_show_end(i)
	else:
		S.reset("day")
		_show_select(false)


func _show_end(i: int) -> void:
	state = "end"
	_hide_all()
	S.reset("day", true)
	var nm := String(ITEMS[i].name).replace("\n", "")
	end_label.text = "「%s」編　おしまい" % nm if not nm.begins_with("一発") else "「拳銃」編　おしまい"
	end_ui.visible = true
	S.sfx("ding", -4.0)


func _on_back() -> void:
	S.sfx("ok")
	_show_select(true)


# ------------------------------------------------------------------ 検証
func _auto() -> void:
	S.play_music()
	var list: Array = range(ITEMS.size()) if args.all else [args.ep]
	var total := 0.0
	var shots_dir: String = args.shots
	var at: Array = args.at
	if shots_dir != "":
		DirAccess.make_dir_recursive_absolute(shots_dir)
		_shot_loop(shots_dir, at)
	for i in list:
		var t0 := S.clock
		state = "episode"
		cur = i
		await _run_episode_auto(i)
		total += S.clock - t0
	print("total %.1fs" % total)
	if args.quit:
		get_tree().quit()


func _run_episode_auto(i: int) -> void:
	_hide_all()
	S.active = true
	S.aborted = false
	var t0 := S.clock
	await eps.run(i)
	print("episode %d (%s): %.1fs" % [i, ITEMS[i].id, S.clock - t0])


func _shot_loop(dir: String, at: Array) -> void:
	var t0 := S.clock
	var idx := 0
	var ts := at.duplicate()
	ts.sort()
	while idx < ts.size():
		await get_tree().process_frame
		if S.clock - t0 >= float(ts[idx]):
			_shot("%s/ep%d_%05.1f" % [dir, cur, float(ts[idx])])
			idx += 1


func _shot(name: String) -> void:
	var path := name
	if not path.contains("/"):
		path = "G:/マイドライブ/昼休みゲーム開発/mujintou/shots/%s" % name
		DirAccess.make_dir_recursive_absolute("G:/マイドライブ/昼休みゲーム開発/mujintou/shots")
	var img := get_viewport().get_texture().get_image()
	img.save_png(path + ".png")
	print("shot ", path)
