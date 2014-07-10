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
			fire card, :battlecry
		elsif action == :attack
			source_card = action[0]
			target_card = action[1]
			battle source_card, target_card
			source_card.has_attacked += 1
		end
	end

	def battle(source, target)
		source.do_damage target
		if target.type != :hero
			target.do_damage source
		end
		source.check_death
		target.check_death
	end
end
