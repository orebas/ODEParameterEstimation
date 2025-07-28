# Polynomial system saved on 2025-07-28T15:45:26.725
using Symbolics
using StaticArrays

# Metadata
# num_variables: 10
# timestamp: 2025-07-28T15:45:26.725
# num_equations: 10

# Variables
varlist_str = """
_tpa_
_tpb_
_t89_x1_t_
_t89_x2_t_
_t89_x1ˍt_t_
_t89_x2ˍt_t_
_t156_x1_t_
_t156_x2_t_
_t156_x1ˍt_t_
_t156_x2ˍt_t_
"""
@variables _tpa_ _tpb_ _t89_x1_t_ _t89_x2_t_ _t89_x1ˍt_t_ _t89_x2ˍt_t_ _t156_x1_t_ _t156_x2_t_ _t156_x1ˍt_t_ _t156_x2ˍt_t_
varlist = [_tpa__tpb__t89_x1_t__t89_x2_t__t89_x1ˍt_t__t89_x2ˍt_t__t156_x1_t__t156_x2_t__t156_x1ˍt_t__t156_x2ˍt_t_]

# Polynomial System
poly_system = [
    3.552368519284018 + 3.0_t89_x1_t_ - 0.25_t89_x2_t_,
    1.0478080137529984 + 2.0_t89_x1_t_ + 0.5_t89_x2_t_,
    1.9921524563296202 + 2.0_t89_x1ˍt_t_ + 0.5_t89_x2ˍt_t_,
    _t89_x1ˍt_t_ + _t89_x2_t_*_tpa_,
    _t89_x2ˍt_t_ - _t89_x1_t_*_tpb_,
    5.192542157067113 + 3.0_t156_x1_t_ - 0.25_t156_x2_t_,
    3.471092604331921 + 2.0_t156_x1_t_ + 0.5_t156_x2_t_,
    0.6815314838047589 + 2.0_t156_x1ˍt_t_ + 0.5_t156_x2ˍt_t_,
    _t156_x1ˍt_t_ + _t156_x2_t_*_tpa_,
    _t156_x2ˍt_t_ - _t156_x1_t_*_tpb_
]

