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
			unless in_senario?
				current_player.mana_grow
			else
				current_player.full_mana = @player1_mana
				opponent_player.full_mana = @player2_mana
			end
			current_player.restore_mana
			current_player.set_overload
			unless in_senario?
				current_player.draw_card
			end
			current_player.hero.has_attacked = 0
			current_player.field.each do |card|
				card.has_attacked = 0
				card.summon_sickness = false
			end
			current_player.turn_action_count = 0
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
		@match.players.each do |player|
			(player.field + player.hand + [player.hero]).each do |card|
				card.cleanup_text :end
			end
			if player.hero.weapon
				player.hero.weapon.cleanup_text :end
			end
		end
	end
end
