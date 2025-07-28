# Polynomial system saved on 2025-07-28T15:36:09.626
using Symbolics
using StaticArrays

# Metadata
# num_variables: 6
# timestamp: 2025-07-28T15:36:09.626
# num_equations: 6

# Variables
varlist_str = """
_tpa_
_tpb_
_t67_x1_t_
_t67_x2_t_
_t67_x1ˍt_t_
_t67_x2ˍt_t_
"""
@variables _tpa_ _tpb_ _t67_x1_t_ _t67_x2_t_ _t67_x1ˍt_t_ _t67_x2ˍt_t_
varlist = [_tpa__tpb__t67_x1_t__t67_x2_t__t67_x1ˍt_t__t67_x2ˍt_t_]

# Polynomial System
poly_system = [
    2.205868963317984 + 3.0_t67_x1_t_ - 0.25_t67_x2_t_,
    2.6838266481531936 + 3.0_t67_x1ˍt_t_ - 0.25_t67_x2ˍt_t_,
    -0.08059032347244778 + 2.0_t67_x1_t_ + 0.5_t67_x2_t_,
    2.0779609389787757 + 2.0_t67_x1ˍt_t_ + 0.5_t67_x2ˍt_t_,
    _t67_x1ˍt_t_ + _t67_x2_t_*_tpa_,
    _t67_x2ˍt_t_ - _t67_x1_t_*_tpb_
]

