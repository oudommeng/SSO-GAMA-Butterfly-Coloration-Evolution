/**
* Name: Project01
* Butterfly wing-coloration evolution under predation and camouflage.
* Single-locus, two-allele genetics: B (black) / W (white).
*   Genotype BB -> black phenotype (only transmits B)
*   Genotype WW -> white phenotype (only transmits W)
*   Genotype BW -> gray phenotype  (transmits B or W, 50/50)
* Predators hunt butterflies; capture probability depends on contrast
* between butterfly color and local patch color (camouflage).
* Extension 1: predators preferentially target the most common color class.
* Extension 2: environment gradient slides across the grid at a configurable speed.
* Extension 3: predation intensity is varied (high vs. low base capture probability)
*   to study its effect on morph selection and persistence.
* Authors: Oudom Meng, Sunchhay Khoun, Solita Pun
* Tags: agent-based model, evolution, predation, camouflage, genetics
*/

model Project01

global {
	// --- World geometry: 100m x 100m square environment ---
	geometry shape <- square(100 #m);

	// --- Grid / environment ---
	int grid_size <- 50;
	string transition_type <- "gradual" among: ["gradual", "abrupt"];
	bool dynamic_environment <- true;
	float env_change_speed <- 0.0; // patches shifted per cycle (extension 2)

	// --- Butterfly population ---
	int nb_butterflies_init <- 200;
	float black_allele_freq <- 0.5; // initial frequency of allele B in the population
	float reproduction_rate <- 0.1; // probability an individual reproduces each cycle
	int carrying_capacity <- 600;
	float natural_death_proba <- 0.01;

	// --- Predator population ---
	int nb_predators_init <- 10;
	float base_capture_proba <- 0.6; // capture probability at maximum contrast / max frequency
	float detection_radius <- 2.0;
	float predator_speed <- 0.5;
	bool frequency_dependent_predation <- false; // extension 1

	// --- Monitoring: population / genotype counts (recomputed every cycle) ---
	int nb_black -> length(butterfly where (each.color_class = "black"));
	int nb_white -> length(butterfly where (each.color_class = "white"));
	int nb_gray -> length(butterfly where (each.color_class = "gray"));
	int nb_BB -> length(butterfly where (each.genotype = "BB"));
	int nb_WW -> length(butterfly where (each.genotype = "WW"));
	int nb_BW -> length(butterfly where (each.genotype = "BW"));
	int nb_allele_B -> 2 * nb_BB + nb_BW; // total B alleles in the population
	int nb_allele_W -> 2 * nb_WW + nb_BW; // total W alleles in the population

	// --- Monitoring: event counters, reset every cycle by reset_counters ---
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
			location <- any_location_in(one_of(patch_env));
		}
		create predator number: nb_predators_init {
			location <- any_location_in(one_of(patch_env));
		}
	}
}

