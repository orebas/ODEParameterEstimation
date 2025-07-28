# Polynomial system saved on 2025-07-28T15:09:07.102
using Symbolics
using StaticArrays

# Metadata
# num_variables: 22
# timestamp: 2025-07-28T15:09:07.102
# num_equations: 22

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
_t445_x1ˍt_t_
_t445_x2ˍt_t_
_t445_x1ˍtt_t_
_t445_x2ˍtt_t_
_t501_x1_t_
_t501_x2_t_
_t501_x3_t_
_t501_x3ˍt_t_
_t501_x3ˍtt_t_
_t501_x3ˍttt_t_
_t501_x1ˍt_t_
_t501_x2ˍt_t_
_t501_x1ˍtt_t_
_t501_x2ˍtt_t_
"""
@variables _tpa_ _tpb_ _t445_x1_t_ _t445_x2_t_ _t445_x3_t_ _t445_x3ˍt_t_ _t445_x3ˍtt_t_ _t445_x3ˍttt_t_ _t445_x1ˍt_t_ _t445_x2ˍt_t_ _t445_x1ˍtt_t_ _t445_x2ˍtt_t_ _t501_x1_t_ _t501_x2_t_ _t501_x3_t_ _t501_x3ˍt_t_ _t501_x3ˍtt_t_ _t501_x3ˍttt_t_ _t501_x1ˍt_t_ _t501_x2ˍt_t_ _t501_x1ˍtt_t_ _t501_x2ˍtt_t_
varlist = [_tpa__tpb__t445_x1_t__t445_x2_t__t445_x3_t__t445_x3ˍt_t__t445_x3ˍtt_t__t445_x3ˍttt_t__t445_x1ˍt_t__t445_x2ˍt_t__t445_x1ˍtt_t__t445_x2ˍtt_t__t501_x1_t__t501_x2_t__t501_x3_t__t501_x3ˍt_t__t501_x3ˍtt_t__t501_x3ˍttt_t__t501_x1ˍt_t__t501_x2ˍt_t__t501_x1ˍtt_t__t501_x2ˍtt_t_]

# Polynomial System
poly_system = [
    -12.587396598335635 + _t445_x3_t_,
    -2.572116611481661 + _t445_x3ˍt_t_,
    -0.39895968836723944 + _t445_x3ˍtt_t_,
    -0.09136721587738919 + _t445_x3ˍttt_t_,
    -0.21476046880966437(_t445_x1_t_ + _t445_x2_t_) + _t445_x3ˍt_t_,
    -0.21476046880966437(_t445_x1ˍt_t_ + _t445_x2ˍt_t_) + _t445_x3ˍtt_t_,
    -0.21476046880966437(_t445_x1ˍtt_t_ + _t445_x2ˍtt_t_) + _t445_x3ˍttt_t_,
    _t445_x1ˍt_t_ + _t445_x1_t_*_tpa_,
    _t445_x2ˍt_t_ - _t445_x2_t_*_tpb_,
    _t445_x1ˍtt_t_ + _t445_x1ˍt_t_*_tpa_,
    _t445_x2ˍtt_t_ - _t445_x2ˍt_t_*_tpb_,
    -14.09308405663227 + _t501_x3_t_,
    -2.8103654027280953 + _t501_x3ˍt_t_,
    -0.4527974781291749 + _t501_x3ˍtt_t_,
    -0.10050362816046665 + _t501_x3ˍttt_t_,
    -0.21476046880966437(_t501_x1_t_ + _t501_x2_t_) + _t501_x3ˍt_t_,
    -0.21476046880966437(_t501_x1ˍt_t_ + _t501_x2ˍt_t_) + _t501_x3ˍtt_t_,
    -0.21476046880966437(_t501_x1ˍtt_t_ + _t501_x2ˍtt_t_) + _t501_x3ˍttt_t_,
    _t501_x1ˍt_t_ + _t501_x1_t_*_tpa_,
    _t501_x2ˍt_t_ - _t501_x2_t_*_tpb_,
    _t501_x1ˍtt_t_ + _t501_x1ˍt_t_*_tpa_,
    _t501_x2ˍtt_t_ - _t501_x2ˍt_t_*_tpb_
]

