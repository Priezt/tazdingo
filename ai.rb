class AI
	def initialize(ai_filename)
		if ai_filename.is_a? String
			self.load_ai(ai_filename)
		else
			choose_proc = ai_filename
			@choose_block = choose_proc
		end
	end

	def load_ai(ai_filename)
		choose_function_definition = File.open(ai_filename).read()
		@choose_block = eval("proc{|*args|\nactions=args[0]\nview=args[1]\n#{choose_function_definition}\n}")
	end

	def choose(*args)
		@choose_block.call *args
	end
end

