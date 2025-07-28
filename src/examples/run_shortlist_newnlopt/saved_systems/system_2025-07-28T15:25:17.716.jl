# Polynomial system saved on 2025-07-28T15:25:17.716
using Symbolics
using StaticArrays

# Metadata
# num_variables: 10
# timestamp: 2025-07-28T15:25:17.716
# num_equations: 10

# Variables
varlist_str = """
_tpa_
_tpb_
_tpc_
_tpd_
_t334_x1_t_
_t334_x2_t_
_t334_x2ˍt_t_
_t334_x2ˍtt_t_
_t334_x1ˍt_t_
_t334_x1ˍtt_t_
"""
@variables _tpa_ _tpb_ _tpc_ _tpd_ _t334_x1_t_ _t334_x2_t_ _t334_x2ˍt_t_ _t334_x2ˍtt_t_ _t334_x1ˍt_t_ _t334_x1ˍtt_t_
varlist = [_tpa__tpb__tpc__tpd__t334_x1_t__t334_x2_t__t334_x2ˍt_t__t334_x2ˍtt_t__t334_x1ˍt_t__t334_x1ˍtt_t_]

# Polynomial System
poly_system = [
    -0.4076668101223746 + _t334_x2_t_,
    0.4430407240158891 + _t334_x2ˍt_t_,
    -1.3652874238701134 + _t334_x2ˍtt_t_,
    -2.391535606593373 + _t334_x1_t_,
    -2.709848828932847 + _t334_x1ˍt_t_,
    -4.024107948912464 + _t334_x1ˍtt_t_,
    _t334_x2ˍt_t_ + _t334_x2_t_*_tpc_ - _t334_x1_t_*_t334_x2_t_*_tpd_,
    _t334_x2ˍtt_t_ + _t334_x2ˍt_t_*_tpc_ - _t334_x1_t_*_t334_x2ˍt_t_*_tpd_ - _t334_x1ˍt_t_*_t334_x2_t_*_tpd_,
    _t334_x1ˍt_t_ - _t334_x1_t_*_tpa_ + _t334_x1_t_*_t334_x2_t_*_tpb_,
    _t334_x1ˍtt_t_ - _t334_x1ˍt_t_*_tpa_ + _t334_x1_t_*_t334_x2ˍt_t_*_tpb_ + _t334_x1ˍt_t_*_t334_x2_t_*_tpb_
]

