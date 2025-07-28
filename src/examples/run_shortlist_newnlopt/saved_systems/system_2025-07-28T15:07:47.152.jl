# Polynomial system saved on 2025-07-28T15:07:47.152
using Symbolics
using StaticArrays

# Metadata
# num_variables: 9
# timestamp: 2025-07-28T15:07:47.152
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
    -3.5756286972342015 + _t167_x2_t_,
    -0.29034043963158546 + _t167_x2ˍt_t_,
    -4.000796879363089 + _t167_x3_t_,
    -0.0004800956169953869 + _t167_x3ˍt_t_,
    -1.451702353832229 + _t167_x1_t_,
    0.3575628637486609 + _t167_x1ˍt_t_,
    _t167_x2ˍt_t_ - _t167_x1_t_*_tpb_,
    _t167_x3ˍt_t_ - _t167_x3_t_*(_tpa_^2)*(_tpb_^2)*_tpbeta_,
    _t167_x1ˍt_t_ + _t167_x2_t_*_tpa_
]

