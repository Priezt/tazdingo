class Player
	def execute(action)
		if action == :summon
			card = action[0]
			position = action[1]
			summon card, position
		elsif action == :attack
			source_card = action[0]
			target_card = action[1]
			battle source_card, target_card
		elsif action == :cast
			card = action[0]
			target = action[1]
			cast card, target
		elsif action == :equip
			card = action[0]
			equip card
		end
	end
end
