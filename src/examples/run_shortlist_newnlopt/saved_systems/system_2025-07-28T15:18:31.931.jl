# Polynomial system saved on 2025-07-28T15:18:31.931
using Symbolics
using StaticArrays

# Metadata
# num_variables: 10
# timestamp: 2025-07-28T15:18:31.931
# num_equations: 10

# Variables
varlist_str = """
_tpa_
_tpb_
_t390_x1_t_
_t390_x2_t_
_t390_x1ˍt_t_
_t390_x2ˍt_t_
_t501_x1_t_
_t501_x2_t_
_t501_x1ˍt_t_
_t501_x2ˍt_t_
"""
@variables _tpa_ _tpb_ _t390_x1_t_ _t390_x2_t_ _t390_x1ˍt_t_ _t390_x2ˍt_t_ _t501_x1_t_ _t501_x2_t_ _t501_x1ˍt_t_ _t501_x2ˍt_t_
varlist = [_tpa__tpb__t390_x1_t__t390_x2_t__t390_x1ˍt_t__t390_x2ˍt_t__t501_x1_t__t501_x2_t__t501_x1ˍt_t__t501_x2ˍt_t_]

# Polynomial System
poly_system = [
    5.186905527956044 + 3.0_t390_x1_t_ - 0.25_t390_x2_t_,
    3.481190517089488 + 2.0_t390_x1_t_ + 0.5_t390_x2_t_,
    0.6648458825347462 + 2.0_t390_x1ˍt_t_ + 0.5_t390_x2ˍt_t_,
    _t390_x1ˍt_t_ + _t390_x2_t_*_tpa_,
    _t390_x2ˍt_t_ - _t390_x1_t_*_tpb_,
    3.7943653804104054 + 3.0_t501_x1_t_ - 0.25_t501_x2_t_,
    3.5076082792296086 + 2.0_t501_x1_t_ + 0.5_t501_x2_t_,
    -0.61881958879798 + 2.0_t501_x1ˍt_t_ + 0.5_t501_x2ˍt_t_,
    _t501_x1ˍt_t_ + _t501_x2_t_*_tpa_,
    _t501_x2ˍt_t_ - _t501_x1_t_*_tpb_
]

