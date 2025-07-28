# Polynomial system saved on 2025-07-28T15:20:58.845
using Symbolics
using StaticArrays

# Metadata
# num_variables: 6
# timestamp: 2025-07-28T15:20:58.845
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
    -0.8164739183861305 + _t111_x2_t_,
    0.003455462870339601 + _t111_x2ˍt_t_,
    0.004319332156696998 + _t111_x1_t_,
    0.3265895754925546 + _t111_x1ˍt_t_,
    _t111_x2ˍt_t_ - _t111_x1_t_*_tpb_,
    _t111_x1ˍt_t_ + _t111_x2_t_*_tpa_
]

