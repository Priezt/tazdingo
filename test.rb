require './engine'
require './senario'

Senario.run do
	# player
	player_hero "Jaina Proudmoore"
	player_hand [
		"Proto Windfury",
		"Proto Windfury",
	]
	player_field [
		"Proto Charge",
	]
	player_deck [
		"Ability Damage",
	]
	# opponent
	opponent_hero "Jaina Proudmoore"
	opponent_hand [
		"Proto Powerful",
		"Proto Powerful",
	]
	opponent_field [
		"Proto Powerful",
		"Proto Powerful",
	]
	opponent_deck [
		"Proto Powerful",
		"Proto Powerful",
	]
	ai {|actions, view|
		actions[0]
	}
end
