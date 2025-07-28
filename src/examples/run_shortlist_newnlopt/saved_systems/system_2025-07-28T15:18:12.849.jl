# Polynomial system saved on 2025-07-28T15:18:12.850
using Symbolics
using StaticArrays

# Metadata
# num_variables: 6
# timestamp: 2025-07-28T15:18:12.849
# num_equations: 6

# Variables
varlist_str = """
_tpa_
_tpb_
_t223_x1_t_
_t223_x2_t_
_t223_x1ˍt_t_
_t223_x2ˍt_t_
"""
@variables _tpa_ _tpb_ _t223_x1_t_ _t223_x2_t_ _t223_x1ˍt_t_ _t223_x2ˍt_t_
varlist = [_tpa__tpb__t223_x1_t__t223_x2_t__t223_x1ˍt_t__t223_x2ˍt_t_]

# Polynomial System
poly_system = [
    3.595599734200959 + 3.0_t223_x1_t_ - 0.25_t223_x2_t_,
    2.150100466638378 + 3.0_t223_x1ˍt_t_ - 0.25_t223_x2ˍt_t_,
    1.0875831384853467 + 2.0_t223_x1_t_ + 0.5_t223_x2_t_,
    1.9853191515227806 + 2.0_t223_x1ˍt_t_ + 0.5_t223_x2ˍt_t_,
    _t223_x1ˍt_t_ + _t223_x2_t_*_tpa_,
    _t223_x2ˍt_t_ - _t223_x1_t_*_tpb_
]

