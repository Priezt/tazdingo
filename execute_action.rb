class Player
	def execute(action)
		if action == :summon
			card = action[0]
			position = action[1]
			cost card.get_cost
			card.purge
			@field.insert position, card
			card.summon_sickness = true
			fire card, :summon
		elsif action == :attack
			source_card = action[0]
			target_card = action[1]
			source_card.has_attacked = true
		end
	end
end
