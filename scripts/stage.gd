class_name Stage
extends Control
## 舞台。海・島・空、主人公の状態、字幕、時間経過テロップ、SE を持つ。
## 各エピソードは await で書く:  await S.say("…")  await S.move(…)  await S.jump("翌日", fn)
## 描画は 空 → 世界(島・主役・小物) → 暗さ → 光(加算) → 前面(文字・雨) の順。

const HORIZON := 300.0
const SW := 1280.0
const SH := 720.0

var opts := {"fast": 1.0, "mute": false}
var active := false            # 演出中（長押し早送りを効かせる）
var aborted := false
var t := 0.0                   # 実時間（ゆらぎ用）
var clock := 0.0               # 演出時間（検証用）
var cam_y := 0.0

var h := {}                    # 主人公
var v := {}                    # エピソード用の変数置き場
var tod := {}                  # 空と海の色
var tick_fn := Callable()
var back_fn := Callable()
var front_fn := Callable()
var glow_fn := Callable()
var fx_fn := Callable()
var hero_visible := true
var island := true
var floaters: Array = []
var parts: Array = []

var sky: Control
var world: Node2D
var tint: ColorRect
var glow: Node2D
var fx: Control
var say_panel: PanelContainer
var say_label: Label
var fade: ColorRect
var cap_label: Label
var music: AudioStreamPlayer
var sfx_pool: Array[AudioStreamPlayer] = []
var sfx_cache := {}
var _sfx_i := 0

var TOD := {}
var PALMS := [Vector3(150, 470, 270), Vector3(1140, 480, 300), Vector3(985, 440, 200)]


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_init_tod()
	sky = Control.new()
	world = Node2D.new()
	tint = ColorRect.new()
	glow = Node2D.new()
	fx = Control.new()
	for n in [sky, tint, fx]:
		(n as Control).set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		(n as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	glow.material = mat
	add_child(sky)
	add_child(world)
	add_child(tint)
	add_child(glow)
	add_child(fx)
	sky.draw.connect(_draw_sky)
	world.draw.connect(_draw_world)
	glow.draw.connect(_draw_glow)
	fx.draw.connect(_draw_fx)

	say_panel = PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.05, 0.07, 0.12, 0.72)
	sb.set_corner_radius_all(18)
	sb.content_margin_left = 26
	sb.content_margin_right = 26
	sb.content_margin_top = 10
	sb.content_margin_bottom = 12
	say_panel.add_theme_stylebox_override("panel", sb)
	say_panel.position = Vector2(140, 622)
	say_panel.size = Vector2(1000, 76)
	say_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	say_label = Label.new()
	say_label.add_theme_font_size_override("font_size", 36)
	say_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	say_label.custom_minimum_size = Vector2(940, 0)
	say_panel.add_child(say_label)
	say_panel.visible = false
	add_child(say_panel)

	fade = ColorRect.new()
	fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fade.color = Color(0, 0, 0, 0)
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(fade)
	cap_label = Label.new()
	cap_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	cap_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cap_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	cap_label.add_theme_font_size_override("font_size", 120)
	cap_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	cap_label.add_theme_constant_override("outline_size", 14)
	cap_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cap_label.visible = false
	add_child(cap_label)

	music = AudioStreamPlayer.new()
	music.bus = "Music"
	add_child(music)
	for i in 10:
		var p := AudioStreamPlayer.new()
		p.bus = "SFX"
		add_child(p)
		sfx_pool.append(p)
	reset("day")


