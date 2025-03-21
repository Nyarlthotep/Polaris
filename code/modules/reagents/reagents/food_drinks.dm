/* Food */

/datum/reagent/nutriment
	name = "Nutriment"
	id = "nutriment"
	description = "All the vitamins, minerals, and carbohydrates the body needs in pure form."
	taste_mult = 4
	reagent_state = SOLID
	metabolism = REM * 4
	ingest_met = REM * 4
	var/nutriment_factor = 30 // Per unit
	var/injectable = 0
	color = "#664330"

/datum/reagent/nutriment/mix_data(var/list/newdata, var/newamount)

	if(!islist(newdata) || !newdata.len)
		return

	//add the new taste data
	if(islist(data))
		for(var/taste in newdata)
			if(taste in data)
				data[taste] += newdata[taste]
			else
				data[taste] = newdata[taste]
	else
		initialize_data(newdata)

	//cull all tastes below 5% of total
	var/totalFlavor = 0
	for(var/taste in data)
		totalFlavor += data[taste]
	if(totalFlavor) //Let's not divide by zero for things w/o taste
		for(var/taste in data)
			if(data[taste]/totalFlavor < 0.05)
				data -= taste

#define ANIMAL_NUTRITION_MULTIPLIER 0.5
/datum/reagent/nutriment/affect_animal(var/mob/living/simple_mob/animal/M, var/removed)
	M.add_nutrition(nutriment_factor * removed * M.get_dietary_food_modifier(src) * ANIMAL_NUTRITION_MULTIPLIER)
	return ..()
#undef ANIMAL_NUTRITION_MULTIPLIER

/datum/reagent/nutriment/affect_blood(var/mob/living/carbon/M, var/alien, var/removed)
	if(!injectable && alien != IS_SLIME)
		M.adjustToxLoss(0.1 * removed)
		return
	affect_ingest(M, alien, removed)
	..()

/datum/reagent/nutriment/affect_ingest(var/mob/living/carbon/M, var/alien, var/removed)
	switch(alien)
		if(IS_DIONA)
			return
		if(IS_UNATHI)
			removed *= 0.5
	if(issmall(M))
		removed *= 2 // Small bodymass, more effect from lower volume.
	if(!(M.species.allergens & allergen_type))	//assuming it doesn't cause a horrible reaction, we'll be ok!
		M.heal_organ_damage(0.5 * removed, 0)
		M.adjust_nutrition(nutriment_factor * removed)
		M.add_chemical_effect(CE_BLOODRESTORE, 4 * removed)


// Aurora Cooking Port Insertion Begin

/*
	Coatings are used in cooking. Dipping food items in a reagent container with a coating in it
	allows it to be covered in that, which will add a masked overlay to the sprite.
	Coatings have both a raw and a cooked image. Raw coating is generally unhealthy
	Generally coatings are intended for deep frying foods
*/
/datum/reagent/nutriment/coating
	name = "coating"
	id = "coating"
	nutriment_factor = 6 //Less dense than the food itself, but coatings still add extra calories
	var/messaged = 0
	var/icon_raw
	var/icon_cooked
	var/coated_adj = "coated"
	var/cooked_name = "coating"

/datum/reagent/nutriment/coating/affect_ingest(var/mob/living/carbon/M, var/alien, var/removed)

	//We'll assume that the batter isn't going to be regurgitated and eaten by someone else. Only show this once
	if(data["cooked"] != 1)
		if (!messaged)
			to_chat(M, "<span class='warning'>Ugh, this raw [name] tastes disgusting.</span>")
			nutriment_factor *= 0.5
			messaged = 1

		//Raw coatings will sometimes cause vomiting. 75% chance of this happening.
		if(prob(75))
			M.vomit()
	..()

/datum/reagent/nutriment/coating/initialize_data(var/newdata) // Called when the reagent is created.
	..()
	if (!data)
		data = list()
	else
		if (isnull(data["cooked"]))
			data["cooked"] = 0
		return
	data["cooked"] = 0
	if (holder && holder.my_atom && istype(holder.my_atom,/obj/item/reagent_containers/food/snacks))
		data["cooked"] = 1
		name = cooked_name

		//Batter which is part of objects at compiletime spawns in a cooked state


//Handles setting the temperature when oils are mixed
/datum/reagent/nutriment/coating/mix_data(var/newdata, var/newamount)
	if (!data)
		data = list()

	data["cooked"] = newdata["cooked"]

/datum/reagent/nutriment/coating/batter
	name = "batter mix"
	cooked_name = "batter"
	id = "batter"
	color = "#f5f4e9"
	reagent_state = LIQUID
	icon_raw = "batter_raw"
	icon_cooked = "batter_cooked"
	coated_adj = "battered"
	allergen_type = ALLERGEN_GRAINS | ALLERGEN_EGGS //Made with flour(grain), and eggs(eggs)

/datum/reagent/nutriment/coating/beerbatter
	name = "beer batter mix"
	cooked_name = "beer batter"
	id = "beerbatter"
	color = "#f5f4e9"
	reagent_state = LIQUID
	icon_raw = "batter_raw"
	icon_cooked = "batter_cooked"
	coated_adj = "beer-battered"
	allergen_type = ALLERGEN_GRAINS | ALLERGEN_EGGS //Made with flour(grain), eggs(eggs), and beer(grain)

/datum/reagent/nutriment/coating/beerbatter/affect_ingest(var/mob/living/carbon/M, var/alien, var/removed)
	..()
	M.add_chemical_effect(CE_ALCOHOL, 0.02) //Very slightly alcoholic

//=========================
//Fats
//=========================
/datum/reagent/nutriment/triglyceride
	name = "triglyceride"
	id = "triglyceride"
	description = "More commonly known as fat, the third macronutrient, with over double the energy content of carbs and protein"

	reagent_state = SOLID
	taste_description = "greasiness"
	taste_mult = 0.1
	nutriment_factor = 27//The caloric ratio of carb/protein/fat is 4:4:9
	color = "#CCCCCC"

/datum/reagent/nutriment/triglyceride/oil
	//Having this base class incase we want to add more variants of oil
	name = "Oil"
	id = "oil"
	description = "Oils are liquid fats."
	reagent_state = LIQUID
	taste_description = "oil"
	color = "#c79705"
	touch_met = 1.5
	var/lastburnmessage = 0

/datum/reagent/nutriment/triglyceride/oil/touch_turf(var/turf/simulated/T)
	if(!istype(T))
		return

	..()

	var/hotspot = (locate(/obj/fire) in T)
	if(hotspot && !istype(T, /turf/space))
		var/datum/gas_mixture/lowertemp = T.remove_air(T:air:total_moles)
		lowertemp.temperature = max(min(lowertemp.temperature-2000, lowertemp.temperature / 2), 0)
		lowertemp.react()
		T.assume_air(lowertemp)
		qdel(hotspot)

	if(volume >= 3)
		T.wet_floor(2)

/datum/reagent/nutriment/triglyceride/oil/initialize_data(var/newdata) // Called when the reagent is created.
	..()
	if (!data)
		data = list("temperature" = T20C)

//Handles setting the temperature when oils are mixed
/datum/reagent/nutriment/triglyceride/oil/mix_data(var/newdata, var/newamount)

	if (!data)
		data = list()

	var/ouramount = volume - newamount
	if (ouramount <= 0 || !data["temperature"] || !volume)
		//If we get here, then this reagent has just been created, just copy the temperature exactly
		data["temperature"] = newdata["temperature"]

	else
		//Our temperature is set to the mean of the two mixtures, taking volume into account
		var/total = (data["temperature"] * ouramount) + (newdata["temperature"] * newamount)
		data["temperature"] = total / volume

	return ..()


//Calculates a scaling factor for scalding damage, based on the temperature of the oil and creature's heat resistance
/datum/reagent/nutriment/triglyceride/oil/proc/heatdamage(var/mob/living/carbon/M)
	var/threshold = 360//Human heatdamage threshold
	var/datum/species/S = M.get_species()
	if (istype(S))
		threshold = S.heat_level_1

	//If temperature is too low to burn, return a factor of 0. no damage
	if (data["temperature"] < threshold)
		return 0

	//Step = degrees above heat level 1 for 1.0 multiplier
	var/step = 60
	if (istype(S))
		step = (S.heat_level_2 - S.heat_level_1)*1.5

	. = data["temperature"] - threshold
	. /= step
	. = min(., 2.5)//Cap multiplier at 2.5

/datum/reagent/nutriment/triglyceride/oil/affect_touch(var/mob/living/carbon/M, var/alien, var/removed)
	var/dfactor = heatdamage(M)
	if (dfactor)
		M.take_organ_damage(0, removed * 1.5 * dfactor)
		data["temperature"] -= (6 * removed) / (1 + volume*0.1)//Cools off as it burns you
		if (lastburnmessage+100 < world.time	)
			to_chat(M, "<span class='danger'>Searing hot oil burns you, wash it off quick!</span>")
			lastburnmessage = world.time

/datum/reagent/nutriment/triglyceride/oil/corn
	name = "Corn Oil"
	id = "cornoil"
	description = "An oil derived from various types of corn."
	reagent_state = LIQUID
	allergen_type = ALLERGEN_VEGETABLE //Corn is a vegetable

/datum/reagent/nutriment/triglyceride/oil/peanut
	name = "Peanut Oil"
	id = "peanutoil"
	description = "An oil derived from various types of nuts."
	taste_description = "nuts"
	taste_mult = 0.3
	nutriment_factor = 15
	color = "#4F3500"
	allergen_type = ALLERGEN_SEEDS //Peanut oil would come from peanuts, hence seeds.

// Aurora Cooking Port Insertion End

/datum/reagent/nutriment/glucose
	name = "Glucose"
	id = "glucose"
	taste_description = "sweetness"
	color = "#FFFFFF"

	injectable = 1

/datum/reagent/nutriment/protein // Bad for Skrell!
	name = "animal protein"
	id = "protein"
	taste_description = "umami"
	color = "#440000"
	allergen_type = ALLERGEN_MEAT //"Animal protein" implies it comes from animals, therefore meat.

/datum/reagent/nutriment/protein/affect_ingest(var/mob/living/carbon/M, var/alien, var/removed)
	switch(alien)
		if(IS_TESHARI)
			..(M, alien, removed*1.2) // Teshari get a bit more nutrition from meat.
		if(IS_UNATHI)
			..(M, alien, removed*2.25) //Unathi get most of their nutrition from meat.
		else
			..()

/datum/reagent/nutriment/protein/tofu
	name = "tofu protein"
	id = "tofu"
	color = "#fdffa8"
	taste_description = "tofu"
	allergen_type = ALLERGEN_BEANS //Made from soy beans

/datum/reagent/nutriment/protein/seafood
	name = "seafood protein"
	id = "seafood"
	color = "#f5f4e9"
	taste_description = "fish"
	allergen_type = ALLERGEN_FISH //I suppose the fish allergy likely refers to seafood in general.

/datum/reagent/nutriment/protein/cheese
	name = "cheese"
	id = "cheese"
	color = "#EDB91F"
	taste_description = "cheese"
	allergen_type = ALLERGEN_DAIRY //Cheese is made from dairy

/datum/reagent/nutriment/protein/egg
	name = "egg yolk"
	id = "egg"
	taste_description = "egg"
	color = "#FFFFAA"
	allergen_type = ALLERGEN_EGGS //Eggs contain egg

/datum/reagent/nutriment/honey
	name = "Honey"
	id = "honey"
	description = "A golden yellow syrup, loaded with sugary sweetness."
	taste_description = "sweetness"
	nutriment_factor = 10
	color = "#FFFF00"

/datum/reagent/nutriment/honey/affect_ingest(var/mob/living/carbon/M, var/alien, var/removed)
	..()

	var/effective_dose = dose
	if(issmall(M))
		effective_dose *= 2

	if(alien == IS_UNATHI)
		if(effective_dose < 2)
			if(effective_dose == metabolism * 2 || prob(5))
				M.emote("yawn")
		else if(effective_dose < 5)
			M.eye_blurry = max(M.eye_blurry, 10)
		else if(effective_dose < 20)
			if(prob(50))
				M.Weaken(2)
			M.drowsyness = max(M.drowsyness, 20)
		else
			M.Sleeping(20)
			M.drowsyness = max(M.drowsyness, 60)

/datum/reagent/nutriment/mayo
	name = "mayonnaise"
	id = "mayo"
	description = "A thick, bitter sauce."
	taste_description = "unmistakably mayonnaise"
	nutriment_factor = 10
	color = "#FFFFFF"
	allergen_type = ALLERGEN_EGGS	//Mayo is made from eggs

/datum/reagent/nutriment/yeast
	name = "Yeast"
	id = "yeast"
	description = "For making bread rise!"
	taste_description = "yeast"
	nutriment_factor = 1
	color = "#D3AF70"

/datum/reagent/nutriment/flour
	name = "Flour"
	id = "flour"
	description = "This is what you rub all over yourself to pretend to be a ghost."
	taste_description = "chalky wheat"
	reagent_state = SOLID
	nutriment_factor = 1
	color = "#FFFFFF"
	allergen_type = ALLERGEN_GRAINS //Flour is made from grain

/datum/reagent/nutriment/flour/touch_turf(var/turf/simulated/T)
	..()
	if(!istype(T, /turf/space))
		new /obj/effect/decal/cleanable/flour(T)

/datum/reagent/nutriment/coffee
	name = "Coffee Powder"
	id = "coffeepowder"
	description = "A bitter powder made by grinding coffee beans."
	taste_description = "bitterness"
	taste_mult = 1.3
	nutriment_factor = 1
	color = "#482000"
	allergen_type = ALLERGEN_COFFEE | ALLERGEN_STIMULANT //Again, coffee contains coffee

/datum/reagent/nutriment/tea
	name = "Tea Powder"
	id = "teapowder"
	description = "A dark, tart powder made from black tea leaves."
	taste_description = "tartness"
	taste_mult = 1.3
	nutriment_factor = 1
	color = "#101000"
	allergen_type = ALLERGEN_STIMULANT //Strong enough to contain caffeine

/datum/reagent/nutriment/decaf_tea
	name = "Decaf Tea Powder"
	id = "decafteapowder"
	description = "A dark, tart powder made from black tea leaves, treated to remove caffeine content."
	taste_description = "tartness"
	taste_mult = 1.3
	nutriment_factor = 1
	color = "#101000"

/datum/reagent/nutriment/coco
	name = "Coco Powder"
	id = "coco"
	description = "A fatty, bitter paste made from coco beans."
	taste_description = "bitterness"
	taste_mult = 1.3
	reagent_state = SOLID
	nutriment_factor = 5
	color = "#302000"

/datum/reagent/nutriment/chocolate
	name = "Chocolate"
	id = "chocolate"
	description = "Great for cooking or on its own!"
	taste_description = "chocolate"
	color = "#582815"
	nutriment_factor = 5
	taste_mult = 1.3

/datum/reagent/nutriment/instantjuice
	name = "Juice Powder"
	id = "instantjuice"
	description = "Dehydrated, powdered juice of some kind."
	taste_mult = 1.3
	nutriment_factor = 1
	allergen_type = ALLERGEN_FRUIT //I suppose it's implied here that the juice is from dehydrated fruit.

/datum/reagent/nutriment/instantjuice/grape
	name = "Grape Juice Powder"
	id = "instantgrape"
	description = "Dehydrated, powdered grape juice."
	taste_description = "dry grapes"
	color = "#863333"

/datum/reagent/nutriment/instantjuice/orange
	name = "Orange Juice Powder"
	id = "instantorange"
	description = "Dehydrated, powdered orange juice."
	taste_description = "dry oranges"
	color = "#e78108"

/datum/reagent/nutriment/instantjuice/watermelon
	name = "Watermelon Juice Powder"
	id = "instantwatermelon"
	description = "Dehydrated, powdered watermelon juice."
	taste_description = "dry sweet watermelon"
	color = "#b83333"

/datum/reagent/nutriment/instantjuice/apple
	name = "Apple Juice Powder"
	id = "instantapple"
	description = "Dehydrated, powdered apple juice."
	taste_description = "dry sweet apples"
	color = "#c07c40"

/datum/reagent/nutriment/soysauce
	name = "Soy Sauce"
	id = "soysauce"
	description = "A salty sauce made from the soy plant."
	taste_description = "umami"
	taste_mult = 1.1
	reagent_state = LIQUID
	nutriment_factor = 2
	color = "#792300"
	allergen_type = ALLERGEN_BEANS //Soy (beans)

/datum/reagent/nutriment/vinegar
	name = "Vinegar"
	id = "vinegar"
	description = "Vinegar, great for fish and pickles."
	taste_description = "vinegar"
	reagent_state = LIQUID
	nutriment_factor = 5
	color = "#54410C"

/datum/reagent/nutriment/ketchup
	name = "Ketchup"
	id = "ketchup"
	description = "Ketchup, catsup, whatever. It's tomato paste."
	taste_description = "ketchup"
	reagent_state = LIQUID
	nutriment_factor = 5
	color = "#731008"
	allergen_type = ALLERGEN_FRUIT 	//Tomatoes are a fruit.

/datum/reagent/nutriment/mustard
	name = "Mustard"
	id = "mustard"
	description = "Delicious mustard. Good on Hot Dogs."
	taste_description = "mustard"
	reagent_state = LIQUID
	nutriment_factor = 5
	color = "#E3BD00"

/datum/reagent/nutriment/barbecue
	name = "Barbeque Sauce"
	id = "barbecue"
	description = "Barbecue sauce for barbecues and long shifts."
	taste_description = "barbeque"
	reagent_state = LIQUID
	nutriment_factor = 5
	color = "#4F330F"

/datum/reagent/nutriment/rice
	name = "Rice"
	id = "rice"
	description = "Enjoy the great taste of nothing."
	taste_description = "rice"
	taste_mult = 0.4
	reagent_state = SOLID
	nutriment_factor = 1
	color = "#FFFFFF"

/datum/reagent/nutriment/cherryjelly
	name = "Cherry Jelly"
	id = "cherryjelly"
	description = "Totally the best. Only to be spread on foods with excellent lateral symmetry."
	taste_description = "cherry"
	taste_mult = 1.3
	reagent_state = LIQUID
	nutriment_factor = 1
	color = "#801E28"
	allergen_type = ALLERGEN_FRUIT //Cherries are fruits

/datum/reagent/nutriment/peanutbutter
	name = "Peanut Butter"
	id = "peanutbutter"
	description = "A butter derived from various types of nuts."
	taste_description = "peanuts"
	taste_mult = 0.5
	reagent_state = LIQUID
	nutriment_factor = 30
	color = "#4F3500"
	allergen_type = ALLERGEN_SEEDS //Peanuts(seeds)

/datum/reagent/nutriment/vanilla
	name = "Vanilla Extract"
	id = "vanilla"
	description = "Vanilla extract. Tastes suspiciously like boring ice-cream."
	taste_description = "vanilla"
	taste_mult = 5
	reagent_state = LIQUID
	nutriment_factor = 2
	color = "#0F0A00"

/datum/reagent/nutriment/durian
	name = "Durian Paste"
	id = "durianpaste"
	description = "A strangely sweet and savory paste."
	taste_description = "sweet and savory"
	color = "#757631"

	glass_name = "durian paste"
	glass_desc = "Durian paste. It smells horrific."

/datum/reagent/nutriment/durian/touch_mob(var/mob/M, var/amount)
	..()
	if(iscarbon(M) && !M.isSynthetic())
		var/message = pick("Oh god, it smells disgusting here.", "What is that stench?", "That's an awful odor.")
		to_chat(M, "<span class='alien'>[message]</span>")
		if(prob(clamp(amount, 5, 90)))
			var/mob/living/L = M
			L.vomit()
	return ..()

/datum/reagent/nutriment/durian/touch_turf(var/turf/T, var/amount)
	..()
	if(istype(T))
		var/obj/effect/decal/cleanable/chemcoating/C = new /obj/effect/decal/cleanable/chemcoating(T)
		C.reagents.add_reagent(id, amount)
	return ..()

/datum/reagent/nutriment/virus_food
	name = "Virus Food"
	id = "virusfood"
	description = "A mixture of water, milk, and oxygen. Virus cells can use this mixture to reproduce."
	taste_description = "vomit"
	taste_mult = 2
	reagent_state = LIQUID
	nutriment_factor = 2
	color = "#899613"
	allergen_type = ALLERGEN_DAIRY	//incase anyone is dumb enough to drink it - it does contain milk!

/datum/reagent/nutriment/sprinkles
	name = "Sprinkles"
	id = "sprinkles"
	description = "Multi-colored little bits of sugar, commonly found on donuts. Loved by cops."
	taste_description = "sugar"
	nutriment_factor = 1
	color = "#FF00FF"

/datum/reagent/nutriment/mint
	name = "Mint"
	id = "mint"
	description = "Also known as Mentha."
	taste_description = "mint"
	reagent_state = LIQUID
	color = "#CF3600"

/datum/reagent/lipozine // The anti-nutriment.
	name = "Lipozine"
	id = "lipozine"
	description = "A chemical compound that causes a powerful fat-burning reaction."
	taste_description = "mothballs"
	reagent_state = LIQUID
	color = "#BBEDA4"
	overdose = REAGENTS_OVERDOSE

