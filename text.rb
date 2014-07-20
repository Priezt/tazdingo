class Text
	attr_accessor :name
	attr_accessor :health_buff
	attr_accessor :attack_buff
	attr_accessor :cost_buff

	def Text.[](_name, &block)
		Text.new(_name, &block)
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
end

