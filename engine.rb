require 'pp'

class Player
	attr_accessor :deck

	def initialize(_deck)
		@deck = Deck.new(_deck)
	end
end

class Match
	attr_accessor :players

	def initialize(deck1, deck2)
		@players = []
		@players << Player.new(deck1)
		@players << Player.new(deck2)
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

class Deck
	attr_accessor :hero
	attr_accessor :cards
	attr_accessor :name

	def initialize(fn)
		load_deck fn
	end

	def load_deck(fn)
		@name = fn
		f = File.open(fn)
		@hero = Card[f.readline.chomp]
		@cards = f.lines.map(&:chomp).map do |cn|
			Card[cn]
		end
		f.close
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
		one = OneCard.new name
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

pp Match.new("test_deck.txt", "test_deck.txt")
