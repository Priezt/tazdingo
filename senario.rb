class Senario < Match
	def initialize(&block)
		@in_senario = true
		set_defaults
		self.instance_eval &block
		[1, 2].each do |n|
			File.open(",senario_deck_#{n}.tmp", "w") do |f|
				f.puts eval("@player#{n}_hero")
				[eval("@player#{n}_field") + eval("@player#{n}_hand") + eval("@player#{n}_deck")].each do |c|
					f.puts c
				end
			end
		end
		super ",senario_deck_1.tmp", @ai_proc, ",senario_deck_2.tmp", "test/always_first.rb"
	end

	def set_defaults
		@player1_hero = "Jaina Proudmoore"
		@player1_hand = []
		@player1_field = []
		@player1_deck = []
		@player1_mana = 5
		@player2_hero = "Jaina Proudmoore"
		@player2_hand = []
		@player2_field = []
		@player2_deck = []
		@player2_mana = 5
	end

	def Senario.run(&block)
		senario = Senario.new(&block)
		senario.run
	end

	def run
		start
	end

	def player_hero(name)
		@player1_hero = name
	end

	def player_hand(cards)
		@player1_hand = cards
	end

	def player_field(cards)
		@player1_field = cards
	end

	def player_deck(cards)
		@player1_deck = cards
	end

	def opponent_hero(name)
		@player2_hero = name
	end

	def opponent_hand(cards)
		@player2_hand = cards
	end

	def opponent_field(cards)
		@player2_field = cards
	end

	def opponent_deck(cards)
		@player2_deck = cards
	end

	def ai(&block)
		@ai_proc = proc(&block)
	end

	def player_mana(mana)
		@player1_mana = mana
	end

	def opponent_mana(mana)
		@player2_mana = mana
	end
end
