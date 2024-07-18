extends Node2D


func _process(delta):
	for body in $Area2D.get_overlapping_bodies():
		if body.is_in_group("player"):
			var player: Player = body
			player.health = player.health * 2
			player.max_health = player.max_health * 2
			queue_free()
