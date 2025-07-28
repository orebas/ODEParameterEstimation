# Polynomial system saved on 2025-07-28T15:07:17.801
using Symbolics
using StaticArrays

# Metadata
# num_variables: 9
# timestamp: 2025-07-28T15:07:17.564
# num_equations: 9

# Variables
varlist_str = """
_tpa_
_tpb_
_tpbeta_
_t56_x1_t_
_t56_x2_t_
_t56_x3_t_
_t56_x2ˍt_t_
_t56_x3ˍt_t_
_t56_x1ˍt_t_
"""
@variables _tpa_ _tpb_ _tpbeta_ _t56_x1_t_ _t56_x2_t_ _t56_x3_t_ _t56_x2ˍt_t_ _t56_x3ˍt_t_ _t56_x1ˍt_t_
varlist = [_tpa__tpb__tpbeta__t56_x1_t__t56_x2_t__t56_x3_t__t56_x2ˍt_t__t56_x3ˍt_t__t56_x1ˍt_t_]

# Polynomial System
poly_system = [
    -3.210707829224334 + _t56_x2_t_,
    -0.3658238196241816 + _t56_x2ˍt_t_,
    -4.0002640087162495 + _t56_x3_t_,
    -0.00048003164787531824 + _t56_x3ˍt_t_,
    -1.8291193659448775 + _t56_x1_t_,
    0.32107077802697115 + _t56_x1ˍt_t_,
    _t56_x2ˍt_t_ - _t56_x1_t_*_tpb_,
    _t56_x3ˍt_t_ - _t56_x3_t_*(_tpa_^2)*(_tpb_^2)*_tpbeta_,
    _t56_x1ˍt_t_ + _t56_x2_t_*_tpa_
]

