extends RefCounted
## Key poses (Keyframes) ของแต่ละท่า — ค่า rotation เป็นเรเดียน เทียบกับท่า Rest
## In-betweens: ใช้ Cubic interpolation + breakdown keys ระหว่างท่าหลัก

const GUARD := {"arm_near_up": -0.45, "arm_near_low": -2.0, "arm_far_up": -0.35, "arm_far_low": -2.1,
	"leg_far_up": 0.22, "leg_far_low": 0.05, "leg_near_up": -0.28, "leg_near_low": 0.18, "hip_y": 8.0, "torso": 0.06}

static func m(a: Dictionary, b: Dictionary) -> Dictionary:
	var r := a.duplicate()
	r.merge(b, true)
	return r

var ANIMS := {
	# ---------------- ยืน (หายใจ / โยกตัวเบา ๆ)
	"idle": {"length": 2.4, "loop": true, "keys": [
		[0.0, {"arm_far_up": -0.1, "arm_near_up": 0.1, "arm_far_low": -0.1, "arm_near_low": -0.1}],
		[1.2, {"hip_y": 5.0, "torso": -0.03, "head": 0.06, "arm_far_up": -0.04, "arm_near_up": 0.16,
			"arm_far_low": -0.18, "arm_near_low": -0.2, "leg_far_up": -0.07, "leg_far_low": 0.14,
			"leg_near_up": -0.07, "leg_near_low": 0.14}],
		[2.4, {"arm_far_up": -0.1, "arm_near_up": 0.1, "arm_far_low": -0.1, "arm_near_low": -0.1}],
	]},
	# ---------------- เดิน (contact - passing - contact - passing)
	"walk": {"length": 1.0, "loop": true, "keys": [
		[0.0,  {"leg_near_up": -0.45, "leg_near_low": 0.05, "leg_far_up": 0.40, "leg_far_low": 0.35,
			"arm_near_up": 0.35, "arm_near_low": -0.15, "arm_far_up": -0.35, "arm_far_low": -0.55, "hip_y": 20.0, "torso": 0.06, "head": -0.04}],
		[0.25, {"leg_near_up": 0.0, "leg_near_low": 0.15, "leg_far_up": 0.0, "leg_far_low": 0.95,
			"arm_near_up": 0.0, "arm_near_low": -0.25, "arm_far_up": 0.0, "arm_far_low": -0.25, "hip_y": 2.0, "torso": 0.04, "head": -0.02}],
		[0.5,  {"leg_near_up": 0.40, "leg_near_low": 0.35, "leg_far_up": -0.45, "leg_far_low": 0.05,
			"arm_near_up": -0.35, "arm_near_low": -0.55, "arm_far_up": 0.35, "arm_far_low": -0.15, "hip_y": 20.0, "torso": 0.06, "head": -0.04}],
		[0.75, {"leg_near_up": 0.0, "leg_near_low": 0.95, "leg_far_up": 0.0, "leg_far_low": 0.15,
			"arm_near_up": 0.0, "arm_near_low": -0.25, "arm_far_up": 0.0, "arm_far_low": -0.25, "hip_y": 2.0, "torso": 0.04, "head": -0.02}],
		[1.0,  {"leg_near_up": -0.45, "leg_near_low": 0.05, "leg_far_up": 0.40, "leg_far_low": 0.35,
			"arm_near_up": 0.35, "arm_near_low": -0.15, "arm_far_up": -0.35, "arm_far_low": -0.55, "hip_y": 20.0, "torso": 0.06, "head": -0.04}],
	]},
	# ---------------- กระโดด (ย่อ - ส่งตัว - ลอยสูงสุด - ตก - ลงพื้น - ยืน)
	"jump": {"length": 1.6, "loop": true, "keys": [
		[0.0,  {}],
		[0.3,  {"hip_y": 38.0, "leg_far_up": -0.6, "leg_far_low": 1.1, "leg_near_up": -0.6, "leg_near_low": 1.1,
			"torso": 0.2, "head": -0.12, "arm_near_up": 0.75, "arm_far_up": 0.55, "arm_near_low": -0.2, "arm_far_low": -0.2}],
		[0.45, {"hip_y": -70.0, "leg_far_up": 0.05, "leg_far_low": 0.05, "leg_near_up": -0.05, "leg_near_low": 0.05,
			"torso": -0.05, "head": 0.05, "arm_near_up": -2.6, "arm_far_up": -2.8, "arm_near_low": -0.1, "arm_far_low": -0.1}],
		[0.72, {"hip_y": -190.0, "leg_far_up": -0.9, "leg_far_low": 1.5, "leg_near_up": -1.0, "leg_near_low": 1.4,
			"torso": 0.05, "head": 0.08, "arm_near_up": -2.4, "arm_far_up": -2.6, "arm_near_low": -0.3, "arm_far_low": -0.3}],
		[0.98, {"hip_y": -80.0, "leg_far_up": -0.25, "leg_far_low": 0.35, "leg_near_up": -0.3, "leg_near_low": 0.35,
			"torso": 0.0, "arm_near_up": -1.4, "arm_far_up": -1.5, "arm_near_low": -0.2, "arm_far_low": -0.2}],
		[1.1,  {"hip_y": 36.0, "leg_far_up": -0.6, "leg_far_low": 1.1, "leg_near_up": -0.6, "leg_near_low": 1.1,
			"torso": 0.22, "head": -0.1, "arm_near_up": 0.3, "arm_far_up": 0.2, "arm_near_low": -0.4, "arm_far_low": -0.4}],
		[1.38, {"arm_far_up": -0.1, "arm_near_up": 0.1, "arm_far_low": -0.1, "arm_near_low": -0.1}],
		[1.6,  {}],
	]},
	# ---------------- ต่อย (การ์ด - ง้าง - หมัดหน้า - การ์ด - ง้าง - หมัดหลัง - การ์ด)
	"punch": {"length": 1.4, "loop": true, "keys": [
		[0.0,  GUARD],
		[0.12, m(GUARD, {"arm_near_up": -0.25, "arm_near_low": -2.3, "torso": -0.04})],
		[0.24, m(GUARD, {"arm_near_up": -1.55, "arm_near_low": -0.05, "torso": 0.16, "hip_x": 10.0, "head": 0.05})],
		[0.42, m(GUARD, {"arm_near_up": -1.5, "arm_near_low": -0.12, "torso": 0.14, "hip_x": 8.0, "head": 0.04})],
		[0.6,  GUARD],
		[0.75, m(GUARD, {"arm_far_up": -0.15, "arm_far_low": -2.35, "torso": -0.03, "z_far": 1})],
		[0.88, m(GUARD, {"arm_far_up": -1.6, "arm_far_low": -0.05, "torso": 0.24, "hip_x": 14.0, "head": 0.06,
			"leg_far_up": 0.32, "leg_far_low": 0.12, "arm_near_up": 0.1, "arm_near_low": -2.5, "z_far": 1})],
		[1.05, m(GUARD, {"arm_far_up": -1.55, "arm_far_low": -0.12, "torso": 0.2, "hip_x": 12.0,
			"leg_far_up": 0.3, "leg_far_low": 0.1, "arm_near_up": 0.05, "arm_near_low": -2.4, "z_far": 1})],
		[1.25, GUARD],
		[1.4,  GUARD],
	]},
	# ---------------- ตาย (โดนโจมตี - เซ - เข่าทรุด - ล้มหงาย - กระแทกพื้น - นิ่ง)
	"die": {"length": 2.8, "loop": false, "keys": [
		[0.0,  {"arm_far_up": -0.1, "arm_near_up": 0.1, "arm_far_low": -0.1, "arm_near_low": -0.1}],
		[0.15, {"torso": -0.35, "head": -0.45, "hip_x": -18.0, "arm_near_up": -0.9, "arm_near_low": -0.6,
			"arm_far_up": -0.7, "arm_far_low": -0.6, "leg_near_up": -0.15, "leg_far_up": 0.1}],
		[0.45, {"torso": -0.45, "head": -0.3, "hip_x": -30.0, "hip_y": 48.0, "leg_far_up": -0.6, "leg_far_low": 1.1,
			"leg_near_up": -0.65, "leg_near_low": 1.15, "arm_near_up": -1.3, "arm_near_low": -0.4, "arm_far_up": -1.1, "arm_far_low": -0.4}],
		[0.8,  {"hip": -0.9, "torso": -0.2, "head": -0.2, "hip_x": -20.0, "hip_y": 140.0, "leg_far_up": -0.5, "leg_far_low": 0.8,
			"leg_near_up": -0.55, "leg_near_low": 0.9, "arm_near_up": -2.0, "arm_near_low": -0.2, "arm_far_up": -1.9, "arm_far_low": -0.2}],
		[1.02, {"hip": -1.52, "torso": 0.0, "head": 0.05, "hip_x": 15.0, "hip_y": 212.0, "leg_far_up": -0.1, "leg_far_low": 0.1,
			"leg_near_up": -0.12, "leg_near_low": 0.1, "arm_near_up": 0.2, "arm_near_low": -0.1, "arm_far_up": 0.05, "arm_far_low": -0.1}],
		[1.14, {"hip": -1.48, "torso": -0.02, "head": -0.12, "hip_x": 18.0, "hip_y": 198.0, "leg_far_up": -0.3, "leg_far_low": 0.3,
			"leg_near_up": -0.35, "leg_near_low": 0.35, "arm_near_up": -0.1, "arm_near_low": -0.3, "arm_far_up": -0.2, "arm_far_low": -0.3}],
		[1.35, {"hip": -1.52, "torso": 0.0, "head": 0.08, "hip_x": 20.0, "hip_y": 212.0, "leg_far_up": -0.05, "leg_far_low": 0.08,
			"leg_near_up": -0.08, "leg_near_low": 0.06, "arm_near_up": 0.12, "arm_near_low": 0.05, "arm_far_up": 0.15, "arm_far_low": 0.0}],
		[2.8,  {"hip": -1.52, "torso": 0.0, "head": 0.08, "hip_x": 20.0, "hip_y": 212.0, "leg_far_up": -0.05, "leg_far_low": 0.08,
			"leg_near_up": -0.08, "leg_near_low": 0.06, "arm_near_up": 0.12, "arm_near_low": 0.05, "arm_far_up": 0.15, "arm_far_low": 0.0}],
	]},
}
