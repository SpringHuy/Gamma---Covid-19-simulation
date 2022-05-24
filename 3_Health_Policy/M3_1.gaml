/*
* Author: huyph
* Description: 
* Tags: Tag1, Tag2, TagN
***/
model M31

/* Insert your model definition here */
global {
	Policy P1;
	//bool total_free;// <- true;

	//for M2_4
	bool global_env_set <- true;
	file city_buildings <- file("../includes/buildings.shp");
	file city_roads <- file("../includes/roads.shp");
	geometry shape <- envelope(city_roads);
	graph road_network;
	int current_hour <- 1 update: cycle mod 24;
	int current_day <- 1 update: int(cycle / 24) + 1;
	float step <- 1 #h;
	int Monday <- 1;
	int Tuesday <- 2;
	int Wednesday <- 3;
	int Thursday <- 4;
	int Friday <- 5;
	int Saturday <- 6;
	int Sunday <- 7;
	int b1_home <- 1;
	int b2_industry <- 2;
	int b3_office <- 3;
	int b4_school <- 4;
	int b5_shop <- 5;
	int b6_supermarket <- 6;
	int b7_coffee <- 7;
	int b8_restaurant <- 8;
	int b9_park <- 9;
	int nb_Individuals <- 500;
	int nb_Infectious_init <- 1;
	int nb_student <- 0;
	int nb_aldult <- 0;
	int nb_elder <- 0;
	int population;

	//float transmission_diameter <- 2.0 #m;
	float infected_prob <- 0.17;
	float quarantine_infected_prob <- 0.0001;
	float asym_infected_prob <- 0.085;

	// Global variables count the number of SEIR Individuals
	int nb_Susceptible_Individuals update: Individuals count each.is_Susceptible;
	int nb_Exposed_Individuals update: Individuals count each.is_Exposed;
	int nb_Infectious_Individuals update: Individuals count each.is_Infectious;
	int nb_Recovered_Individuals update: Individuals count each.is_Recovered;
	int nb_Quarantine_Individuals update: Individuals count each.is_quarantine;

	init {
		create buildings from: city_buildings with: [b_height::int(read("height"))];
		create road from: city_roads;
		loop i from: 0 to: (length(buildings) - 1) {
			if flip(0.025) {
				buildings[i].Build_ID <- i;
				buildings[i].b_type <- b4_school;
				buildings[i].b_color <- #chocolate;
				///
				///  
			} else {
				if flip(0.8) {
					buildings[i].Build_ID <- i;
					buildings[i].b_type <- b1_home;
					buildings[i].b_color <- #cadetblue;
				} else {
					buildings[i].Build_ID <- i;
					buildings[i].b_type <- one_of([b2_industry, b3_office, b5_shop, b6_supermarket, b7_coffee, b8_restaurant, b9_park]);
					buildings[i].b_color <- rgb(int(255 * 2 / buildings[i].b_type), int(255 * 2 / buildings[i].b_type), int(255 * 2 / buildings[i].b_type));
				}

			}

			//write [i, buildings[i].b_type]; //763 house
			//save [i, buildings[i].b_type] to: "Data_buildings_E1_3.csv" type:"csv" rewrite:false;
		}

		int ind <- 0;
		loop i from: 0 to: length(buildings) - 1 {
			if (buildings[i].b_type = b1_home) {
				int nb_childs <- rnd(3);
				if (nb_childs > 0) { //childs
					create Individuals number: nb_childs {
						my_ID <- ind;
						ind <- ind + 1;
						my_home <- i;
						current_building <- my_home;
						location <- buildings[i].location;
						my_school <- one_of(buildings where (each.b_type = b4_school)).Build_ID;
						age <- rnd(22);
						if flip(0.5) {
							gender <- "F";
						} else {
							gender <- "M";
						}
						/*
                           if(age>2){  my_school <- one_of(buildings where(each.b_type = b4_school)); }  //adding later 
                           * */
					}

				}

				nb_student <- nb_student + nb_childs;
				create Individuals number: 1 { //wife
					my_ID <- ind;
					ind <- ind + 1;
					my_home <- i;
					current_building <- my_home;
					location <- buildings[i].location;
					age <- 23 + rnd(22);
					gender <- "F";
					if (flip(0.6)) {
						my_workplace <- one_of(buildings where (each.b_type = b2_industry)).Build_ID;
					} else {
						my_workplace <- one_of(buildings where (each.b_type = b3_office)).Build_ID;
					}

				}

				create Individuals number: 1 { //husband
					my_ID <- ind;
					ind <- ind + 1;
					my_home <- i;
					current_building <- my_home;
					//write [i, "my_home", my_home];
					location <- buildings[i].location;
					age <- 23 + rnd(22);
					gender <- "M";
					if (flip(0.6)) {
						my_workplace <- one_of(buildings where (each.b_type = b2_industry)).Build_ID;
					} else {
						my_workplace <- one_of(buildings where (each.b_type = b3_office)).Build_ID;
					}

				}

				nb_aldult <- nb_aldult + 2;
				if flip(0.5) {
					create Individuals number: 1 {
						my_ID <- ind;
						ind <- ind + 1;
						my_home <- i;
						current_building <- my_home;
						location <- buildings[i].location;
						age <- 56 + rnd(30);
						if flip(0.5) {
							gender <- "F";
						} else {
							gender <- "M";
						}

					}

					nb_elder <- nb_elder + 1;
				}

			} //end initialize population
			population <- nb_elder + nb_aldult + nb_student;
			//
			create LocalAuthority number: 1 {
			}

			create Policy number: 1 {
			}

			P1 <- Policy[0];
			/*
                    if(total_free){
                    	P1.p1_total_free <- true;	
                    } else{
                    	P1.p1_total_free <- false;	
                    } */
		}

		ask nb_Infectious_init among Individuals {
			is_Infectious <- true;
			is_Susceptible <- false;
			day_infectious <- current_hour;
			hour_infectious <- current_day;
		}

		road_network <- as_edge_graph(road);
	} //init  
	reflex end_simulation when: (nb_Exposed_Individuals = 0 and nb_Infectious_Individuals = 0) or cycle > 6000 {
		write "End of the simulation when there is no E and I or cycle is greater than 500";
		do pause;
	}

}

