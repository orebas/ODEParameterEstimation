# Polynomial system saved on 2025-07-28T15:20:27.475
using Symbolics
using StaticArrays

# Metadata
# num_variables: 6
# timestamp: 2025-07-28T15:20:27.475
# num_equations: 6

# Variables
varlist_str = """
_tpa_
_tpb_
_t111_x1_t_
_t111_x2_t_
_t111_x2ˍt_t_
_t111_x1ˍt_t_
"""
@variables _tpa_ _tpb_ _t111_x1_t_ _t111_x2_t_ _t111_x2ˍt_t_ _t111_x1ˍt_t_
varlist = [_tpa__tpb__t111_x1_t__t111_x2_t__t111_x2ˍt_t__t111_x1ˍt_t_]

# Polynomial System
poly_system = [
    -0.8164739437525992 + _t111_x2_t_,
    0.003455454905004783 + _t111_x2ˍt_t_,
    0.004319326905556697 + _t111_x1_t_,
    0.3265895693558928 + _t111_x1ˍt_t_,
    _t111_x2ˍt_t_ - _t111_x1_t_*_tpb_,
    _t111_x1ˍt_t_ + _t111_x2_t_*_tpa_
]

