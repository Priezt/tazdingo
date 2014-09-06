class Player
	def heal(target, points)
		target.take_heal points
	end

	def equip(card)
		cost card.get_cost
		card.purge
		@hero.weapon = card
		card.born
		do_action card, :combo
	end

	def cast(card, target)
		cost card.get_cost
		card.purge
		run card, :act, target
	end

	def battle(source, target)
		source.do_damage target
		if target.type != :hero
			target.do_damage source
		end
		if source.type == :hero and source.weapon
			source.weapon.reduce_durability
		end
		source.has_attacked += 1
	end

	def put_at_last(card)
		put_at card, @field.count
	end

	alias put_at_right put_at_last

	def put_at(card, position)
		card.purge
		@field.insert position, card
		card.born
		card.original_health = card.health
		card.summon_sickness = true
		fire card, :summon
	end

	def summon(card, position)
		cost card.get_cost
		put_at card, position
		do_action card, :battlecry
		do_action card, :combo
	end

	def draw_card
		card = @deck.draw
		unless card.owner
			card.owner = self
		end
		log "Draw a card: #{card}"
		fire card, :draw
		if card.name != "Tired Card"
			@hand << card
			if @hand.count > 10
				log "Full hand"
				@hand[-1].purge
			end
		end
	end

	def silent(target)
		target.silent_self
	end

	def freeze(target)
		assign_text target, Text[:freeze]
	end

	def damage(target, points)
		target.take_damage points
	end

	def assign_text(target, text)
		target.texts << text
	end

	def assign_temp_text(target, text, clean_timing)
		assign_text(target, text)
		cleaner_text = Text.cleaner(text, clean_timing)
		assign_text(target, cleaner_text)
	end

	def delay(action_proc)
		@match.todo PendingEffect.new(self, action_proc)
	end
end

######################## For target select ########################

class Player
	def all
		minions + [self.hero, opponent.hero]
	end

	def minions
		friend_minions + enemy_minions
	end

	def friend_minions
		field
	end

	def enemy_minions
		opponent.field.select do |card|
			not card.has_text? :stealth
		end
	end

	def enemy_characters
		enemy_minions + [opponent.hero]
	end

	def friend_characters
		friend_minions + [hero]
	end
end
