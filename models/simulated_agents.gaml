/***
* Name: GIS
* Author: Daniset
* Description: Model for the GIS Species Context

* Tags: Tag1, Tag2, TagN
***/

model SimulatedAgents

//Import the model Common Schelling Segregation
import "../includes/Common Schelling Segregation.gaml" 
global {
	// TODO Change shape file for the correct one for cinvestav
	file rooms_file <- file("../includes/building.shp");
	list<geometry> agent_shapes <- [square(1), circle(0.5)];
	list<rgb> colors <- [#blue, #red, #green, #orange];
	list<string> genders <- ["male", "female"];
	//List of all the free places
	list<space> free_places ;
	//List of all the places
	list<space> all_places ;
	//Shape of the world
	geometry shape <- square(dimensions);
	//geometry shape <- envelope(rooms_file);
	//Action to initialize the people agents
	
	action initialize_people { 
		create simulated_agent number: number_of_people;
		all_people <- simulated_agent as list ;  
	}
	
	//Action to initialize the places
	action initialize_places { 
		all_places <- shuffle (space);
		free_places <- all_places;  
	}
	 
	init {
		create room from: rooms_file with: [type:: read("NATURE")] {
			if type = "Industrial" {
				color <- #blue;
			}

		}
		
	}

}


//Grid to discretize space, each cell representing a free space for the people agents
grid space width: dimensions height: dimensions neighbors: 8 use_regular_agents: false frequency: 0{
	rgb color  <- #black;
}

species room {
	rgb color <- #black;
	string type;

	aspect base {
		draw shape color: color;
	}

}

species simulated_agent parent: base {
	//Color of the agent
	rgb color <- one_of(colors);
	geometry agent_shape <- one_of(agent_shapes);
	string number <- string(rnd(1,5));
	//List of all the neighbours of the agent
	list<simulated_agent> my_neighbours -> simulated_agent at_distance neighbours_distance;
	//Cell representing the place of the agent
	space my_place;
	bool is_happy <- false;
	init {
		//The agent will be located on one of the free places
		my_place <- one_of(free_places);
		location <- my_place.location; 
		//As one agent is in the place, the place is removed from the free places
		free_places >> my_place;
		is_happy <- false;
	}
	 
	//Reflex to migrate the people agent when it is not happy 
	reflex migrate when: !is_happy {
		//Add the place to the free places as it will move to another place
		free_places << my_place;
		//Change the place of the agent
		my_place <- one_of(free_places);
		location <- my_place.location; 
		//Remove the new place from the free places
		free_places >> my_place;
		
		float similarity_nearby <- 0.0;
		
		loop neighbour over: my_neighbours {
			float similarity <- 0.0;
			if (neighbour.color = color) {
				similarity <- similarity + 1.0;
			}
			if (neighbour.number = number) {
				similarity <- similarity + 1.0;
			}
			if (neighbour.agent_shape = agent_shape) {
				similarity <- similarity + 1.0;
			}
			similarity_nearby <- similarity_nearby + (similarity/3.0);
		}
		int total_neighbours <- (length(my_neighbours));
		if (total_neighbours > 0) {
			similarity_nearby <- similarity_nearby/total_neighbours;	
		}
		is_happy <- similarity_nearby >= (percent_similar_wanted);
	}
	
	aspect default{ 
		draw agent_shape color: color at: location;
		draw number at: location;
	}
}

experiment schelling type: gui {
/** Insert here the definition of the input and output of the model */
	output {
		display Segregation {
			species simulated_agent;
		}	

	}

}
