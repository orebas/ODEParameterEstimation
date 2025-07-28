# Polynomial system saved on 2025-07-28T15:31:52
using Symbolics
using StaticArrays

# Metadata
# num_variables: 6
# timestamp: 2025-07-28T15:31:51.999
# num_equations: 6

# Variables
varlist_str = """
_tpa_
_tpb_
_t390_x1_t_
_t390_x2_t_
_t390_x2ˍt_t_
_t390_x1ˍt_t_
"""
@variables _tpa_ _tpb_ _t390_x1_t_ _t390_x2_t_ _t390_x2ˍt_t_ _t390_x1ˍt_t_
varlist = [_tpa__tpb__t390_x1_t__t390_x2_t__t390_x2ˍt_t__t390_x1ˍt_t_]

# Polynomial System
poly_system = [
    -0.57084526567516 + _t390_x2_t_,
    -0.5132939482683674 + _t390_x2ˍt_t_,
    1.8075635671720176 + _t390_x1_t_,
    -0.5708452585874414 + _t390_x1ˍt_t_,
    _t390_x1_t_ + _t390_x2ˍt_t_ + (-1 + _t390_x1_t_^2)*_t390_x2_t_*_tpb_,
    _t390_x1ˍt_t_ - _t390_x2_t_*_tpa_
]

