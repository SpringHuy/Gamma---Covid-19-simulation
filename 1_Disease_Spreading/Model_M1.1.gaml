/***
* Name: ModelM11
* Author: huyph
* Description: 
* Tags: Tag1, Tag2, TagN
***/

model ModelM11

/* Insert your model definition here */

global {	
	int nb_Individuals <- 500;
	int nb_Infectious_init <- 1;
	
	float transmission_diameter <- 2.0 #m;
	float infected_prob <- 0.3;
	int incubation_period <- 7 ;
	int infectious_period <- 14;
	
	// Global variables count the number of SEIR Individuals
	int nb_Susceptible_Individuals update: Individuals count each.is_Susceptible;
	int nb_Exposed_Individuals update: Individuals count each.is_Exposed;
	int nb_Infectious_Individuals update: Individuals count each.is_Infectious;
	int nb_Recovered_Individuals update: Individuals count each.is_Recovered;
	
	//for E1.3
	int peak_Infected_cycle;
	int peak_Infected <- nb_Infectious_Individuals;
	
	init {
		create Individuals number: nb_Individuals;
		ask nb_Infectious_init among Individuals {
        	is_Infectious <- true;
        	is_Susceptible <- false;
    	}
	}
	
	reflex peak_infected_check when: peak_Infected < nb_Infectious_Individuals {
		peak_Infected <- nb_Infectious_Individuals;
		peak_Infected_cycle <- cycle;
	}
	
	//(nb_Exposed_Individuals = 0 and nb_Infectious_Individuals = 0 ) or
	reflex end_simulation when:  cycle > 185 {
		write "End of the simulation when there is no E and I or cycle is greater than 500";
		do pause;
	}	
}




