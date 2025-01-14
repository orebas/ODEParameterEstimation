from dataclasses import dataclass, field
import antimony
import tellurium as te
import numpy as np
import pandas as pd
import yaml
import os
import tomli
from typing import Dict, List, Tuple, Optional
from pathlib import Path


@dataclass
class ParameterBounds:
    """Bounds and scaling for parameters"""

    lower_bound: float
    upper_bound: float
    scale: str = "log10"


@dataclass
class Observable:
    """Specification of an observable"""

    name: str
    formula: str
    transformation: str = "lin"
    noise_distribution: str = "normal"


@dataclass
class ODEModel:
    """Specification of an ODE model"""

    states: List[str]
    parameters: Dict[str, float]
    equations: List[str]
    initial_conditions: Dict[str, float]
    observables: List[Observable]
    estimate_initial_conditions: List[str] = field(default_factory=list)


@dataclass
class DataGenerationSpec:
    """Specification for synthetic data generation and PETAB configuration"""

    timespan: Tuple[float, float]
    n_timepoints: int
    noise_level: float
    random_seed: int = 42
    output_dir: str = "petab_problem"
    condition_id: str = "condition1"
    dataset_id: str = "dataset1"
    noise_formula: str = "noiseParameter1"
    parameter_bounds: Dict[str, ParameterBounds] = field(default_factory=dict)
    default_bounds: ParameterBounds = field(
        default_factory=lambda: ParameterBounds(1e-3, 1e3, "log10")
    )
    blind: bool = False


def parse_toml_model(toml_file: str) -> Tuple[ODEModel, DataGenerationSpec]:
    """Parse a TOML file into model and data generation specifications"""
    with open(toml_file, "rb") as f:
        config = tomli.load(f)

    # Parse model section
    model_config = config["model"]

    # Process states as a list of objects
    states = []
    initial_conditions = {}
    estimate_initial_conditions = []

    for state in model_config["states"]:
        state_name = state["name"]
        states.append(state_name)
        initial_conditions[state_name] = state["initial_value"]
        if state.get("estimate", False):
            estimate_initial_conditions.append(state_name)

    # Process parameters
    parameters = {}
    parameter_bounds = {}

    for param in model_config["parameters"]:
        param_name = param["name"]
        parameters[param_name] = param["value"]
        if "bounds" in param:
            parameter_bounds[param_name] = ParameterBounds(
                lower_bound=param["bounds"][0],
                upper_bound=param["bounds"][1],
                scale=param.get("scale", "log10"),
            )

    # Process observables - if none defined, create identity observables for all states
    observables = []
    if "observables" in model_config:
        for obs in model_config["observables"]:
            observables.append(
                Observable(
                    name=obs["name"],
                    formula=obs["formula"],
                    transformation=obs.get("transformation", "lin"),
                    noise_distribution=obs.get("noise_distribution", "normal"),
                )
            )
    else:
        # Create identity observables for all states
        for state in states:
            observables.append(
                Observable(
                    name=f"obs_{state}",
                    formula=state,  # Identity observable
                    transformation="lin",  # Default to linear transformation
                    noise_distribution="normal",  # Default to normal noise
                )
            )

    model = ODEModel(
        states=states,
        parameters=parameters,
        equations=model_config["equations"],
        initial_conditions=initial_conditions,
        observables=observables,
        estimate_initial_conditions=estimate_initial_conditions,
    )

    # Parse simulation section
    sim_config = config.get("simulation", {})
    data_spec = DataGenerationSpec(
        timespan=tuple(sim_config.get("timespan", (0, 10))),
        n_timepoints=sim_config.get("n_timepoints", 100),
        noise_level=sim_config.get("noise_level", 0.05),
        random_seed=sim_config.get("random_seed", 42),
        output_dir=sim_config.get("output_dir", "petab_problem"),
        blind=sim_config.get("blind", False),
        parameter_bounds=parameter_bounds,
    )

    return model, data_spec


