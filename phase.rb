class Phase
	def initialize(match)
		@match = match
	end

	def run
	end
end

class PhaseBegin < Phase
	def run
		@match.instance_eval do
			current_player.log "Turn Start: #{turn}"
			current_player.mana_grow
			current_player.restore_mana
			current_player.draw_card
		end
	end
end

class PhaseFree < Phase
	def run
		@match.instance_eval do
			while true
				actions = current_player.get_all_actions
				chosen_action = current_player.choose(actions)
				current_player.log chosen_action.to_s
				if chosen_action == :turn_end
					return
				else
					current_player.execute chosen_action
				end
			end
		end
	end
end

class PhaseEnd < Phase
	def run
		@match.instance_eval do
			current_player.field.each do |card|
				card.summon_sickness = false
			end
			current_player.log "Turn end"
		end
	end
end
