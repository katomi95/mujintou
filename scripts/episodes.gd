class_name Episodes
extends RefCounted
## 10 本のエピソード。どれも「まともな選択肢を、まともに使わない」。
## 共通の作法: _open で暗転から入り、_end で暗転して終わる。時間が飛ぶほどくだらなくする。

var S: Stage

const FIRE := Vector2(780, 515)
const FISH_L := Vector2(940, 410)
const TENT := Vector2(660, 520)
const SUMMIT := Vector2(350, 190)
const TOWER_X := 360.0
const GOLD_P := Vector2(710, 548)
const ROCK_P := Vector2(900, 548)
const FISH := [
	["タイ", Color("e8584f"), 1.1],
	["アジ", Color("8fb4d8"), 0.9],
	["サバ", Color("4f9aa0"), 1.0],
	["キス", Color("e7d38a"), 0.8],
	["イワシ", Color("b9c9d6"), 0.7],
]


func _init(stage: Stage) -> void:
	S = stage


func run(i: int) -> void:
	match i:
		0: await ep_knife()
		1: await ep_lighter()
		2: await ep_rod()
		3: await ep_tent()
		4: await ep_phone()
		5: await ep_book()
		6: await ep_food()
		7: await ep_satphone()
		8: await ep_gold()
		9: await ep_gun()


# ------------------------------------------------------------------ 共通
func _open(time_name: String = "day") -> void:
	S.reset(time_name, true)
	S.sfx("pop", -6.0)
	await S.fade_to(0.0, 0.5)


func _end(hold: float = 1.2) -> void:
	await S.wait(hold)
	S.clear_say()
	await S.fade_to(1.0, 0.8)


func _head() -> Vector2:
	return S.w2s(S.hl(Vector2(0, -150)))


func _arms(l: float, r: float) -> void:
	S.h.arm_l = l
	S.h.arm_r = r


func _held(c: CanvasItem, id: String, side: int, sz: float, off: Vector2 = Vector2.ZERO, rot: float = 0.0) -> void:
	var d := S.dir()
	Art.item(c, id, S.hand(side) + Vector2(off.x * d, off.y) * sz, sz, rot * d, d)


# ================================================================== 1. ナイフ
func ep_knife() -> void:
	await _open()
	S.v = {"dolls": 0.0, "seen": 0, "last": 0.0, "carve": false, "cd": 0.0}
	_make_dolls()
	S.back_fn = _knife_back
	S.front_fn = _knife_front
	S.tick_fn = _knife_tick
	S.h.p = Vector2(640, 500)
	_arms(8.0, 95.0)
	await S.say("ナイフか。いいね。", 1.5)
	S.h.expr = "smile"
	await S.say("まずは、木を……", 1.3)
	await _carve(3.0)
	S.v.dolls = 1.0
	S.sfx("ding")
	S.h.expr = "joy"
	await S.say("できた。一体目。", 1.4)
	await _carve(1.8)
	S.v.dolls = 2.0
	S.sfx("ding")
	S.h.expr = "joy"
	await S.say("二体目。", 0.9)
	for n in [3.0, 4.0, 5.0, 6.0]:
		await _carve(0.55)
		S.v.dolls = n
	await S.jump("一週間後", func(): S.v.dolls = 14.0)
	S.v.carve = true
	S.h.expr = "serious"
	S.anim(S.v, "dolls", 40.0, 3.5)
	await S.wait(3.5)
	await S.jump("三ヶ月後", func(): S.v.dolls = 60.0)
	S.anim(S.v, "dolls", 170.0, 3.5)
	await S.wait(3.5)
	S.v.carve = false
	_arms(8.0, 8.0)
	S.h.expr = "smile"
	await S.say("これで寂しくない", 2.6)
	await _end(1.0)


func _carve(sec: float) -> void:
	S.v.carve = true
	S.h.expr = "serious"
	await S.wait(sec)
	S.v.carve = false
	_arms(8.0, 95.0)
	S.h.expr = "smile"


func _make_dolls() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var pts: Array = [Vector2(520, 535), Vector2(770, 535)]
	var rest: Array = []
	var tries := 0
	while rest.size() < 168 and tries < 8000:
		tries += 1
		var x := rng.randf_range(70.0, 1210.0)
		var y := rng.randf_range(420.0, 665.0)
		var dx := (x - 640.0) / 585.0
		var dy := (y - 540.0) / 140.0
		if dx * dx + dy * dy > 1.0:
			continue
		var p := Vector2(x, y)
		if p.distance_to(Vector2(640, 520)) < 95.0:
			continue
		var ok := true
		for q in pts:
			if (q as Vector2).distance_to(p) < 33.0:
				ok = false
				break
		if ok:
			pts.append(p)
			rest.append(p)
	var first: Array = pts.slice(0, 2)
	rest.sort_custom(func(a, b): return (a as Vector2).distance_to(Vector2(640, 520)) < (b as Vector2).distance_to(Vector2(640, 520)))
	var all: Array = first + rest
	var order: Array = range(all.size())
	order.sort_custom(func(a, b): return (all[a] as Vector2).y < (all[b] as Vector2).y)
	S.v.doll_pos = all
	S.v.doll_order = order


func _draw_dolls(c: CanvasItem, front: bool) -> void:
	var n := int(S.v.dolls)
	var all: Array = S.v.doll_pos
	var order: Array = S.v.doll_order
	for i in order:
		if i >= n:
			continue
		var p: Vector2 = all[i]
		if (p.y > S.h.p.y) != front:
			continue
		var pop := clampf(1.0 - (float(i) - float(n) + 6.0) * 0.0, 0.0, 1.0)
		Art.doll(c, p, 0.4 * pop, S.t + float(i))


func _knife_back(c: CanvasItem) -> void:
	_draw_dolls(c, false)


func _knife_front(c: CanvasItem) -> void:
	_draw_dolls(c, true)
	var hl := S.hand(0)
	var d := S.dir()
	Art.rrect(c, Rect2(hl.x - 14, hl.y - 40, 28, 52), 6, Art.WOOD)
	Art.ellipse(c, Vector2(hl.x, hl.y - 40), 14.0, 5.0, Art.WOOD_D)
	Art.item(c, "knife", S.hand(1) + Vector2(22.0 * d, -4.0), 0.5, -0.5 * d, d)


func _knife_tick(dt: float) -> void:
	var v: Dictionary = S.v
	if v.carve:
		S.h.arm_r = 100.0 + sin(S.t * 16.0) * 18.0
		S.h.arm_l = 80.0
		v.cd -= dt
		if v.cd <= 0.0:
			v.cd = 0.17
			S.sfx("chop", -10.0, randf_range(0.9, 1.15))
			S.burst(S.w2s(S.hand(0)), Color("e8c088"), 3, 120.0)
	else:
		S.h.arm_l = 80.0
	var n := int(v.dolls)
	if n > int(v.seen):
		v.seen = n
		if S.t - float(v.last) > 0.06:
			v.last = S.t
			S.sfx("pop", -14.0, 1.0 + randf() * 0.5)


