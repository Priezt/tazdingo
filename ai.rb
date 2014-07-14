class AI
	def initialize(ai_filename)
		self.load_ai(ai_filename)
	end

	def load_ai(ai_filename)
		puts "Loading AI: #{ai_filename}"
		choose_function_definition = File.open(ai_filename).read()
		#@choose_block = eval("proc{|actions, view|\n#{choose_function_definition}\n}")
		@choose_block = eval("proc{|*args|\nactions=args[0]\nview=args[1]\n#{choose_function_definition}\n}")
	end

	def choose(*args)
		@choose_block.call *args
	end
end

