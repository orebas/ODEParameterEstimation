# Polynomial system saved on 2025-07-28T15:18:14.193
using Symbolics
using StaticArrays

# Metadata
# num_variables: 6
# timestamp: 2025-07-28T15:18:14.193
# num_equations: 6

# Variables
varlist_str = """
_tpa_
_tpb_
_t278_x1_t_
_t278_x2_t_
_t278_x1ˍt_t_
_t278_x2ˍt_t_
"""
@variables _tpa_ _tpb_ _t278_x1_t_ _t278_x2_t_ _t278_x1ˍt_t_ _t278_x2ˍt_t_
varlist = [_tpa__tpb__t278_x1_t__t278_x2_t__t278_x1ˍt_t__t278_x2ˍt_t_]

# Polynomial System
poly_system = [
    4.586540829425231 + 3.0_t278_x1_t_ - 0.25_t278_x2_t_,
    1.4242070882987719 + 3.0_t278_x1ˍt_t_ - 0.25_t278_x2ˍt_t_,
    2.1097615701505164 + 2.0_t278_x1_t_ + 0.5_t278_x2_t_,
    1.7016609408094752 + 2.0_t278_x1ˍt_t_ + 0.5_t278_x2ˍt_t_,
    _t278_x1ˍt_t_ + _t278_x2_t_*_tpa_,
    _t278_x2ˍt_t_ - _t278_x1_t_*_tpb_
]

