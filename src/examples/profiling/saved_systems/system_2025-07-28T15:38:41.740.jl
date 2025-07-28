# Polynomial system saved on 2025-07-28T15:38:41.740
using Symbolics
using StaticArrays

# Metadata
# num_variables: 9
# timestamp: 2025-07-28T15:38:41.740
# num_equations: 9

# Variables
varlist_str = """
_tpa_
_tpb_
_tpc_
_t134_x1_t_
_t134_x2_t_
_t134_x3_t_
_t134_x2ˍt_t_
_t134_x3ˍt_t_
_t134_x1ˍt_t_
"""
@variables _tpa_ _tpb_ _tpc_ _t134_x1_t_ _t134_x2_t_ _t134_x3_t_ _t134_x2ˍt_t_ _t134_x3ˍt_t_ _t134_x1ˍt_t_
varlist = [_tpa__tpb__tpc__t134_x1_t__t134_x2_t__t134_x3_t__t134_x2ˍt_t__t134_x3ˍt_t__t134_x1ˍt_t_]

# Polynomial System
poly_system = [
    -7.509584831978844 + _t134_x2_t_^3,
    2.7393161428275405 + 3(_t134_x2_t_^2)*_t134_x2ˍt_t_,
    -14.480412688953527 + _t134_x3_t_^3,
    6.365660993759522 + 3(_t134_x3_t_^2)*_t134_x3ˍt_t_,
    -1.6874896899586442 + _t134_x1_t_^3,
    0.832697587586458 + 3(_t134_x1_t_^2)*_t134_x1ˍt_t_,
    _t134_x2ˍt_t_ + _t134_x1_t_*_tpb_,
    _t134_x3ˍt_t_ + _t134_x1_t_*_tpc_,
    _t134_x1ˍt_t_ + _t134_x2_t_*_tpa_
]

