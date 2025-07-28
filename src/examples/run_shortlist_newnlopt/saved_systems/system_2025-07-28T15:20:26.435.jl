# Polynomial system saved on 2025-07-28T15:20:26.435
using Symbolics
using StaticArrays

# Metadata
# num_variables: 6
# timestamp: 2025-07-28T15:20:26.435
# num_equations: 6

# Variables
varlist_str = """
_tpa_
_tpb_
_t56_x1_t_
_t56_x2_t_
_t56_x2ˍt_t_
_t56_x1ˍt_t_
"""
@variables _tpa_ _tpb_ _t56_x1_t_ _t56_x2_t_ _t56_x2ˍt_t_ _t56_x1ˍt_t_
varlist = [_tpa__tpb__t56_x1_t__t56_x2_t__t56_x2ˍt_t__t56_x1ˍt_t_]

# Polynomial System
poly_system = [
    -0.7791443343414963 + _t56_x2_t_,
    -0.1381026801347102 + _t56_x2ˍt_t_,
    -0.17262835549880606 + _t56_x1_t_,
    0.31165773732209334 + _t56_x1ˍt_t_,
    _t56_x2ˍt_t_ - _t56_x1_t_*_tpb_,
    _t56_x1ˍt_t_ + _t56_x2_t_*_tpa_
]