# Rest of your PETABGenerator class remains the same
class PETABGenerator:
    def __init__(self, model: ODEModel, data_spec: DataGenerationSpec):
        self.model = model
        self.data_spec = data_spec

    def create_antimony_string(self, use_true_values: bool = True) -> str:
        """Convert model specification to Antimony format
        
        Args:
            use_true_values: If True, use true parameter values. If False, use 1.0 for parameters.
        """
        lines = ["model feedback"]

        # Add parameters for estimated initial conditions first
        for state in self.model.estimate_initial_conditions:
            init_param = f"init_{state}"
            # Use true values for simulation, 1.0 for SBML when blind
            value = self.model.initial_conditions[state] if use_true_values or not self.data_spec.blind else 1.0
            lines.append(f"{init_param} = {value}")
        lines.append("")

        # Add initial conditions
        for state, value in self.model.initial_conditions.items():
            if state in self.model.estimate_initial_conditions:
                # Use parameter reference for estimated initial conditions
                lines.append(f"species {state} = init_{state}")
            else:
                # Use fixed value for non-estimated initial conditions
                value = value if use_true_values or not self.data_spec.blind else 1.0
                lines.append(f"species {state} = {value}")
        lines.append("")

        # Add parameter values - use true values for simulation, 1.0 for SBML when blind
        for param in self.model.parameters:
            value = self.model.parameters[param] if use_true_values or not self.data_spec.blind else 1.0
            lines.append(f"{param} = {value}")
        lines.append("")

        # Add equations
        for eq in self.model.equations:
            lines.append(f"  {eq}")
        lines.append("")

        # Add observable definitions
        for obs in self.model.observables:
            lines.append(f"{obs.name} := {obs.formula}")
        lines.append("")

        lines.append("end")
        return "\n".join(lines)

    def simulate_system(self):
        """Simulate the system using tellurium"""
        # Always use true values for simulation
        model_string = self.create_antimony_string(use_true_values=True)
        r = te.loada(model_string)
        
        # Configure integrator for high precision
        r.setIntegrator('cvode')
        r.integrator.setValue('absolute_tolerance', 1e-12)  # Default is usually 1e-6
        r.integrator.setValue('relative_tolerance', 1e-12)  # Default is usually 1e-6
        r.integrator.setValue('stiff', True)
        r.integrator.setValue('variable_step_size', True)
        
        t = np.linspace(self.data_spec.timespan[0], self.data_spec.timespan[1], self.data_spec.n_timepoints)
        y = r.simulate(t[0], t[-1], len(t))
        
        return t, y

    def create_measurement_file(self, t, y) -> pd.DataFrame:
        """Create measurement file with synthetic data"""
        measurements_list = []
        np.random.seed(self.data_spec.random_seed)
        
        # Create a dictionary mapping state names to their column indices
        state_to_col = {state: i+1 for i, state in enumerate(self.model.states)}
        
        # Create a local copy of the simulation data for formula evaluation
        locals_dict = {state: y[:, state_to_col[state]] for state in self.model.states}
        # Add parameters to the evaluation context
        locals_dict.update(self.model.parameters)
        
        for obs in self.model.observables:
            # Evaluate the observable formula
            true_values = eval(obs.formula, {}, locals_dict)
            
            # Apply noise based on the observable's transformation
            if obs.transformation == "log10":
                # For log-transformed data, apply noise in log space
                log_values = np.log10(true_values)
                noise = np.random.normal(0, self.data_spec.noise_level, len(t))
                noisy_values = 10**(log_values + noise)
            else:
                # For linear data, apply additive noise scaled by the mean
                noise_scale = np.mean(np.abs(true_values)) * self.data_spec.noise_level
                noise = np.random.normal(0, noise_scale, len(t))
                noisy_values = true_values + noise
            
            measurements = pd.DataFrame({
                "simulationConditionId": self.data_spec.condition_id,
                "measurement": noisy_values,
                "time": t,
                "observableId": obs.name,
                "observableParameters": "",
                "noiseParameters": self.data_spec.noise_formula,
                "datasetId": self.data_spec.dataset_id,
                "replicateId": 0
            })
            measurements_list.append(measurements)
        
        return pd.concat(measurements_list, ignore_index=True)

    def create_parameter_file(self) -> pd.DataFrame:
        """Create parameter definition file"""
        params = []
        columns = [
            "parameterId",
            "parameterScale",
            "lowerBound",
            "upperBound",
            "nominalValue",
            "estimate",
        ]

        # Add model parameters
        for param in self.model.parameters.keys():
            bounds = self.data_spec.parameter_bounds.get(
                param, self.data_spec.default_bounds
            )
            # Use 1.0 as nominal value only in parameter file when blind=True
            nominal_value = 1.0 if self.data_spec.blind else self.model.parameters[param]
            param_dict = {
                "parameterId": param,
                "parameterScale": bounds.scale,  # Use scale from TOML
                "lowerBound": bounds.lower_bound,
                "upperBound": bounds.upper_bound,
                "nominalValue": nominal_value,
                "estimate": 1,
            }
            params.append(param_dict)

        # Add initial conditions that should be estimated
        for state in self.model.estimate_initial_conditions:
            init_param_id = f"init_{state}"
            bounds = self.data_spec.parameter_bounds.get(
                init_param_id, self.data_spec.default_bounds
            )
            # Use 1.0 as nominal value only in parameter file when blind=True
            nominal_value = 1.0 if self.data_spec.blind else self.model.initial_conditions[state]
            param_dict = {
                "parameterId": init_param_id,
                "parameterScale": "lin",  # Initial conditions typically use linear scale
                "lowerBound": bounds.lower_bound,
                "upperBound": bounds.upper_bound,
                "nominalValue": nominal_value,
                "estimate": 1,
            }
            params.append(param_dict)

        # Add noise parameter - fixed to true value, not estimated
        noise_param_dict = {
            "parameterId": self.data_spec.noise_formula,
            "parameterScale": "lin",  # Changed to linear scale for noise
            "lowerBound": self.data_spec.noise_level,
            "upperBound": self.data_spec.noise_level,
            "nominalValue": self.data_spec.noise_level,
            "estimate": 0,
        }
        params.append(noise_param_dict)

        return pd.DataFrame(params, columns=columns)

    def create_observable_file(self) -> pd.DataFrame:
        """Create observable file according to spec"""
        observables = []
        for obs in self.model.observables:
            observable = {
                "observableId": obs.name,
                "observableName": f"Observable {obs.name}",
                "observableFormula": obs.formula,
                "observableTransformation": obs.transformation,
                "noiseFormula": f"{self.data_spec.noise_formula} * {obs.name}",
                "noiseDistribution": obs.noise_distribution,
            }
            observables.append(observable)
        return pd.DataFrame(observables)

    def create_condition_file(self) -> pd.DataFrame:
        """Create condition file according to spec"""
        return pd.DataFrame(
            {
                "conditionId": [self.data_spec.condition_id],
                "conditionName": [""],  # Optional but included
            }
        )

    def create_yaml(self) -> dict:
        """Create YAML configuration"""
        return {
            "format_version": 1,
            "parameter_file": "parameters.tsv",
            "problems": [
                {
                    "condition_files": ["conditions.tsv"],
                    "measurement_files": ["measurements.tsv"],
                    "observable_files": ["observables.tsv"],
                    "sbml_files": ["model.xml"],
                }
            ],
        }

    def generate_petab_problem(self):
        """Generate complete PETAB problem"""
        os.makedirs(self.data_spec.output_dir, exist_ok=True)

        # Save true parameter values if blind=True
        if self.data_spec.blind:
            true_values = {
                "parameters": self.model.parameters,
                "initial_conditions": {
                    state: self.model.initial_conditions[state]
                    for state in self.model.estimate_initial_conditions
                }
            }
            import json
            with open(os.path.join(self.data_spec.output_dir, "true_values.json"), "w") as f:
                json.dump(true_values, f, indent=4)

        # Convert model to SBML using blinded values when blind=True
        model_string = self.create_antimony_string(use_true_values=False)
        antimony.loadAntimonyString(model_string)
        sbml_string = antimony.getSBMLString("feedback")

        with open(os.path.join(self.data_spec.output_dir, "model.xml"), "w") as f:
            f.write(sbml_string)

        # Generate synthetic data using true parameters
        t, y = self.simulate_system()

        # Create and save all PETAB files
        self.create_measurement_file(t, y).to_csv(
            os.path.join(self.data_spec.output_dir, "measurements.tsv"),
            sep="\t",
            index=False,
        )
        self.create_parameter_file().to_csv(
            os.path.join(self.data_spec.output_dir, "parameters.tsv"),
            sep="\t",
            index=False,
        )
        self.create_observable_file().to_csv(
            os.path.join(self.data_spec.output_dir, "observables.tsv"),
            sep="\t",
            index=False,
        )
        self.create_condition_file().to_csv(
            os.path.join(self.data_spec.output_dir, "conditions.tsv"),
            sep="\t",
            index=False,
        )

        with open(os.path.join(self.data_spec.output_dir, "problem.yaml"), "w") as f:
            yaml.dump(self.create_yaml(), f, sort_keys=False)


def generate_from_toml(toml_file: str):
    """Generate PETab problem from a TOML specification"""
    model, data_spec = parse_toml_model(toml_file)
    generator = PETABGenerator(model, data_spec)
    generator.generate_petab_problem()


if __name__ == "__main__":
    import sys

    if len(sys.argv) != 2:
        print("Usage: python petab_generator.py <model.toml>")
        sys.exit(1)

    generate_from_toml(sys.argv[1])
