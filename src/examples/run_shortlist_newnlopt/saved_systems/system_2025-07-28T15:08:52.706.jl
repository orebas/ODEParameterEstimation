# Polynomial system saved on 2025-07-28T15:08:52.707
using Symbolics
using StaticArrays

# Metadata
# num_variables: 15
# timestamp: 2025-07-28T15:08:52.706
# num_equations: 15

# Variables
varlist_str = """
_tpa_
_tpb_
_t445_x1_t_
_t445_x2_t_
_t445_x3_t_
_t445_x3ˍt_t_
_t445_x3ˍtt_t_
_t445_x3ˍttt_t_
_t445_x3ˍtttt_t_
_t445_x1ˍt_t_
_t445_x2ˍt_t_
_t445_x1ˍtt_t_
_t445_x2ˍtt_t_
_t445_x2ˍttt_t_
_t445_x1ˍttt_t_
"""
@variables _tpa_ _tpb_ _t445_x1_t_ _t445_x2_t_ _t445_x3_t_ _t445_x3ˍt_t_ _t445_x3ˍtt_t_ _t445_x3ˍttt_t_ _t445_x3ˍtttt_t_ _t445_x1ˍt_t_ _t445_x2ˍt_t_ _t445_x1ˍtt_t_ _t445_x2ˍtt_t_ _t445_x2ˍttt_t_ _t445_x1ˍttt_t_
varlist = [_tpa__tpb__t445_x1_t__t445_x2_t__t445_x3_t__t445_x3ˍt_t__t445_x3ˍtt_t__t445_x3ˍttt_t__t445_x3ˍtttt_t__t445_x1ˍt_t__t445_x2ˍt_t__t445_x1ˍtt_t__t445_x2ˍtt_t__t445_x2ˍttt_t__t445_x1ˍttt_t_]

# Polynomial System
poly_system = [
    -12.587396555949873 + _t445_x3_t_,
    -2.572116654932286 + _t445_x3ˍt_t_,
    -0.3989601142844096 + _t445_x3ˍtt_t_,
    -0.0913662723841244 + _t445_x3ˍttt_t_,
    -0.017235028720096662 + _t445_x3ˍtttt_t_,
    -0.2330495234587907(_t445_x1_t_ + _t445_x2_t_) + _t445_x3ˍt_t_,
    -0.2330495234587907(_t445_x1ˍt_t_ + _t445_x2ˍt_t_) + _t445_x3ˍtt_t_,
    -0.2330495234587907(_t445_x1ˍtt_t_ + _t445_x2ˍtt_t_) + _t445_x3ˍttt_t_,
    -0.2330495234587907(_t445_x1ˍttt_t_ + _t445_x2ˍttt_t_) + _t445_x3ˍtttt_t_,
    _t445_x1ˍt_t_ + _t445_x1_t_*_tpa_,
    _t445_x2ˍt_t_ - _t445_x2_t_*_tpb_,
    _t445_x1ˍtt_t_ + _t445_x1ˍt_t_*_tpa_,
    _t445_x2ˍtt_t_ - _t445_x2ˍt_t_*_tpb_,
    _t445_x2ˍttt_t_ - _t445_x2ˍtt_t_*_tpb_,
    _t445_x1ˍttt_t_ + _t445_x1ˍtt_t_*_tpa_
]

