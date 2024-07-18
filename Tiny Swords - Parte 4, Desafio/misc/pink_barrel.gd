extends Node2D

func _process(delta):
	for body in $Area2D.get_overlapping_bodies():
		if body.is_in_group("player"):
			var player: Player = body
			player.ritual_damage = player.ritual_damage * 2
			queue_free()
