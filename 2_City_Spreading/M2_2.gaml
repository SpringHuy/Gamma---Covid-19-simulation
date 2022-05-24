/***
* Name: M22
* Author: huyph
* Description: 
* Tags: Tag1, Tag2, TagN
***/

model M22

/* Insert your model definition here */

global {
       file city_buildings <- file("../includes/buildings.shp");
       file city_roads <- file("../includes/roads.shp");
       geometry shape <- envelope(city_roads);     
       graph road_network;      
       
       int current_hour <- 0 update: cycle mod 24 ;  
       int current_day <- 1 update: int(cycle/24) + 1 ;  
       int leave_time <- 9;
       int back_time <- 17;
       float step <- 1 #h;   
       
       int ct1 <- 0; 
       int ct2 <- 0;
       
       int nb_building_type <- 9;
       int b1_home <- 1;	       int b2_industry <- 2;
       int b3_office <- 3;	       int b4_school <- 4;
       int b5_shop <- 5;	       int b6_supermarket <- 6;
       int b7_coffee <- 7;	       int b8_restaurant <- 8;
       int b9_park <- 9;
       //list<int> building_types <- [b1_home, b2_industry, b3_office, b4_school, b5_shop, b6_supermarket, b7_coffee, b8_restaurant, b9_park];
       
       int nb_Individuals <- 500;
       int nb_Infectious_init <- 1;
       
       //float transmission_diameter <- 2.0 #m;
       float infected_prob <- 0.17;

       // Global variables count the number of SEIR Individuals
       int nb_Susceptible_Individuals update: Individuals count each.is_Susceptible;
       int nb_Exposed_Individuals update: Individuals count each.is_Exposed;
       int nb_Infectious_Individuals update: Individuals count each.is_Infectious;
       int nb_Recovered_Individuals update: Individuals count each.is_Recovered;
       
       init {
             create buildings from: city_buildings with:[b_height::int(read("height")) ];
             create road from: city_roads;
             
             loop i from: 0 to: (length(buildings) - 1){
                    if flip(0.025){
                           buildings[i].b_type <- b4_school;
                           buildings[i].b_color <- #chocolate;    
                    }
                    else{
                           if flip(0.8){
                                 buildings[i].b_type <- b1_home;
                                 buildings[i].b_color <- #cadetblue;
                           }
                           else{
                                 buildings[i].b_type <- one_of([b2_industry, b3_office, b5_shop, b6_supermarket, b7_coffee, b8_restaurant, b9_park]);        
                                 buildings[i].b_color <- rgb(int(255*2/buildings[i].b_type), int(255*2/buildings[i].b_type), int(255*2/buildings[i].b_type));       
                           }
                    }
             }
             
             create Individuals number: nb_Individuals {
             	my_home <- one_of(buildings where(each.b_type = b1_home));             	
             	if flip(0.75){
             		if flip(0.6){
             			my_workplace <- one_of(buildings where(each.b_type = b2_industry));
             		}
             		else{
             			my_workplace <- one_of(buildings where(each.b_type = b3_office));
             		}
             	}    
             	else{
             		my_school <- one_of(buildings where(each.b_type = b4_school));
             	}        	                    
                location <- my_home.location;               
      		}
      		ask nb_Infectious_init among Individuals {
		        is_Infectious <- true;
		        is_Susceptible <- false;
		        day_infectious <- current_hour;
       		    hour_infectious <- current_day;
	        }     		
     		road_network <- as_edge_graph(road);
       }
		       
       //reflex check_time{    write [current_day, current_hour];      }    
       
             //(nb_Exposed_Individuals = 0 and nb_Infectious_Individuals = 0 ) or
       reflex end_simulation when: cycle > 2500 { //(nb_Exposed_Individuals = 0 and nb_Infectious_Individuals = 0 ) or 
             write "End of the simulation when there is no E and I or cycle is greater than 500";
             do pause;
       }      
}

