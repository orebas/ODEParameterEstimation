# Polynomial system saved on 2025-07-28T15:17:17.289
using Symbolics
using StaticArrays

# Metadata
# num_variables: 12
# timestamp: 2025-07-28T15:17:17.289
# num_equations: 12

# Variables
varlist_str = """
_tpk21_
_tpke_
_t56_C1_t_
_t56_C2_t_
_t56_C1ˍt_t_
_t56_C1ˍtt_t_
_t56_C2ˍt_t_
_t223_C1_t_
_t223_C2_t_
_t223_C1ˍt_t_
_t223_C1ˍtt_t_
_t223_C2ˍt_t_
"""
@variables _tpk21_ _tpke_ _t56_C1_t_ _t56_C2_t_ _t56_C1ˍt_t_ _t56_C1ˍtt_t_ _t56_C2ˍt_t_ _t223_C1_t_ _t223_C2_t_ _t223_C1ˍt_t_ _t223_C1ˍtt_t_ _t223_C2ˍt_t_
varlist = [_tpk21__tpke__t56_C1_t__t56_C2_t__t56_C1ˍt_t__t56_C1ˍtt_t__t56_C2ˍt_t__t223_C1_t__t223_C2_t__t223_C1ˍt_t__t223_C1ˍtt_t__t223_C2ˍt_t_]

# Polynomial System
poly_system = [
    -2.0953257784914485 + _t56_C1_t_,
    0.15773091727194882 + _t56_C1ˍt_t_,
    -0.06338517309599544 + _t56_C1ˍtt_t_,
    0.0885369226375835_t56_C1_t_ + _t56_C1ˍt_t_ + _t56_C1_t_*_tpke_ - 0.3053486098369606_t56_C2_t_*_tpk21_,
    0.0885369226375835_t56_C1ˍt_t_ + _t56_C1ˍtt_t_ + _t56_C1ˍt_t_*_tpke_ - 0.3053486098369606_t56_C2ˍt_t_*_tpk21_,
    -0.28995358022051365_t56_C1_t_ + _t56_C2ˍt_t_ + _t56_C2_t_*_tpk21_,
    -0.9980207696210551 + _t223_C1_t_,
    0.04371151457987201 + _t223_C1ˍt_t_,
    -0.0019146106341227927 + _t223_C1ˍtt_t_,
    0.0885369226375835_t223_C1_t_ + _t223_C1ˍt_t_ + _t223_C1_t_*_tpke_ - 0.3053486098369606_t223_C2_t_*_tpk21_,
    0.0885369226375835_t223_C1ˍt_t_ + _t223_C1ˍtt_t_ + _t223_C1ˍt_t_*_tpke_ - 0.3053486098369606_t223_C2ˍt_t_*_tpk21_,
    -0.28995358022051365_t223_C1_t_ + _t223_C2ˍt_t_ + _t223_C2_t_*_tpk21_
]

