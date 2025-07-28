# Polynomial system saved on 2025-07-28T15:25:23.107
using Symbolics
using StaticArrays

# Metadata
# num_variables: 10
# timestamp: 2025-07-28T15:25:23.107
# num_equations: 10

# Variables
varlist_str = """
_tpa_
_tpb_
_tpc_
_tpd_
_t390_x1_t_
_t390_x2_t_
_t390_x2ˍt_t_
_t390_x2ˍtt_t_
_t390_x1ˍt_t_
_t390_x1ˍtt_t_
"""
@variables _tpa_ _tpb_ _tpc_ _tpd_ _t390_x1_t_ _t390_x2_t_ _t390_x2ˍt_t_ _t390_x2ˍtt_t_ _t390_x1ˍt_t_ _t390_x1ˍtt_t_
varlist = [_tpa__tpb__tpc__tpd__t390_x1_t__t390_x2_t__t390_x2ˍt_t__t390_x2ˍtt_t__t390_x1ˍt_t__t390_x1ˍtt_t_]

# Polynomial System
poly_system = [
    -4.7930323975391556 + _t390_x2_t_,
    -1.3563475372785356 + _t390_x2ˍt_t_,
    43.89140649053381 + _t390_x2ˍtt_t_,
    -4.103729045100397 + _t390_x1_t_,
    11.546779415467133 + _t390_x1ˍt_t_,
    -27.479911409002135 + _t390_x1ˍtt_t_,
    _t390_x2ˍt_t_ + _t390_x2_t_*_tpc_ - _t390_x1_t_*_t390_x2_t_*_tpd_,
    _t390_x2ˍtt_t_ + _t390_x2ˍt_t_*_tpc_ - _t390_x1_t_*_t390_x2ˍt_t_*_tpd_ - _t390_x1ˍt_t_*_t390_x2_t_*_tpd_,
    _t390_x1ˍt_t_ - _t390_x1_t_*_tpa_ + _t390_x1_t_*_t390_x2_t_*_tpb_,
    _t390_x1ˍtt_t_ - _t390_x1ˍt_t_*_tpa_ + _t390_x1_t_*_t390_x2ˍt_t_*_tpb_ + _t390_x1ˍt_t_*_t390_x2_t_*_tpb_
]

