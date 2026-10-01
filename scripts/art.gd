class_name Art
extends RefCounted
## 絵はすべてコードで描く（素材ファイルなし）。主人公・小物・背景パーツ。

static var font: Font
static var food_label := "一年分"

const SKIN := Color("f7cfa6")
const HAIR := Color("4a3328")
const SHIRT := Color("f2a33a")
const PANTS := Color("3f74b5")
const SHOE := Color("7a4a2a")
const INK := Color("2a2018")
const WOOD := Color("dba868")
const WOOD_D := Color("a8733a")
const GOLD := Color("ffd23f")
const MOUTH := Color("7a3b30")


# ------------------------------------------------------------------ 基本
static func ellipse(c: CanvasItem, ctr: Vector2, rx: float, ry: float, col: Color, n: int = 28) -> void:
	var pts := PackedVector2Array()
	for i in n:
		var a := TAU * float(i) / float(n)
		pts.append(ctr + Vector2(cos(a) * rx, sin(a) * ry))
	c.draw_colored_polygon(pts, col)


static func rrect(c: CanvasItem, r: Rect2, rad: float, col: Color) -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = col
	sb.set_corner_radius_all(int(rad))
	sb.anti_aliasing = true
	c.draw_style_box(sb, r)


static func ctext(c: CanvasItem, s: String, ctr: Vector2, size: int, col: Color, outline: int = 0, ocol: Color = Color(0.1, 0.08, 0.05, 0.9), w: float = 900.0) -> void:
	var pos := Vector2(ctr.x - w * 0.5, ctr.y)
	if outline > 0:
		c.draw_string_outline(font, pos, s, HORIZONTAL_ALIGNMENT_CENTER, w, size, outline, ocol)
	c.draw_string(font, pos, s, HORIZONTAL_ALIGNMENT_CENTER, w, size, col)


static func sparkle(c: CanvasItem, p: Vector2, r: float, col: Color = Color(1, 1, 0.85, 1)) -> void:
	var k := r * 0.16
	c.draw_colored_polygon(PackedVector2Array([
		p + Vector2(0, -r), p + Vector2(k, -k), p + Vector2(r, 0), p + Vector2(k, k),
		p + Vector2(0, r), p + Vector2(-k, k), p + Vector2(-r, 0), p + Vector2(-k, -k)]), col)


static func reset_tf(c: CanvasItem) -> void:
	c.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


# ------------------------------------------------------------------ 主人公
static func hero_pts(o: Dictionary) -> Dictionary:
	var sit: bool = o.get("sit", false)
	var thin: float = o.get("thin", 0.0)
	var bob: float = o.get("bob", 0.0)
	var hip_y := -20.0 if sit else -34.0
	var bc := Vector2(0.0, hip_y - 26.0 + bob)
	var top := bc.y - 26.0
	var head := Vector2(0.0, top - 36.0 + bob * 0.5)
	var al: float = o.get("arm_l", 8.0)
	var ar: float = o.get("arm_r", 8.0)
	if o.get("moving", false) and o.get("arms_free", true):
		var sw := sin(float(o.get("walk", 0.0)))
		al = 10.0 + sw * 38.0
		ar = 10.0 - sw * 38.0
	var shw := 22.0 - thin * 4.0
	var sl := Vector2(-shw, top + 12.0)
	var sr := Vector2(shw, top + 12.0)
	var a1 := deg_to_rad(al)
	var a2 := deg_to_rad(ar)
	return {
		"hip": hip_y, "bc": bc, "top": top, "head": head, "sl": sl, "sr": sr,
		"hl": sl + Vector2(-sin(a1), cos(a1)) * 36.0,
		"hr": sr + Vector2(sin(a2), cos(a2)) * 36.0,
	}


static func to_world(o: Dictionary, local: Vector2) -> Vector2:
	var s: float = o.get("s", 1.0)
	var fl := -1.0 if o.get("flip", false) else 1.0
	var p: Vector2 = o.get("p", Vector2.ZERO)
	return p + Vector2(local.x * s * fl, local.y * s)


