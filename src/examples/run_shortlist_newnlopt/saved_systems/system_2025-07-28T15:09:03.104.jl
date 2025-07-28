# Polynomial system saved on 2025-07-28T15:09:03.104
using Symbolics
using StaticArrays

# Metadata
# num_variables: 22
# timestamp: 2025-07-28T15:09:03.104
# num_equations: 22

# Variables
varlist_str = """
_tpa_
_tpb_
_t223_x1_t_
_t223_x2_t_
_t223_x3_t_
_t223_x3ˍt_t_
_t223_x3ˍtt_t_
_t223_x3ˍttt_t_
_t223_x1ˍt_t_
_t223_x2ˍt_t_
_t223_x1ˍtt_t_
_t223_x2ˍtt_t_
_t390_x1_t_
_t390_x2_t_
_t390_x3_t_
_t390_x3ˍt_t_
_t390_x3ˍtt_t_
_t390_x3ˍttt_t_
_t390_x1ˍt_t_
_t390_x2ˍt_t_
_t390_x1ˍtt_t_
_t390_x2ˍtt_t_
"""
@variables _tpa_ _tpb_ _t223_x1_t_ _t223_x2_t_ _t223_x3_t_ _t223_x3ˍt_t_ _t223_x3ˍtt_t_ _t223_x3ˍttt_t_ _t223_x1ˍt_t_ _t223_x2ˍt_t_ _t223_x1ˍtt_t_ _t223_x2ˍtt_t_ _t390_x1_t_ _t390_x2_t_ _t390_x3_t_ _t390_x3ˍt_t_ _t390_x3ˍtt_t_ _t390_x3ˍttt_t_ _t390_x1ˍt_t_ _t390_x2ˍt_t_ _t390_x1ˍtt_t_ _t390_x2ˍtt_t_
varlist = [_tpa__tpb__t223_x1_t__t223_x2_t__t223_x3_t__t223_x3ˍt_t__t223_x3ˍtt_t__t223_x3ˍttt_t__t223_x1ˍt_t__t223_x2ˍt_t__t223_x1ˍtt_t__t223_x2ˍtt_t__t390_x1_t__t390_x2_t__t390_x3_t__t390_x3ˍt_t__t390_x3ˍtt_t__t390_x3ˍttt_t__t390_x1ˍt_t__t390_x2ˍt_t__t390_x1ˍtt_t__t390_x2ˍtt_t_]

# Polynomial System
poly_system = [
    -7.709695035051479 + _t223_x3_t_,
    -1.883586532340259 + _t223_x3ˍt_t_,
    -0.2325524730302913 + _t223_x3ˍtt_t_,
    -0.060930258054335454 + _t223_x3ˍttt_t_,
    -0.5325807763659169(_t223_x1_t_ + _t223_x2_t_) + _t223_x3ˍt_t_,
    -0.5325807763659169(_t223_x1ˍt_t_ + _t223_x2ˍt_t_) + _t223_x3ˍtt_t_,
    -0.5325807763659169(_t223_x1ˍtt_t_ + _t223_x2ˍtt_t_) + _t223_x3ˍttt_t_,
    _t223_x1ˍt_t_ + _t223_x1_t_*_tpa_,
    _t223_x2ˍt_t_ - _t223_x2_t_*_tpb_,
    _t223_x1ˍtt_t_ + _t223_x1ˍt_t_*_tpa_,
    _t223_x2ˍtt_t_ - _t223_x2ˍt_t_*_tpb_,
    -11.230605945814906 + _t390_x3_t_,
    -2.366043096851774 + _t390_x3ˍt_t_,
    -0.35121721118511773 + _t390_x3ˍtt_t_,
    -0.0824359719655266 + _t390_x3ˍttt_t_,
    -0.5325807763659169(_t390_x1_t_ + _t390_x2_t_) + _t390_x3ˍt_t_,
    -0.5325807763659169(_t390_x1ˍt_t_ + _t390_x2ˍt_t_) + _t390_x3ˍtt_t_,
    -0.5325807763659169(_t390_x1ˍtt_t_ + _t390_x2ˍtt_t_) + _t390_x3ˍttt_t_,
    _t390_x1ˍt_t_ + _t390_x1_t_*_tpa_,
    _t390_x2ˍt_t_ - _t390_x2_t_*_tpb_,
    _t390_x1ˍtt_t_ + _t390_x1ˍt_t_*_tpa_,
    _t390_x2ˍtt_t_ - _t390_x2ˍt_t_*_tpb_
]

