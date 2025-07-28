# Polynomial system saved on 2025-07-28T15:35:52.591
using Symbolics
using StaticArrays

# Metadata
# num_variables: 6
# timestamp: 2025-07-28T15:35:52.590
# num_equations: 6

# Variables
varlist_str = """
_tpa_
_tpb_
_t112_x1_t_
_t112_x2_t_
_t112_x2ˍt_t_
_t112_x1ˍt_t_
"""
@variables _tpa_ _tpb_ _t112_x1_t_ _t112_x2_t_ _t112_x2ˍt_t_ _t112_x1ˍt_t_
varlist = [_tpa__tpb__t112_x1_t__t112_x2_t__t112_x2ˍt_t__t112_x1ˍt_t_]

# Polynomial System
poly_system = [
    -0.4716127200707887 + _t112_x2_t_,
    0.3770404531004173 + _t112_x2ˍt_t_,
    0.47130055927002507 + _t112_x1_t_,
    0.18864509329030696 + _t112_x1ˍt_t_,
    _t112_x2ˍt_t_ - _t112_x1_t_*_tpb_,
    _t112_x1ˍt_t_ + _t112_x2_t_*_tpa_
]