species Individuals {
	bool is_Susceptible <- true;
	bool is_Exposed <- false;
	bool is_Infectious <- false;
	bool is_Recovered <- false;
	
	int incubation_counter <- 0;
	int infectious_counter <- 0;
	rgb color;
	
	list<Individuals> neighbours update: Individuals at_distance transmission_diameter;

	reflex become_Recovered when: is_Infectious  {
		//after sometimes become recovered
		if(infectious_counter = infectious_period){
			is_Recovered <- true;
			is_Infectious <- false ;
		}
		else{
			infectious_counter <- infectious_counter + 1 ;
		}
	}	

	reflex become_Infectious when: is_Exposed {
		//become Infectious Individuals
		if(incubation_counter = incubation_period){
			is_Infectious <- true ;
			is_Exposed <- false;
		}
		else{
			incubation_counter <- incubation_counter + 1 ;			
		}
	}
	
	reflex become_Exposed when: is_Susceptible {
		//if in neighbours has an is_Infectious Individuals
		int infectious_neighbour_count <- neighbours count (each.is_Infectious = true);
		if(infectious_neighbour_count > 0){
			is_Exposed <- flip(infected_prob) ? true : false;
		}		
		if(is_Exposed) {is_Susceptible <- false;}
	}
	
	reflex update_color{
		if( is_Susceptible ){ color <- #green; }
		if( is_Exposed ){ color <- #yellow ; }
		if( is_Infectious ){ color <- #red ; }
		if( is_Recovered ){ color <- #grey ; }
	}
	
	reflex move {
		location <- any_location_in(world);
		//do wander;
	}
	aspect circle {
		draw circle(2) color: color border: #black;
	}
}


experiment exp_M1_2_R0 type: gui {
	parameter "Nb Individuals" var: nb_Individuals min: 100 max: 4000 step: 200;
	parameter "Infected probability" var: infected_prob  min: 0.0 max: 1.0 step: 0.1;
	parameter "Incubation period" var: incubation_period min: 5 max: 15 step: 1;
	parameter "Infectious period" var: infectious_period min: 5 max: 50 step: 1;

	output {
		display d {
			species Individuals aspect: circle;
		}
			
		display series_Individuals_SEIR {
			chart "Individuals in SEIR" type: series {
				data "Susceptible Individuals" value: nb_Susceptible_Individuals color: #green;
				data "Exposed Individuals" value: nb_Exposed_Individuals color: #yellow;
				data "Infectious Individuals" value: nb_Infectious_Individuals color: #red;
				data "Recovered Individuals" value: nb_Recovered_Individuals color: #grey;
			}
		}
		
		monitor "Susceptible Individuals" value: nb_Susceptible_Individuals;
		monitor "Exposed Individuals" value: nb_Exposed_Individuals;
		monitor "Infectious Individuals" value: nb_Infectious_Individuals;
		monitor "Recoverd Individuals" value: nb_Recovered_Individuals;
		monitor "Recoverd Individuals" value: nb_Recovered_Individuals;
		monitor "Peak Infected" value: peak_Infected;
		monitor "Peak Infected Cycle" value: peak_Infected_cycle;
		monitor "Step at stop" value: cycle;
	}
}

/// Exploration E1.1. Effect of randomness
experiment E1_1 type: gui {
	parameter "Nb Individuals agents" var: nb_Individuals min: 100 max: 4000 step: 200;
	parameter "Infected probability" var: infected_prob  min: 0.0 max: 1.0 step: 0.1;
	parameter "Incubation period" var: incubation_period min: 5 max: 15 step: 1;
	parameter "Infectious period" var: infectious_period min: 5 max: 50 step: 1;

	init {
		//		create simulation with: [seed::2];		create simulation with: [seed::3];				
		loop i from: 2 to: 11 step:1 {
			create simulation with: [seed::i];
		}
	}

	permanent {
		display series_Infectious_Individuals {
			chart "Individuals in SEIR - E1.1" type: series {
				loop simu over: simulations {										
					data "Infectious Individuals "+int(simu)  value: simu.nb_Infectious_Individuals color: #red;									
				}
			}
		}
	}	
}


/// Exploration E1.2. Impact of the number of individuals
experiment E1_2 type: gui {
	parameter "Nb Individuals agents" var: nb_Individuals min: 100 max: 4000 step: 200;
	parameter "Infected probability" var: infected_prob  min: 0.0 max: 1.0 step: 0.1;
	parameter "Incubation period" var: incubation_period min: 5 max: 15 step: 1;
	parameter "Infectious period" var: infectious_period min: 5 max: 50 step: 1;

	init {
		loop i from: 0 to: 10 step:1{
			int nb_individual_init <- 200 + i*200;
			create simulation with:[nb_Individuals::nb_individual_init, seed::seed];	
		}					
	}

	permanent {
		display series_Infectious_Individuals {
			chart "Individuals in SEIR - E1.2" type: series {
				loop simu over: simulations {										
					data "Infectious Individuals_"+int(simu)+"_"+int(nb_Individuals)  value: simu.nb_Infectious_Individuals color: #red;									
				}
			}
		}
	}	
}

//Exploration E1.3. Impact of the number of individuals.
experiment E1_3 type: batch until: (nb_Exposed_Individuals = 0 and nb_Infectious_Individuals = 0 ) {
	parameter "Nb Individuals agents" var: nb_Individuals init: 200 min: 200 max: 2000 step: 200;
	parameter "NV initial infectious" var: nb_Infectious_init init: 1 min: 1 max: 1;
	
	method exhaustive;
	
	init {
		save ["Number of Individuals", "Max infected Day", "Pandemic duration" ] to: "Data_E1_3.csv" type:"csv" rewrite:true header:false;
	}
	
	reflex data_save_tofile {
		ask simulations {
			save [self.nb_Individuals, self.peak_Infected_cycle, self.cycle] to: "Data_E1_3.csv" type:"csv" rewrite:false;
		}
	}
	
	permanent {
		display cycle_peak {
			chart "#Infected" type: series {
				data "Cycle with Peak Infected" value: mean(simulations collect each.peak_Infected_cycle);
				data "Peak Infected Individuals" value: mean(simulations collect each.peak_Infected);
			}
		}
	}
}