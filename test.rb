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
	ai [
		proc{|actions, view|
			summon_action = actions.select{|action|
				action == :summon
			}.select{|action|
				action[0].name == "Proto Charge"
			}.first
		},
		proc{|actions, view|
			assert actions.select{|action|
				action == :attack
			}.select{|action|
				action[0].name == "Proto Charge"
			}.count > 0, "Minion with charge cannot attack"
		}
	]
end
