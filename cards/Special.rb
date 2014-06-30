card "Tired Card" do
	type :special

	on :draw do |i|
		this_card = @this_card
		damage = this_card.instance_eval{@damage}
		log "Take #{damage} damages"
		@hero.take_damage damage
	end
end
