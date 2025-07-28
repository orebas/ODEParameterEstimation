# Polynomial system saved on 2025-07-28T15:50:25.093
using Symbolics
using StaticArrays

# Metadata
# num_variables: 12
# timestamp: 2025-07-28T15:50:25.093
# num_equations: 12

# Variables
varlist_str = """
_tpa_
_tpb_
_tpc_
_tpd_
_t89_x1_t_
_t89_x2_t_
_t89_x2ˍt_t_
_t89_x1ˍt_t_
_t156_x1_t_
_t156_x2_t_
_t156_x2ˍt_t_
_t156_x1ˍt_t_
"""
@variables _tpa_ _tpb_ _tpc_ _tpd_ _t89_x1_t_ _t89_x2_t_ _t89_x2ˍt_t_ _t89_x1ˍt_t_ _t156_x1_t_ _t156_x2_t_ _t156_x2ˍt_t_ _t156_x1ˍt_t_
varlist = [_tpa__tpb__tpc__tpd__t89_x1_t__t89_x2_t__t89_x2ˍt_t__t89_x1ˍt_t__t156_x1_t__t156_x2_t__t156_x2ˍt_t__t156_x1ˍt_t_]

# Polynomial System
poly_system = [
    -0.4678908553112018 + _t89_x2_t_,
    0.6150444425471763 + _t89_x2ˍt_t_,
    -2.106852305637551 + _t89_x1_t_,
    -2.2730720582378794 + _t89_x1ˍt_t_,
    _t89_x2ˍt_t_ + _t89_x2_t_*_tpc_ - _t89_x1_t_*_t89_x2_t_*_tpd_,
    _t89_x1ˍt_t_ - _t89_x1_t_*_tpa_ + _t89_x1_t_*_t89_x2_t_*_tpb_,
    -4.686850001224679 + _t156_x2_t_,
    -3.371104358186658 + _t156_x2ˍt_t_,
    -4.6490811549319115 + _t156_x1_t_,
    12.636991970041828 + _t156_x1ˍt_t_,
    _t156_x2ˍt_t_ + _t156_x2_t_*_tpc_ - _t156_x1_t_*_t156_x2_t_*_tpd_,
    _t156_x1ˍt_t_ - _t156_x1_t_*_tpa_ + _t156_x1_t_*_t156_x2_t_*_tpb_
]

