# Polynomial system saved on 2025-07-28T15:36:05.420
using Symbolics
using StaticArrays

# Metadata
# num_variables: 6
# timestamp: 2025-07-28T15:36:05.420
# num_equations: 6

# Variables
varlist_str = """
_tpa_
_tpb_
_t22_x1_t_
_t22_x2_t_
_t22_x1ˍt_t_
_t22_x2ˍt_t_
"""
@variables _tpa_ _tpb_ _t22_x1_t_ _t22_x2_t_ _t22_x1ˍt_t_ _t22_x2ˍt_t_
varlist = [_tpa__tpb__t22_x1_t__t22_x2_t__t22_x1ˍt_t__t22_x2ˍt_t_]

# Polynomial System
poly_system = [
    -1.0455351753208362 + 3.0_t22_x1_t_ - 0.25_t22_x2_t_,
    2.9000334441566746 + 3.0_t22_x1ˍt_t_ - 0.25_t22_x2ˍt_t_,
    -2.247889763788228 + 2.0_t22_x1_t_ + 0.5_t22_x2_t_,
    1.6440915684416664 + 2.0_t22_x1ˍt_t_ + 0.5_t22_x2ˍt_t_,
    _t22_x1ˍt_t_ + _t22_x2_t_*_tpa_,
    _t22_x2ˍt_t_ - _t22_x1_t_*_tpb_
]

