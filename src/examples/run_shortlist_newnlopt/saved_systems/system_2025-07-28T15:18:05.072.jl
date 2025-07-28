# Polynomial system saved on 2025-07-28T15:18:05.072
using Symbolics
using StaticArrays

# Metadata
# num_variables: 6
# timestamp: 2025-07-28T15:18:05.072
# num_equations: 6

# Variables
varlist_str = """
_tpa_
_tpb_
_t445_x1_t_
_t445_x2_t_
_t445_x1ˍt_t_
_t445_x2ˍt_t_
"""
@variables _tpa_ _tpb_ _t445_x1_t_ _t445_x2_t_ _t445_x1ˍt_t_ _t445_x2ˍt_t_
varlist = [_tpa__tpb__t445_x1_t__t445_x2_t__t445_x1ˍt_t__t445_x2ˍt_t_]

# Polynomial System
poly_system = [
    4.727778998619829 + 3.0_t445_x1_t_ - 0.25_t445_x2_t_,
    -1.2678303452321544 + 3.0_t445_x1ˍt_t_ - 0.25_t445_x2ˍt_t_,
    3.6738499957813304 + 2.0_t445_x1_t_ + 0.5_t445_x2_t_,
    0.030073568180591773 + 2.0_t445_x1ˍt_t_ + 0.5_t445_x2ˍt_t_,
    _t445_x1ˍt_t_ + _t445_x2_t_*_tpa_,
    _t445_x2ˍt_t_ - _t445_x1_t_*_tpb_
]

