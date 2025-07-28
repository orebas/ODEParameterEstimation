# Polynomial system saved on 2025-07-28T15:09:06.517
using Symbolics
using StaticArrays

# Metadata
# num_variables: 22
# timestamp: 2025-07-28T15:09:06.516
# num_equations: 22

# Variables
varlist_str = """
_tpa_
_tpb_
_t390_x1_t_
_t390_x2_t_
_t390_x3_t_
_t390_x3ˍt_t_
_t390_x3ˍtt_t_
_t390_x3ˍttt_t_
_t390_x1ˍt_t_
_t390_x2ˍt_t_
_t390_x1ˍtt_t_
_t390_x2ˍtt_t_
_t501_x1_t_
_t501_x2_t_
_t501_x3_t_
_t501_x3ˍt_t_
_t501_x3ˍtt_t_
_t501_x3ˍttt_t_
_t501_x1ˍt_t_
_t501_x2ˍt_t_
_t501_x1ˍtt_t_
_t501_x2ˍtt_t_
"""
@variables _tpa_ _tpb_ _t390_x1_t_ _t390_x2_t_ _t390_x3_t_ _t390_x3ˍt_t_ _t390_x3ˍtt_t_ _t390_x3ˍttt_t_ _t390_x1ˍt_t_ _t390_x2ˍt_t_ _t390_x1ˍtt_t_ _t390_x2ˍtt_t_ _t501_x1_t_ _t501_x2_t_ _t501_x3_t_ _t501_x3ˍt_t_ _t501_x3ˍtt_t_ _t501_x3ˍttt_t_ _t501_x1ˍt_t_ _t501_x2ˍt_t_ _t501_x1ˍtt_t_ _t501_x2ˍtt_t_
varlist = [_tpa__tpb__t390_x1_t__t390_x2_t__t390_x3_t__t390_x3ˍt_t__t390_x3ˍtt_t__t390_x3ˍttt_t__t390_x1ˍt_t__t390_x2ˍt_t__t390_x1ˍtt_t__t390_x2ˍtt_t__t501_x1_t__t501_x2_t__t501_x3_t__t501_x3ˍt_t__t501_x3ˍtt_t__t501_x3ˍttt_t__t501_x1ˍt_t__t501_x2ˍt_t__t501_x1ˍtt_t__t501_x2ˍtt_t_]

# Polynomial System
poly_system = [
    -11.23060590493501 + _t390_x3_t_,
    -2.366043019550081 + _t390_x3ˍt_t_,
    -0.35121754733801286 + _t390_x3ˍtt_t_,
    -0.08243849353327296 + _t390_x3ˍttt_t_,
    -0.36772263729092025(_t390_x1_t_ + _t390_x2_t_) + _t390_x3ˍt_t_,
    -0.36772263729092025(_t390_x1ˍt_t_ + _t390_x2ˍt_t_) + _t390_x3ˍtt_t_,
    -0.36772263729092025(_t390_x1ˍtt_t_ + _t390_x2ˍtt_t_) + _t390_x3ˍttt_t_,
    _t390_x1ˍt_t_ + _t390_x1_t_*_tpa_,
    _t390_x2ˍt_t_ - _t390_x2_t_*_tpb_,
    _t390_x1ˍtt_t_ + _t390_x1ˍt_t_*_tpa_,
    _t390_x2ˍtt_t_ - _t390_x2ˍt_t_*_tpb_,
    -14.093083933112556 + _t501_x3_t_,
    -2.810365302227474 + _t501_x3ˍt_t_,
    -0.4528006082582872 + _t501_x3ˍtt_t_,
    -0.1005200959498655 + _t501_x3ˍttt_t_,
    -0.36772263729092025(_t501_x1_t_ + _t501_x2_t_) + _t501_x3ˍt_t_,
    -0.36772263729092025(_t501_x1ˍt_t_ + _t501_x2ˍt_t_) + _t501_x3ˍtt_t_,
    -0.36772263729092025(_t501_x1ˍtt_t_ + _t501_x2ˍtt_t_) + _t501_x3ˍttt_t_,
    _t501_x1ˍt_t_ + _t501_x1_t_*_tpa_,
    _t501_x2ˍt_t_ - _t501_x2_t_*_tpb_,
    _t501_x1ˍtt_t_ + _t501_x1ˍt_t_*_tpa_,
    _t501_x2ˍtt_t_ - _t501_x2ˍt_t_*_tpb_
]

