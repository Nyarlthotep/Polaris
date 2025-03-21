#define HUMAN_LOWEST_SLOWDOWN -3

/mob/living/carbon/human/movement_delay(oldloc, direct)

	. = 0

	if (istype(loc, /turf/space))
		return ..() - 1

	. += species.get_slowdown(src)

	if(force_max_speed)
		return ..() + HUMAN_LOWEST_SLOWDOWN

	for(var/datum/modifier/M in modifiers)
		if(!isnull(M.haste) && M.haste == TRUE)
			return ..() + HUMAN_LOWEST_SLOWDOWN // Returning -1 will actually result in a slowdown for Teshari.
		if(!isnull(M.slowdown))
			. += M.slowdown

	var/health_deficiency = (getMaxHealth() - health)
	if(health_deficiency >= 40) . += (health_deficiency / 25)

	if(can_feel_pain())
		if(halloss >= 10) . += (halloss / 10) //halloss shouldn't slow you down if you can't even feel it

	var/hungry = (MAX_NUTRITION - nutrition) / 5
	if (hungry >= 70) . += hungry/50

	if(istype(buckled, /obj/structure/bed/chair/wheelchair))
		for(var/organ_name in list(BP_L_HAND, BP_R_HAND, BP_L_ARM, BP_R_ARM))
			var/obj/item/organ/external/E = get_organ(organ_name)
			if(!E || E.is_stump())
				. += 4
			else if(E.splinted && E.splinted.loc != E)
				. += 0.5
			else if(E.status & ORGAN_BROKEN)
				. += 1.5
	else
		for(var/organ_name in list(BP_L_LEG, BP_R_LEG, BP_L_FOOT, BP_R_FOOT))
			var/obj/item/organ/external/E = get_organ(organ_name)
			if(!E || E.is_stump())
				. += 4
			else if(E.splinted && E.splinted.loc != E)
				. += 0.5
			else if(E.status & ORGAN_BROKEN)
				. += 1.5

	if(shock_stage >= 10) . += 3

	if(aiming && aiming.aiming_at) . += 5 // Iron sights make you slower, it's a well-known fact.

	if(FAT in src.mutations)
		. += 1.5

	if (bodytemperature < species.cold_level_1)
		. += (species.cold_level_1 - bodytemperature) / 10 * 1.75

	. += max(2 * stance_damage, 0) //damaged/missing feet or legs is slow

	if(mRun in mutations)
		. = 0

	// Turf related slowdown
	var/turf/T = get_turf(src)
	. += calculate_turf_slowdown(T, direct)

	// Item related slowdown.
	var/item_tally = calculate_item_encumbrance()

	// Dragging heavy objects will also slow you down, similar to above.
	if(pulling)
		if(istype(pulling, /obj/item))
			var/obj/item/pulled = pulling
			item_tally += max(pulled.slowdown, 0)
		else if(ishuman(pulling))
			var/mob/living/carbon/human/H = pulling
			var/their_slowdown = max(H.calculate_item_encumbrance(), 1)
			item_tally = max(item_tally, their_slowdown) // If our slowdown is less than theirs, then we become as slow as them (before species modifires).

	item_tally *= species.item_slowdown_mod

	. += item_tally

	if(CE_SLOWDOWN in chem_effects)
		if (. >= 0 )
			. *= 1.25 //Add a quarter of penalties on top.
		. += chem_effects[CE_SLOWDOWN]

	if(CE_SPEEDBOOST in chem_effects)
		if (. >= 0)	// cut any penalties in half
			. *= 0.5
		. -= chem_effects[CE_SPEEDBOOST]	// give 'em a buff on top.

	. = max(HUMAN_LOWEST_SLOWDOWN, . + config.human_delay)	// Minimum return should be the same as force_max_speed
	. += ..()

/mob/living/carbon/human/Moved()
	. = ..()
	if(embedded_flag)
		handle_embedded_objects() //Moving with objects stuck in you can cause bad times.

// This calculates the amount of slowdown to receive from items worn. This does NOT include species modifiers.
// It is in a separate place to avoid an infinite loop situation with dragging mobs dragging each other.
// Also its nice to have these things separated.
/mob/living/carbon/human/proc/calculate_item_encumbrance()
	if(!buckled && shoes) // Shoes can make you go faster.
		. += shoes.slowdown

	// Loop through some slots, and add up their slowdowns.
	// Includes slots which can provide armor, the back slot, belt, and suit storage.
	for(var/obj/item/I in list(wear_suit, w_uniform, back, gloves, head, s_store, belt))
		. += I.slowdown

	// Hands are also included, to make the 'take off your armor instantly and carry it with you to go faster' trick no longer viable.
	// This is done separately to disallow negative numbers (so you can't hold shoes in your hands to go faster).
	for(var/obj/item/I in list(r_hand, l_hand))
		. += max(I.slowdown, 0)

