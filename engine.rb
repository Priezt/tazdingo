require 'pp'
require './phase'

module Logger
	def log(msg)
		if @log_prefix
			@match.log @log_prefix+msg
		else
			@match.log msg
		end
	end
end

class Action
	def Action.[](*args)
		Action.new *args
	end

	def initialize(*args)
		@args = args
	end

	def name
		@args[0]
	end

	def arg(idx)
		@args[idx + 1]
	end

	def [](idx)
		self.arg(idx)
	end

	def ==(action_name)
		self.name.to_s == action_name.to_s
	end

	def to_s
		"(#{@args.map{|arg|arg.to_s}.join(",")})"
	end
end

class AI
	def initialize(ai_filename)
		self.load_ai(ai_filename)
	end

	def load_ai(ai_filename)
		puts "Loading AI: #{ai_filename}"
		choose_function_definition = File.open(ai_filename).read()
		#@choose_block = eval("proc{|actions, view|\n#{choose_function_definition}\n}")
		@choose_block = eval("proc{|*args|\nactions=args[0]\nview=args[1]\n#{choose_function_definition}\n}")
	end

	def choose(*args)
		@choose_block.call *args
	end
end

class Player
	attr_accessor :deck
	attr_accessor :hero
	attr_accessor :hand
	attr_accessor :player_id
	attr_accessor :ai

	include Logger

	def initialize(_deck, _ai, _pid)
		@player_id = _pid
		@log_prefix = "[Player#{@player_id}]"
		@deck = Deck.new(_deck)
		@ai = AI.new(_ai)
		@hero = @deck.hero
		@hand = []
	end

	def draw_card
		card = @deck.draw
		@hand << card
		log "Draw a card: #{card}"
	end

	def change_hand
		keeping = []
		changing = []
		@hand.each_with_index do |card, idx|
			result = choose [
				Action[:keep, card, idx],
				Action[:change, card, idx],
			]
			if result == :keep
				log "Keep #{card}"
				keeping << card
			else
				log "Change #{card}"
				changing << card
			end
		end
		@hand = keeping
		changing.each do |card|
			@deck.push_card card
		end
		@deck.shuffle
		changing.count.times do
			draw_card
		end
	end

	def choose(actions)
		@ai.choose actions, @match
	end
end

class Match
	attr_accessor :players
	attr_accessor :turn
	attr_accessor :logs
	attr_accessor :timing

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

	def initialize(deck1, ai1, deck2, ai2)
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
		puts "Prepare to start game"
		@timing = :draw_initial_cards
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
	end

	def start
		@turn = 1
		@sub_turn = 0
		prepare_to_start
		log "Match start"
		main_loop
	end

	def main_loop
		while true
			PhaseBegin.new(self).run
			PhaseFree.new(self).run
			PhaseEnd.new(self).run
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
end

class Card
	attr_accessor :name
	attr_accessor :type
	attr_accessor :rarity
	attr_accessor :clas
	attr_accessor :cost
	attr_accessor :can_put_into_deck

	@@cards = {}

	def Card.[](cn)
		Card.cards[cn].clone
	end

	def Card.cards
		@@cards
	end

	def initialize
		@type = Card.card_class_to_type(self.class.to_s).to_sym
		@can_put_into_deck = true
	end

	def Card.type_to_card_class(t)
		"Card" + (t.to_s.split("_").map do |part|
			part.capitalize
		end.join "")
	end

	def Card.card_class_to_type(cc)
		cc.sub(/.*:/, "").sub(/^Card/, "").gsub(/([a-z])([A-Z])/, "\\1_\\2").downcase
	end

	def to_s
		"<#{@name}>"
	end
end

class CardMinion < Card
	attr_accessor :race
	attr_accessor :attack
	attr_accessor :health
end

class CardWeapon < Card
	attr_accessor :attack
	attr_accessor :durability
end

class CardAbility < Card
end

class CardHeroPower < Card
	def initialize
		super
		@can_put_into_deck = false
		@cost = 2
	end
end

class CardHero < Card
	attr_accessor :hero_power

	def initialize
		super
		@can_put_into_deck = false
		@cost = 0
		@health = 30
	end
end

class CardSpecial < Card
end

class Deck
	attr_accessor :hero
	attr_accessor :cards
	attr_accessor :name

	def initialize(fn)
		load_deck fn
		@tired_count = 0
	end

	def load_deck(fn)
		@name = fn
		f = File.open(fn)
		@hero = Card[f.readline.chomp]
		@cards = f.each_line.map(&:chomp).map do |cn|
			Card[cn]
		end
		f.close
	end

	def shuffle
		@cards.sort_by!{rand}
	end

	def draw
		if cards.count > 0
			@cards.shift
		else
			card = Card["Tired Card"]
			@tired_count += 1
			damage = @tired_count
			card.instance_eval do
				@damage = damage
			end
		end
	end

	def push_card(card)
		@cards.unshift card
	end
end

class CardLoader
	class OneCard
		attr_accessor :product

		def type(t)
			@product = eval(Card.type_to_card_class(t)).new
		end

		def cannot_put_into_deck
			@product.can_put_into_deck = false
		end

		[ :clas, :rarity, :cost, :attack, :health, :hero_power ].each do |m|
			define_method m do |v|
				@product.send "#{m}=", v
			end
		end
	end

	def card(name, &detail)
		one = OneCard.new
		one.instance_eval &detail
		one.product.name = name
		Card.cards[name] = one.product
	end
	
	def load_one_card(cn)
		puts "Loading card: #{cn}"
		eval File.open("cards/#{cn}.rb").read()
	end

	def load_all_cards
		Dir["cards/*.rb"].each do |path|
			next unless path =~ /\/(\w+)\.rb$/
			load_one_card $1
		end
	end
end

CardLoader.new.load_all_cards

match = Match.new("test_deck.txt", "random_choose.rb", "test_deck.txt", "random_choose.rb")

match.start

#pp match
