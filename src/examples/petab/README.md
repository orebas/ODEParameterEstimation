# PEtab Integration Workflow

This directory contains tools and examples for converting ODEParameterEstimation models to and from the PEtab format.

## Directory Structure

- `models/` - PEtab model files and directories
- `tomls/` - Intermediate TOML representations of models
- `examples/` - Example PEtab files and usage demonstrations
- `model2toml/` - Julia tools for converting ODEParameterEstimation models to TOML
- `toml2petab/` - Python tools for converting TOML to PEtab format
- `petab-ODEPE.jl` - Main PEtab integration file

## Workflow

The conversion between ODEParameterEstimation and PEtab follows this pipeline:

1. **ODEParameterEstimation Model** (`../models/`)
   - Native Julia model definitions
   - Defines ODEs, parameters, states, and observables

2. **↓ Convert to TOML** (`model2toml/`)
   - Julia script converts model to TOML format
   - Preserves all model information in a standard format

3. **TOML Representation** (`tomls/`)
   - Intermediate representation of the model
   - Human-readable and language-agnostic

4. **↓ Convert to PEtab** (`toml2petab/`)
   - Python script converts TOML to PEtab format
   - Generates all required PEtab files (YAML, CSV, etc.)

5. **PEtab Format** (`models/`)
   - Standard PEtab directory structure
   - Compatible with PEtab tools ecosystem

6. **↓ Load and Verify**
   - Julia loader imports PEtab format
   - Verifies equivalence with original model

## Usage

1. To convert models to TOML:
   ```julia
   cd("examples/petab/model2toml")
   include("generate_petab_tomls.jl")
   ```
   This will generate TOML files in the `tomls/` directory for all available models.

2. To convert TOML to PEtab:
   ```bash
   cd examples/petab/toml2petab
   python generate_petab.py ../tomls/model_name.toml
   ```
   This will create a PEtab directory in `models/` for the specified model.

3. To load and verify:
   ```julia
   using ODEParameterEstimation
   include("examples/petab/petab-ODEPE.jl")
   
   # Load original model
   model = simple()  # or any other model function
   
   # Load PEtab version
   petab_model = load_petab("examples/petab/models/simple")
   
   # Compare the models
   verify_models_equivalent(model, petab_model)
   ```

## Adding New Models

1. Create your model in `../models/`:
   - Add it to the appropriate category file
   - Follow the existing model structure
   - Make sure it returns a `ParameterEstimationProblem`

2. Run the conversion tools:
   ```julia
   # Generate TOML
   include("examples/petab/model2toml/generate_petab_tomls.jl")
   
   # Convert to PEtab (in shell)
   cd examples/petab/toml2petab
   python generate_petab.py ../tomls/your_model.toml
   ```

3. Verify the conversion:
   ```julia
   # In Julia REPL
   include("examples/petab/petab-ODEPE.jl")
   verify_models_equivalent(your_model(), load_petab("examples/petab/models/your_model"))
   ```

## Requirements

- Julia requirements:
  - ODEParameterEstimation
  - ModelingToolkit
  - TOML

- Python requirements:
  - petab
  - yaml
  - pandas 