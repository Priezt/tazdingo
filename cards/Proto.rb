card "Proto Blank" do
	type :minion
	clas :any
	number 1, 1, 1
end

card "Proto Charge" do
	type :minion
	clas :any
	number 1, 1, 2
	charge
end

card "Proto Taunt" do
	type :minion
	clas :any
	number 1, 1, 2
	taunt
end

card "Proto Windfury" do
	type :minion
	clas :any
	number 1, 1, 2
	windfury
end

card "Proto Divine Shield" do
	type :minion
	clas :any
	number 1, 1, 1
	divine_shield
end

card "Proto Stealth" do
	type :minion
	clas :any
	number 1, 1, 2
	stealth
end

card "Proto Battlecry" do
	type :minion
	clas :any
	number 1, 1, 1
	battlecry {
		draw_card
	}
end

card "Ability Heal" do
	type :ability
	number 1
	targets {
		all
	}
	act {|target|
		heal target, 3
	}
end

card "Ability Damage" do
	type :ability
	number 1
	targets {
		enemy_characters
	}
	act {|target|
		damage target, 5
	}
end

card "Proto Powerful" do
	type :minion
	number 1, 1, 1
	add_text :buff do
		@health_buff = 5
		@attack_buff = 5
	end
end

card "Proto Aura" do
	type :minion
	number 1, 1, 1
	add_text :aura do
		targets {
			friend_minions
		}
		buff {
			@attack_buff = 2
		}
	end
end

card "Weapon 1" do
	type :weapon
	number 1, 5, 2
end

card "Proto Temp Text" do
	type :minion
	number 1, 2, 2
	battlecry do
		assign_temp_text this_card, Text.new(:buff){
			@health_buff = 5
			@attack_buff = 5
		}, :end
	end
end

card "Proto Fire Element" do
	type :minion
	number 1, 6, 5
	battlecry do
		target_action = choose all.select{|card| card != this_card}.map{|card|
			Action[:target, card]
		}
		if target_action
			damage target_action[0], 3
		end
	end
end

card "Proto Deathrattle" do
	type :minion
	number 1, 1, 1
	deathrattle do
		draw_card
	end
end

card "Ability Silent All" do
	type :ability
	number 1
	targets {
		none
	}
	act {|target|
		(field + opponent.field).each do |card|
			silent card
		end
	}
end

card "Ability Freeze All" do
	type :ability
	number 1
	targets {
		none
	}
	act {|target|
		(field + opponent.field).each do |card|
			freeze card
		end
	}
end

card "Ability Combo" do
	type :ability
	number 1
	targets {
		none
	}
	no_combo {
		draw_card
	}
	combo {
		draw_card
		draw_card
	}
end

card "Weapon Combo" do
	type :weapon
	number 1, 1, 3
	no_combo {
	}
	combo {
		draw_card
	}
end

card "Proto Minion Combo" do
	type :minion
	number 1, 1, 3
	no_combo {
		draw_card
	}
	combo {
		draw_card
		draw_card
	}
end

card "Proto Listen Death" do
	type :minion
	number 1, 1, 2
	listen :death do |card|
		draw_card
	end
end

card "Proto Listen Summon" do
	type :minion
	number 1, 1, 2
	listen :summon do |card|
		if card != this_card
			draw_card
		end
	end
end

card "Ability Choose One" do
	type :ability
	number 1
	choose_one proc{
		draw_card
	}, proc{
		draw_card
		draw_card
	}
end

card "Minion Choose One" do
	type :minion
	number 1, 1, 2
	choose_one proc{
		draw_card
	}, proc{
		draw_card
		draw_card
	}
end

card "Proto Enrage" do
	type :minion
	number 1, 1, 5
	enrage proc{
		enrage_buff_text = Text.new(:buff){
			@attack_buff = 3
			@health_buff = 0
		}
		this_card.texts << enrage_buff_text
		this_card.instance_eval{
			@enrage_buff_text = enrage_buff_text
		}
	}, proc{
		this_card.texts.delete this_card.instance_eval{@enrage_buff_text}
	}
end

card "Proto Overload" do
	type :minion
	number 1, 8, 8
	overload 5
end

