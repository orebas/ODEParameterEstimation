# Polynomial system saved on 2025-07-28T15:35:57.391
using Symbolics
using StaticArrays

# Metadata
# num_variables: 6
# timestamp: 2025-07-28T15:35:57.390
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
    -0.8164739333886809 + _t45_x2_t_,
    0.0034554325048293155 + _t45_x2ˍt_t_,
    0.004319311153350436 + _t45_x1_t_,
    0.32658956488190827 + _t45_x1ˍt_t_,
    _t45_x2ˍt_t_ - _t45_x1_t_*_tpb_,
    _t45_x1ˍt_t_ + _t45_x2_t_*_tpa_
]

