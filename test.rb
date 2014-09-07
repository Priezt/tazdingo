require './engine'
require './senario'

class Senario
	def log(msg)
		txt = "[LOG]#{msg}"
		logs << txt
	end

	def assert(condition, *args)
		unless condition
			if args.count > 0
				puts "Assert Failed: #{args[0]}"
			else
				puts "Assert Failed"
			end
			exit
		end
	end

	def finish
		Action[:turn_end]
	end
end

class Array
	[ :summon, :attack, :cast, :equip, :target ].each do |m|
		define_method m do
			self.select do |action|
				action == m
			end
		end
	end

	def target_minion
		self.select do |action|
			action[1].type == :minion
		end
	end

	def target_hero
		self.select do |action|
			action[1].type == :hero
		end
	end

	def attack_minion
		self.attack.target_minion.first
	end

	def attack_hero
		self.attack.target_hero.first
	end

	def summon_minion
		self.summon.first
	end
end

def test(senario_name, &block)
	puts "Test: #{senario_name}"
	Senario.run do
		name "#{senario_name}"
		self.instance_eval &block
	end
end

test "Charge" do
	player_hand [
		"Proto Charge",
	]
	steps [
		proc{|actions, view|
			actions.summon_minion
		},
		proc{|actions, view|
			assert actions.attack.count > 0, "Minion with charge cannot attack"
			finish
		}
	]
end

test "Taunt" do
	player_field [
		"Proto Charge",
	]
	opponent_field [
		"Proto Charge",
		"Proto Charge",
		"Proto Taunt",
	]
	steps [
		proc{|actions, view|
			assert actions.attack.count == 1, "Taunt does not take effect"
			finish
		}
	]
end

test "Windfury" do
	player_field [
		"Proto Windfury",
	]
	init {
		assign_text field[0], Text[:charge]
	}
	steps [
		proc{|actions, view|
			actions.attack_hero
		},
		proc{|actions, view|
			assert actions.attack.count > 0, "Windfury cannot attack twice"
			finish
		},
	]
end

test "Divine Shield" do
	player_field [
		"Proto Charge",
		"Proto Charge",
	]
	opponent_field [
		"Proto Divine Shield"
	]
	steps [
		proc{|actions, view|
			actions.attack_minion
		},
		proc{|actions, view|
			assert actions.attack_minion, "Divine Shield does not work"
			finish
		},
	]
end

test "Stealth" do
	player_field [
		"Proto Charge",
	]
	opponent_field [
		"Proto Stealth"
	]
	steps [
		proc{|actions, view|
			assert (not actions.attack_minion), "Can still attack a minion with stealth"
			finish
		},
	]
end

test "Battlecry" do
	player_hand [
		"Proto Battlecry",
	]
	player_deck [
		"Proto Battlecry",
	]
	steps [
		proc{|actions, view|
			actions.summon_minion
		},
		proc{|actions, view|
			assert actions.summon_minion, "Battlecry not fired"
			finish
		},
	]
end

test "Heal" do
	player_hand [
		"Ability Heal",
	]
	init {
		@hero.health = 25
	}
	steps [
		proc{|actions, view|
			actions.cast.select do |action|
				action[1] == view.hero
			end.first
		},
		proc{|actions, view|
			assert view.hero.health == 28, "Hero not healed"
			finish
		}
	]
end

test "Damage" do
	player_hand [
		"Ability Damage",
	]
	steps [
		proc{|actions, view|
			actions.cast.select do |action|
				action[1] == view.opponent_hero
			end.first
		},
		proc{|actions, view|
			assert view.opponent_hero.health == 25, "Opponent hero not damaged"
			finish
		}
	]
end

test "Buff" do
	player_field [
		"Proto Powerful",
	]
	steps [
		proc{|actions, view|
			assert view.field.first.get_attack == 6, "Attack buff not correct"
			assert view.field.first.get_health == 6, "Health buff not correct"
			finish
		}
	]
end

test "Aura" do
	player_field [
		"Proto Charge",
		"Proto Aura",
	]
	steps [
		proc{|actions, view|
			assert view.field.first.get_attack == 3, "Aura buff not work"
			finish
		}
	]
end

test "Weapon" do
	player_hand [
		"Weapon 1",
	]
	steps [
		proc{|actions, view|
			actions.equip.first
		},
		proc{|actions, view|
			assert actions.attack.count > 0, "Hero cannot attack with weapon"
			finish
		},
	]
