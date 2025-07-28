# Polynomial system saved on 2025-07-28T15:17:26.772
using Symbolics
using StaticArrays

# Metadata
# num_variables: 12
# timestamp: 2025-07-28T15:17:26.772
# num_equations: 12

# Variables
varlist_str = """
_tpk21_
_tpke_
_t334_C1_t_
_t334_C2_t_
_t334_C1ˍt_t_
_t334_C1ˍtt_t_
_t334_C2ˍt_t_
_t501_C1_t_
_t501_C2_t_
_t501_C1ˍt_t_
_t501_C1ˍtt_t_
_t501_C2ˍt_t_
"""
@variables _tpk21_ _tpke_ _t334_C1_t_ _t334_C2_t_ _t334_C1ˍt_t_ _t334_C1ˍtt_t_ _t334_C2ˍt_t_ _t501_C1_t_ _t501_C2_t_ _t501_C1ˍt_t_ _t501_C1ˍtt_t_ _t501_C2ˍt_t_
varlist = [_tpk21__tpke__t334_C1_t__t334_C2_t__t334_C1ˍt_t__t334_C1ˍtt_t__t334_C2ˍt_t__t501_C1_t__t501_C2_t__t501_C1ˍt_t__t501_C1ˍtt_t__t501_C2ˍt_t_]

# Polynomial System
poly_system = [
    -0.6258193242352434 + _t334_C1_t_,
    0.027409691689816666 + _t334_C1ˍt_t_,
    -0.0012005619063762206 + _t334_C1ˍtt_t_,
    0.9868711237279278_t334_C1_t_ + _t334_C1ˍt_t_ + _t334_C1_t_*_tpke_ - 0.6614718977146087_t334_C2_t_*_tpk21_,
    0.9868711237279278_t334_C1ˍt_t_ + _t334_C1ˍtt_t_ + _t334_C1ˍt_t_*_tpke_ - 0.6614718977146087_t334_C2ˍt_t_*_tpk21_,
    -1.4919320490221524_t334_C1_t_ + _t334_C2ˍt_t_ + _t334_C2_t_*_tpk21_,
    -0.3100987781611546 + _t501_C1_t_,
    0.013581505285083811 + _t501_C1ˍt_t_,
    -0.0005984315236825523 + _t501_C1ˍtt_t_,
    0.9868711237279278_t501_C1_t_ + _t501_C1ˍt_t_ + _t501_C1_t_*_tpke_ - 0.6614718977146087_t501_C2_t_*_tpk21_,
    0.9868711237279278_t501_C1ˍt_t_ + _t501_C1ˍtt_t_ + _t501_C1ˍt_t_*_tpke_ - 0.6614718977146087_t501_C2ˍt_t_*_tpk21_,
    -1.4919320490221524_t501_C1_t_ + _t501_C2ˍt_t_ + _t501_C2_t_*_tpk21_
]

