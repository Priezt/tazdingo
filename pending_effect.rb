class PendingEffect
	attr_accessor :player
	attr_accessor :effect_proc
	
	def initialize(_player, _effect_proc)
		@player = _player
		@effect_proc = _effect_proc
	end

	def run
		@player.instance_eval &(@effect_proc)
	end
end
