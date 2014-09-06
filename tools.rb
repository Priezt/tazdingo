class Object
	def self.proxy(parent_variable, proxy_methods)
		proxy_methods.each do |pm|
			define_method pm do |*args|
				eval "@#{parent_variable.to_s}.#{pm.to_s}(*args)"
			end
		end
	end
end
