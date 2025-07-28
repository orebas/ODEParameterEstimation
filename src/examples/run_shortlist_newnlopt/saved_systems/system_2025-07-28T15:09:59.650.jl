# Polynomial system saved on 2025-07-28T15:09:59.651
using Symbolics
using StaticArrays

# Metadata
# num_variables: 9
# timestamp: 2025-07-28T15:09:59.650
# num_equations: 9

# Variables
varlist_str = """
_tpa_
_tpb_
_tpc_
_t223_x1_t_
_t223_x2_t_
_t223_x3_t_
_t223_x2ˍt_t_
_t223_x3ˍt_t_
_t223_x1ˍt_t_
"""
@variables _tpa_ _tpb_ _tpc_ _t223_x1_t_ _t223_x2_t_ _t223_x3_t_ _t223_x2ˍt_t_ _t223_x3ˍt_t_ _t223_x1ˍt_t_
varlist = [_tpa__tpb__tpc__t223_x1_t__t223_x2_t__t223_x3_t__t223_x2ˍt_t__t223_x3ˍt_t__t223_x1ˍt_t_]

# Polynomial System
poly_system = [
    -11.33619353189458 + _t223_x2_t_^3,
    4.306719909446629 + 3(_t223_x2_t_^2)*_t223_x2ˍt_t_,
    -23.630401931234488 + _t223_x3_t_^3,
    10.541615253221531 + 3(_t223_x3_t_^2)*_t223_x3ˍt_t_,
    -2.877740838995741 + _t223_x1_t_^3,
    1.363467256476035 + 3(_t223_x1_t_^2)*_t223_x1ˍt_t_,
    _t223_x2ˍt_t_ + _t223_x1_t_*_tpb_,
    _t223_x3ˍt_t_ + _t223_x1_t_*_tpc_,
    _t223_x1ˍt_t_ + _t223_x2_t_*_tpa_
]

