# Polynomial system saved on 2025-07-28T15:18:08.641
using Symbolics
using StaticArrays

# Metadata
# num_variables: 6
# timestamp: 2025-07-28T15:18:08.641
# num_equations: 6

# Variables
varlist_str = """
_tpa_
_tpb_
_t56_x1_t_
_t56_x2_t_
_t56_x1ˍt_t_
_t56_x2ˍt_t_
"""
@variables _tpa_ _tpb_ _t56_x1_t_ _t56_x2_t_ _t56_x1ˍt_t_ _t56_x2ˍt_t_
varlist = [_tpa__tpb__t56_x1_t__t56_x2_t__t56_x1ˍt_t__t56_x2ˍt_t_]

# Polynomial System
poly_system = [
    -0.9729321843117776 + 3.0_t56_x1_t_ - 0.25_t56_x2_t_,
    2.9081074513698653 + 3.0_t56_x1ˍt_t_ - 0.25_t56_x2ˍt_t_,
    -2.206564089495078 + 2.0_t56_x1_t_ + 0.5_t56_x2_t_,
    1.6619097370389824 + 2.0_t56_x1ˍt_t_ + 0.5_t56_x2ˍt_t_,
    _t56_x1ˍt_t_ + _t56_x2_t_*_tpa_,
    _t56_x2ˍt_t_ - _t56_x1_t_*_tpb_
]

