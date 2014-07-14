class PlayerView
	def initialize(m)
		@match = m
	end

	def opponent_hand
		@match.opponent_player.hand.count
	end

	def opponent_field
		@match.opponent_player.field
	end

	def opponent_deck
		@match.opponent_player.deck.cards.count
	end

	def opponent_hero
		@match.opponent_player.hero
	end

	def hand
		@match.current_player.hand
	end

	def field
		@match.current_player.field
	end

	def hero
		@match.current_player.hero
	end

	def deck
		@match.current_player.deck.cards.count
	end
end