//Should combine POLICY and LOCAL AUTHORITY into one species, policy is a part of authority
species LocalAuthority {

	action by_time {
	//do what at the start? NO - not implement this one
	//this is hard to define amd it is not practical and there is not a persuasive reason to applied the rule at a time
	// an example could be recommend to wear masks at step 0, 3, 5,...
	// and consider when go to public places 
	// for a country maybe, they can decide to close the border if neighbours countries has the pademic, but this is a small town          
	}

	action by_test {
	//for M3_2 - this is most 
	}

	reflex wear_mask when: !P1.p4_wear_mask and nb_Infectious_Individuals > 2 {
	//assume that when an patient is symptomatic, then authorities when know he/she is ill
	//when detect first infected patient -> all to wear mask
	//when wearing mask does not have any effect to individuals agenda 
		P1.p4_wear_mask <- true;
		P1.p1_total_free <- false;
		infected_prob <- infected_prob / 2;
	}

	reflex drop_wear_mask when: P1.p4_wear_mask and nb_Infectious_Individuals < 2 {
		P1.p1_total_free <- true;
		P1.p4_wear_mask <- false;
		infected_prob <- 0.17;
	}

	reflex partial_lockdown when: (nb_Infectious_Individuals / population) > 0.002 and !P1.p5_partial_lockdown and !P1.p6_total_lockdown {
		write "Partial lockdown";
		P1.p5_partial_lockdown <- true;
		P1.lockdown_period <- 14;
		P1.p1_total_free <- false;
		P1.started_partial_day <- current_day;
		P1.spartial_hour <- current_hour + 1;
		//do something like quanrantine infectious at home (as there is no hospital), but set infected_prob to 0 or very low
	}

	reflex drop_partial_lockdown when: P1.p6_total_lockdown or (P1.p5_partial_lockdown and ((current_day - P1.started_partial_day = P1.lockdown_period) and
	P1.spartial_hour = current_hour)) or (nb_Infectious_Individuals / population) < 0.0005 {
		P1.p5_partial_lockdown <- false;
		P1.lockdown_period <- nil;
		P1.started_partial_day <- nil;
		P1.spartial_hour <- nil;
		//do something like quanrantine infectious at home (as there is no hospital), but set infected_prob of him to very low
		//control more about agenda 
	}

	reflex total_lockdown when: (nb_Infectious_Individuals / population) >= 0.01 and !P1.p6_total_lockdown {
		write "Total lockdown";
		P1.p6_total_lockdown <- true;
		P1.lockdown_period <- 30;
		P1.p1_total_free <- false;
		P1.p5_partial_lockdown <- false;
		P1.started_total_day <- current_day;
		P1.stotal_hour <- current_hour + 1;
		//similar action with infectious as in partial lockdown, plus qurantine infectious individuals and other people that patient met
	}

	reflex drop_total_lockdown when: P1.p6_total_lockdown and ((current_day - P1.started_total_day = P1.lockdown_period) and P1.stotal_hour = current_hour) or
	(nb_Infectious_Individuals / population) <= 0.004 {
		P1.p6_total_lockdown <- false;
		P1.lockdown_period <- nil;
		P1.started_total_day <- nil;
		P1.stotal_hour <- nil;
		//similar action with infectious as in partial lockdown, plus qurantine infectious individuals and other people that patient met
	}

	reflex drop_quarantine when: !P1.p5_partial_lockdown and !P1.p6_total_lockdown and nb_Infectious_Individuals = 0 {
		if (current_day - P1.Zero_infectious_day - 1 = P1.self_isolation_period) {
			list<Individuals> quaran_man <- Individuals where (each.is_quarantine = true);
			loop i from: 0 to: (length(quaran_man) - 1) {
				quaran_man[i].is_quarantine <- false;
			}
			list<buildings> quaran_builds <- buildings where(each.b_is_quarantine = true);
			loop i from: 0 to: (length(quaran_builds) - 1) {
				quaran_builds[i].b_is_quarantine <- false;
			}
		}
	}

}