# ================================================================== 2. ライター
func ep_lighter() -> void:
	await _open()
	S.v = {"fire": 0.0, "fire_t": 0.0, "lighter": true, "flame": false, "carry": false, "benches": false, "cd": 0.0}
	S.back_fn = _fire_back
	S.front_fn = _fire_front
	S.glow_fn = _fire_glow
	S.tick_fn = _fire_tick
	S.h.p = Vector2(420, 520)
	_arms(8.0, 100.0)
	await S.say("ライターか。いいね。", 1.4)
	await S.say("焚き火でも起こすか。", 1.3)
	await S.move(Vector2(650, 520), 1.2)
	S.sfx("flick")
	await S.wait(0.45)
	S.v.flame = true
	await S.wait(0.5)
	S.v.fire_t = 0.7
	S.sfx("crackle")
	S.float_text("ボッ", S.w2s(FIRE + Vector2(0, -130)), Color("ffb040"), 64)
	S.h.expr = "smile"
	await S.say("よし、点いた。", 1.3)
	S.v.flame = false
	S.v.lighter = false
	S.h.expr = "burn"
	_arms(8.0, 8.0)
	await S.say("火を、絶やしてはいけない。", 2.0)
	await _trip(0.7)
	await S.say("ごはん？ あとだ。薪だ。", 1.7)
	await _trip(0.7)
	await S.jump("三日後", func(): S.v.fire_t = 2.2; S.v.benches = true; S.time_now("dusk"))
	await _trip(0.6)
	await S.say("火は、消えていない。", 1.5)
	await S.jump("一ヶ月後", func(): S.v.fire_t = 3.8; S.time_now("night"))
	await _trip(0.8, 0.6)
	await S.jump("一年後", func(): S.v.fire_t = 7.0; S.h.s = 0.8; S.h.p = Vector2(560, 535))
	await S.wait(1.4)
	S.h.expr = "smile"
	_arms(8.0, 165.0)
	await S.say("よし。今日も火は消えていない", 2.8)
	await _end(1.2)


func _trip(add: float, dur: float = 0.8) -> void:
	_arms(15.0, 15.0)
	S.h.arms_free = false
	await S.move(Vector2(250, 540) if S.h.s > 0.9 else Vector2(200, 550), dur)
	S.v.carry = true
	_arms(125.0, 125.0)
	await S.move(Vector2(650, 520) if S.h.s > 0.9 else Vector2(560, 535), dur)
	S.v.carry = false
	S.sfx("whoosh", -4.0)
	_arms(170.0, 170.0)
	S.v.fire_t += add
	S.sfx("crackle")
	S.burst(S.w2s(FIRE + Vector2(0, -60)), Color("ffa030"), 12, 280.0)
	await S.wait(0.2)
	S.h.arms_free = true
	_arms(8.0, 8.0)


func _fire_tick(dt: float) -> void:
	var v: Dictionary = S.v
	v.fire = lerpf(v.fire, v.fire_t, minf(1.0, dt * 2.5))
	v.cd -= dt
	if v.cd <= 0.0 and v.fire > 0.05:
		v.cd = 1.1
		S.sfx("crackle", -14.0 - 0.0, randf_range(0.85, 1.1))


func _fire_back(c: CanvasItem) -> void:
	var v: Dictionary = S.v
	var f: float = v.fire
	if v.benches:
		var off := 120.0 + 22.0 * minf(f, 6.0)
		for sgn in [-1.0, 1.0]:
			Art.rrect(c, Rect2(FIRE.x + sgn * off - 55, FIRE.y + 22, 110, 24), 10, Art.WOOD_D)
			Art.ellipse(c, Vector2(FIRE.x + sgn * off + sgn * 55, FIRE.y + 34), 8.0, 12.0, Art.WOOD)
	if f < 0.05:
		for k in 5:
			c.draw_line(FIRE + Vector2(-26 + k * 8, 10), FIRE + Vector2(-8 + k * 10, -8), Art.WOOD_D, 7.0)
	else:
		Art.campfire(c, FIRE, f, S.t)


func _fire_front(c: CanvasItem) -> void:
	var v: Dictionary = S.v
	if v.lighter:
		_held(c, "lighter", 1, 0.55, Vector2(0, -18))
		if v.flame:
			Art.flame(c, S.hand(1) + Vector2(0, -50) * S.h.s, 8.0, 26.0, S.t, 0.0)
	if v.carry:
		var a := S.hand(0)
		var b := S.hand(1)
		c.draw_line(a + Vector2(-34, 6), b + Vector2(34, -10), Art.WOOD_D, 9.0)
		c.draw_line(a + Vector2(10, -2), a + Vector2(36, -32), Color("4a8f3a"), 5.0)
		c.draw_line(a + Vector2(-8, 0), a + Vector2(-30, -26), Color("4a8f3a"), 5.0)


func _fire_glow(c: CanvasItem) -> void:
	var f: float = S.v.fire
	if f < 0.05:
		return
	var rad := 140.0 + 120.0 * minf(f, 7.0)
	var ctr := FIRE + Vector2(0, -20.0 * minf(f, 5.0))
	var fl := 1.0 + sin(S.t * 9.0) * 0.05
	for k in 8:
		var rr := rad * float(k + 1) / 8.0 * fl
		var a := 0.05 * float(8 - k) / 8.0 * minf(1.0, f / 2.0 + 0.3)
		c.draw_circle(ctr, rr, Color(1.0, 0.55, 0.15, a))


# ================================================================== 3. 釣り竿
func ep_rod() -> void:
	await _open()
	S.v = {"fs": 0, "fu": 0.0, "kind": 0, "dip": 0.0, "dip_t": 0.0, "rip": 0.0, "sx": -999.0, "ssz": 1.0}
	S.back_fn = _rod_back
	S.front_fn = _rod_front
	S.tick_fn = _rod_tick
	S.h.p = Vector2(500, 520)
	_arms(60.0, 105.0)
	await S.say("釣り竿か。魚が釣れれば安泰だな。", 2.3)
	await S.wait(0.8)
	await _catch(0)
	S.h.expr = "joy"
	await S.say("おっ、釣れた！", 1.1)
	S.h.expr = "blank"
	await S.say("違う。あいつじゃない。", 1.8)
	await _release()
	S.h.expr = "normal"
	await S.wait(0.4)
	await _shadow(4.5, 1.0, "……いたな。")
	await _catch(1)
	await S.say("こいつでもない。", 1.5)
	await _release()
	await _growl()
	for k in [2, 3, 4]:
		await _catch(k)
		await S.say("違う", 0.6)
		await _release()
	await _growl()
	await S.jump("三日後", func(): S.h.thin = 0.3; S.time_now("dusk"))
	await _catch(0)
	await S.say("これでもない。", 1.2)
	await _release()
	await _shadow(4.0, 1.4, "……近いな。")
	await _growl()
	await S.jump("一ヶ月後", func(): S.h.thin = 0.65; S.time_now("night"); S.h.sit = true; S.h.p = Vector2(520, 535))
	S.h.expr = "hungry"
	await S.wait(1.2)
	await _growl()
	await _catch(2)
	await S.say("違う。", 1.0)
	await _release()
	await _shadow(4.0, 1.8)
	S.h.expr = "burn"
	S.v.rip = 1.0
	S.sfx("whoosh", -10.0, 0.6)
	await S.wait(1.0)
	await S.say("いつか必ず、あいつを釣る", 2.8)
	await _end(1.2)


func _shadow(dur: float, sz: float, line: String = "") -> void:
	S.v.ssz = sz
	S.v.sx = -400.0
	S.h.look = Vector2(1.0, -0.4)
	S.sfx("whoosh", -10.0, 0.5)
	S.anim(S.v, "sx", 1700.0, dur)
	S.h.expr = "shock"
	await S.wait(1.2)
	if line != "":
		await S.say(line, 1.6)
		S.clear_say()
		await S.wait(maxf(0.0, dur - 2.8))
	else:
		await S.wait(dur - 1.2)
	S.h.look = Vector2.ZERO
	S.h.expr = "normal"


