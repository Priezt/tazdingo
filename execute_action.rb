class Player
	def execute(action)
		if action == :summon
			card = action[0]
			position = action[1]
			cost card.get_cost
			card.purge
			@field.insert position, card
			card.original_health = card.health
			card.summon_sickness = true
			fire card, :summon
			run card, :battlecry
		elsif action == :attack
			source_card = action[0]
			target_card = action[1]
			battle source_card, target_card
			source_card.has_attacked += 1
		elsif action == :act
			card = action[0]
			target = action[1]
			cost card.get_cost
			card.purge
			run card, :act, target
		elsif action == :equip
			card = action[0]
			cost card.get_cost
			card.purge
			@hero.equip_weapon card
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
