# Polynomial system saved on 2025-07-28T15:16:43.789
using Symbolics
using StaticArrays

# Metadata
# num_variables: 9
# timestamp: 2025-07-28T15:16:43.789
# num_equations: 9

# Variables
varlist_str = """
_tpk21_
_tpke_
_t56_C1_t_
_t56_C2_t_
_t56_C1ˍt_t_
_t56_C1ˍtt_t_
_t56_C1ˍttt_t_
_t56_C2ˍt_t_
_t56_C2ˍtt_t_
"""
@variables _tpk21_ _tpke_ _t56_C1_t_ _t56_C2_t_ _t56_C1ˍt_t_ _t56_C1ˍtt_t_ _t56_C1ˍttt_t_ _t56_C2ˍt_t_ _t56_C2ˍtt_t_
varlist = [_tpk21__tpke__t56_C1_t__t56_C2_t__t56_C1ˍt_t__t56_C1ˍtt_t__t56_C1ˍttt_t__t56_C2ˍt_t__t56_C2ˍtt_t_]

# Polynomial System
poly_system = [
    -2.095325976516726 + _t56_C1_t_,
    0.15773144850936568 + _t56_C1ˍt_t_,
    -0.06338150644254692 + _t56_C1ˍtt_t_,
    0.05112801696864823 + _t56_C1ˍttt_t_,
    0.859244994082393_t56_C1_t_ + _t56_C1ˍt_t_ + _t56_C1_t_*_tpke_ - 0.9522297161244431_t56_C2_t_*_tpk21_,
    0.859244994082393_t56_C1ˍt_t_ + _t56_C1ˍtt_t_ + _t56_C1ˍt_t_*_tpke_ - 0.9522297161244431_t56_C2ˍt_t_*_tpk21_,
    0.859244994082393_t56_C1ˍtt_t_ + _t56_C1ˍttt_t_ + _t56_C1ˍtt_t_*_tpke_ - 0.9522297161244431_t56_C2ˍtt_t_*_tpk21_,
    -0.9023505353093829_t56_C1_t_ + _t56_C2ˍt_t_ + _t56_C2_t_*_tpk21_,
    -0.9023505353093829_t56_C1ˍt_t_ + _t56_C2ˍtt_t_ + _t56_C2ˍt_t_*_tpk21_
]

