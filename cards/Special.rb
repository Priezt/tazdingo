card "Tired Card" do
	type :special

	on :draw do |i|
		damage = this_card.instance_eval{@damage}
		this_card.log "Take #{damage} damages"
		@hero.take_damage damage
		@hero.check_death
		this_card.purge
	end
end
