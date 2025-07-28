# Polynomial system saved on 2025-07-28T15:48:39.997
using Symbolics
using StaticArrays

# Metadata
# num_variables: 9
# timestamp: 2025-07-28T15:48:39.996
# num_equations: 9

# Variables
varlist_str = """
_tpa_
_tpb_
_tpc_
_t89_x1_t_
_t89_x2_t_
_t89_x3_t_
_t89_x2ˍt_t_
_t89_x3ˍt_t_
_t89_x1ˍt_t_
"""
@variables _tpa_ _tpb_ _tpc_ _t89_x1_t_ _t89_x2_t_ _t89_x3_t_ _t89_x2ˍt_t_ _t89_x3ˍt_t_ _t89_x1ˍt_t_
varlist = [_tpa__tpb__tpc__t89_x1_t__t89_x2_t__t89_x3_t__t89_x2ˍt_t__t89_x3ˍt_t__t89_x1ˍt_t_]

# Polynomial System
poly_system = [
    -11.422683325696124 + _t89_x2_t_^3,
    4.342286797468099 + 3(_t89_x2_t_^2)*_t89_x2ˍt_t_,
    -23.84219795340592 + _t89_x3_t_^3,
    10.638048398904727 + 3(_t89_x3_t_^2)*_t89_x3ˍt_t_,
    -2.9051311186634687 + _t89_x1_t_^3,
    1.3755862292473835 + 3(_t89_x1_t_^2)*_t89_x1ˍt_t_,
    _t89_x2ˍt_t_ + _t89_x1_t_*_tpb_,
    _t89_x3ˍt_t_ + _t89_x1_t_*_tpc_,
    _t89_x1ˍt_t_ + _t89_x2_t_*_tpa_
]

