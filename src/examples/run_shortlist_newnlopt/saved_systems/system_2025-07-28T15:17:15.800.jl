# Polynomial system saved on 2025-07-28T15:17:15.800
using Symbolics
using StaticArrays

# Metadata
# num_variables: 12
# timestamp: 2025-07-28T15:17:15.800
# num_equations: 12

# Variables
varlist_str = """
_tpk21_
_tpke_
_t56_C1_t_
_t56_C2_t_
_t56_C1ˍt_t_
_t56_C1ˍtt_t_
_t56_C2ˍt_t_
_t223_C1_t_
_t223_C2_t_
_t223_C1ˍt_t_
_t223_C1ˍtt_t_
_t223_C2ˍt_t_
"""
@variables _tpk21_ _tpke_ _t56_C1_t_ _t56_C2_t_ _t56_C1ˍt_t_ _t56_C1ˍtt_t_ _t56_C2ˍt_t_ _t223_C1_t_ _t223_C2_t_ _t223_C1ˍt_t_ _t223_C1ˍtt_t_ _t223_C2ˍt_t_
varlist = [_tpk21__tpke__t56_C1_t__t56_C2_t__t56_C1ˍt_t__t56_C1ˍtt_t__t56_C2ˍt_t__t223_C1_t__t223_C2_t__t223_C1ˍt_t__t223_C1ˍtt_t__t223_C2ˍt_t_]

# Polynomial System
poly_system = [
    -2.0953260048060516 + _t56_C1_t_,
    0.15773074790632827 + _t56_C1ˍt_t_,
    -0.06338092388461436 + _t56_C1ˍtt_t_,
    0.6915536352273473_t56_C1_t_ + _t56_C1ˍt_t_ + _t56_C1_t_*_tpke_ - 3.454491883409332_t56_C2_t_*_tpk21_,
    0.6915536352273473_t56_C1ˍt_t_ + _t56_C1ˍtt_t_ + _t56_C1ˍt_t_*_tpke_ - 3.454491883409332_t56_C2ˍt_t_*_tpk21_,
    -0.20018968304676812_t56_C1_t_ + _t56_C2ˍt_t_ + _t56_C2_t_*_tpk21_,
    -0.9980208014465461 + _t223_C1_t_,
    0.0437114887752164 + _t223_C1ˍt_t_,
    -0.001914441947428431 + _t223_C1ˍtt_t_,
    0.6915536352273473_t223_C1_t_ + _t223_C1ˍt_t_ + _t223_C1_t_*_tpke_ - 3.454491883409332_t223_C2_t_*_tpk21_,
    0.6915536352273473_t223_C1ˍt_t_ + _t223_C1ˍtt_t_ + _t223_C1ˍt_t_*_tpke_ - 3.454491883409332_t223_C2ˍt_t_*_tpk21_,
    -0.20018968304676812_t223_C1_t_ + _t223_C2ˍt_t_ + _t223_C2_t_*_tpk21_
]