static func hero(c: CanvasItem, o: Dictionary) -> void:
	var P := hero_pts(o)
	var p: Vector2 = o.get("p", Vector2.ZERO)
	var s: float = o.get("s", 1.0)
	var fl := -1.0 if o.get("flip", false) else 1.0
	var sit: bool = o.get("sit", false)
	var thin: float = o.get("thin", 0.0)
	var rag: float = o.get("rag", 0.0)
	var beard: float = o.get("beard", 0.0)
	var age: float = o.get("age", 0.0)
	var halo: float = o.get("halo", 0.0)
	var t: float = o.get("t", 0.0)
	var hip: float = P.hip
	var hc: Vector2 = P.head
	c.draw_set_transform(p, 0.0, Vector2(s * fl, s))
	ellipse(c, Vector2(14.0 if sit else 0.0, 0), 46.0, 10.0, Color(0, 0, 0, 0.18))
	if halo > 0.01:
		for i in 5:
			c.draw_circle(hc, 58.0 + i * 15.0, Color(1.0, 0.95, 0.55, 0.16 * halo * (1.0 - i * 0.17)))
	# 脚
	var lw := 12.0 - thin * 3.0
	if sit:
		c.draw_line(Vector2(-4, hip), Vector2(40, hip + 8), SKIN, lw)
		c.draw_line(Vector2(4, hip), Vector2(46, hip + 14), SKIN, lw)
		ellipse(c, Vector2(46, hip + 8), 7, 10, SHOE)
		ellipse(c, Vector2(52, hip + 14), 7, 10, SHOE)
	else:
		var mv: bool = o.get("moving", false)
		var wk: float = o.get("walk", 0.0)
		var sw := sin(wk) * 15.0 if mv else 0.0
		var l1 := maxf(0.0, cos(wk)) * 7.0 if mv else 0.0
		var l2 := maxf(0.0, -cos(wk)) * 7.0 if mv else 0.0
		c.draw_line(Vector2(-9, hip), Vector2(-11 + sw, -l1 - 4), SKIN, lw)
		c.draw_line(Vector2(9, hip), Vector2(11 - sw, -l2 - 4), SKIN, lw)
		ellipse(c, Vector2(-8 + sw, -l1 - 2), 12, 6, SHOE)
		ellipse(c, Vector2(14 - sw, -l2 - 2), 12, 6, SHOE)
	ellipse(c, Vector2(0, hip - 4), 21.0 - thin * 3.0, 14.0, PANTS)
	# 胴
	var bw := 24.0 - thin * 6.0
	ellipse(c, P.bc, bw, 28.0, SHIRT)
	if rag > 0.25:
		c.draw_rect(Rect2(P.bc.x + 4, P.bc.y + 2, 12, 11), Color("8a5a3a"))
		c.draw_line(Vector2(P.bc.x + 4, P.bc.y + 2), Vector2(P.bc.x + 16, P.bc.y + 13), Color("5a3a22"), 1.5)
	if rag > 0.55:
		for i in 5:
			var x: float = P.bc.x - bw + 6.0 + i * (bw * 2.0 - 8.0) / 4.0
			var y: float = P.bc.y + 24.0
			c.draw_colored_polygon(PackedVector2Array([Vector2(x - 5, y - 4), Vector2(x + 5, y - 4), Vector2(x, y + 7)]), SKIN)
		c.draw_rect(Rect2(P.bc.x - 17, P.bc.y - 14, 10, 9), Color("c47a2a"))
	# 腕
	c.draw_line(P.sl, P.hl, SKIN, 10.0 - thin * 2.0)
	c.draw_line(P.sr, P.hr, SKIN, 10.0 - thin * 2.0)
	c.draw_line(P.sl, (P.sl as Vector2).lerp(P.hl, 0.34), SHIRT, 13.0)
	c.draw_line(P.sr, (P.sr as Vector2).lerp(P.hr, 0.34), SHIRT, 13.0)
	c.draw_circle(P.hl, 6.5, SKIN)
	c.draw_circle(P.hr, 6.5, SKIN)
	# 頭
	var r := 40.0 - thin * 2.0
	var hcol := HAIR.lerp(Color("eeeeee"), age)
	c.draw_circle(hc + Vector2(-r, 5), 7, SKIN)
	c.draw_circle(hc + Vector2(r, 5), 7, SKIN)
	c.draw_circle(hc, r, SKIN)
	if beard > 0.02:
		var pts := PackedVector2Array()
		for i in 13:
			var a := lerpf(0.06, 0.94, float(i) / 12.0) * PI
			var ext := sin(a) * beard * 34.0
			pts.append(hc + Vector2(cos(a) * (r + 1.0), 6.0 + sin(a) * (r - 4.0) + ext))
		pts.append(hc + Vector2(-r * 0.5, r * 0.38))
		pts.append(hc + Vector2(0, r * 0.28))
		pts.append(hc + Vector2(r * 0.5, r * 0.38))
		c.draw_colored_polygon(pts, hcol)
	hair(c, hc, r, hcol, t)
	face(c, hc, r, o.get("expr", "normal"), t, o)
	reset_tf(c)


static func hair(c: CanvasItem, hc: Vector2, r: float, col: Color, t: float) -> void:
	var pts := PackedVector2Array()
	for i in 17:
		var a := PI + PI * float(i) / 16.0
		pts.append(hc + Vector2(cos(a), sin(a)) * (r + 3.0))
	pts.append(hc + Vector2(r * 0.92, -r * 0.18))
	pts.append(hc + Vector2(r * 0.55, -r * 0.5))
	pts.append(hc + Vector2(r * 0.22, -r * 0.28))
	pts.append(hc + Vector2(-r * 0.15, -r * 0.55))
	pts.append(hc + Vector2(-r * 0.55, -r * 0.3))
	pts.append(hc + Vector2(-r * 0.92, -r * 0.18))
	c.draw_colored_polygon(pts, col)
	c.draw_colored_polygon(PackedVector2Array([
		hc + Vector2(-5, -r - 1), hc + Vector2(3 + sin(t * 2.0) * 2.0, -r - 20), hc + Vector2(9, -r + 1)]), col)


