# Polynomial system saved on 2025-07-28T15:25:15.769
using Symbolics
using StaticArrays

# Metadata
# num_variables: 10
# timestamp: 2025-07-28T15:25:15.769
# num_equations: 10

# Variables
varlist_str = """
_tpa_
_tpb_
_tpc_
_tpd_
_t278_x1_t_
_t278_x2_t_
_t278_x2ˍt_t_
_t278_x2ˍtt_t_
_t278_x1ˍt_t_
_t278_x1ˍtt_t_
"""
@variables _tpa_ _tpb_ _tpc_ _tpd_ _t278_x1_t_ _t278_x2_t_ _t278_x2ˍt_t_ _t278_x2ˍtt_t_ _t278_x1ˍt_t_ _t278_x1ˍtt_t_
varlist = [_tpa__tpb__tpc__tpd__t278_x1_t__t278_x2_t__t278_x2ˍt_t__t278_x2ˍtt_t__t278_x1ˍt_t__t278_x1ˍtt_t_]

# Polynomial System
poly_system = [
    -4.519408009957043 + _t278_x2_t_,
    -5.1010893769092425 + _t278_x2ˍt_t_,
    42.14957716901365 + _t278_x2ˍtt_t_,
    -5.160883967298279 + _t278_x1_t_,
    13.250402173829336 + _t278_x1ˍt_t_,
    -10.326522090261813 + _t278_x1ˍtt_t_,
    _t278_x2ˍt_t_ + _t278_x2_t_*_tpc_ - _t278_x1_t_*_t278_x2_t_*_tpd_,
    _t278_x2ˍtt_t_ + _t278_x2ˍt_t_*_tpc_ - _t278_x1_t_*_t278_x2ˍt_t_*_tpd_ - _t278_x1ˍt_t_*_t278_x2_t_*_tpd_,
    _t278_x1ˍt_t_ - _t278_x1_t_*_tpa_ + _t278_x1_t_*_t278_x2_t_*_tpb_,
    _t278_x1ˍtt_t_ - _t278_x1ˍt_t_*_tpa_ + _t278_x1_t_*_t278_x2ˍt_t_*_tpb_ + _t278_x1ˍt_t_*_t278_x2_t_*_tpb_
]

