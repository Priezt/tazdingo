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
			elsif @type == :ability
				ability_targets = fire :targets
				ability_targets.each do |t|
					actions << Action[:shoot, t]
				end
			end
		end
		actions
	end

	def fire(event)
		@owner.fire self, event
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