func _catch(kind: int) -> void:
	S.v.dip_t = 1.0
	S.sfx("splash", -6.0)
	S.float_text("ピクッ", S.w2s(FISH_L + Vector2(0, -50)), Color.WHITE, 40, 0.8)
	await S.wait(0.5)
	S.h.arm_r = 160.0
	S.sfx("whoosh")
	S.v.kind = kind
	S.v.fs = 1
	S.v.fu = 0.0
	S.v.dip_t = 0.0
	S.h.arm_l = 90.0
	await S.wait(0.6)
	var fk: Array = FISH[kind]
	S.float_text(fk[0], S.w2s(S.hand(0) + Vector2(0, -80)), Color("ffe9a0"), 36, 1.0)
	S.h.arm_r = 105.0


func _release() -> void:
	S.v.fs = 3
	S.v.fu = 0.0
	await S.wait(0.6)
	S.sfx("splash", -4.0)
	S.burst(S.w2s(FISH_L), Color("bfe6ff"), 10, 240.0)
	S.h.arm_l = 60.0


func _growl() -> void:
	S.sfx("growl")
	var keep: String = S.h.expr
	S.h.expr = "hungry"
	S.float_text("ぐぅ～", _head() + Vector2(60, -10), Color("ffd8a0"), 60, 1.4)
	await S.wait(1.2)
	S.h.expr = keep


func _fish_pos() -> Vector2:
	var v: Dictionary = S.v
	var u: float = v.fu
	if v.fs == 1:
		return FISH_L.lerp(S.hand(0), u) - Vector2(0, sin(u * PI) * 150.0)
	if v.fs == 3:
		return S.hand(0).lerp(FISH_L, u) - Vector2(0, sin(u * PI) * 150.0)
	return S.hand(0) + Vector2(0, 30)


func _rod_tick(dt: float) -> void:
	var v: Dictionary = S.v
	v.dip = lerpf(v.dip, v.dip_t, minf(1.0, dt * 8.0))
	if v.fs == 1 or v.fs == 3:
		v.fu = minf(float(v.fu) + dt / 0.55, 1.0)
		if v.fu >= 1.0:
			v.fs = 2 if v.fs == 1 else 0


func _rod_back(c: CanvasItem) -> void:
	var sx: float = S.v.sx
	if sx > -500.0 and sx < 1750.0:
		var z: float = S.v.ssz
		var sp := Vector2(sx, 392.0 + 8.0 * z)
		Art.ellipse(c, sp, 190.0 * z, 30.0 * z, Color(0.04, 0.12, 0.25, 0.42), 28)
		c.draw_colored_polygon(PackedVector2Array([sp + Vector2(-150, 0) * z, sp + Vector2(-260, -26) * z, sp + Vector2(-250, 26) * z]), Color(0.04, 0.12, 0.25, 0.42))
		c.draw_colored_polygon(PackedVector2Array([sp + Vector2(10, -20) * z, sp + Vector2(40, -62) * z, sp + Vector2(78, -20) * z]), Color(0.1, 0.16, 0.26, 0.9))
	var rip: float = S.v.rip
	if rip > 0.01:
		var ctr := Vector2(1030, 435)
		c.draw_set_transform(ctr, 0.0, Vector2(1.0, 0.28))
		for k in 3:
			var ph := fmod(S.t * 0.45 + float(k) * 0.33, 1.0)
			c.draw_arc(Vector2.ZERO, 25.0 + ph * 130.0, 0.0, TAU, 40, Color(1, 1, 1, (1.0 - ph) * 0.7 * rip), 4.0)
		Art.reset_tf(c)


func _rod_front(c: CanvasItem) -> void:
	var v: Dictionary = S.v
	var hr := S.hand(1)
	var d := S.dir()
	var hs: float = S.h.s
	var tip: Vector2 = hr + Vector2(92.0 * d, -108.0) * hs
	c.draw_line(hr + Vector2(-22.0 * d, 26.0) * hs, tip, Color("8a5a35"), 6.0)
	var fl: Vector2 = FISH_L + Vector2(0, float(v.dip) * 16.0 + sin(S.t * 2.0) * 2.0)
	var mid: Vector2 = (tip + fl) * 0.5 + Vector2(0, 46)
	var pts := PackedVector2Array()
	for i in 13:
		var u := float(i) / 12.0
		pts.append(tip.lerp(mid, u).lerp(mid.lerp(fl, u), u))
	c.draw_polyline(pts, Color(1, 1, 1, 0.8), 1.8)
	if v.fs == 0 or v.fs == 3 and false:
		c.draw_circle(fl + Vector2(0, -4), 8.0, Color("f2f2f2"))
		c.draw_arc(fl + Vector2(0, -4), 8.0, PI, TAU, 10, Color("e04040"), 8.0)
	if v.fs != 0:
		var fk: Array = FISH[v.kind]
		var u: float = v.fu
		var rot := u * TAU * 1.5 if v.fs != 2 else sin(S.t * 14.0) * 0.25
		Art.fish(c, _fish_pos(), fk[2], fk[1], false, rot)


# ================================================================== 4. テント
func ep_tent() -> void:
	await _open("dusk")
	S.v = {"tent": 0.0, "lit": 0.0, "patch": 0.0, "sign": false, "boat": -500.0, "label": "キャンプ 1日目",
		"hammer": false, "cd": 0.0, "zcd": 0.0, "zzz": false, "wave": false}
	S.back_fn = _tent_back
	S.glow_fn = _tent_glow
	S.fx_fn = _tent_fx
	S.tick_fn = _tent_tick
	S.h.p = Vector2(480, 525)
	S.v.sign = true
	S.sfx("pon")
	S.h.expr = "smile"
	await S.say("ここは……キャンプ場だな。", 2.2)
	await S.say("テントか。まずは設営だな。", 1.9)
	await _pitch(3.0)
	S.h.expr = "smile"
	await S.say("完成。いい感じだ。", 1.4)
	await _sleep(2.4)
	await _morning("キャンプ 2日目", true, 1.4)
	await _fold(2.0)
	await S.set_time("day", 0.8)
	await S.move(Vector2(300, 545), 1.0)
	await S.move(Vector2(520, 525), 1.0)
	await S.jump("夕方", func(): S.time_now("dusk"))
	await _pitch(1.4)
	await _sleep(1.2)
	await _morning("キャンプ 3日目", false, 0.9)
	await _fold(1.0)
	await S.jump("三週間後", func(): S.v.sign = true; S.time_now("dusk"); S.h.p = Vector2(480, 525))
	await _pitch(1.0)
	await _sleep(0.8)
	await _morning("キャンプ 22日目", false, 0.7)
	await _fold(0.8)
	await S.jump("二年後", func(): S.v.patch = 1.0; S.h.beard = 0.45; S.h.rag = 0.35; S.time_now("dusk"); S.h.p = Vector2(480, 525))
	await _pitch(0.9)
	await _sleep(0.7)
	await _morning("キャンプ 730日目", false, 0.6)
	S.h.expr = "smile"
	await S.say("遭難？ ただのキャンプだが？", 2.4)
	await S.say("ちょっと長めのキャンプだなあ", 2.6)
	await _end(1.0)


func _pitch(dur: float) -> void:
	S.float_text("チェックイン", _head() + Vector2(60, 0), Color("fff08a"), 44, 1.4)
	S.h.expr = "serious"
	S.v.hammer = true
	await S.anim(S.v, "tent", 1.0, dur)
	S.v.hammer = false
	_arms(8.0, 8.0)


func _sleep(dur: float) -> void:
	S.clear_say()
	await S.set_time("night", 1.0)
	await S.move(Vector2(660, 520), 0.8)
	S.hero_visible = false
	S.v.lit = 1.0
	S.v.zzz = true
	await S.wait(dur)
	S.v.zzz = false