/datum/reagent/lipozine/affect_blood(var/mob/living/carbon/M, var/alien, var/removed)
	M.adjust_nutrition(-10 * removed)

/* Non-food stuff like condiments */

/datum/reagent/sodiumchloride
	name = "Table Salt"
	id = "sodiumchloride"
	description = "A salt made of sodium chloride. Commonly used to season food."
	taste_description = "salt"
	reagent_state = SOLID
	color = "#FFFFFF"
	overdose = REAGENTS_OVERDOSE
	ingest_met = REM

/datum/reagent/sodiumchloride/affect_blood(var/mob/living/carbon/M, var/alien, var/removed)
	..()
	if(alien == IS_SLIME)
		M.adjustFireLoss(removed)

/datum/reagent/sodiumchloride/affect_ingest(var/mob/living/carbon/M, var/alien, var/removed)
	var/pass_mod = rand(3,5)
	var/passthrough = (removed - (removed/pass_mod)) //Some may be nullified during consumption, between one third and one fifth.
	affect_blood(M, alien, passthrough)

/datum/reagent/blackpepper
	name = "Black Pepper"
	id = "blackpepper"
	description = "A powder ground from peppercorns. *AAAACHOOO*"
	taste_description = "pepper"
	reagent_state = SOLID
	ingest_met = REM
	color = "#000000"

/datum/reagent/enzyme
	name = "Universal Enzyme"
	id = "enzyme"
	description = "A universal enzyme used in the preperation of certain chemicals and foods."
	taste_description = "sweetness"
	taste_mult = 0.7
	reagent_state = LIQUID
	color = "#365E30"
	overdose = REAGENTS_OVERDOSE

/datum/reagent/spacespice
	name = "Wurmwoad"
	id = "spacespice"
	description = "An exotic blend of spices for cooking. Definitely not worms."
	reagent_state = SOLID
	color = "#e08702"

/datum/reagent/browniemix
	name = "Brownie Mix"
	id = "browniemix"
	description = "A dry mix for making delicious brownies."
	reagent_state = SOLID
	color = "#441a03"

/datum/reagent/frostoil
	name = "Frost Oil"
	id = "frostoil"
	description = "A special oil that noticably chills the body. Extracted from Ice Peppers."
	taste_description = "mint"
	taste_mult = 1.5
	reagent_state = LIQUID
	ingest_met = REM
	color = "#B31008"

/datum/reagent/frostoil/affect_blood(var/mob/living/carbon/M, var/alien, var/removed)
	if(alien == IS_DIONA)
		return
	M.bodytemperature = max(M.bodytemperature - 10 * TEMPERATURE_DAMAGE_COEFFICIENT, 215)
	if(prob(1))
		M.emote("shiver")
	holder.remove_reagent("capsaicin", 5)

/datum/reagent/frostoil/affect_ingest(var/mob/living/carbon/M, var/alien, var/removed) // Eating frostoil now acts like capsaicin. Wee!
	if(alien == IS_DIONA)
		return
	if(ishuman(M))
		var/mob/living/carbon/human/H = M
		if(!H.can_feel_pain())
			return
	var/effective_dose = (dose * M.species.spice_mod)
	if((effective_dose < 5) && (dose == metabolism || prob(5)))
		to_chat(M, "<span class='danger'>Your insides suddenly feel a spreading chill!</span>")
	if(effective_dose >= 5)
		M.apply_effect(2 * M.species.spice_mod, AGONY, 0)
		M.bodytemperature -= rand(1, 5) * M.species.spice_mod // Really fucks you up, cause it makes you cold.
		if(prob(5))
			M.visible_message("<span class='warning'>[M] [pick("dry heaves!","coughs!","splutters!")]</span>", pick("<span class='danger'>You feel like your insides are freezing!</span>", "<span class='danger'>Your insides feel like they're turning to ice!</span>"))
	holder.remove_reagent("capsaicin", 5)

/datum/reagent/frostoil/cryotoxin //A longer lasting version of frost oil.
	name = "Cryotoxin"
	id = "cryotoxin"
	description = "Lowers the body's internal temperature."
	reagent_state = LIQUID
	color = "#B31008"
	metabolism = REM * 0.5

/datum/reagent/capsaicin
	name = "Capsaicin Oil"
	id = "capsaicin"
	description = "This is what makes chilis hot."
	taste_description = "spiciness"
	taste_mult = 1.5
	reagent_state = LIQUID
	ingest_met = REM
	color = "#B31008"

/datum/reagent/capsaicin/affect_blood(var/mob/living/carbon/M, var/alien, var/removed)
	if(alien == IS_DIONA)
		return
	M.adjustToxLoss(0.5 * removed)

/datum/reagent/capsaicin/affect_ingest(var/mob/living/carbon/M, var/alien, var/removed)
	if(alien == IS_DIONA)
		return
	if(ishuman(M))
		var/mob/living/carbon/human/H = M
		if(!H.can_feel_pain())
			return

	var/effective_dose = (dose * M.species.spice_mod)
	if((effective_dose < 5) && (dose == metabolism || prob(5)))
		to_chat(M, "<span class='danger'>Your insides feel uncomfortably hot!</span>")
	if(effective_dose >= 5)
		M.apply_effect(2 * M.species.spice_mod, AGONY, 0)
		M.bodytemperature += rand(1, 5) * M.species.spice_mod // Really fucks you up, cause it makes you overheat, too.
		if(prob(5))
			M.visible_message("<span class='warning'>[M] [pick("dry heaves!","coughs!","splutters!")]</span>", pick("<span class='danger'>You feel like your insides are burning!</span>", "<span class='danger'>You feel like your insides are on fire!</span>", "<span class='danger'>You feel like your belly is full of lava!</span>"))
	holder.remove_reagent("frostoil", 5)

/datum/reagent/condensedcapsaicin
	name = "Condensed Capsaicin"
	id = "condensedcapsaicin"
	description = "A chemical agent used for self-defense and in police work."
	taste_description = "fire"
	taste_mult = 10
	reagent_state = LIQUID
	touch_met = 50 // Get rid of it quickly
	ingest_met = REM
	color = "#B31008"

/datum/reagent/condensedcapsaicin/affect_blood(var/mob/living/carbon/M, var/alien, var/removed)
	if(alien == IS_DIONA)
		return
	M.adjustToxLoss(0.5 * removed)

/datum/reagent/condensedcapsaicin/affect_touch(var/mob/living/carbon/M, var/alien, var/removed)
	var/eyes_covered = 0
	var/mouth_covered = 0

	var/head_covered = 0
	var/arms_covered = 0 //These are used for the effects on slime-based species.
	var/legs_covered = 0
	var/hands_covered = 0
	var/feet_covered = 0
	var/chest_covered = 0
	var/groin_covered = 0

	var/obj/item/safe_thing = null

	var/effective_strength = 5

	if(alien == IS_SKRELL)	//Larger eyes means bigger targets.
		effective_strength = 8

	if(istype(M, /mob/living/carbon/human))
		var/mob/living/carbon/human/H = M
		if(!H.can_feel_pain())
			return
		if(H.head)
			if(H.head.body_parts_covered & EYES)
				eyes_covered = 1
				safe_thing = H.head
			if((H.head.body_parts_covered & FACE) && !(H.head.item_flags & FLEXIBLEMATERIAL))
				mouth_covered = 1
				safe_thing = H.head
		if(H.wear_mask)
			if(!eyes_covered && H.wear_mask.body_parts_covered & EYES)
				eyes_covered = 1
				safe_thing = H.wear_mask
			if(!mouth_covered && (H.wear_mask.body_parts_covered & FACE) && !(H.wear_mask.item_flags & FLEXIBLEMATERIAL))
				mouth_covered = 1
				safe_thing = H.wear_mask
		if(H.glasses && H.glasses.body_parts_covered & EYES)
			if(!eyes_covered)
				eyes_covered = 1
				if(!safe_thing)
					safe_thing = H.glasses
		if(alien == IS_SLIME)
			for(var/obj/item/clothing/C in H.worn_clothing)
				if(C.body_parts_covered & HEAD)
					head_covered = 1
				if(C.body_parts_covered & UPPER_TORSO)
					chest_covered = 1
				if(C.body_parts_covered & LOWER_TORSO)
					groin_covered = 1
				if(C.body_parts_covered & LEGS)
					legs_covered = 1
				if(C.body_parts_covered & ARMS)
					arms_covered = 1
				if(C.body_parts_covered & HANDS)
					hands_covered = 1
				if(C.body_parts_covered & FEET)
					feet_covered = 1
				if(head_covered && chest_covered && groin_covered && legs_covered && arms_covered && hands_covered && feet_covered)
					break
	if(eyes_covered && mouth_covered)
		to_chat(M, "<span class='warning'>Your [safe_thing] protects you from the pepperspray!</span>")
		if(alien != IS_SLIME)
			return
	else if(eyes_covered)
		to_chat(M, "<span class='warning'>Your [safe_thing] protects you from most of the pepperspray!</span>")
		M.eye_blurry = max(M.eye_blurry, effective_strength * 3)
		M.Blind(effective_strength)
		M.Stun(5)
		M.Weaken(5)
		if(alien != IS_SLIME)
			return
	else if(mouth_covered) // Mouth cover is better than eye cover
		to_chat(M, "<span class='warning'>Your [safe_thing] protects your face from the pepperspray!</span>")
		M.eye_blurry = max(M.eye_blurry, effective_strength)
		if(alien != IS_SLIME)
			return
	else// Oh dear :D
		to_chat(M, "<span class='warning'>You're sprayed directly in the eyes with pepperspray!</span>")
		M.eye_blurry = max(M.eye_blurry, effective_strength * 5)
		M.Blind(effective_strength * 2)
		M.Stun(5)
		M.Weaken(5)
		if(alien != IS_SLIME)
			return
	if(alien == IS_SLIME)
		if(!head_covered)
			if(prob(33))
				to_chat(M, "<span class='warning'>The exposed flesh on your head burns!</span>")
			M.apply_effect(5 * effective_strength, AGONY, 0)
		if(!chest_covered)
			if(prob(33))
				to_chat(M, "<span class='warning'>The exposed flesh on your chest burns!</span>")
			M.apply_effect(5 * effective_strength, AGONY, 0)
		if(!groin_covered && prob(75))
			if(prob(33))
				to_chat(M, "<span class='warning'>The exposed flesh on your groin burns!</span>")
			M.apply_effect(3 * effective_strength, AGONY, 0)
		if(!arms_covered && prob(45))
			if(prob(33))
				to_chat(M, "<span class='warning'>The exposed flesh on your arms burns!</span>")
			M.apply_effect(3 * effective_strength, AGONY, 0)
		if(!legs_covered && prob(45))
			if(prob(33))
				to_chat(M, "<span class='warning'>The exposed flesh on your legs burns!</span>")
			M.apply_effect(3 * effective_strength, AGONY, 0)
		if(!hands_covered && prob(20))
			if(prob(33))
				to_chat(M, "<span class='warning'>The exposed flesh on your hands burns!</span>")
			M.apply_effect(effective_strength / 2, AGONY, 0)
		if(!feet_covered && prob(20))
			if(prob(33))
				to_chat(M, "<span class='warning'>The exposed flesh on your feet burns!</span>")
			M.apply_effect(effective_strength / 2, AGONY, 0)

/datum/reagent/condensedcapsaicin/affect_ingest(var/mob/living/carbon/M, var/alien, var/removed)
	if(ishuman(M))
		var/mob/living/carbon/human/H = M
		if(!H.can_feel_pain())
			return
	if(dose == metabolism)
		to_chat(M, "<span class='danger'>You feel like your insides are burning!</span>")
	else
		M.apply_effect(4, AGONY, 0)
		if(prob(5))
			M.visible_message("<span class='warning'>[M] [pick("dry heaves!","coughs!","splutters!")]</span>", "<span class='danger'>You feel like your insides are burning!</span>")

/* Drinks */

/datum/reagent/drink
	name = "Drink"
	id = "drink"
	description = "Uh, some kind of drink."
	ingest_met = REM
	reagent_state = LIQUID
	color = "#E78108"
	var/nutrition = 0 // Per unit
	var/adj_dizzy = 0 // Per tick
	var/adj_drowsy = 0
	var/adj_sleepy = 0
	var/adj_temp = 0
	var/water_based = TRUE

/datum/reagent/drink/affect_blood(var/mob/living/carbon/M, var/alien, var/removed)
	var/strength_mod = 1
	if(alien == IS_SLIME && water_based)
		strength_mod = 3
	M.adjustToxLoss(removed * strength_mod) // Probably not a good idea; not very deadly though
	return

/datum/reagent/drink/affect_ingest(var/mob/living/carbon/M, var/alien, var/removed)
	if(!(M.species.allergens & allergen_type))
		M.adjust_nutrition(nutrition * removed)
	M.dizziness = max(0, M.dizziness + adj_dizzy)
	M.drowsyness = max(0, M.drowsyness + adj_drowsy)
	M.AdjustSleeping(adj_sleepy)
	if(adj_temp > 0 && M.bodytemperature < 310) // 310 is the normal bodytemp. 310.055
		M.bodytemperature = min(310, M.bodytemperature + (adj_temp * TEMPERATURE_DAMAGE_COEFFICIENT))
	if(adj_temp < 0 && M.bodytemperature > 310)
		M.bodytemperature = min(310, M.bodytemperature - (adj_temp * TEMPERATURE_DAMAGE_COEFFICIENT))
	if(alien == IS_SLIME && water_based)
		M.adjustToxLoss(removed * 2)

/datum/reagent/drink/overdose(var/mob/living/carbon/M, var/alien) //Add special interactions here in the future if desired.
	..()

// Juices

/datum/reagent/drink/juice/banana
	name = "Banana Juice"
	id = "banana"
	description = "The raw essence of a banana."
	taste_description = "banana"
	color = "#C3AF00"

	glass_name = "banana juice"
	glass_desc = "The raw essence of a banana. HONK!"
	allergen_type = ALLERGEN_FRUIT //Bananas are fruit

/datum/reagent/drink/juice/berry
	name = "Berry Juice"
	id = "berryjuice"
	description = "A delicious blend of several different kinds of berries."
	taste_description = "berries"
	color = "#990066"

	glass_name = "berry juice"
	glass_desc = "Berry juice. Or maybe it's jam. Who cares?"
	allergen_type = ALLERGEN_FRUIT //Berries are fruit

/datum/reagent/drink/juice/pineapple
	name = "Pineapple Juice"
	id = "pineapplejuice"
	description = "A sour but refreshing juice from a pineapple."
	taste_description = "pineapple"
	color = "#C3AF00"

	glass_name = "pineapple juice"
	glass_desc = "Pineapple juice. Or maybe it's spineapple. Who cares?"
	allergen_type = ALLERGEN_FRUIT //Pineapples are fruit

/datum/reagent/drink/juice/carrot
	name = "Carrot juice"
	id = "carrotjuice"
	description = "It is just like a carrot but without crunching."
	taste_description = "carrots"
	color = "#FF8C00" // rgb: 255, 140, 0

	glass_name = "carrot juice"
	glass_desc = "It is just like a carrot but without crunching."
	allergen_type = ALLERGEN_VEGETABLE //Carrots are vegetables

/datum/reagent/drink/juice/carrot/affect_ingest(var/mob/living/carbon/M, var/alien, var/removed)
	..()
	M.reagents.add_reagent("imidazoline", removed * 0.2)

/datum/reagent/drink/juice
	name = "Grape Juice"
	id = "grapejuice"
	description = "It's grrrrrape!"
	taste_description = "grapes"
	color = "#863333"
	var/sugary = TRUE ///So non-sugary juices don't make Unathi snooze.

	glass_name = "grape juice"
	glass_desc = "It's grrrrrape!"
	allergen_type = ALLERGEN_FRUIT //Grapes are fruit

/datum/reagent/drink/juice/affect_ingest(var/mob/living/carbon/M, var/alien, var/removed)
	..()

	var/effective_dose = dose/2
	if(issmall(M))
		effective_dose *= 2

	if(alien == IS_UNATHI)
		if(sugary == TRUE)
			if(effective_dose < 2)
				if(effective_dose == metabolism * 2 || prob(5))
					M.emote("yawn")
			else if(effective_dose < 5)
				M.eye_blurry = max(M.eye_blurry, 10)
			else if(effective_dose < 20)
				if(prob(50))
					M.Weaken(2)
				M.drowsyness = max(M.drowsyness, 20)
			else
				M.Sleeping(20)
				M.drowsyness = max(M.drowsyness, 60)

/datum/reagent/drink/juice/lemon
	name = "Lemon Juice"
	id = "lemonjuice"
	description = "This juice is VERY sour."
	taste_description = "sourness"
	taste_mult = 1.1
	color = "#AFAF00"

	glass_name = "lemon juice"
	glass_desc = "Sour..."
	allergen_type = ALLERGEN_FRUIT //Lemons are fruit


/datum/reagent/drink/juice/apple
	name = "Apple Juice"
	id = "applejuice"
	description = "The most basic juice."
	taste_description = "crispness"
	taste_mult = 1.1
	color = "#E2A55F"

	glass_name = "apple juice"
	glass_desc = "An earth favorite."
	allergen_type = ALLERGEN_FRUIT //Apples are fruit

/datum/reagent/drink/juice/lime
	name = "Lime Juice"
	id = "limejuice"
	description = "The sweet-sour juice of limes."
	taste_description = "sourness"
	taste_mult = 1.8
	color = "#365E30"

	glass_name = "lime juice"
	glass_desc = "A glass of sweet-sour lime juice"
	allergen_type = ALLERGEN_FRUIT //Limes are fruit

/datum/reagent/drink/juice/lime/affect_ingest(var/mob/living/carbon/M, var/alien, var/removed)
	..()
	if(alien == IS_DIONA)
		return
	M.adjustToxLoss(-0.5 * removed)

/datum/reagent/drink/juice/orange
	name = "Orange juice"
	id = "orangejuice"
	description = "Both delicious AND rich in Vitamin C, what more do you need?"
	taste_description = "oranges"
	color = "#E78108"

	glass_name = "orange juice"
	glass_desc = "Vitamins! Yay!"
	allergen_type = ALLERGEN_FRUIT //Oranges are fruit

/datum/reagent/drink/juice/orange/affect_ingest(var/mob/living/carbon/M, var/alien, var/removed)
	..()
	if(alien == IS_DIONA)
		return
	M.adjustOxyLoss(-2 * removed)

/datum/reagent/drink/juice/lettuce
	name = "Lettuce Juice"
	id = "lettucejuice"
	description = "It's mostly water, just a bit more lettucy."
	taste_description = "fresh greens"
	color = "#29df4b"

	glass_name = "lettuce juice"
	glass_desc = "This is just lettuce water. Fresh but boring."

/datum/reagent/toxin/poisonberryjuice // It has more in common with toxins than drinks... but it's a juice
	name = "Poison Berry Juice"
	id = "poisonberryjuice"
	description = "A tasty juice blended from various kinds of very deadly and toxic berries."
	taste_description = "berries"
	color = "#863353"
	strength = 5

	glass_name = "poison berry juice"
	glass_desc = "A glass of deadly juice."

/datum/reagent/toxin/meatcolony
	name = "A colony of meat cells"
	id = "meatcolony"
	description = "Specialised cells designed to produce a large amount of meat once activated, whilst manufacturers have managed to stop these cells from taking over the body when ingested, it's still poisonous."
	taste_description = "a fibrous mess"
	reagent_state = LIQUID
	color = "#ff2424"
	strength = 10
	allergen_type = ALLERGEN_MEAT //It's meat.

/datum/reagent/toxin/plantcolony
	name = "A colony of plant cells"
	id = "plantcolony"
	description = "Specialised cells designed to produce a large amount of nutriment once activated, whilst manufacturers have managed to stop these cells from taking over the body when ingested, it's still poisonous."
	taste_description = "a fibrous mess"
	reagent_state = LIQUID
	color = "#7ce01f"
	strength = 10
	allergen_type = ALLERGEN_VEGETABLE //It's plant.

/datum/reagent/drink/juice/potato
	name = "Potato Juice"
	id = "potatojuice"
	description = "Juice of the potato. Bleh."
	taste_description = "potatoes"
	nutrition = 2
	color = "#302000"
	sugary = FALSE

	glass_name = "potato juice"
	glass_desc = "Juice from a potato. Bleh."
	allergen_type = ALLERGEN_VEGETABLE //Potatoes are vegetables

/datum/reagent/drink/juice/turnip
	name = "Turnip Juice"
	id = "turnipjuice"
	description = "Juice of the turnip. A step below the potato."
	taste_description = "turnips"
	nutrition = 2
	color = "#251e2e"
	sugary = FALSE

	glass_name = "turnip juice"
	glass_desc = "Juice of the turnip. A step below the potato."
	allergen_type = ALLERGEN_VEGETABLE //Turnips are vegetables

/datum/reagent/drink/juice/tomato
	name = "Tomato Juice"
	id = "tomatojuice"
	description = "Tomatoes made into juice. What a waste of big, juicy tomatoes, huh?"
	taste_description = "tomatoes"
	color = "#731008"
	sugary = FALSE

	glass_name = "tomato juice"
	glass_desc = "Are you sure this is tomato juice?"
	allergen_type = ALLERGEN_FRUIT //Yes tomatoes are a fruit

