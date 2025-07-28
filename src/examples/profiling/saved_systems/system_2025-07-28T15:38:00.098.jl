# Polynomial system saved on 2025-07-28T15:38:00.099
using Symbolics
using StaticArrays

# Metadata
# num_variables: 9
# timestamp: 2025-07-28T15:38:00.098
# num_equations: 9

# Variables
varlist_str = """
_tpa_
_tpb_
_tpc_
_t112_x1_t_
_t112_x2_t_
_t112_x3_t_
_t112_x2ˍt_t_
_t112_x3ˍt_t_
_t112_x1ˍt_t_
"""
@variables _tpa_ _tpb_ _tpc_ _t112_x1_t_ _t112_x2_t_ _t112_x3_t_ _t112_x2ˍt_t_ _t112_x3ˍt_t_ _t112_x1ˍt_t_
varlist = [_tpa__tpb__tpc__t112_x1_t__t112_x2_t__t112_x3_t__t112_x2ˍt_t__t112_x3ˍt_t__t112_x1ˍt_t_]

# Polynomial System
poly_system = [
    -9.198780030483274 + _t112_x2_t_^3,
    3.4295522185867875 + 3(_t112_x2_t_^2)*_t112_x2ˍt_t_,
    -18.461068549573405 + _t112_x3_t_^3,
    8.184889671311387 + 3(_t112_x3_t_^2)*_t112_x3ˍt_t_,
    -2.2069772728373236 + _t112_x1_t_^3,
    1.065524199760769 + 3(_t112_x1_t_^2)*_t112_x1ˍt_t_,
    _t112_x2ˍt_t_ + _t112_x1_t_*_tpb_,
    _t112_x3ˍt_t_ + _t112_x1_t_*_tpc_,
    _t112_x1ˍt_t_ + _t112_x2_t_*_tpa_
]

