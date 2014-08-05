require './engine'
require './senario'

class Senario
	def log(msg)
		txt = "[LOG]#{msg}"
		logs << txt
	end

	def assert(condition, msg)
		unless condition
			puts "Assert Failed: #{msg}"
			exit
		end
	end

	def finish
		Action[:turn_end]
	end
end

class Array
	def attack
		self.select do |action|
			action == :attack
		end
	end

	def summon
		self.select do |action|
			action == :summon
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
	ai [
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
	ai [
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
	ai [
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
	ai [
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
	ai [
		proc{|actions, view|
			actions.summon_minion
		},
		proc{|actions, view|
			assert actions.summon_minion, "Battlecry not fired"
			finish
		},
	]
end
