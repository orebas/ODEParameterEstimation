# Polynomial system saved on 2025-07-28T15:09:04.789
using Symbolics
using StaticArrays

# Metadata
# num_variables: 22
# timestamp: 2025-07-28T15:09:04.788
# num_equations: 22

# Variables
varlist_str = """
_tpa_
_tpb_
_t278_x1_t_
_t278_x2_t_
_t278_x3_t_
_t278_x3ˍt_t_
_t278_x3ˍtt_t_
_t278_x3ˍttt_t_
_t278_x1ˍt_t_
_t278_x2ˍt_t_
_t278_x1ˍtt_t_
_t278_x2ˍtt_t_
_t445_x1_t_
_t445_x2_t_
_t445_x3_t_
_t445_x3ˍt_t_
_t445_x3ˍtt_t_
_t445_x3ˍttt_t_
_t445_x1ˍt_t_
_t445_x2ˍt_t_
_t445_x1ˍtt_t_
_t445_x2ˍtt_t_
"""
@variables _tpa_ _tpb_ _t278_x1_t_ _t278_x2_t_ _t278_x3_t_ _t278_x3ˍt_t_ _t278_x3ˍtt_t_ _t278_x3ˍttt_t_ _t278_x1ˍt_t_ _t278_x2ˍt_t_ _t278_x1ˍtt_t_ _t278_x2ˍtt_t_ _t445_x1_t_ _t445_x2_t_ _t445_x3_t_ _t445_x3ˍt_t_ _t445_x3ˍtt_t_ _t445_x3ˍttt_t_ _t445_x1ˍt_t_ _t445_x2ˍt_t_ _t445_x1ˍtt_t_ _t445_x2ˍtt_t_
varlist = [_tpa__tpb__t278_x1_t__t278_x2_t__t278_x3_t__t278_x3ˍt_t__t278_x3ˍtt_t__t278_x3ˍttt_t__t278_x1ˍt_t__t278_x2ˍt_t__t278_x1ˍtt_t__t278_x2ˍtt_t__t445_x1_t__t445_x2_t__t445_x3_t__t445_x3ˍt_t__t445_x3ˍtt_t__t445_x3ˍttt_t__t445_x1ˍt_t__t445_x2ˍt_t__t445_x1ˍtt_t__t445_x2ˍtt_t_]

# Polynomial System
poly_system = [
    -8.782572657760175 + _t278_x3_t_,
    -2.021012717387878 + _t278_x3ˍt_t_,
    -0.26775298096459715 + _t278_x3ˍtt_t_,
    -0.06719272611370494 + _t278_x3ˍttt_t_,
    -0.49663309452023074(_t278_x1_t_ + _t278_x2_t_) + _t278_x3ˍt_t_,
    -0.49663309452023074(_t278_x1ˍt_t_ + _t278_x2ˍt_t_) + _t278_x3ˍtt_t_,
    -0.49663309452023074(_t278_x1ˍtt_t_ + _t278_x2ˍtt_t_) + _t278_x3ˍttt_t_,
    _t278_x1ˍt_t_ + _t278_x1_t_*_tpa_,
    _t278_x2ˍt_t_ - _t278_x2_t_*_tpb_,
    _t278_x1ˍtt_t_ + _t278_x1ˍt_t_*_tpa_,
    _t278_x2ˍtt_t_ - _t278_x2ˍt_t_*_tpb_,
    -12.587396652935425 + _t445_x3_t_,
    -2.5721167453702143 + _t445_x3ˍt_t_,
    -0.39895973181786415 + _t445_x3ˍtt_t_,
    -0.09136097275521524 + _t445_x3ˍttt_t_,
    -0.49663309452023074(_t445_x1_t_ + _t445_x2_t_) + _t445_x3ˍt_t_,
    -0.49663309452023074(_t445_x1ˍt_t_ + _t445_x2ˍt_t_) + _t445_x3ˍtt_t_,
    -0.49663309452023074(_t445_x1ˍtt_t_ + _t445_x2ˍtt_t_) + _t445_x3ˍttt_t_,
    _t445_x1ˍt_t_ + _t445_x1_t_*_tpa_,
    _t445_x2ˍt_t_ - _t445_x2_t_*_tpb_,
    _t445_x1ˍtt_t_ + _t445_x1ˍt_t_*_tpa_,
    _t445_x2ˍtt_t_ - _t445_x2ˍt_t_*_tpb_
]

