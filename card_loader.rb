class CardLoader
	class OneCard
		attr_accessor :product

		def type(t)
			@product = eval(Card.type_to_card_class(t)).new
		end

		def cannot_put_into_deck
			@product.can_put_into_deck = false
		end

		[ :clas, :rarity, :cost, :attack, :health, :hero_power, :durability ].each do |m|
			define_method m do |v|
				@product.send "#{m}=", v
			end
		end

		[ :charge, :taunt, :windfury, :divine_shield, :stealth ].each do |m|
			define_method m do
				@product.texts << Text[m]
			end
		end

		def add_text(text_name, &block)
			@product.texts << Text[text_name, &block]
		end

		def on(event, &block)
			@product.handlers[event.to_s] = Proc.new(&block)
		end

		def job(j, &block)
			@product.jobs[j.to_s] = Proc.new(&block)
		end

		[ :targets, :act ].each do |m| # For Ability
			define_method m do |&block|
				job m, &block
			end
		end

		[ :battlecry, :deathrattle ].each do |m|
			define_method m do |&block|
				@product.texts << Text.action(m, &block)
			end
		end

		def number(*args)
			if @product.type == :minion
				cost args[0]
				attack args[1]
				health args[2]
			elsif @product.type == :ability
				cost args[0]
			elsif @product.type == :weapon
				cost args[0]
				attack args[1]
				durability args[2]
			elsif @product.type == :secret
				cost args[0]
			end
		end

		def no_combo(&block)
			@combos = []
			@combos << proc(&block)
		end

		def combo(&block)
			@combos << proc(&block)
			combos = @combos
			combo_action = proc{|*args|
				if @turn_action_count > 0
					self.instance_exec(*args, &(combos[1]))
				else
					self.instance_exec(*args, &(combos[0]))
				end
			}
			if @product.type == :ability
				job :act, &(combo_action)
			elsif @product.type == :weapon
				@product.texts << Text.action(:combo, &(combo_action))
			elsif @product.type == :minion
				@product.texts << Text.action(:combo, &(combo_action))
			end
		end

		def choose_one(proc1,proc2)
			choices = [proc1, proc2]
			choose_one_action = proc{|*args|
				chosen_action = choose [1, 2].map{|n|
					Action[:choose_one, n]
				}
				if chosen_action[0] == 1
					chosen_action = choices[0]
				elsif chosen_action[0] == 2
					chosen_action = choices[1]
				else
					raise "Choice must be 1 or 2"
				end
				self.instance_exec(*args, &(chosen_action))
			}
			if @product.type == :ability
				targets {
					none
				}
				job :act, &(choose_one_action)
			elsif @product.type == :minion
				@product.texts << Text.action(:choose_one, &(choose_one_action))
			end
		end

		def listen(event, &block)
			text = Text.action(:listen, &block)
			text.event = event
			@product.texts << text
		end
	end

	def card(name, &detail)
		one = OneCard.new
		one.instance_eval &detail
		one.product.name = name
		Card.cards[name] = one.product
	end
	
	def load_one_card_file(cn)
		puts "Loading card file: #{cn}"
		#instance_eval File.open("cards/#{cn}.rb").read()
		load "cards/#{cn}.rb"
	end

	def load_all_cards
		Dir["cards/*.rb"].each do |path|
			next unless path =~ /\/(\w+)\.rb$/
			load_one_card_file $1
		end
	end
end

