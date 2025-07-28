# Polynomial system saved on 2025-07-28T15:38:32.522
using Symbolics
using StaticArrays

# Metadata
# num_variables: 9
# timestamp: 2025-07-28T15:38:32.522
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
    -11.422683258944236 + _t89_x2_t_^3,
    4.342287852458434 + 3(_t89_x2_t_^2)*_t89_x2ˍt_t_,
    -23.842198136248797 + _t89_x3_t_^3,
    10.638052168435038 + 3(_t89_x3_t_^2)*_t89_x3ˍt_t_,
    -2.9051311357546283 + _t89_x1_t_^3,
    1.3755862030205461 + 3(_t89_x1_t_^2)*_t89_x1ˍt_t_,
    _t89_x2ˍt_t_ + _t89_x1_t_*_tpb_,
    _t89_x3ˍt_t_ + _t89_x1_t_*_tpc_,
    _t89_x1ˍt_t_ + _t89_x2_t_*_tpa_
]

