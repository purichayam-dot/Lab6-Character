# Lab 6 — ตัวละคร 3D จาก Blender + Mixamo Animation (Godot 4.7)

**ผู้จัดทำ:** ภูริชญา โมรา

## โครงสร้าง
| โฟลเดอร์ | เนื้อหา |
|---|---|
| `blender/` | `Purichaya.blend` ไฟล์โมเดล, `make_character.py` สคริปต์สร้างโมเดลจาก Primitive (Cube / Cylinder / UV Sphere) + โครงกระดูกชื่อแบบ Mixamo, `face.png` ใบหน้า |
| `godot/` | โปรเจกต์ Godot 4.7 — ฉาก `Scenes/Demo.tscn` |
| `screenshots/` | ภาพตัวอย่าง |

## ขั้นตอน
1. **Blender:** ขึ้นรูปตัวละคร Low-Poly จาก primitive พื้นฐาน (หัว/ผม/ลำตัว/แขน/ขา/รองเท้า) ใส่วัสดุสี และใบหน้าเป็นภาพ (`face.png` — เปลี่ยนเป็นรูปหน้าตัวเองได้)
2. **Rig:** สร้าง Armature ตั้งชื่อกระดูกตามมาตรฐาน Mixamo (`mixamorig_Hips`, `mixamorig_Spine` … ) ทำ Skin weights และท่า `TPose` แล้ว export เป็น `Purichaya.glb`
3. **Godot:** Import `.glb` → Skeleton3D → Retarget ด้วย **Mixamo BoneMap.tres** (SkeletonProfileHumanoid)
4. เพิ่ม Animation Library จาก [Godot4-OpenAnimationLibraries](https://github.com/catprisbrey/Godot4-OpenAnimationLibraries): `MeleeLib.res` + `ShooterLib.res` (รวม 220 ท่า)
5. **Demo Scene:** โชว์ท่าทาง 24 ท่า (เลือกจากรายการ / เล่นอัตโนมัติ / dropdown ทุกท่า) และโหมดเดินเล่น

## ปุ่มควบคุม (โหมดเดินเล่น — กด Tab)
WASD เดิน • Shift วิ่ง • Space กระโดด • J ฟันดาบ • K ต่อย • L เตะ • Q กลิ้ง • ลากเมาส์หมุนกล้อง • ล้อเมาส์ซูม

## เครดิต
- Animation libraries & Mixamo BoneMap: catprisbrey / Godot4-OpenAnimationLibraries
- Props: Quaternius, konta johanna, Flopsi (poly.pizza) • ฟอนต์ Kanit (OFL)
