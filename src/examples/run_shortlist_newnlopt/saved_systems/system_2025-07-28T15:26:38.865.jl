# Polynomial system saved on 2025-07-28T15:26:38.866
using Symbolics
using StaticArrays

# Metadata
# num_variables: 12
# timestamp: 2025-07-28T15:26:38.865
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
    -0.43386891277082174 + _t223_x2_t_,
    0.5206873061822801 + _t223_x2ˍt_t_,
    -2.2498714382394156 + _t223_x1_t_,
    -2.4962720014448587 + _t223_x1ˍt_t_,
    _t223_x2ˍt_t_ + _t223_x2_t_*_tpc_ - _t223_x1_t_*_t223_x2_t_*_tpd_,
    _t223_x1ˍt_t_ - _t223_x1_t_*_tpa_ + _t223_x1_t_*_t223_x2_t_*_tpb_,
    -4.79303238371077 + _t390_x2_t_,
    -1.3563471921357446 + _t390_x2ˍt_t_,
    -4.103729021942759 + _t390_x1_t_,
    11.54678011779289 + _t390_x1ˍt_t_,
    _t390_x2ˍt_t_ + _t390_x2_t_*_tpc_ - _t390_x1_t_*_t390_x2_t_*_tpd_,
    _t390_x1ˍt_t_ - _t390_x1_t_*_tpa_ + _t390_x1_t_*_t390_x2_t_*_tpb_
]

