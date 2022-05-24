/***
* Name: M23
* Author: huyph
* Description: 
* Tags: Tag1, Tag2, TagN
***/

model M23

global {

       bool global_env_set <- false;

       file city_buildings <- file("../includes/buildings.shp");
       file city_roads <- file("../includes/roads.shp");
       geometry shape <- envelope(city_roads);
       graph road_network;
       int current_hour <- 1 update: cycle mod 24;
       int current_day <- 1 update: int(cycle / 24) + 1;
       float step <- 1 #s;
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
       int nb_building_type <- 9;
       int nb_Individuals <- 500;
       int nb_Infectious_init <- 1;
       int nb_student <- 0;
       int nb_aldult <- 0;
       int nb_elder <- 0;

       //float transmission_diameter <- 2.0 #m;
       float infected_prob <- 0.17;

       // Global variables count the number of SEIR Individuals
       int nb_Susceptible_Individuals update: Individuals count each.is_Susceptible;
       int nb_Exposed_Individuals update: Individuals count each.is_Exposed;
       int nb_Infectious_Individuals update: Individuals count each.is_Infectious;
       int nb_Recovered_Individuals update: Individuals count each.is_Recovered;

       init {
             create buildings from: city_buildings with: [b_height::int(read("height"))];
             create road from: city_roads;
             loop i from: 0 to: (length(buildings) - 1) {
                    if flip(0.025) {
                           buildings[i].Build_ID <- i;
                           buildings[i].b_type <- b4_school;
                           buildings[i].b_color <- #chocolate;
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
                                        //write [i, "my_home", my_home];
                                        location <- buildings[i].location;
                                        my_school <- one_of(buildings where (each.b_type = b4_school)).Build_ID;
                                        //write ["my school", my_school];
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
                                 write [i, "my_home", my_home];
                                 location <- buildings[i].location;
                                 age <- 23 + rnd(22);
                                 gender <- "F";
                                 my_workplace <- one_of(buildings where (each.b_type = b2_industry)).Build_ID;                                
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
                                 my_workplace <- one_of(buildings where (each.b_type = b3_office)).Build_ID;
                           }

                           nb_aldult <- nb_aldult + 2;
                           if flip(0.5) {
                                 create Individuals number: 1 {
                                        my_ID <- ind;
                                        ind <- ind + 1;
                                        my_home <- i;
                                        current_building <- my_home;
                                        location <- buildings[i].location;
                                        //write [i, "my_home", my_home];
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
                    //
             }

             ask nb_Infectious_init among Individuals {
                    is_Infectious <- true;
                    is_Susceptible <- false;
                    day_infectious <- current_hour;
                    hour_infectious <- current_day;
             }

             road_network <- as_edge_graph(road);
       } //init  
       reflex end_simulation when: (nb_Exposed_Individuals = 0 and nb_Infectious_Individuals = 0) or cycle > 2000 {
             write "End of the simulation when there is no E and I or cycle is greater than 500";
             do pause;
       }

}

species Individuals skills: [moving] {
       
       int my_ID;   //Identity of each person
       
       bool is_asymptomatic;
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
       int age;
       string gender;
       int current_building;
       int temp_building;
       int my_home;
       int my_workplace;
       int my_school;
       rgb color;
       float speed <- 30 #km / #h; ///make sure come to target within a cycle         

       /*AGENDA
             * Week days:
             * - adult: 9-17 100% at work, 18-21: 50% at home, 50% shop, coffe, park, restaurant, 22-8 100% at home
             * - elder: 9-11 100% at hospital, 12-16 100% at home, 17-19 100% at park, coffe, shop, restaurant, 20-8 100% at home
             * - student: 9-16 100% at school, 17-18 100% at park, 19-8 100% at home
             * Weekend:
             * - same agenda: 9-12 shop/supermarket, 13-16 home, 17-21 park/shop/coffee/restaurant 
              */
       reflex adult_agenda when: age > 22 and age < 56 and ((current_day mod 7) != 6) and ((current_day mod 7) != 0) {
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
             } }

       reflex student_agenda when: age < 23 and ((current_day mod 7) != 6) and ((current_day mod 7) != 0) {
             if (current_hour = 9) {
             //to school
                    do go_to_school;
             } else if (current_hour = 17) {
             // go to park
                    do visit_park;
             } else if (current_hour = 20) {
             // go home
                    do go_home;
             } }

       reflex elder_agenda when: age > 56 and ((current_day mod 7) != 6) and ((current_day mod 7) != 0) {
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
             } }

       reflex weekend_agenda when: ((current_day mod 7) = 6) or ((current_day mod 7) = 0) {
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
             } }

       action go_work {
             point target <- buildings[my_workplace].location;
             do goto target: target;// on: road_network;
             if (location = target) {
                    current_building <- my_workplace;
                    target <- nil;
             }
             //write [location, my_home, my_workplace, my_school, is_Susceptible, is_Exposed, is_Infectious, is_Recovered ];    
       }

       action go_home {
             point target <- buildings[my_home].location;
             do goto target: target;// on: road_network;
             if (location = target) {
                    current_building <- my_home;
                    target <- nil;
             }

       }

       action visit_park {
             current_building <- one_of(buildings where (each.b_type = b9_park)).Build_ID;
             point target <- buildings[current_building].location;
             do goto target: target on: road_network;
             if (location = target) {
                    target <- nil;
             }

       }

       action go_coffee {
             current_building <- one_of(buildings where (each.b_type = b7_coffee)).Build_ID;
             point target <- buildings[current_building].location;
             do goto target: target on: road_network;
             if (location = target) {
                    target <- nil;
             }

       }

       action go_to_school {
             current_building <- one_of(buildings where (each.b_type = b4_school)).Build_ID;
             point target <- buildings[current_building].location;
             do goto target: target on: road_network;
             if (location = target) {
                    target <- nil;
             }

       }

       action go_shopping { //weekend morning
             current_building <- one_of(buildings where (each.b_type = b6_supermarket or each.b_type = b5_shop)).Build_ID;
             point target <- buildings[current_building].location;
             do goto target: target on: road_network;
             if (location = target) {
                    target <- nil;
             }

       }

       action go_outting { //weekend evening
             current_building <- one_of(buildings where (each.b_type = b7_coffee or each.b_type = b5_shop or each.b_type = b8_restaurant or each.b_type = b9_park)).Build_ID;
             point target <- buildings[current_building].location;
             do goto target: target on: road_network;
             if (location = target) {
                    target <- nil;
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
       }

       reflex expose_other when: is_Infectious { //expose to the building as well
             list<Individuals> neighbours <- Individuals where (each.current_building = self.current_building and each.is_Susceptible = true);
             int indx1 <- 0;
             loop person over: neighbours {
                    if(flip(infected_prob)) {
                           person.is_Exposed <- true;
                           person.color <- #yellow;
                           person.day_exposed <- current_day;
                           person.hour_exposed <- current_hour;
                           person.is_Susceptible <- false;
                           indx1 <- indx1 + 1;
                    }                 
             }
             neighbours <- nil;
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
       int b_height;
       int b_type;
       rgb b_color;

       /*
     * The virus can live in the environment for 16 hours only
     * initial infected probability from env to human is mostly equal to the tramiss 0.17 and decrease by hours increase = 0.17 / nb_hours
     */
       aspect geom {
             draw shape color: b_color depth: b_height;
       }

}

species road {

       aspect geom {
             draw shape * 2 color: #white;
       }

}

experiment E2_2 type: gui  {
	//parameter "Number of people" var: humanNumber init: 1000 min:1000 max:10000 step:1000;
	//parameter "Initial infected" var: initialInfected init:10 min:1 max:100;
	parameter "Nb Initial Infectious Individuals" var: nb_Infectious_init min: 1 max: 100 step: 1;	
	
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
		
		display Population_gender {
			chart "Population by gender" type: histogram {
				datalist ["M", "F"] value:[length(Individuals where(each.gender="M")), length(Individuals where(each.gender="F"))];
			}								
		}
		
		display Population_by_age {
			chart "Population by age" type: histogram {
				datalist ["0-22", "23-55", "55+"] 
				value:[length(Individuals where(each.age<=22)), 
					   length(Individuals where(22<each.age and each.age<=55)), 
					   length(Individuals where(55<each.age))
					  ];
			}
		}		
	}	
}

experiment E2_3 type: gui {
       //parameter "Nb Individuals" var: nb_Individuals min: 1 max: 4000 step: 200;
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
             monitor "Curent Hour" value: current_hour; 
             monitor "Curent day" value: current_day;
             monitor "Cycle" value: cycle;   
       }
}
