class Player
	attr_accessor :deck
	attr_accessor :hero
	attr_accessor :hand
	attr_accessor :field
	attr_accessor :player_id
	attr_accessor :ai
	attr_accessor :full_mana
	attr_accessor :mana
	attr_accessor :match
	attr_accessor :turn_action_count

	include Logger

	def settle
		@match.settle
	end

	def get_available_attack_targets
		targets = []
		taunts = @field.select do |card|
			card.has_text? :taunt
		end.select do |card|
			not card.has_text? :stealth
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
			not card.has_text? :stealth
		end
		targets
	end

	def opponent
		me = self
		@match.players.select do |p|
			p != me
		end.first
	end

	alias old_to_s to_s

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

	def available_mana
		@mana - @current_overload
	end

	def get_all_actions
		actions = []
		actions << Action[:turn_end]
		actions += @hand.map{|card|
			if card.get_cost <= card.owner.available_mana
				card.get_actions_from_hand
			else
				[]
			end
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
		@this_card_stack = []
		@turn_action_count = 0
		@current_overload = 0
		@next_overload = 0
		@full_mana = 0
	end

	def set_overload
		@current_overload = @next_overload
		@next_overload = 0
	end

	def none
		[:none]
	end

	def push_this_card(card)
		@this_card_stack.push card
	end

	def pop_this_card
		@this_card_stack.pop
	end

	def this_card
		@this_card_stack.last
	end

	def do_action(card, action_name)
		card.texts.select do |t|
			t == action_name
		end.each do |t|
			push_this_card card
			result = self.instance_exec(&(t.action_proc))
			pop_this_card
			result
		end
	end

	def run(card, j, *args) # run jobs
		if card.jobs.include? j.to_s
			push_this_card card
			result = self.instance_exec(*args, &(card.jobs[j.to_s]))
			pop_this_card
			result
		end
	end

	def fire(card, event, *args)
		if card.handlers.include? event.to_s
			push_this_card card
			card.log "respond to: #{event.to_s}"
			result = self.instance_exec(*args, &(card.handlers[event.to_s]))
			pop_this_card
			result
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
		if actions.count == 0
			nil
		else
			@ai.choose actions, get_current_view
		end
	end
end

require './effect'
