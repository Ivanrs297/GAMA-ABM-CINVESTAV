/***
* Name: GIS
* Author: Daniset
* Description: Model for the GIS Species Context

* Tags: Tag1, Tag2, TagN
***/
model GIS

global {
	file rooms_file <- file("../includes/building.shp");
	geometry shape <- envelope(rooms_file);
	init {
		create room from: rooms_file with: [type:: read("NATURE")] {
			if type = "Industrial" {
				color <- #blue;
			}

		}

	}

}

species room {
	rgb color <- #black;
	string type;

	aspect base {
		draw shape color: color;
	}

}

experiment GIS type: gui {
/** Insert here the definition of the input and output of the model */
	output {
		display cinvestav type: opengl {
			species room aspect: base;
		}

	}

}