/datum/reagent/drink/juice/tomato/affect_ingest(var/mob/living/carbon/M, var/alien, var/removed)
	..()
	if(alien == IS_DIONA)
		return
	M.heal_organ_damage(0, 0.5 * removed)

/datum/reagent/drink/juice/watermelon
	name = "Watermelon Juice"
	id = "watermelonjuice"
	description = "Delicious juice made from watermelon."
	taste_description = "sweet watermelon"
	color = "#B83333"

	glass_name = "watermelon juice"
	glass_desc = "Delicious juice made from watermelon."
	allergen_type = ALLERGEN_FRUIT //Watermelon is a fruit

// Everything else

/datum/reagent/drink/milk
	name = "Milk"
	id = "milk"
	description = "An opaque white liquid produced by the mammary glands of mammals."
	taste_description = "milk"
	color = "#DFDFDF"

	glass_name = "milk"
	glass_desc = "White and nutritious goodness!"

	cup_icon_state = "cup_cream"
	cup_name = "cup of milk"
	cup_desc = "White and nutritious goodness!"
	allergen_type = ALLERGEN_DAIRY //Milk is dairy

/datum/reagent/drink/milk/chocolate
	name =  "Chocolate Milk"
	id = "chocolate_milk"
	description = "A delicious mixture of perfectly healthy mix and terrible chocolate."
	taste_description = "chocolate milk"
	color = "#74533b"

	cup_icon_state = "cup_brown"
	cup_name = "cup of chocolate milk"
	cup_desc = "Deliciously fattening!"

	glass_name = "chocolate milk"
	glass_desc = "Deliciously fattening!"

/datum/reagent/drink/milk/affect_ingest(var/mob/living/carbon/M, var/alien, var/removed)
	..()
	if(alien == IS_DIONA)
		return
	M.heal_organ_damage(0.5 * removed, 0)
	holder.remove_reagent("capsaicin", 10 * removed)

/datum/reagent/drink/milk/cream
	name = "Cream"
	id = "cream"
	description = "The fatty, still liquid part of milk. Why don't you mix this with sum scotch, eh?"
	taste_description = "thick milk"
	color = "#DFD7AF"

	glass_name = "cream"
	glass_desc = "Ewwww..."

	cup_icon_state = "cup_cream"
	cup_name = "cup of cream"
	cup_desc = "Ewwww..."
	allergen_type = ALLERGEN_DAIRY //Cream is dairy

/datum/reagent/drink/milk/soymilk
	name = "Soy Milk"
	id = "soymilk"
	description = "An opaque white liquid made from soybeans."
	taste_description = "soy milk"
	color = "#DFDFC7"

	glass_name = "soy milk"
	glass_desc = "White and nutritious soy goodness!"

	cup_icon_state = "cup_cream"
	cup_name = "cup of milk"
	cup_desc = "White and nutritious goodness!"
	allergen_type = ALLERGEN_BEANS //Would be made from soy beans

/datum/reagent/drink/tea
	name = "Tea"
	id = "tea"
	description = "Tasty black tea, it has antioxidants, it's good for you!"
	taste_description = "black tea"
	color = "#832700"
	adj_dizzy = -2
	adj_drowsy = -1
	adj_sleepy = -3
	adj_temp = 20

	glass_name = "cup of tea"
	glass_desc = "Tasty black tea, it has antioxidants, it's good for you!"

	cup_icon_state = "cup_tea"
	cup_name = "cup of tea"
	cup_desc = "Tasty black tea, it has antioxidants, it's good for you!"
	allergen_type = ALLERGEN_STIMULANT //Black tea strong enough to have significant caffeine content

/datum/reagent/drink/tea/affect_ingest(var/mob/living/carbon/M, var/alien, var/removed)
	..()
	if(alien == IS_DIONA)
		return
	M.adjustToxLoss(-0.5 * removed)

/datum/reagent/drink/tea/decaf
	name = "Decaf Tea"
	id = "teadecaf"
	description = "Tasty black tea, it has antioxidants, it's good for you, and won't keep you up at night!"
	color = "#832700"
	adj_dizzy = 0
	adj_drowsy = 0 //Decaf won't help you here.
	adj_sleepy = 0

	glass_name = "cup of decaf tea"
	glass_desc = "Tasty black tea, it has antioxidants, it's good for you, and won't keep you up at night!"

	cup_name = "cup of decaf tea"
	cup_desc = "Tasty black tea, it has antioxidants, it's good for you, and won't keep you up at night!"
	allergen_type = null //Certified cat-safe!


/datum/reagent/drink/tea/icetea
	name = "Iced Tea"
	id = "icetea"
	description = "No relation to a certain rap artist/ actor."
	taste_description = "sweet tea"
	color = "#AC7F24" // rgb: 16, 64, 56
	adj_temp = -5

	glass_name = "iced tea"
	glass_desc = "No relation to a certain rap artist/ actor."
	glass_special = list(DRINK_ICE)

	cup_icon_state = "cup_tea"
	cup_name = "cup of iced tea"
	cup_desc = "No relation to a certain rap artist/ actor."

/datum/reagent/drink/tea/icetea/affect_ingest(var/mob/living/carbon/M, var/alien, var/removed)
	..()
	if(alien == IS_SLIME)
		if(M.bodytemperature > T0C)
			M.bodytemperature -= 0.5
		if(M.bodytemperature < T0C)
			M.bodytemperature += 0.5
		M.adjustToxLoss(5 * removed)

/datum/reagent/drink/tea/icetea/affect_blood(var/mob/living/carbon/M, var/alien, var/removed)
	..()
	if(alien == IS_SLIME)
		if(M.bodytemperature > T0C)
			M.bodytemperature -= 0.5
		if(M.bodytemperature < T0C)
			M.bodytemperature += 0.5
		M.adjustToxLoss(5 * removed)

/datum/reagent/drink/tea/icetea/decaf
	name = "Decaf Iced Tea"
	glass_name = "decaf iced tea"
	cup_name = "cup of decaf iced tea"
	id = "iceteadecaf"
	adj_dizzy = 0
	adj_drowsy = 0
	adj_sleepy = 0
	allergen_type = null

/datum/reagent/drink/tea/minttea
	name = "Mint Tea"
	id = "minttea"
	description = "A tasty mixture of mint and tea. It's apparently good for you!"
	color = "#A8442C"
	taste_description = "black tea with tones of mint"

	glass_name = "mint tea"
	glass_desc = "A tasty mixture of mint and tea. It's apparently good for you!"

	cup_name = "cup of mint tea"
	cup_desc = "A tasty mixture of mint and tea. It's apparently good for you!"

/datum/reagent/drink/tea/minttea/decaf
	name = "Decaf Mint Tea"
	glass_name = "decaf mint tea"
	cup_name = "cup of decaf mint tea"
	id = "mintteadecaf"
	adj_dizzy = 0
	adj_drowsy = 0
	adj_sleepy = 0
	allergen_type = null

/datum/reagent/drink/tea/lemontea
	name = "Lemon Tea"
	id = "lemontea"
	description = "A tasty mixture of lemon and tea. It's apparently good for you!"
	color = "#FC6A00"
	taste_description = "black tea with tones of lemon"

	glass_name = "lemon tea"
	glass_desc = "A tasty mixture of lemon and tea. It's apparently good for you!"

	cup_name = "cup of lemon tea"
	cup_desc = "A tasty mixture of lemon and tea. It's apparently good for you!"
	allergen_type = ALLERGEN_FRUIT | ALLERGEN_STIMULANT //Made with lemon juice, still tea

/datum/reagent/drink/tea/lemontea/decaf
	name = "Decaf Lemon Tea"
	glass_name = "decaf lemon tea"
	cup_name = "cup of decaf lemon tea"
	id = "lemonteadecaf"
	adj_dizzy = 0
	adj_drowsy = 0
	adj_sleepy = 0
	allergen_type = ALLERGEN_FRUIT //No caffine, still lemon.

/datum/reagent/drink/tea/limetea
	name = "Lime Tea"
	id = "limetea"
	description = "A tasty mixture of lime and tea. It's apparently good for you!"
	color = "#DE4300"
	taste_description = "black tea with tones of lime"

	glass_name = "lime tea"
	glass_desc = "A tasty mixture of lime and tea. It's apparently good for you!"

	cup_name = "cup of lime tea"
	cup_desc = "A tasty mixture of lime and tea. It's apparently good for you!"
	allergen_type = ALLERGEN_FRUIT | ALLERGEN_STIMULANT //Made with lime juice, still tea

/datum/reagent/drink/tea/limetea/decaf
	name = "Decaf Lime Tea"
	glass_name = "decaf lime tea"
	cup_name = "cup of decaf lime tea"
	id = "limeteadecaf"
	adj_dizzy = 0
	adj_drowsy = 0
	adj_sleepy = 0
	allergen_type = ALLERGEN_FRUIT //No caffine, still lime.

/datum/reagent/drink/tea/orangetea
	name = "Orange Tea"
	id = "orangetea"
	description = "A tasty mixture of orange and tea. It's apparently good for you!"
	color = "#FB4F06"
	taste_description = "black tea with tones of orange"

	glass_name = "orange tea"
	glass_desc = "A tasty mixture of orange and tea. It's apparently good for you!"

	cup_name = "cup of orange tea"
	cup_desc = "A tasty mixture of orange and tea. It's apparently good for you!"
	allergen_type = ALLERGEN_FRUIT | ALLERGEN_STIMULANT //Made with orange juice, still tea

/datum/reagent/drink/tea/orangetea/decaf
	name = "Decaf orange Tea"
	glass_name = "decaf orange tea"
	cup_name = "cup of decaf orange tea"
	id = "orangeteadecaf"
	adj_dizzy = 0
	adj_drowsy = 0
	adj_sleepy = 0
	allergen_type = ALLERGEN_FRUIT //No caffine, still orange.

/datum/reagent/drink/tea/berrytea
	name = "Berry Tea"
	id = "berrytea"
	description = "A tasty mixture of berries and tea. It's apparently good for you!"
	color = "#A60735"
	taste_description = "black tea with tones of berries"

	glass_name = "berry tea"
	glass_desc = "A tasty mixture of berries and tea. It's apparently good for you!"

	cup_name = "cup of berry tea"
	cup_desc = "A tasty mixture of berries and tea. It's apparently good for you!"
	allergen_type = ALLERGEN_FRUIT | ALLERGEN_STIMULANT //Made with berry juice, still tea

/datum/reagent/drink/tea/berrytea/decaf
	name = "Decaf Berry Tea"
	glass_name = "decaf berry tea"
	cup_name = "cup of decaf berry tea"
	id = "berryteadecaf"
	adj_dizzy = 0
	adj_drowsy = 0
	adj_sleepy = 0
	allergen_type = ALLERGEN_FRUIT //No caffine, still berries.

/datum/reagent/drink/greentea
	name = "Green Tea"
	id = "greentea"
	description = "A subtle blend of green tea. It's apparently good for you!"
	color = "#A8442C"
	taste_description = "green tea"

	glass_name = "green tea"
	glass_desc = "A subtle blend of green tea. It's apparently good for you!"

	cup_name = "cup of green tea"
	cup_desc = "A subtle blend of green tea. It's apparently good for you!"

/datum/reagent/drink/tea/chaitea
	name = "Chai Tea"
	id = "chaitea"
	description = "A milky tea spiced with cinnamon and cloves."
	color = "#A8442C"
	taste_description = "creamy cinnamon and spice"

	glass_name = "chai tea"
	glass_desc = "A milky tea spiced with cinnamon and cloves."

	cup_name = "cup of chai tea"
	cup_desc = "A milky tea spiced with cinnamon and cloves."
	allergen_type = ALLERGEN_STIMULANT|ALLERGEN_DAIRY //Made with milk and tea.

/datum/reagent/drink/tea/chaitea/decaf
	name = "Decaf Chai Tea"
	glass_name = "decaf chai tea"
	cup_name = "cup of decaf chai tea"
	id = "chaiteadecaf"
	adj_dizzy = 0
	adj_drowsy = 0
	adj_sleepy = 0
	allergen_type = ALLERGEN_DAIRY //No caffeine, still milk.

/datum/reagent/drink/coffee
	name = "Coffee"
	id = "coffee"
	description = "Coffee is a brewed drink prepared from roasted seeds, commonly called coffee beans, of the coffee plant."
	taste_description = "coffee"
	taste_mult = 1.3
	color = "#482000"
	adj_dizzy = -5
	adj_drowsy = -3
	adj_sleepy = -2
	adj_temp = 25
	overdose = 45

	cup_icon_state = "cup_coffee"
	cup_name = "cup of coffee"
	cup_desc = "Don't drop it, or you'll send scalding liquid and ceramic shards everywhere."

	glass_name = "coffee"
	glass_desc = "Don't drop it, or you'll send scalding liquid and glass shards everywhere."
	allergen_type = ALLERGEN_COFFEE | ALLERGEN_STIMULANT //Apparently coffee contains coffee

/datum/reagent/drink/coffee/affect_ingest(var/mob/living/carbon/M, var/alien, var/removed)
	if(alien == IS_DIONA)
		return
	..()
	if(alien == IS_TAJARA)
		M.make_jittery(4) //extra sensitive to caffine
	if(adj_temp > 0)
		holder.remove_reagent("frostoil", 10 * removed)

/datum/reagent/drink/coffee/affect_blood(var/mob/living/carbon/M, var/alien, var/removed)
	..()
	if(alien == IS_TAJARA)
		M.make_jittery(4)
		return

/datum/reagent/drink/coffee/overdose(var/mob/living/carbon/M, var/alien)
	if(alien == IS_DIONA)
		return
	if(alien == IS_TAJARA)
		M.adjustToxLoss(4 * REM)
		M.apply_effect(3, STUTTER)
	M.make_jittery(5)

/datum/reagent/drink/coffee/icecoffee
	name = "Iced Coffee"
	id = "icecoffee"
	description = "Coffee and ice, refreshing and cool."
	color = "#102838"
	adj_temp = -5

	glass_name = "iced coffee"
	glass_desc = "A drink to perk you up and refresh you!"
	glass_special = list(DRINK_ICE)

/datum/reagent/drink/coffee/icecoffee/affect_ingest(var/mob/living/carbon/M, var/alien, var/removed)
	..()
	if(alien == IS_SLIME)
		if(M.bodytemperature > T0C)
			M.bodytemperature -= 0.5
		if(M.bodytemperature < T0C)
			M.bodytemperature += 0.5
		M.adjustToxLoss(5 * removed)

/datum/reagent/drink/coffee/icecoffee/affect_blood(var/mob/living/carbon/M, var/alien, var/removed)
	..()
	if(alien == IS_SLIME)
		if(M.bodytemperature > T0C)
			M.bodytemperature -= 0.5
		if(M.bodytemperature < T0C)
			M.bodytemperature += 0.5
		M.adjustToxLoss(5 * removed)

/datum/reagent/drink/coffee/soy_latte
	name = "Soy Latte"
	id = "soy_latte"
	description = "A nice and tasty beverage while you are reading your hippie books."
	taste_description = "creamy coffee"
	color = "#C65905"
	adj_temp = 5

	glass_desc = "A nice and refreshing beverage while you are reading."
	glass_name = "soy latte"

	cup_icon_state = "cup_latte"
	cup_name = "cup of soy latte"
	cup_desc = "A nice and refreshing beverage while you are reading."
	allergen_type = ALLERGEN_COFFEE|ALLERGEN_BEANS 	//Soy(beans) and coffee

/datum/reagent/drink/coffee/soy_latte/affect_ingest(var/mob/living/carbon/M, var/alien, var/removed)
	..()
	M.heal_organ_damage(0.5 * removed, 0)

/datum/reagent/drink/coffee/cafe_latte
	name = "Cafe Latte"
	id = "cafe_latte"
	description = "A nice, strong and tasty beverage while you are reading."
	taste_description = "bitter cream"
	color = "#C65905"
	adj_temp = 5

	glass_name = "cafe latte"
	glass_desc = "A nice, strong and refreshing beverage while you are reading."

	cup_icon_state = "cup_latte"
	cup_name = "cup of cafe latte"
	cup_desc = "A nice and refreshing beverage while you are reading."
	allergen_type = ALLERGEN_COFFEE|ALLERGEN_DAIRY //Cream and coffee

/datum/reagent/drink/coffee/cafe_latte/affect_ingest(var/mob/living/carbon/M, var/alien, var/removed)
	..()
	M.heal_organ_damage(0.5 * removed, 0)

/datum/reagent/drink/decaf
	name = "Decaf Coffee"
	id = "decaf"
	description = "Coffee with all the wake-up sucked out."
	taste_description = "bad coffee"
	taste_mult = 1.3
	color = "#482000"
	adj_temp = 25

	cup_icon_state = "cup_coffee"
	cup_name = "cup of decaf"
	cup_desc = "Basically just brown, bitter water."

	glass_name = "decaf coffee"
	glass_desc = "Basically just brown, bitter water."
	allergen_type = ALLERGEN_COFFEE //Decaf coffee is still coffee, just less stimulating.

/datum/reagent/drink/hot_coco
	name = "Hot Chocolate"
	id = "hot_coco"
	description = "Made with love! And cocoa beans."
	taste_description = "creamy chocolate"
	reagent_state = LIQUID
	color = "#403010"
	nutrition = 2
	adj_temp = 5

	glass_name = "hot chocolate"
	glass_desc = "Made with love! And cocoa beans."

	cup_icon_state = "cup_coco"
	cup_name = "cup of hot chocolate"
	cup_desc = "Made with love! And cocoa beans."

/datum/reagent/drink/soda/sodawater
	name = "Soda Water"
	id = "sodawater"
	description = "A can of club soda. Why not make a scotch and soda?"
	taste_description = "carbonated water"
	color = "#619494"
	adj_dizzy = -5
	adj_drowsy = -3
	adj_temp = -5

	glass_name = "soda water"
	glass_desc = "Soda water. Why not make a scotch and soda?"
	glass_special = list(DRINK_FIZZ)

/datum/reagent/drink/soda/grapesoda
	name = "Grape Soda"
	id = "grapesoda"
	description = "Grapes made into a fine drank."
	taste_description = "grape soda"
	color = "#421C52"
	adj_drowsy = -3

	glass_name = "grape soda"
	glass_desc = "Looks like a delicious drink!"
	glass_special = list(DRINK_FIZZ)
	allergen_type = ALLERGEN_FRUIT //Made with grape juice

/datum/reagent/drink/soda/tonic
	name = "Tonic Water"
	id = "tonic"
	description = "It tastes strange but at least the quinine keeps the Space Malaria at bay."
	taste_description = "tart and fresh"
	color = "#619494"

	adj_dizzy = -5
	adj_drowsy = -3
	adj_sleepy = -2
	adj_temp = -5

	glass_name = "tonic water"
	glass_desc = "Quinine tastes funny, but at least it'll keep that Space Malaria away."

/datum/reagent/drink/soda/lemonade
	name = "Lemonade"
	id = "lemonade"
	description = "Oh the nostalgia..."
	taste_description = "lemonade"
	color = "#FFFF00"
	adj_temp = -5

	glass_name = "lemonade"
	glass_desc = "Oh the nostalgia..."
	glass_special = list(DRINK_FIZZ)
	allergen_type = ALLERGEN_FRUIT //Made with lemon juice

/datum/reagent/drink/soda/melonade
	name = "Melonade"
	id = "melonade"
	description = "Oh the.. nostalgia?"
	taste_description = "watermelon"
	color = "#FFB3BB"
	adj_temp = -5

	glass_name = "melonade"
	glass_desc = "Oh the.. nostalgia?"
	glass_special = list(DRINK_FIZZ)
	allergen_type = ALLERGEN_FRUIT //Made with watermelon juice

/datum/reagent/drink/soda/appleade
	name = "Appleade"
	id = "appleade"
	description = "Applejuice, improved."
	taste_description = "apples"
	color = "#FFD1B3"
	adj_temp = -5

	glass_name = "appleade"
	glass_desc = "Applejuice, improved."
	glass_special = list(DRINK_FIZZ)
	allergen_type = ALLERGEN_FRUIT //Made with apple juice

/datum/reagent/drink/soda/pineappleade
	name = "Pineappleade"
	id = "pineappleade"
	description = "Pineapple, juiced up."
	taste_description = "sweet`n`sour pineapples"
	color = "#FFFF00"
	adj_temp = -5

	glass_name = "pineappleade"
	glass_desc = "Pineapple, juiced up."
	glass_special = list(DRINK_FIZZ)
	allergen_type = ALLERGEN_FRUIT //Made with pineapple juice

/datum/reagent/drink/soda/kiraspecial
	name = "Kira Special"
	id = "kiraspecial"
	description = "Long live the guy who everyone had mistaken for a girl. Baka!"
	taste_description = "fruity sweetness"
	color = "#CCCC99"
	adj_temp = -5

	glass_name = "Kira Special"
	glass_desc = "Long live the guy who everyone had mistaken for a girl. Baka!"
	glass_special = list(DRINK_FIZZ)
	allergen_type = ALLERGEN_FRUIT //Made from orange and lime juice

