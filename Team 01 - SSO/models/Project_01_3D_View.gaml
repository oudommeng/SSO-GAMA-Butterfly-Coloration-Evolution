/**
* Name: Project01_3D_View
* Standalone 3D-motion version of Project01 (see Project_01.gaml for the
* reference 2D model). Butterflies and predators fly using the moving3D
* skill and vary in altitude (z-axis), instead of only being viewed from
* an angled camera over a flat plane. Genetics/predation rules are the
* same single-locus B/W model as the reference.
* Author: oudommeng
* Tags: 3d, flight, predation, camouflage
*/

model Project01_3D_View

global {
	// --- World geometry: 100m x 100m x 100m volume (moving3D requires a 3D shape) ---
	geometry shape <- cube(100 #m);

	// --- Grid / environment ---
	int grid_size <- 50;
	string transition_type <- "gradual" among: ["gradual", "abrupt"];
	bool dynamic_environment <- true;
	float env_change_speed <- 0.0;

	// --- Butterfly population ---
	int nb_butterflies_init <- 200;
	float black_allele_freq <- 0.5;
	float reproduction_rate <- 0.1;
	int carrying_capacity <- 600;
	float natural_death_proba <- 0.01;

	// --- Predator population ---
	int nb_predators_init <- 10;
	float base_capture_proba <- 0.6;
	float detection_radius <- 2.0;
	float predator_speed <- 0.5;
	bool frequency_dependent_predation <- false;

	// --- Flight envelope (3D-motion specific) ---
	float z_max <- 15 #m;
	float z_min <- 0.5 #m;

	// --- Butterfly icons by genotype ---
	map<string, gif_file> butterfly_icons <- ["BB"::gif_file("../assets/butterfly_BB.gif"), "WW"::gif_file("../assets/butterfly_WW.gif"), "BW"::gif_file("../assets/butterfly_BW.gif")];

	// --- Monitoring ---
	int nb_black -> length(butterfly where (each.color_class = "black"));
	int nb_white -> length(butterfly where (each.color_class = "white"));
	int nb_gray -> length(butterfly where (each.color_class = "gray"));
	int nb_BB -> length(butterfly where (each.genotype = "BB"));
	int nb_WW -> length(butterfly where (each.genotype = "WW"));
	int nb_BW -> length(butterfly where (each.genotype = "BW"));
	int nb_allele_B -> 2 * nb_BB + nb_BW;
	int nb_allele_W -> 2 * nb_WW + nb_BW;

	int nb_reproductions <- 0;
	int nb_deaths_predation <- 0;
	int nb_deaths_natural <- 0;
	int nb_deaths_total -> nb_deaths_predation + nb_deaths_natural;

	reflex reset_counters {
		nb_reproductions <- 0;
		nb_deaths_predation <- 0;
		nb_deaths_natural <- 0;
	}

	init {
		create butterfly number: nb_butterflies_init {
			string a1 <- flip(black_allele_freq) ? "B" : "W";
			string a2 <- flip(black_allele_freq) ? "B" : "W";
			genotype <- (a1 = "B" and a2 = "B") ? "BB" : ((a1 = "W" and a2 = "W") ? "WW" : "BW");
			point p <- any_location_in(one_of(patch_env));
			location <- {p.x, p.y, z_min + rnd(z_max - z_min)};
		}
		create predator number: nb_predators_init {
			point p <- any_location_in(one_of(patch_env));
			location <- {p.x, p.y, z_min + rnd(z_max - z_min)};
		}
	}
}

grid patch_env width: grid_size height: grid_size neighbors: 8 {
	float env_color <- 0.0;
	rgb color update: rgb(env_color * 255, env_color * 255, env_color * 255);

	init {
		env_color <- (transition_type = "abrupt") ? (grid_x < grid_size / 2 ? 0.0 : 1.0) : (grid_x / float(grid_size - 1));
	}

	reflex slide_gradient when: dynamic_environment {
		float shift <- (cycle * env_change_speed) mod grid_size;
		float x_shifted <- (grid_x + shift) mod grid_size;
		env_color <- (transition_type = "abrupt") ? (x_shifted < grid_size / 2 ? 0.0 : 1.0) : (x_shifted / (grid_size - 1));
	}
}

species butterfly skills: [moving3D] {
	string genotype; // "BB", "WW" or "BW"
	string color_class update: (genotype = "BB") ? "black" : ((genotype = "WW") ? "white" : "gray");
	float color_value update: (genotype = "BB") ? 0.0 : ((genotype = "WW") ? 1.0 : 0.5);
	rgb color update: (color_class = "black") ? #black : ((color_class = "white") ? #white : rgb(128, 128, 128));

	string transmit_allele() {
		if (genotype = "BB") {
			return "B";
		} else if (genotype = "WW") {
			return "W";
		} else {
			return flip(0.5) ? "B" : "W";
		}
	}

	reflex move {
		do wander(amplitude: 30.0, speed: 0.5);
	}

	reflex clamp_altitude {
		if (location.z) < z_min {
			location <- {location.x, location.y, z_min};
		} else if (location.z) > z_max {
			location <- {location.x, location.y, z_max};
		}
	}

	reflex reproduce when: flip(reproduction_rate) and (length(butterfly) < carrying_capacity) {
		list<butterfly> mates <- (butterfly at_distance 5) - self;
		if not empty(mates) {
			butterfly mate <- one_of(mates);
			string a1 <- self.transmit_allele();
			string a2 <- mate.transmit_allele();
			string child_genotype <- (a1 = "B" and a2 = "B") ? "BB" : ((a1 = "W" and a2 = "W") ? "WW" : "BW");
			create butterfly number: 1 {
				genotype <- child_genotype;
				location <- myself.location;
			}
			nb_reproductions <- nb_reproductions + 1;
		}
	}

	reflex die_natural when: flip(natural_death_proba) {
		nb_deaths_natural <- nb_deaths_natural + 1;
		do die;
	}

	aspect base {
		draw circle(1) color: color;
	}

	aspect flight {
		draw (butterfly_icons at genotype) size: 2.5 #m rotate: heading;
	}
}

species predator skills: [moving3D] {
	gif_file bird_icon <- gif_file("../assets/predators_bird.gif");

	reflex hunt {
		list<butterfly> preys <- butterfly at_distance detection_radius;
		if not empty(preys) {
			butterfly prey <- one_of(preys);
			float capture_p;
			if frequency_dependent_predation {
				float freq <- length(butterfly where (each.color_class = prey.color_class)) / max(1, length(butterfly));
				capture_p <- base_capture_proba * freq;
			} else {
				patch_env here_patch <- patch_env({prey.location.x, prey.location.y});
				float contrast <- abs(here_patch.env_color - prey.color_value);
				capture_p <- base_capture_proba * contrast;
			}
			if flip(capture_p) {
				nb_deaths_predation <- nb_deaths_predation + 1;
				ask prey {
					do die;
				}
			} else {
				do goto(target: prey.location, speed: predator_speed);
			}
		} else {
			do wander(amplitude: 30.0, speed: predator_speed);
		}
	}

	reflex clamp_altitude {
		if (location.z) < z_min {
			location <- {location.x, location.y, z_min};
		} else if (location.z) > z_max {
			location <- {location.x, location.y, z_max};
		}
	}

	aspect base {
		draw triangle(1.5) color: #red;
	}

	aspect flight {
		draw bird_icon size: 4 #m rotate: heading;
	}
}

experiment Motion_3D type: gui {
	parameter "Grid size" var: grid_size;
	parameter "Environment transition" var: transition_type;
	parameter "Initial butterflies" var: nb_butterflies_init;
	parameter "Initial black-allele frequency" var: black_allele_freq;
	parameter "Reproduction rate" var: reproduction_rate;
	parameter "Carrying capacity" var: carrying_capacity;
	parameter "Initial predators" var: nb_predators_init;
	parameter "Base capture probability" var: base_capture_proba;
	parameter "Predator detection radius" var: detection_radius;
	parameter "Flight ceiling" var: z_max;
	parameter "Flight floor" var: z_min;

	output {
		layout #split;
		monitor "Butterflies alive" value: length(butterfly);
		monitor "Deaths - predation (this cycle)" value: nb_deaths_predation;
		monitor "Deaths - natural (this cycle)" value: nb_deaths_natural;
		monitor "Genotype BB (black)" value: nb_BB;
		monitor "Genotype WW (white)" value: nb_WW;
		monitor "Genotype BW (gray)" value: nb_BW;

		display Environment_3D_Motion type: 3d {
			species patch_env transparency: 0.5;
			species butterfly aspect: flight;
			species predator aspect: flight;
			camera "default" location: {25, -60, 70} target: {50, 50, z_max / 2};
		}

		display ThirdPerson_Predator type: 3d antialias: false {
			//Chase camera positioned behind and above the tracked predator, looking at it
			camera "default" dynamic: true
				location: {first(predator).location.x - (cos(first(predator).heading) * 8), first(predator).location.y - (sin(first(predator).heading) * 8), first(predator).location.z + 4}
				target: first(predator).location;
			species patch_env transparency: 0.5;
			species butterfly aspect: flight;
			species predator aspect: flight;
		}

		display Population_Chart {
			chart "Color morphs over time" type: series {
				data "black" value: nb_black color: #black;
				data "gray" value: nb_gray color: #gray;
				data "white" value: nb_white color: #black marker: false;
			}
		}
	}
}