static func face(c: CanvasItem, hc: Vector2, r: float, expr: String, t: float, o: Dictionary) -> void:
	var look: Vector2 = o.get("look", Vector2.ZERO)
	var ex := r * 0.40
	var ey := hc.y + r * 0.08
	var lp := Vector2(hc.x - ex, ey)
	var rp := Vector2(hc.x + ex, ey)
	var lk := look * 4.0
	var blink := fmod(t + 0.7, 3.8) < 0.11
	var mc := hc + Vector2(0, r * 0.55)
	var chk := Color(1.0, 0.5, 0.45, 0.4)
	c.draw_circle(hc + Vector2(-r * 0.68, r * 0.36), r * 0.12, chk)
	c.draw_circle(hc + Vector2(r * 0.68, r * 0.36), r * 0.12, chk)
	match expr:
		"smile":
			_eyes_dot(c, lp, rp, lk, blink)
			_smile(c, mc, 11.0)
		"grin":
			_eyes_dot(c, lp, rp, lk, blink)
			_grin(c, mc, 14.0, 11.0)
		"joy":
			_eyes_arc(c, lp, rp, true)
			_grin(c, mc, 15.0, 13.0)
		"shock":
			for e in [lp, rp]:
				c.draw_circle(e, 10.0, Color.WHITE)
				c.draw_arc(e, 10.0, 0.0, TAU, 20, INK, 2.5)
				c.draw_circle(e + lk * 0.5, 2.8, INK)
			ellipse(c, mc + Vector2(0, 4), 6.0, 9.0, MOUTH, 16)
			for i in 3:
				var x := hc.x + (i - 1) * 14.0
				c.draw_line(Vector2(x, hc.y - r * 0.92), Vector2(x, hc.y - r * 0.5), Color(0.35, 0.45, 0.85, 0.85), 3.0)
			_sweat(c, hc + Vector2(r * 0.85, -r * 0.3))
		"think":
			_eyes_dot(c, lp, rp, lk + Vector2(3, -3), blink)
			c.draw_line(lp + Vector2(-8, -12), lp + Vector2(8, -16), INK, 3.0)
			c.draw_line(rp + Vector2(-8, -10), rp + Vector2(8, -10), INK, 3.0)
			c.draw_polyline(PackedVector2Array([mc + Vector2(-3, 1), mc + Vector2(1, -2), mc + Vector2(5, 1), mc + Vector2(9, -2)]), INK, 3.0)
		"sad":
			_eyes_dot(c, lp, rp, lk, blink)
			c.draw_line(lp + Vector2(-8, -8), lp + Vector2(8, -15), INK, 3.0)
			c.draw_line(rp + Vector2(8, -8), rp + Vector2(-8, -15), INK, 3.0)
			_frown(c, mc, 9.0)
			c.draw_circle(lp + Vector2(-2, 14), 4.0, Color("6cb4f5"))
		"serious":
			_eyes_dot(c, lp, rp, lk, blink, 4.2)
			c.draw_line(lp + Vector2(-9, -15), lp + Vector2(8, -9), INK, 3.5)
			c.draw_line(rp + Vector2(9, -15), rp + Vector2(-8, -9), INK, 3.5)
			c.draw_line(mc + Vector2(-7, 2), mc + Vector2(7, 2), INK, 3.0)
		"blank":
			c.draw_line(lp + Vector2(-8, 0), lp + Vector2(8, 0), INK, 3.5)
			c.draw_line(rp + Vector2(-8, 0), rp + Vector2(8, 0), INK, 3.5)
			c.draw_line(mc + Vector2(-6, 2), mc + Vector2(6, 2), INK, 3.0)
		"sleep":
			_eyes_arc(c, lp, rp, false)
			c.draw_circle(mc + Vector2(0, 2), 3.5, MOUTH)
		"enlight":
			_eyes_arc(c, lp, rp, false)
			_smile(c, mc, 12.0)
		"burn":
			for e in [lp, rp]:
				c.draw_circle(e + lk, 8.0, Color(1.0, 0.6, 0.15, 0.9))
				c.draw_circle(e + lk, 5.5, INK)
				c.draw_circle(e + lk + Vector2(2, -2.5), 2.2, Color.WHITE)
			c.draw_line(lp + Vector2(-9, -15), lp + Vector2(8, -9), INK, 3.5)
			c.draw_line(rp + Vector2(9, -15), rp + Vector2(-8, -9), INK, 3.5)
			_smile(c, mc, 8.0)
		"hungry":
			_eyes_dot(c, lp, rp, lk, blink)
			c.draw_line(lp + Vector2(-8, -8), lp + Vector2(8, -15), INK, 3.0)
			c.draw_line(rp + Vector2(8, -8), rp + Vector2(-8, -15), INK, 3.0)
			var wv := PackedVector2Array()
			for i in 7:
				wv.append(mc + Vector2(-12 + i * 4.0, sin(i * 1.6) * 3.0))
			c.draw_polyline(wv, INK, 3.0)
		"yawn":
			_eyes_arc(c, lp, rp, false)
			ellipse(c, mc + Vector2(0, 5), 10.0, 13.0, MOUTH, 18)
		"cry":
			_eyes_arc(c, lp, rp, false)
			c.draw_line(lp + Vector2(-4, 2), lp + Vector2(-9, 32), Color("6cb4f5"), 4.0)
			c.draw_line(rp + Vector2(4, 2), rp + Vector2(9, 32), Color("6cb4f5"), 4.0)
			_grin(c, mc + Vector2(0, 3), 11.0, 9.0)
		"smug":
			_eyes_dot(c, lp, rp, lk, blink, 4.2)
			c.draw_line(lp + Vector2(-9, -9), lp + Vector2(8, -13), INK, 3.5)
			c.draw_line(rp + Vector2(9, -9), rp + Vector2(-8, -13), INK, 3.5)
			c.draw_arc(mc + Vector2(4, -3), 10.0, 0.0, 0.7 * PI, 10, INK, 3.5)
		_:
			_eyes_dot(c, lp, rp, lk, blink)
			_smile(c, mc, 7.0)


