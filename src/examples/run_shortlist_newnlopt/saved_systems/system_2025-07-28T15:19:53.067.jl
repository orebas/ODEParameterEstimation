# Polynomial system saved on 2025-07-28T15:19:53.067
using Symbolics
using StaticArrays

# Metadata
# num_variables: 6
# timestamp: 2025-07-28T15:19:53.067
# num_equations: 6

# Variables
varlist_str = """
_tpa_
_tpc_
_t278_x1_t_
_t278_x2_t_
_t278_x2ˍt_t_
_t278_x1ˍt_t_
"""
@variables _tpa_ _tpc_ _t278_x1_t_ _t278_x2_t_ _t278_x2ˍt_t_ _t278_x1ˍt_t_
varlist = [_tpa__tpc__t278_x1_t__t278_x2_t__t278_x2ˍt_t__t278_x1ˍt_t_]

# Polynomial System
poly_system = [
    -5.419455014561052 + _t278_x2_t_,
    -0.7580544773498996 + _t278_x2ˍt_t_,
    -1.5161089966543164 + _t278_x1_t_,
    0.15161089321661586 + _t278_x1ˍt_t_,
    _t278_x2ˍt_t_ + _t278_x1_t_*(-0.672186869481938 - _tpc_),
    _t278_x1ˍt_t_ + _t278_x1_t_*_tpa_
]

