card "Proto Charge" do
	type :minion
	clas :any
	rarity :normal
	number 1, 1, 2
	charge
end

card "Proto Taunt" do
	type :minion
	clas :any
	rarity :normal
	number 1, 1, 2
	taunt
end

card "Proto Windfury" do
	type :minion
	clas :any
	rarity :normal
	number 1, 1, 2
	windfury
end

card "Proto Divine Shield" do
	type :minion
	clas :any
	rarity :normal
	number 1, 1, 2
	divine_shield
end

card "Proto Stealth" do
	type :minion
	clas :any
	rarity :normal
	number 1, 1, 2
	stealth
end

card "Proto Battlecry" do
	type :minion
	clas :any
	rarity :normal
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
