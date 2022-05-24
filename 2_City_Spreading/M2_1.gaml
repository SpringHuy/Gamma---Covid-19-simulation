/***
* Name: M21
* Author: huyph
* Description: 
* Tags: Tag1, Tag2, TagN
***/

model M21

/* Insert your model definition here */

global {
       file city_buildings <- file("../includes/buildings.shp");
       file city_roads <- file("../includes/roads.shp");
       geometry shape <- envelope(city_roads);
       float step <- 1 #h;
       graph road_network;
       
       int nb_building_type <- 9;
       int b1_home <- 1;
       int b2_industry <- 2;
       int b3_office <- 3;
       int b4_school <- 4;
       int b5_shop <- 5;
       int b6_supermarket <- 6;
       int b7_coffee <- 7;
       int b8_restaurant <- 8;
       int b9_park <- 9;
       list<int> building_types <- [b1_home, b2_industry, b3_office, b4_school, b5_shop, b6_supermarket, b7_coffee, b8_restaurant, b9_park];
       
       int nb_Individuals <- 500;
       int nb_Infectious_init <- 5;
       
       float transmission_diameter <- 2.0 #m;
       float infected_prob <- 0.7;
       int incubation_period <- 7 ;
       int infectious_period <- 14;
       
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
             
             create Individuals number: 500 {
                    location <- any_location_in(one_of(buildings));                    
      		}
      		ask nb_Infectious_init among Individuals {
	             is_Infectious <- true;
	             is_Susceptible <- false;
             }
      	road_network <- as_edge_graph(road);
       }
	/*       
       reflex update_speed {
             map<road,float> new_weights <- road as_map (each::each.shape.perimeter * each.speed_rate);
             road_network <- road_network with_weights new_weights;
       }
     */   
             //(nb_Exposed_Individuals = 0 and nb_Infectious_Individuals = 0 ) or
       reflex end_simulation when: (nb_Exposed_Individuals = 0 and nb_Infectious_Individuals = 0 ) or cycle > 500 {
             write "End of the simulation when there is no E and I or cycle is greater than 500";
             do pause;
       }      
}


species Individuals skills:[moving] {
       bool is_Susceptible <- true;
       bool is_Exposed <- false;
       bool is_Infectious <- false;
       bool is_Recovered <- false;
       
       int incubation_counter <- 0;
       int infectious_counter <- 0;
       rgb color;
       
       point target <- nil;
       float proba_leave <- 0.6; 
       float speed <- 30 #km/#h;           

       reflex become_Recovered when: is_Infectious  {
             //after sometimes become recovered
             if(infectious_counter = infectious_period){
                    is_Recovered <- true;
                    is_Infectious <- false ;
                    color <- #grey ;                  
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
                    color <- #red ;
             }
             else{
                    incubation_counter <- incubation_counter + 1 ;                   
             }
       }
       
       reflex become_Exposed when: is_Susceptible {
             //if in neighbours has an is_Infectious Individuals
             list<Individuals> neighbours <- Individuals at_distance transmission_diameter where(each.is_Infectious = true);
             if(length(neighbours) > 0){
                    if flip(infected_prob){
                    	is_Exposed <- true;
                    	is_Susceptible <- false;
             			color <- #yellow ;	
                    }                  
              }
       }
       
       reflex leave when: (target = nil) and (flip(proba_leave)) {
             target <- any_location_in(one_of(buildings));
       }
       
       reflex move when: target != nil {
             do goto target: target on: road_network;
             if (location = target) {
                    target <- nil;
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
       int b_height;
       int b_type;
       rgb b_color <- #grey;
       aspect geom {
             draw shape color: b_color depth: b_height; // texture: ["../includes/roof_top.png"]; //,"../includes/texture5.jpg"];
       }
}

species road {
       float capacity <- 1 + shape.perimeter/30;
       int nb_drivers <- 0 update: length(Individuals at_distance 1);
       float speed_rate <- 1.0 update:  exp(-nb_drivers/capacity);
       aspect geom {
             draw (shape + 3 * speed_rate) color: #white;
       }
}

experiment M2_1_Realistic_city type: gui {
       parameter "Nb Individuals" var: nb_Individuals min: 100 max: 4000 step: 200;
       parameter "Infected probability" var: infected_prob  min: 0.0 max: 1.0 step: 0.1;
       parameter "Nb Initial Infectious Individuals" var: nb_Infectious_init min: 1 max: 100 step: 1;
       parameter "Incubation period" var: incubation_period min: 5 max: 15 step: 1;
       parameter "Infectious period" var: infectious_period min: 5 max: 30 step: 1;


       output {
             display map type: opengl {
                    image "../includes/earth_turtle.jpg" refresh: false;
                    species buildings aspect: geom refresh: false;
                    species road aspect: geom ;
                    species Individuals aspect: threeD;
                                 
                    graphics g {
                           draw "" + current_date font: font("Arial", 32, #bold) at: {50,100} color: #black;
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
             monitor "Recoverd Individuals" value: nb_Recovered_Individuals;
             monitor "Recoverd Individuals" value: nb_Recovered_Individuals;
             monitor "Step at stop" value: cycle;   
       }
}
