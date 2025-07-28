# Polynomial system saved on 2025-07-28T15:08:54.167
using Symbolics
using StaticArrays

# Metadata
# num_variables: 15
# timestamp: 2025-07-28T15:08:54.167
# num_equations: 15

# Variables
varlist_str = """
_tpa_
_tpb_
_t334_x1_t_
_t334_x2_t_
_t334_x3_t_
_t334_x3ˍt_t_
_t334_x3ˍtt_t_
_t334_x3ˍttt_t_
_t334_x3ˍtttt_t_
_t334_x1ˍt_t_
_t334_x2ˍt_t_
_t334_x1ˍtt_t_
_t334_x2ˍtt_t_
_t334_x2ˍttt_t_
_t334_x1ˍttt_t_
"""
@variables _tpa_ _tpb_ _t334_x1_t_ _t334_x2_t_ _t334_x3_t_ _t334_x3ˍt_t_ _t334_x3ˍtt_t_ _t334_x3ˍttt_t_ _t334_x3ˍtttt_t_ _t334_x1ˍt_t_ _t334_x2ˍt_t_ _t334_x1ˍtt_t_ _t334_x2ˍtt_t_ _t334_x2ˍttt_t_ _t334_x1ˍttt_t_
varlist = [_tpa__tpb__t334_x1_t__t334_x2_t__t334_x3_t__t334_x3ˍt_t__t334_x3ˍtt_t__t334_x3ˍttt_t__t334_x3ˍtttt_t__t334_x1ˍt_t__t334_x2ˍt_t__t334_x1ˍtt_t__t334_x2ˍtt_t__t334_x2ˍttt_t__t334_x1ˍttt_t_]

# Polynomial System
poly_system = [
    -9.958340764990027 + _t334_x3_t_,
    -2.181854502478089 + _t334_x3ˍt_t_,
    -0.30735226553329653 + _t334_x3ˍtt_t_,
    -0.07437231620860985 + _t334_x3ˍttt_t_,
    -0.013584260072093457 + _t334_x3ˍtttt_t_,
    -0.07514994258733987(_t334_x1_t_ + _t334_x2_t_) + _t334_x3ˍt_t_,
    -0.07514994258733987(_t334_x1ˍt_t_ + _t334_x2ˍt_t_) + _t334_x3ˍtt_t_,
    -0.07514994258733987(_t334_x1ˍtt_t_ + _t334_x2ˍtt_t_) + _t334_x3ˍttt_t_,
    -0.07514994258733987(_t334_x1ˍttt_t_ + _t334_x2ˍttt_t_) + _t334_x3ˍtttt_t_,
    _t334_x1ˍt_t_ + _t334_x1_t_*_tpa_,
    _t334_x2ˍt_t_ - _t334_x2_t_*_tpb_,
    _t334_x1ˍtt_t_ + _t334_x1ˍt_t_*_tpa_,
    _t334_x2ˍtt_t_ - _t334_x2ˍt_t_*_tpb_,
    _t334_x2ˍttt_t_ - _t334_x2ˍtt_t_*_tpb_,
    _t334_x1ˍttt_t_ + _t334_x1ˍtt_t_*_tpa_
]

