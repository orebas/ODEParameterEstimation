# Polynomial system saved on 2025-07-28T15:48:54.995
using Symbolics
using StaticArrays

# Metadata
# num_variables: 9
# timestamp: 2025-07-28T15:48:54.995
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
    -9.198779808010801 + _t112_x2_t_^3,
    3.4295523459744404 + 3(_t112_x2_t_^2)*_t112_x2ˍt_t_,
    -18.461067814619206 + _t112_x3_t_^3,
    8.184889277524913 + 3(_t112_x3_t_^2)*_t112_x3ˍt_t_,
    -2.2069772521096103 + _t112_x1_t_^3,
    1.065523687502953 + 3(_t112_x1_t_^2)*_t112_x1ˍt_t_,
    _t112_x2ˍt_t_ + _t112_x1_t_*_tpb_,
    _t112_x3ˍt_t_ + _t112_x1_t_*_tpc_,
    _t112_x1ˍt_t_ + _t112_x2_t_*_tpa_
]

