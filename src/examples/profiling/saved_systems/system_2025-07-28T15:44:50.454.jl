# Polynomial system saved on 2025-07-28T15:44:50.459
using Symbolics
using StaticArrays

# Metadata
# num_variables: 6
# timestamp: 2025-07-28T15:44:50.454
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
    0.4894780207941088 + _t201_x2_t_,
    0.36968235755858037 + _t201_x2ˍt_t_,
    0.4621029469498553 + _t201_x1_t_,
    -0.19579120831914665 + _t201_x1ˍt_t_,
    _t201_x2ˍt_t_ - _t201_x1_t_*_tpb_,
    _t201_x1ˍt_t_ + _t201_x2_t_*_tpa_
]

