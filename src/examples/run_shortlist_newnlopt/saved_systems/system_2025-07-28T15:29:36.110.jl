# Polynomial system saved on 2025-07-28T15:29:36.111
using Symbolics
using StaticArrays

# Metadata
# num_variables: 8
# timestamp: 2025-07-28T15:29:36.110
# num_equations: 8

# Variables
varlist_str = """
_tpa_
_tpb_
_t223_X_t_
_t223_Y_t_
_t223_Xˍt_t_
_t390_X_t_
_t390_Y_t_
_t390_Xˍt_t_
"""
@variables _tpa_ _tpb_ _t223_X_t_ _t223_Y_t_ _t223_Xˍt_t_ _t390_X_t_ _t390_Y_t_ _t390_Xˍt_t_
varlist = [_tpa__tpb__t223_X_t__t223_Y_t__t223_Xˍt_t__t390_X_t__t390_Y_t__t390_Xˍt_t_]

# Polynomial System
poly_system = [
    -2.5255865858437256 + _t223_Y_t_,
    -0.5764897637350113 + _t223_X_t_,
    0.4666043698997358 + _t223_Xˍt_t_,
    -1.0 + _t223_Xˍt_t_ + _t223_X_t_*(1 + _tpb_) - (_t223_X_t_^2)*_t223_Y_t_*_tpa_,
    -2.0656604038412194 + _t390_Y_t_,
    -0.9037197726260083 + _t390_X_t_,
    0.9278373419569197 + _t390_Xˍt_t_,
    -1.0 + _t390_Xˍt_t_ + _t390_X_t_*(1 + _tpb_) - (_t390_X_t_^2)*_t390_Y_t_*_tpa_
]

