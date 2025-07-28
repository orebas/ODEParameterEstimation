# Polynomial system saved on 2025-07-28T15:47:19.831
using Symbolics
using StaticArrays

# Metadata
# num_variables: 9
# timestamp: 2025-07-28T15:47:19.831
# num_equations: 9

# Variables
varlist_str = """
_tpa_
_tpb_
_tpc_
_t201_x1_t_
_t201_x2_t_
_t201_x3_t_
_t201_x2ˍt_t_
_t201_x3ˍt_t_
_t201_x1ˍt_t_
"""
@variables _tpa_ _tpb_ _tpc_ _t201_x1_t_ _t201_x2_t_ _t201_x3_t_ _t201_x2ˍt_t_ _t201_x3ˍt_t_ _t201_x1ˍt_t_
varlist = [_tpa__tpb__tpc__t201_x1_t__t201_x2_t__t201_x3_t__t201_x2ˍt_t__t201_x3ˍt_t__t201_x1ˍt_t_]

# Polynomial System
poly_system = [
    -4.180223076446074 + _t201_x2_t_^3,
    1.3904192185583724 + 3(_t201_x2_t_^2)*_t201_x2ˍt_t_,
    -7.037470487323674 + _t201_x3_t_^3,
    2.9515148019723574 + 3(_t201_x3_t_^2)*_t201_x3ˍt_t_,
    -0.7121725690490956 + _t201_x1_t_^3,
    0.3854029111975271 + 3(_t201_x1_t_^2)*_t201_x1ˍt_t_,
    _t201_x2ˍt_t_ + _t201_x1_t_*_tpb_,
    _t201_x3ˍt_t_ + _t201_x1_t_*_tpc_,
    _t201_x1ˍt_t_ + _t201_x2_t_*_tpa_
]

