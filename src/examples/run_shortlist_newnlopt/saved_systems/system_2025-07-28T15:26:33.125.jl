# Polynomial system saved on 2025-07-28T15:26:33.126
using Symbolics
using StaticArrays

# Metadata
# num_variables: 12
# timestamp: 2025-07-28T15:26:33.125
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
    -4.183266826309919 + _t167_x2_t_,
    -7.158825763677991 + _t167_x2ˍt_t_,
    -5.889125730127352 + _t167_x1_t_,
    13.338514015824227 + _t167_x1ˍt_t_,
    _t167_x2ˍt_t_ + _t167_x2_t_*_tpc_ - _t167_x1_t_*_t167_x2_t_*_tpd_,
    _t167_x1ˍt_t_ - _t167_x1_t_*_tpa_ + _t167_x1_t_*_t167_x2_t_*_tpb_,
    -0.4076668145301725 + _t334_x2_t_,
    0.4430404122774243 + _t334_x2ˍt_t_,
    -2.3915356052149424 + _t334_x1_t_,
    -2.7098478639869015 + _t334_x1ˍt_t_,
    _t334_x2ˍt_t_ + _t334_x2_t_*_tpc_ - _t334_x1_t_*_t334_x2_t_*_tpd_,
    _t334_x1ˍt_t_ - _t334_x1_t_*_tpa_ + _t334_x1_t_*_t334_x2_t_*_tpb_
]

