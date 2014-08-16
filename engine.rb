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

class SenarioComplete < Exception
end

class LoseGame < Exception
	attr_accessor :hero

	def initialize(_hero)
		@hero = _hero
	end
end

require './pending_effect'
require './text'
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

cl = CardLoader.new
# the method load seems only eval code in main:Object context
# DIRTY HACK: add proxy method "card" to main:Object
self.class.class_eval do
	define_method :card do |name, &block|
		cl.card name, &block
	end
end
cl.load_all_cards

#match = Match.new("test/test_deck.txt", "debug.rb", "test/test_deck.txt", "test/random_choose.rb")
#match.start

