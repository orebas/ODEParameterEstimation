# Polynomial system saved on 2025-07-28T15:09:00.278
using Symbolics
using StaticArrays

# Metadata
# num_variables: 22
# timestamp: 2025-07-28T15:09:00.277
# num_equations: 22

# Variables
varlist_str = """
_tpa_
_tpb_
_t167_x1_t_
_t167_x2_t_
_t167_x3_t_
_t167_x3ˍt_t_
_t167_x3ˍtt_t_
_t167_x3ˍttt_t_
_t167_x1ˍt_t_
_t167_x2ˍt_t_
_t167_x1ˍtt_t_
_t167_x2ˍtt_t_
_t334_x1_t_
_t334_x2_t_
_t334_x3_t_
_t334_x3ˍt_t_
_t334_x3ˍtt_t_
_t334_x3ˍttt_t_
_t334_x1ˍt_t_
_t334_x2ˍt_t_
_t334_x1ˍtt_t_
_t334_x2ˍtt_t_
"""
@variables _tpa_ _tpb_ _t167_x1_t_ _t167_x2_t_ _t167_x3_t_ _t167_x3ˍt_t_ _t167_x3ˍtt_t_ _t167_x3ˍttt_t_ _t167_x1ˍt_t_ _t167_x2ˍt_t_ _t167_x1ˍtt_t_ _t167_x2ˍtt_t_ _t334_x1_t_ _t334_x2_t_ _t334_x3_t_ _t334_x3ˍt_t_ _t334_x3ˍtt_t_ _t334_x3ˍttt_t_ _t334_x1ˍt_t_ _t334_x2ˍt_t_ _t334_x1ˍtt_t_ _t334_x2ˍtt_t_
varlist = [_tpa__tpb__t167_x1_t__t167_x2_t__t167_x3_t__t167_x3ˍt_t__t167_x3ˍtt_t__t167_x3ˍttt_t__t167_x1ˍt_t__t167_x2ˍt_t__t167_x1ˍtt_t__t167_x2ˍtt_t__t334_x1_t__t334_x2_t__t334_x3_t__t334_x3ˍt_t__t334_x3ˍtt_t__t334_x3ˍttt_t__t334_x1ˍt_t__t334_x2ˍt_t__t334_x1ˍtt_t__t334_x2ˍtt_t_]

# Polynomial System
poly_system = [
    -6.689610533057996 + _t167_x3_t_,
    -1.7626053588593154 + _t167_x3ˍt_t_,
    -0.20005247609324728 + _t167_x3ˍtt_t_,
    -0.05525521397928367 + _t167_x3ˍttt_t_,
    -0.09682150893663677(_t167_x1_t_ + _t167_x2_t_) + _t167_x3ˍt_t_,
    -0.09682150893663677(_t167_x1ˍt_t_ + _t167_x2ˍt_t_) + _t167_x3ˍtt_t_,
    -0.09682150893663677(_t167_x1ˍtt_t_ + _t167_x2ˍtt_t_) + _t167_x3ˍttt_t_,
    _t167_x1ˍt_t_ + _t167_x1_t_*_tpa_,
    _t167_x2ˍt_t_ - _t167_x2_t_*_tpb_,
    _t167_x1ˍtt_t_ + _t167_x1ˍt_t_*_tpa_,
    _t167_x2ˍtt_t_ - _t167_x2ˍt_t_*_tpb_,
    -9.958340726509332 + _t334_x3_t_,
    -2.1818544107491493 + _t334_x3ˍt_t_,
    -0.3073519935758464 + _t334_x3ˍtt_t_,
    -0.0743754912881759 + _t334_x3ˍttt_t_,
    -0.09682150893663677(_t334_x1_t_ + _t334_x2_t_) + _t334_x3ˍt_t_,
    -0.09682150893663677(_t334_x1ˍt_t_ + _t334_x2ˍt_t_) + _t334_x3ˍtt_t_,
    -0.09682150893663677(_t334_x1ˍtt_t_ + _t334_x2ˍtt_t_) + _t334_x3ˍttt_t_,
    _t334_x1ˍt_t_ + _t334_x1_t_*_tpa_,
    _t334_x2ˍt_t_ - _t334_x2_t_*_tpb_,
    _t334_x1ˍtt_t_ + _t334_x1ˍt_t_*_tpa_,
    _t334_x2ˍtt_t_ - _t334_x2ˍt_t_*_tpb_
]