func _morning(label: String, detailed: bool, hold: float) -> void:
	await S.set_time("morning", 0.9)
	S.v.lit = 0.0
	S.v.label = label
	S.hero_visible = true
	S.h.p = Vector2(660, 535)
	S.h.expr = "yawn"
	_arms(170.0, 170.0)
	S.sfx("whoosh", -8.0)
	await S.wait(0.7 if detailed else 0.4)
	_arms(8.0, 8.0)
	S.h.expr = "smile"
	await S.say("キャンプの朝だ。", hold)
	if detailed:
		S.v.boat = 1400.0
		S.anim(S.v, "boat", -250.0, 9.0)
		S.v.wave = true
		S.h.expr = "joy"
		await S.say("おはようございまーす！", 2.0)
		await S.say("お隣のキャンパーさんかな。", 2.2)
		S.v.wave = false
		_arms(8.0, 8.0)


func _fold(dur: float) -> void:
	S.float_text("チェックアウト", _head() + Vector2(60, 0), Color("fff08a"), 44, 1.4)
	await S.move(Vector2(520, 525), 0.4)
	S.h.expr = "serious"
	S.v.hammer = true
	await S.anim(S.v, "tent", 0.0, dur)
	S.v.hammer = false
	_arms(8.0, 8.0)
	S.h.expr = "smile"


func _tent_tick(dt: float) -> void:
	var v: Dictionary = S.v
	if v.hammer:
		S.h.arm_r = 105.0 + sin(S.t * 14.0) * 35.0
		S.h.arm_l = 20.0
		v.cd -= dt
		if v.cd <= 0.0:
			v.cd = 0.28
			S.sfx("thud", -8.0, randf_range(1.0, 1.3))
	if v.wave:
		S.h.arm_r = 150.0 + sin(S.t * 9.0) * 25.0
	if v.zzz:
		v.zcd -= dt
		if v.zcd <= 0.0:
			v.zcd = 0.7
			S.float_text("Z", S.w2s(TENT + Vector2(randf_range(-20, 40), -150)), Color("cfe6ff"), 52, 1.6, Vector2(24, -50))


func _tent_back(c: CanvasItem) -> void:
	var v: Dictionary = S.v
	var bx: float = v.boat
	if bx > -200.0 and bx < 1400.0:
		Art.boat(c, Vector2(bx, S.HORIZON + 8.0), 0.9)
	if v.sign:
		c.draw_line(Vector2(900, 505), Vector2(900, 440), Art.WOOD_D, 8.0)
		Art.rrect(c, Rect2(830, 408, 140, 44), 6, Art.WOOD)
		Art.ctext(c, "キャンプ場", Vector2(900, 440), 26, Color("5a3a1a"), 0, Color.BLACK, 140.0)
	Art.tent(c, TENT, v.tent, 1.0, v.lit, v.patch)


func _tent_glow(c: CanvasItem) -> void:
	var lit: float = S.v.lit
	if lit > 0.01 and float(S.v.tent) > 0.5:
		for k in 6:
			c.draw_circle(TENT + Vector2(0, -30), 40.0 + k * 34.0, Color(1.0, 0.8, 0.4, 0.06 * lit * float(6 - k) / 6.0))


func _tent_fx(c: CanvasItem) -> void:
	Art.ctext(c, S.v.label, Vector2(230, 70), 42, Color.WHITE, 8, Color(0.1, 0.1, 0.2, 0.8), 420.0)


# ================================================================== 5. スマートフォン
func ep_phone() -> void:
	await _open()
	S.v = {"phone": true, "hill": false, "tower": 0.0, "auto_cam": false, "cam_t": 0.0, "build": false, "cd": 0.0, "top": false, "top_pop": 0.0, "bar_on": false}
	S.fx_fn = _phone_fx
	S.back_fn = _phone_back
	S.front_fn = _phone_front
	S.tick_fn = _phone_tick
	S.h.p = Vector2(520, 520)
	_arms(8.0, 140.0)
	S.h.expr = "think"
	await S.say("スマホか。電波は……", 1.6)
	_nosignal()
	S.h.expr = "shock"
	await S.wait(0.9)
	S.h.expr = "normal"
	await S.say("場所が悪いだけだな。", 1.6)
	S.anim(S.h, "s", 0.8, 1.6)
	await S.move(Vector2(880, 430), 1.6)
	_arms(8.0, 170.0)
	_nosignal()
	await S.wait(1.0)
	S.h.expr = "think"
	await S.say("もう少し、高いところか", 1.7)
	S.anim(S.h, "s", 0.85, 1.0)
	await S.move(Vector2(1120, 475), 1.0)
	S.h.arms_free = false
	_arms(175.0, 175.0)
	await S.move(Vector2(1150, 300), 1.8)
	_arms(175.0, 150.0)
	_nosignal()
	S.h.expr = "shock"
	await S.say("木の上でも、圏外だ", 1.8)
	S.h.arms_free = true
	await S.jump("三日後", func(): S.v.hill = true; S.h.p = SUMMIT + Vector2(-34, 4); S.h.s = 0.6; _arms(8.0, 165.0); S.h.expr = "normal")
	_nosignal()
	S.h.expr = "shock"
	await S.say("山頂でも……圏外。", 1.8)
	await S.jump("一ヶ月後", func(): S.h.p = Vector2(430, 192); S.h.expr = "serious"; S.v.phone = false; S.v.build = true; S.v.auto_cam = true)
	await S.say("ここなら、スマホ台を建てられる", 2.0)
	await S.anim(S.v, "tower", 110.0, 2.4)
	await S.jump("半年後", func(): S.v.tower = 260.0)
	await S.anim(S.v, "tower", 450.0, 2.4)
	await S.jump("一年後", func():
		S.v.tower = 620.0
		S.v.build = false
		S.v.auto_cam = false
		S.v.cam_t = 700.0
		S.cam_y = 700.0
		S.h.s = 0.9
		S.h.p = Vector2(TOWER_X - 16.0, SUMMIT.y - 620.0)
		_arms(8.0, 8.0)
		S.h.expr = "smile")
	S.v.top = true
	S.sfx("pon")
	await S.wait(0.8)
	S.sfx("beep")
	await S.anim(S.v, "top_pop", 1.0, 0.35)
	await S.wait(1.0)
	S.v.bar_on = true
	S.sfx("chime", -4.0)
	S.h.expr = "shock"
	await S.wait(0.6)
	S.v.bar_on = false
	S.sfx("beep")
	await S.say("今、一瞬だけ一本立った！", 2.0)
	S.h.expr = "smile"
	await S.say("あと少しだな", 2.6)
	await _end(0.8)


func _nosignal() -> void:
	S.sfx("beep")
	S.float_text("圏外", S.w2s(S.hand(1) + Vector2(0, -90) * S.h.s), Color("ff9a9a"), 58, 1.2)


func _phone_tick(dt: float) -> void:
	var v: Dictionary = S.v
	if v.auto_cam:
		v.cam_t = maxf(0.0, float(v.tower) - 150.0)
	S.cam_y = lerpf(S.cam_y, v.cam_t, minf(1.0, dt * 3.0))
	if v.build:
		S.h.arm_l = 125.0 + sin(S.t * 6.0) * 28.0
		S.h.arm_r = S.h.arm_l
		v.cd -= dt
		if v.cd <= 0.0:
			v.cd = 0.55
			S.sfx("thud", -8.0, randf_range(0.7, 0.9))


func _phone_back(c: CanvasItem) -> void:
	var v: Dictionary = S.v
	if v.hill:
		Art.hill(c, SUMMIT, 470.0, 215.0)
	if float(v.tower) > 1.0:
		Art.tower(c, TOWER_X, SUMMIT.y, v.tower)
		if v.tower > 600.0:
			Art.rrect(c, Rect2(TOWER_X - 46, SUMMIT.y - float(v.tower) - 12, 92, 14), 5, Color("cfd3d8"))
	if v.top:
		Art.item(c, "phone", Vector2(TOWER_X + 62.0, SUMMIT.y - float(v.tower) - 66.0), 1.3, 0.12)


