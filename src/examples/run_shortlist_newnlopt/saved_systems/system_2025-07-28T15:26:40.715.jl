# Polynomial system saved on 2025-07-28T15:26:40.715
using Symbolics
using StaticArrays

# Metadata
# num_variables: 12
# timestamp: 2025-07-28T15:26:40.715
# num_equations: 12

# Variables
varlist_str = """
_tpa_
_tpb_
_tpc_
_tpd_
_t223_x1_t_
_t223_x2_t_
_t223_x2ˍt_t_
_t223_x1ˍt_t_
_t390_x1_t_
_t390_x2_t_
_t390_x2ˍt_t_
_t390_x1ˍt_t_
"""
@variables _tpa_ _tpb_ _tpc_ _tpd_ _t223_x1_t_ _t223_x2_t_ _t223_x2ˍt_t_ _t223_x1ˍt_t_ _t390_x1_t_ _t390_x2_t_ _t390_x2ˍt_t_ _t390_x1ˍt_t_
varlist = [_tpa__tpb__tpc__tpd__t223_x1_t__t223_x2_t__t223_x2ˍt_t__t223_x1ˍt_t__t390_x1_t__t390_x2_t__t390_x2ˍt_t__t390_x1ˍt_t_]

# Polynomial System
poly_system = [
    -0.4338689003252745 + _t223_x2_t_,
    0.520687797192402 + _t223_x2ˍt_t_,
    -2.2498714261092245 + _t223_x1_t_,
    -2.4962723235721556 + _t223_x1ˍt_t_,
    _t223_x2ˍt_t_ + _t223_x2_t_*_tpc_ - _t223_x1_t_*_t223_x2_t_*_tpd_,
    _t223_x1ˍt_t_ - _t223_x1_t_*_tpa_ + _t223_x1_t_*_t223_x2_t_*_tpb_,
    -4.793032430727282 + _t390_x2_t_,
    -1.3563477893247888 + _t390_x2ˍt_t_,
    -4.103729021942759 + _t390_x1_t_,
    11.546779194389826 + _t390_x1ˍt_t_,
    _t390_x2ˍt_t_ + _t390_x2_t_*_tpc_ - _t390_x1_t_*_t390_x2_t_*_tpd_,
    _t390_x1ˍt_t_ - _t390_x1_t_*_tpa_ + _t390_x1_t_*_t390_x2_t_*_tpb_
]

