# Polynomial system saved on 2025-07-28T15:44:59.157
using Symbolics
using StaticArrays

# Metadata
# num_variables: 6
# timestamp: 2025-07-28T15:44:59.156
# num_equations: 6

# Variables
varlist_str = """
_tpa_
_tpb_
_t89_x1_t_
_t89_x2_t_
_t89_x2ˍt_t_
_t89_x1ˍt_t_
"""
@variables _tpa_ _tpb_ _t89_x1_t_ _t89_x2_t_ _t89_x2ˍt_t_ _t89_x1ˍt_t_
varlist = [_tpa__tpb__t89_x1_t__t89_x2_t__t89_x2ˍt_t__t89_x1ˍt_t_]

# Polynomial System
poly_system = [
    -0.659879153367982 + _t89_x2_t_,
    0.27201558339137893 + _t89_x2ˍt_t_,
    0.3400194882832917 + _t89_x1_t_,
    0.26395165271894283 + _t89_x1ˍt_t_,
    _t89_x2ˍt_t_ - _t89_x1_t_*_tpb_,
    _t89_x1ˍt_t_ + _t89_x2_t_*_tpa_
]

