# Polynomial system saved on 2025-07-28T15:39:33.997
using Symbolics
using StaticArrays

# Metadata
# num_variables: 10
# timestamp: 2025-07-28T15:39:33.997
# num_equations: 10

# Variables
varlist_str = """
_tpa_
_tpb_
_tpc_
_tpd_
_t89_x1_t_
_t89_x2_t_
_t89_x2ˍt_t_
_t89_x2ˍtt_t_
_t89_x1ˍt_t_
_t89_x1ˍtt_t_
"""
@variables _tpa_ _tpb_ _tpc_ _tpd_ _t89_x1_t_ _t89_x2_t_ _t89_x2ˍt_t_ _t89_x2ˍtt_t_ _t89_x1ˍt_t_ _t89_x1ˍtt_t_
varlist = [_tpa__tpb__tpc__tpd__t89_x1_t__t89_x2_t__t89_x2ˍt_t__t89_x2ˍtt_t__t89_x1ˍt_t__t89_x1ˍtt_t_]

# Polynomial System
poly_system = [
    -0.4678908503131869 + _t89_x2_t_,
    0.6150447073641673 + _t89_x2ˍt_t_,
    -1.6591156412744557 + _t89_x2ˍtt_t_,
    -2.106852271291018 + _t89_x1_t_,
    -2.2730722891175588 + _t89_x1ˍt_t_,
    -3.618859198968067 + _t89_x1ˍtt_t_,
    _t89_x2ˍt_t_ + _t89_x2_t_*_tpc_ - _t89_x1_t_*_t89_x2_t_*_tpd_,
    _t89_x2ˍtt_t_ + _t89_x2ˍt_t_*_tpc_ - _t89_x1_t_*_t89_x2ˍt_t_*_tpd_ - _t89_x1ˍt_t_*_t89_x2_t_*_tpd_,
    _t89_x1ˍt_t_ - _t89_x1_t_*_tpa_ + _t89_x1_t_*_t89_x2_t_*_tpb_,
    _t89_x1ˍtt_t_ - _t89_x1ˍt_t_*_tpa_ + _t89_x1_t_*_t89_x2ˍt_t_*_tpb_ + _t89_x1ˍt_t_*_t89_x2_t_*_tpb_
]