species Policy {
	int lockdown_period;
	int self_isolation_period <- 20; //people which are               
	int started_partial_day;
	int spartial_hour;
	int started_total_day;
	int stotal_hour;
	int Zero_infectious_day;
	bool p1_total_free <- true;

	//affect agenda, no need new varibale
	bool p2_close_school <- false;

	//affect agenda, no need new varibale
	bool p3_close_entertain <- false;

	// wearing mask the probability to be infected reduced to 50%
	//activated when detect first patient by test (all to wears when out of home)
	bool p4_wear_mask <- false;

	//close school, entertain -> elder and kids at home
	// if there is kid < 10 years old, and auldult has to stay at home       
	// other alfult still go to work
	// allow auldult to go to super market to buy food, essential thing only - the time should be random 8am-20pm during weekend and 18-20 week days
	// activated when there is a series of twos tests that detected patients in two days or detect two patien a day
	// close lock down after two weeks             
	bool p5_partial_lockdown <- false;

	//close school, entertain -> elder and kids at home
	// if there is kid < 14 years old, and auldult has to stay at home to take care of them       
	// other alfult still go to work
	// allow auldult to go to super market to buy food, essential thing only - the time should be random 8am-20pm during weekend and 18-20 week days
	// activated when there is a series of twos tests that detected patients in two days or detect two patien a day
	// drop lock down after 1 month
	bool p6_total_lockdown <- false;

	//idea is when detect an infectious, quarantine the people that was in contact with him. Need to keep list of those contacted one.
	bool p7_tracing_infeced_source <- false;

	reflex zero_infectious when: nb_Infectious_Individuals = 0 {
		Zero_infectious_day <- current_day;
	}

}

