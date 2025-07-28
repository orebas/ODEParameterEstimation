# Polynomial system saved on 2025-07-28T15:45:28.139
using Symbolics
using StaticArrays

# Metadata
# num_variables: 10
# timestamp: 2025-07-28T15:45:28.139
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
    4.593643514746496 + 3.0_t112_x1_t_ - 0.25_t112_x2_t_,
    2.1182613892323316 + 2.0_t112_x1_t_ + 0.5_t112_x2_t_,
    1.6982784771176016 + 2.0_t112_x1ˍt_t_ + 0.5_t112_x2ˍt_t_,
    _t112_x1ˍt_t_ + _t112_x2_t_*_tpa_,
    _t112_x2ˍt_t_ - _t112_x1_t_*_tpb_,
    4.715025045097552 + 3.0_t179_x1_t_ - 0.25_t179_x2_t_,
    3.6740918942043796 + 2.0_t179_x1_t_ + 0.5_t179_x2_t_,
    0.018316977783057718 + 2.0_t179_x1ˍt_t_ + 0.5_t179_x2ˍt_t_,
    _t179_x1ˍt_t_ + _t179_x2_t_*_tpa_,
    _t179_x2ˍt_t_ - _t179_x1_t_*_tpb_
]

