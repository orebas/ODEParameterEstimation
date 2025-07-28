# Polynomial system saved on 2025-07-28T15:08:02.080
using Symbolics
using StaticArrays

# Metadata
# num_variables: 9
# timestamp: 2025-07-28T15:08:02.080
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
    -3.5756286929846977 + _t167_x2_t_,
    -0.2903404708236556 + _t167_x2ˍt_t_,
    -4.000796879366551 + _t167_x3_t_,
    -0.00048009562552697727 + _t167_x3ˍt_t_,
    -1.4517023541181697 + _t167_x1_t_,
    0.35756286929841097 + _t167_x1ˍt_t_,
    _t167_x2ˍt_t_ - _t167_x1_t_*_tpb_,
    _t167_x3ˍt_t_ - _t167_x3_t_*(_tpa_^2)*(_tpb_^2)*_tpbeta_,
    _t167_x1ˍt_t_ + _t167_x2_t_*_tpa_
]