func _phone_fx(c: CanvasItem) -> void:
	var pop: float = S.v.top_pop
	if pop > 0.01:
		var sz := int(150.0 * (0.5 + 0.5 * pop))
		Art.ctext(c, "圏外", Vector2(820, 300), sz, Color("e8f4ff"), 16, Color(0.1, 0.25, 0.45, 0.9), 700.0)
		for i in 4:
			var on: bool = S.v.bar_on and i == 0
			var col := Color("5cff7a") if on else Color(1, 1, 1, 0.35)
			c.draw_rect(Rect2(740.0 + i * 34.0, 400.0 - (i + 1) * 16.0, 24, (i + 1) * 16.0), col)


func _phone_front(c: CanvasItem) -> void:
	var v: Dictionary = S.v
	if v.phone:
		_held(c, "phone", 1, 0.8, Vector2(0, -34))
	if v.build:
		var m: Vector2 = (S.hand(0) + S.hand(1)) * 0.5
		Art.ellipse(c, m + Vector2(0, -18), 24.0 * S.h.s, 18.0 * S.h.s, Color("9a9ea6"), 14)


# ================================================================== 6. 本
func ep_book() -> void:
	await _open()
	S.v = {"wear": 0.0, "pg": 0.0, "rate": 0.0, "label": "", "pgcd": 0.0, "stat": 0.0}
	S.back_fn = _book_back
	S.front_fn = _book_front
	S.tick_fn = _book_tick
	S.fx_fn = _book_fx
	S.h.p = Vector2(420, 535)
	S.h.sit = true
	_arms(75.0, 75.0)
	await S.say("本か。……難しそうな本だな。", 2.1)
	S.v.label = "1周目"
	S.v.rate = 1.1
	S.h.expr = "think"
	await S.wait(3.0)
	S.h.expr = "shock"
	S.float_text("？？？", _head() + Vector2(0, -20), Color.WHITE, 70, 1.4)
	await S.wait(1.3)
	S.v.rate = 0.0
	S.h.expr = "blank"
	S.h.look = Vector2.ZERO
	S.sfx("page", -4.0)
	await S.wait(1.5)
	await S.say("……もう一度読むか。", 1.8)
	S.v.label = "2周目"
	S.v.rate = 2.4
	S.h.expr = "think"
	await S.wait(2.4)
	await S.jump("十周目", func(): S.v.wear = 0.25; S.v.label = "10周目"; S.v.rate = 3.0; S.h.expr = "serious"; S.h.thin = 0.1)
	await S.wait(2.4)
	await S.jump("百周目", func(): S.v.wear = 0.55; S.v.label = "100周目"; S.v.rate = 3.4; S.h.expr = "think"; S.h.thin = 0.25; S.h.beard = 0.25)
	await S.wait(2.4)
	await S.jump("三年後", func(): S.v.wear = 0.95; S.v.label = "1000周目"; S.v.rate = 2.0; S.h.expr = "enlight"; S.h.thin = 0.4; S.h.beard = 0.7; S.h.rag = 0.7)
	S.anim(S.h, "halo", 1.0, 2.0)
	await S.wait(3.0)
	S.v.rate = 0.0
	await S.say("……なるほど。", 1.8)
	S.sfx("ding")
	S.anim(S.v, "stat", 1.0, 0.3)
	await S.wait(3.2)
	await _end(0.5)


func _book_tick(dt: float) -> void:
	var v: Dictionary = S.v
	var rate: float = v.rate
	if rate > 0.0:
		v.pg = fmod(float(v.pg) + dt * rate, 1.0)
		S.h.look = Vector2(sin(S.t * 5.0), 0.7)
		v.pgcd -= dt
		if v.pgcd <= 0.0:
			v.pgcd = 0.9 / rate
			S.sfx("page", -8.0, randf_range(0.9, 1.2))
	else:
		S.h.look = Vector2(0, 0.3)


func _book_back(c: CanvasItem) -> void:
	var wear: float = S.v.wear
	if wear > 0.4:
		Art.crab(c, Vector2(250, 590), 0.8, S.t)


func _book_front(c: CanvasItem) -> void:
	var v: Dictionary = S.v
	var wear: float = v.wear
	var ctr := S.hl(Vector2(50, -46))
	var cov := Color("7a2e2e").lerp(Color("4a3a30"), wear)
	var pap := Color("f6efd8").lerp(Color("d8c392"), wear)
	Art.rrect(c, Rect2(ctr.x - 66, ctr.y - 44, 132, 88), 5, cov)
	c.draw_rect(Rect2(ctr.x - 60, ctr.y - 38, 58, 76), pap)
	c.draw_rect(Rect2(ctr.x + 2, ctr.y - 38, 58, 76), pap)
	for i in 4:
		c.draw_line(Vector2(ctr.x - 52, ctr.y - 24 + i * 16), Vector2(ctr.x - 10, ctr.y - 24 + i * 16), Color(0.3, 0.25, 0.2, 0.35), 2.0)
		c.draw_line(Vector2(ctr.x + 10, ctr.y - 24 + i * 16), Vector2(ctr.x + 52, ctr.y - 24 + i * 16), Color(0.3, 0.25, 0.2, 0.35), 2.0)
	if float(v.rate) > 0.0:
		var w := cos(float(v.pg) * PI) * 58.0
		var x0 := ctr.x
		c.draw_colored_polygon(PackedVector2Array([Vector2(x0, ctr.y - 38), Vector2(x0 + w, ctr.y - 42), Vector2(x0 + w, ctr.y + 34), Vector2(x0, ctr.y + 38)]), pap.darkened(0.06))
	c.draw_line(Vector2(ctr.x, ctr.y - 40), Vector2(ctr.x, ctr.y + 40), Color(0.2, 0.15, 0.1, 0.6), 3.0)
	if wear > 0.2:
		c.draw_circle(ctr + Vector2(-34, 14), 9.0, Color(0.5, 0.35, 0.2, 0.4))
		c.draw_circle(ctr + Vector2(30, -18), 7.0, Color(0.5, 0.35, 0.2, 0.4))
	if wear > 0.5:
		c.draw_rect(Rect2(ctr.x - 66, ctr.y - 6, 22, 12), Color("e0d8b0"))
		c.draw_line(Vector2(ctr.x - 66, ctr.y), Vector2(ctr.x - 44, ctr.y), Color("b8a878"), 1.5)
	if wear > 0.8:
		c.draw_colored_polygon(PackedVector2Array([Vector2(ctr.x + 66, ctr.y + 44), Vector2(ctr.x + 40, ctr.y + 44), Vector2(ctr.x + 66, ctr.y + 20)]), Color(0.65, 0.78, 0.9, 0.0))
		for k in 3:
			var fx := ctr.x + 80.0 + k * 22.0 + sin(S.t * 2.0 + k) * 6.0
			c.draw_rect(Rect2(fx, ctr.y + 30 + fmod(S.t * 20.0 + k * 13.0, 40.0), 10, 8), pap)


