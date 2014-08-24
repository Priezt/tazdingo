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
			if @product.type == :ability
				@acts = []
				@acts << proc(&block)
			end
		end

		def combo(&block)
			if @product.type == :ability
				@acts << proc(&block)
				acts = @acts
				job :act do |*args|
					if @turn_action_count > 0
						self.instance_exec(*args, &(acts[1]))
					else
						self.instance_exec(*args, &(acts[0]))
					end
				end
			end
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

