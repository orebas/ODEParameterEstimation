# Polynomial system saved on 2025-07-28T15:17:25.195
using Symbolics
using StaticArrays

# Metadata
# num_variables: 12
# timestamp: 2025-07-28T15:17:25.184
# num_equations: 12

# Variables
varlist_str = """
_tpk21_
_tpke_
_t278_C1_t_
_t278_C2_t_
_t278_C1ˍt_t_
_t278_C1ˍtt_t_
_t278_C2ˍt_t_
_t445_C1_t_
_t445_C2_t_
_t445_C1ˍt_t_
_t445_C1ˍtt_t_
_t445_C2ˍt_t_
"""
@variables _tpk21_ _tpke_ _t278_C1_t_ _t278_C2_t_ _t278_C1ˍt_t_ _t278_C1ˍtt_t_ _t278_C2ˍt_t_ _t445_C1_t_ _t445_C2_t_ _t445_C1ˍt_t_ _t445_C1ˍtt_t_ _t445_C2ˍt_t_
varlist = [_tpk21__tpke__t278_C1_t__t278_C2_t__t278_C1ˍt_t__t278_C1ˍtt_t__t278_C2ˍt_t__t445_C1_t__t445_C2_t__t445_C1ˍt_t__t445_C1ˍtt_t__t445_C2ˍt_t_]

# Polynomial System
poly_system = [
    -0.7919673438001575 + _t278_C1_t_,
    0.034686651789577645 + _t278_C1ˍt_t_,
    -0.0015191388095915138 + _t278_C1ˍtt_t_,
    0.48723651598420514_t278_C1_t_ + _t278_C1ˍt_t_ + _t278_C1_t_*_tpke_ - 0.4968391187920921_t278_C2_t_*_tpk21_,
    0.48723651598420514_t278_C1ˍt_t_ + _t278_C1ˍtt_t_ + _t278_C1ˍt_t_*_tpke_ - 0.4968391187920921_t278_C2ˍt_t_*_tpk21_,
    -0.9806726112242677_t278_C1_t_ + _t278_C2ˍt_t_ + _t278_C2_t_*_tpk21_,
    -0.3924265401318551 + _t445_C1_t_,
    0.01718751822701439 + _t445_C1ˍt_t_,
    -0.0007527619550116294 + _t445_C1ˍtt_t_,
    0.48723651598420514_t445_C1_t_ + _t445_C1ˍt_t_ + _t445_C1_t_*_tpke_ - 0.4968391187920921_t445_C2_t_*_tpk21_,
    0.48723651598420514_t445_C1ˍt_t_ + _t445_C1ˍtt_t_ + _t445_C1ˍt_t_*_tpke_ - 0.4968391187920921_t445_C2ˍt_t_*_tpk21_,
    -0.9806726112242677_t445_C1_t_ + _t445_C2ˍt_t_ + _t445_C2_t_*_tpk21_
]

