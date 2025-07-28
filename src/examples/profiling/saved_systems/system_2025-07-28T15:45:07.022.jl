# Polynomial system saved on 2025-07-28T15:45:07.022
using Symbolics
using StaticArrays

# Metadata
# num_variables: 6
# timestamp: 2025-07-28T15:45:07.022
# num_equations: 6

# Variables
varlist_str = """
_tpa_
_tpb_
_t201_x1_t_
_t201_x2_t_
_t201_x2ˍt_t_
_t201_x1ˍt_t_
"""
@variables _tpa_ _tpb_ _t201_x1_t_ _t201_x2_t_ _t201_x2ˍt_t_ _t201_x1ˍt_t_
varlist = [_tpa__tpb__t201_x1_t__t201_x2_t__t201_x2ˍt_t__t201_x1ˍt_t_]

# Polynomial System
poly_system = [
    0.4894780275343179 + _t201_x2_t_,
    0.36968257001568977 + _t201_x2ˍt_t_,
    0.4621029414983119 + _t201_x1_t_,
    -0.19579139290319286 + _t201_x1ˍt_t_,
    _t201_x2ˍt_t_ - _t201_x1_t_*_tpb_,
    _t201_x1ˍt_t_ + _t201_x2_t_*_tpa_
]