static func _eyes_dot(c: CanvasItem, lp: Vector2, rp: Vector2, lk: Vector2, blink: bool, rad: float = 4.8) -> void:
	if blink:
		c.draw_line(lp + Vector2(-6, 0), lp + Vector2(6, 0), INK, 3.0)
		c.draw_line(rp + Vector2(-6, 0), rp + Vector2(6, 0), INK, 3.0)
		return
	for e in [lp, rp]:
		c.draw_circle(e + lk, rad, INK)
		c.draw_circle(e + lk + Vector2(1.6, -1.8), rad * 0.32, Color.WHITE)


static func _eyes_arc(c: CanvasItem, lp: Vector2, rp: Vector2, up: bool) -> void:
	for e in [lp, rp]:
		if up:
			c.draw_arc(e + Vector2(0, 5), 8.0, PI, TAU, 12, INK, 3.5)
		else:
			c.draw_arc(e + Vector2(0, -4), 8.0, 0.0, PI, 12, INK, 3.5)


static func _smile(c: CanvasItem, ctr: Vector2, w: float) -> void:
	c.draw_arc(ctr + Vector2(0, -4), w, 0.15 * PI, 0.85 * PI, 12, INK, 3.5)


static func _frown(c: CanvasItem, ctr: Vector2, w: float) -> void:
	c.draw_arc(ctr + Vector2(0, 8), w, 1.15 * PI, 1.85 * PI, 12, INK, 3.5)


static func _grin(c: CanvasItem, ctr: Vector2, w: float, hgt: float) -> void:
	var pts := PackedVector2Array()
	for i in 13:
		var a := PI * float(i) / 12.0
		pts.append(ctr + Vector2(cos(a) * w, sin(a) * hgt))
	c.draw_colored_polygon(pts, MOUTH)
	ellipse(c, ctr + Vector2(0, hgt * 0.62), w * 0.5, hgt * 0.3, Color("e8776a"), 12)
	pts.append(pts[0])
	c.draw_polyline(pts, INK, 2.5)


static func _sweat(c: CanvasItem, p: Vector2) -> void:
	c.draw_circle(p + Vector2(0, 4), 5.0, Color("8fd0ff"))
	c.draw_colored_polygon(PackedVector2Array([p + Vector2(-4.5, 2), p + Vector2(4.5, 2), p + Vector2(0, -9)]), Color("8fd0ff"))


# ------------------------------------------------------------------ 木彫り人形
static func doll(c: CanvasItem, p: Vector2, s: float, t: float) -> void:
	c.draw_set_transform(p, 0.0, Vector2(s, s))
	ellipse(c, Vector2.ZERO, 34, 8, Color(0, 0, 0, 0.15), 16)
	c.draw_line(Vector2(-18, -58), Vector2(-32, -32), WOOD_D, 9.0)
	c.draw_line(Vector2(18, -58), Vector2(32, -32), WOOD_D, 9.0)
	c.draw_line(Vector2(-8, -14), Vector2(-9, -2), WOOD_D, 10.0)
	c.draw_line(Vector2(8, -14), Vector2(9, -2), WOOD_D, 10.0)
	ellipse(c, Vector2(0, -38), 22.0, 28.0, WOOD, 18)
	var hc := Vector2(0, -96)
	c.draw_circle(hc, 40.0, WOOD)
	hair(c, hc, 40.0, WOOD_D.darkened(0.35), t)
	face(c, hc, 40.0, "smile", 0.0, {})
	reset_tf(c)


