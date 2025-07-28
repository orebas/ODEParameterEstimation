# Polynomial system saved on 2025-07-28T15:39:36.675
using Symbolics
using StaticArrays

# Metadata
# num_variables: 10
# timestamp: 2025-07-28T15:39:36.675
# num_equations: 10

# Variables
varlist_str = """
_tpa_
_tpb_
_tpc_
_tpd_
_t201_x1_t_
_t201_x2_t_
_t201_x2ˍt_t_
_t201_x2ˍtt_t_
_t201_x1ˍt_t_
_t201_x1ˍtt_t_
"""
@variables _tpa_ _tpb_ _tpc_ _tpd_ _t201_x1_t_ _t201_x2_t_ _t201_x2ˍt_t_ _t201_x2ˍtt_t_ _t201_x1ˍt_t_ _t201_x1ˍtt_t_
varlist = [_tpa__tpb__tpc__tpd__t201_x1_t__t201_x2_t__t201_x2ˍt_t__t201_x2ˍtt_t__t201_x1ˍt_t__t201_x1ˍtt_t_]

# Polynomial System
poly_system = [
    -4.804236574304596 + _t201_x2_t_,
    0.8942601488127372 + _t201_x2ˍt_t_,
    38.214916021086744 + _t201_x2ˍtt_t_,
    -3.5181616100828266 + _t201_x1_t_,
    9.928102890023878 + _t201_x1ˍt_t_,
    -31.308307722576302 + _t201_x1ˍtt_t_,
    _t201_x2ˍt_t_ + _t201_x2_t_*_tpc_ - _t201_x1_t_*_t201_x2_t_*_tpd_,
    _t201_x2ˍtt_t_ + _t201_x2ˍt_t_*_tpc_ - _t201_x1_t_*_t201_x2ˍt_t_*_tpd_ - _t201_x1ˍt_t_*_t201_x2_t_*_tpd_,
    _t201_x1ˍt_t_ - _t201_x1_t_*_tpa_ + _t201_x1_t_*_t201_x2_t_*_tpb_,
    _t201_x1ˍtt_t_ - _t201_x1ˍt_t_*_tpa_ + _t201_x1_t_*_t201_x2ˍt_t_*_tpb_ + _t201_x1ˍt_t_*_t201_x2_t_*_tpb_
]

