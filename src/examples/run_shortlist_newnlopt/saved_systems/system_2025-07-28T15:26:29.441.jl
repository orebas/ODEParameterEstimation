# Polynomial system saved on 2025-07-28T15:26:29.441
using Symbolics
using StaticArrays

# Metadata
# num_variables: 12
# timestamp: 2025-07-28T15:26:29.441
# num_equations: 12

# Variables
varlist_str = """
_tpa_
_tpb_
_tpc_
_tpd_
_t56_x1_t_
_t56_x2_t_
_t56_x2ˍt_t_
_t56_x1ˍt_t_
_t223_x1_t_
_t223_x2_t_
_t223_x2ˍt_t_
_t223_x1ˍt_t_
"""
@variables _tpa_ _tpb_ _tpc_ _tpd_ _t56_x1_t_ _t56_x2_t_ _t56_x2ˍt_t_ _t56_x1ˍt_t_ _t223_x1_t_ _t223_x2_t_ _t223_x2ˍt_t_ _t223_x1ˍt_t_
varlist = [_tpa__tpb__tpc__tpd__t56_x1_t__t56_x2_t__t56_x2ˍt_t__t56_x1ˍt_t__t223_x1_t__t223_x2_t__t223_x2ˍt_t__t223_x1ˍt_t_]

# Polynomial System
poly_system = [
    -3.752368191277787 + _t56_x2_t_,
    -8.537465707964634 + _t56_x2ˍt_t_,
    -6.59402592092546 + _t56_x1_t_,
    12.377838678099318 + _t56_x1ˍt_t_,
    _t56_x2ˍt_t_ + _t56_x2_t_*_tpc_ - _t56_x1_t_*_t56_x2_t_*_tpd_,
    _t56_x1ˍt_t_ - _t56_x1_t_*_tpa_ + _t56_x1_t_*_t56_x2_t_*_tpb_,
    -0.43386891691933727 + _t223_x2_t_,
    0.520687502859426 + _t223_x2ˍt_t_,
    -2.249871476284106 + _t223_x1_t_,
    -2.496274304902916 + _t223_x1ˍt_t_,
    _t223_x2ˍt_t_ + _t223_x2_t_*_tpc_ - _t223_x1_t_*_t223_x2_t_*_tpd_,
    _t223_x1ˍt_t_ - _t223_x1_t_*_tpa_ + _t223_x1_t_*_t223_x2_t_*_tpb_
]

