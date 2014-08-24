class Player
	def execute(action)
		if action == :summon
			card = action[0]
			position = action[1]
			summon card, position
			settle
		elsif action == :attack
			source_card = action[0]
			target_card = action[1]
			battle source_card, target_card
			settle
		elsif action == :cast
			card = action[0]
			target = action[1]
			cast card, target
			settle
		elsif action == :equip
			card = action[0]
			equip card
			settle
		elsif action == :turn_end
		else
			puts "Unknown action: #{action}"
		end
		@turn_action_count += 1
	end
end