func _init_tod() -> void:
	TOD = {
		"day": {"top": Color("4fb3ee"), "bot": Color("d2f0ff"), "sea1": Color("2fb0dc"), "sea2": Color("1b86c2"),
			"sand": Color("f3dc9c"), "tint": Color(0, 0, 0, 0), "sun": Vector2(1000, 110), "sunv": 1.0, "moon": 0.0, "stars": 0.0, "cloud": 1.0},
		"morning": {"top": Color("78b4e6"), "bot": Color("ffdcae"), "sea1": Color("46a8c8"), "sea2": Color("2a80ae"),
			"sand": Color("f2d9a4"), "tint": Color(1.0, 0.75, 0.45, 0.10), "sun": Vector2(1090, 255), "sunv": 1.0, "moon": 0.0, "stars": 0.0, "cloud": 1.0},
		"dusk": {"top": Color("5a5aa8"), "bot": Color("ff9a5c"), "sea1": Color("4b7fb0"), "sea2": Color("263f7a"),
			"sand": Color("e8c690"), "tint": Color(0.6, 0.25, 0.1, 0.13), "sun": Vector2(250, 290), "sunv": 1.0, "moon": 0.0, "stars": 0.0, "cloud": 0.8},
		"night": {"top": Color("0b1030"), "bot": Color("26336a"), "sea1": Color("16305e"), "sea2": Color("0c1d42"),
			"sand": Color("b6a77e"), "tint": Color(0.02, 0.04, 0.18, 0.38), "sun": Vector2(250, 360), "sunv": 0.0, "moon": 1.0, "stars": 1.0, "cloud": 0.15},
		"storm": {"top": Color("3c4456"), "bot": Color("7d8798"), "sea1": Color("3d5d7a"), "sea2": Color("2a455f"),
			"sand": Color("d3c08c"), "tint": Color(0.0, 0.03, 0.12, 0.26), "sun": Vector2(1000, 110), "sunv": 0.0, "moon": 0.0, "stars": 0.0, "cloud": 0.0},
	}


# ------------------------------------------------------------------ 状態
func reset(time_name: String = "day", black: bool = false) -> void:
	h = {"p": Vector2(640, 520), "s": 1.0, "flip": false, "expr": "normal", "arm_l": 8.0, "arm_r": 8.0,
		"sit": false, "moving": false, "walk": 0.0, "beard": 0.0, "age": 0.0, "thin": 0.0, "rag": 0.0,
		"halo": 0.0, "arms_free": true, "look": Vector2.ZERO, "t": 0.0, "bob": 0.0}
	v = {}
	tod = (TOD[time_name] as Dictionary).duplicate()
	tick_fn = Callable()
	back_fn = Callable()
	front_fn = Callable()
	glow_fn = Callable()
	fx_fn = Callable()
	hero_visible = true
	island = true
	floaters.clear()
	parts.clear()
	cam_y = 0.0
	say_panel.visible = false
	cap_label.visible = false
	fade.color.a = 1.0 if black else 0.0


func speed_mult() -> float:
	var m: float = opts.fast
	if active and (Input.is_key_pressed(KEY_SPACE) or Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)):
		m *= 3.0
	return m


func _process(dt: float) -> void:
	t += dt
	var sdt := dt * speed_mult()
	clock += sdt
	h.t = t
	h.bob = sin(t * 3.0) * 1.5
	if tick_fn.is_valid():
		tick_fn.call(sdt)
	for f in floaters:
		f.life -= sdt
		f.pos += f.vel * sdt
	floaters = floaters.filter(func(f): return f.life > 0.0)
	for p in parts:
		p.life -= sdt
		p.vel.y += 520.0 * sdt
		p.pos += p.vel * sdt
	parts = parts.filter(func(p): return p.life > 0.0)
	world.position.y = cam_y
	glow.position.y = cam_y
	tint.color = tod.tint
	sky.queue_redraw()
	world.queue_redraw()
	glow.queue_redraw()
	fx.queue_redraw()


# ------------------------------------------------------------------ 待ち・補間（中断されたら即抜ける）
func wait(sec: float) -> void:
	var el := 0.0
	while el < sec and not aborted:
		await get_tree().process_frame
		el += get_process_delta_time() * speed_mult()


func anim(d: Dictionary, key: String, to: float, dur: float) -> void:
	var from: float = d.get(key, 0.0)
	var el := 0.0
	while el < dur and not aborted:
		await get_tree().process_frame
		el += get_process_delta_time() * speed_mult()
		var k := clampf(el / dur, 0.0, 1.0)
		k = k * k * (3.0 - 2.0 * k)
		d[key] = lerpf(from, to, k)
	d[key] = to