species Individuals skills: [moving] {
	int my_ID; //Identity of each person
	bool is_quarantine <- false;
	bool is_Asymptomatic; //if this is true then this person can inform Authorities about there health status
	bool is_Susceptible <- true;
	bool is_Exposed <- false;
	bool is_Infectious <- false;
	bool is_Recovered <- false;
	int day_exposed;
	int hour_exposed;
	int day_infectious;
	int hour_infectious;
	int incubation_period <- 3 + rnd(7);
	int infectious_period <- 10 + rnd(20);
	int day_s_quaran;
	int hour_s_quaran;
	
	int age;
	string gender;
	int current_building;
	int temp_building;
	int my_home;
	int my_workplace;
	int my_school;
	rgb color;
	float speed <- 50 #km / #h; ///make sure come to target within a cycle         

		/*AGENDA
             * Week days:
             * - adult: 9-17 100% at work, 18-21: 50% at home, 50% shop, coffe, park, restaurant, 22-8 100% at home
             * - elder: 9-11 100% at hospital, 12-16 100% at home, 17-19 100% at park, coffe, shop, restaurant, 20-8 100% at home
             * - student: 9-16 100% at school, 17-18 100% at park, 19-8 100% at home
             * Weekend:
             * - same agenda: 9-12 shop/supermarket, 13-16 home, 17-21 park/shop/coffee/restaurant 
              */
///How the quarantine will affect agenda - 
	/*
         * When partial lockdown: 
         * - Going out free, just close the buildings that infected
         * - If in the household has an infectious, people in that house are quarantine
         * 
         * When Total lockdown:
         * student: Stay at home
         * elder: stay at home
         * aldult: 10% are allowed to go to work
         */
	reflex adult_agenda when: age > 22 and age < 56 and ((current_day mod 7) != 6) and ((current_day mod 7) != 0) and !is_quarantine {
		if (P1.p1_total_free or P1.p5_partial_lockdown) {
			if (current_hour = 9) {
			//to work
				do go_work;
			} else if (current_hour = 18) {
			//50% go home 50% go out
				if flip(0.5) {
					do go_home;
				} else {
					do go_outting;
				}

			} else if (current_hour = 22 and current_building != my_home) {
			// the rest go home
				do go_home;
			} } else if (P1.p6_total_lockdown) {
			if flip(0.15) {
				if (current_hour = 9) {
				//to work
					if (!buildings[my_workplace].b_is_quarantine) {
						do go_work;
					}

				} else if (current_hour = 18) {
					do go_home;
				}

			}

		} }

	reflex student_agenda when: age < 23 and ((current_day mod 7) != 6) and ((current_day mod 7) != 0) and !is_quarantine {
		if (P1.p1_total_free or P1.p5_partial_lockdown) {
			if (current_hour = 9) {
			//to school
				do go_to_school;
			} else if (current_hour = 17) {
			// go to park
				do visit_park;
			} else if (current_hour = 20) {
			// go home
				do go_home;
			} } else if (P1.p6_total_lockdown) {
			if (current_building != my_home) {
				do go_home;
			}

		} }

	reflex elder_agenda when: age > 56 and ((current_day mod 7) != 6) and ((current_day mod 7) != 0) and !is_quarantine {
		if (P1.p1_total_free) {
			if (current_hour = 9) {
			//go coffee
				do go_coffee;
			} else if (current_hour = 12) {
			// go home
				do go_home;
			} else if (current_hour = 17) {
			// go out
				do go_outting;
			} else if (current_hour = 20) {
			//go home
				do go_home;
			} } else if (P1.p5_partial_lockdown) {
		} else if (P1.p6_total_lockdown) {
			if (current_building != my_home) {
				do go_home;
			}

		} }

	reflex weekend_agenda when: ((current_day mod 7) = 6) or ((current_day mod 7) = 0) and !is_quarantine {
		if (P1.p1_total_free or P1.p5_partial_lockdown) {
			if (current_hour = 9) {
			//to shop / super
				do go_shopping;
			} else if (current_hour = 12) {
			// go home
				do go_home;
			} else if (current_hour = 17) {
			// go out
				do go_outting;
			} else if (current_hour = 22) {
			//go home
				do go_home;
			} } else if (P1.p6_total_lockdown) {
			if (current_building != my_home) {
				do go_home;
			}

		} }

	action go_work {
		point target <- buildings[my_workplace].location;
		do goto target: target; // on: road_network;
		if (location = target) {
			current_building <- my_workplace;
			target <- nil;
		}
		//write [location, my_home, my_workplace, my_school, is_Susceptible, is_Exposed, is_Infectious, is_Recovered ];    
	}

	action go_home {
		point target <- buildings[my_home].location;
		do goto target: target; // on: road_network;
		if (location = target) {
			current_building <- my_home;
			target <- nil;
		}

	}

	action visit_park {
		current_building <- one_of(buildings where (each.b_type = b9_park)).Build_ID;
		if (buildings[current_building].b_is_quarantine) {
			do go_home;
		} else {
			point target <- buildings[current_building].location;
			do goto target: target on: road_network;
			if (location = target) {
				target <- nil;
			}

		}

	}

	action go_coffee {
		current_building <- one_of(buildings where (each.b_type = b7_coffee)).Build_ID;
		do check_n_go;
	}

	action go_to_school {
		current_building <- one_of(buildings where (each.b_type = b4_school)).Build_ID;
		do check_n_go;
	}

	action go_shopping { //weekend morning
		current_building <- one_of(buildings where (each.b_type = b6_supermarket or each.b_type = b5_shop)).Build_ID;
		do check_n_go;
	}

	action go_outting { //weekend evening
		current_building <- one_of(buildings where (each.b_type = b7_coffee or each.b_type = b5_shop or each.b_type = b8_restaurant or each.b_type = b9_park)).Build_ID;
		do check_n_go;
	}

	action check_n_go {
		if (buildings[current_building].b_is_quarantine) {
			do go_home;
		} else {
			point target <- buildings[current_building].location;
			do goto target: target on: road_network;
			if (location = target) {
				target <- nil;
			}

		}

	}

	reflex become_Recovered when: is_Infectious and hour_infectious = current_hour and ((current_day - day_infectious) = infectious_period) {
		is_Recovered <- true;
		is_Infectious <- false;
		color <- #grey;
		day_infectious <- nil;
		hour_infectious <- nil;
	}

	reflex become_Infectious when: is_Exposed and hour_exposed = current_hour and (current_day - day_exposed) = incubation_period {
		is_Exposed <- false;
		is_Infectious <- true;
		color <- #red;
		day_infectious <- current_day;
		hour_infectious <- current_hour;
		day_exposed <- nil;
		hour_exposed <- nil;
		/* 
              *               * //Not practical, let him infect some other before quarantine 
             if (P1.p5_partial_lockdown or P1.p6_total_lockdown) {
             	is_quarantine <- true;
             }
             * 
             */
	}

	reflex expose_other when: is_Infectious { //expose to the building as well
		list<Individuals> neighbours <- Individuals where (each.current_building = self.current_building and each.is_Susceptible = true);
		if ((length(neighbours) > 0)) {
			if (P1.p1_total_free) {
					loop person from: 0 to: (length(neighbours) - 1) {
						if (flip(infected_prob)) {
							neighbours[person].is_Exposed <- true;
							neighbours[person].color <- #yellow;
							neighbours[person].day_exposed <- current_day;
							neighbours[person].hour_exposed <- current_hour;
							neighbours[person].is_Susceptible <- false;
						}
					}
			} else if(P1.p5_partial_lockdown or P1.p6_total_lockdown ) and !is_quarantine{
					loop person from: 0 to: (length(neighbours) - 1) {
						if (flip(infected_prob)) {
							neighbours[person].is_Exposed <- true;
							neighbours[person].color <- #yellow;
							neighbours[person].day_exposed <- current_day;
							neighbours[person].hour_exposed <- current_hour;
							neighbours[person].is_Susceptible <- false;
							neighbours[person].day_s_quaran <- current_day;
							neighbours[person].hour_s_quaran <- current_hour;							
						}
					}
			} else if (is_quarantine) { 
				loop person from: 0 to: (length(neighbours) - 1) {
					neighbours[person].is_quarantine <- true;
					//person::go_home;
					if (flip(quarantine_infected_prob)) {
						neighbours[person].is_Exposed <- true;
						neighbours[person].color <- #yellow;
						neighbours[person].day_exposed <- current_day;
						neighbours[person].hour_exposed <- current_hour;
						neighbours[person].is_Susceptible <- false;
						neighbours[person].day_s_quaran <- current_day;
						neighbours[person].hour_s_quaran <- current_hour;	
					}

				}

			}

		}

		//write [self, cycle, indx1, length(neighbours), self.current_building, buildings[current_building].b_type, buildings[my_workplace].b_type, buildings[my_school].b_type,  current_hour, current_day];
		neighbours <- nil;
		if (global_env_set) { //when compare two models
			buildings[current_building].b_infectious <- true;
			//if the buildings is infected, then no one is allowed to get in (change in agenda)
			buildings[current_building].b_hour_infected <- current_hour;
			buildings[current_building].b_day_infected <- current_day;
		} else if (P1.p5_partial_lockdown or P1.p6_total_lockdown) and global_env_set {			
				self.is_quarantine <- true;
				buildings[current_building].b_is_quarantine <- true;
				buildings[current_building].b_quanran_day <- current_day;
				buildings[current_building].b_quanran_hour <- current_hour;
		}
	}

/*
	reflex expose_other when: is_Infectious { //expose to the building as well
		list<Individuals> neighbours <- Individuals where (each.current_building = self.current_building and each.is_Susceptible = true);
		if ((length(neighbours) > 0)) {
			if (P1.p1_total_free) {
				loop person from: 0 to: (length(neighbours) - 1) {
					if (flip(infected_prob)) {
						neighbours[person].is_Exposed <- true;
						neighbours[person].color <- #yellow;
						neighbours[person].day_exposed <- current_day;
						neighbours[person].hour_exposed <- current_hour;
						neighbours[person].is_Susceptible <- false;
					}

				}

			} else if (is_quarantine) { // (P1.p5_partial_lockdown or P1.p6_total_lockdown) {
				loop person from: 0 to: (length(neighbours) - 1) {
					neighbours[person].is_quarantine <- true;
					//person::go_home;
					if (flip(quarantine_infected_prob)) {
						neighbours[person].is_Exposed <- true;
						neighbours[person].color <- #yellow;
						neighbours[person].day_exposed <- current_day;
						neighbours[person].hour_exposed <- current_hour;
						neighbours[person].is_Susceptible <- false;
					}

				}

			}

		}

		//write [self, cycle, indx1, length(neighbours), self.current_building, buildings[current_building].b_type, buildings[my_workplace].b_type, buildings[my_school].b_type,  current_hour, current_day];
		neighbours <- nil;
		if (P1.p1_total_free and global_env_set) { //when compare two models
			buildings[current_building].b_infectious <- true;
			//if the buildings is infected, then no one is allowed to get in (change in agenda)
			buildings[current_building].b_hour_infected <- current_hour;
			buildings[current_building].b_day_infected <- current_day;
		} else if (P1.p5_partial_lockdown or P1.p6_total_lockdown) {
			if (global_env_set) { //when compare two models
				buildings[current_building].b_infectious <- true;
				//if the buildings is infected, then no one is allowed to get in (change in agenda)
				buildings[current_building].b_hour_infected <- current_hour;
				buildings[current_building].b_day_infected <- current_day;
				buildings[current_building].b_is_quarantine <- true;
				if (!is_Asymptomatic) {
					self.is_quarantine <- true;
					buildings[current_building].b_is_quarantine <- true;
					buildings[current_building].b_quanran_day <- current_day;
					buildings[current_building].b_quanran_hour <- current_hour;
				}
			}			
		}

	}

	reflex env_expose when: buildings[current_building].b_infectious and global_env_set and !buildings[current_building].b_is_quarantine {
		int b_nb_hours <- 1 + (current_day - buildings[current_building].b_day_infected) * 24 + current_hour - buildings[current_building].b_hour_infected;
		if (P1.p1_total_free) {
		//calculate nbof hours the house became infected             
			if b_nb_hours < 17 and flip(infected_prob / b_nb_hours) {
				is_Exposed <- true;
				color <- #yellow;
				day_exposed <- current_day;
				hour_exposed <- current_hour;
				is_Susceptible <- false;
			}

		} else if (buildings[current_building].b_is_quarantine) {
			if (b_nb_hours < 17 and flip(quarantine_infected_prob)) {
				is_Exposed <- true;
				color <- #yellow;
				day_exposed <- current_day;
				hour_exposed <- current_hour;
				is_Susceptible <- false;
			}

		} else if (b_nb_hours > 16) {
			buildings[current_building].b_infectious <- false;
			buildings[current_building].b_hour_infected <- nil;
			buildings[current_building].b_day_infected <- nil;
		} 
	}

* 
*/
		//after become infecious to expose other and the building, the infectious is detected by authorities and has to go home for qurantine 
	reflex go_home_quarantine when: is_quarantine { //infectious will go home after executing previous reflex, other in close contact will be quarantined also
		do go_home;
	}

	reflex quarantine_infectious_family when: current_hour = 1 and is_Infectious and (P1.p5_partial_lockdown or P1.p6_total_lockdown) {
		list<Individuals> family_members <- Individuals where (each.my_home = self.my_home);
		loop i from: 0 to: length(family_members) - 1 {
			family_members[i].is_quarantine <- true;
		}

	}

	reflex Indi_drop_quaran when: is_quarantine and !is_Infectious and hour_s_quaran=current_hour and day_s_quaran + P1.self_isolation_period = current_day {
		is_quarantine <- false;
		day_s_quaran <- nil;
		hour_s_quaran <- nil;
	}
	
	aspect circle {
		draw circle(5) color: color;
	}

	aspect threeD {
		draw pyramid(5) color: color;
		draw sphere(2) at: location + {0, 0, 5} color: color;
	} }

