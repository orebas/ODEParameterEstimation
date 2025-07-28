# Polynomial system saved on 2025-07-28T15:27:41.778
using Symbolics
using StaticArrays

# Metadata
# num_variables: 6
# timestamp: 2025-07-28T15:27:41.778
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
    0.9631309305733236 + _t223_x2_t_,
    0.26903310311736384 + _t223_x2ˍt_t_,
    0.26903310311745166 + _t223_x1_t_,
    -0.9631309305713547 + _t223_x1ˍt_t_,
    -_t223_x1_t_ + _t223_x2ˍt_t_*_tpb_,
    _t223_x1ˍt_t_ + _t223_x2_t_*_tpa_
]

