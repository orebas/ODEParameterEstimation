# Polynomial system saved on 2025-07-28T15:35:54.033
using Symbolics
using StaticArrays

# Metadata
# num_variables: 6
# timestamp: 2025-07-28T15:35:54.032
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
    0.489477980638657 + _t201_x2_t_,
    0.3696817046115698 + _t201_x2ˍt_t_,
    0.46210294572524363 + _t201_x1_t_,
    -0.19579124206866283 + _t201_x1ˍt_t_,
    _t201_x2ˍt_t_ - _t201_x1_t_*_tpb_,
    _t201_x1ˍt_t_ + _t201_x2_t_*_tpa_
]

