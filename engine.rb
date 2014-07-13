require 'pp'
require './phase'

module Logger
	def log(msg)
		prefix = @log_prefix || ""
		full_msg = @log_prefix + msg
		if @match
			@match.log full_msg
		elsif @owner
			@owner.log full_msg
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
		"->(#{@args.map{|arg|arg.to_s}.join(",")})"
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

class Player
	attr_accessor :deck
	attr_accessor :hero
	attr_accessor :hand
	attr_accessor :field
	attr_accessor :player_id
	attr_accessor :ai
	attr_accessor :full_mana
	attr_accessor :mana

	include Logger

	def get_available_attack_targets
		targets = []
		taunts = @field.select do |card|
			card.has_text :taunt
		end.select do |card|
			not card.has_text :stealth
		end
		if taunts.count > 0
			targets = taunts
		else
			@field.each do |card|
				targets << card
			end
			targets << @hero
		end
		targets = targets.select do |card|
			not card.has_text :stealth
		end
		targets
	end

	def opponent
		me = self
		@match.players.select do |p|
			p != me
		end.first
	end

	def to_s
		"Player#{@player_id}(#{@hero.name})(#{@mana}/#{@full_mana}):hand(#{
			@hand.map(&:to_s).join(",")
		}):field(#{
			@field.map(&:to_s).join(",")
		})"
	end

	def mana_grow
		@full_mana += 1
		if @full_mana > 10
			@full_mana = 10
		end
	end

	def cost(cost_value)
		@mana -= cost_value
	end

	def restore_mana
		@mana = @full_mana
	end

	def build_card(card_name)
		new_card = Card[card_name]
		new_card.owner = self
		new_card
	end

	def get_all_actions
		actions = []
		actions << Action[:turn_end]
		actions += @hand.map{|card|
			card.get_actions_from_hand
		}.reduce([]){|x, y| x + y}
		actions += @field.map{|card|
			card.get_actions_from_field
		}.reduce([]){|x, y| x + y}
		actions += @hero.hero_power.get_actions_for_hero_power
		actions += @hero.get_actions_for_hero
	end

	def initialize(_deck, _ai, _pid)
		@player_id = _pid
		@log_prefix = "[Player#{@player_id}]"
		@deck = Deck.new(_deck)
		@ai = AI.new(_ai)
		@hero = @deck.hero
		@hand = []
		@field = []
	end

	def fire(card, event)
		if card.handlers.include? event.to_s
			@this_card = card
			card.log "respond to: #{event.to_s}"
			self.instance_eval(&(card.handlers[event.to_s]))
		end
	end

	def set_card_owner
		@deck.cards.each do |card|
			card.owner = self
		end
		@hand.each do |card|
			card.owner = self
		end
		@hero.owner = self
		@hero.hero_power.owner = self
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

	def get_current_view
		PlayerView.new @match
	end

	def choose(actions)
		@ai.choose actions, get_current_view
	end
end

require './execute_action'

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
		@players.each do |p|
			p.full_mana = 0
		end
		@players.each do |p|
			p.hero.hero_power = Card[p.hero.hero_power]
		end
		@players.each do |p|
			p.set_card_owner
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
end

class Text
	attr_accessor :name

	def initialize(_name)
		@name = _name
	end

	def ==(n)
		@name.to_s == n.to_s
	end
end

class Card
	attr_accessor :name
	attr_accessor :type
	attr_accessor :rarity
	attr_accessor :clas
	attr_accessor :cost
	attr_accessor :can_put_into_deck
	attr_accessor :handlers
	attr_accessor :owner
	attr_accessor :texts

	@@cards = {}

	def get_texts
		@texts
	end

	def remove_text(n)
		@texts = @texts.select do |t|
			t != n
		end
	end

	def has_text(n)
		get_texts.any? do |t|
			t == n
		end
	end

	def log(msg)
		@owner.log self.to_s + msg
	end

	def purge
		@owner.field.delete self
		@owner.hand.delete self
	end

	def Card.[](cn)
		Card.cards[cn].clone
	end

	def Card.cards
		@@cards
	end

	def initialize
		@type = Card.card_class_to_type(self.class.to_s).to_sym
		@can_put_into_deck = true
		@handlers = {}
		@texts = []
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

	def detail
		""
	end

	def to_ss
		"<#{@name}#{
			if self.is_a? CardMinion
				"(#{@attack} #{@health})"
			else
				""
			end
		}>"
	end

	def get_cost
		@cost
	end

	def get_actions_from_hand
		actions = []
		if get_cost <= @owner.mana
			if @type == :minion
				if @owner.field.count < 7 # Max field minion count = 7
					(@owner.field.count + 1).times do |position|
						actions << Action[:summon, self, position]
					end
				end
			end
		end
		actions
	end

	def get_actions_from_field
		actions = []
		this_card = self
		if @type == :minion
			if can_attack
				@targets = @owner.opponent.get_available_attack_targets
				@targets.each do |target|
					actions << Action[:attack, this_card, target]
				end
			end
		end
		actions
	end
end

module Living
	attr_accessor :health
	attr_accessor :has_attacked
	attr_accessor :race

	def take_damage(damage)
		if has_text :divine_shield
			remove_text :divine_shield
			log "Divine Shield Broken"
		else
			@health -= damage
		end
	end

	def do_damage(target_card)
		target_card.take_damage get_attack
	end

	def check_death
		if @health <= 0
			die
		end
	end

	def can_attack
		unless @has_attacked
			@has_attacked = 0
		end
		if @has_attacked > 0
			if @has_attacked == 1 and has_text :windfury
				true
			else
				false
			end
		elsif @type == :minion
			if @summon_sickness and not has_text(:charge)
				false
			else
				true
			end
		else
			true
		end
	end

	def get_attack
		@attack
	end

	def die
		@dead = true
		log "Destroyed"
		purge
	end
end

class CardMinion < Card
	include Living
	attr_accessor :attack
	attr_accessor :summon_sickness
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

	def get_actions_for_hero_power
		[]
	end
end

class LoseGame < Exception
	attr_accessor :hero

	def initialize(_hero)
		@hero = _hero
	end
end

class CardHero < Card
	include Living
	attr_accessor :hero_power

	def initialize
		super
		@can_put_into_deck = false
		@cost = 0
		@health = 30
	end

	def get_actions_for_hero
		[]
	end

	def die
		raise LoseGame.new(self)
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
			card
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

		[ :charge, :taunt, :windfury, :divine_shield, :stealth ].each do |m|
			define_method m do
				@product.texts << Text.new(m)
			end
		end

		def battlecry(&block)
			on :battlecry, &block
		end

		def on(event, &block)
			@product.handlers[event.to_s] = Proc.new(&block)
		end

		def need(&block)
		end

		def act(&block)
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

match = Match.new("test_deck.txt", "debug.rb", "test_deck.txt", "random_choose.rb")

match.start

#pp match