func move(to: Vector2, dur: float, face: bool = true) -> void:
	var from: Vector2 = h.p
	if face and absf(to.x - from.x) > 1.0:
		h.flip = to.x < from.x
	h.moving = true
	var el := 0.0
	while el < dur and not aborted:
		await get_tree().process_frame
		var d := get_process_delta_time() * speed_mult()
		el += d
		h.walk += d * 11.0
		h.p = from.lerp(to, clampf(el / dur, 0.0, 1.0))
	h.p = to
	h.moving = false


func set_time(name: String, dur: float = 0.0) -> void:
	var to: Dictionary = TOD[name]
	var from := tod.duplicate()
	var el := 0.0
	while el < dur and not aborted:
		await get_tree().process_frame
		el += get_process_delta_time() * speed_mult()
		var k := clampf(el / dur, 0.0, 1.0)
		for key in to:
			tod[key] = lerp(from[key], to[key], k)
	tod = to.duplicate()


func time_now(name: String) -> void:
	tod = (TOD[name] as Dictionary).duplicate()


func fade_to(a: float, dur: float) -> void:
	var from := fade.color.a
	var el := 0.0
	while el < dur and not aborted:
		await get_tree().process_frame
		el += get_process_delta_time() * speed_mult()
		fade.color.a = lerpf(from, a, clampf(el / dur, 0.0, 1.0))
	fade.color.a = a


# ------------------------------------------------------------------ 字幕・テロップ
func say(text: String, hold: float = -1.0) -> void:
	say_label.text = text
	say_panel.visible = true
	sfx("blip", -12.0)
	if hold < 0.0:
		hold = 0.8 + float(text.length()) * 0.085
	await wait(hold)


func clear_say() -> void:
	say_panel.visible = false


## 画面を暗くして時間経過テロップを出す。暗い間に fn で状態を書き換える。
func jump(text: String, fn: Callable = Callable(), hold: float = 1.5) -> void:
	sfx("skip", -4.0)
	say_panel.visible = false
	await fade_to(0.8, 0.3)
	cap_label.text = text
	cap_label.visible = true
	await wait(hold * 0.45)
	if fn.is_valid():
		fn.call()
	await wait(hold * 0.55)
	cap_label.visible = false
	await fade_to(0.0, 0.4)


func float_text(text: String, pos: Vector2, col: Color = Color.WHITE, size: int = 44, life: float = 1.3, vel: Vector2 = Vector2(0, -36)) -> void:
	floaters.append({"text": text, "pos": pos, "vel": vel, "life": life, "max": life, "size": size, "col": col, "star": false})


func float_star(pos: Vector2, size: float = 40.0, life: float = 0.8) -> void:
	floaters.append({"text": "", "pos": pos, "vel": Vector2(0, -10), "life": life, "max": life, "size": int(size), "col": Color.WHITE, "star": true})


func burst(pos: Vector2, col: Color, n: int, spd: float) -> void:
	for i in n:
		var a := randf_range(-PI * 0.95, -PI * 0.05)
		parts.append({"pos": pos, "vel": Vector2(cos(a), sin(a)) * spd * randf_range(0.4, 1.0), "life": randf_range(0.4, 0.8), "col": col, "size": randf_range(3.0, 6.0)})


func w2s(p: Vector2) -> Vector2:
	return p + Vector2(0, cam_y)


# ------------------------------------------------------------------ 主人公まわり
func hand(side: int) -> Vector2:
	var P := Art.hero_pts(h)
	return Art.to_world(h, P.hr if side == 1 else P.hl)


func hl(local: Vector2) -> Vector2:
	return Art.to_world(h, local)


func dir() -> float:
	return -1.0 if h.flip else 1.0


