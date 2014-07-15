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

	def all
		minions + [self.hero, opponent.hero]
	end

	def minions
		my_minions + opponent_minions
	end

	def my_minions
		field
	end

	def opponent_minions
		opponent.field.select do |card|
			not card.has_text? :stealth
		end
	end
end