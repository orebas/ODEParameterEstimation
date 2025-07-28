# Polynomial system saved on 2025-07-28T15:38:30.832
using Symbolics
using StaticArrays

# Metadata
# num_variables: 9
# timestamp: 2025-07-28T15:38:30.832
# num_equations: 9

# Variables
varlist_str = """
_tpa_
_tpb_
_tpc_
_t67_x1_t_
_t67_x2_t_
_t67_x3_t_
_t67_x2ˍt_t_
_t67_x3ˍt_t_
_t67_x1ˍt_t_
"""
@variables _tpa_ _tpb_ _tpc_ _t67_x1_t_ _t67_x2_t_ _t67_x3_t_ _t67_x2ˍt_t_ _t67_x3ˍt_t_ _t67_x1ˍt_t_
varlist = [_tpa__tpb__tpc__t67_x1_t__t67_x2_t__t67_x3_t__t67_x2ˍt_t__t67_x3ˍt_t__t67_x1ˍt_t_]

# Polynomial System
poly_system = [
    -14.10303570390888 + _t67_x2_t_^3,
    5.446831735174329 + 3(_t67_x2_t_^2)*_t67_x2ˍt_t_,
    -30.490067097252528 + _t67_x3_t_^3,
    13.660474499157049 + 3(_t67_x3_t_^2)*_t67_x3ˍt_t_,
    -3.761430202993284 + _t67_x1_t_^3,
    1.7530492195416492 + 3(_t67_x1_t_^2)*_t67_x1ˍt_t_,
    _t67_x2ˍt_t_ + _t67_x1_t_*_tpb_,
    _t67_x3ˍt_t_ + _t67_x1_t_*_tpc_,
    _t67_x1ˍt_t_ + _t67_x2_t_*_tpa_
]