# ------------------------------------------------------------------ 音
func sfx(n: String, db: float = 0.0, pitch: float = 1.0) -> void:
	if opts.mute:
		return
	if not sfx_cache.has(n):
		var p := "res://audio/%s.wav" % n
		sfx_cache[n] = load(p) if ResourceLoader.exists(p) else null
	var st: AudioStream = sfx_cache[n]
	if st == null:
		return
	var pl := sfx_pool[_sfx_i]
	_sfx_i = (_sfx_i + 1) % sfx_pool.size()
	pl.stream = st
	pl.volume_db = db
	pl.pitch_scale = pitch
	pl.play()


func play_music() -> void:
	if music.playing or opts.mute:
		return
	var p := "res://audio/bgm.wav"
	if not ResourceLoader.exists(p):
		return
	var st := (load(p) as AudioStreamWAV).duplicate() as AudioStreamWAV
	st.loop_mode = AudioStreamWAV.LOOP_FORWARD
	st.loop_begin = 0
	st.loop_end = st.data.size() / 2
	music.stream = st
	music.volume_db = 0.0
	music.play()


func music_db(db: float, dur: float) -> void:
	create_tween().tween_property(music, "volume_db", db, dur)


# ------------------------------------------------------------------ 描画
func _draw_sky() -> void:
	var hy := HORIZON + cam_y + 20.0
	var top: Color = tod.top
	var bot: Color = tod.bot
	sky.draw_polygon(PackedVector2Array([Vector2(0, 0), Vector2(SW, 0), Vector2(SW, hy), Vector2(0, hy)]), PackedColorArray([top, top, bot, bot]))
	var stars: float = tod.stars
	if stars > 0.02:
		for i in 60:
			var x := fmod(float(i) * 197.3, SW)
			var y := fmod(float(i) * 83.7, maxf(HORIZON + cam_y - 20.0, 200.0))
			var tw := 0.6 + 0.4 * sin(t * 2.0 + float(i))
			sky.draw_circle(Vector2(x, y), 1.8 + fmod(float(i), 3.0) * 0.5, Color(1, 1, 0.9, stars * tw))
	var sunv: float = tod.sunv
	var sp: Vector2 = tod.sun
	if sunv > 0.02:
		var sc := Vector2(sp.x, sp.y)
		for i in 4:
			sky.draw_circle(sc, 90.0 - i * 18.0, Color(1.0, 0.9, 0.55, 0.10 * sunv))
		sky.draw_circle(sc, 46.0, Color(1.0, 0.95, 0.6, sunv))
	var moon: float = tod.moon
	if moon > 0.02:
		var mp := Vector2(200, 120)
		sky.draw_circle(mp, 62.0, Color(0.9, 0.95, 1.0, 0.10 * moon))
		sky.draw_circle(mp, 36.0, Color(1.0, 1.0, 0.88, moon))
		sky.draw_circle(mp + Vector2(14, -8), 31.0, Color(top.r, top.g, top.b, moon))
	var cl: float = tod.cloud
	if cl > 0.02:
		var cc := Color(1, 1, 1, 1).lerp(Color(bot.r, bot.g, bot.b, 1), 0.2 + 0.8 * (1.0 - cl))
		for i in 4:
			var x := fmod(float(i) * 390.0 + t * (6.0 + i * 2.0), SW + 300.0) - 150.0
			Art.cloud(sky, Vector2(x, 70.0 + (i % 3) * 52.0 + fmod(float(i) * 31.0, 30.0)), 1.0 + (i % 2) * 0.3, cc)


