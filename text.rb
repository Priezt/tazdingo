class Text
	attr_accessor :name
	attr_accessor :health_buff
	attr_accessor :attack_buff
	attr_accessor :cost_buff
	attr_accessor :targets_proc
	attr_accessor :buff_text
	attr_accessor :action_proc

	def Text.[](_name, &block)
		Text.new(_name, &block)
	end

	def Text.action(_name, &block)
		new_text = Text.new(_name)
		new_text.action_proc = proc(&block);
		new_text
	end

	def health
		unless @health
			@health = @health_buff || 0
		end
		@health
	end

	def health=(new_health)
		unless @health
			@health = @health_buff || 0
		end
		@health = new_health
	end

	def initialize(_name, &block)
		@name = _name
		if block
			self.instance_eval(&block)
		end
	end

	def ==(n)
		@name.to_s == n.to_s
	end

	def targets(&block)
		@targets_proc = proc(&block)
	end

	def buff(&block)
		@buff_text = Text[:buff, &block]
	end
end

