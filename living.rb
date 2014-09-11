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

	def into_enrage
		card = self
		delay proc{
			do_action card, :into_enrage
		}
	end

	def outof_enrage
		card = self
		delay proc{
			do_action card, :outof_enrage
		}
	end

	def take_heal(_points)
		old_health = get_health
		points = _points
		if points > 0 and @health < @original_health
			this_points = [points, @original_health - @health].min
			@health += this_points
			points -= this_points
		end
		get_texts.reverse.each do |t|
			if points > 0 and t == :buff and t.health < t.health_buff
				this_points = [points, t.health_buff - t.health].min
				t.health += this_points
				points -= this_points
			end
		end
		new_health = get_health
		if new_health == max_health
			outof_enrage
		end
		log "healed #{old_health} -> #{new_health}"
	end

	def take_real_damage(_damage)
		damage = _damage
		get_texts.each do |t|
			if damage > 0 and t == :buff and t.health > 0
				this_damage = [damage, t.health].min
				t.health -= this_damage
				damage -= this_damage
			end
		end
		@health -= damage
		into_enrage
	end

	def take_damage(_damage)
		damage = _damage
		old_health = get_health
		if has_text? :divine_shield
			remove_text :divine_shield
			log "Divine Shield Broken"
		else
			take_real_damage damage
		end
		new_health = get_health
		log "damaged #{old_health} -> #{new_health}"
	end

	def do_damage(target_card)
		target_card.take_damage get_attack
	end

	def check_death
		if get_health <= 0
			check_deathrattle
			this_card = self
			delay proc{
				@match.check_death_listener this_card
			}
			die
		end
	end

	def summoned
		this_card = self
		delay proc{
			@match.check_summon_listener this_card
		}
	end

	def check_enrage
	end

	def can_attack?
		unless @has_attacked
			@has_attacked = 0
		end
		if has_text? :freeze
			false
		elsif @has_attacked > 0
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