grid patch_env width: grid_size height: grid_size neighbors: 8 {
	float env_color <- 0.0; // 0 = black background, 1 = white background
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

species butterfly skills: [moving] {
	string genotype; // "BB", "WW" or "BW"
	string color_class update: (genotype = "BB") ? "black" : ((genotype = "WW") ? "white" : "gray");
	float color_value update: (genotype = "BB") ? 0.0 : ((genotype = "WW") ? 1.0 : 0.5);
	rgb color update: (color_class = "black") ? #black : ((color_class = "white") ? #white : rgb(128, 128, 128));

	string transmit_allele {
		if (genotype = "BB") {
			return "B";
		} else if (genotype = "WW") {
			return "W";
		} else {
			return flip(0.5) ? "B" : "W";
		}
	}

	reflex move {
		do wander amplitude: 30.0 speed: 0.5;
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

	aspect realistic {
		string icon <- "../assets/butterfly_" + color_class + ".png";
		if file_exists(icon) {
			draw square(2.0) rotate: heading texture: icon;
		} else {
			draw sphere(0.6) color: color;
		}
	}
}

species predator skills: [moving] {
	reflex hunt {
		list<butterfly> preys <- butterfly at_distance detection_radius;
		if not empty(preys) {
			butterfly prey <- one_of(preys);
			float capture_p;
			if frequency_dependent_predation {
				float freq <- length(butterfly where (each.color_class = prey.color_class)) / max(1, length(butterfly));
				capture_p <- base_capture_proba * freq;
			} else {
				patch_env here_patch <- patch_env(prey.location);
				float contrast <- abs(here_patch.env_color - prey.color_value);
				capture_p <- base_capture_proba * contrast;
			}
			if flip(capture_p) {
				nb_deaths_predation <- nb_deaths_predation + 1;
				ask prey {
					do die;
				}
			} else {
				do goto target: prey.location speed: predator_speed;
			}
		} else {
			do wander amplitude: 30.0 speed: predator_speed;
		}
	}

	aspect base {
		draw triangle(1.5) color: #red;
	}

	aspect realistic {
		string icon <- "../assets/predator.png";
		if file_exists(icon) {
			draw square(3.0) rotate: heading texture: icon;
		} else {
			draw cone3D(1.2, 2.0) color: #red;
		}
	}
}

experiment Base_Model type: gui {
	parameter "Grid size" var: grid_size;
	parameter "Environment transition" var: transition_type;
	parameter "Initial butterflies" var: nb_butterflies_init;
	parameter "Initial black-allele frequency" var: black_allele_freq;
	parameter "Reproduction rate" var: reproduction_rate;
	parameter "Carrying capacity" var: carrying_capacity;
	parameter "Initial predators" var: nb_predators_init;
	parameter "Base capture probability" var: base_capture_proba;
	parameter "Predator detection radius" var: detection_radius;

	output {
		monitor "Butterflies alive" value: length(butterfly);
		monitor "Reproductions (this cycle)" value: nb_reproductions;
		monitor "Deaths - predation (this cycle)" value: nb_deaths_predation;
		monitor "Deaths - natural (this cycle)" value: nb_deaths_natural;
		monitor "Deaths - total (this cycle)" value: nb_deaths_total;
		monitor "Genotype BB (black)" value: nb_BB;
		monitor "Genotype WW (white)" value: nb_WW;
		monitor "Genotype BW (gray)" value: nb_BW;
		monitor "Allele B count" value: nb_allele_B;
		monitor "Allele W count" value: nb_allele_W;

		display Environment type: 2d {
			image "../assets/background.jpg";
			grid patch_env border: #black transparency: 0.3;
			species butterfly aspect: base;
			species predator aspect: base;
		}
		display Population_Chart {
			chart "Color morphs over time" type: series {
				data "black" value: nb_black color: #black;
				data "gray" value: nb_gray color: #gray;
				data "white" value: nb_white color: #black marker: false;
			}
		}
		display Events_Chart {
			chart "Reproductions vs deaths per cycle" type: series {
				data "reproductions" value: nb_reproductions color: #green;
				data "deaths (predation)" value: nb_deaths_predation color: #red;
				data "deaths (natural)" value: nb_deaths_natural color: #gray;
			}
		}
	}
}

experiment Extension1_FrequencyDependentPredation parent: Base_Model {
	parameter "Frequency-dependent predation" var: frequency_dependent_predation init: true;
}

experiment Extension2_DynamicEnvironment parent: Base_Model {
	parameter "Dynamic environment" var: dynamic_environment init: true;
	parameter "Environment change speed" var: env_change_speed init: 0.1;
}

experiment Extension3_HighPredation parent: Base_Model {
	parameter "Base capture probability" var: base_capture_proba init: 0.9;
}

experiment Extension3_LowPredation parent: Base_Model {
	parameter "Base capture probability" var: base_capture_proba init: 0.15;
}

experiment View_3D parent: Base_Model {
	output {
		display Environment_3D type: 3d {
//			image "../assets/background.jpg" size: {100, 100, 0} position: {0, 0, 0};
			species patch_env transparency: 0.6;
			species butterfly aspect: realistic;
			species predator aspect: realistic;
			camera "default" location: {50, -30, 90} target: {50, 50, 0};
		}
	}
}
