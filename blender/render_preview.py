import bpy, math, sys
from mathutils import Vector
bpy.ops.wm.open_mainfile(filepath="Purichaya.blend")
sc = bpy.context.scene
sc.render.engine = "BLENDER_WORKBENCH"
sc.display.shading.light = "STUDIO"
sc.display.shading.color_type = "MATERIAL"
sc.render.resolution_x = 900; sc.render.resolution_y = 900
sc.render.film_transparent = False
sc.world = bpy.data.worlds.new("W") if not sc.world else sc.world
cam_data = bpy.data.cameras.new("Cam"); cam = bpy.data.objects.new("Cam", cam_data); sc.collection.objects.link(cam); sc.camera = cam
for i, ang in enumerate([0, 35, 180]):
    r = 3.2
    a = math.radians(ang)
    cam.location = (math.sin(a) * r, -math.cos(a) * r, 1.1)
    d = Vector((0, 0, 0.95)) - cam.location
    cam.rotation_euler = d.to_track_quat('-Z', 'Y').to_euler()
    sc.render.filepath = f"/home/claude/shots/char_{i}.png"
    bpy.ops.render.render(write_still=True)
