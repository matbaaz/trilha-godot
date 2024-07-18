extends Node2D

func _process(delta):
	for body in $Area2D.get_overlapping_bodies():
		if body.is_in_group("player"):
			var player: Player = body
			player.speed = player.ritual_damage + 3
			queue_free()
