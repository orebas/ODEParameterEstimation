# Polynomial system saved on 2025-07-28T15:18:04.053
using Symbolics
using StaticArrays

# Metadata
# num_variables: 6
# timestamp: 2025-07-28T15:18:04.053
# num_equations: 6

# Variables
varlist_str = """
_tpa_
_tpb_
_t390_x1_t_
_t390_x2_t_
_t390_x1ˍt_t_
_t390_x2ˍt_t_
"""
@variables _tpa_ _tpb_ _t390_x1_t_ _t390_x2_t_ _t390_x1ˍt_t_ _t390_x2ˍt_t_
varlist = [_tpa__tpb__t390_x1_t__t390_x2_t__t390_x1ˍt_t__t390_x2ˍt_t_]

# Polynomial System
poly_system = [
    5.186905536450743 + 3.0_t390_x1_t_ - 0.25_t390_x2_t_,
    -0.38823130242581716 + 3.0_t390_x1ˍt_t_ - 0.25_t390_x2ˍt_t_,
    3.481190498956674 + 2.0_t390_x1_t_ + 0.5_t390_x2_t_,
    0.6648458881177131 + 2.0_t390_x1ˍt_t_ + 0.5_t390_x2ˍt_t_,
    _t390_x1ˍt_t_ + _t390_x2_t_*_tpa_,
    _t390_x2ˍt_t_ - _t390_x1_t_*_tpb_
]

