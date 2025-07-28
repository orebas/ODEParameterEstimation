# Polynomial system saved on 2025-07-28T15:08:49.695
using Symbolics
using StaticArrays

# Metadata
# num_variables: 15
# timestamp: 2025-07-28T15:08:49.695
# num_equations: 15

# Variables
varlist_str = """
_tpa_
_tpb_
_t223_x1_t_
_t223_x2_t_
_t223_x3_t_
_t223_x3ˍt_t_
_t223_x3ˍtt_t_
_t223_x3ˍttt_t_
_t223_x3ˍtttt_t_
_t223_x1ˍt_t_
_t223_x2ˍt_t_
_t223_x1ˍtt_t_
_t223_x2ˍtt_t_
_t223_x2ˍttt_t_
_t223_x1ˍttt_t_
"""
@variables _tpa_ _tpb_ _t223_x1_t_ _t223_x2_t_ _t223_x3_t_ _t223_x3ˍt_t_ _t223_x3ˍtt_t_ _t223_x3ˍttt_t_ _t223_x3ˍtttt_t_ _t223_x1ˍt_t_ _t223_x2ˍt_t_ _t223_x1ˍtt_t_ _t223_x2ˍtt_t_ _t223_x2ˍttt_t_ _t223_x1ˍttt_t_
varlist = [_tpa__tpb__t223_x1_t__t223_x2_t__t223_x3_t__t223_x3ˍt_t__t223_x3ˍtt_t__t223_x3ˍttt_t__t223_x3ˍtttt_t__t223_x1ˍt_t__t223_x2ˍt_t__t223_x1ˍtt_t__t223_x2ˍtt_t__t223_x2ˍttt_t__t223_x1ˍttt_t_]

# Polynomial System
poly_system = [
    -7.709694997642155 + _t223_x3_t_,
    -1.8835865589495562 + _t223_x3ˍt_t_,
    -0.23255216946536475 + _t223_x3ˍtt_t_,
    -0.06092932571845007 + _t223_x3ˍttt_t_,
    -0.010756861486426962 + _t223_x3ˍtttt_t_,
    -0.665021003154237(_t223_x1_t_ + _t223_x2_t_) + _t223_x3ˍt_t_,
    -0.665021003154237(_t223_x1ˍt_t_ + _t223_x2ˍt_t_) + _t223_x3ˍtt_t_,
    -0.665021003154237(_t223_x1ˍtt_t_ + _t223_x2ˍtt_t_) + _t223_x3ˍttt_t_,
    -0.665021003154237(_t223_x1ˍttt_t_ + _t223_x2ˍttt_t_) + _t223_x3ˍtttt_t_,
    _t223_x1ˍt_t_ + _t223_x1_t_*_tpa_,
    _t223_x2ˍt_t_ - _t223_x2_t_*_tpb_,
    _t223_x1ˍtt_t_ + _t223_x1ˍt_t_*_tpa_,
    _t223_x2ˍtt_t_ - _t223_x2ˍt_t_*_tpb_,
    _t223_x2ˍttt_t_ - _t223_x2ˍtt_t_*_tpb_,
    _t223_x1ˍttt_t_ + _t223_x1ˍtt_t_*_tpa_
]

