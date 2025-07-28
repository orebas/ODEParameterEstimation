# Polynomial system saved on 2025-07-28T15:11:14.264
using Symbolics
using StaticArrays

# Metadata
# num_variables: 9
# timestamp: 2025-07-28T15:11:14.264
# num_equations: 9

# Variables
varlist_str = """
_tpa_
_tpb_
_tpc_
_t56_x1_t_
_t56_x2_t_
_t56_x3_t_
_t56_x2ˍt_t_
_t56_x3ˍt_t_
_t56_x1ˍt_t_
"""
@variables _tpa_ _tpb_ _tpc_ _t56_x1_t_ _t56_x2_t_ _t56_x3_t_ _t56_x2ˍt_t_ _t56_x3ˍt_t_ _t56_x1ˍt_t_
varlist = [_tpa__tpb__tpc__t56_x1_t__t56_x2_t__t56_x3_t__t56_x2ˍt_t__t56_x3ˍt_t__t56_x1ˍt_t_]

# Polynomial System
poly_system = [
    -21.690974015040936 + _t56_x2_t_^3,
    8.590745377629679 + 3(_t56_x2_t_^2)*_t56_x2ˍt_t_,
    -49.96967287946074 + _t56_x3_t_^3,
    22.477105342195088 + 3(_t56_x3_t_^2)*_t56_x3ˍt_t_,
    -6.2385136279973565 + _t56_x1_t_^3,
    2.8353166502464426 + 3(_t56_x1_t_^2)*_t56_x1ˍt_t_,
    _t56_x2ˍt_t_ + _t56_x1_t_*_tpb_,
    _t56_x3ˍt_t_ + _t56_x1_t_*_tpc_,
    _t56_x1ˍt_t_ + _t56_x2_t_*_tpa_
]

