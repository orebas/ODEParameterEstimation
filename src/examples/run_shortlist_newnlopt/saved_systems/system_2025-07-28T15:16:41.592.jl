# Polynomial system saved on 2025-07-28T15:16:41.592
using Symbolics
using StaticArrays

# Metadata
# num_variables: 9
# timestamp: 2025-07-28T15:16:41.592
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
    -2.095325985946501 + _t56_C1_t_,
    0.15773097148846002 + _t56_C1ˍt_t_,
    -0.0633812986206735 + _t56_C1ˍtt_t_,
    0.0511408773537827 + _t56_C1ˍttt_t_,
    0.8017563673479196_t56_C1_t_ + _t56_C1ˍt_t_ + _t56_C1_t_*_tpke_ - 1.1362638384010941_t56_C2_t_*_tpk21_,
    0.8017563673479196_t56_C1ˍt_t_ + _t56_C1ˍtt_t_ + _t56_C1ˍt_t_*_tpke_ - 1.1362638384010941_t56_C2ˍt_t_*_tpk21_,
    0.8017563673479196_t56_C1ˍtt_t_ + _t56_C1ˍttt_t_ + _t56_C1ˍtt_t_*_tpke_ - 1.1362638384010941_t56_C2ˍtt_t_*_tpk21_,
    -0.7056075712803812_t56_C1_t_ + _t56_C2ˍt_t_ + _t56_C2_t_*_tpk21_,
    -0.7056075712803812_t56_C1ˍt_t_ + _t56_C2ˍtt_t_ + _t56_C2ˍt_t_*_tpk21_
]

