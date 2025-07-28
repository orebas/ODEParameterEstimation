# Polynomial system saved on 2025-07-28T15:39:36.260
using Symbolics
using StaticArrays

# Metadata
# num_variables: 10
# timestamp: 2025-07-28T15:39:36.260
# num_equations: 10

# Variables
varlist_str = """
_tpa_
_tpb_
_tpc_
_tpd_
_t179_x1_t_
_t179_x2_t_
_t179_x2ˍt_t_
_t179_x2ˍtt_t_
_t179_x1ˍt_t_
_t179_x1ˍtt_t_
"""
@variables _tpa_ _tpb_ _tpc_ _tpd_ _t179_x1_t_ _t179_x2_t_ _t179_x2ˍt_t_ _t179_x2ˍtt_t_ _t179_x1ˍt_t_ _t179_x1ˍtt_t_
varlist = [_tpa__tpb__tpc__tpd__t179_x1_t__t179_x2_t__t179_x2ˍt_t__t179_x2ˍtt_t__t179_x1ˍt_t__t179_x1ˍtt_t_]

# Polynomial System
poly_system = [
    -0.3749304634620405 + _t179_x2_t_,
    0.33440901524742506 + _t179_x2ˍt_t_,
    -1.2170437016238629 + _t179_x2ˍtt_t_,
    -2.635091487342533 + _t179_x1_t_,
    -3.0634573250156913 + _t179_x1ˍt_t_,
    -4.354598843753088 + _t179_x1ˍtt_t_,
    _t179_x2ˍt_t_ + _t179_x2_t_*_tpc_ - _t179_x1_t_*_t179_x2_t_*_tpd_,
    _t179_x2ˍtt_t_ + _t179_x2ˍt_t_*_tpc_ - _t179_x1_t_*_t179_x2ˍt_t_*_tpd_ - _t179_x1ˍt_t_*_t179_x2_t_*_tpd_,
    _t179_x1ˍt_t_ - _t179_x1_t_*_tpa_ + _t179_x1_t_*_t179_x2_t_*_tpb_,
    _t179_x1ˍtt_t_ - _t179_x1ˍt_t_*_tpa_ + _t179_x1_t_*_t179_x2ˍt_t_*_tpb_ + _t179_x1ˍt_t_*_t179_x2_t_*_tpb_
]

