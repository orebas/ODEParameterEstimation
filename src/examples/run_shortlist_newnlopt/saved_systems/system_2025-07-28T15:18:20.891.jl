# Polynomial system saved on 2025-07-28T15:18:20.891
using Symbolics
using StaticArrays

# Metadata
# num_variables: 10
# timestamp: 2025-07-28T15:18:20.891
# num_equations: 10

# Variables
varlist_str = """
_tpa_
_tpb_
_t56_x1_t_
_t56_x2_t_
_t56_x1ˍt_t_
_t56_x2ˍt_t_
_t223_x1_t_
_t223_x2_t_
_t223_x1ˍt_t_
_t223_x2ˍt_t_
"""
@variables _tpa_ _tpb_ _t56_x1_t_ _t56_x2_t_ _t56_x1ˍt_t_ _t56_x2ˍt_t_ _t223_x1_t_ _t223_x2_t_ _t223_x1ˍt_t_ _t223_x2ˍt_t_
varlist = [_tpa__tpb__t56_x1_t__t56_x2_t__t56_x1ˍt_t__t56_x2ˍt_t__t223_x1_t__t223_x2_t__t223_x1ˍt_t__t223_x2ˍt_t_]

# Polynomial System
poly_system = [
    -0.9729322037748291 + 3.0_t56_x1_t_ - 0.25_t56_x2_t_,
    -2.206564103518013 + 2.0_t56_x1_t_ + 0.5_t56_x2_t_,
    1.6619097472969624 + 2.0_t56_x1ˍt_t_ + 0.5_t56_x2ˍt_t_,
    _t56_x1ˍt_t_ + _t56_x2_t_*_tpa_,
    _t56_x2ˍt_t_ - _t56_x1_t_*_tpb_,
    3.59559971318064 + 3.0_t223_x1_t_ - 0.25_t223_x2_t_,
    1.08758310166405 + 2.0_t223_x1_t_ + 0.5_t223_x2_t_,
    1.9853191450766963 + 2.0_t223_x1ˍt_t_ + 0.5_t223_x2ˍt_t_,
    _t223_x1ˍt_t_ + _t223_x2_t_*_tpa_,
    _t223_x2ˍt_t_ - _t223_x1_t_*_tpb_
]

