class Card
	attr_accessor :name
	attr_accessor :type
	attr_accessor :rarity
	attr_accessor :clas
	attr_accessor :cost
	attr_accessor :can_put_into_deck
	attr_accessor :handlers
	attr_accessor :jobs
	attr_accessor :owner
	attr_accessor :texts
	attr_accessor :born_id

	@@cards = {}

	alias old_clone clone

	def born
		@born_id = @owner.match.generate_born_id
	end

	def cleanup_text(timing)
		texts.clone.select do |t|
			t == :cleaner and t.clean_timing == timing
		end.each do |t|
			texts.delete t.text_to_clean
			texts.delete t
		end
	end

	def clone
		new_card = self.old_clone
		new_card.texts = self.texts.map do |t|
			t.clone
		end
		new_card
	end

	def get_texts
		all_cards = [@owner.hero] + @owner.field + [@owner.opponent.hero] + @owner.opponent.field
		extra_texts = []
		all_cards.each do |card|
			card.texts.each do |t|
				if t == :aura
					if @owner.instance_eval(&(t.targets_proc)).include? card
						extra_texts << t.buff_text.clone
					end
				end
			end
		end
		@texts + extra_texts
	end

	def check_deathrattle
		get_texts.select do |text|
			text == :deathrattle
		end.each do |text|
			@owner.match.todo PendingEffect.new(@owner, text.action_proc)
		end
	end

	def remove_text(n)
		@texts = @texts.select do |t|
			t != n
		end
	end

	def has_text?(n)
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
		@jobs = {}
		@texts = []
		@rarity = :normal
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
				"(#{get_attack} #{get_health})"
			else
				""
			end
		}>"
	end

	def get_cost
		@cost
	end

	def run(j, *args)
		@owner.run self, j, *args
	end

	def fire(event, *args)
		@owner.fire self, event, *args
	end

	def get_actions_from_field
		actions = []
		this_card = self
		if @type == :minion
			if can_attack?
				@targets = @owner.opponent.get_available_attack_targets
				@targets.each do |target|
					actions << Action[:attack, this_card, target]
				end
			end
		end
		actions
	end
end

require './living'

class CardMinion < Card
	include Living
	attr_accessor :attack
	attr_accessor :summon_sickness

	def get_actions_from_hand
		actions = []
		if @owner.field.count < 7 # Max field minion count = 7
			(@owner.field.count + 1).times do |position|
				actions << Action[:summon, self, position]
			end
		end
		actions
	end
end

class CardWeapon < Card
	attr_accessor :attack
	attr_accessor :durability

	def get_actions_from_hand
		actions = []
		actions << Action[:equip, self]
		actions
	end

	def reduce_durability
		@durability -= 1
	end

	def check_death
		if @durability <= 0
			check_deathrattle
			@owner.hero.weapon = nil
		end
	end

	def check_enrage
	end
end

class CardAbility < Card
	def get_actions_from_hand
		actions = []
		ability_targets = run :targets
		ability_targets.each do |t|
			actions << Action[:cast, self, t]
		end
		actions
	end
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
	attr_accessor :armor
	attr_accessor :weapon

	def initialize
		super
		@can_put_into_deck = false
		@cost = 0
		@health = 30
		@original_health = @health
		@armor = 0
		@weapon = nil
	end

	def gain_armor(_armor)
		@armor += _armor
	end

	def can_attack?
		get_attack > 0
	end

	def get_attack
		total_attack = 0
		if @weapon
			total_attack += @weapon.attack
		end
		total_attack
	end

	def get_actions_for_hero
		actions = []
		if can_attack?
			@owner.opponent.get_available_attack_targets.each do |target|
				actions << Action[:attack, self, target]
			end
		end
		actions
	end

	def die
		raise LoseGame.new(self)
	end

	alias _take_real_damage take_real_damage
	def take_real_damage(_damage)
		damage = _damage
		this_damage = [damage, @armor].min
		@armor -= this_damage
		damage -= this_damage
		_take_real_damage damage
	end
end

class CardSpecial < Card
end