func _book_fx(c: CanvasItem) -> void:
	var v: Dictionary = S.v
	if v.label != "":
		Art.ctext(c, v.label, Vector2(190, 74), 54, Color.WHITE, 9, Color(0.1, 0.1, 0.2, 0.8), 360.0)
	var st: float = v.stat
	if st > 0.01:
		var x := 700.0
		var y := 110.0
		var sc := 0.6 + st * 0.4
		Art.rrect(c, Rect2(x - 20, y - 56, 520, 190), 14, Color(0.05, 0.08, 0.15, 0.82 * st))
		Art.ctext(c, "知識　　★★★★★", Vector2(x + 240, y), int(38 * sc), Color(1, 1, 1, st), 0, Color.BLACK, 500.0)
		Art.ctext(c, "悟り　　　MAX", Vector2(x + 240, y + 50), int(38 * sc), Color(1, 0.95, 0.5, st), 0, Color.BLACK, 500.0)
		var blink := 0.7 + 0.3 * sin(S.t * 6.0)
		Art.ctext(c, "サバイバル能力　０", Vector2(x + 240, y + 104), int(38 * sc), Color(1, 0.45, 0.45, st * blink), 0, Color.BLACK, 500.0)


# ================================================================== 7. 食料一年分
func ep_food() -> void:
	await _open()
	S.v = {"crates": 12, "feast": false, "ration": false, "lines": ["朝：豆2粒", "昼：クラッカー1/4枚", "夜：水"], "plate": 0, "eat": false}
	S.back_fn = _food_back
	S.front_fn = _food_front
	S.tick_fn = _food_tick
	S.fx_fn = _food_fx
	S.h.p = Vector2(520, 520)
	S.sfx("thud")
	await S.wait(0.4)
	S.h.expr = "shock"
	await S.say("一年分もあるのか！", 1.6)
	S.h.expr = "joy"
	_arms(170.0, 170.0)
	await S.wait(0.8)
	_arms(8.0, 8.0)
	await S.jump("その夜", func(): S.time_now("night"); S.v.feast = true; S.v.crates = 10; S.v.eat = true)
	S.float_text("ガツガツ", _head() + Vector2(90, 0), Color("ffe08a"), 52, 1.4)
	S.sfx("tada", -6.0)
	await S.say("今夜は宴だ！", 1.6)
	await S.jump("翌朝", func(): S.time_now("morning"); S.v.crates = 8)
	S.float_text("モグモグ", _head() + Vector2(90, 0), Color("ffe08a"), 52, 1.4)
	await S.say("朝から豪華だ！", 1.5)
	await S.jump("昼", func(): S.time_now("day"); S.v.crates = 6)
	S.float_text("ワイワイ", _head() + Vector2(90, 0), Color("ffe08a"), 52, 1.4)
	await S.wait(1.4)
	await S.jump("数日後", func(): S.v.crates = 3; S.v.feast = false; S.v.eat = false; S.h.expr = "shock")
	S.sfx("beep")
	await S.say("……減りすぎでは？", 2.0)
	S.h.expr = "serious"
	S.v.ration = true
	S.sfx("pon")
	await S.say("配給制にしよう", 1.5)
	S.v.plate = 1
	S.sfx("pon")
	await S.say("朝：豆2粒", 1.5)
	S.v.plate = 2
	S.sfx("pon")
	await S.say("昼：クラッカー1/4枚", 1.9)
	S.v.plate = 3
	S.sfx("pon")
	await S.say("夜：水", 1.3)
	await S.jump("三ヶ月後", func(): S.h.thin = 0.6; S.h.expr = "hungry"; S.v.plate = 1; S.v.lines = ["朝：豆1粒", "昼：クラッカーの端", "夜：水の残り香"])
	S.sfx("growl", -4.0)
	await S.wait(1.2)
	S.h.expr = "smile"
	await S.say("計画的って、いいな……", 2.4)
	await _end(1.0)


func _food_tick(dt: float) -> void:
	if S.v.eat:
		S.h.arm_r = 120.0 + sin(S.t * 9.0) * 45.0
		S.h.arm_l = 100.0 + sin(S.t * 7.0) * 30.0


func _crate_pos(i: int) -> Vector2:
	var rows := [4, 3, 2, 2, 1]
	var idx := i
	for r in rows.size():
		var n: int = rows[r]
		if idx < n:
			return Vector2(100.0 + r * 47.0 + idx * 94.0, 545.0 - r * 62.0)
		idx -= n
	return Vector2.ZERO


func _food_back(c: CanvasItem) -> void:
	Art.food_label = "1ヶ月分"
	for i in int(S.v.crates):
		Art.item(c, "food", _crate_pos(i), 1.0)
	Art.food_label = "一年分"
	if S.v.feast:
		Art.rrect(c, Rect2(590, 548, 190, 18), 6, Art.WOOD_D)
		Art.rrect(c, Rect2(600, 566, 14, 40), 3, Art.WOOD_D)
		Art.rrect(c, Rect2(756, 566, 14, 40), 3, Art.WOOD_D)
		_dish(c, Vector2(625, 546), Color("c7792f"))
		_dish(c, Vector2(690, 546), Color("e04a5a"))
		_dish(c, Vector2(750, 546), Color("f0d060"))
		Art.ellipse(c, Vector2(690, 520), 22.0, 16.0, Color("f6e0b0"))
		c.draw_rect(Rect2(688, 494, 4, 14), Color("e04a5a"))
	elif S.v.ration:
		Art.rrect(c, Rect2(610, 548, 110, 14), 5, Art.WOOD_D)
		Art.rrect(c, Rect2(620, 562, 12, 40), 3, Art.WOOD_D)
		Art.rrect(c, Rect2(698, 562, 12, 40), 3, Art.WOOD_D)
		_board(c)


func _dish(c: CanvasItem, p: Vector2, col: Color) -> void:
	Art.ellipse(c, p + Vector2(0, 4), 30.0, 9.0, Color("f4f4f4"))
	Art.ellipse(c, p + Vector2(0, -2), 20.0, 14.0, col)


func _food_front(c: CanvasItem) -> void:
	var v: Dictionary = S.v
	if v.ration:
		var p := Vector2(665, 546)
		Art.ellipse(c, p + Vector2(0, 2), 40.0, 10.0, Color("f4f4f4"))
		Art.ellipse(c, p + Vector2(0, 1), 28.0, 6.0, Color("dcdcdc"))
		var plate: int = v.plate
		if plate == 1:
			c.draw_circle(p + Vector2(-7, -3), 4.2, Color("a0773a"))
			c.draw_circle(p + Vector2(7, -2), 4.2, Color("a0773a"))
		elif plate == 2:
			c.draw_rect(Rect2(p.x - 10, p.y - 12, 18, 14), Color("e8c888"))
			c.draw_line(Vector2(p.x - 10, p.y - 5), Vector2(p.x + 8, p.y - 5), Color("b89858"), 1.5)
		elif plate == 3:
			Art.rrect(c, Rect2(p.x - 11, p.y - 22, 22, 22), 4, Color("d8eef8"))
			c.draw_rect(Rect2(p.x - 9, p.y - 11, 18, 11), Color("7fc4ec"))


func _food_fx(_c: CanvasItem) -> void:
	pass


func _board(c: CanvasItem) -> void:
	var lines: Array = S.v.lines
	c.draw_line(Vector2(930, 430), Vector2(930, 500), Art.WOOD_D, 10.0)
	c.draw_line(Vector2(1170, 430), Vector2(1170, 500), Art.WOOD_D, 10.0)
	Art.rrect(c, Rect2(858, 250, 380, 190), 12, Color("c9a060"))
	Art.rrect(c, Rect2(866, 258, 364, 174), 8, Color("f6e8c4"))
	Art.ctext(c, "配給表", Vector2(1048, 300), 36, Color("5a3a1a"), 0, Color.BLACK, 360.0)
	for i in lines.size():
		Art.ctext(c, lines[i], Vector2(1048, 348 + i * 38), 26, Color("5a3a1a"), 0, Color.BLACK, 360.0)