end

test "Temp Text" do
	player_hand [
		"Proto Temp Text",
	]
	steps [
		proc{|actions, view|
			actions.summon_minion
		},
		proc{|actions, view|
			assert view.field.first.get_attack == 7, "Not buffed"
			assert view.field.first.get_health == 7, "Not buffed"
			Action[:turn_end]
		},
		proc{|actions, view|
			assert view.field.first.get_attack == 2, "Not recovered"
			assert view.field.first.get_health == 2, "Not recovered"
			finish
		},
	]
end

test "Choose Target" do
	player_hand [
		"Proto Fire Element",
	]
	steps [
		proc{|actions, view|
			actions.summon_minion
		},
		proc{|actions, view|
			assert actions.target.count == 2, "No 2 targets"
			actions.target.select do |action|
				action[0] != view.hero
			end.first
		},
		proc{|actions, view|
			assert view.opponent_hero.get_health == 27, "Target not damaged"
			finish
		},
	]
end

test "Deathrattle" do
	player_field [
		"Proto Deathrattle",
	]
	player_deck [
		"Proto Deathrattle",
	]
	opponent_field [
		"Proto Taunt",
	]
	steps [
		proc{|actions, view|
			actions.attack_minion
		},
		proc{|actions, view|
			assert view.hand.count == 1, "Deathrattle not fired"
			finish
		},
	]
end

test "Armor" do
	player_field [
		"Proto Fire Element",
	]
	init {
		opponent.hero.gain_armor 2
	}
	steps [
		proc{|actions, view|
			actions.attack.first
		},
		proc{|actions, view|
			assert view.opponent_hero.get_health == 26
			finish
		},
	]
end

test "Silent" do
	player_field [
		"Proto Charge",
		"Proto Aura",
		"Proto Powerful",
	]
	player_hand [
		"Ability Silent All",
	]
	steps [
		proc{|actions, view|
			assert actions.cast.count > 0, "Cannot cast ability"
			actions.cast.first
		},
		proc{|actions, view|
			assert view.field[0].get_attack == 1
			assert view.field[1].get_attack == 1
			assert view.field[2].get_attack == 1
			finish
		},
	]
end

test "Freeze" do
	player_field [
		"Proto Charge",
	]
	player_hand [
		"Ability Freeze All",
	]
	steps [
		proc{|actions, view|
			assert actions.cast.count > 0, "Cannot cast ability"
			actions.cast.first
		},
		proc{|actions, view|
			assert actions.attack.count == 0
			finish
		},
	]
end

test "Ability Combo" do
	player_hand [
		"Ability Combo",
		"Ability Combo",
	]
	player_deck [
		"Proto Charge",
		"Proto Charge",
		"Proto Charge",
	]
	steps [
		proc{|actions, view|
			actions.cast.first
		},
		proc{|actions, view|
			assert view.hand.count == 2
			actions.cast.first
		},
		proc{|actions, view|
			assert view.hand.count == 3
			finish
		},
	]
end

test "Weapon Combo" do
	player_hand [
		"Weapon Combo",
		"Weapon Combo",
	]
	player_deck [
		"Proto Charge",
		"Proto Charge",
		"Proto Charge",
	]
	steps [
		proc{|actions, view|
			actions.equip.first
		},
		proc{|actions, view|
			assert view.hand.count == 1
			actions.equip.first
		},
		proc{|actions, view|
			assert view.hand.count == 1
			finish
		},
	]
end

test "Minion Combo" do
	player_hand [
		"Proto Minion Combo",
		"Proto Minion Combo",
	]
	player_deck [
		"Ability Combo",
		"Ability Combo",
		"Ability Combo",
	]
	steps [
		proc{|actions, view|
			actions.summon_minion
		},
		proc{|actions, view|
			assert view.hand.count == 2
			actions.summon_minion
		},
		proc{|actions, view|
			assert view.hand.count == 3
			finish
		},
	]
end

test "Listen Death" do
	player_hand [
		"Proto Listen Death",
	]
	player_field [
		"Proto Charge",
	]
	player_deck [
		"Proto Charge",
		"Proto Charge",
		"Proto Charge",
		"Proto Charge",
	]
	opponent_field [
		"Proto Blank"
	]
	steps [
		proc{|actions, view|
			actions.summon_minion
		},
		proc{|actions, view|
			actions.attack_minion
		},
		proc{|actions, view|
			assert view.hand.count == 1
			finish
		},
	]
end
