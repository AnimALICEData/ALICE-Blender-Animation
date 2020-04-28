def subtract(that,fromThat):
    bpy.ops.object.select_all(action='DESELECT')
    bpy.data.objects[fromThat.name].select = True
    bpy.context.scene.objects.active = None
    bpy.context.scene.objects.active = fromThat
    bpy.ops.object.modifier_add(type='BOOLEAN')
    bpy.context.object.modifiers["Boolean"].operation = 'DIFFERENCE'
    bpy.context.object.modifiers["Boolean"].object = bpy.data.objects[that.name]
    bpy.ops.object.modifier_apply(apply_as='DATA', modifier="Boolean")
    bpy.ops.object.select_all(action='DESELECT')
    bpy.data.objects[that.name].select = True
    bpy.ops.object.delete()

def createMaterial(name,R,G,B,shadows,cast_shadows,transparency,alpha,emit,specular_alpha,fresnel_factor,fresnel):
    bpy.data.materials.new(name=name)
    bpy.data.materials[name].diffuse_color = (R, G, B)
    bpy.data.materials[name].use_shadows = shadows
    bpy.data.materials[name].use_cast_shadows = cast_shadows
    bpy.data.materials[name].use_transparency = transparency
    bpy.data.materials[name].alpha = alpha
    bpy.data.materials[name].emit = emit
    bpy.data.materials[name].specular_alpha = specular_alpha
    bpy.data.materials[name].raytrace_transparency.fresnel_factor = fresnel_factor
    bpy.data.materials[name].raytrace_transparency.fresnel = fresnel

def joinObjects(objs): # objs is a list of objects that MUST have a name
    bpy.ops.object.select_all(action='DESELECT')
    bpy.context.scene.objects.active = None
    bpy.context.scene.objects.active = objs[0]
    for ob in objs:
        bpy.data.objects[ob.name].select = True
    bpy.ops.object.join()
