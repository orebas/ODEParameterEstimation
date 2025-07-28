# Polynomial system saved on 2025-07-28T15:39:37.035
using Symbolics
using StaticArrays

# Metadata
# num_variables: 10
# timestamp: 2025-07-28T15:39:37.035
# num_equations: 10

# Variables
varlist_str = """
_tpa_
_tpb_
_tpc_
_tpd_
_t201_x1_t_
_t201_x2_t_
_t201_x2ˍt_t_
_t201_x2ˍtt_t_
_t201_x1ˍt_t_
_t201_x1ˍtt_t_
"""
@variables _tpa_ _tpb_ _tpc_ _tpd_ _t201_x1_t_ _t201_x2_t_ _t201_x2ˍt_t_ _t201_x2ˍtt_t_ _t201_x1ˍt_t_ _t201_x1ˍtt_t_
varlist = [_tpa__tpb__tpc__tpd__t201_x1_t__t201_x2_t__t201_x2ˍt_t__t201_x2ˍtt_t__t201_x1ˍt_t__t201_x1ˍtt_t_]

# Polynomial System
poly_system = [
    -4.804236591004397 + _t201_x2_t_,
    0.8942316664289253 + _t201_x2ˍt_t_,
    38.21312969327744 + _t201_x2ˍtt_t_,
    -3.5181615915202036 + _t201_x1_t_,
    9.928198109423366 + _t201_x1ˍt_t_,
    -31.302040166924147 + _t201_x1ˍtt_t_,
    _t201_x2ˍt_t_ + _t201_x2_t_*_tpc_ - _t201_x1_t_*_t201_x2_t_*_tpd_,
    _t201_x2ˍtt_t_ + _t201_x2ˍt_t_*_tpc_ - _t201_x1_t_*_t201_x2ˍt_t_*_tpd_ - _t201_x1ˍt_t_*_t201_x2_t_*_tpd_,
    _t201_x1ˍt_t_ - _t201_x1_t_*_tpa_ + _t201_x1_t_*_t201_x2_t_*_tpb_,
    _t201_x1ˍtt_t_ - _t201_x1ˍt_t_*_tpa_ + _t201_x1_t_*_t201_x2ˍt_t_*_tpb_ + _t201_x1ˍt_t_*_t201_x2_t_*_tpb_
]