species buildings {
	int Build_ID; //Identity of each building
	int b_hour_infected;
	int b_day_infected;
	bool b_infectious <- false;
	bool b_is_quarantine <- false;
	int b_height;
	int b_type;
	rgb b_color;
	int b_quanran_day;
	int b_quanran_hour;

	/*
     * The virus can live in the environment for 16 hours only
     * initial infected probability from env to human is mostly equal to the tramiss 0.17 and decrease by hours increase = 0.17 / nb_hours
     */
	reflex infectious_status when: global_env_set and b_infectious and ((1 + (current_day - b_day_infected) * 24 + current_hour - b_hour_infected) = 17) {
		b_infectious <- false;
		b_hour_infected <- nil;
		b_day_infected <- nil;
	}
	
	reflex building_drop_quarantine when: b_is_quarantine and current_hour=b_quanran_hour and current_day - 7 =b_quanran_hour {
		b_is_quarantine <- false;
	}

	aspect geom {
		draw shape color: b_color depth: b_height;
	}

}

species road {

	aspect geom {
		draw shape * 3 color: #white;
	}

}

experiment E3_1_test type: gui {
	parameter "Nb Initial Infectious Individuals" var: nb_Infectious_init min: 1 max: 100 step: 1;
	parameter "Infected probability" var: infected_prob min: 0.0 max: 1.0 step: 0.1;

	init {
		create simulation with: [global_env_set::true]; //, total_free::true];
		create simulation with: [global_env_set::true]; //, total_free::false];
	}

	permanent {
		display series_Infectious_Individuals {
			chart "Individuals in SEIR - E2.4" type: series {
				loop simu over: simulations {
					if (int(simu) != 6) {
						data "Infectious Individuals " + int(simu) value: simu.nb_Infectious_Individuals color: #red;
						data "Exposed Individuals " + int(simu) value: simu.nb_Exposed_Individuals color: #yellow;
					}

				}

			}

		}

	}

}

