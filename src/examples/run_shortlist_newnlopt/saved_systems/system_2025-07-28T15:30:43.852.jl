# Polynomial system saved on 2025-07-28T15:30:43.853
using Symbolics
using StaticArrays

# Metadata
# num_variables: 6
# timestamp: 2025-07-28T15:30:43.852
# num_equations: 6

# Variables
varlist_str = """
_tpa_
_tpb_
_t278_x1_t_
_t278_x2_t_
_t278_x2ˍt_t_
_t278_x1ˍt_t_
"""
@variables _tpa_ _tpb_ _t278_x1_t_ _t278_x2_t_ _t278_x2ˍt_t_ _t278_x1ˍt_t_
varlist = [_tpa__tpb__t278_x1_t__t278_x2_t__t278_x2ˍt_t__t278_x1ˍt_t_]

# Polynomial System
poly_system = [
    2.0776859345854266 + _t278_x2_t_,
    -4.161237672258519 + _t278_x2ˍt_t_,
    1.508843907760439 + _t278_x1_t_,
    2.0776858928105857 + _t278_x1ˍt_t_,
    _t278_x1_t_ + _t278_x2ˍt_t_ + (-1 + _t278_x1_t_^2)*_t278_x2_t_*_tpb_,
    _t278_x1ˍt_t_ - _t278_x2_t_*_tpa_
]

