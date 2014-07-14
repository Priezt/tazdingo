class Action
	def Action.[](*args)
		Action.new *args
	end

	def initialize(*args)
		@args = args
	end

	def name
		@args[0]
	end

	def arg(idx)
		@args[idx + 1]
	end

	def [](idx)
		self.arg(idx)
	end

	def ==(action_name)
		self.name.to_s == action_name.to_s
	end

	def to_s
		"->(#{@args.map{|arg|arg.to_s}.join(",")})"
	end
end

