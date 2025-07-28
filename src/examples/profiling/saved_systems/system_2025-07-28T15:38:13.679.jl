# Polynomial system saved on 2025-07-28T15:38:13.679
using Symbolics
using StaticArrays

# Metadata
# num_variables: 9
# timestamp: 2025-07-28T15:38:13.679
# num_equations: 9

# Variables
varlist_str = """
_tpa_
_tpb_
_tpc_
_t179_x1_t_
_t179_x2_t_
_t179_x3_t_
_t179_x2ˍt_t_
_t179_x3ˍt_t_
_t179_x1ˍt_t_
"""
@variables _tpa_ _tpb_ _tpc_ _t179_x1_t_ _t179_x2_t_ _t179_x3_t_ _t179_x2ˍt_t_ _t179_x3ˍt_t_ _t179_x1ˍt_t_
varlist = [_tpa__tpb__tpc__t179_x1_t__t179_x2_t__t179_x3_t__t179_x2ˍt_t__t179_x3ˍt_t__t179_x1ˍt_t_]

# Polynomial System
poly_system = [
    -5.036255097231113 + _t179_x2_t_^3,
    1.7354040990379778 + 3(_t179_x2_t_^2)*_t179_x2ˍt_t_,
    -8.884515353494294 + _t179_x3_t_^3,
    3.800516127420458 + 3(_t179_x3_t_^2)*_t179_x3ˍt_t_,
    -0.9539618307071702 + _t179_x1_t_^3,
    0.49832064951347327 + 3(_t179_x1_t_^2)*_t179_x1ˍt_t_,
    _t179_x2ˍt_t_ + _t179_x1_t_*_tpb_,
    _t179_x3ˍt_t_ + _t179_x1_t_*_tpc_,
    _t179_x1ˍt_t_ + _t179_x2_t_*_tpa_
]