/datum/reagent/drink/soda/brownstar
	name = "Brown Star"
	id = "brownstar"
	description = "It's not what it sounds like..."
	taste_description = "orange and cola soda"
	color = "#9F3400"
	adj_temp = -2

	glass_name = "Brown Star"
	glass_desc = "It's not what it sounds like..."
	allergen_type = ALLERGEN_FRUIT | ALLERGEN_STIMULANT //Made with orangejuice and cola

/datum/reagent/drink/soda/brownstar_decaf //For decaf starkist
	name = "Decaf Brown Star"
	id = "brownstar_decaf"
	description = "It's not what it sounds like..."
	taste_description = "orange and cola soda"
	color = "#9F3400"
	adj_temp = -2

	glass_name = "Brown Star"
	glass_desc = "It's not what it sounds like..."

/datum/reagent/drink/milkshake
	name = "Milkshake"
	id = "milkshake"
	description = "Glorious brainfreezing mixture."
	taste_description = "vanilla milkshake"
	color = "#AEE5E4"
	adj_temp = -9

	glass_name = "milkshake"
	glass_desc = "Glorious brainfreezing mixture."
	allergen_type = ALLERGEN_DAIRY //Made with dairy products

/datum/reagent/milkshake/affect_ingest(var/mob/living/carbon/M, var/alien, var/removed)
	..()

	var/effective_dose = dose/2
	if(issmall(M))
		effective_dose *= 2

	if(alien == IS_UNATHI)
		if(effective_dose < 2)
			if(effective_dose == metabolism * 2 || prob(5))
				M.emote("yawn")
		else if(effective_dose < 5)
			M.eye_blurry = max(M.eye_blurry, 10)
		else if(effective_dose < 20)
			if(prob(50))
				M.Weaken(2)
			M.drowsyness = max(M.drowsyness, 20)
		else
			M.Sleeping(20)
			M.drowsyness = max(M.drowsyness, 60)

/datum/reagent/drink/milkshake/chocoshake
	name = "Chocolate Milkshake"
	id = "chocoshake"
	description = "A refreshing chocolate milkshake."
	taste_description = "cold refreshing chocolate and cream"
	color = "#8e6f44" // rgb(142, 111, 68)
	adj_temp = -9

	glass_name = "Chocolate Milkshake"
	glass_desc = "A refreshing chocolate milkshake, just like mom used to make."
	allergen_type = ALLERGEN_DAIRY //Made with dairy products

/datum/reagent/drink/milkshake/berryshake
	name = "Berry Milkshake"
	id = "berryshake"
	description = "A refreshing berry milkshake."
	taste_description = "cold refreshing berries and cream"
	color = "#ffb2b2" // rgb(255, 178, 178)
	adj_temp = -9

	glass_name = "Berry Milkshake"
	glass_desc = "A refreshing berry milkshake, just like mom used to make."
	allergen_type = ALLERGEN_FRUIT|ALLERGEN_DAIRY //Made with berry juice and dairy products

/datum/reagent/drink/milkshake/coffeeshake
	name = "Coffee Milkshake"
	id = "coffeeshake"
	description = "A refreshing coffee milkshake."
	taste_description = "cold energizing coffee and cream"
	color = "#8e6f44" // rgb(142, 111, 68)
	adj_temp = -9
	adj_dizzy = -5
	adj_drowsy = -3
	adj_sleepy = -2

	glass_name = "Coffee Milkshake"
	glass_desc = "An energizing coffee milkshake, perfect for hot days at work.."
	allergen_type = ALLERGEN_DAIRY|ALLERGEN_COFFEE //Made with coffee and dairy products

/datum/reagent/drink/milkshake/coffeeshake/overdose(var/mob/living/carbon/M, var/alien)
	M.make_jittery(5)

/datum/reagent/drink/milkshake/peanutshake
	name = "Peanut Milkshake"
	id = "peanutmilkshake"
	description = "Savory cream in an ice-cold stature."
	taste_description = "cold peanuts and cream"
	color = "#8e6f44"

	glass_name = "Peanut Milkshake"
	glass_desc = "Savory cream in an ice-cold stature."
	allergen_type = ALLERGEN_SEEDS|ALLERGEN_DAIRY //Made with peanutbutter(seeds) and dairy products

/datum/reagent/drink/rewriter
	name = "Rewriter"
	id = "rewriter"
	description = "The secret of the sanctuary of the Libarian..."
	taste_description = "citrus and coffee"
	color = "#485000"
	adj_temp = -5

	glass_name = "Rewriter"
	glass_desc = "The secret of the sanctuary of the Libarian..."
	allergen_type = ALLERGEN_FRUIT|ALLERGEN_COFFEE|ALLERGEN_STIMULANT //Made with space mountain wind (Fruit, caffeine)

/datum/reagent/drink/rewriter/affect_ingest(var/mob/living/carbon/M, var/alien, var/removed)
	..()
	M.make_jittery(5)

/datum/reagent/drink/soda/nuka_cola
	name = "Nuka Cola"
	id = "nuka_cola"
	description = "Cola, cola never changes."
	taste_description = "cola"
	color = "#100800"
	adj_temp = -5
	adj_sleepy = -2

	glass_name = "Nuka-Cola"
	glass_desc = "Don't cry, Don't raise your eye, It's only nuclear wasteland"
	glass_special = list(DRINK_FIZZ)
	allergen_type = ALLERGEN_STIMULANT

/datum/reagent/drink/soda/nuka_cola/affect_ingest(var/mob/living/carbon/M, var/alien, var/removed)
	..()
	M.add_chemical_effect(CE_SPEEDBOOST, 1)
	M.make_jittery(20)
	M.druggy = max(M.druggy, 30)
	M.dizziness += 5
	M.drowsyness = 0

/datum/reagent/drink/grenadine 	//Description implies that the grenadine we would be working with does not contain fruit, so no allergens.
	name = "Grenadine Syrup"
	id = "grenadine"
	description = "Made in the modern day with proper pomegranate substitute. Who uses real fruit, anyways?"
	taste_description = "100% pure pomegranate"
	color = "#FF004F"
	water_based = FALSE

	glass_name = "grenadine syrup"
	glass_desc = "Sweet and tangy, a bar syrup used to add color or flavor to drinks."

/datum/reagent/drink/soda/space_cola
	name = "Space Cola"
	id = "cola"
	description = "A refreshing beverage."
	taste_description = "cola"
	reagent_state = LIQUID
	color = "#100800"
	adj_drowsy = -3
	adj_temp = -5

	glass_name = "Space Cola"
	glass_desc = "A glass of refreshing Space Cola"
	glass_special = list(DRINK_FIZZ)
	allergen_type = ALLERGEN_STIMULANT //Cola is typically caffeinated.

/datum/reagent/drink/soda/decaf_cola
	name = "Space Cola Free"
	id = "decafcola"
	description = "A refreshing beverage with none of the jitters."
	taste_description = "cola"
	reagent_state = LIQUID
	color = "#100800"
	adj_temp = -5

	glass_name = "Space Cola Free"
	glass_desc = "A glass of refreshing Space Cola Free"
	glass_special = list(DRINK_FIZZ)

/datum/reagent/drink/soda/lemon_soda
	name = "Lemon Soda"
	id = "lemonsoda"
	description = "Soda made using lemon concentrate. Sour."
	taste_description = "strong sourness"
	reagent_state = LIQUID
	color = "#ffe658"
	adj_drowsy = -3
	adj_temp = -5

	glass_name = "lemon Soda"
	glass_desc = "A glass of refreshing Lemon Soda. So sour!"
	glass_special = list(DRINK_FIZZ)
	allergen_type = ALLERGEN_FRUIT

/datum/reagent/drink/soda/apple_soda
	name = "Apple Soda"
	id = "applesoda"
	description = "Soda made using fresh apples."
	taste_description = "crisp juiciness"
	reagent_state = LIQUID
	color = "#c73737"
	adj_drowsy = -3
	adj_temp = -5

	glass_name = "Apple Soda"
	glass_desc = "A glass of refreshing Apple Soda. Crisp!"
	glass_special = list(DRINK_FIZZ)
	allergen_type = ALLERGEN_FRUIT


/datum/reagent/drink/soda/straw_soda
	name = "Strawberry Soda"
	id = "strawsoda"
	description = "Soda made using sweet berries."
	taste_description = "oddly bland"
	reagent_state = LIQUID
	color = "#ffa3a3"
	adj_drowsy = -3
	adj_temp = -5

	glass_name = "Strawberry Soda"
	glass_desc = "A glass of refreshing Strawberry Soda"
	glass_special = list(DRINK_FIZZ)
	allergen_type = ALLERGEN_FRUIT

/datum/reagent/drink/soda/orangesoda
	name = "Orange Soda"
	id = "orangesoda"
	description = "Soda made using fresh picked oranges."
	taste_description = "sweet and citrusy"
	reagent_state = LIQUID
	color = "#ff992c"
	adj_drowsy = -3
	adj_temp = -5

	glass_name = "Orange Soda"
	glass_desc = "A glass of refreshing Orange Soda. Delicious!"
	glass_special = list(DRINK_FIZZ)
	allergen_type = ALLERGEN_FRUIT

/datum/reagent/drink/soda/grapesoda
	name = "Grape Soda"
	id = "grapesoda"
	description = "Soda made of carbonated grapejuice."
	taste_description = "tangy goodness"
	reagent_state = LIQUID
	color = "#9862d2"
	adj_drowsy = -3
	adj_temp = -5

	glass_name = "Grape Soda"
	glass_desc = "A glass of refreshing Grape Soda. Tangy!"
	glass_special = list(DRINK_FIZZ)
	allergen_type = ALLERGEN_FRUIT

/datum/reagent/drink/soda/sarsaparilla
	name = "Sarsaparilla"
	id = "sarsaparilla"
	description = "Soda made from genetically modified Mexican sarsaparilla plants."
	taste_description = "licorice and caramel"
	reagent_state = LIQUID
	color = "#e1bb59"
	adj_drowsy = -3
	adj_temp = -5

	glass_name = "Sarsaparilla"
	glass_desc = "A glass of refreshing Sarsaparilla. Delicious!"
	glass_special = list(DRINK_FIZZ)

/datum/reagent/drink/soda/pork_soda
	name = "Bacon Soda"
	id = "porksoda"
	description = "Soda made using pork like flavoring."
	taste_description = "sugar coated bacon"
	reagent_state = LIQUID
	color = "ff8080"
	adj_drowsy = -3
	adj_temp = -5

	glass_name = "Bacon Soda"
	glass_desc = "A glass of Bacon Soda, very odd..."
	glass_special = list(DRINK_FIZZ)

/datum/reagent/drink/soda/spacemountainwind
	name = "Mountain Wind"
	id = "spacemountainwind"
	description = "Blows right through you like a space wind."
	taste_description = "sweet citrus soda"
	color = "#102000"
	adj_drowsy = -7
	adj_sleepy = -1
	adj_temp = -5

	glass_name = "Space Mountain Wind"
	glass_desc = "Space Mountain Wind. As you know, there are no mountains in space, only wind."
	glass_special = list(DRINK_FIZZ)
	allergen_type = ALLERGEN_FRUIT|ALLERGEN_STIMULANT //Citrus, and caffeination

/datum/reagent/drink/soda/dr_gibb
	name = "Dr. Gibb"
	id = "dr_gibb"
	description = "A delicious blend of 42 different flavors."
	taste_description = "cherry soda"
	color = "#102000"
	adj_drowsy = -6
	adj_temp = -5

	glass_name = "Dr. Gibb"
	glass_desc = "Dr. Gibb. Not as dangerous as the name might imply."
	allergen_type = ALLERGEN_STIMULANT

/datum/reagent/drink/soda/space_up
	name = "Space-Up"
	id = "space_up"
	description = "Tastes like a hull breach in your mouth."
	taste_description = "citrus soda"
	color = "#202800"
	adj_temp = -8

	glass_name = "Space-up"
	glass_desc = "Space-up. It helps keep your cool."
	glass_special = list(DRINK_FIZZ)
	allergen_type = ALLERGEN_FRUIT

/datum/reagent/drink/soda/lemon_lime
	name = "Lemon-Lime"
	id = "lemon_lime"
	description = "A tangy substance made of 0.5% natural citrus!"
	taste_description = "tangy lime and lemon soda"
	color = "#878F00"
	adj_temp = -8

	glass_name = "lemon lime soda"
	glass_desc = "A tangy substance made of 0.5% natural citrus!"
	glass_special = list(DRINK_FIZZ)
	allergen_type = ALLERGEN_FRUIT //Made with lemon and lime juice

/datum/reagent/drink/soda/gingerale
	name = "Ginger Ale"
	id = "gingerale"
	description = "The original."
	taste_description = "somewhat tangy ginger ale"
	color = "#edcf8f"
	adj_temp = -8

	glass_name = "ginger ale"
	glass_desc = "The original, refreshing not-actually-ale."
	glass_special = list(DRINK_FIZZ)

/datum/reagent/drink/root_beer
	name = "R&D Root Beer"
	id = "rootbeer"
	color = "#211100"
	adj_drowsy = -6
	taste_description = "sassafras and anise soda"

	glass_name = "glass of R&D Root Beer"
	glass_desc = "A glass of bubbly R&D Root Beer."

/datum/reagent/drink/dr_gibb_diet
	name = "Diet Dr. Gibb"
	id = "diet_dr_gibb"
	color = "#102000"
	taste_description = "chemically sweetened cherry soda"

	glass_name = "glass of Diet Dr. Gibb"
	glass_desc = "Regular Dr.Gibb is probably healthier than this cocktail of artificial flavors."
	glass_special = list(DRINK_FIZZ)

/datum/reagent/drink/shirley_temple
	name = "Shirley Temple"
	id =  "shirley_temple"
	description = "A sweet concotion hated even by its namesake."
	taste_description = "sweet ginger ale"
	color = "#EF304F"
	adj_temp = -8

	glass_name = "shirley temple"
	glass_desc = "A sweet concotion hated even by its namesake."
	glass_special = list(DRINK_FIZZ)

/datum/reagent/drink/roy_rogers
	name = "Roy Rogers"
	id = "roy_rogers"
	description = "I'm a cowboy, on a steel horse I ride."
	taste_description = "cola and fruit"
	color = "#4F1811"
	adj_temp = -8

	glass_name = "roy rogers"
	glass_desc = "I'm a cowboy, on a steel horse I ride"
	glass_special = list(DRINK_FIZZ)
	allergen_type = ALLERGEN_FRUIT | ALLERGEN_STIMULANT //Made with lemon lime and cola

/datum/reagent/drink/collins_mix
	name = "Collins Mix"
	id = "collins_mix"
	description = "Best hope it isn't a hoax."
	taste_description = "gin and lemonade"
	color = "#D7D0B3"
	adj_temp = -8

	glass_name = "collins mix"
	glass_desc = "Best hope it isn't a hoax."
	glass_special = list(DRINK_FIZZ)
	allergen_type = ALLERGEN_FRUIT //Made with lemon lime

/datum/reagent/drink/arnold_palmer
	name = "Arnold Palmer"
	id = "arnold_palmer"
	description = "Tastes just like the old man."
	taste_description = "lemon and sweet tea"
	color = "#AF5517"
	adj_temp = -8

	glass_name = "arnold palmer"
	glass_desc = "Tastes just like the old man."
	glass_special = list(DRINK_FIZZ)
	allergen_type = ALLERGEN_FRUIT | ALLERGEN_STIMULANT //Made with lemonade and tea

/datum/reagent/drink/doctor_delight
	name = "The Doctor's Delight"
	id = "doctorsdelight"
	description = "A gulp a day keeps the MediBot away. That's probably for the best."
	taste_description = "homely fruit smoothie"
	reagent_state = LIQUID
	color = "#FF8CFF"
	nutrition = 1

	glass_name = "The Doctor's Delight"
	glass_desc = "A healthy mixture of juices, guaranteed to keep you healthy until the next toolboxing takes place."
	allergen_type = ALLERGEN_FRUIT|ALLERGEN_DAIRY //Made from several fruit juices, and cream.

/datum/reagent/drink/doctor_delight/affect_ingest(var/mob/living/carbon/M, var/alien, var/removed)
	..()
	if(alien == IS_DIONA)
		return
	M.adjustOxyLoss(-4 * removed)
	M.heal_organ_damage(2 * removed, 2 * removed)
	M.adjustToxLoss(-2 * removed)
	if(M.dizziness)
		M.dizziness = max(0, M.dizziness - 15)
	if(M.confused)
		M.Confuse(-5)

/datum/reagent/drink/dry_ramen
	name = "Dry Ramen"
	id = "dry_ramen"
	description = "Space age food, since August 25, 1958. Contains dried noodles, vegetables, and chemicals that boil in contact with water."
	taste_description = "dry cheap noodles"
	reagent_state = SOLID
	nutrition = 1
	color = "#302000"

/datum/reagent/drink/hot_ramen
	name = "Hot Ramen"
	id = "hot_ramen"
	description = "The noodles are boiled, the flavors are artificial, just like being back in school."
	taste_description = "noodles and salt"
	reagent_state = LIQUID
	color = "#302000"
	nutrition = 5
	adj_temp = 5

/datum/reagent/drink/hell_ramen
	name = "Hell Ramen"
	id = "hell_ramen"
	description = "The noodles are boiled, the flavors are artificial, just like being back in school."
	taste_description = "noodles and spice"
	taste_mult = 1.7
	reagent_state = LIQUID
	color = "#302000"
	nutrition = 5

/datum/reagent/drink/hell_ramen/affect_ingest(var/mob/living/carbon/M, var/alien, var/removed)
	..()
	if(alien == IS_DIONA)
		return
	M.bodytemperature += 10 * TEMPERATURE_DAMAGE_COEFFICIENT

/datum/reagent/drink/sweetsundaeramen
	name = "Dessert Ramen"
	id = "dessertramen"
	description = "How many things can you add to a cup of ramen before it begins to question its exitance?"
	taste_description = "unbearable sweetness"
	color = "#4444FF"
	nutrition = 5

	glass_name = "Sweet Sundae Ramen"
	glass_desc = "How many things can you add to a cup of ramen before it begins to question its existence?"

/datum/reagent/drink/ice
	name = "Ice"
	id = "ice"
	description = "Frozen water, your dentist wouldn't like you chewing this."
	taste_description = "ice"
	reagent_state = SOLID
	color = "#619494"
	adj_temp = -5

	glass_name = "ice"
	glass_desc = "Generally, you're supposed to put something else in there too..."
	glass_icon = DRINK_ICON_NOISY

/datum/reagent/drink/ice/affect_blood(var/mob/living/carbon/M, var/alien, var/removed)
	..()
	if(alien == IS_SLIME)
		if(M.bodytemperature > T0C)
			M.bodytemperature -= rand(1,3)
		if(M.bodytemperature < T0C)
			M.bodytemperature += rand(1,3)
		M.adjustToxLoss(5 * removed)

/datum/reagent/drink/ice/affect_ingest(var/mob/living/carbon/M, var/alien, var/removed)
	..()
	if(alien == IS_SLIME)
		if(M.bodytemperature > T0C)
			M.bodytemperature -= rand(1,3)
		if(M.bodytemperature < T0C)
			M.bodytemperature += rand(1,3)
		M.adjustToxLoss(5 * removed)

/datum/reagent/drink/nothing
	name = "Nothing"
	id = "nothing"
	description = "Absolutely nothing."
	taste_description = "nothing"

	glass_name = "nothing"
	glass_desc = "Absolutely nothing."

/datum/reagent/drink/dreamcream
	name = "Dream Cream"
	id = "dreamcream"
	description = "A smoothy, silky mix of honey and dairy."
	taste_description = "sweet, soothing dairy"
	color = "#fcfcc9" // rgb(252, 252, 201)

	glass_name = "Dream Cream"
	glass_desc = "A smoothy, silky mix of honey and dairy."
	allergen_type = ALLERGEN_DAIRY //Made using dairy

/datum/reagent/drink/soda/vilelemon
	name = "Vile Lemon"
	id = "vilelemon"
	description = "A fizzy, sour lemonade mix."
	taste_description = "fizzy, sour lemon"
	color = "#c6c603" // rgb(198, 198, 3)

	glass_name = "Vile Lemon"
	glass_desc = "A sour, fizzy drink with lemonade and lemonlime."
	glass_special = list(DRINK_FIZZ)
	allergen_type = ALLERGEN_FRUIT|ALLERGEN_STIMULANT //Made from lemonade and mtn wind(caffeine)

/datum/reagent/drink/entdraught
	name = "Ent's Draught"
	id = "entdraught"
	description = "A natural, earthy combination of all things peaceful."
	taste_description = "fresh rain and sweet memories"
	color = "#3a6617" // rgb(58, 102, 23)

	glass_name = "Ent's Draught"
	glass_desc = "You can almost smell the tranquility emanating from this."
	//allergen_type = ALLERGEN_FRUIT Sorry to break the news, chief. Honey is not a fruit.

