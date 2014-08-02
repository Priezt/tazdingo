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

	def prepare_to_start
		before_prepare
		[1,2].each do |n|
			p = @players[n - 1]
			eval("@player#{n}_field").count.times do
				p.draw_card
				card = p.hand[0]
				p.put_at_last card
			end
			eval("@player#{n}_hand").count.times do
				p.draw_card
			end
		end
		after_prepare
	end

	def set_defaults
		@player1_hero = "Jaina Proudmoore"
		@player1_hand = []
		@player1_field = []
		@player1_deck = ["Proto Blank"] * 5
		@player1_mana = 10
		@player2_hero = "Jaina Proudmoore"
		@player2_hand = []
		@player2_field = []
		@player2_deck = ["Proto Blank"] * 5
		@player2_mana = 10
	end

	def Senario.run(&block)
		senario = Senario.new(&block)
		senario.run
	end

	def name(senario_name)
		@senario_name = senario_name
	end

	def run
		log "Senario: #{@senario_name}"
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

	def ai(procs)
		ai_procs = procs
		@ai_proc = proc{|*args|
			ai_proc = ai_procs.shift
			unless ai_proc
				raise SenarioComplete.new
			end
			ai_proc.call *args
		}
	end

	def player_mana(mana)
		@player1_mana = mana
	end

	def opponent_mana(mana)
		@player2_mana = mana
	end
end
