# Polynomial system saved on 2025-07-28T15:17:31.124
using Symbolics
using StaticArrays

# Metadata
# num_variables: 7
# timestamp: 2025-07-28T15:17:31.123
# num_equations: 12

# Variables
varlist_str = """
_tpk21_
_tpke_
_t501_C1_t_
_t501_C2_t_
_t501_C1ˍt_t_
_t501_C1ˍtt_t_
_t501_C2ˍt_t_
"""
@variables _tpk21_ _tpke_ _t501_C1_t_ _t501_C2_t_ _t501_C1ˍt_t_ _t501_C1ˍtt_t_ _t501_C2ˍt_t_
varlist = [_tpk21__tpke__t501_C1_t__t501_C2_t__t501_C1ˍt_t__t501_C1ˍtt_t__t501_C2ˍt_t_]

# Polynomial System
poly_system = [
    -0.31009879947306995 + _t501_C1_t_,
    0.013581245989289645 + _t501_C1ˍt_t_,
    -0.000602680355662315 + _t501_C1ˍtt_t_,
    0.24192829009584493_t501_C1_t_ + _t501_C1ˍt_t_ + _t501_C1_t_*_tpke_ - 89.58569672114265_t501_C2_t_*_tpk21_,
    0.24192829009584493_t501_C1ˍt_t_ + _t501_C1ˍtt_t_ + _t501_C1ˍt_t_*_tpke_ - 89.58569672114265_t501_C2ˍt_t_*_tpk21_,
    -0.002700523620962683_t501_C1_t_ + _t501_C2ˍt_t_ + _t501_C2_t_*_tpk21_,
    -0.31009879947306995 + _t501_C1_t_,
    0.013581245989289645 + _t501_C1ˍt_t_,
    -0.000602680355662315 + _t501_C1ˍtt_t_,
    0.24192829009584493_t501_C1_t_ + _t501_C1ˍt_t_ + _t501_C1_t_*_tpke_ - 89.58569672114265_t501_C2_t_*_tpk21_,
    0.24192829009584493_t501_C1ˍt_t_ + _t501_C1ˍtt_t_ + _t501_C1ˍt_t_*_tpke_ - 89.58569672114265_t501_C2ˍt_t_*_tpk21_,
    -0.002700523620962683_t501_C1_t_ + _t501_C2ˍt_t_ + _t501_C2_t_*_tpk21_
]

