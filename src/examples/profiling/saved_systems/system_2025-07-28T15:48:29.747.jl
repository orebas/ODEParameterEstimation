# Polynomial system saved on 2025-07-28T15:48:29.748
using Symbolics
using StaticArrays

# Metadata
# num_variables: 9
# timestamp: 2025-07-28T15:48:29.747
# num_equations: 9

# Variables
varlist_str = """
_tpa_
_tpb_
_tpc_
_t89_x1_t_
_t89_x2_t_
_t89_x3_t_
_t89_x2ˍt_t_
_t89_x3ˍt_t_
_t89_x1ˍt_t_
"""
@variables _tpa_ _tpb_ _tpc_ _t89_x1_t_ _t89_x2_t_ _t89_x3_t_ _t89_x2ˍt_t_ _t89_x3ˍt_t_ _t89_x1ˍt_t_
varlist = [_tpa__tpb__tpc__t89_x1_t__t89_x2_t__t89_x3_t__t89_x2ˍt_t__t89_x3ˍt_t__t89_x1ˍt_t_]

# Polynomial System
poly_system = [
    -11.422683264379849 + _t89_x2_t_^3,
    4.342287114862428 + 3(_t89_x2_t_^2)*_t89_x2ˍt_t_,
    -23.84219775535664 + _t89_x3_t_^3,
    10.638049711216727 + 3(_t89_x3_t_^2)*_t89_x3ˍt_t_,
    -2.905131351761657 + _t89_x1_t_^3,
    1.375586588793479 + 3(_t89_x1_t_^2)*_t89_x1ˍt_t_,
    _t89_x2ˍt_t_ + _t89_x1_t_*_tpb_,
    _t89_x3ˍt_t_ + _t89_x1_t_*_tpc_,
    _t89_x1ˍt_t_ + _t89_x2_t_*_tpa_
]

