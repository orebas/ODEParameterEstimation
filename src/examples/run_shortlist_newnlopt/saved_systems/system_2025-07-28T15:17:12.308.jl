# Polynomial system saved on 2025-07-28T15:17:12.309
using Symbolics
using StaticArrays

# Metadata
# num_variables: 9
# timestamp: 2025-07-28T15:17:12.309
# num_equations: 9

# Variables
varlist_str = """
_tpk21_
_tpke_
_t167_C1_t_
_t167_C2_t_
_t167_C1ˍt_t_
_t167_C1ˍtt_t_
_t167_C1ˍttt_t_
_t167_C2ˍt_t_
_t167_C2ˍtt_t_
"""
@variables _tpk21_ _tpke_ _t167_C1_t_ _t167_C2_t_ _t167_C1ˍt_t_ _t167_C1ˍtt_t_ _t167_C1ˍttt_t_ _t167_C2ˍt_t_ _t167_C2ˍtt_t_
varlist = [_tpk21__tpke__t167_C1_t__t167_C2_t__t167_C1ˍt_t__t167_C1ˍtt_t__t167_C1ˍttt_t__t167_C2ˍt_t__t167_C2ˍtt_t_]

# Polynomial System
poly_system = [
    -1.262992911891813 + _t167_C1_t_,
    0.05532385738347412 + _t167_C1ˍt_t_,
    -0.002429237449292243 + _t167_C1ˍtt_t_,
    0.00011166905247783632 + _t167_C1ˍttt_t_,
    0.5304192527006654_t167_C1_t_ + _t167_C1ˍt_t_ + _t167_C1_t_*_tpke_ - 0.22146179749849007_t167_C2_t_*_tpk21_,
    0.5304192527006654_t167_C1ˍt_t_ + _t167_C1ˍtt_t_ + _t167_C1ˍt_t_*_tpke_ - 0.22146179749849007_t167_C2ˍt_t_*_tpk21_,
    0.5304192527006654_t167_C1ˍtt_t_ + _t167_C1ˍttt_t_ + _t167_C1ˍtt_t_*_tpke_ - 0.22146179749849007_t167_C2ˍtt_t_*_tpk21_,
    -2.3950823965667567_t167_C1_t_ + _t167_C2ˍt_t_ + _t167_C2_t_*_tpk21_,
    -2.3950823965667567_t167_C1ˍt_t_ + _t167_C2ˍtt_t_ + _t167_C2ˍt_t_*_tpk21_
]

