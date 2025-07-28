# Polynomial system saved on 2025-07-28T15:26:21.217
using Symbolics
using StaticArrays

# Metadata
# num_variables: 10
# timestamp: 2025-07-28T15:26:21.217
# num_equations: 10

# Variables
varlist_str = """
_tpa_
_tpb_
_tpc_
_tpd_
_t445_x1_t_
_t445_x2_t_
_t445_x2ˍt_t_
_t445_x2ˍtt_t_
_t445_x1ˍt_t_
_t445_x1ˍtt_t_
"""
@variables _tpa_ _tpb_ _tpc_ _tpd_ _t445_x1_t_ _t445_x2_t_ _t445_x2ˍt_t_ _t445_x2ˍtt_t_ _t445_x1ˍt_t_ _t445_x1ˍtt_t_
varlist = [_tpa__tpb__tpc__tpd__t445_x1_t__t445_x2_t__t445_x2ˍt_t__t445_x2ˍtt_t__t445_x1ˍt_t__t445_x1ˍtt_t_]

# Polynomial System
poly_system = [
    -0.3855170496091925 + _t445_x2_t_,
    0.37159857227806764 + _t445_x2ˍt_t_,
    -1.2632601229080649 + _t445_x2ˍtt_t_,
    -2.5451292535088883 + _t445_x1_t_,
    -2.934622231645317 + _t445_x1ˍt_t_,
    -4.2349108906356605 + _t445_x1ˍtt_t_,
    _t445_x2ˍt_t_ + _t445_x2_t_*_tpc_ - _t445_x1_t_*_t445_x2_t_*_tpd_,
    _t445_x2ˍtt_t_ + _t445_x2ˍt_t_*_tpc_ - _t445_x1_t_*_t445_x2ˍt_t_*_tpd_ - _t445_x1ˍt_t_*_t445_x2_t_*_tpd_,
    _t445_x1ˍt_t_ - _t445_x1_t_*_tpa_ + _t445_x1_t_*_t445_x2_t_*_tpb_,
    _t445_x1ˍtt_t_ - _t445_x1ˍt_t_*_tpa_ + _t445_x1_t_*_t445_x2ˍt_t_*_tpb_ + _t445_x1ˍt_t_*_t445_x2_t_*_tpb_
]

