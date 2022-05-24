/***
* Name: ModelM11
* Author: huyph
* Description: 
* Tags: Tag1, Tag2, TagN
***/

model ModelM12_R0

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
	
	
	int minR0 <- 0 update: Individuals where(each.is_Infectious) min_of(each.R0);
	int maxR0 <- 0 update: Individuals where(each.is_Infectious) max_of(each.R0);
	float avgR0 <- 0.0 update: Individuals where(each.is_Infectious) sum_of(each.R0) / max(1,nb_Infectious_Individuals) ;
	
	init {
		create Individuals number: nb_Individuals;
		ask nb_Infectious_init among Individuals {
        	is_Infectious <- true;
        	is_Susceptible <- false;
    	}
	}
	
	/*
	int minR0_temp <- 0;
	int maxR0_temp <- 0;
	int avgR0_temp <- 0;
	*/	
	/*
	reflex R0_tracking when: nb_Infectious_Individuals != 0 {
		minR0 <- minR0_temp;
		minR0_temp <- 0;
		maxR0 <- maxR0_temp;
		maxR0_temp <- 0;
		avgR0 <- avgR0_temp / nb_Infectious_Individuals ;
		avgR0_temp <- 0;
	}
	 */
	
	reflex end_simulation when: nb_Infectious_Individuals = 0 or cycle > 500 {
		write "End of the simulation when there is no I or cycle is greater than 500";
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
	
	int R0 <- 0;	
	
	//int neighbour_exposed_before_cycle;
	//int neighbour_exposed_after_cycle;
		
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
	
	reflex expose_other when: is_Infectious {
		//if in neighbours has an is_Infectious Individuals
		list<Individuals> neighbours <- Individuals at_distance transmission_diameter where (each.is_Susceptible = true);
		
		loop person over: neighbours {
			if(flip(infected_prob)){
				R0 <- R0 + 1;
				person.is_Exposed <- true;
				person.is_Susceptible <- false;
				person.color <- #yellow;
			}
		}		
		
	}
	
	/* 
	 * NOT work as only one this agent executing this reflex 
	reflex count_neighbour_exposed_before_cycle {
		neighbour_exposed_before_cycle <- neighbours count (each.is_Exposed = true);	
	}	
	 
	 
	reflex count_neighbour_exposed_after_cycle_R0 when: is_Infectious = true {
		neighbour_exposed_after_cycle <- neighbours count (each.is_Exposed = true);
		R0 <- R0 + neighbour_exposed_after_cycle - neighbour_exposed_before_cycle;
		if(minR0_temp > R0){
			minR0_temp <- R0;
		}	
		if(maxR0_temp < R0){
			maxR0_temp <- R0;
		}
		avgR0_temp <- avgR0_temp + R0;		
	}
	* 	*/
	
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
	parameter "Nb Individuals" var: nb_Individuals min: 200 max: 2000 step: 200;
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
		
		display R0_series {
			chart "R0 series" type: series {
				
				data "Min R0" value: minR0 color: #green;
				data "Max R0" value: maxR0 color: #red;
				data "Average R0" value: avgR0 color: #yellow;
			}
		}
		
		monitor "Susceptible Individuals" value: nb_Susceptible_Individuals;
		monitor "Exposed Individuals" value: nb_Exposed_Individuals;
		monitor "Infectious Individuals" value: nb_Infectious_Individuals;
		monitor "Recoverd Individuals" value: nb_Recovered_Individuals;
		monitor "Recoverd Individuals" value: nb_Recovered_Individuals;

		monitor "minR0" value:minR0;
		monitor "maxR0" value:maxR0;
		monitor "Step at stop" value: cycle;
	}
}

