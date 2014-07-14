require 'pp'

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

class LoseGame < Exception
	attr_accessor :hero

	def initialize(_hero)
		@hero = _hero
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

require './phase'
require './ai'
require './action'
require './player_view'
require './player'
require './execute_action'
require './match'
require './card'
require './match'
require './deck'
require './card_loader'

CardLoader.new.load_all_cards

match = Match.new("test_deck.txt", "debug.rb", "test_deck.txt", "random_choose.rb")
match.start
