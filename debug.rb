puts "=" * 50
puts "Opponent: #{view.opponent_hero.name}(#{view.opponent_hero.health}) - Hand: #{view.opponent_hand}"
puts "\tField: [#{view.opponent_field.map{|card| card.to_ss}.join ", "}]"
puts "Player: #{view.hero.name}(#{view.hero.health})"
puts "\t#Hand: #{view.hand}"
puts "\tField: [#{view.field.map{|card| card.to_ss}.join ", "}]"
puts "=" * 50
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
	elsif command =~ /^h(\d+)$/
		puts view.hand[$1.to_i - 1].detail
	elsif command =~ /^f(\d+)$/
		puts view.field[$1.to_i - 1].detail
	end
end
actions[choice - 1]
