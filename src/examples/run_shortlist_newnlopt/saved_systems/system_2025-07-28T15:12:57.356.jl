# Polynomial system saved on 2025-07-28T15:12:57.356
using Symbolics
using StaticArrays

# Metadata
# num_variables: 9
# timestamp: 2025-07-28T15:12:57.356
# num_equations: 9

# Variables
varlist_str = """
_tpa_
_tpb_
_tpc_
_t278_x1_t_
_t278_x2_t_
_t278_x3_t_
_t278_x2ˍt_t_
_t278_x3ˍt_t_
_t278_x1ˍt_t_
"""
@variables _tpa_ _tpb_ _tpc_ _t278_x1_t_ _t278_x2_t_ _t278_x3_t_ _t278_x2ˍt_t_ _t278_x3ˍt_t_ _t278_x1ˍt_t_
varlist = [_tpa__tpb__tpc__t278_x1_t__t278_x2_t__t278_x3_t__t278_x2ˍt_t__t278_x3ˍt_t__t278_x1ˍt_t_]

# Polynomial System
poly_system = [
    -9.215945251723674 + _t278_x2_t_^3,
    3.436581154284876 + 3(_t278_x2_t_^2)*_t278_x2ˍt_t_,
    -18.502039790887252 + _t278_x3_t_^3,
    8.203596601706659 + 3(_t278_x3_t_^2)*_t278_x3ˍt_t_,
    -2.212310908534882 + _t278_x1_t_^3,
    1.0679035248642452 + 3(_t278_x1_t_^2)*_t278_x1ˍt_t_,
    _t278_x2ˍt_t_ + _t278_x1_t_*_tpb_,
    _t278_x3ˍt_t_ + _t278_x1_t_*_tpc_,
    _t278_x1ˍt_t_ + _t278_x2_t_*_tpa_
]