/datum/reagent/drink/lovepotion
	name = "Love Potion"
	id = "lovepotion"
	description = "Creamy strawberries and sugar, simple and sweet."
	taste_description = "strawberries and cream"
	color = "#fc8a8a" // rgb(252, 138, 138)

	glass_name = "Love Potion"
	glass_desc = "Love me tender, love me sweet."
	allergen_type = ALLERGEN_FRUIT|ALLERGEN_DAIRY //Made from cream(dairy) and berryjuice(fruit)

/datum/reagent/drink/oilslick
	name = "Oil Slick"
	id = "oilslick"
	description = "A viscous, but sweet, ooze."
	taste_description = "honey"
	color = "#FDF5E6" // rgb(253,245,230)
	water_based = FALSE

	glass_name = "Oil Slick"
	glass_desc = "A concoction that should probably be in an engine, rather than your stomach."
	glass_icon = DRINK_ICON_NOISY
	allergen_type = ALLERGEN_VEGETABLE //Made from corn oil

/datum/reagent/drink/slimeslammer
	name = "Slick Slimes Slammer"
	id = "slimeslammer"
	description = "A viscous, but savory, ooze."
	taste_description = "peanuts`n`slime"
	color = "#93604D"
	water_based = FALSE

	glass_name = "Slick Slime Slammer"
	glass_desc = "A concoction that should probably be in an engine, rather than your stomach. Still."
	glass_icon = DRINK_ICON_NOISY
	allergen_type = ALLERGEN_VEGETABLE|ALLERGEN_SEEDS //Made from corn oil and peanutbutter

/datum/reagent/drink/eggnog
	name = "Eggnog"
	id = "eggnog"
	description = "A creamy, rich beverage made out of whisked eggs, milk and sugar, for when you feel like celebrating the winter holidays."
	taste_description = "thick cream and vanilla"
	color = "#fff3c1" // rgb(255, 243, 193)

	glass_name = "Eggnog"
	glass_desc = "You can't egg-nore the holiday cheer all around you"
	allergen_type = ALLERGEN_DAIRY|ALLERGEN_EGGS //Eggnog is made with dairy and eggs.

/datum/reagent/drink/nuclearwaste
	name = "Nuclear Waste"
	id = "nuclearwaste"
	description = "A viscous, glowing slurry."
	taste_description = "sour honey drops"
	color = "#7FFF00" // rgb(127,255,0)
	water_based = FALSE

	glass_name = "Nuclear Waste"
	glass_desc = "Sadly, no super powers."
	glass_icon = DRINK_ICON_NOISY
	glass_special = list(DRINK_FIZZ)
	allergen_type = ALLERGEN_VEGETABLE //Made from oilslick, so has the same allergens.

/datum/reagent/drink/nuclearwaste/affect_blood(var/mob/living/carbon/M, var/alien, var/removed)
	..()
	if(alien == IS_DIONA)
		return
	M.bloodstr.add_reagent("radium", 0.3)

/datum/reagent/drink/nuclearwaste/affect_ingest(var/mob/living/carbon/M, var/alien, var/removed)
	..()
	if(alien == IS_DIONA)
		return
	M.ingested.add_reagent("radium", 0.25)

/datum/reagent/drink/sodaoil //Mixed with normal drinks to make a 'potable' version for Prometheans if mixed 1-1. Dilution is key.
	name = "Soda Oil"
	id = "sodaoil"
	description = "A thick, bubbling soda."
	taste_description = "chewy water"
	color = "#F0FFF0" // rgb(245,255,250)
	water_based = FALSE

	glass_name = "Soda Oil"
	glass_desc = "A pitiful sludge that looks vaguely like a soda.. if you look at it a certain way."
	glass_icon = DRINK_ICON_NOISY
	glass_special = list(DRINK_FIZZ)
	allergen_type = ALLERGEN_VEGETABLE //Made from corn oil

/datum/reagent/drink/sodaoil/affect_blood(var/mob/living/carbon/M, var/alien, var/removed)
	..()
	if(M.bloodstr) // If, for some reason, they are injected, dilute them as well.
		for(var/datum/reagent/R in M.ingested.reagent_list)
			if(istype(R, /datum/reagent/drink))
				var/datum/reagent/drink/D = R
				if(D.water_based)
					M.adjustToxLoss(removed * -3)

/datum/reagent/drink/sodaoil/affect_ingest(var/mob/living/carbon/M, var/alien, var/removed)
	..()
	if(M.ingested) // Find how many drinks are causing tox, and negate them.
		for(var/datum/reagent/R in M.ingested.reagent_list)
			if(istype(R, /datum/reagent/drink))
				var/datum/reagent/drink/D = R
				if(D.water_based)
					M.adjustToxLoss(removed * -2)

/datum/reagent/drink/mojito
	name = "Mojito"
	id = "virginmojito"
	description = "Mint, bubbly water, and citrus, made for sailing."
	taste_description = "mint and lime"
	color = "#FFF7B3"

	glass_name = "mojito"
	glass_desc = "Mint, bubbly water, and citrus, made for sailing."
	glass_special = list(DRINK_FIZZ)
	allergen_type = ALLERGEN_FRUIT //Made with lime juice

/datum/reagent/drink/sexonthebeach
	name = "Virgin Sex On The Beach"
	id = "virginsexonthebeach"
	description = "A secret combination of orange juice and pomegranate."
	taste_description = "60% orange juice, 40% pomegranate"
	color = "#7051E3"

	glass_name = "sex on the beach"
	glass_desc = "A secret combination of orange juice and pomegranate."
	allergen_type = ALLERGEN_FRUIT //Made with orange juice

/datum/reagent/drink/driverspunch
	name = "Driver's Punch"
	id = "driverspunch"
	description = "A fruity punch!"
	taste_description = "sharp, sour apples"
	color = "#D2BA6E"

	glass_name = "driver`s punch"
	glass_desc = "A fruity punch!"
	glass_special = list(DRINK_FIZZ)
	allergen_type = ALLERGEN_FRUIT //Made with appleade and orange juice

/datum/reagent/drink/mintapplesparkle
	name = "Mint Apple Sparkle"
	id = "mintapplesparkle"
	description = "Delicious appleade with a touch of mint."
	taste_description = "minty apples"
	color = "#FDDA98"

	glass_name = "mint apple sparkle"
	glass_desc = "Delicious appleade with a touch of mint."
	glass_special = list(DRINK_FIZZ)
	allergen_type = ALLERGEN_FRUIT //Made with appleade

/datum/reagent/drink/berrycordial
	name = "Berry Cordial"
	id = "berrycordial"
	description = "How <font face='comic sans ms'>berry cordial</font> of you."
	taste_description = "sweet chivalry"
	color = "#D26EB8"

	glass_name = "berry cordial"
	glass_desc = "How <font face='comic sans ms'>berry cordial</font> of you."
	glass_icon = DRINK_ICON_NOISY
	allergen_type = ALLERGEN_FRUIT //Made with berry and lemonjuice

/datum/reagent/drink/tropicalfizz
	name = "Tropical Fizz"
	id = "tropicalfizz"
	description = "One sip and you're in the Bahamas."
	taste_description = "tropical"
	color = "#69375C"

	glass_name = "tropical fizz"
	glass_desc = "One sip and you're in the Bahamas."
	glass_icon = DRINK_ICON_NOISY
	glass_special = list(DRINK_FIZZ)
	allergen_type = ALLERGEN_FRUIT //Made with several fruit juices

/datum/reagent/drink/fauxfizz
	name = "Faux Fizz"
	id = "fauxfizz"
	description = "One sip and you're in the Bahamas... maybe."
	taste_description = "slightly tropical"
	color = "#69375C"

	glass_name = "tropical fizz"
	glass_desc = "One sip and you're in the Bahamas... maybe."
	glass_icon = DRINK_ICON_NOISY
	glass_special = list(DRINK_FIZZ)
	allergen_type = ALLERGEN_FRUIT //made with several fruit juices


/* Alcohol */

// Basic

/datum/reagent/ethanol/absinthe
	name = "Absinthe"
	id = "absinthe"
	description = "Watch out that the Green Fairy doesn't come for you!"
	taste_description = "licorice"
	taste_mult = 1.5
	color = "#33EE00"
	strength = 12

	glass_name = "absinthe"
	glass_desc = "Wormwood, anise, oh my."

/datum/reagent/ethanol/ale
	name = "Ale"
	id = "ale"
	description = "A dark alcoholic beverage made by malted barley and yeast."
	taste_description = "hearty barley ale"
	color = "#4C3100"
	strength = 50

	glass_name = "ale"
	glass_desc = "A freezing pint of delicious ale"

	allergen_type = ALLERGEN_GRAINS //Barley is grain

/datum/reagent/ethanol/beer
	name = "Beer"
	id = "beer"
	description = "An alcoholic beverage made from malted grains, hops, yeast, and water."
	taste_description = "beer"
	color = "#FFD300"
	strength = 50
	nutriment_factor = 1

	glass_name = "beer"
	glass_desc = "A freezing pint of beer"

	allergen_type = ALLERGEN_GRAINS //Made from grains

/datum/reagent/ethanol/beer/affect_ingest(var/mob/living/carbon/M, var/alien, var/removed)
	..()
	if(alien == IS_DIONA)
		return
	M.jitteriness = max(M.jitteriness - 3, 0)

/datum/reagent/ethanol/beer/lite
	name = "Lite Beer"
	id = "litebeer"
	description = "An alcoholic beverage made from malted grains, hops, yeast, water, and water."
	taste_description = "bad beer"
	color = "#FFD300"
	strength = 75
	nutriment_factor = 1

	glass_name = "lite beer"
	glass_desc = "A freezing pint of lite beer"

	allergen_type = ALLERGEN_GRAINS //Made from grains

/datum/reagent/ethanol/bluecuracao
	name = "Blue Curacao"
	id = "bluecuracao"
	description = "Exotically blue, fruity drink, distilled from oranges."
	taste_description = "oranges"
	taste_mult = 1.1
	color = "#0000CD"
	strength = 15

	glass_name = "blue curacao"
	glass_desc = "Exotically blue, fruity drink, distilled from oranges."

	allergen_type = ALLERGEN_FRUIT //Made from oranges(fruit)

/datum/reagent/ethanol/cognac
	name = "Cognac"
	id = "cognac"
	description = "A sweet and strongly alcoholic drink, made after numerous distillations and years of maturing. Classy as fornication."
	taste_description = "rich and smooth alcohol"
	taste_mult = 1.1
	color = "#AB3C05"
	strength = 15

	glass_name = "cognac"
	glass_desc = "Damn, you feel like some kind of French aristocrat just by holding this."

	allergen_type = ALLERGEN_FRUIT //Cognac is made from wine which is made from grapes.

/datum/reagent/ethanol/deadrum
	name = "Deadrum"
	id = "deadrum"
	description = "Popular with the sailors. Not very popular with everyone else."
	taste_description = "butterscotch and salt"
	taste_mult = 1.1
	color = "#ECB633"
	strength = 50

	glass_name = "rum"
	glass_desc = "Now you want to Pray for a pirate suit, don't you?"

/datum/reagent/ethanol/deadrum/affect_ingest(var/mob/living/carbon/M, var/alien, var/removed)
	..()
	if(alien == IS_DIONA)
		return
	M.dizziness +=5

/datum/reagent/ethanol/firepunch
	name = "Fire Punch"
	id = "firepunch"
	description = "Yo ho ho and a jar of honey."
	taste_description = "sharp butterscotch"
	color = "#ECB633"
	strength = 7

	glass_name = "fire punch"
	glass_desc = "Yo ho ho and a jar of honey."

/datum/reagent/ethanol/gin
	name = "Gin"
	id = "gin"
	description = "It's gin. In space. I say, good sir."
	taste_description = "an alcoholic christmas tree"
	color = "#0064C6"
	strength = 50

	glass_name = "gin"
	glass_desc = "A crystal clear glass of Griffeater gin."

	allergen_type = ALLERGEN_FRUIT //Made from juniper berries

//Base type for alcoholic drinks containing coffee
/datum/reagent/ethanol/coffee
	overdose = 45
	allergen_type = ALLERGEN_COFFEE|ALLERGEN_STIMULANT //Contains coffee or is made from coffee

/datum/reagent/ethanol/coffee/affect_ingest(var/mob/living/carbon/M, var/alien, var/removed)
	if(alien == IS_DIONA)
		return
	..()
	M.dizziness = max(0, M.dizziness - 5)
	M.drowsyness = max(0, M.drowsyness - 3)
	M.AdjustSleeping(-2)
	if(M.bodytemperature > 310)
		M.bodytemperature = max(310, M.bodytemperature - (5 * TEMPERATURE_DAMAGE_COEFFICIENT))
	if(alien == IS_TAJARA)
		M.make_jittery(4) //extra sensitive to caffine

/datum/reagent/ethanol/coffee/affect_blood(var/mob/living/carbon/M, var/alien, var/removed)
	if(alien == IS_TAJARA)
		M.make_jittery(4)
		return
	..()

/datum/reagent/ethanol/coffee/overdose(var/mob/living/carbon/M, var/alien)
	if(alien == IS_DIONA)
		return
	if(alien == IS_TAJARA)
		M.adjustToxLoss(4 * REM)
		M.apply_effect(3, STUTTER)
	M.make_jittery(5)

/datum/reagent/ethanol/coffee/kahlua
	name = "Kahlúa"
	id = "kahlua"
	description = "A widely known, Mexican coffee-flavored liqueur. In production since 1936!"
	taste_description = "spiked latte"
	taste_mult = 1.1
	color = "#4C3100"
	strength = 15

	glass_name = "RR coffee liquor"
	glass_desc = "A widely known, Mexican coffee-flavored liqueur. In production since 1936!"
//	glass_desc = "DAMN, THIS THING LOOKS ROBUST" //If this isn't what our players should talk like, it isn't what our game should say to them.

/datum/reagent/ethanol/melonliquor
	name = "Melon Liquor"
	id = "melonliquor"
	description = "A relatively sweet and fruity 46 proof liquor."
	taste_description = "fruity alcohol"
	color = "#138808" // rgb: 19, 136, 8
	strength = 50

	glass_name = "melon liquor"
	glass_desc = "A relatively sweet and fruity 46 proof liquor."

	allergen_type = ALLERGEN_FRUIT //Made from watermelons

/datum/reagent/ethanol/melonspritzer
	name = "Melon Spritzer"
	id = "melonspritzer"
	description = "Melons: Citrus style."
	taste_description = "sour melon"
	color = "#934D5D"
	strength = 10

	glass_name = "melon spritzer"
	glass_desc = "Melons: Citrus style."
	glass_special = list(DRINK_FIZZ)

	allergen_type = ALLERGEN_FRUIT //Made from watermelon juice, apple juice, and lime juice

/datum/reagent/ethanol/rum
	name = "Rum"
	id = "rum"
	description = "Yo-ho-ho and all that."
	taste_description = "spiked butterscotch"
	taste_mult = 1.1
	color = "#ECB633"
	strength = 15

	glass_name = "rum"
	glass_desc = "Makes you want to buy a ship and just go pillaging."

/datum/reagent/ethanol/sake //Made from rice, yes. Rice is technically a grain, but also kinda a psuedo-grain, so I don't count it for grain allergies.
	name = "Sake"
	id = "sake"
	description = "Anime's favorite drink."
	taste_description = "dry alcohol"
	color = "#DDDDDD"
	strength = 25

	glass_name = "sake"
	glass_desc = "A glass of sake."

/datum/reagent/ethanol/sexonthebeach
	name = "Sex On The Beach"
	id = "sexonthebeach"
	description = "A concoction of vodka and a secret combination of orange juice and pomegranate."
	taste_description = "60% orange juice, 40% pomegranate, 100% alcohol"
	color = "#7051E3"
	strength = 15

	glass_name = "sex on the beach"
	glass_desc = "A concoction of vodka and a secret combination of orange juice and pomegranate."

	allergen_type = ALLERGEN_FRUIT //Made from orange juice

/datum/reagent/ethanol/tequila
	name = "Tequila"
	id = "tequilla"
	description = "A strong and mildly flavored, Mexican produced spirit. Feeling thirsty hombre?"
	taste_description = "paint thinner"
	color = "#FFFF91"
	strength = 25

	glass_name = "Tequilla"
	glass_desc = "Now all that's missing is the weird colored shades!"

/datum/reagent/ethanol/thirteenloko
	name = "Thirteen Loko"
	id = "thirteenloko"
	description = "A potent mixture of caffeine and alcohol."
	taste_description = "battery acid"
	color = "#102000"
	strength = 25
	nutriment_factor = 1

	glass_name = "Thirteen Loko"
	glass_desc = "This is a glass of Thirteen Loko, it appears to be of the highest quality. The drink, not the glass."
	allergen_type = ALLERGEN_STIMULANT //Holy shit dude.

/datum/reagent/ethanol/thirteenloko/affect_ingest(var/mob/living/carbon/M, var/alien, var/removed)
	..()
	if(alien == IS_DIONA)
		return
	M.drowsyness = max(0, M.drowsyness - 7)
	if (M.bodytemperature > 310)
		M.bodytemperature = max(310, M.bodytemperature - (5 * TEMPERATURE_DAMAGE_COEFFICIENT))
	M.make_jittery(5)

/datum/reagent/ethanol/vermouth
	name = "Vermouth"
	id = "vermouth"
	description = "You suddenly feel a craving for a martini..."
	taste_description = "dry alcohol"
	taste_mult = 1.3
	color = "#91FF91" // rgb: 145, 255, 145
	strength = 15

	glass_name = "vermouth"
	glass_desc = "You wonder why you're even drinking this straight."
	allergen_type = ALLERGEN_FRUIT //Vermouth is made from wine which is made from grapes(fruit)

/datum/reagent/ethanol/vodka
	name = "Vodka"
	id = "vodka"
	description = "Number one drink AND fueling choice for Russians worldwide."
	taste_description = "grain alcohol"
	color = "#0064C8" // rgb: 0, 100, 200
	strength = 15

	glass_name = "vodka"
	glass_desc = "The glass contain wodka. Xynta."

	allergen_type = ALLERGEN_GRAINS //Vodka is made from grains

/datum/reagent/ethanol/vodka/affect_ingest(var/mob/living/carbon/M, var/alien, var/removed)
	..()
	M.apply_effect(max(M.radiation - 1 * removed, 0), IRRADIATE, check_protection = 0)

/datum/reagent/ethanol/whiskey
	name = "Whiskey"
	id = "whiskey"
	description = "A superb and well-aged single-malt whiskey. Damn."
	taste_description = "molasses"
	color = "#4C3100"
	strength = 25

	glass_name = "whiskey"
	glass_desc = "The silky, smokey whiskey goodness inside the glass makes the drink look very classy."

	allergen_type = ALLERGEN_GRAINS //Whiskey is also made from grain.

/datum/reagent/ethanol/redwine
	name = "Red Wine"
	id = "redwine"
	description = "An premium alcoholic beverage made from distilled grape juice."
	taste_description = "bitter sweetness"
	color = "#7E4043" // rgb: 126, 64, 67
	strength = 15

	glass_name = "red wine"
	glass_desc = "A very classy looking drink."

	allergen_type = ALLERGEN_FRUIT //Wine is made from grapes (fruit)

/datum/reagent/ethanol/whitewine
	name = "White Wine"
	id = "whitewine"
	description = "An premium alcoholic beverage made from fermenting of the non-coloured pulp of grapes."
	taste_description = "light fruity flavor"
	color = "#F4EFB0" // rgb: 244, 239, 176
	strength = 15

	glass_name = "white wine"
	glass_desc = "A very classy looking drink."

	allergen_type = ALLERGEN_FRUIT //Wine is made from grapes (fruit)

/datum/reagent/ethanol/carnoth
	name = "Carnoth"
	id = "carnoth"
	description = "An premium alcoholic beverage made with multiple hybridized species of grapes that give it a dark maroon coloration."
	taste_description = "alcoholic sweet flavor"
	color = "#5B0000" // rgb: 0, 100, 35
	strength = 20

	glass_name = "carnoth"
	glass_desc = "A very classy looking drink."

	allergen_type = ALLERGEN_FRUIT //Wine is made from grapes (fruit)

/datum/reagent/ethanol/pwine
	name = "Poison Wine"
	id = "pwine"
	description = "Is this even wine? Toxic! Hallucinogenic! Probably consumed in boatloads by your superiors!"
	color = "#000000"
	strength = 10
	druggy = 50
	halluci = 10

	glass_name = "???"
	glass_desc = "A black ichor with an oily purple sheer on top. Are you sure you should drink this?"
	allergen_type = ALLERGEN_FRUIT //Made from berries which are fruit

/datum/reagent/ethanol/pwine/affect_ingest(var/mob/living/carbon/M, var/alien, var/removed)
	..()
	if(dose > 30)
		M.adjustToxLoss(2 * removed)
	if(dose > 60 && ishuman(M) && prob(5))
		var/mob/living/carbon/human/H = M
		var/obj/item/organ/internal/heart/L = H.internal_organs_by_name[O_HEART]
		if (L && istype(L))
			if(dose < 120)
				L.take_damage(10 * removed, 0)
			else
				L.take_damage(100, 0)

