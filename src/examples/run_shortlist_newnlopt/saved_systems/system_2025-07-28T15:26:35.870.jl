# Polynomial system saved on 2025-07-28T15:26:35.871
using Symbolics
using StaticArrays

# Metadata
# num_variables: 12
# timestamp: 2025-07-28T15:26:35.870
# num_equations: 12

# Variables
varlist_str = """
_tpa_
_tpb_
_tpc_
_tpd_
_t167_x1_t_
_t167_x2_t_
_t167_x2ˍt_t_
_t167_x1ˍt_t_
_t334_x1_t_
_t334_x2_t_
_t334_x2ˍt_t_
_t334_x1ˍt_t_
"""
@variables _tpa_ _tpb_ _tpc_ _tpd_ _t167_x1_t_ _t167_x2_t_ _t167_x2ˍt_t_ _t167_x1ˍt_t_ _t334_x1_t_ _t334_x2_t_ _t334_x2ˍt_t_ _t334_x1ˍt_t_
varlist = [_tpa__tpb__tpc__tpd__t167_x1_t__t167_x2_t__t167_x2ˍt_t__t167_x1ˍt_t__t334_x1_t__t334_x2_t__t334_x2ˍt_t__t334_x1ˍt_t_]

# Polynomial System
poly_system = [
    -4.183266823717097 + _t167_x2_t_,
    -7.158825422963067 + _t167_x2ˍt_t_,
    -5.8891255625101655 + _t167_x1_t_,
    13.338515386827702 + _t167_x1ˍt_t_,
    _t167_x2ˍt_t_ + _t167_x2_t_*_tpc_ - _t167_x1_t_*_t167_x2_t_*_tpd_,
    _t167_x1ˍt_t_ - _t167_x1_t_*_tpa_ + _t167_x1_t_*_t167_x2_t_*_tpb_,
    -0.40766680389960097 + _t334_x2_t_,
    0.4430400242922232 + _t334_x2ˍt_t_,
    -2.391535669449818 + _t334_x1_t_,
    -2.709848019738358 + _t334_x1ˍt_t_,
    _t334_x2ˍt_t_ + _t334_x2_t_*_tpc_ - _t334_x1_t_*_t334_x2_t_*_tpd_,
    _t334_x1ˍt_t_ - _t334_x1_t_*_tpa_ + _t334_x1_t_*_t334_x2_t_*_tpb_
]

