/***
* Name: GridCinv
* Author: Constante
* Description: Importar archivo GeoJSON, con polígonos del area de Cinvestav.
* Tags: Tag1, Tag2, TagN
***/

model GridCinv

global {
	file geo_file <- geojson_file("../includes/Hex_grid_3m.geojson");
	geometry shape <- envelope(geo_file);
	init {
		create Hex from: geo_file with: [type:: "type"];
		loop el over: geo_file {
            write el;
        }
	}
} 

species Hex {
	rgb color <- #black;
	rgb text_color <- (color.brighter);
	string type;
	
	init {
		shape <- (simplification(shape,1));
	}
	aspect default {
		draw shape.contour color: color;
		draw name font: font("Helvetica", 10 + #zoom, #bold) color: #black at: location + {0,0,12} perspective:false;
	}
}

experiment Display  type: gui {
	output {
		display Countries type: opengl{	
			species Hex;			
		}
	}
}
