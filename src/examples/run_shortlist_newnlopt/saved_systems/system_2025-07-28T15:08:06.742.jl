# Polynomial system saved on 2025-07-28T15:08:06.743
using Symbolics
using StaticArrays

# Metadata
# num_variables: 9
# timestamp: 2025-07-28T15:08:06.742
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
    -3.4020006268029563 + _t111_x2_t_,
    -0.32943567092850456 + _t111_x2ˍt_t_,
    -4.0005280348567 + _t111_x3_t_,
    -0.00048006337240551596 + _t111_x3ˍt_t_,
    -1.6471781564276542 + _t111_x1_t_,
    0.34020006963925686 + _t111_x1ˍt_t_,
    _t111_x2ˍt_t_ - _t111_x1_t_*_tpb_,
    _t111_x3ˍt_t_ - _t111_x3_t_*(_tpa_^2)*(_tpb_^2)*_tpbeta_,
    _t111_x1ˍt_t_ + _t111_x2_t_*_tpa_
]