# ------------------------------------------------------------------ 小物アイコン（原寸は 100 四方）
static func item(c: CanvasItem, id: String, pos: Vector2, sz: float, rot: float = 0.0, fl: float = 1.0) -> void:
	c.draw_set_transform(pos, rot, Vector2(sz * fl, sz))
	match id:
		"knife":
			rrect(c, Rect2(-52, -9, 40, 18), 7, Color("8a5a35"))
			c.draw_rect(Rect2(-12, -15, 7, 30), Color("555d68"))
			c.draw_colored_polygon(PackedVector2Array([Vector2(-5, -10), Vector2(30, -10), Vector2(54, 6), Vector2(-5, 10)]), Color("dfe5ea"))
			c.draw_line(Vector2(-5, 6), Vector2(48, 6), Color("aab3bd"), 2.0)
		"lighter":
			rrect(c, Rect2(-15, -6, 30, 50), 6, Color("e04848"))
			rrect(c, Rect2(-15, -24, 30, 20), 4, Color("c8ced6"))
			c.draw_circle(Vector2(-3, -28), 6.0, Color("8e949c"))
			c.draw_rect(Rect2(-6, 8, 12, 14), Color(1, 1, 1, 0.35))
		"rod":
			c.draw_line(Vector2(-48, 44), Vector2(50, -46), Color("8a5a35"), 6.0)
			c.draw_circle(Vector2(-22, 20), 10.0, Color("9aa1aa"))
			c.draw_circle(Vector2(-22, 20), 4.0, Color("5a6068"))
			c.draw_polyline(PackedVector2Array([Vector2(50, -46), Vector2(58, -8), Vector2(52, 30)]), Color.WHITE, 2.0)
			c.draw_arc(Vector2(48, 36), 6.0, 0.0, PI, 8, Color("cfd5dc"), 2.5)
		"tent":
			tent(c, Vector2(0, 34), 1.0, 0.42, 0.0)
		"phone":
			rrect(c, Rect2(-24, -46, 48, 92), 8, Color("2c3138"))
			c.draw_rect(Rect2(-20, -38, 40, 70), Color("a8dcf2"))
			ctext(c, "圏外", Vector2(0, 2), 17, Color("37424d"), 0, Color.BLACK, 60.0)
			for i in 4:
				c.draw_rect(Rect2(-14 + i * 7, -24 - i * 3 + 0, 4, 6 + i * 3), Color(0.3, 0.35, 0.4, 0.35))
			c.draw_circle(Vector2(0, 40), 3.0, Color("8d96a0"))
		"book":
			rrect(c, Rect2(-34, -46, 68, 92), 4, Color("7a2e2e"))
			c.draw_rect(Rect2(28, -42, 6, 84), Color("f3ead2"))
			c.draw_rect(Rect2(-30, -46, 5, 92), Color("5a1f1f"))
			rrect(c, Rect2(-22, -32, 46, 40), 2, Color("e8d8a8"))
			ctext(c, "不確かさ", Vector2(1, -14), 13, Color("4a2a1a"), 0, Color.BLACK, 60.0)
			ctext(c, "哲学", Vector2(1, 4), 12, Color("4a2a1a"), 0, Color.BLACK, 60.0)
		"food":
			rrect(c, Rect2(-46, -30, 92, 62), 4, WOOD)
			c.draw_rect(Rect2(-46, -30, 92, 12), WOOD_D)
			c.draw_line(Vector2(-46, 2), Vector2(46, 2), WOOD_D, 3.0)
			c.draw_line(Vector2(-46, 20), Vector2(46, 20), WOOD_D, 3.0)
			rrect(c, Rect2(-26, -10, 52, 26), 3, Color("f6f0e0"))
			ctext(c, food_label, Vector2(0, 9), 19 if food_label.length() <= 3 else 14, Color("b02a2a"), 0, Color.BLACK, 60.0)
		"satphone":
			c.draw_line(Vector2(-12, -14), Vector2(-30, -64), Color("2a2d33"), 7.0)
			c.draw_circle(Vector2(-30, -64), 5.0, Color("c43a3a"))
			rrect(c, Rect2(-20, -16, 40, 62), 8, Color("3b4048"))
			c.draw_rect(Rect2(-14, -8, 28, 15), Color("9ee89a"))
			for i in 9:
				c.draw_circle(Vector2(-10 + (i % 3) * 10, 16 + (i / 3) * 9), 3.0, Color("a9b0b8"))
		"gold":
			c.draw_colored_polygon(PackedVector2Array([Vector2(-40, -8), Vector2(-18, -26), Vector2(44, -26), Vector2(26, -8)]), Color("fff08a"))
			c.draw_colored_polygon(PackedVector2Array([Vector2(-40, -8), Vector2(26, -8), Vector2(26, 26), Vector2(-40, 26)]), GOLD)
			c.draw_colored_polygon(PackedVector2Array([Vector2(26, -8), Vector2(44, -26), Vector2(44, 8), Vector2(26, 26)]), Color("e0a800"))
			c.draw_line(Vector2(-34, -2), Vector2(18, -2), Color(1, 1, 1, 0.55), 3.0)
		"gun":
			c.draw_colored_polygon(PackedVector2Array([Vector2(-34, -6), Vector2(-14, -6), Vector2(-20, 42), Vector2(-40, 36)]), Color("7a4a2a"))
			c.draw_colored_polygon(PackedVector2Array([Vector2(-8, -20), Vector2(50, -20), Vector2(50, -8), Vector2(-8, -8)]), Color("6d7683"))
			rrect(c, Rect2(-36, -24, 34, 22), 6, Color("7d8794"))
			c.draw_circle(Vector2(-6, -14), 12.0, Color("525a66"))
			c.draw_circle(Vector2(-6, -14), 4.0, Color("2f343b"))
			c.draw_arc(Vector2(-14, 2), 9.0, 0.0, PI, 8, Color("525a66"), 3.0)
	reset_tf(c)


