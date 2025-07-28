# Polynomial system saved on 2025-07-28T15:08:09.162
using Symbolics
using StaticArrays

# Metadata
# num_variables: 9
# timestamp: 2025-07-28T15:08:09.162
# num_equations: 9

# Variables
varlist_str = """
_tpa_
_tpb_
_tpbeta_
_t167_x1_t_
_t167_x2_t_
_t167_x3_t_
_t167_x2ˍt_t_
_t167_x3ˍt_t_
_t167_x1ˍt_t_
"""
@variables _tpa_ _tpb_ _tpbeta_ _t167_x1_t_ _t167_x2_t_ _t167_x3_t_ _t167_x2ˍt_t_ _t167_x3ˍt_t_ _t167_x1ˍt_t_
varlist = [_tpa__tpb__tpbeta__t167_x1_t__t167_x2_t__t167_x3_t__t167_x2ˍt_t__t167_x3ˍt_t__t167_x1ˍt_t_]

# Polynomial System
poly_system = [
    -3.5756286914527964 + _t167_x2_t_,
    -0.29034044063277287 + _t167_x2ˍt_t_,
    -4.000796879361791 + _t167_x3_t_,
    -0.0004800956216483501 + _t167_x3ˍt_t_,
    -1.4517023469517256 + _t167_x1_t_,
    0.3575628681402375 + _t167_x1ˍt_t_,
    _t167_x2ˍt_t_ - _t167_x1_t_*_tpb_,
    _t167_x3ˍt_t_ - _t167_x3_t_*(_tpa_^2)*(_tpb_^2)*_tpbeta_,
    _t167_x1ˍt_t_ + _t167_x2_t_*_tpa_
]

