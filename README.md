# Butterfly Coloration Evolution
## GAMA Agent-Based Model

![Simulation Preview](Team%2001%20-%20SSO/assets/preview.gif)

Agent-based model (ABM) exploring how butterfly wing coloration emerges from
predator-prey interactions and camouflage against a black-to-white
environmental gradient, built with the [GAMA Platform](https://gama-platform.org/).

## Assignment

> **USTH 2024 – Project 1**
> **Butterfly color evolution**
>
> *How do colorations of butterflies emerge from predator-prey interactions and camouflage?*
>
> The colorful canvas of butterfly wings are examples of evolutionary innovation and adaptation.
> Starting in the 19th century, naturalists investigated the function of wing-color patterns in
> different butterfly species. The understanding of population genetics in the early 20th century
> led to associations between specific genes and color patterns, helping elucidate how and when
> they evolved. Recently, researchers have discovered that just a few genes are responsible for
> setting up the patterning throughout the wing.
>
> The environmental conditions (dominant color in the surroundings) and predator avoidance
> through camouflage are key selective drivers of colorations. Observations of black and white
> colorations of closely related butterflies living in different habitats are examples of local
> adaptations and natural selection. For instance, peppered moths are displaying three morphs:
> a white morph, a black morph, and different intermediate shades of gray.
>
> A research question is to evaluate how predatory selection in a gradient of environmental
> conditions (black to white) can allow the emergence of distinct populations with different
> colors.
>
> Create an agent-based model describing the butterfly population, its reproduction at a fixed
> rate, with coloration dependent on a simple transmission system (each parent transmits black
> or white depending on its color: white butterflies only transmit white, black only black and
> gray ones have 50% chance to transmit either color), predation pressure (modeling a predator
> population that feeds on butterflies but can be tricked by their camouflage) and an abrupt or
> gradual transition in local environmental colors to explore under which conditions distinct
> morphs can emerge.
>
> **Extension 1**: Modify the model by considering that predators prefer to hunt the most
> represented color of the moth population.
>
> **Extension 2**: Modify the model to include dynamic environmental transitions, where the
> colors of the environmental patches can change at a given speed. Investigate how the
> variability in this change rate influences the emergence and stability of distinct morphs in
> butterfly populations.
>
> **Extension 3**: Explore the impact of varying predation intensity within the model. Adjust
> the predation pressure on butterfly populations, introducing scenarios with high and low
> predation rates. Examine how predation intensity influences the selection and persistence of
> different color morphs.

## Research question

How can predatory selection, acting across a gradient of environmental
background colors (black to white), drive a butterfly population to split
into distinct color morphs (black, white, gray)?

The model is inspired by the classic peppered moth case: a single
population exposed to a habitat color gradient, under predation pressure,
gives rise to black, white, and intermediate gray morphs depending on local
selective advantage.

## Model design

- **Butterfly population**: reproduces at a fixed rate. Coloration is
  inherited via simple Mendelian-like transmission:
  - white × white → white
  - black × black → black
  - gray parent → transmits black or white with 50/50 probability
- **Predator population**: hunts butterflies but can be fooled by
  camouflage — the closer a butterfly's color is to its local background,
  the lower its capture probability.
- **Environment**: a grid of patches with a color gradient from black to
  white, which can be set up as an abrupt (sharp boundary) or gradual
  (smooth gradient) transition.

### Extensions

- **Extension 1 — frequency-dependent predation**: predators preferentially
  hunt the most common color morph in the population (apostatic/negative
  frequency-dependent selection), instead of hunting purely by camouflage
  contrast.
- **Extension 2 — dynamic environment**: patch colors change over time at a
  configurable rate. The model is used to study how the speed of
  environmental change affects whether distinct morphs emerge and how
  stable they remain.
- **Extension 3 — predation intensity**: the base capture probability is
  varied between high- and low-predation scenarios to examine how the
  strength of predation pressure affects which morph(s) are selected and
  whether they persist over time.

## Repository structure

```
GAMA_Project/
└── Team 01 - SSO/
    ├── models/
    │   └── Project_01.gaml   # GAML model source (butterfly ABM)
    ├── includes/             # additional GAML includes / shared code
    └── assets/               # project assets (report, images, etc.)
```

## Running the simulation with GAMA

1. **Install GAMA** (v2025-06 or later)
   - Download the installer for your OS from the
     [official download page](https://gama-platform.org/download):
     - Windows: `.exe` installer
     - macOS: `.dmg` (choose Apple Silicon or Intel build)
     - Linux: `.deb` package
   - GAMA ships with a bundled JDK, so no separate Java install is needed.
   - Run the installer and launch **GAMA** from your applications menu
     (or command line on Linux).

2. **Open the project**
   - In GAMA, go to `File > Import > General > Existing Projects into
     Workspace` (or `File > Open Projects from File System`).
   - Select the `Team 01 - SSO` folder from this repository.
   - The project will appear in the GAMA Navigator panel.

3. **Run the model**
   - Expand `Team 01 - SSO > models` in the Navigator.
   - Double-click `Project_01.gaml` to open it in the editor.
   - Click the green **Run** (▶) button, or right-click the model and
     choose **Run**.
   - Pick an experiment from the launch dialog:
     - `Base_Model` — base predator/camouflage/gradient model
     - `Extension1_FrequencyDependentPredation` — predators target the most common morph
     - `Extension2_DynamicEnvironment` — environment gradient slides over time
     - `Extension3_HighPredation` / `Extension3_LowPredation` — high vs. low predation pressure
     - `View_3D` — 3D display with textured butterfly/predator icons

4. **Explore parameters**
   - Use the experiment's parameters panel to adjust reproduction rate,
     predation pressure, gradient shape (abrupt vs. gradual), and — for
     the extensions — predator color preference and environmental change
     speed.
   - Observe the population's color distribution over time in the
     displayed charts/grid to see when distinct morphs emerge and how
     stable they are.

## Contributors

<table>
<tr>
<td align="center">
<a href="https://github.com/oudommeng">
<img src="https://github.com/oudommeng.png" width="100" alt="oudommeng"/><br/>
<sub><b>Oudom Meng</b></sub>
</a>
</td>
<td align="center">
<a href="https://github.com/SunchhayK">
<img src="https://github.com/SunchhayK.png" width="100" alt="SunchhayK"/><br/>
<sub><b>Sunchhay K.</b></sub>
</a>
</td>
<td align="center">
<a href="https://github.com/SoLitaP">
<img src="https://github.com/SoLitaP.png" width="100" alt="SoLitaP"/><br/>
<sub><b>Solita P.</b></sub>
</a>
</td>
</tr>
</table>

## References

- GAMA Platform: <https://gama-platform.org/>
- Peppered moth industrial melanism (background biological case study)
