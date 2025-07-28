# Polynomial system saved on 2025-07-28T15:18:26.666
using Symbolics
using StaticArrays

# Metadata
# num_variables: 10
# timestamp: 2025-07-28T15:18:26.665
# num_equations: 10

# Variables
varlist_str = """
_tpa_
_tpb_
_t278_x1_t_
_t278_x2_t_
_t278_x1ˍt_t_
_t278_x2ˍt_t_
_t445_x1_t_
_t445_x2_t_
_t445_x1ˍt_t_
_t445_x2ˍt_t_
"""
@variables _tpa_ _tpb_ _t278_x1_t_ _t278_x2_t_ _t278_x1ˍt_t_ _t278_x2ˍt_t_ _t445_x1_t_ _t445_x2_t_ _t445_x1ˍt_t_ _t445_x2ˍt_t_
varlist = [_tpa__tpb__t278_x1_t__t278_x2_t__t278_x1ˍt_t__t278_x2ˍt_t__t445_x1_t__t445_x2_t__t445_x1ˍt_t__t445_x2ˍt_t_]

# Polynomial System
poly_system = [
    4.586540801564195 + 3.0_t278_x1_t_ - 0.25_t278_x2_t_,
    2.109761571238111 + 2.0_t278_x1_t_ + 0.5_t278_x2_t_,
    1.7016609385108874 + 2.0_t278_x1ˍt_t_ + 0.5_t278_x2ˍt_t_,
    _t278_x1ˍt_t_ + _t278_x2_t_*_tpa_,
    _t278_x2ˍt_t_ - _t278_x1_t_*_tpb_,
    4.727778927133144 + 3.0_t445_x1_t_ - 0.25_t445_x2_t_,
    3.673849970862935 + 2.0_t445_x1_t_ + 0.5_t445_x2_t_,
    0.030073596585160147 + 2.0_t445_x1ˍt_t_ + 0.5_t445_x2ˍt_t_,
    _t445_x1ˍt_t_ + _t445_x2_t_*_tpa_,
    _t445_x2ˍt_t_ - _t445_x1_t_*_tpb_
]

