# Polynomial system saved on 2025-07-28T15:45:08.286
using Symbolics
using StaticArrays

# Metadata
# num_variables: 6
# timestamp: 2025-07-28T15:45:08.286
# num_equations: 6

# Variables
varlist_str = """
_tpa_
_tpb_
_t22_x1_t_
_t22_x2_t_
_t22_x1ˍt_t_
_t22_x2ˍt_t_
"""
@variables _tpa_ _tpb_ _t22_x1_t_ _t22_x2_t_ _t22_x1ˍt_t_ _t22_x2ˍt_t_
varlist = [_tpa__tpb__t22_x1_t__t22_x2_t__t22_x1ˍt_t__t22_x2ˍt_t_]

# Polynomial System
poly_system = [
    -1.045535072340225 + 3.0_t22_x1_t_ - 0.25_t22_x2_t_,
    2.9000336749240003 + 3.0_t22_x1ˍt_t_ - 0.25_t22_x2ˍt_t_,
    -2.247889788756907 + 2.0_t22_x1_t_ + 0.5_t22_x2_t_,
    1.6440916848739553 + 2.0_t22_x1ˍt_t_ + 0.5_t22_x2ˍt_t_,
    _t22_x1ˍt_t_ + _t22_x2_t_*_tpa_,
    _t22_x2ˍt_t_ - _t22_x1_t_*_tpb_
]

