# Polynomial system saved on 2025-07-28T15:45:01.559
using Symbolics
using StaticArrays

# Metadata
# num_variables: 6
# timestamp: 2025-07-28T15:45:01.558
# num_equations: 6

# Variables
varlist_str = """
_tpa_
_tpb_
_t134_x1_t_
_t134_x2_t_
_t134_x2ˍt_t_
_t134_x1ˍt_t_
"""
@variables _tpa_ _tpb_ _t134_x1_t_ _t134_x2_t_ _t134_x2ˍt_t_ _t134_x1ˍt_t_
varlist = [_tpa__tpb__t134_x1_t__t134_x2_t__t134_x2ˍt_t__t134_x1ˍt_t_]

# Polynomial System
poly_system = [
    -0.24492741191511602 + _t134_x2_t_,
    0.4406095988987471 + _t134_x2ˍt_t_,
    0.550761999407922 + _t134_x1_t_,
    0.09797096452052292 + _t134_x1ˍt_t_,
    _t134_x2ˍt_t_ - _t134_x1_t_*_tpb_,
    _t134_x1ˍt_t_ + _t134_x2_t_*_tpa_
]

