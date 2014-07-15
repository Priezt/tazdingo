class Player
	def heal(target, points)
		target.take_heal points
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

	def damage(target, points)
		target.take_damage points
		target.check_death
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
