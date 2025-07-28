# Polynomial system saved on 2025-07-28T15:08:24.379
using Symbolics
using StaticArrays

# Metadata
# num_variables: 15
# timestamp: 2025-07-28T15:08:24.378
# num_equations: 15

# Variables
varlist_str = """
_tpa_
_tpb_
_t56_x1_t_
_t56_x2_t_
_t56_x3_t_
_t56_x3ˍt_t_
_t56_x3ˍtt_t_
_t56_x3ˍttt_t_
_t56_x3ˍtttt_t_
_t56_x1ˍt_t_
_t56_x2ˍt_t_
_t56_x1ˍtt_t_
_t56_x2ˍtt_t_
_t56_x2ˍttt_t_
_t56_x1ˍttt_t_
"""
@variables _tpa_ _tpb_ _t56_x1_t_ _t56_x2_t_ _t56_x3_t_ _t56_x3ˍt_t_ _t56_x3ˍtt_t_ _t56_x3ˍttt_t_ _t56_x3ˍtttt_t_ _t56_x1ˍt_t_ _t56_x2ˍt_t_ _t56_x1ˍtt_t_ _t56_x2ˍtt_t_ _t56_x2ˍttt_t_ _t56_x1ˍttt_t_
varlist = [_tpa__tpb__t56_x1_t__t56_x2_t__t56_x3_t__t56_x3ˍt_t__t56_x3ˍtt_t__t56_x3ˍttt_t__t56_x3ˍtttt_t__t56_x1ˍt_t__t56_x2ˍt_t__t56_x1ˍtt_t__t56_x2ˍtt_t__t56_x2ˍttt_t__t56_x1ˍttt_t_]

# Polynomial System
poly_system = [
    -4.8443404206365726 + _t56_x3_t_,
    -1.572541393635199 + _t56_x3ˍt_t_,
    -0.14414146823482862 + _t56_x3ˍtt_t_,
    -0.045863484609641354 + _t56_x3ˍttt_t_,
    -0.007434570428500695 + _t56_x3ˍtttt_t_,
    -0.045458943657346595(_t56_x1_t_ + _t56_x2_t_) + _t56_x3ˍt_t_,
    -0.045458943657346595(_t56_x1ˍt_t_ + _t56_x2ˍt_t_) + _t56_x3ˍtt_t_,
    -0.045458943657346595(_t56_x1ˍtt_t_ + _t56_x2ˍtt_t_) + _t56_x3ˍttt_t_,
    -0.045458943657346595(_t56_x1ˍttt_t_ + _t56_x2ˍttt_t_) + _t56_x3ˍtttt_t_,
    _t56_x1ˍt_t_ + _t56_x1_t_*_tpa_,
    _t56_x2ˍt_t_ - _t56_x2_t_*_tpb_,
    _t56_x1ˍtt_t_ + _t56_x1ˍt_t_*_tpa_,
    _t56_x2ˍtt_t_ - _t56_x2ˍt_t_*_tpb_,
    _t56_x2ˍttt_t_ - _t56_x2ˍtt_t_*_tpb_,
    _t56_x1ˍttt_t_ + _t56_x1ˍtt_t_*_tpa_
]

