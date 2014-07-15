class CardLoader
	class OneCard
		attr_accessor :product

		def type(t)
			@product = eval(Card.type_to_card_class(t)).new
		end

		def cannot_put_into_deck
			@product.can_put_into_deck = false
		end

		[ :clas, :rarity, :cost, :attack, :health, :hero_power ].each do |m|
			define_method m do |v|
				@product.send "#{m}=", v
			end
		end

		[ :charge, :taunt, :windfury, :divine_shield, :stealth ].each do |m|
			define_method m do
				@product.texts << Text.new(m)
			end
		end

		def on(event, &block)
			@product.handlers[event.to_s] = Proc.new(&block)
		end

		def job(j, &block)
			@product.jobs[j.to_s] = Proc.new(&block)
		end

		[ :battlecry, :targets, :act ].each do |m|
			define_method m do |&block|
				job m, &block
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

