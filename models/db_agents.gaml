/***
* Name: GIS
* Author: Daniset
* Description: Model for the GIS Species Context

* Tags: Tag1, Tag2, TagN
***/
model DbAgents

//Import the model Common Schelling Segregation
import "../includes/Common Schelling Segregation.gaml"

global {
	map<string, string> MySQLParams <- ['host'::'slashwebmariadb.cyuazzw9rdsu.us-east-1.rds.amazonaws.com', 'dbtype'::'MySQL', 'database'::'geosensing', // it may be a null string
	'port'::'3306', 'user'::'geosensing', 'passwd'::'8vfYLf2j9BXPbtUu'];
	
	list<geometry> agent_shapes <- [square(0.00002), circle(0.00001)];
	list<rgb> colors <- [#blue, #red, #green, #orange];
	list<string> genders <- ["male", "female"];
	//List of all the free places
	list<space> free_places;
	//List of all the places
	list<space> all_places;
	//Shape of the world
	//geometry shape <- square(dimensions);
	//geometry shape <- envelope(rooms_file);
	//Action to initialize the people agents
	file geo_file <- geojson_file("../includes/Hex_grid_3m.geojson");
	file cinvestav_file <- dxf_file('./../includes/Cinvestav - Planta Baja.dxf',#m);
	geometry shape <- envelope(geo_file);
	action initialize_people {
		create simulated_agent number: number_of_people;
		all_people <- simulated_agent as list;
	}

	//Action to initialize the places
	action initialize_places {
		all_places <- shuffle(space);
		free_places <- all_places;
	}

	init {
		create db_agent number: 1;
		create Hex from: geo_file;
		//create cinvest_element from: cinvestav_file;
	}

}

species Hex {
	geometry geo;
	rgb color <- #black;
	rgb text_color <- (color.brighter);
	
	init {
		shape <- (simplification(shape,1));
		//write(location);
	}
	aspect default {
		draw shape.contour color: color;
		draw name font: font("Helvetica", 10 + #zoom, #bold) color: #black at: location + {0,0,12} perspective:false;
	}
	
}

//Grid to discretize space, each cell representing a free space for the people agents
grid space width: dimensions height: dimensions neighbors: 8 use_regular_agents: false frequency: 0 {
	rgb color <- #black;
}

species room {
	rgb color <- #black;
	string type;

	aspect base {
		draw shape color: color;
	}

}
species cinvest_element
{
	aspect default
		{
		draw cinvestav_file;
	}
	init {
		shape <- polygon(shape.points);
	}
}
species simulated_agent parent: base {
	Hex cell <- one_of(Hex);
//Color of the agent
	rgb color <- one_of(colors);
	geometry agent_shape <- one_of(agent_shapes);
	string number <- string(rnd(1, 5));
	//List of all the neighbours of the agent
	list<simulated_agent> my_neighbours -> simulated_agent at_distance neighbours_distance;
	//Cell representing the place of the agent
	space my_place;
	bool is_happy <- false;

	init {
	//The agent will be located on one of the free places
		location <- cell.location;
		//As one agent is in the place, the place is removed from the free places
		//free_places >> my_place;
		is_happy <- false;
	}

	//Reflex to migrate the people agent when it is not happy 
	reflex migrate when: !is_happy {
	//Add the place to the free places as it will move to another place
		cell <- one_of(Hex);
		//Change the place of the agent
		location <- cell.location;
		//Remove the new place from the free places
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

			similarity_nearby <- similarity_nearby + (similarity / 3.0);
		}

		int total_neighbours <- (length(my_neighbours));
		if (total_neighbours > 0) {
			similarity_nearby <- similarity_nearby / total_neighbours;
		}

		is_happy <- similarity_nearby >= (percent_similar_wanted);
	}

	aspect default {
		draw agent_shape color: color at: location;
		draw number at: location;
	}

}

species db_agent skills: [SQLSKILL] {
	// for initializing the select
	string usuariosRealesSelect <- 'SELECT u.id, u.username, g.created_at, u.genre, u.speciality, g.latitude, g.longitude from Geolocation g JOIN User u ON g.user_id = u.id 
									WHERE  DATE_ADD(NOW(),INTERVAL -7 SECOND) <= g.created_at GROUP BY(g.user_id)';
	list<list> real_agents <- [];

	init {
		if (self testConnection (params: MySQLParams)) {
			write "Connection is OK";
			real_agents <- list(self select (params: MySQLParams,
                                                           select: usuariosRealesSelect));
			create real_agent from: real_agents with:[ id:: "id", username:: "username", genre:: "genre", speciality:: "speciality", 
														latitude:: "latitude", longitude:: "longitude"
			];
		} else {
			write "Connection is false";
		} }
		
	reflex update {
		//write("updating...");
		list<list> users <- list(self select (params: MySQLParams,
                                                           select: usuariosRealesSelect));
        loop user over: real_agents[2] {
        	int idx <- 0;
        	bool existe <- false;
        	loop u over: users[2] {
        		if(u['id'] = user['id']) {
        			existe <- true;
        			break;
        		}
        		idx <- idx + 1;	
        	}
        	if(existe) {
        		users[2] >> users[2][idx];
        	}
        }
        loop user over: users[2] {
        		real_agents[2] << user;
        		write(user);
        }
        //write(newUsers);
		create real_agent from: users with:[ id:: "id", username:: "username", genre:: "genre", speciality:: "speciality"];
	} 
}

species real_agent parent: base skills: [SQLSKILL] {
	string id;
	string username;
	string genre;
	string speciality;
	space my_place;
	string latitude;
	string longitude;
	init {
		float x <- (0 - float(longitude) - 103.4641779121691824);
		float y <- (float(latitude) - 20.6673548651040311);
		write(location.x);
		location <- {x, y};
		write(id);
		
	}
	aspect default {
		draw agent_shapes[int(genre)] color: colors[int(speciality)] at: location;
	}
	
	reflex update {
		string usuariosRealesSelect <- 'SELECT * from user where id = ?';
		list<list> user <- list(self select (params: MySQLParams,
                                                           select: 'SELECT u.id, u.username, g.created_at, u.genre, u.speciality, g.latitude, g.longitude from Geolocation g JOIN User u ON g.user_id = u.id 
									WHERE  DATE_ADD(NOW(),INTERVAL -7 SECOND) <= g.created_at AND g.user_id = ? GROUP BY(g.user_id);',
                                                           values: [id]));
	   if(length(user[2]) > 0) {
	   	float x <- (0 - float(user[2][0][6]) - 103.4641779121691824);
		float y <- (float(user[2][0][5]) - 20.6673548651040311);
		location <- {x, y};
		write(location.x);
	   		write(user[2][0]);
	   }
       
                                            
	}
}
species cinvestav {
	file img <- dxf_file('./../includes/Cinvestav - Planta Baja.dxf');
	aspect default {
		 draw img;
	}
}
experiment schelling type: gui {
/** Insert here the definition of the input and output of the model */
	output {
		display Segregation {
			species Hex; 
			image 'background' file: './../includes/Girada.jpg';
			species simulated_agent;
			species real_agent aspect: default; 	
			species simulated_agent;
			//species cinvest_element;
			
		}

	}

}
