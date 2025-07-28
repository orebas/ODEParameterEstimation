# Polynomial system saved on 2025-07-28T15:45:11.497
using Symbolics
using StaticArrays

# Metadata
# num_variables: 6
# timestamp: 2025-07-28T15:45:11.496
# num_equations: 6

# Variables
varlist_str = """
_tpa_
_tpb_
_t89_x1_t_
_t89_x2_t_
_t89_x1ˍt_t_
_t89_x2ˍt_t_
"""
@variables _tpa_ _tpb_ _t89_x1_t_ _t89_x2_t_ _t89_x1ˍt_t_ _t89_x2ˍt_t_
varlist = [_tpa__tpb__t89_x1_t__t89_x2_t__t89_x1ˍt_t__t89_x2ˍt_t_]

# Polynomial System
poly_system = [
    3.552368588401495 + 3.0_t89_x1_t_ - 0.25_t89_x2_t_,
    2.172974206109919 + 3.0_t89_x1ˍt_t_ - 0.25_t89_x2ˍt_t_,
    1.0478080000584213 + 2.0_t89_x1_t_ + 0.5_t89_x2_t_,
    1.9921524939374962 + 2.0_t89_x1ˍt_t_ + 0.5_t89_x2ˍt_t_,
    _t89_x1ˍt_t_ + _t89_x2_t_*_tpa_,
    _t89_x2ˍt_t_ - _t89_x1_t_*_tpb_
]

