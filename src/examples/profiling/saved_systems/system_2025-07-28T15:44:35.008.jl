# Polynomial system saved on 2025-07-28T15:44:35.008
using Symbolics
using StaticArrays

# Metadata
# num_variables: 6
# timestamp: 2025-07-28T15:44:35.008
# num_equations: 6

# Variables
varlist_str = """
_tpa_
_tpb_
_t45_x1_t_
_t45_x2_t_
_t45_x2ˍt_t_
_t45_x1ˍt_t_
"""
@variables _tpa_ _tpb_ _t45_x1_t_ _t45_x2_t_ _t45_x2ˍt_t_ _t45_x1ˍt_t_
varlist = [_tpa__tpb__t45_x1_t__t45_x2_t__t45_x2ˍt_t__t45_x1ˍt_t_]

# Polynomial System
poly_system = [
    -0.816473915149911 + _t45_x2_t_,
    0.003455571946755519 + _t45_x2ˍt_t_,
    0.00431932887677261 + _t45_x1_t_,
    0.32658956589790983 + _t45_x1ˍt_t_,
    _t45_x2ˍt_t_ - _t45_x1_t_*_tpb_,
    _t45_x1ˍt_t_ + _t45_x2_t_*_tpa_
]

