# Polynomial system saved on 2025-07-28T15:08:54.049
using Symbolics
using StaticArrays

# Metadata
# num_variables: 15
# timestamp: 2025-07-28T15:08:54.049
# num_equations: 15

# Variables
varlist_str = """
_tpa_
_tpb_
_t278_x1_t_
_t278_x2_t_
_t278_x3_t_
_t278_x3ˍt_t_
_t278_x3ˍtt_t_
_t278_x3ˍttt_t_
_t278_x3ˍtttt_t_
_t278_x1ˍt_t_
_t278_x2ˍt_t_
_t278_x1ˍtt_t_
_t278_x2ˍtt_t_
_t278_x2ˍttt_t_
_t278_x1ˍttt_t_
"""
@variables _tpa_ _tpb_ _t278_x1_t_ _t278_x2_t_ _t278_x3_t_ _t278_x3ˍt_t_ _t278_x3ˍtt_t_ _t278_x3ˍttt_t_ _t278_x3ˍtttt_t_ _t278_x1ˍt_t_ _t278_x2ˍt_t_ _t278_x1ˍtt_t_ _t278_x2ˍtt_t_ _t278_x2ˍttt_t_ _t278_x1ˍttt_t_
varlist = [_tpa__tpb__t278_x1_t__t278_x2_t__t278_x3_t__t278_x3ˍt_t__t278_x3ˍtt_t__t278_x3ˍttt_t__t278_x3ˍtttt_t__t278_x1ˍt_t__t278_x2ˍt_t__t278_x1ˍtt_t__t278_x2ˍtt_t__t278_x2ˍttt_t__t278_x1ˍttt_t_]

# Polynomial System
poly_system = [
    -8.78257263244966 + _t278_x3_t_,
    -2.0210126212892217 + _t278_x3ˍt_t_,
    -0.2677527147801797 + _t278_x3ˍtt_t_,
    -0.06719552389956718 + _t278_x3ˍttt_t_,
    -0.012074606649036923 + _t278_x3ˍtttt_t_,
    -0.9153681136419027(_t278_x1_t_ + _t278_x2_t_) + _t278_x3ˍt_t_,
    -0.9153681136419027(_t278_x1ˍt_t_ + _t278_x2ˍt_t_) + _t278_x3ˍtt_t_,
    -0.9153681136419027(_t278_x1ˍtt_t_ + _t278_x2ˍtt_t_) + _t278_x3ˍttt_t_,
    -0.9153681136419027(_t278_x1ˍttt_t_ + _t278_x2ˍttt_t_) + _t278_x3ˍtttt_t_,
    _t278_x1ˍt_t_ + _t278_x1_t_*_tpa_,
    _t278_x2ˍt_t_ - _t278_x2_t_*_tpb_,
    _t278_x1ˍtt_t_ + _t278_x1ˍt_t_*_tpa_,
    _t278_x2ˍtt_t_ - _t278_x2ˍt_t_*_tpb_,
    _t278_x2ˍttt_t_ - _t278_x2ˍtt_t_*_tpb_,
    _t278_x1ˍttt_t_ + _t278_x1ˍtt_t_*_tpa_
]

