# Polynomial system saved on 2025-07-28T15:38:31.467
using Symbolics
using StaticArrays

# Metadata
# num_variables: 9
# timestamp: 2025-07-28T15:38:31.467
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
    -11.422683338330327 + _t89_x2_t_^3,
    4.342288084756315 + 3(_t89_x2_t_^2)*_t89_x2ˍt_t_,
    -23.842197000540246 + _t89_x3_t_^3,
    10.638052562221514 + 3(_t89_x3_t_^2)*_t89_x3ˍt_t_,
    -2.905131464092375 + _t89_x1_t_^3,
    1.3755859912984423 + 3(_t89_x1_t_^2)*_t89_x1ˍt_t_,
    _t89_x2ˍt_t_ + _t89_x1_t_*_tpb_,
    _t89_x3ˍt_t_ + _t89_x1_t_*_tpc_,
    _t89_x1ˍt_t_ + _t89_x2_t_*_tpa_
]

