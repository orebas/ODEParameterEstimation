# Polynomial system saved on 2025-07-28T15:49:53.354
using Symbolics
using StaticArrays

# Metadata
# num_variables: 10
# timestamp: 2025-07-28T15:49:53.354
# num_equations: 10

# Variables
varlist_str = """
_tpa_
_tpb_
_tpc_
_tpd_
_t22_x1_t_
_t22_x2_t_
_t22_x2ˍt_t_
_t22_x2ˍtt_t_
_t22_x1ˍt_t_
_t22_x1ˍtt_t_
"""
@variables _tpa_ _tpb_ _tpc_ _tpd_ _t22_x1_t_ _t22_x2_t_ _t22_x2ˍt_t_ _t22_x2ˍtt_t_ _t22_x1ˍt_t_ _t22_x1ˍtt_t_
varlist = [_tpa__tpb__tpc__tpd__t22_x1_t__t22_x2_t__t22_x2ˍt_t__t22_x2ˍtt_t__t22_x1ˍt_t__t22_x1ˍtt_t_]

# Polynomial System
poly_system = [
    -3.0826235894235547 + _t22_x2_t_,
    -9.057603850299703 + _t22_x2ˍt_t_,
    -3.285967367702483 + _t22_x2ˍtt_t_,
    -7.422847003354433 + _t22_x1_t_,
    9.45938844085449 + _t22_x1ˍt_t_,
    48.45520894483798 + _t22_x1ˍtt_t_,
    _t22_x2ˍt_t_ + _t22_x2_t_*_tpc_ - _t22_x1_t_*_t22_x2_t_*_tpd_,
    _t22_x2ˍtt_t_ + _t22_x2ˍt_t_*_tpc_ - _t22_x1_t_*_t22_x2ˍt_t_*_tpd_ - _t22_x1ˍt_t_*_t22_x2_t_*_tpd_,
    _t22_x1ˍt_t_ - _t22_x1_t_*_tpa_ + _t22_x1_t_*_t22_x2_t_*_tpb_,
    _t22_x1ˍtt_t_ - _t22_x1ˍt_t_*_tpa_ + _t22_x1_t_*_t22_x2ˍt_t_*_tpb_ + _t22_x1ˍt_t_*_t22_x2_t_*_tpb_
]