# ================================================================== 8. 衛星電話
func ep_satphone() -> void:
	await _open()
	S.v = {"ant": 0.0, "bars": 0, "phone": true, "rock": false, "finger": 0.0, "led": false}
	S.back_fn = _sat_back
	S.front_fn = _sat_front
	S.glow_fn = _sat_glow
	S.tick_fn = _sat_tick
	S.h.p = Vector2(560, 520)
	_arms(8.0, 105.0)
	await S.say("衛星電話か！ これは当たりだ。", 2.1)
	S.h.expr = "joy"
	S.sfx("whoosh", -6.0)
	await S.anim(S.v, "ant", 1.0, 0.7)
	S.v.bars = 4
	S.sfx("chime")
	S.float_text("電波あり", S.w2s(S.hand(1) + Vector2(0, -130)), Color("9aff9a"), 56, 1.6)
	await S.wait(1.0)
	S.float_text("バッテリー 100%", S.w2s(S.hand(1) + Vector2(0, -130)), Color("9aff9a"), 44, 1.6)
	await S.wait(1.2)
	S.h.expr = "smile"
	await S.say("これで帰れる。", 1.4)
	S.v.finger = 1.0
	for i in 3:
		S.sfx("beep", -6.0, 1.6)
		await S.wait(0.35)
	await S.wait(0.5)
	S.v.finger = 0.0
	_arms(8.0, 105.0)
	S.h.expr = "blank"
	await S.say("…………", 2.0)
	S.h.look = Vector2(0.9, -0.5)
	S.float_text("ざざーん……", S.w2s(Vector2(900, 380)), Color("cfe9ff"), 48, 1.6)
	await S.wait(1.4)
	await S.set_time("dusk", 1.6)
	S.h.look = Vector2(-0.9, -0.7)
	S.float_text("夕日……", S.w2s(Vector2(250, 230)), Color("ffd0a0"), 48, 1.6)
	await S.wait(1.4)
	S.h.look = Vector2(1.0, -1.0)
	S.float_text("ヤシの木……", S.w2s(Vector2(1100, 180)), Color("c8ffc0"), 48, 1.6)
	await S.wait(1.4)
	S.h.look = Vector2.ZERO
	S.h.expr = "smile"
	await S.say("せっかく来たしなあ。", 2.0)
	await S.move(Vector2(800, 530), 0.9)
	S.v.phone = false
	S.v.rock = true
	S.sfx("pon")
	await S.wait(0.5)
	await S.jump("翌日", func(): S.time_now("day"); S.h.sit = true; S.h.p = Vector2(790, 535); _arms(8.0, 100.0); S.h.expr = "blank")
	await S.wait(1.0)
	S.v.finger = 1.0
	await S.wait(1.2)
	S.v.finger = 0.0
	S.h.expr = "smile"
	await S.wait(0.8)
	await S.jump("一週間後", func(): S.time_now("day"); S.h.expr = "blank")
	S.v.finger = 1.0
	await S.wait(1.2)
	S.v.finger = 0.0
	S.h.expr = "smile"
	await S.wait(0.6)
	await S.jump("一ヶ月後", func(): S.time_now("night"); S.v.led = true; S.h.expr = "smile")
	await S.wait(0.8)
	await S.say("明日でいいか。", 2.4)
	await _end(1.0)


func _sat_tick(dt: float) -> void:
	var f: float = S.v.finger
	if f > 0.01:
		S.h.arm_r = 100.0 + sin(S.t * 7.0) * 12.0 * f


func _sat(c: CanvasItem, p: Vector2, sz: float, rot: float, fl: float) -> void:
	var ant: float = S.v.ant
	c.draw_set_transform(p, rot, Vector2(sz * fl, sz))
	var tip := Vector2(-12.0 - 18.0 * ant, -14.0 - 50.0 * ant)
	c.draw_line(Vector2(-12, -14), tip, Color("2a2d33"), 7.0)
	c.draw_circle(tip, 5.0, Color("c43a3a"))
	Art.rrect(c, Rect2(-20, -16, 40, 62), 8, Color("3b4048"))
	c.draw_rect(Rect2(-14, -8, 28, 15), Color("9ee89a") if int(S.v.bars) > 0 else Color("7a8a78"))
	for i in int(S.v.bars):
		c.draw_rect(Rect2(-11 + i * 6, 3 - i * 2.5, 4, 3 + i * 2.5), Color("2e6a34"))
	for i in 9:
		c.draw_circle(Vector2(-10 + (i % 3) * 10, 18 + (i / 3) * 9), 3.0, Color("a9b0b8"))
	Art.reset_tf(c)


func _sat_back(c: CanvasItem) -> void:
	Art.rock(c, ROCK_P, 1.0)
	if S.v.rock:
		_sat(c, ROCK_P + Vector2(8, -56), 0.95, 0.12, 1.0)


func _sat_front(c: CanvasItem) -> void:
	if S.v.phone:
		var d := S.dir()
		_sat(c, S.hand(1) + Vector2(2.0 * d, -22.0), 1.1, 0.0, d)


func _sat_glow(c: CanvasItem) -> void:
	if S.v.led:
		var k := 0.6 + 0.4 * sin(S.t * 3.0)
		for i in 5:
			c.draw_circle(ROCK_P + Vector2(8, -76), 18.0 + i * 16.0, Color(0.5, 1.0, 0.5, 0.07 * k * float(5 - i) / 5.0))


# ================================================================== 9. 金塊
func ep_gold() -> void:
	await _open()
	S.v = {"shine": 0.0, "rain": 0.0, "umb": false, "storm": false, "flash": 0.0, "polish": false, "cd": 0.0, "fcd": 3.0}
	S.back_fn = _gold_back
	S.front_fn = _gold_front
	S.glow_fn = _gold_glow
	S.tick_fn = _gold_tick
	S.h.p = Vector2(540, 535)
	S.h.sit = true
	_arms(8.0, 70.0)
	S.h.expr = "joy"
	await S.say("金塊か。これで一生安泰だ。", 2.1)
	S.h.expr = "think"
	await S.wait(0.8)
	S.h.expr = "blank"
	await S.say("……どこで使うんだ、これ。", 2.0)
	S.h.expr = "think"
	await S.say("ひとまず、磨くか。", 1.5)
	S.v.polish = true
	S.h.expr = "serious"
	await S.wait(2.0)
	await S.jump("毎日", func(): S.v.shine = 0.4)
	await S.set_time("dusk", 1.0)
	await S.set_time("night", 1.0)
	await S.set_time("morning", 1.0)
	await S.jump("雨の日も", func(): S.time_now("storm"); S.v.rain = 0.9; S.v.umb = true; S.h.expr = "sad"; S.v.shine = 0.6)
	await S.wait(2.4)
	await S.jump("嵐のあとも", func(): S.v.rain = 1.0; S.v.storm = true; S.h.rag = 0.5; S.h.beard = 0.3; S.h.thin = 0.2)
	await S.wait(3.0)
	await S.jump("三年後", func():
		S.time_now("day")
		S.v.rain = 0.0
		S.v.storm = false
		S.v.umb = false
		S.v.shine = 1.0
		S.h.rag = 0.9
		S.h.beard = 0.8
		S.h.thin = 0.4
		S.h.expr = "smug")
	await S.wait(1.6)
	S.v.polish = false
	_arms(8.0, 8.0)
	S.sfx("glint")
	S.float_text("キラーン", S.w2s(GOLD_P + Vector2(90, -120)), Color("fff08a"), 96, 2.6, Vector2(0, -14))
	for i in 5:
		S.float_star(S.w2s(GOLD_P + Vector2(randf_range(-80, 80), randf_range(-70, 20))), randf_range(24, 44), 1.4)
	await S.wait(0.8)
	await S.say("資産は守った", 2.6)
	await _end(1.0)


