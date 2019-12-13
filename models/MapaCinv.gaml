/***
* Name: MapaCinv
* Author: Constante
* Description: Importar mapa de Cinvestav como mapa de archivo DXF.
* Tags: Tag1, Tag2, TagN prueba
***/

model MapaCinv

global
{
	file cinvest_file <- dxf_file('./../includes/Cinvestav - Planta Baja.dxf',#m);

	//compute the environment size from the dxf file envelope
	geometry shape <- envelope(cinvest_file);
	init
	{
	//create house_element agents from the dxf file and initialized the layer attribute of the agents from the the file
		create cinvest_element from: cinvest_file;
	}
}

species cinvest_element
{
	aspect default
		{
		draw shape.contour color: #black;
	}
	init {
		shape <- polygon(shape.points);
	}
}

experiment DXFAgents type: gui
{   
	output
	{	
		layout #split;
		display map type: opengl
		{
			species cinvest_element;
		}

	}

}
