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
			self.current_player.draw_card
		end
	end
end
