# Polynomial system saved on 2025-07-28T15:17:29.498
using Symbolics
using StaticArrays

# Metadata
# num_variables: 12
# timestamp: 2025-07-28T15:17:29.498
# num_equations: 12

# Variables
varlist_str = """
_tpk21_
_tpke_
_t445_C1_t_
_t445_C2_t_
_t445_C1ˍt_t_
_t445_C1ˍtt_t_
_t445_C2ˍt_t_
_t501_C1_t_
_t501_C2_t_
_t501_C1ˍt_t_
_t501_C1ˍtt_t_
_t501_C2ˍt_t_
"""
@variables _tpk21_ _tpke_ _t445_C1_t_ _t445_C2_t_ _t445_C1ˍt_t_ _t445_C1ˍtt_t_ _t445_C2ˍt_t_ _t501_C1_t_ _t501_C2_t_ _t501_C1ˍt_t_ _t501_C1ˍtt_t_ _t501_C2ˍt_t_
varlist = [_tpk21__tpke__t445_C1_t__t445_C2_t__t445_C1ˍt_t__t445_C1ˍtt_t__t445_C2ˍt_t__t501_C1_t__t501_C2_t__t501_C1ˍt_t__t501_C1ˍtt_t__t501_C2ˍt_t_]

# Polynomial System
poly_system = [
    -0.3924265384141111 + _t445_C1_t_,
    0.017187544436346007 + _t445_C1ˍt_t_,
    -0.0007527404169338585 + _t445_C1ˍtt_t_,
    0.6978332467871728_t445_C1_t_ + _t445_C1ˍt_t_ + _t445_C1_t_*_tpke_ - 0.7962646865881218_t445_C2_t_*_tpk21_,
    0.6978332467871728_t445_C1ˍt_t_ + _t445_C1ˍtt_t_ + _t445_C1ˍt_t_*_tpke_ - 0.7962646865881218_t445_C2ˍt_t_*_tpk21_,
    -0.8763835173669282_t445_C1_t_ + _t445_C2ˍt_t_ + _t445_C2_t_*_tpk21_,
    -0.3100987888811255 + _t501_C1_t_,
    0.013581285269275796 + _t501_C1ˍt_t_,
    -0.0006054646349009489 + _t501_C1ˍtt_t_,
    0.6978332467871728_t501_C1_t_ + _t501_C1ˍt_t_ + _t501_C1_t_*_tpke_ - 0.7962646865881218_t501_C2_t_*_tpk21_,
    0.6978332467871728_t501_C1ˍt_t_ + _t501_C1ˍtt_t_ + _t501_C1ˍt_t_*_tpke_ - 0.7962646865881218_t501_C2ˍt_t_*_tpk21_,
    -0.8763835173669282_t501_C1_t_ + _t501_C2ˍt_t_ + _t501_C2_t_*_tpk21_
]

