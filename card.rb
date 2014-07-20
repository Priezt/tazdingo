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

	@@cards = {}

	alias old_clone clone

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
	attr_accessor :original_health
	attr_accessor :has_attacked
	attr_accessor :race

	def max_health
		health_buff = get_texts.map {|t|
			if t == :buff
				t.health_buff || 0
			else
				0
			end
		}.reduce(0){|x, y| x + y}
		@original_health + health_buff
	end

	def take_heal(points)
		old_health = @health
		@health += points
		if @health > max_health
			@health = max_health
		end
		new_health = @health
		log "healed #{old_health} -> #{new_health}"
	end

	def take_damage(_damage)
		damage = _damage
		old_health = get_health
		if has_text? :divine_shield
			remove_text :divine_shield
			log "Divine Shield Broken"
		else
			get_texts.each do |t|
				if damage > 0 and t == :buff and t.health > 0
					this_damage = [damage, t.health].min
					t.health -= this_damage
					damage -= this_damage
				end
			end
			@health -= damage
		end
		new_health = get_health
		log "damaged #{old_health} -> #{new_health}"
	end

	def do_damage(target_card)
		target_card.take_damage get_attack
	end

	def check_death
		if get_health <= 0
			die
		end
	end

	def can_attack
		unless @has_attacked
			@has_attacked = 0
		end
		if @has_attacked > 0
			if @has_attacked == 1 and has_text? :windfury
				true
			else
				false
			end
		elsif @type == :minion
			if @summon_sickness and not has_text?(:charge)
				false
			else
				true
			end
		else
			true
		end
	end

	def get_attack
		attack_buff = get_texts.map {|t|
			if t == :buff
				t.attack_buff || 0
			else
				0
			end
		}.reduce(0){|x, y| x + y}
		@attack + attack_buff
	end

	def get_health
		health_buff = get_texts.map {|t|
			if t == :buff
				t.health
			else
				0
			end
		}.reduce(0){|x, y| x + y}
		@health + health_buff
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
end

class CardAbility < Card
	def get_actions_from_hand
		actions = []
		ability_targets = run :targets
		ability_targets.each do |t|
			actions << Action[:act, self, t]
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

	def get_actions_for_hero
		[]
	end

	def die
		raise LoseGame.new(self)
	end
end

class CardSpecial < Card
end
