# Polynomial system saved on 2025-07-28T15:39:35.233
using Symbolics
using StaticArrays

# Metadata
# num_variables: 10
# timestamp: 2025-07-28T15:39:35.232
# num_equations: 10

# Variables
varlist_str = """
_tpa_
_tpb_
_tpc_
_tpd_
_t134_x1_t_
_t134_x2_t_
_t134_x2ˍt_t_
_t134_x2ˍtt_t_
_t134_x1ˍt_t_
_t134_x1ˍtt_t_
"""
@variables _tpa_ _tpb_ _tpc_ _tpd_ _t134_x1_t_ _t134_x2_t_ _t134_x2ˍt_t_ _t134_x2ˍtt_t_ _t134_x1ˍt_t_ _t134_x1ˍtt_t_
varlist = [_tpa__tpb__tpc__tpd__t134_x1_t__t134_x2_t__t134_x2ˍt_t__t134_x2ˍtt_t__t134_x1ˍt_t__t134_x1ˍtt_t_]

# Polynomial System
poly_system = [
    -0.41446696356547585 + _t134_x2_t_,
    0.46376487915613995 + _t134_x2ˍt_t_,
    -1.3978083492549693 + _t134_x2ˍtt_t_,
    -2.3513386970753296 + _t134_x1_t_,
    -2.6499163398081866 + _t134_x1ˍt_t_,
    -3.9675658572027306 + _t134_x1ˍtt_t_,
    _t134_x2ˍt_t_ + _t134_x2_t_*_tpc_ - _t134_x1_t_*_t134_x2_t_*_tpd_,
    _t134_x2ˍtt_t_ + _t134_x2ˍt_t_*_tpc_ - _t134_x1_t_*_t134_x2ˍt_t_*_tpd_ - _t134_x1ˍt_t_*_t134_x2_t_*_tpd_,
    _t134_x1ˍt_t_ - _t134_x1_t_*_tpa_ + _t134_x1_t_*_t134_x2_t_*_tpb_,
    _t134_x1ˍtt_t_ - _t134_x1ˍt_t_*_tpa_ + _t134_x1_t_*_t134_x2ˍt_t_*_tpb_ + _t134_x1ˍt_t_*_t134_x2_t_*_tpb_
]

