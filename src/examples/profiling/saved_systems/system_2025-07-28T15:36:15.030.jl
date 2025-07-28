# Polynomial system saved on 2025-07-28T15:36:15.030
using Symbolics
using StaticArrays

# Metadata
# num_variables: 10
# timestamp: 2025-07-28T15:36:15.030
# num_equations: 10

# Variables
varlist_str = """
_tpa_
_tpb_
_t112_x1_t_
_t112_x2_t_
_t112_x1ˍt_t_
_t112_x2ˍt_t_
_t179_x1_t_
_t179_x2_t_
_t179_x1ˍt_t_
_t179_x2ˍt_t_
"""
@variables _tpa_ _tpb_ _t112_x1_t_ _t112_x2_t_ _t112_x1ˍt_t_ _t112_x2ˍt_t_ _t179_x1_t_ _t179_x2_t_ _t179_x1ˍt_t_ _t179_x2ˍt_t_
varlist = [_tpa__tpb__t112_x1_t__t112_x2_t__t112_x1ˍt_t__t112_x2ˍt_t__t179_x1_t__t179_x2_t__t179_x1ˍt_t__t179_x2ˍt_t_]

# Polynomial System
poly_system = [
    4.59364345976797 + 3.0_t112_x1_t_ - 0.25_t112_x2_t_,
    2.1182614220211757 + 2.0_t112_x1_t_ + 0.5_t112_x2_t_,
    1.6982784928011998 + 2.0_t112_x1ˍt_t_ + 0.5_t112_x2ˍt_t_,
    _t112_x1ˍt_t_ + _t112_x2_t_*_tpa_,
    _t112_x2ˍt_t_ - _t112_x1_t_*_tpb_,
    4.715025020718519 + 3.0_t179_x1_t_ - 0.25_t179_x2_t_,
    3.6740919311257847 + 2.0_t179_x1_t_ + 0.5_t179_x2_t_,
    0.01831680679907856 + 2.0_t179_x1ˍt_t_ + 0.5_t179_x2ˍt_t_,
    _t179_x1ˍt_t_ + _t179_x2_t_*_tpa_,
    _t179_x2ˍt_t_ - _t179_x1_t_*_tpb_
]