/datum/reagent/ethanol/wine/champagne
	name = "Champagne"
	id = "champagne"
	description = "A sparkling wine made with Pinot Noir, Pinot Meunier, and Chardonnay."
	taste_description = "fizzy bitter sweetness"
	color = "#D1B166"

	glass_name = "champagne"
	glass_desc = "An even classier looking drink."

	allergen_type = ALLERGEN_FRUIT //Still wine, and still made from grapes (fruit)

/datum/reagent/ethanol/cider
	name = "Cider"
	id = "cider"
	description = "Hard? Soft? No-one knows but it'll get you drunk."
	taste_description = "tartness"
	color = "#CE9C00" // rgb: 206, 156, 0
	strength = 10

	glass_name = "cider"
	glass_desc = "The second most Irish drink."
	glass_special = list(DRINK_FIZZ)

	allergen_type = ALLERGEN_FRUIT //Made from fruit

// Cocktails


/datum/reagent/ethanol/acid_spit
	name = "Acid Spit"
	id = "acidspit"
	description = "A drink for the daring, can be deadly if incorrectly prepared!"
	taste_description = "bitter tang"
	reagent_state = LIQUID
	color = "#365000"
	strength = 30

	glass_name = "Acid Spit"
	glass_desc = "A drink from the company archives. Made from live aliens."

	allergen_type = ALLERGEN_FRUIT //Made from wine (fruit)

/datum/reagent/ethanol/alliescocktail
	name = "Allies Cocktail"
	id = "alliescocktail"
	description = "A drink made from your allies, not as sweet as when made from your enemies."
	taste_description = "bitter sweetness"
	color = "#D8AC45"
	strength = 25

	glass_name = "Allies cocktail"
	glass_desc = "A drink made from your allies."

	allergen_type = ALLERGEN_GRAINS|ALLERGEN_FRUIT //Made from vodka(grain) as well as martini(vermouth(fruit) and gin(fruit))

/datum/reagent/ethanol/aloe
	name = "Aloe"
	id = "aloe"
	description = "So very, very, very good."
	taste_description = "sweet and creamy"
	color = "#B7EA75"
	strength = 15

	glass_name = "Aloe"
	glass_desc = "Very, very, very good."

	allergen_type = ALLERGEN_FRUIT|ALLERGEN_DAIRY|ALLERGEN_GRAINS //Made from cream(dairy), whiskey(grains), and watermelon juice(fruit)

/datum/reagent/ethanol/amasec
	name = "Amasec"
	id = "amasec"
	description = "Official drink of the Gun Club!"
	taste_description = "dark and metallic"
	reagent_state = LIQUID
	color = "#FF975D"
	strength = 25

	glass_name = "Amasec"
	glass_desc = "Always handy before combat!"

	allergen_type = ALLERGEN_FRUIT|ALLERGEN_GRAINS //Made from wine(fruit) and vodka(grains)

/datum/reagent/ethanol/andalusia
	name = "Andalusia"
	id = "andalusia"
	description = "A nice, strangely named drink."
	taste_description = "lemons"
	color = "#F4EA4A"
	strength = 15

	glass_name = "Andalusia"
	glass_desc = "A nice, strange named drink."

	allergen_type = ALLERGEN_GRAINS|ALLERGEN_FRUIT //Made from whiskey(grains) and lemonjuice (fruit)

/datum/reagent/ethanol/antifreeze
	name = "Anti-freeze"
	id = "antifreeze"
	description = "Ultimate refreshment."
	taste_description = "ice cold vodka"
	color = "#56DEEA"
	strength = 12
	adj_temp = 20
	targ_temp = 330

	glass_name = "Anti-freeze"
	glass_desc = "The ultimate refreshment."

	allergen_type = ALLERGEN_GRAINS|ALLERGEN_DAIRY //Made from vodka(grains) and cream(dairy)

/datum/reagent/ethanol/atomicbomb
	name = "Atomic Bomb"
	id = "atomicbomb"
	description = "Nuclear proliferation never tasted so good."
	taste_description = "coffee, almonds, and whiskey, with a kick"
	reagent_state = LIQUID
	color = "#666300"
	strength = 10
	druggy = 50

	glass_name = "Atomic Bomb"
	glass_desc = "We cannot take legal responsibility for your actions after imbibing."

	allergen_type = ALLERGEN_COFFEE|ALLERGEN_DAIRY|ALLERGEN_FRUIT|ALLERGEN_GRAINS|ALLERGEN_STIMULANT //Made from b52 which contains Kahlúa(coffee/caffeine), cognac(fruit), and Irish cream(Whiskey(grains),cream(dairy))

/datum/reagent/ethanol/coffee/b52
	name = "B-52"
	id = "b52"
	description = "Kahlúa, Irish cream, and cognac. You will get bombed."
	taste_description = "coffee, almonds, and whiskey"
	taste_mult = 1.3
	color = "#997650"
	strength = 12

	glass_name = "B-52"
	glass_desc = "Kahlúa, Irish cream, and cognac. You will get bombed."

	allergen_type = ALLERGEN_COFFEE|ALLERGEN_DAIRY|ALLERGEN_FRUIT|ALLERGEN_GRAINS|ALLERGEN_STIMULANT //Made from Kahlúa(coffee/caffeine), cognac(fruit), and Irish cream(Whiskey(grains),cream(dairy))

/datum/reagent/ethanol/bahama_mama
	name = "Bahama mama"
	id = "bahama_mama"
	description = "Tropical cocktail."
	taste_description = "lime and orange"
	color = "#FF7F3B"
	strength = 25

	glass_name = "Bahama Mama"
	glass_desc = "Tropical cocktail."

	allergen_type = ALLERGEN_FRUIT //Made from orange juice and lime juice

/datum/reagent/ethanol/bananahonk
	name = "Banana Mama"
	id = "bananahonk"
	description = "A drink from Clown Heaven."
	taste_description = "bananas and sugar"
	nutriment_factor = 1
	color = "#FFFF91"
	strength = 12

	glass_name = "Banana Honk"
	glass_desc = "A drink from Banana Heaven."

	allergen_type = ALLERGEN_FRUIT|ALLERGEN_DAIRY //Made from banana juice(fruit) and cream(dairy)

/datum/reagent/ethanol/barefoot
	name = "Barefoot"
	id = "barefoot"
	description = "Barefoot and pregnant."
	taste_description = "creamy berries"
	color = "#FFCDEA"
	strength = 30

	glass_name = "Barefoot"
	glass_desc = "Barefoot and pregnant."

	allergen_type = ALLERGEN_DAIRY|ALLERGEN_FRUIT //Made from berry juice (fruit), cream(dairy), and vermouth(fruit)

/datum/reagent/ethanol/beepsky_smash
	name = "Beepsky Smash"
	id = "beepskysmash"
	description = "Deny drinking this and prepare for THE LAW."
	taste_description = "whiskey and citrus"
	taste_mult = 2
	reagent_state = LIQUID
	color = "#404040"
	strength = 12

	glass_name = "Beepsky Smash"
	glass_desc = "Heavy, hot and strong. Just like the Iron fist of the LAW."

	allergen_type = ALLERGEN_FRUIT|ALLERGEN_GRAINS //Made from whiskey(grains), and limejuice(fruit)

/datum/reagent/ethanol/beepsky_smash/affect_ingest(var/mob/living/carbon/M, var/alien, var/removed)
	..()
	M.Stun(2)

/datum/reagent/ethanol/bilk
	name = "Bilk"
	id = "bilk"
	description = "This appears to be beer mixed with milk. Disgusting."
	taste_description = "sour milk"
	color = "#895C4C"
	strength = 50
	nutriment_factor = 2

	glass_name = "bilk"
	glass_desc = "A brew of milk and beer. For those alcoholics who fear osteoporosis."

	allergen_type = ALLERGEN_GRAINS|ALLERGEN_DAIRY //Made from milk(dairy) and beer(grains)

/datum/reagent/ethanol/black_russian
	name = "Black Russian"
	id = "blackrussian"
	description = "For the lactose-intolerant. Still as classy as a White Russian."
	taste_description = "coffee"
	color = "#360000"
	strength = 15

	glass_name = "Black Russian"
	glass_desc = "For the lactose-intolerant. Still as classy as a White Russian."

	allergen_type = ALLERGEN_COFFEE|ALLERGEN_GRAINS|ALLERGEN_STIMULANT //Made from vodka(grains) and Kahlúa(coffee/caffeine)

/datum/reagent/ethanol/bloody_mary
	name = "Bloody Mary"
	id = "bloodymary"
	description = "A strange yet pleasurable mixture made of vodka, tomato and lime juice. Or at least you THINK the red stuff is tomato juice."
	taste_description = "tomatoes with a hint of lime"
	color = "#B40000"
	strength = 15

	glass_name = "Bloody Mary"
	glass_desc = "Tomato juice, mixed with Vodka and a lil' bit of lime. Tastes like liquid murder."

	allergen_type = ALLERGEN_GRAINS|ALLERGEN_FRUIT //Made from vodka (grains), tomato juice(fruit), and lime juice(fruit)

/datum/reagent/ethanol/booger
	name = "Booger"
	id = "booger"
	description = "Ewww..."
	taste_description = "sweet 'n creamy"
	color = "#8CFF8C"
	strength = 30

	glass_name = "Booger"
	glass_desc = "Ewww..."

	allergen_type = ALLERGEN_DAIRY|ALLERGEN_FRUIT //Made from cream(dairy), banana juice(fruit), and watermelon juice(fruit)

/datum/reagent/ethanol/coffee/brave_bull //Since it's under the /coffee subtype, it already has coffee and caffeine allergens.
	name = "Brave Bull"
	id = "bravebull"
	description = "It's just as effective as Dutch-Courage!"
	taste_description = "coffee and paint thinner"
	taste_mult = 1.1
	color = "#4C3100"
	strength = 15

	glass_name = "Brave Bull"
	glass_desc = "Tequilla and coffee liquor, brought together in a mouthwatering mixture. Drink up."

/datum/reagent/ethanol/changelingsting
	name = "Changeling Sting"
	id = "changelingsting"
	description = "You take a tiny sip and feel a burning sensation..."
	taste_description = "constantly changing flavors"
	color = "#2E6671"
	strength = 10

	glass_name = "Changeling Sting"
	glass_desc = "A stingy drink."

	allergen_type = ALLERGEN_FRUIT|ALLERGEN_GRAINS //Made from screwdriver(vodka(grains), orange juice(fruit)), lime juice(fruit), and lemon juice(fruit)

/datum/reagent/ethanol/martini
	name = "Classic Martini"
	id = "martini"
	description = "Vermouth with Gin. Not quite how 007 enjoyed it, but still delicious."
	taste_description = "dry class"
	color = "#0064C8"
	strength = 25

	glass_name = "classic martini"
	glass_desc = "Damn, the bartender even stirred it, not shook it."

	allergen_type = ALLERGEN_FRUIT //Made from gin(fruit) and vermouth(fruit)

/datum/reagent/ethanol/cuba_libre
	name = "Cuba Libre"
	id = "cubalibre"
	description = "Rum, mixed with cola and a splash of lime. Viva la revolucion."
	taste_description = "cola with lime"
	color = "#3E1B00"
	strength = 30

	glass_name = "Cuba Libre"
	glass_desc = "A classic mix of rum, cola, and lime."
	allergen_type = ALLERGEN_STIMULANT //Cola

/datum/reagent/ethanol/rum_and_cola
	name = "Rum and Cola"
	id = "rumandcola"
	description = "A classic mix of sugar with more sugar."
	taste_description = "cola"
	color = "#3E1B00"
	strength = 30

	glass_name = "rum and cola"
	glass_desc = "A classic mix of rum and cola."
	allergen_type = ALLERGEN_STIMULANT // Cola

/datum/reagent/ethanol/demonsblood
	name = "Demons Blood"
	id = "demonsblood"
	description = "This thing makes the hair on the back of your neck stand up."
	taste_description = "sweet tasting iron"
	taste_mult = 1.5
	color = "#820000"
	strength = 15

	glass_name = "Demons' Blood"
	glass_desc = "Just looking at this thing makes the hair on the back of your neck stand up."
	allergen_type = ALLERGEN_FRUIT|ALLERGEN_STIMULANT //Made from space mountain wind(fruit) and dr.gibb(caffeine)

/datum/reagent/ethanol/devilskiss
	name = "Devils Kiss"
	id = "devilskiss"
	description = "Creepy time!"
	taste_description = "bitter iron"
	color = "#A68310"
	strength = 15

	glass_name = "Devil's Kiss"
	glass_desc = "Creepy time!"
	allergen_type = ALLERGEN_COFFEE|ALLERGEN_STIMULANT //Made from Kahlúa (Coffee)

/datum/reagent/ethanol/driestmartini
	name = "Driest Martini"
	id = "driestmartini"
	description = "Only for the experienced. You think you see sand floating in the glass."
	taste_description = "a beach"
	nutriment_factor = 1
	color = "#2E6671"
	strength = 12

	glass_name = "Driest Martini"
	glass_desc = "Only for the experienced. You think you see sand floating in the glass."
	allergen_type = ALLERGEN_FRUIT //Made from gin(fruit)

/datum/reagent/ethanol/ginfizz
	name = "Gin Fizz"
	id = "ginfizz"
	description = "Refreshingly lemony, deliciously dry."
	taste_description = "dry, tart lemons"
	color = "#FFFFAE"
	strength = 30

	glass_name = "gin fizz"
	glass_desc = "Refreshingly lemony, deliciously dry."

	allergen_type = ALLERGEN_FRUIT //Made from gin(fruit) and lime juice(fruit)

/datum/reagent/ethanol/grog
	name = "Grog"
	id = "grog"
	description = "Watered-down rum, pirate approved!"
	taste_description = "a poor excuse for alcohol"
	reagent_state = LIQUID
	color = "#FFBB00"
	strength = 100

	glass_name = "grog"
	glass_desc = "A fine and cepa drink for Space."

/datum/reagent/ethanol/erikasurprise
	name = "Erika Surprise"
	id = "erikasurprise"
	description = "The surprise is, it's green!"
	taste_description = "tartness and bananas"
	color = "#2E6671"
	strength = 15

	glass_name = "Erika Surprise"
	glass_desc = "The surprise is, it's green!"

	allergen_type = ALLERGEN_GRAINS|ALLERGEN_FRUIT //Made from ale (grains), lime juice (fruit), whiskey(grains), banana juice(fruit)

/datum/reagent/ethanol/gargle_blaster
	name = "Pan-Galactic Gargle Blaster"
	id = "gargleblaster"
	description = "Whoah, this stuff looks volatile!"
	taste_description = "your brains smashed out by a lemon wrapped around a gold brick"
	taste_mult = 5
	reagent_state = LIQUID
	color = "#7F00FF"
	strength = 10
	druggy = 15

	glass_name = "Pan-Galactic Gargle Blaster"
	glass_desc = "Does... does this mean that Arthur and Ford are on the station? Oh joy."

	allergen_type = ALLERGEN_FRUIT|ALLERGEN_GRAINS //Made from vodka(grains), gin(fruit), whiskey(grains), cognac(fruit), and lime juice(fruit)

/datum/reagent/ethanol/gintonic
	name = "Gin and Tonic"
	id = "gintonic"
	description = "An all time classic, mild cocktail."
	taste_description = "mild and tart"
	color = "#0064C8"
	strength = 50

	glass_name = "gin and tonic"
	glass_desc = "A mild but still great cocktail. Drink up, like a true Englishman."

	allergen_type = ALLERGEN_FRUIT //Made from gin(fruit)

/datum/reagent/ethanol/goldschlager
	name = "Goldschlager"
	id = "goldschlager"
	description = "100 proof cinnamon schnapps, made for alcoholic teen girls on spring break."
	taste_description = "burning cinnamon"
	taste_mult = 1.3
	color = "#F4E46D"
	strength = 15

	glass_name = "Goldschlager"
	glass_desc = "100 proof that teen girls will drink anything with gold in it."

	allergen_type = ALLERGEN_GRAINS //Made from vodka(grains)

/datum/reagent/ethanol/hippies_delight
	name = "Hippies' Delight"
	id = "hippiesdelight"
	description = "You just don't get it maaaan."
	taste_description = "giving peace a chance"
	reagent_state = LIQUID
	color = "#FF88FF"
	strength = 15
	druggy = 50

	glass_name = "Hippie's Delight"
	glass_desc = "A drink enjoyed by people during the 1960's."

	allergen_type = ALLERGEN_FRUIT|ALLERGEN_GRAINS //Made from gargle blaster which contains vodka(grains), gin(fruit), whiskey(grains), cognac(fruit), and lime juice(fruit)
	//Also, yes. Mushrooms produce psilocybin; however, it's also still just a chemical compound, and not necessarily going to trigger a fungi allergy.

/datum/reagent/ethanol/hooch
	name = "Hooch"
	id = "hooch"
	description = "Either someone's failure at cocktail making or attempt in alcohol production. In any case, do you really want to drink that?"
	taste_description = "pure alcohol"
	color = "#4C3100"
	strength = 25
	toxicity = 2

	glass_name = "Hooch"
	glass_desc = "You've really hit rock bottom now... your liver packed its bags and left last night."

/datum/reagent/ethanol/iced_beer
	name = "Iced Beer"
	id = "iced_beer"
	description = "A beer which is so cold the air around it freezes."
	taste_description = "refreshingly cold"
	color = "#FFD300"
	strength = 50
	adj_temp = -20
	targ_temp = 280

	glass_name = "iced beer"
	glass_desc = "A beer so frosty, the air around it freezes."
	glass_special = list(DRINK_ICE)
	allergen_type = ALLERGEN_GRAINS //Made from beer(grains)

/datum/reagent/ethanol/irishcarbomb
	name = "Irish Car Bomb"
	id = "irishcarbomb"
	description = "Mmm, tastes like chocolate cake..."
	taste_description = "delicious anger"
	color = "#2E6671"
	strength = 15

	glass_name = "Irish Car Bomb"
	glass_desc = "An Irish car bomb."

	allergen_type = ALLERGEN_DAIRY|ALLERGEN_GRAINS //Made from ale(grains) and Irish cream(whiskey(grains), cream(dairy))

/datum/reagent/ethanol/coffee/irishcoffee
	name = "Irish Coffee"
	id = "irishcoffee"
	description = "Coffee, and alcohol. More fun than a Mimosa to drink in the morning."
	taste_description = "giving up on the day"
	color = "#4C3100"
	strength = 15

	glass_name = "Irish coffee"
	glass_desc = "Coffee and alcohol. More fun than a Mimosa to drink in the morning."

	allergen_type = ALLERGEN_COFFEE|ALLERGEN_DAIRY|ALLERGEN_GRAINS|ALLERGEN_STIMULANT //Made from Coffee(coffee/caffeine) and Irish cream(whiskey(grains), cream(dairy))

/datum/reagent/ethanol/irish_cream
	name = "Irish Cream"
	id = "irishcream"
	description = "Whiskey-imbued cream, what else would you expect from the Irish."
	taste_description = "creamy alcohol"
	color = "#DDD9A3"
	strength = 25

	glass_name = "Irish cream"
	glass_desc = "It's cream, mixed with whiskey. What else would you expect from the Irish?"

	allergen_type = ALLERGEN_DAIRY|ALLERGEN_GRAINS //Made from cream(dairy) and whiskey(grains)

/datum/reagent/ethanol/longislandicedtea
	name = "Long Island Iced Tea"
	id = "longislandicedtea"
	description = "The liquor cabinet, brought together in a delicious mix. Intended for middle-aged alcoholic women only."
	taste_description = "sweet tea, with a kick"
	color = "#895B1F"
	strength = 12

	glass_name = "Long Island iced tea"
	glass_desc = "The liquor cabinet, brought together in a delicious mix. Intended for middle-aged alcoholic women only."

	allergen_type = ALLERGEN_GRAINS|ALLERGEN_FRUIT|ALLERGEN_STIMULANT //Made from vodka(grains), cola(caffeine) and gin(fruit)

/datum/reagent/ethanol/manhattan
	name = "Manhattan"
	id = "manhattan"
	description = "The Detective's undercover drink of choice. He never could stomach gin..."
	taste_description = "mild dryness"
	color = "#C13600"
	strength = 15

	glass_name = "Manhattan"
	glass_desc = "The Detective's undercover drink of choice. He never could stomach gin..."

	allergen_type = ALLERGEN_GRAINS|ALLERGEN_FRUIT //Made from whiskey(grains), and vermouth(fruit)

/datum/reagent/ethanol/manhattan_proj
	name = "Manhattan Project"
	id = "manhattan_proj"
	description = "A scientist's drink of choice, for pondering ways to blow up the station."
	taste_description = "death, the destroyer of worlds"
	color = "#C15D00"
	strength = 10
	druggy = 30

	glass_name = "Manhattan Project"
	glass_desc = "A scientist's drink of choice, for thinking how to blow up the station."
	allergen_type = ALLERGEN_GRAINS|ALLERGEN_FRUIT //Made from Manhattan which is made from whiskey(grains), and vermouth(fruit)

/datum/reagent/ethanol/manly_dorf
	name = "The Manly Dorf"
	id = "manlydorf"
	description = "Beer and Ale, brought together in a delicious mix. Intended for true men only."
	taste_description = "hair on your chest and your chin"
	color = "#4C3100"
	strength = 25

	glass_name = "The Manly Dorf"
	glass_desc = "A manly concoction made from Ale and Beer. Intended for true men only."

	allergen_type = ALLERGEN_GRAINS //Made from beer(grains) and ale(grains)

