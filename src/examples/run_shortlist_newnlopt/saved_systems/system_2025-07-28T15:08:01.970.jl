# Polynomial system saved on 2025-07-28T15:08:01.970
using Symbolics
using StaticArrays

# Metadata
# num_variables: 9
# timestamp: 2025-07-28T15:08:01.970
# num_equations: 9

# Variables
varlist_str = """
_tpa_
_tpb_
_tpbeta_
_t111_x1_t_
_t111_x2_t_
_t111_x3_t_
_t111_x2ˍt_t_
_t111_x3ˍt_t_
_t111_x1ˍt_t_
"""
@variables _tpa_ _tpb_ _tpbeta_ _t111_x1_t_ _t111_x2_t_ _t111_x3_t_ _t111_x2ˍt_t_ _t111_x3ˍt_t_ _t111_x1ˍt_t_
varlist = [_tpa__tpb__tpbeta__t111_x1_t__t111_x2_t__t111_x3_t__t111_x2ˍt_t__t111_x3ˍt_t__t111_x1ˍt_t_]

# Polynomial System
poly_system = [
    -3.4020006254166053 + _t111_x2_t_,
    -0.3294356308799564 + _t111_x2ˍt_t_,
    -4.000528034849532 + _t111_x3_t_,
    -0.00048006336418460194 + _t111_x3ˍt_t_,
    -1.64717815439997 + _t111_x1_t_,
    0.34020006254171875 + _t111_x1ˍt_t_,
    _t111_x2ˍt_t_ - _t111_x1_t_*_tpb_,
    _t111_x3ˍt_t_ - _t111_x3_t_*(_tpa_^2)*(_tpb_^2)*_tpbeta_,
    _t111_x1ˍt_t_ + _t111_x2_t_*_tpa_
]

