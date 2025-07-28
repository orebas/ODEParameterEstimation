# Polynomial system saved on 2025-07-28T15:17:13.676
using Symbolics
using StaticArrays

# Metadata
# num_variables: 9
# timestamp: 2025-07-28T15:17:13.676
# num_equations: 9

# Variables
varlist_str = """
_tpk21_
_tpke_
_t445_C1_t_
_t445_C2_t_
_t445_C1ˍt_t_
_t445_C1ˍtt_t_
_t445_C1ˍttt_t_
_t445_C2ˍt_t_
_t445_C2ˍtt_t_
"""
@variables _tpk21_ _tpke_ _t445_C1_t_ _t445_C2_t_ _t445_C1ˍt_t_ _t445_C1ˍtt_t_ _t445_C1ˍttt_t_ _t445_C2ˍt_t_ _t445_C2ˍtt_t_
varlist = [_tpk21__tpke__t445_C1_t__t445_C2_t__t445_C1ˍt_t__t445_C1ˍtt_t__t445_C1ˍttt_t__t445_C2ˍt_t__t445_C2ˍtt_t_]

# Polynomial System
poly_system = [
    -0.3924265346931323 + _t445_C1_t_,
    0.017187528669598273 + _t445_C1ˍt_t_,
    -0.0007527807516767293 + _t445_C1ˍtt_t_,
    3.297035145431726e-5 + _t445_C1ˍttt_t_,
    0.6398914861102692_t445_C1_t_ + _t445_C1ˍt_t_ + _t445_C1_t_*_tpke_ - 0.14273437465063155_t445_C2_t_*_tpk21_,
    0.6398914861102692_t445_C1ˍt_t_ + _t445_C1ˍtt_t_ + _t445_C1ˍt_t_*_tpke_ - 0.14273437465063155_t445_C2ˍt_t_*_tpk21_,
    0.6398914861102692_t445_C1ˍtt_t_ + _t445_C1ˍttt_t_ + _t445_C1ˍtt_t_*_tpke_ - 0.14273437465063155_t445_C2ˍtt_t_*_tpk21_,
    -4.48309307184426_t445_C1_t_ + _t445_C2ˍt_t_ + _t445_C2_t_*_tpk21_,
    -4.48309307184426_t445_C1ˍt_t_ + _t445_C2ˍtt_t_ + _t445_C2ˍt_t_*_tpk21_
]

