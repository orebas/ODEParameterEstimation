# Polynomial system saved on 2025-07-28T15:48:18.643
using Symbolics
using StaticArrays

# Metadata
# num_variables: 9
# timestamp: 2025-07-28T15:48:18.643
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
    -14.103035622509722 + _t67_x2_t_^3,
    5.4468329284872805 + 3(_t67_x2_t_^2)*_t67_x2ˍt_t_,
    -30.490066758417335 + _t67_x3_t_^3,
    13.660470352093242 + 3(_t67_x3_t_^2)*_t67_x3ˍt_t_,
    -3.761430204801287 + _t67_x1_t_^3,
    1.7530487475777923 + 3(_t67_x1_t_^2)*_t67_x1ˍt_t_,
    _t67_x2ˍt_t_ + _t67_x1_t_*_tpb_,
    _t67_x3ˍt_t_ + _t67_x1_t_*_tpc_,
    _t67_x1ˍt_t_ + _t67_x2_t_*_tpa_
]