experiment E3_1 type: gui {
	parameter "Nb Initial Infectious Individuals" var: nb_Infectious_init min: 1 max: 100 step: 1;
	parameter "Infected probability" var: infected_prob min: 0.0 max: 1.0 step: 0.1;
	output {
		display map type: opengl {
			image "../includes/earth_turtle.jpg" refresh: false;
			species buildings aspect: geom refresh: false;
			species road aspect: geom;
			species Individuals aspect: threeD;
			graphics g {
				draw "" + current_date font: font("Arial", 18, #bold) at: {50, 100} color: #black;
			}

		}

		display series_Infectious_Individuals {
			chart "Individuals in SEIR - E3.1" type: series {
				data "Susceptible Individuals" value: nb_Susceptible_Individuals color: #green;
				data "Exposed Individuals" value: nb_Exposed_Individuals color: #yellow;
				data "Infectious Individuals" value: nb_Infectious_Individuals color: #red;
				data "Recovered Individuals" value: nb_Recovered_Individuals color: #grey;
				data "Quarantine Individuals" value: nb_Quarantine_Individuals color: #violet;
			}

		}

		monitor "Susceptible Individuals" value: nb_Susceptible_Individuals;
		monitor "Exposed Individuals" value: nb_Exposed_Individuals;
		monitor "Infectious Individuals" value: nb_Infectious_Individuals;
		monitor "Recovered Individuals" value: nb_Recovered_Individuals;
		monitor "Quarantine Individuals" value: nb_Quarantine_Individuals;
		monitor "Population" value: population;
		monitor "Curent Hour" value: current_hour;
		monitor "Curent day" value: current_day;
		monitor "Wearing masks" value: P1.p4_wear_mask;
		monitor "partial lockdown" value: P1.p5_partial_lockdown;
		monitor "Total lockdown" value: P1.p6_total_lockdown;
		monitor "Cycle" value: cycle;
	}

}