func _gold_tick(dt: float) -> void:
	var v: Dictionary = S.v
	if v.polish:
		S.h.arm_r = 70.0 + sin(S.t * 12.0) * 22.0
		v.cd -= dt
		if v.cd <= 0.0:
			v.cd = 0.3
			S.sfx("page", -12.0, 1.6)
			if float(v.shine) > 0.2 and randf() < float(v.shine) + 0.3:
				S.float_star(S.w2s(GOLD_P + Vector2(randf_range(-60, 60), randf_range(-60, 10))), randf_range(14.0, 30.0), 0.5)
	v.flash = maxf(0.0, float(v.flash) - dt * 2.5)
	if v.storm:
		v.fcd -= dt
		if v.fcd <= 0.0:
			v.fcd = randf_range(0.9, 1.6)
			v.flash = 0.85
			S.sfx("thunder", -2.0)


func _gold_back(c: CanvasItem) -> void:
	Art.ellipse(c, GOLD_P + Vector2(10, 30), 100.0, 14.0, Color(0, 0, 0, 0.16))
	Art.item(c, "gold", GOLD_P, 1.6)
	var sh: float = S.v.shine
	if sh > 0.05:
		Art.sparkle(c, GOLD_P + Vector2(-50, -30), 16.0 * sh * (0.6 + 0.4 * sin(S.t * 5.0)), Color(1, 1, 0.9, 0.9))
	if S.v.umb:
		Art.umbrella(c, GOLD_P + Vector2(30, 20), 1.7)


func _gold_glow(c: CanvasItem) -> void:
	var sh: float = S.v.shine
	if sh < 0.05:
		return
	var k := sh * (0.75 + 0.25 * sin(S.t * 4.0))
	for i in 6:
		c.draw_circle(GOLD_P + Vector2(0, -10), 40.0 + i * 24.0, Color(1.0, 0.85, 0.3, 0.07 * k * float(6 - i) / 6.0))


func _gold_front(c: CanvasItem) -> void:
	if S.v.polish:
		var hp := S.hand(1)
		Art.rrect(c, Rect2(hp.x - 12, hp.y - 12, 30, 22), 6, Color("f2f2f2"))


# ================================================================== 10. 一発だけ実弾の入った拳銃
func ep_gun() -> void:
	await _open("dusk")
	S.v = {"close": 0.0, "crab": false, "cx": 930.0, "gull": -300.0, "cane": false, "cradle": false, "cd": 0.0}
	S.back_fn = _gun_back
	S.front_fn = _gun_front
	S.fx_fn = _gun_fx
	S.tick_fn = _gun_tick
	S.h.p = Vector2(640, 520)
	_arms(8.0, 28.0)
	S.h.expr = "serious"
	S.music_db(-40.0, 1.0)
	await S.wait(2.2)
	S.sfx("beep", -10.0, 0.5)
	await S.anim(S.v, "close", 1.0, 0.5)
	await S.wait(2.4)
	await S.anim(S.v, "close", 0.0, 0.4)
	S.h.expr = "blank"
	await S.wait(1.6)
	await S.say("……一発しかない", 2.0)
	S.music_db(0.0, 1.5)
	S.h.expr = "smile"
	S.sfx("ok")
	await S.say("絶対に無駄撃ちはできないな", 2.6)
	await S.jump("翌日", func(): S.time_now("day"); S.v.crab = true; S.h.p = Vector2(480, 520); S.h.expr = "serious")
	S.h.arms_free = false
	_arms(20.0, 92.0)
	await S.move(Vector2(700, 520), 1.2)
	await S.wait(0.5)
	S.h.expr = "blank"
	await S.say("……いや、違うな。", 1.5)
	S.h.expr = "serious"
	S.anim(S.v, "gull", 1500.0, 3.5)
	_arms(20.0, 125.0)
	await S.wait(1.8)
	S.h.expr = "blank"
	await S.say("あれも、違う。", 1.4)
	await S.jump("数日後", func(): S.v.crab = false; S.h.p = Vector2(300, 540); S.h.expr = "serious"; _arms(20.0, 92.0))
	for i in 2:
		await S.move(Vector2(900, 530), 1.5)
		await S.move(Vector2(300, 540), 1.5)
	await S.say("まだ、見つからない。", 1.7)
	await S.jump("数年後", func(): S.h.beard = 0.8; S.h.rag = 0.8; S.h.thin = 0.3; S.h.p = Vector2(300, 540); S.h.expr = "serious")
	await S.move(Vector2(900, 530), 1.6)
	await S.move(Vector2(500, 540), 1.2)
	await S.say("急ぐことはない。", 1.6)
	await S.jump("数十年後", func():
		S.h.beard = 1.0
		S.h.age = 1.0
		S.h.rag = 1.0
		S.h.thin = 0.45
		S.h.s = 0.95
		S.v.cane = true
		S.v.cradle = true
		S.h.p = Vector2(420, 540)
		S.h.expr = "smile")
	_arms(40.0, 62.0)
	S.h.arms_free = false
	await S.move(Vector2(760, 540), 3.4)
	S.h.expr = "serious"
	await S.say("まだだ。", 1.6)
	await S.say("もっと撃つべき時があるはずだ。", 2.8)
	await S.fade_to(1.0, 1.6)
	await S.wait(1.4)


func _gun_tick(dt: float) -> void:
	var v: Dictionary = S.v
	if v.crab:
		v.cx = 930.0 + sin(S.t * 1.3) * 120.0


func _gun_back(c: CanvasItem) -> void:
	var v: Dictionary = S.v
	if v.crab:
		Art.crab(c, Vector2(float(v.cx), 560.0), 1.0, S.t)
	if float(v.gull) > -200.0 and float(v.gull) < 1400.0:
		Art.gull(c, Vector2(float(v.gull), 170.0 + sin(S.t * 2.0) * 10.0), 1.2, S.t)


func _gun_front(c: CanvasItem) -> void:
	var v: Dictionary = S.v
	var d := S.dir()
	if v.cane:
		var hl := S.hand(0)
		c.draw_line(hl, Vector2(hl.x + 4.0 * d, S.h.p.y), Art.WOOD_D, 6.0)
	if v.cradle:
		Art.item(c, "gun", S.hand(1) + Vector2(12.0 * d, -26.0), 0.62, -1.25 * d, d)
	else:
		var up: float = (float(S.h.arm_r) - 92.0) / 100.0
		var hs: float = S.h.s
		Art.item(c, "gun", S.hand(1) + Vector2(28.0 * d, -16.0) * hs, 0.62 * hs, -0.2 * d - up * 0.9 * d, d)


func _gun_fx(c: CanvasItem) -> void:
	var cl: float = S.v.close
	if cl < 0.01:
		return
	c.draw_rect(Rect2(0, 0, 1280, 720), Color(0, 0, 0, 0.7 * cl))
	var ctr := Vector2(640, 340)
	var rot := 0.3
	c.draw_circle(ctr, 170.0 * cl, Color("6d7683"))
	c.draw_arc(ctr, 170.0 * cl, 0.0, TAU, 48, Color("3a414b"), 8.0)
	for i in 6:
		var a := rot + TAU * float(i) / 6.0
		var p := ctr + Vector2(cos(a), sin(a)) * 98.0 * cl
		c.draw_circle(p, 38.0 * cl, Color("22262c"))
		if i == 0:
			c.draw_circle(p, 28.0 * cl, Color("f0b830"))
			c.draw_circle(p + Vector2(-8, -8) * cl, 8.0 * cl, Color("fff0a0"))
	c.draw_circle(ctr, 26.0 * cl, Color("3a414b"))