# ------------------------------------------------------------------ 背景パーツ
static func flame(c: CanvasItem, base: Vector2, w: float, hgt: float, t: float, ph: float) -> void:
	var f := 1.0 + sin(t * 9.0 + ph) * 0.08 + sin(t * 17.0 + ph * 2.0) * 0.05
	var sway := sin(t * 5.0 + ph) * w * 0.14
	_flame_layer(c, base, w, hgt * f, sway, Color("ff7a1a"))
	_flame_layer(c, base, w * 0.68, hgt * 0.72 * f, sway * 0.8, Color("ffb52e"))
	_flame_layer(c, base, w * 0.38, hgt * 0.45 * f, sway * 0.6, Color("fff1a8"))


static func _flame_layer(c: CanvasItem, base: Vector2, w: float, hgt: float, sway: float, col: Color) -> void:
	var pts := PackedVector2Array()
	pts.append(base + Vector2(-w, 0))
	pts.append(base + Vector2(-w * 0.9, -hgt * 0.35))
	pts.append(base + Vector2(-w * 0.35 + sway * 0.5, -hgt * 0.7))
	pts.append(base + Vector2(sway, -hgt))
	pts.append(base + Vector2(w * 0.4 + sway * 0.5, -hgt * 0.65))
	pts.append(base + Vector2(w * 0.95, -hgt * 0.3))
	pts.append(base + Vector2(w, 0))
	for i in range(1, 6):
		var a := PI * float(i) / 6.0
		pts.append(base + Vector2(cos(a) * w, sin(a) * w * 0.4))
	c.draw_colored_polygon(pts, col)


static func campfire(c: CanvasItem, pos: Vector2, sz: float, t: float) -> void:
	var s := minf(sz, 6.0)
	var lw := 10.0 + 3.0 * s
	c.draw_line(pos + Vector2(-38, 8) * s * 0.7, pos + Vector2(38, -2) * s * 0.7, WOOD_D, lw)
	c.draw_line(pos + Vector2(-38, -2) * s * 0.7, pos + Vector2(38, 8) * s * 0.7, WOOD, lw)
	var n := clampi(int(1.0 + sz * 1.3), 1, 8)
	for i in n:
		var off := 0.0 if n == 1 else (float(i) / float(n - 1) - 0.5) * 2.0
		var bx := pos + Vector2(off * 34.0 * s, -2.0)
		flame(c, bx, 24.0 * s * 0.8, 86.0 * s * (1.0 - 0.45 * absf(off)), t, float(i) * 1.7)
	for i in 14:
		var ph := fmod(t * 0.7 + float(i) * 0.37, 1.0)
		var x := pos.x + sin(float(i) * 12.9 + t) * 30.0 * s * ph
		var y := pos.y - ph * 170.0 * s
		c.draw_circle(Vector2(x, y), 2.5 + s * 0.3, Color(1.0, 0.75, 0.3, 1.0 - ph))


static func palm(c: CanvasItem, base: Vector2, hgt: float, lean: float, t: float, leaves: float = 1.0) -> void:
	var top := base + Vector2(lean * hgt, -hgt)
	var ctrl := base + Vector2(lean * hgt * 0.1, -hgt * 0.6)
	var prev := base
	for i in range(1, 13):
		var u := float(i) / 12.0
		var q := base.lerp(ctrl, u).lerp(ctrl.lerp(top, u), u)
		c.draw_line(prev, q, Color("8a5e3a"), lerpf(20.0, 11.0, u))
		if i % 2 == 0:
			c.draw_line(q + Vector2(-8, 0), q + Vector2(8, 2), Color("6d4727"), 2.0)
		prev = q
	var cols := [Color("3f9a3f"), Color("52b04a")]
	for i in int(ceil(8.0 * leaves)):
		var a := deg_to_rad(-175.0 + 22.0 * i) + sin(t * 1.4 + i) * 0.04
		var dir := Vector2(cos(a), sin(a))
		var len := 105.0 + (i % 2) * 14.0
		var droop := 34.0 + absf(cos(a)) * 30.0
		var perp := Vector2(-dir.y, dir.x)
		var tip := top + dir * len + Vector2(0, droop)
		var mid := top + dir * len * 0.5 + Vector2(0, droop * 0.25)
		c.draw_colored_polygon(PackedVector2Array([top, mid + perp * 15.0, tip, mid - perp * 13.0]), cols[i % 2])
		c.draw_line(top, tip, Color("2f7a32"), 2.0)
	if leaves > 0.5:
		c.draw_circle(top + Vector2(-8, 8), 9.0, Color("6a4526"))
		c.draw_circle(top + Vector2(9, 10), 9.0, Color("5a3a1f"))


