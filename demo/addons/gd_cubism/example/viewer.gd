# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2023 MizunagiKB <mizukb@live.jp>
extends Control


const ENABLE_MOTION_FINISHED := false

var cubism_model: GDCubismUserModel
var last_motion = null
var last_expression = null
var pressed: bool

func recalc_model_position(model: GDCubismUserModel):
	if model.assets == "":
		return

	var canvas_info: Dictionary = model.get_canvas_info()

	if canvas_info.is_empty() != true:
		var vct_viewport_size = Vector2(get_viewport_rect().size)
		var scale: float = vct_viewport_size.y / max(canvas_info.size_in_pixels.x, canvas_info.size_in_pixels.y)
		model.position = vct_viewport_size / 2.0
		model.scale = Vector2(scale, scale)


func setup(pathname: String):
	if pathname == "":
		return
	last_motion = null
	last_expression = null
	cubism_model.stop_motion()
	cubism_model.stop_expression()
	cubism_model.assets = pathname

	recalc_model_position(cubism_model)

	var idx: int = 0
	var dict_motion = cubism_model.get_motions()
	$UI/ItemListMotion.clear()
	for k in dict_motion:
		for v in range(dict_motion[k]):
			$UI/ItemListMotion.add_item("{0}_{1}".format([k, v]))
			$UI/ItemListMotion.set_item_metadata(idx, {"group": k, "no": v})
			idx += 1

	$UI/ItemListExpression.clear()
	for item in cubism_model.get_expressions():
		$UI/ItemListExpression.add_item(item)

	cubism_model.playback_process_mode = GDCubismUserModel.IDLE


func model3_search(dirname: String):

	var dir: DirAccess = DirAccess.open(dirname)
	if dir == null:
		return

	dir.list_dir_begin()
	var name = dir.get_next()
	while name != "":
		if dir.current_is_dir():
			model3_search(dirname.path_join(name))
		else:
			if name.ends_with(".model3.json"):
				print(dirname.path_join(name))
				$UI/OptModel.add_item(dirname.path_join(name))
		name = dir.get_next()


func _ready():
	cubism_model = GDCubismUserModel.new()
	self.add_child(cubism_model)

	if ENABLE_MOTION_FINISHED == true:
		cubism_model.motion_finished.connect(_on_motion_finished)

	$UI/OptModel.clear()
	$UI/OptModel.add_item("")
	model3_search("res://addons/gd_cubism/example/res/live2d")

#func _process(delta: float) -> void:
	#var parameters=$Sprite2D/GDCubismUserModel.get_parameters()
	#print(parameters)

func _on_motion_finished():
	cubism_model.start_motion(
		last_motion.group,
		last_motion.no,
		GDCubismUserModel.PRIORITY_FORCE
	)


func _on_opt_model_item_selected(index):
	setup($UI/OptModel.get_item_text(index))


func _on_item_list_motion_item_selected(index):
	var motion = $UI/ItemListMotion.get_item_metadata(index)
	# 点击同一个 motion：停止并重置
	if last_motion and last_motion.group == motion.group and last_motion.no == motion.no:
		last_motion = null
		cubism_model.stop_motion()
		for param in cubism_model.get_parameters():
			param.reset()
		return
	# 点击不同 motion：先停旧的，再播放新的
	if last_motion:
		cubism_model.stop_motion()
	var m = cubism_model.start_motion(motion.group, motion.no, GDCubismUserModel.PRIORITY_FORCE)
	if m.error != GDCubismMotionQueueEntryHandle.HandleError.OK:
		print("Motion start failed: ", motion.group, "_", motion.no)
		return
	last_motion = motion


func _on_item_list_expression_item_selected(index):
	var expression_id = $UI/ItemListExpression.get_item_text(index)
	if last_expression == expression_id:
		last_expression = null
		cubism_model.stop_expression()
		for param in cubism_model.get_parameters():
			param.reset()
		return
	cubism_model.start_expression(expression_id)
	last_expression = expression_id
	
#func _input(event):
		#if event as InputEventMouseButton:
			#pressed = event.is_pressed()
#
		#if event as InputEventMouseMotion:
			#if pressed == true:
				## Convert to Node using mouse coordinates for display
				#var local_pos = event.position-Vector2(get_tree().root.content_scale_size)/2
				## Adjust the converted coordinates to the display size of SubViewport
				#var render_size: Vector2 = Vector2(get_tree().root.content_scale_size) *Vector2(1,-1)
				#local_pos /= render_size
				#$Sprite2D/GDCubismUserModel/GDCubismEffectTargetPoint.set_target(local_pos)
			#else:
				#$Sprite2D/GDCubismUserModel/GDCubismEffectTargetPoint.set_target(Vector2.ZERO)

func _on_gd_cubism_effect_hit_area_hit_area_entered(model: GDCubismUserModel, id: String) -> void:
	print(id)


func _on_h_slider_value_changed(value: float) -> void:
	$Sprite2D/GDCubismUserModel/GDCubismEffectCustom.value=value


func _on_item_list_expression_item_clicked(index: int, at_position: Vector2, mouse_button_index: int) -> void:
	var expression_id = $UI/ItemListExpression.get_item_text(index)
	if last_expression == expression_id:
		last_expression = null
		cubism_model.stop_expression()
		#for param in cubism_model.get_parameters():
			#param.reset()
		return
	cubism_model.start_expression(expression_id)
	last_expression = expression_id
