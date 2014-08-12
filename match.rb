class Match
	attr_accessor :players
	attr_accessor :turn
	attr_accessor :logs
	attr_accessor :timing

	def in_senario?
		if @in_senario
			true
		else
			false
		end
	end

	def log(msg)
		txt = "[LOG]#{msg}"
		logs << txt
		puts txt
	end

	def current_player
		@players[@sub_turn]
	end

	def opponent_player
		@players[1 - @sub_turn]
	end

	def generate_born_id
		@increment_born_id += 1
		@increment_born_id
	end

	def initialize(deck1, ai1, deck2, ai2)
		@increment_born_id = 0
		@timing = :not_started
		@logs = []
		@players = []
		@players << Player.new(deck1, ai1, 1)
		@players << Player.new(deck2, ai2, 2)
		match = self
		@players.each do |p|
			p.instance_eval do
				@match = match
			end
		end
		@game_over = false
	end

	def prepare_to_start
		before_prepare
		log "Shuffle decks"
		@players.each do |p|
			p.deck.shuffle
		end
		3.times do
			current_player.draw_card
		end
		4.times do
			opponent_player.draw_card
		end
		@timing = :change_hand
		@players.each do |p|
			p.change_hand
		end
		after_prepare
	end

	def before_prepare
		log "Prepare to start game"
		@timing = :draw_initial_cards
	end

	def after_prepare
		@players.each do |p|
			p.full_mana = 0
			p.hero.hero_power = Card[p.hero.hero_power]
			p.set_card_owner
			p.hero.born
		end
	end

	def start
		@turn = 1
		@sub_turn = 0
		prepare_to_start
		log "Match start"
		winner = main_loop
		log "Winner is Player#{winner.player_id}"
	end

	def main_loop
		while true
			begin
				PhaseBegin.new(self).run
				PhaseFree.new(self).run
				PhaseEnd.new(self).run
			rescue LoseGame => lose_game
				loser_hero = lose_game.hero
				@players.each do |p|
					if p.hero != loser_hero
						return p
					end
				end
			rescue SenarioComplete => senario_complete
				return current_player
			end
			forward_turn
		end
	end

	def forward_turn
		@sub_turn += 1
		if @sub_turn == 2
			@sub_turn = 0
			@turn += 1
		end
		if @turn > 200
			raise "Too many turns"
		end
	end

	def settle
		@something_happened = false
		check_death
		check_enrage
		unless @something_happened
			return
		end
		settle
	end

	def get_check_targets
		players.map{|player|
			player.field + [player.hero] + (
				player.hero.weapon ? [player.hero.weapon] : []
			)
		}.flatten.sort_by{|card| card.born_id}
	end

	def check_death
		cards = get_check_targets
		cards.each do |card|
			card.check_death
		end
	end

	def check_enrage
		cards = get_check_targets
		cards.each do |card|
			card.check_enrage
		end
	end
end

