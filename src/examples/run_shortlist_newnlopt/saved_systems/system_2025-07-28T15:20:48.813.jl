# Polynomial system saved on 2025-07-28T15:20:48.813
using Symbolics
using StaticArrays

# Metadata
# num_variables: 6
# timestamp: 2025-07-28T15:20:48.813
# num_equations: 6

# Variables
varlist_str = """
_tpa_
_tpb_
_t223_x1_t_
_t223_x2_t_
_t223_x2ˍt_t_
_t223_x1ˍt_t_
"""
@variables _tpa_ _tpb_ _t223_x1_t_ _t223_x2_t_ _t223_x2ˍt_t_ _t223_x1ˍt_t_
varlist = [_tpa__tpb__t223_x1_t__t223_x2_t__t223_x2ˍt_t__t223_x1ˍt_t_]

# Polynomial System
poly_system = [
    -0.6543967262156182 + _t223_x2_t_,
    0.27622131689969365 + _t223_x2ˍt_t_,
    0.3452766461247248 + _t223_x1_t_,
    0.2617586904862321 + _t223_x1ˍt_t_,
    _t223_x2ˍt_t_ - _t223_x1_t_*_tpb_,
    _t223_x1ˍt_t_ + _t223_x2_t_*_tpa_
]

