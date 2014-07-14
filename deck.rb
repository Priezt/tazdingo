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