species Individuals skills:[moving] {
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
              
       rgb color;            
       buildings my_home <- nil;
       buildings my_workplace <- nil;
       buildings my_school <- nil;       
       float speed <- 30 #km/#h; ///make sure come to target within a cycle    

       reflex go_out when: current_hour = leave_time  {
       		point target <- (my_workplace != nil) ? my_workplace.location : my_school.location ; 
             do goto target: target;// on: road_network;
             if (location = target) { target <- nil; }  
             //write [location, my_home, my_workplace, my_school, is_Susceptible, is_Exposed, is_Infectious, is_Recovered ];    
       }
       
       reflex go_back_home when: current_hour = back_time  {
       		point target <- my_home.location ; 
            do goto target: target;// on: road_network;
            if (location = target) { target <- nil; }      
            //write [location, my_home, my_workplace, my_school, is_Susceptible, is_Exposed, is_Infectious, is_Recovered ];
            
       }
       
       reflex become_Recovered when: is_Infectious and hour_infectious = current_hour and ((current_day - day_infectious) = infectious_period) {
             //after sometimes become recovered             
             is_Recovered <- true;
             is_Infectious <- false ;
             color <- #grey;
             ct2 <- ct2 + 1;
       }      		
		// and hour_exposed = current_hour
       reflex become_Infectious when: is_Exposed and hour_exposed = current_hour and (current_day - day_exposed) = incubation_period {  
       		//write [self,hour_exposed, current_hour, (current_day - day_exposed), incubation_period]   ;       
       			 is_Exposed <- false;
	             is_Infectious <- true ;             
	             color <- #red;
	             day_infectious <- current_day;
	       		 hour_infectious <- current_hour;	             	       	
       } 
              
	reflex expose_other when: is_Infectious {
		//if in neighbours has an is_Infectious Individuals			 
		list<Individuals> neighbours <- Individuals where(each.is_Susceptible = true and each.location = self.location and (each.my_home=self.my_home or each.my_workplace = self.my_workplace or each.my_school = self.my_school) );		
		loop person over: neighbours {		
			if flip(infected_prob){
				person.is_Exposed <- true;				
				person.color <- #yellow;
				person.day_exposed <- current_day;
				person.hour_exposed <- current_hour;
				person.is_Susceptible <- false;	
				ct1 <- ct1 + 1;
			}			 	
		}				
	}                    
       
       aspect circle {
             draw circle(5) color: color;
       }
       
       aspect threeD{
             draw pyramid(5) color: color;
             draw sphere(2) at: location + {0,0,5} color: color;
       }
}

species buildings {
	bool b_infectious <- false;	
	int b_height;
	int b_type;
    rgb b_color <- #grey;
    aspect geom {   draw shape color: b_color depth: b_height; } 
}

species road {
       aspect geom { draw shape*2 color: #white;     }
}

experiment M2_2_Population type: gui {
       parameter "Nb Individuals" var: nb_Individuals min: 1 max: 4000 step: 200;
       parameter "Nb Initial Infectious Individuals" var: nb_Infectious_init min: 1 max: 100 step: 1;
       parameter "Infected probability" var: infected_prob  min: 0.0 max: 1.0 step: 0.1;
       
       output {
             display map type: opengl {
                    image "../includes/earth_turtle.jpg" refresh: false;
                    species buildings aspect: geom refresh: false;
                    species road aspect: geom ;
                    species Individuals aspect: threeD;
                                 
                    graphics g {
                           draw "" + current_date font: font("Arial", 18, #bold) at: {50,100} color: #black;
                    }                   
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
             monitor "Recovered Individuals" value: nb_Recovered_Individuals;
             monitor "Counter 1" value: ct1;  
             monitor "Counter 2" value: ct2;   
             monitor "Curent Hour" value: current_hour; 
             monitor "Curent day" value: current_day;
             monitor "Cycle" value: cycle;   
       }
}

experiment E2_1 type: gui {
       parameter "Nb Individuals" var: nb_Individuals min: 1 max: 4000 step: 200;
       parameter "Nb Initial Infectious Individuals" var: nb_Infectious_init min: 1 max: 100 step: 1;
       parameter "Infected probability" var: infected_prob  min: 0.0 max: 1.0 step: 0.1;
       
		init {
			//		create simulation with: [seed::2];		create simulation with: [seed::3];				
			loop i from: 2 to: 11 step:1 {
				create simulation with: [seed::i];
			}
		}
		permanent {
			display series_Infectious_Individuals {
				chart "Individuals in SEIR - E2.1" type: series {					
					loop simu over: simulations {	
						//rgb colory <- rgb(int(255/int(simu)), int(255/int(simu)), int(255/int(simu)));														
						data "Infectious Individuals "+int(simu) value: simu.nb_Infectious_Individuals color: #red; // colory;								
					}
				}
			}
		}
}