/datum/reagent/ethanol/margarita
	name = "Margarita"
	id = "margarita"
	description = "On the rocks with salt on the rim. Arriba~!"
	taste_description = "dry and salty"
	color = "#8CFF8C"
	strength = 15

	glass_name = "margarita"
	glass_desc = "On the rocks with salt on the rim. Arriba~!"

	allergen_type = ALLERGEN_FRUIT //Made from lime juice(fruit)

/datum/reagent/ethanol/mead
	name = "Mead"
	id = "mead"
	description = "A Viking's drink, though a cheap one."
	taste_description = "sweet yet alcoholic"
	reagent_state = LIQUID
	color = "#FFBB00"
	strength = 30
	nutriment_factor = 1

	glass_name = "mead"
	glass_desc = "A Viking's beverage, though a cheap one."

/datum/reagent/ethanol/moonshine
	name = "Moonshine"
	id = "moonshine"
	description = "You've really hit rock bottom now... your liver packed its bags and left last night."
	taste_description = "bitterness"
	taste_mult = 2.5
	color = "#0064C8"
	strength = 12

	glass_name = "moonshine"
	glass_desc = "You've really hit rock bottom now... your liver packed its bags and left last night."

/datum/reagent/ethanol/neurotoxin
	name = "Neurotoxin"
	id = "neurotoxin"
	description = "A strong neurotoxin that puts the subject into a death-like state."
	taste_description = "a numbing sensation"
	reagent_state = LIQUID
	color = "#2E2E61"
	strength = 10

	glass_name = "Neurotoxin"
	glass_desc = "A drink that is guaranteed to knock you silly."
	glass_icon = DRINK_ICON_NOISY
	glass_special = list("neuroright")

	allergen_type = ALLERGEN_FRUIT|ALLERGEN_GRAINS //Made from gargle blaster which is made from vodka(grains), gin(fruit), whiskey(grains), cognac(fruit), and lime juice(fruit)

/datum/reagent/ethanol/neurotoxin/affect_ingest(var/mob/living/carbon/M, var/alien, var/removed)
	..()
	M.Weaken(3)

/datum/reagent/ethanol/patron
	name = "Patron"
	id = "patron"
	description = "Tequila with silver in it, a favorite of alcoholic women in the club scene."
	taste_description = "metallic paint thinner"
	color = "#585840"
	strength = 30

	glass_name = "Patron"
	glass_desc = "Drinking patron in the bar, with all the subpar ladies."

/datum/reagent/ethanol/red_mead
	name = "Red Mead"
	id = "red_mead"
	description = "The true Viking's drink! Even though it has a strange red color."
	taste_description = "sweet and salty alcohol"
	color = "#C73C00"
	strength = 30

	glass_name = "red mead"
	glass_desc = "A true Viking's beverage, though its color is strange."

/datum/reagent/ethanol/sbiten
	name = "Sbiten"
	id = "sbiten"
	description = "A spicy Vodka! Might be a bit hot for the little guys!"
	taste_description = "hot and spice"
	color = "#FFA371"
	strength = 15
	adj_temp = 50
	targ_temp = 360

	glass_name = "Sbiten"
	glass_desc = "A spicy mix of Vodka and Spice. Very hot."

	allergen_type = ALLERGEN_GRAINS //Made from vodka(grains)

/datum/reagent/ethanol/screwdrivercocktail
	name = "Screwdriver"
	id = "screwdrivercocktail"
	description = "Vodka, mixed with plain ol' orange juice. The result is surprisingly delicious."
	taste_description = "oranges"
	color = "#A68310"
	strength = 15

	glass_name = "Screwdriver"
	glass_desc = "A simple, yet superb mixture of Vodka and orange juice. Just the thing for the tired engineer."

	allergen_type = ALLERGEN_FRUIT|ALLERGEN_GRAINS //Made from vodka(grains) and orange juice(fruit)

/datum/reagent/ethanol/silencer
	name = "Silencer"
	id = "silencer"
	description = "A drink from Mime Heaven."
	taste_description = "a pencil eraser"
	taste_mult = 1.2
	nutriment_factor = 1
	color = "#FFFFFF"
	strength = 12

	glass_name = "Silencer"
	glass_desc = "A drink from mime Heaven."
	allergen_type = ALLERGEN_DAIRY //Made from cream (dairy)

/datum/reagent/ethanol/singulo
	name = "Singulo"
	id = "singulo"
	description = "A blue-space beverage!"
	taste_description = "concentrated matter"
	color = "#2E6671"
	strength = 10

	glass_name = "Singulo"
	glass_desc = "A blue-space beverage."

	allergen_type = ALLERGEN_GRAINS|ALLERGEN_FRUIT //Made from vodka(grains) and wine(fruit)

/datum/reagent/ethanol/snowwhite
	name = "Snow White"
	id = "snowwhite"
	description = "A cold refreshment"
	taste_description = "refreshing cold"
	color = "#FFFFFF"
	strength = 30

	glass_name = "Snow White"
	glass_desc = "A cold refreshment."

	allergen_type = ALLERGEN_COFFEE|ALLERGEN_FRUIT|ALLERGEN_STIMULANT //made from Pineapple juice(fruit), lemon_lime(fruit), and Kahlúa(coffee/caffine)

/datum/reagent/ethanol/suidream
	name = "Sui Dream"
	id = "suidream"
	description = "Comprised of: White soda, blue curacao, melon liquor."
	taste_description = "fruit"
	color = "#00A86B"
	strength = 100

	glass_name = "Sui Dream"
	glass_desc = "A froofy, fruity, and sweet mixed drink. Understanding the name only brings shame."

	allergen_type = ALLERGEN_FRUIT //Made from blue curacao(fruit) and melon liquor(fruit)

/datum/reagent/ethanol/syndicatebomb
	name = "Syndicate Bomb"
	id = "syndicatebomb"
	description = "Tastes like terrorism!"
	taste_description = "strong alcohol"
	color = "#2E6671"
	strength = 10

	glass_name = "Syndicate Bomb"
	glass_desc = "Tastes like terrorism!"

	allergen_type = ALLERGEN_GRAINS|ALLERGEN_STIMULANT //Made from beer(grain) and whiskeycola(whiskey(grain) and cola(caffeine))

/datum/reagent/ethanol/tequilla_sunrise
	name = "Tequila Sunrise"
	id = "tequillasunrise"
	description = "Tequila and orange juice. Much like a Screwdriver, only Mexican~."
	taste_description = "oranges"
	color = "#FFE48C"
	strength = 25

	glass_name = "Tequilla Sunrise"
	glass_desc = "Oh great, now you feel nostalgic about sunrises back on Earth..."

/datum/reagent/ethanol/threemileisland
	name = "Three Mile Island Iced Tea"
	id = "threemileisland"
	description = "Made for a woman, strong enough for a man."
	taste_description = "dry"
	color = "#666340"
	strength = 10
	druggy = 50

	glass_name = "Three Mile Island iced tea"
	glass_desc = "A glass of this is sure to prevent a meltdown."

	allergen_type = ALLERGEN_GRAINS|ALLERGEN_FRUIT //Made from long island iced tea(vodka(grains) and gin(fruit))

/datum/reagent/ethanol/toxins_special
	name = "Toxins Special"
	id = "phoronspecial"
	description = "This thing is literally on fire!"
	taste_description = "spicy toxins"
	reagent_state = LIQUID
	color = "#7F00FF"
	strength = 10
	adj_temp = 15
	targ_temp = 330

	glass_name = "Toxins Special"
	glass_desc = "Whoah, this thing is on fire!"

	allergen_type = ALLERGEN_FRUIT //Made from vermouth(fruit)

/datum/reagent/ethanol/vodkamartini
	name = "Vodka Martini"
	id = "vodkamartini"
	description = "Vodka with Gin. Not quite how 007 enjoyed it, but still delicious."
	taste_description = "shaken, not stirred"
	color = "#0064C8"
	strength = 12

	glass_name = "vodka martini"
	glass_desc ="A bastardization of the classic martini. Still great."

	allergen_type = ALLERGEN_GRAINS|ALLERGEN_FRUIT //made from vodka(grains) and vermouth(fruit)

/datum/reagent/ethanol/vodkatonic
	name = "Vodka and Tonic"
	id = "vodkatonic"
	description = "For when a gin and tonic isn't Russian enough."
	taste_description = "tart bitterness"
	color = "#0064C8" // rgb: 0, 100, 200
	strength = 15

	glass_name = "vodka and tonic"
	glass_desc = "For when a gin and tonic isn't Russian enough."

	allergen_type = ALLERGEN_GRAINS //Made from vodka(grains)

/datum/reagent/ethanol/white_russian
	name = "White Russian"
	id = "whiterussian"
	description = "That's just, like, your opinion, man..."
	taste_description = "coffee icecream"
	color = "#A68340"
	strength = 15

	glass_name = "White Russian"
	glass_desc = "A very nice looking drink. But that's just, like, your opinion, man."

	allergen_type = ALLERGEN_COFFEE|ALLERGEN_GRAINS|ALLERGEN_DAIRY|ALLERGEN_STIMULANT //Made from black Russian(vodka(grains), Kahlúa(coffee/caffeine)) and cream(dairy)

/datum/reagent/ethanol/whiskey_cola
	name = "Whiskey Cola"
	id = "whiskeycola"
	description = "Whiskey, mixed with cola. Surprisingly refreshing."
	taste_description = "cola with an alcoholic undertone"
	color = "#3E1B00"
	strength = 25

	glass_name = "whiskey cola"
	glass_desc = "An innocent-looking mixture of cola and Whiskey. Delicious."

	allergen_type = ALLERGEN_GRAINS|ALLERGEN_STIMULANT //Made from whiskey(grains) and cola(caffeine)

/datum/reagent/ethanol/whiskeysoda
	name = "Whiskey Soda"
	id = "whiskeysoda"
	description = "Ultimate refreshment."
	taste_description = "carbonated whiskey"
	color = "#EAB300"
	strength = 15

	glass_name = "whiskey soda"
	glass_desc = "Ultimate refreshment."

	allergen_type = ALLERGEN_GRAINS //Made from whiskey(grains)

/datum/reagent/ethanol/specialwhiskey // I have no idea what this is and where it comes from
	name = "Special Blend Whiskey"
	id = "specialwhiskey"
	description = "Just when you thought regular station whiskey was good... This silky, amber goodness has to come along and ruin everything. The smell of it singes your nostrils."
	taste_description = "unspeakable whiskey bliss"
	color = "#523600"
	strength = 7

	glass_name = "special blend whiskey"
	glass_desc = "Just when you thought regular station whiskey was good... This silky, amber goodness has to come along and ruin everything."

	allergen_type = ALLERGEN_GRAINS //Whiskey(grains)

/datum/reagent/ethanol/unathiliquor
	name = "Redeemer's Brew"
	id = "unathiliquor"
	description = "This barely qualifies as a drink, and could give jet fuel a run for its money. Also known to cause feelings of euphoria and numbness."
	taste_description = "spiced numbness"
	color = "#242424"
	strength = 5

	glass_name = "unathi liquor"
	glass_desc = "This barely qualifies as a drink, and may cause euphoria and numbness. Imbiber beware!"

/datum/reagent/ethanol/unathiliquor/affect_ingest(var/mob/living/carbon/M, var/alien, var/removed)
	..()
	if(alien == IS_DIONA)
		return

	var/drug_strength = 10
	if(alien == IS_SKRELL)
		drug_strength = drug_strength * 0.8

	M.druggy = max(M.druggy, drug_strength)
	if(prob(10) && isturf(M.loc) && !istype(M.loc, /turf/space) && M.canmove && !M.restrained())
		step(M, pick(cardinal))

/datum/reagent/ethanol/sakebomb
	name = "Sake Bomb"
	id = "sakebomb"
	description = "Alcohol in more alcohol."
	taste_description = "thick, dry alcohol"
	color = "#FFFF7F"
	strength = 12
	nutriment_factor = 1

	glass_name = "Sake Bomb"
	glass_desc = "Some sake mixed into a pint of beer."

	allergen_type = ALLERGEN_GRAINS //Made from beer(grains)

/datum/reagent/ethanol/tamagozake
	name = "Tamagozake"
	id = "tamagozake"
	description = "Sake, egg, and sugar. A disgusting folk cure."
	taste_description = "eggy booze"
	color = "#E8C477"
	strength = 30
	nutriment_factor = 3

	glass_name = "Tamagozake"
	glass_desc = "An egg cracked into sake and sugar."
	allergen_type = ALLERGEN_EGGS //Made with eggs

/datum/reagent/ethanol/ginzamary
	name = "Ginza Mary"
	id = "ginzamary"
	description = "An alcoholic drink made with vodka, sake, and juices."
	taste_description = "spicy tomato sake"
	color = "#FF3232"
	strength = 25

	glass_name = "Ginza Mary"
	glass_desc = "Tomato juice, vodka, and sake make something not quite completely unlike a Bloody Mary."

	allergen_type = ALLERGEN_FRUIT|ALLERGEN_GRAINS //Made from vodka(grains) and tomatojuice(fruit)

/datum/reagent/ethanol/tokyorose
	name = "Tokyo Rose"
	id = "tokyorose"
	description = "A pale pink cocktail made with sake and berry juice."
	taste_description = "fruity booze"
	color = "#FA8072"
	strength = 35

	glass_name = "Tokyo Rose"
	glass_desc = "It's kinda pretty!"

	allergen_type = ALLERGEN_FRUIT //Made from berryjuice

/datum/reagent/ethanol/saketini
	name = "Saketini"
	id = "saketini"
	description = "For when you're too weeb for a real martini."
	taste_description = "dry alcohol"
	color = "#0064C8"
	strength = 15

	glass_name = "Saketini"
	glass_desc = "What are you doing drinking this outside of New Kyoto?"

	allergen_type = ALLERGEN_FRUIT //Made from gin(fruit)

/datum/reagent/ethanol/coffee/elysiumfacepunch
	name = "Elysium Facepunch"
	id = "elysiumfacepunch"
	description = "A loathsome cocktail favored by Heaven's skeleton shift workers."
	taste_description = "sour coffee"
	color = "#8f7729"
	strength = 20

	glass_name = "Elysium Facepunch"
	glass_desc = "A loathsome cocktail favored by Heaven's skeleton shift workers."

	allergen_type = ALLERGEN_COFFEE|ALLERGEN_FRUIT|ALLERGEN_STIMULANT //Made from Kahlúa(Coffee/caffeine) and lemonjuice(fruit)

/datum/reagent/ethanol/erebusmoonrise
	name = "Erebus Moonrise"
	id = "erebusmoonrise"
	description = "A deeply alcoholic mix, popular in Nyx."
	taste_description = "hard alcohol"
	color = "#947459"
	strength = 10

	glass_name = "Erebus Moonrise"
	glass_desc = "A deeply alcoholic mix, popular in Nyx."

	allergen_type = ALLERGEN_GRAINS //Made from whiskey(grains) and Vodka(grains)

/datum/reagent/ethanol/balloon
	name = "Balloon"
	id = "balloon"
	description = "A strange drink invented in the aerostats of Venus."
	taste_description = "strange alcohol"
	color = "#FAEBD7"
	strength = 66

	glass_name = "Balloon"
	glass_desc = "A strange drink invented in the aerostats of Venus."

	allergen_type = ALLERGEN_DAIRY|ALLERGEN_FRUIT //Made from blue curacao(fruit) and cream(dairy)

/datum/reagent/ethanol/natunabrandy
	name = "Natuna Brandy"
	id = "natunabrandy"
	description = "On Natuna, they do the best with what they have."
	taste_description = "watered-down beer"
	color = "#FFFFCC"
	strength = 80

	glass_name = "Natuna Brandy"
	glass_desc = "On Natuna, they do the best with what they have."
	glass_special = list(DRINK_FIZZ)

	allergen_type = ALLERGEN_GRAINS //Made from beer(grains)

/datum/reagent/ethanol/euphoria
	name = "Euphoria"
	id = "euphoria"
	description = "Invented by a Eutopian marketing team, this is one of the most expensive cocktails in existence."
	taste_description = "impossibly rich alcohol"
	color = "#614126"
	strength = 9

	glass_name = "Euphoria"
	glass_desc = "Invented by a Eutopian marketing team, this is one of the most expensive cocktails in existence."

	allergen_type = ALLERGEN_GRAINS|ALLERGEN_FRUIT //Made from specialwhiskey(grain) and cognac(fruit)

/datum/reagent/ethanol/xanaducannon
	name = "Xanadu Cannon"
	id = "xanaducannon"
	description = "Common in the entertainment districts of Titan."
	taste_description = "sweet alcohol"
	color = "#614126"
	strength = 50

	glass_name = "Xanadu Cannon"
	glass_desc = "Common in the entertainment districts of Titan."

	allergen_type = ALLERGEN_GRAINS|ALLERGEN_STIMULANT //Made from ale(grain) and dr.gibb(caffeine)

/datum/reagent/ethanol/debugger
	name = "Debugger"
	id = "debugger"
	description = "From Shelf. Not for human consumption."
	taste_description = "oily bitterness"
	color = "#d3d3d3"
	strength = 32

	glass_name = "Debugger"
	glass_desc = "From Shelf. Not for human consumption."
	allergen_type = ALLERGEN_VEGETABLE //Made from corn oil(vegetable)

/datum/reagent/ethanol/spacersbrew
	name = "Spacer's Brew"
	id = "spacersbrew"
	description = "Ethanol and orange soda. A common emergency drink on frontier colonies."
	taste_description = "bitter oranges"
	color = "#ffc04c"
	strength = 43

	glass_name = "Spacer's Brew"
	glass_desc = "Ethanol and orange soda. A common emergency drink on frontier colonies."

	allergen_type = ALLERGEN_FRUIT|ALLERGEN_STIMULANT //Made from brownstar(orange juice(fruit) + cola(caffeine)

/datum/reagent/ethanol/binmanbliss
	name = "Binman Bliss"
	id = "binmanbliss"
	description = "A dry cocktail popular on Binma."
	taste_description = "very dry alcohol"
	color = "#c3c3c3"
	strength = 24

	glass_name = "Binman Bliss"
	glass_desc = "A dry cocktail popular on Binma."

/datum/reagent/ethanol/chrysanthemum
	name = "Chrysanthemum"
	id = "chrysanthemum"
	description = "An exotic cocktail from New Kyoto."
	taste_description = "fruity liquor"
	color = "#9999FF"
	strength = 35

	glass_name = "Chrysanthemum"
	glass_desc = "An exotic cocktail from New Kyoto."

	allergen_type = ALLERGEN_FRUIT //Made from melon liquor(fruit)

/datum/reagent/ethanol/bitters
	name = "Bitters"
	id = "bitters"
	description = "An aromatic, typically alcohol-based infusions of bittering botanicals and flavoring agents like fruit peels, spices, dried flowers, and herbs."
	taste_description = "sharp bitterness"
	color = "#9b6241" // rgb(155, 98, 65)
	strength = 50

	glass_name = "Bitters"
	glass_desc = "An aromatic, typically alcohol-based infusions of bittering botanicals and flavoring agents like fruit peels, spices, dried flowers, and herbs."

/datum/reagent/ethanol/soemmerfire
	name = "Soemmer Fire"
	id = "soemmerfire"
	description = "A painfully hot mixed drink, for when you absolutely need to hurt right now."
	taste_description = "pure fire"
	color = "#d13b21" // rgb(209, 59, 33)
	strength = 25

	glass_name = "Soemmer Fire"
	glass_desc = "A painfully hot mixed drink, for when you absolutely need to hurt right now."

	allergen_type = ALLERGEN_GRAINS|ALLERGEN_FRUIT //Made from Manhattan(whiskey(grains), vermouth(fruit))

/datum/reagent/drink/soemmerfire/affect_ingest(var/mob/living/carbon/M, var/alien, var/removed)
	..()
	if(alien == IS_DIONA)
		return
	M.bodytemperature += 10 * TEMPERATURE_DAMAGE_COEFFICIENT

/datum/reagent/ethanol/winebrandy
	name = "Wine Brandy"
	id = "winebrandy"
	description = "A premium spirit made from distilled wine."
	taste_description = "very sweet dried fruit with many elegant notes"
	color = "#4C130B" // rgb(76,19,11)
	strength = 20

	glass_name = "Wine Brandy"
	glass_desc = "A very classy looking after-dinner drink."

	allergen_type = ALLERGEN_FRUIT //Made from wine, which is made from fruit

/datum/reagent/ethanol/morningafter
	name = "Morning After"
	id = "morningafter"
	description = "The finest hair of the dog, coming up!"
	taste_description = "bitter regrets"
	color = "#482000" // rgb(72, 32, 0)
	strength = 60

	glass_name = "Morning After"
	glass_desc = "The finest hair of the dog, coming up!"

	allergen_type = ALLERGEN_GRAINS|ALLERGEN_COFFEE|ALLERGEN_STIMULANT //Made from sbiten(vodka(grain)) and coffee(coffee/caffeine)