static func tent(c: CanvasItem, base: Vector2, prog: float, sc: float, lit: float, patch: float = 0.0) -> void:
	if prog <= 0.01:
		return
	var w := 120.0 * sc
	var hh := 150.0 * sc * prog
	ellipse(c, base + Vector2(0, 4), w * 1.1, 12.0 * sc + 2.0, Color(0, 0, 0, 0.18))
	c.draw_colored_polygon(PackedVector2Array([base + Vector2(-w, 0), base + Vector2(0, -hh), base + Vector2(0, 0)]), Color("ee7a4c"))
	c.draw_colored_polygon(PackedVector2Array([base + Vector2(0, -hh), base + Vector2(w, 0), base + Vector2(0, 0)]), Color("d65a32"))
	var door := Color("5a2a1a").lerp(Color("ffd98a"), lit)
	c.draw_colored_polygon(PackedVector2Array([base + Vector2(-w * 0.34, 0), base + Vector2(0, -hh * 0.74), base + Vector2(w * 0.34, 0)]), door)
	c.draw_line(base + Vector2(0, -hh * 0.74), base + Vector2(-w * 0.34, 0), Color("ffb08a"), 3.0)
	c.draw_line(base + Vector2(0, -hh * 0.74), base + Vector2(w * 0.34, 0), Color("ffb08a"), 3.0)
	c.draw_line(base + Vector2(0, -hh), base + Vector2(0, -hh - 14.0 * sc), Color("8a5a35"), 4.0)
	for sgn in [-1.0, 1.0]:
		c.draw_line(base + Vector2(sgn * w, 0), base + Vector2(sgn * (w + 30.0 * sc), 9.0), Color("e9e2d2"), 2.0)
		c.draw_circle(base + Vector2(sgn * (w + 30.0 * sc), 9.0), 3.0 * sc + 1.0, Color("8a5a35"))
	if patch > 0.01:
		c.draw_rect(Rect2(base + Vector2(-w * 0.62, -hh * 0.22), Vector2(34.0, 26.0) * sc), Color("7aa9d8"))
		c.draw_rect(Rect2(base + Vector2(w * 0.3, -hh * 0.32), Vector2(28.0, 22.0) * sc), Color("9ac36a"))


static func fish(c: CanvasItem, pos: Vector2, sz: float, col: Color, flip: bool, rot: float = 0.0) -> void:
	c.draw_set_transform(pos, rot, Vector2(sz * (-1.0 if flip else 1.0), sz))
	ellipse(c, Vector2.ZERO, 34.0, 16.0, col, 20)
	c.draw_colored_polygon(PackedVector2Array([Vector2(-28, 0), Vector2(-54, -17), Vector2(-54, 17)]), col.darkened(0.2))
	c.draw_colored_polygon(PackedVector2Array([Vector2(-6, -14), Vector2(8, -28), Vector2(18, -13)]), col.darkened(0.2))
	ellipse(c, Vector2(2, 6), 26.0, 7.0, Color(1, 1, 1, 0.45), 16)
	c.draw_circle(Vector2(20, -4), 4.6, Color.WHITE)
	c.draw_circle(Vector2(21, -4), 2.3, INK)
	c.draw_line(Vector2(32, 3), Vector2(26, 5), INK, 1.8)
	reset_tf(c)


static func crab(c: CanvasItem, pos: Vector2, sz: float, t: float) -> void:
	c.draw_set_transform(pos, 0.0, Vector2(sz, sz))
	var red := Color("e2503c")
	for sgn in [-1.0, 1.0]:
		for i in 3:
			var wig := sin(t * 10.0 + i + sgn) * 3.0
			c.draw_line(Vector2(sgn * 14, 0), Vector2(sgn * (30 + i * 3), 10 + wig), red.darkened(0.2), 3.0)
		c.draw_line(Vector2(sgn * 16, -6), Vector2(sgn * 28, -22), red, 4.0)
		c.draw_circle(Vector2(sgn * 30, -26), 8.0, red)
		c.draw_line(Vector2(sgn * 6, -12), Vector2(sgn * 6, -22), red, 2.0)
		c.draw_circle(Vector2(sgn * 6, -24), 3.5, Color.WHITE)
		c.draw_circle(Vector2(sgn * 6, -24), 1.6, INK)
	ellipse(c, Vector2(0, -2), 22.0, 14.0, red, 18)
	reset_tf(c)


static func gull(c: CanvasItem, pos: Vector2, sz: float, t: float) -> void:
	var fl := sin(t * 7.0) * 9.0
	c.draw_polyline(PackedVector2Array([
		pos + Vector2(-34, 4 + fl) * sz, pos + Vector2(-17, -10 - fl * 0.5) * sz, pos,
		pos + Vector2(17, -10 - fl * 0.5) * sz, pos + Vector2(34, 4 + fl) * sz]), Color.WHITE, 5.0 * sz)
	c.draw_circle(pos + Vector2(0, 2) * sz, 6.0 * sz, Color.WHITE)


