# Polynomial system saved on 2025-07-28T15:29:41.645
using Symbolics
using StaticArrays

# Metadata
# num_variables: 8
# timestamp: 2025-07-28T15:29:41.645
# num_equations: 8

# Variables
varlist_str = """
_tpa_
_tpb_
_t278_X_t_
_t278_Y_t_
_t278_Xˍt_t_
_t445_X_t_
_t445_Y_t_
_t445_Xˍt_t_
"""
@variables _tpa_ _tpb_ _t278_X_t_ _t278_Y_t_ _t278_Xˍt_t_ _t445_X_t_ _t445_Y_t_ _t445_Xˍt_t_
varlist = [_tpa__tpb__t278_X_t__t278_Y_t__t278_Xˍt_t__t445_X_t__t445_Y_t__t445_Xˍt_t_]

# Polynomial System
poly_system = [
    -4.014377526297339 + _t278_Y_t_,
    -0.3930738403361734 + _t278_X_t_,
    -0.047954449111867796 + _t278_Xˍt_t_,
    -1.0 + _t278_Xˍt_t_ + _t278_X_t_*(1 + _tpb_) - (_t278_X_t_^2)*_t278_Y_t_*_tpa_,
    -3.7378658143616548 + _t445_Y_t_,
    -0.3755110047444232 + _t445_X_t_,
    -0.025026884162588033 + _t445_Xˍt_t_,
    -1.0 + _t445_Xˍt_t_ + _t445_X_t_*(1 + _tpb_) - (_t445_X_t_^2)*_t445_Y_t_*_tpa_
]