/datum/reagent/ethanol/vesper
	name = "Vesper"
	id = "vesper"
	description = "A dry martini, ice cold and well shaken."
	taste_description = "lemony class"
	color = "#cca01c" // rgb(204, 160, 28)
	strength = 20

	glass_name = "Vesper"
	glass_desc = "A dry martini, ice cold and well shaken."

	allergen_type = ALLERGEN_FRUIT|ALLERGEN_GRAINS //Made from wine(fruit), vodka(grain), and gin(fruit)

/datum/reagent/ethanol/rotgut
	name = "Rotgut Fever Dream"
	id = "rotgut"
	description = "A heinous combination of clashing flavors."
	taste_description = "plague and coldsweats"
	color = "#3a6617" // rgb(58, 102, 23)
	strength = 10

	glass_name = "Rotgut Fever Dream"
	glass_desc = "Why are you doing this to yourself?"

	allergen_type = ALLERGEN_GRAINS|ALLERGEN_STIMULANT //Made from whiskey(grains), cola (caffeine) and vodka(grains)

/datum/reagent/ethanol/screamingviking
	name = "Screaming Viking"
	id = "screamingviking"
	description = "A boozy, citrus-packed brew."
	taste_description = "the bartender's frustration"
	color = "#c6c603" // rgb(198, 198, 3)
	strength = 9

	glass_name = "Screaming Viking"
	glass_desc = "A boozy, citrus-packed brew."

	allergen_type = ALLERGEN_FRUIT|ALLERGEN_GRAINS //Made from martini(gin(fruit), vermouth(fruit)), vodka tonic(vodka(grain)), and lime juice(fruit)

/datum/reagent/ethanol/robustin
	name = "Robustin"
	id = "robustin"
	description = "A bootleg brew of all the worst things on station."
	taste_description = "cough syrup and fire"
	color = "#6b0145" // rgb(107, 1, 69)
	strength = 10

	glass_name = "Robustin"
	glass_desc = "A bootleg brew of all the worst things on station."

	allergen_type = ALLERGEN_GRAINS|ALLERGEN_DAIRY //Made from antifreeze(vodka(grains),cream(dairy)) and vodka(grains)

/datum/reagent/ethanol/virginsip
	name = "Virgin Sip"
	id = "virginsip"
	description = "A perfect martini, watered down and ruined."
	taste_description = "emasculation and failure"
	color = "#2E6671" // rgb(46, 102, 113)
	strength = 60

	glass_name = "Virgin Sip"
	glass_desc = "A perfect martini, watered down and ruined."

	allergen_type = ALLERGEN_FRUIT //Made from driest martini(gin(fruit))

/datum/reagent/ethanol/jellyshot
	name = "Jelly Shot"
	id = "jellyshot"
	description = "A thick and vibrant alcoholic gel, perfect for the night life."
	taste_description = "thick, alcoholic cherry gel"
	color = "#e00b0b" // rgb(224, 11, 11)
	strength = 10

	glass_name = "Jelly Shot"
	glass_desc = "A thick and vibrant alcoholic gel, perfect for the night life."

	allergen_type = ALLERGEN_FRUIT|ALLERGEN_GRAINS //Made from cherry jelly(fruit), and vodka(grains)

/datum/reagent/ethanol/slimeshot
	name = "Named Bullet"
	id = "slimeshot"
	description = "A thick and toxic slime jelly shot."
	taste_description = "liquified organs"
	color = "#6fa300" // rgb(111, 163, 0)
	strength = 10

	glass_name = "Named Bullet"
	glass_desc = "A thick slime jelly shot. You can feel your death approaching."

	allergen_type = ALLERGEN_GRAINS //Made from vodka(grains)

/datum/reagent/drink/slimeshot/affect_ingest(var/mob/living/carbon/M, var/alien, var/removed)
	..()
	if(alien == IS_DIONA)
		return
	M.reagents.add_reagent("slimejelly", 0.25)

/datum/reagent/ethanol/cloverclub
	name = "Clover Club"
	id = "cloverclub"
	description = "A light and refreshing raspberry cocktail."
	taste_description = "sweet raspberry"
	color = "#dd00a6" // rgb(221, 0, 166)
	strength = 30

	glass_name = "Clover Club"
	glass_desc = "A light and refreshing raspberry cocktail."

	allergen_type = ALLERGEN_FRUIT //Made from berry juice(fruit), lemon juice(fruit), and gin(fruit)

/datum/reagent/ethanol/negroni
	name = "Negroni"
	id = "negroni"
	description = "A dark, complicated mix of gin and campari... classy."
	taste_description = "summer nights and wood smoke"
	color = "#77000d" // rgb(119, 0, 13)
	strength = 25

	glass_name = "Negroni"
	glass_desc = "A dark, complicated blend, perfect for relaxing nights by the fire."

	allergen_type = ALLERGEN_FRUIT //Made from gin(fruit) and vermouth(fruit)

/datum/reagent/ethanol/whiskeysour
	name = "Whiskey Sour"
	id = "whiskeysour"
	description = "A smokey, refreshing lemoned whiskey."
	taste_description = "smoke and citrus"
	color = "#a0692e" // rgb(160, 105, 46)
	strength = 20

	glass_name = "Whiskey Sour"
	glass_desc = "A smokey, refreshing lemoned whiskey."

	allergen_type = ALLERGEN_GRAINS|ALLERGEN_FRUIT //Made from whiskey(grains) and lemon juice(fruit)

/datum/reagent/ethanol/oldfashioned
	name = "Old Fashioned"
	id = "oldfashioned"
	description = "A classic mix of whiskey and sugar... simple and direct."
	taste_description = "smokey, divine whiskey"
	color = "#774410" // rgb(119, 68, 16)
	strength = 15

	glass_name = "Old Fashioned"
	glass_desc = "A classic mix of whiskey and sugar... simple and direct."

	allergen_type = ALLERGEN_GRAINS //Made from whiskey(grains)

/datum/reagent/ethanol/daiquiri
	name = "Daiquiri"
	id = "daiquiri"
	description = "Refeshing rum and citrus. Time for a tropical get away."
	taste_description = "refreshing citrus and rum"
	color = "#d1ff49" // rgb(209, 255, 73
	strength = 25

	glass_name = "Daiquiri"
	glass_desc = "Refeshing rum and citrus. Time for a tropical get away."

	allergen_type = ALLERGEN_FRUIT //Made from lime juice(fruit)

/datum/reagent/ethanol/mojito
	name = "Mojito"
	id = "mojito"
	description = "Minty rum and citrus, made for sailing."
	taste_description = "minty rum and lime"
	color = "#d1ff49" // rgb(209, 255, 73
	strength = 30

	glass_name = "Mojito"
	glass_desc = "Minty rum and citrus, made for sailing."
	glass_special = list(DRINK_FIZZ)

	allergen_type = ALLERGEN_FRUIT //Made from lime juice(fruit)

/datum/reagent/ethanol/paloma
	name = "Paloma"
	id = "paloma"
	description = "Tequila and citrus, iced just right..."
	taste_description = "grapefruit and cold fire"
	color = "#ffb070" // rgb(255, 176, 112)
	strength = 20

	glass_name = "Paloma"
	glass_desc = "Tequila and citrus, iced just right..."
	glass_special = list(DRINK_FIZZ)

	allergen_type = ALLERGEN_FRUIT //Made from orange juice(fruit)

/datum/reagent/ethanol/piscosour
	name = "Pisco Sour"
	id = "piscosour"
	description = "Wine Brandy, Lemon, and a dream. A South American classic"
	taste_description = "light sweetness"
	color = "#f9f96b" // rgb(249, 249, 107)
	strength = 30

	glass_name = "Pisco Sour"
	glass_desc = "South American bliss, served ice cold."

	allergen_type = ALLERGEN_FRUIT //Made from wine brandy(fruit), and lemon juice(fruit)

/datum/reagent/ethanol/coldfront
	name = "Cold Front"
	id = "coldfront"
	description = "Minty, rich, and painfully cold. It's a blizzard in a cup."
	taste_description = "biting cold"
	color = "#ffe8c4" // rgb(255, 232, 196)
	strength = 30
	adj_temp = -20
	targ_temp = 220 //Dangerous to certain races. Drink in moderation.

	glass_name = "Cold Front"
	glass_desc = "Minty, rich, and painfully cold. It's a blizzard in a cup."

	allergen_type = ALLERGEN_COFFEE|ALLERGEN_STIMULANT //Made from iced coffee(coffee)

/datum/reagent/ethanol/mintjulep
	name = "Mint Julep"
	id = "mintjulep"
	description = "Minty and refreshing, perfect for a hot day."
	taste_description = "refreshing mint"
	color = "#bbfc8a" // rgb(187, 252, 138)
	strength = 25
	adj_temp = -5

	glass_name = "Mint Julep"
	glass_desc = "Minty and refreshing, perfect for a hot day."

/datum/reagent/ethanol/godsake
	name = "Gods Sake"
	id = "godsake"
	description = "Anime's favorite drink."
	taste_description = "the power of god and anime"
	color = "#DDDDDD"
	strength = 25

	glass_name = "God's Sake"
	glass_desc = "A glass of sake."

/datum/reagent/ethanol/godka
	name = "Godka"
	id = "godka"
	description = "Number one drink AND fueling choice for Russians multiverse-wide."
	taste_description = "Russian steel and a hint of grain"
	color = "#0064C8"
	strength = 50

	glass_name = "Godka"
	glass_desc = "The glass is barely able to contain the wodka. Xynta."
	glass_special = list(DRINK_FIZZ)

	allergen_type = ALLERGEN_GRAINS //Made from vodka(grain)

/datum/reagent/ethanol/godka/affect_ingest(var/mob/living/carbon/M, var/alien, var/removed)
	..()
	M.apply_effect(max(M.radiation - 5 * removed, 0), IRRADIATE, check_protection = 0)
	if(ishuman(M))
		var/mob/living/carbon/human/H = M
		if(H.species.has_organ[O_LIVER])
			var/obj/item/organ/L = H.internal_organs_by_name[O_LIVER]
			if(!L)
				return
			var/adjust_liver = rand(-3, 2)
			if(prob(L.damage))
				to_chat(M, "<span class='cult'>You feel woozy...</span>")
			L.damage = max(L.damage + (adjust_liver * removed), 0)
	var/adjust_tox = rand(-4, 2)
	M.adjustToxLoss(adjust_tox * removed)

/datum/reagent/ethanol/holywine
	name = "Angel Ichor"
	id = "holywine"
	description = "A premium alcoholic beverage made from distilled angel blood."
	taste_description = "wings in a glass, and a hint of grape"
	color = "#C4921E"
	strength = 20

	glass_name = "Angel Ichor"
	glass_desc = "A very pious looking drink."
	glass_icon = DRINK_ICON_NOISY

	allergen_type = ALLERGEN_FRUIT //Made from grapes(fruit)

/datum/reagent/ethanol/holy_mary
	name = "Holy Mary"
	id = "holymary"
	description = "A strange yet pleasurable mixture made of vodka, angel's ichor and lime juice. Or at least you THINK the yellow stuff is angel's ichor."
	taste_description = "grapes with a hint of lime"
	color = "#DCAE12"
	strength = 20

	glass_name = "Holy Mary"
	glass_desc = "Angel's Ichor, mixed with Vodka and a lil' bit of lime. Tastes like liquid ascension."

	allergen_type = ALLERGEN_FRUIT|ALLERGEN_GRAINS //Made from vodka(grain), holy wine(fruit), and lime juice(fruit)

/datum/reagent/ethanol/angelswrath
	name = "Angels Wrath"
	id = "angelswrath"
	description = "This thing makes the hair on the back of your neck stand up."
	taste_description = "sweet victory and sour iron"
	taste_mult = 1.5
	color = "#F3C906"
	strength = 30

	glass_name = "Angels' Wrath"
	glass_desc = "Just looking at this thing makes you sweat."
	glass_icon = DRINK_ICON_NOISY
	glass_special = list(DRINK_FIZZ)

	allergen_type = ALLERGEN_FRUIT|ALLERGEN_STIMULANT //Made from space mountain wind(fruit), dr.gibb(caffine) and holy wine(fruit)

/datum/reagent/ethanol/angelskiss
	name = "Angels Kiss"
	id = "angelskiss"
	description = "Miracle time!"
	taste_description = "sweet forgiveness and bitter iron"
	color = "#AD772B"
	strength = 25

	glass_name = "Angel's Kiss"
	glass_desc = "Miracle time!"

	allergen_type = ALLERGEN_FRUIT|ALLERGEN_COFFEE|ALLERGEN_STIMULANT //Made from holy wine(fruit), and Kahlúa(coffee)

/datum/reagent/ethanol/ichor_mead
	name = "Ichor Mead"
	id = "ichor_mead"
	description = "A trip to Valhalla."
	taste_description = "valhalla"
	color = "#955B37"
	strength = 30

	glass_name = "Ichor Mead"
	glass_desc = "A trip to Valhalla."

	allergen_type = ALLERGEN_FRUIT //Made from holy wine(fruit)

/datum/reagent/ethanol/schnapps_pep
	name = "Peppermint Schnapps"
	id = "schnapps_pep"
	description = "Achtung, pfefferminze."
	taste_description = "minty alcohol"
	color = "#8FC468"
	strength = 25

	glass_name = "peppermint schnapps"
	glass_desc = "A glass of peppermint schnapps. It seems like it'd be better, mixed."

/datum/reagent/ethanol/schnapps_pea
	name = "Peach Schnapps"
	id = "schnapps_pea"
	description = "Achtung, fruchtig."
	taste_description = "peaches"
	color = "#d67d4d"
	strength = 25

	glass_name = "peach schnapps"
	glass_desc = "A glass of peach schnapps. It seems like it'd be better, mixed."

	allergen_type = ALLERGEN_FRUIT //Made from peach(fruit)

/datum/reagent/ethanol/schnapps_lem
	name = "Lemonade Schnapps"
	id = "schnapps_lem"
	description = "Childhood memories are not included."
	taste_description = "sweet, lemon-y alcohol"
	color = "#FFFF00"
	strength = 25

	glass_name = "lemonade schnapps"
	glass_desc = "A glass of lemonade schnapps. It seems like it'd be better, mixed."

	allergen_type = ALLERGEN_FRUIT //Made from lemons(fruit)

/datum/reagent/ethanol/jager
	name = "Schuss Konig"
	id = "jager"
	description = "A complex alcohol that leaves you feeling all warm inside."
	taste_description = "complex, rich alcohol"
	color = "#7f6906"
	strength = 25

	glass_name = "schusskonig"
	glass_desc = "A glass of schusskonig digestif. Good for shooting or mixing."

/datum/reagent/ethanol/fusionnaire
	name = "Fusionnaire"
	id = "fusionnaire"
	description = "A drink for the brave."
	taste_description = "a painfully alcoholic lemon soda with an undertone of mint"
	color = "#6BB486"
	strength = 9

	glass_name = "fusionnaire"
	glass_desc = "A relatively new cocktail, mostly served in the bars of NanoTrasen owned stations."

	allergen_type = ALLERGEN_FRUIT|ALLERGEN_GRAINS //Made from lemon juice(fruit), vodka(grains), and lemon schnapps(fruit)

/datum/reagent/ethanol/deathbell
	name = "Deathbell"
	id = "deathbell"
	description = "A successful experiment to make the most alcoholic thing possible."
	taste_description = "your brains smashed out by a smooth brick of hard, ice cold alcohol"
	color = "#9f6aff"
	taste_mult = 5
	strength = 10
	adj_temp = 10
	targ_temp = 330

	glass_name = "Deathbell"
	glass_desc = "The perfect blend of the most alcoholic things a bartender can get their hands on."

	allergen_type = ALLERGEN_GRAINS|ALLERGEN_DAIRY|ALLERGEN_FRUIT //Made from antifreeze(vodka(grains),cream(dairy)), gargleblaster(vodka(grains),gin(fruit),whiskey(grains),cognac(fruit),lime juice(fruit)), and syndicate bomb(beer(grain),whiskeycola(whiskey(grain)))

/datum/reagent/ethanol/deathbell/affect_ingest(var/mob/living/carbon/M, var/alien, var/removed)
	..()

	if(dose * strength >= strength) // Early warning
		M.make_dizzy(24) // Intentionally higher than normal to compensate for it's previous effects.
	if(dose * strength >= strength * 2.5) // Slurring takes longer. Again, intentional.
		M.slurring = max(M.slurring, 30)

/datum/reagent/drink/soda/kompot
	name = "Kompot"
	id = "kompot"
	description = "A traditional Eastern European beverage once used to preserve fruit in the 1980s"
	taste_description = "refreshingly sweet and fruity"
	color = "#ed9415" // rgb: 237, 148, 21
	adj_drowsy = -1
	adj_temp = -6
	glass_name = "kompot"
	glass_desc = "A glass of refreshing kompot."
	glass_special = list(DRINK_FIZZ)

/datum/reagent/ethanol/kvass
	name = "Kvass"
	id = "kvass"
	description = "A traditional fermented Slavic and Baltic beverage commonly made from rye bread."
	taste_description = "a warm summer day at babushka's cabin"
	color = "#b78315" // rgb: 183, 131, 21
	strength = 95 //It's just soda to Russians
	nutriment_factor = 2
	glass_name = "kvass"
	glass_desc = "A hearty glass of Slavic brew."

//Querbalak stuff
/datum/reagent/drink/juice/dyn
	name = "Dyn juice"
	id = "dynjuice"
	description = "Juice from a Qerr'balakian herb. Good for you, but usually diluted for potability."
	taste_description = "astringent menthol"
	color = "#00e0e0"
	glass_name = "dyn juice"
	glass_desc = "Juice from a Qerr'balakian herb. Good for you, but usually diluted for potability."
	sugary = FALSE

/datum/reagent/drink/tea/dyn
	name = "Dyn tea"
	id = "dynhot"
	description = "A traditional skrellian drink with documented medicinal properties."
	color = "#00e0e0"
	taste_description = "peppermint water"
	allergen_type = null //no caffine here
	glass_name = "dyn tea"
	glass_desc = "An old-fashioned, but traditional skrellian drink with documented medicinal properties."
	cup_name = "cup of dyn tea"
	cup_desc = "An old-fashioned, but traditional skrellian drink with documented medicinal properties."

/datum/reagent/drink/tea/icetea/dyn
	name = "Dyn iced tea"
	id = "dyncold"
	description = "A modern spin on an old formula. Good for you!"
	color = "#00e0e0"
	taste_description = "fizzy mint tea"
	allergen_type = null
	glass_name = "dyn iced tea"
	glass_desc = "A modern spin on an old formula. Good for you!"

/datum/reagent/nutriment/qazal_flour
	name = "Qa'zal flour"
	id = "qazal_flour"
	description = "Harvested from ground qa'zal, this is one of the main ingredients in qa'zal bread."
	taste_description = "chalky, sweet dryness"
	reagent_state = SOLID
	nutriment_factor = 1
	color = "#c499bc"

/datum/reagent/nutriment/kirani_jelly
	name = "Kirani jelly"
	id = "kirani_jelly"
	description = "Sticky, sweet jelly from ground kiriani fruits."
	taste_description = "ultra-sweet fruity jelly"
	color = "#993c5c"

/datum/reagent/drink/gauli_juice
	name = "Ga'uli juice"
	id = "gauli_juice"
	description = "Juice from a ga'uli pod, used in skrellian and teshari cooking."
	color = "#6f83a6"
	taste_description = "mintyness"

/datum/reagent/ethanol/kiranicider
	name = "Kirani cider"
	id = "kirani_cider"
	description = "Fermented kirani jelly, popular among teshari packs."
	taste_description = "sweet, tangy, fruity alcohol"
	color = "#993c5c"
	strength = 10
	glass_name = "kirani cider"
	glass_desc = "Fermented kirani jelly, popular among teshari packs."
	allergen_type = ALLERGEN_FRUIT //Made from fruit

/datum/reagent/ethanol/sirisaian_pole
	name = "Sirisaian pole"
	id = "sirisaian_pole"
	description = "Fermented kirani mixed with ga'uli and ice, for a fruity cocktail as cold as Sirisai's poles."
	taste_description = "chilled, minty, sweet fruit with an alcoholic kick"
	color = "#993c5c"
	strength = 10
	adj_temp = -20
	targ_temp = 220
	glass_name = "Sirisaian pole"
	glass_desc = "Fermented kirani mixed with ga'uli and ice, for a fruity cocktail as cold as Sirisai's poles."
	allergen_type = ALLERGEN_FRUIT //Made with kirani and ga'uli

/datum/reagent/drink/soda/kiraniade
	name = "Kiraniade"
	id = "kiraniade"
	description = "Kirani jelly mixed with soda water into a more drinkable form, sweet enough to not even need extra sugar added."
	taste_description = "super sweet, fizzy fruit"
	color = "#993c5c"
	adj_temp = -5
	glass_name = "kiraniade"
	glass_desc = "Kirani jelly mixed with soda water into a more drinkable form, sweet enough to not even need extra sugar added."
	glass_special = list(DRINK_FIZZ)
	allergen_type = ALLERGEN_FRUIT //Made with kirani
