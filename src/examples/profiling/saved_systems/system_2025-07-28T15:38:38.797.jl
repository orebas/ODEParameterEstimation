# Polynomial system saved on 2025-07-28T15:38:38.798
using Symbolics
using StaticArrays

# Metadata
# num_variables: 9
# timestamp: 2025-07-28T15:38:38.797
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
    -9.198779787018555 + _t112_x2_t_^3,
    3.429552299337288 + 3(_t112_x2_t_^2)*_t112_x2ˍt_t_,
    -18.461068510524075 + _t112_x3_t_^3,
    8.18489310765562 + 3(_t112_x3_t_^2)*_t112_x3ˍt_t_,
    -2.206977370820256 + _t112_x1_t_^3,
    1.0655236574016966 + 3(_t112_x1_t_^2)*_t112_x1ˍt_t_,
    _t112_x2ˍt_t_ + _t112_x1_t_*_tpb_,
    _t112_x3ˍt_t_ + _t112_x1_t_*_tpc_,
    _t112_x1ˍt_t_ + _t112_x2_t_*_tpa_
]

