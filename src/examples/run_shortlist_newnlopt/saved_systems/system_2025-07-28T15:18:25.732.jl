# Polynomial system saved on 2025-07-28T15:18:25.732
using Symbolics
using StaticArrays

# Metadata
# num_variables: 10
# timestamp: 2025-07-28T15:18:25.732
# num_equations: 10

# Variables
varlist_str = """
_tpa_
_tpb_
_t223_x1_t_
_t223_x2_t_
_t223_x1ˍt_t_
_t223_x2ˍt_t_
_t390_x1_t_
_t390_x2_t_
_t390_x1ˍt_t_
_t390_x2ˍt_t_
"""
@variables _tpa_ _tpb_ _t223_x1_t_ _t223_x2_t_ _t223_x1ˍt_t_ _t223_x2ˍt_t_ _t390_x1_t_ _t390_x2_t_ _t390_x1ˍt_t_ _t390_x2ˍt_t_
varlist = [_tpa__tpb__t223_x1_t__t223_x2_t__t223_x1ˍt_t__t223_x2ˍt_t__t390_x1_t__t390_x2_t__t390_x1ˍt_t__t390_x2ˍt_t_]

# Polynomial System
poly_system = [
    3.5955997417987056 + 3.0_t223_x1_t_ - 0.25_t223_x2_t_,
    1.087583105346278 + 2.0_t223_x1_t_ + 0.5_t223_x2_t_,
    1.9853191901975165 + 2.0_t223_x1ˍt_t_ + 0.5_t223_x2ˍt_t_,
    _t223_x1ˍt_t_ + _t223_x2_t_*_tpa_,
    _t223_x2ˍt_t_ - _t223_x1_t_*_tpb_,
    5.186905532345107 + 3.0_t390_x1_t_ - 0.25_t390_x2_t_,
    3.481190545752555 + 2.0_t390_x1_t_ + 0.5_t390_x2_t_,
    0.6648458778006514 + 2.0_t390_x1ˍt_t_ + 0.5_t390_x2ˍt_t_,
    _t390_x1ˍt_t_ + _t390_x2_t_*_tpa_,
    _t390_x2ˍt_t_ - _t390_x1_t_*_tpb_
]

