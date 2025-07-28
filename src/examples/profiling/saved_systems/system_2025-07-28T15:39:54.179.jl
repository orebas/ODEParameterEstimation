# Polynomial system saved on 2025-07-28T15:39:54.179
using Symbolics
using StaticArrays

# Metadata
# num_variables: 8
# timestamp: 2025-07-28T15:39:54.179
# num_equations: 12

# Variables
varlist_str = """
_tpa_
_tpb_
_tpc_
_tpd_
_t201_x1_t_
_t201_x2_t_
_t201_x2ˍt_t_
_t201_x1ˍt_t_
"""
@variables _tpa_ _tpb_ _tpc_ _tpd_ _t201_x1_t_ _t201_x2_t_ _t201_x2ˍt_t_ _t201_x1ˍt_t_
varlist = [_tpa__tpb__tpc__tpd__t201_x1_t__t201_x2_t__t201_x2ˍt_t__t201_x1ˍt_t_]

# Polynomial System
poly_system = [
    -4.80423655657769 + _t201_x2_t_,
    0.8942945580601115 + _t201_x2ˍt_t_,
    -3.518161580276432 + _t201_x1_t_,
    9.92822122662793 + _t201_x1ˍt_t_,
    _t201_x2ˍt_t_ + _t201_x2_t_*_tpc_ - _t201_x1_t_*_t201_x2_t_*_tpd_,
    _t201_x1ˍt_t_ - _t201_x1_t_*_tpa_ + _t201_x1_t_*_t201_x2_t_*_tpb_,
    -4.80423655657769 + _t201_x2_t_,
    0.8942945580601115 + _t201_x2ˍt_t_,
    -3.518161580276432 + _t201_x1_t_,
    9.92822122662793 + _t201_x1ˍt_t_,
    _t201_x2ˍt_t_ + _t201_x2_t_*_tpc_ - _t201_x1_t_*_t201_x2_t_*_tpd_,
    _t201_x1ˍt_t_ - _t201_x1_t_*_tpa_ + _t201_x1_t_*_t201_x2_t_*_tpb_
]