func _draw_world() -> void:
	var w := world
	var s1: Color = tod.sea1
	var s2: Color = tod.sea2
	w.draw_polygon(PackedVector2Array([Vector2(0, HORIZON), Vector2(SW, HORIZON), Vector2(SW, 780), Vector2(0, 780)]), PackedColorArray([s1, s1, s2, s2]))
	w.draw_rect(Rect2(0, 780, SW, 1200), s2)
	w.draw_rect(Rect2(0, HORIZON - 2, SW, 5), Color(1, 1, 1, 0.25))
	var sunv: float = tod.sunv
	var sp: Vector2 = tod.sun
	if sunv > 0.1 and sp.y > 200.0:
		for i in 7:
			var ww := 150.0 - i * 16.0
			w.draw_rect(Rect2(sp.x - ww * 0.5 + sin(t * 1.5 + i) * 6.0, HORIZON + 8 + i * 15, ww, 4), Color(1.0, 0.95, 0.7, 0.35 * sunv))
	for i in 16:
		var x := fmod(float(i) * 173.0 + t * (10.0 + (i % 3) * 4.0), SW + 140.0) - 70.0
		var y := HORIZON + 24.0 + fmod(float(i) * 47.0, 420.0)
		var ww := 18.0 + (y - HORIZON) * 0.07
		w.draw_arc(Vector2(x, y), ww, PI * 1.15, PI * 1.85, 8, Color(1, 1, 1, 0.34), 2.5)
	if island:
		Art.ellipse(w, Vector2(640, 545), 650.0, 178.0, Color(s1.r + 0.12, s1.g + 0.1, s1.b + 0.05, 0.55), 48)
		Art.ellipse(w, Vector2(640, 545), 622.0, 162.0, Color(1, 1, 1, 0.55), 48)
		var sand: Color = tod.sand
		Art.ellipse(w, Vector2(640, 545), 608.0, 152.0, sand.darkened(0.12), 48)
		Art.ellipse(w, Vector2(640, 540), 600.0, 146.0, sand, 48)
		for i in 40:
			var x := 120.0 + fmod(float(i) * 131.7, 1040.0)
			var y := 410.0 + fmod(float(i) * 57.3, 230.0)
			var dx := (x - 640.0) / 590.0
			var dy := (y - 540.0) / 135.0
			if dx * dx + dy * dy < 0.9:
				w.draw_circle(Vector2(x, y), 2.5, Color(0.6, 0.5, 0.3, 0.25))
		for pm in PALMS:
			var q: Vector3 = pm
			if not v.get("no_palm_%d" % int(q.x), false):
				Art.palm(w, Vector2(q.x, q.y), q.z, -0.1 if q.x < 640.0 else 0.1, t, float(v.get("lv_%d" % int(q.x), 1.0)))
	if back_fn.is_valid():
		back_fn.call(w)
	if hero_visible:
		Art.hero(w, h)
	if front_fn.is_valid():
		front_fn.call(w)


func _draw_glow() -> void:
	if glow_fn.is_valid():
		glow_fn.call(glow)


func _draw_fx() -> void:
	var rain: float = v.get("rain", 0.0)
	if rain > 0.01:
		for i in 170:
			var x := fmod(float(i) * 97.3 + t * 260.0, SW + 140.0) - 70.0
			var y := fmod(float(i) * 61.7 + t * 1000.0, SH + 80.0) - 40.0
			fx.draw_line(Vector2(x, y), Vector2(x - 14, y + 34), Color(0.8, 0.9, 1.0, 0.45 * rain), 2.0)
	if fx_fn.is_valid():
		fx_fn.call(fx)
	for p in parts:
		var a := clampf(p.life * 3.0, 0.0, 1.0)
		var col: Color = p.col
		fx.draw_rect(Rect2(p.pos - Vector2(p.size, p.size) * 0.5, Vector2(p.size, p.size)), Color(col.r, col.g, col.b, a))
	for f in floaters:
		var age: float = f.max - f.life
		var a := clampf(f.life / (f.max * 0.4), 0.0, 1.0)
		var pop := clampf(age / 0.14, 0.4, 1.0)
		if f.star:
			Art.sparkle(fx, f.pos, float(f.size) * pop, Color(1, 1, 0.8, a))
		else:
			var col: Color = f.col
			Art.ctext(fx, f.text, f.pos, int(float(f.size) * pop), Color(col.r, col.g, col.b, a), 8, Color(0.1, 0.08, 0.05, a * 0.9), 700.0)
	var fl: float = v.get("flash", 0.0)
	if fl > 0.01:
		fx.draw_rect(Rect2(0, 0, SW, SH), Color(1, 1, 1, fl))
