actions.each_with_index do |a, i|
	puts "#{i + 1}: #{a}"
end
choice = nil
while true
	print ">> "
	command = STDIN.readline.chomp
	if command =~ /^\d+$/
		choice = command.to_i
		if choice >= 1 and choice <= actions.count
			break
		end
	elsif command == "q"
		puts "Quit"
		exit
	end
end
actions[choice - 1]