// Similar to above, but for turf slowdown.
/mob/living/carbon/human/proc/calculate_turf_slowdown(turf/T, direct)
	if(!T)
		return 0

	var/movecost = T.get_movement_cost()
	var/snow_layers = SNOW_NONE
	if (istype(T, /turf/simulated/floor)) // isfloor() doesn't work here, since snow is specifically on simulated floors only
		var/turf/simulated/floor/F = T
		snow_layers = max(SNOW_NONE, F.snow_layers)
	if(movecost)
		var/turf_move_cost = movecost
		if(istype(T, /turf/simulated/floor/water))
			if(species.water_movement)
				turf_move_cost = clamp(turf_move_cost + species.water_movement, HUMAN_LOWEST_SLOWDOWN, 15)
			if(shoes)
				var/obj/item/clothing/shoes/feet = shoes
				if(feet.water_speed)
					turf_move_cost = clamp(turf_move_cost + feet.water_speed, HUMAN_LOWEST_SLOWDOWN, 15)
			. += turf_move_cost
		else if(snow_layers)
			if(species.snow_movement)
				turf_move_cost = clamp(turf_move_cost + species.snow_movement, HUMAN_LOWEST_SLOWDOWN, 15)
			if(shoes)
				var/obj/item/clothing/shoes/feet = shoes
				if(feet.water_speed)
					turf_move_cost = clamp(turf_move_cost + feet.snow_speed, HUMAN_LOWEST_SLOWDOWN, 15)
			. += turf_move_cost
		else
			turf_move_cost = clamp(turf_move_cost, HUMAN_LOWEST_SLOWDOWN, 15)
			. += turf_move_cost

	// Wind makes it easier or harder to move, depending on if you're with or against the wind.
	if((T.is_outdoors()) && (T.z <= SSplanets.z_to_planet.len))
		var/datum/planet/P = SSplanets.z_to_planet[z]
		if(P)
			var/datum/weather_holder/WH = P.weather_holder
			if(WH && WH.wind_speed) // Is there any wind?
				// With the wind.
				if(direct & WH.wind_dir)
					. = max(. - WH.wind_speed, -0.5) // Wind speedup is capped to prevent supersonic speeds from a storm.
				// Against it.
				else if(direct & reverse_dir[WH.wind_dir])
					. += WH.wind_speed

#undef HUMAN_LOWEST_SLOWDOWN

/mob/living/carbon/human/get_jetpack()
	if(back)
		var/obj/item/rig/rig = get_rig()
		if(istype(back, /obj/item/tank/jetpack))
			return back
		else if(istype(rig))
			for(var/obj/item/rig_module/maneuvering_jets/module in rig.installed_modules)
				return module.jets

/mob/living/carbon/human/Process_Spacemove(var/check_drift = 0)
	//Can we act?
	if(restrained())	return 0

	if(..()) //Can move due to other reasons, don't use jetpack fuel
		return 1

	//Do we have a working jetpack?
	var/obj/item/tank/jetpack/thrust = get_jetpack()

	if(thrust)
		if(((!check_drift) || (check_drift && thrust.stabilization_on)) && (!lying) && (thrust.do_thrust(0.01, src)))
			inertia_dir = 0
			return 1

	return 0


/mob/living/carbon/human/Process_Spaceslipping(var/prob_slip = 5)
	//If knocked out we might just hit it and stop.  This makes it possible to get dead bodies and such.

	if(species.flags & NO_SLIP)
		return 0

	var/obj/item/tank/jetpack/thrust = get_jetpack()
	if(thrust?.can_thrust(0.01))
		return 0

	if(stat)
		prob_slip = 0 // Changing this to zero to make it line up with the comment, and also, make more sense.

	//Do we have magboots or such on if so no slip
	if(istype(shoes, /obj/item/clothing/shoes/magboots) && (shoes.item_flags & NOSLIP))
		prob_slip = 0

	//Check hands and mod slip
	if(!l_hand)	prob_slip -= 2
	else if(l_hand.w_class <= 2)	prob_slip -= 1
	if (!r_hand)	prob_slip -= 2
	else if(r_hand.w_class <= 2)	prob_slip -= 1

	prob_slip = round(prob_slip)
	return(prob_slip)

// Handle footstep sounds
/mob/living/carbon/human/handle_footstep(var/turf/T)
	if(!istype(T))
		return
	if(is_incorporeal())
		return
	if(!config.footstep_volume || !T.footstep_sounds || !T.footstep_sounds.len)
		return
	// Future Upgrades - Multi species support
	var/list/footstep_sounds = T.footstep_sounds["human"]
	if(!footstep_sounds)
		return

	var/S = pick(footstep_sounds)
	GLOB.step_taken_shift_roundstat++
	if(!S) return

	// Play every 20 steps while walking, for the sneak
	if(IS_WALKING(src) && step_count++ % 20 != 0)
		return

	// Play every other step while running
	if(IS_RUNNING(src) && step_count++ % 2 != 0)
		return

	var/volume = config.footstep_volume

	// Reduce volume while walking or barefoot
	if(!shoes || IS_WALKING(src))
		volume *= 0.5
	else if(shoes)
		var/obj/item/clothing/shoes/feet = shoes
		if(istype(feet))
			volume *= feet.step_volume_mod

	if(!has_organ(BP_L_FOOT) && !has_organ(BP_R_FOOT))
		return // no feet = no footsteps

	if(buckled || lying || throwing)
		return // people flying, lying down or sitting do not step

	if(!has_gravity(src) && prob(75))
		return // Far less likely to make noise in no gravity

	playsound(T, S, volume, FALSE)
	return

/mob/living/carbon/human/set_dir(var/new_dir)
	. = ..()
	if(. && (species.tail || tail_style))
		update_tail_showing()