static func tower(c: CanvasItem, bx: float, by: float, hgt: float) -> void:
	var layer := 28.0
	var n := int(hgt / layer)
	for i in n:
		var w := lerpf(130.0, 66.0, float(i) * layer / 620.0)
		var y := by - float(i + 1) * layer
		var off := (fmod(float(i) * 37.13, 1.0) - 0.5) * 8.0
		var g := 0.58 + fmod(float(i) * 0.173, 0.22)
		rrect(c, Rect2(bx - w * 0.5 + off, y, w, layer + 2.0), 8, Color(g, g * 0.98, g * 0.93))
		c.draw_line(Vector2(bx - w * 0.5 + off + w * 0.35, y + 3), Vector2(bx - w * 0.5 + off + w * 0.35, y + layer - 2), Color(0, 0, 0, 0.18), 2.0)
		c.draw_line(Vector2(bx - w * 0.5 + off + w * 0.68, y + 3), Vector2(bx - w * 0.5 + off + w * 0.68, y + layer - 2), Color(0, 0, 0, 0.18), 2.0)


static func hill(c: CanvasItem, apex: Vector2, base_y: float, half_w: float) -> void:
	var pts := PackedVector2Array()
	pts.append(Vector2(apex.x - half_w, base_y))
	for i in 9:
		var u := float(i) / 8.0
		var x := lerpf(apex.x - half_w * 0.9, apex.x - 40.0, u)
		pts.append(Vector2(x, lerpf(base_y - 30.0, apex.y, pow(u, 0.7))))
	pts.append(Vector2(apex.x + 40.0, apex.y))
	for i in 9:
		var u := float(i) / 8.0
		var x := lerpf(apex.x + 40.0, apex.x + half_w * 0.9, u)
		pts.append(Vector2(x, lerpf(apex.y, base_y - 30.0, pow(u, 1.4))))
	pts.append(Vector2(apex.x + half_w, base_y))
	c.draw_colored_polygon(pts, Color("5fa24a"))
	c.draw_colored_polygon(PackedVector2Array([
		Vector2(apex.x - 70, apex.y + 40), Vector2(apex.x - 40, apex.y), Vector2(apex.x + 40, apex.y), Vector2(apex.x + 70, apex.y + 44)]), Color("8f8a7c"))
	c.draw_line(Vector2(apex.x - 40, apex.y), Vector2(apex.x + 40, apex.y), Color("b8b2a0"), 4.0)


static func rock(c: CanvasItem, pos: Vector2, sz: float) -> void:
	ellipse(c, pos + Vector2(0, 4), 70.0 * sz, 12.0 * sz, Color(0, 0, 0, 0.16), 20)
	c.draw_colored_polygon(PackedVector2Array([
		pos + Vector2(-64, 0) * sz, pos + Vector2(-50, -34) * sz, pos + Vector2(-10, -50) * sz,
		pos + Vector2(34, -42) * sz, pos + Vector2(62, -10) * sz, pos + Vector2(60, 0) * sz]), Color("8d9199"))
	c.draw_colored_polygon(PackedVector2Array([
		pos + Vector2(-50, -34) * sz, pos + Vector2(-10, -50) * sz, pos + Vector2(34, -42) * sz, pos + Vector2(0, -30) * sz]), Color("b3b8c0"))


static func cloud(c: CanvasItem, pos: Vector2, sz: float, col: Color) -> void:
	for d in [Vector2(-34, 6), Vector2(0, -6), Vector2(36, 4), Vector2(0, 10), Vector2(-60, 14), Vector2(62, 14)]:
		c.draw_circle(pos + (d as Vector2) * sz, 24.0 * sz, col)
	c.draw_rect(Rect2(pos + Vector2(-62, 8) * sz, Vector2(126, 18) * sz), col)


static func umbrella(c: CanvasItem, pos: Vector2, sz: float) -> void:
	c.draw_line(pos, pos + Vector2(0, -90) * sz, Color("5a4a3a"), 4.0 * sz)
	var pts := PackedVector2Array()
	for i in 13:
		var a := PI + PI * float(i) / 12.0
		pts.append(pos + Vector2(0, -90) * sz + Vector2(cos(a) * 80.0, sin(a) * 52.0) * sz)
	c.draw_colored_polygon(pts, Color("e04a5a"))
	for i in 4:
		var a := PI + PI * float(i + 1) / 5.0
		c.draw_line(pos + Vector2(0, -90) * sz, pos + Vector2(0, -90) * sz + Vector2(cos(a) * 80.0, sin(a) * 52.0) * sz, Color("b02a3a"), 2.0)


static func boat(c: CanvasItem, pos: Vector2, sz: float) -> void:
	c.draw_colored_polygon(PackedVector2Array([pos + Vector2(-50, -10) * sz, pos + Vector2(56, -10) * sz, pos + Vector2(40, 8) * sz, pos + Vector2(-36, 8) * sz]), Color("e8e8ee"))
	c.draw_rect(Rect2(pos + Vector2(-50, -4) * sz, Vector2(104, 5) * sz), Color("c0392b"))
	c.draw_rect(Rect2(pos + Vector2(-14, -28) * sz, Vector2(34, 18) * sz), Color("f4f4f8"))
	c.draw_rect(Rect2(pos + Vector2(-8, -24) * sz, Vector2(8, 8) * sz), Color("7ab0d8"))
	c.draw_rect(Rect2(pos + Vector2(6, -24) * sz, Vector2(8, 8) * sz), Color("7ab0d8"))
	c.draw_line(pos + Vector2(2, -28) * sz, pos + Vector2(2, -42) * sz, Color("555"), 2.0)
