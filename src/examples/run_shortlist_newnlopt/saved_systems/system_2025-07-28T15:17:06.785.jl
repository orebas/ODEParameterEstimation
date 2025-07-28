# Polynomial system saved on 2025-07-28T15:17:06.786
using Symbolics
using StaticArrays

# Metadata
# num_variables: 9
# timestamp: 2025-07-28T15:17:06.786
# num_equations: 9

# Variables
varlist_str = """
_tpk21_
_tpke_
_t223_C1_t_
_t223_C2_t_
_t223_C1ˍt_t_
_t223_C1ˍtt_t_
_t223_C1ˍttt_t_
_t223_C2ˍt_t_
_t223_C2ˍtt_t_
"""
@variables _tpk21_ _tpke_ _t223_C1_t_ _t223_C2_t_ _t223_C1ˍt_t_ _t223_C1ˍtt_t_ _t223_C1ˍttt_t_ _t223_C2ˍt_t_ _t223_C2ˍtt_t_
varlist = [_tpk21__tpke__t223_C1_t__t223_C2_t__t223_C1ˍt_t__t223_C1ˍtt_t__t223_C1ˍttt_t__t223_C2ˍt_t__t223_C2ˍtt_t_]

# Polynomial System
poly_system = [
    -0.9980207884806054 + _t223_C1_t_,
    0.04371145569612339 + _t223_C1ˍt_t_,
    -0.001914521117753819 + _t223_C1ˍtt_t_,
    8.406676759527825e-5 + _t223_C1ˍttt_t_,
    0.6245098451303577_t223_C1_t_ + _t223_C1ˍt_t_ + _t223_C1_t_*_tpke_ - 1.8002316002901098_t223_C2_t_*_tpk21_,
    0.6245098451303577_t223_C1ˍt_t_ + _t223_C1ˍtt_t_ + _t223_C1ˍt_t_*_tpke_ - 1.8002316002901098_t223_C2ˍt_t_*_tpk21_,
    0.6245098451303577_t223_C1ˍtt_t_ + _t223_C1ˍttt_t_ + _t223_C1ˍtt_t_*_tpke_ - 1.8002316002901098_t223_C2ˍtt_t_*_tpk21_,
    -0.3469052787595313_t223_C1_t_ + _t223_C2ˍt_t_ + _t223_C2_t_*_tpk21_,
    -0.3469052787595313_t223_C1ˍt_t_ + _t223_C2ˍtt_t_ + _t223_C2ˍt_t_*_tpk21_
]

