# Polynomial system saved on 2025-07-28T15:17:34.348
using Symbolics
using StaticArrays

# Metadata
# num_variables: 6
# timestamp: 2025-07-28T15:17:34.339
# num_equations: 6

# Variables
varlist_str = """
_tpa_
_tpb_
_t56_x1_t_
_t56_x2_t_
_t56_x1ˍt_t_
_t56_x2ˍt_t_
"""
@variables _tpa_ _tpb_ _t56_x1_t_ _t56_x2_t_ _t56_x1ˍt_t_ _t56_x2ˍt_t_
varlist = [_tpa__tpb__t56_x1_t__t56_x2_t__t56_x1ˍt_t__t56_x2ˍt_t_]

# Polynomial System
poly_system = [
    -0.9729321689728443 + 3.0_t56_x1_t_ - 0.25_t56_x2_t_,
    2.908107496049793 + 3.0_t56_x1ˍt_t_ - 0.25_t56_x2ˍt_t_,
    -2.206564090407687 + 2.0_t56_x1_t_ + 0.5_t56_x2_t_,
    1.6619097553449234 + 2.0_t56_x1ˍt_t_ + 0.5_t56_x2ˍt_t_,
    _t56_x1ˍt_t_ + _t56_x2_t_*_tpa_,
    _t56_x2ˍt_t_ - _t56_x1_t_*_tpb_
]

