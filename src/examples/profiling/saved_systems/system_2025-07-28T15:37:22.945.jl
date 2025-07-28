# Polynomial system saved on 2025-07-28T15:37:22.945
using Symbolics
using StaticArrays

# Metadata
# num_variables: 9
# timestamp: 2025-07-28T15:37:22.945
# num_equations: 9

# Variables
varlist_str = """
_tpa_
_tpb_
_tpc_
_t22_x1_t_
_t22_x2_t_
_t22_x3_t_
_t22_x2ˍt_t_
_t22_x3ˍt_t_
_t22_x1ˍt_t_
"""
@variables _tpa_ _tpb_ _tpc_ _t22_x1_t_ _t22_x2_t_ _t22_x3_t_ _t22_x2ˍt_t_ _t22_x3ˍt_t_ _t22_x1ˍt_t_
varlist = [_tpa__tpb__tpc__t22_x1_t__t22_x2_t__t22_x3_t__t22_x2ˍt_t__t22_x3ˍt_t__t22_x1ˍt_t_]

# Polynomial System
poly_system = [
    -21.906862107974693 + _t22_x2_t_^3,
    8.680458399520965 + 3(_t22_x2_t_^2)*_t22_x2ˍt_t_,
    -50.53478213203773 + _t22_x3_t_^3,
    22.732160503697926 + 3(_t22_x3_t_^2)*_t22_x3ˍt_t_,
    -6.3097833176423705 + _t22_x1_t_^3,
    2.866316124256852 + 3(_t22_x1_t_^2)*_t22_x1ˍt_t_,
    _t22_x2ˍt_t_ + _t22_x1_t_*_tpb_,
    _t22_x3ˍt_t_ + _t22_x1_t_*_tpc_,
    _t22_x1ˍt_t_ + _t22_x2_t_*_tpa_
]

