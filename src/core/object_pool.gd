## ObjectPool — Generic pooling for high-frequency spawned objects.
## Usage: var pool = ObjectPool.new(scene, parent, size)
class_name ObjectPool
extends RefCounted

var _pool: Array[Node] = []
var _scene: PackedScene
var _parent: Node

func _init(scene: PackedScene, parent: Node, initial_size: int = 20) -> void:
	_scene = scene
	_parent = parent
	for i in initial_size:
		_create_instance()

func _create_instance() -> Node:
	var instance := _scene.instantiate()
	instance.process_mode = Node.PROCESS_MODE_DISABLED
	instance.hide()
	_parent.add_child(instance)
	_pool.append(instance)
	return instance

func get_instance() -> Node:
	for node in _pool:
		if not node.visible:
			node.process_mode = Node.PROCESS_MODE_INHERIT
			node.show()
			return node
	# Pool exhausted — grow
	var node := _create_instance()
	node.process_mode = Node.PROCESS_MODE_INHERIT
	node.show()
	return node

func release(node: Node) -> void:
	node.process_mode = Node.PROCESS_MODE_DISABLED
	node.hide()
	if node.has_method("reset"):
		node.reset()

func release_all() -> void:
	for node in _pool:
		release(node)
