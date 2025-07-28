# Polynomial system saved on 2025-07-28T15:17:23.927
using Symbolics
using StaticArrays

# Metadata
# num_variables: 12
# timestamp: 2025-07-28T15:17:23.927
# num_equations: 12

# Variables
varlist_str = """
_tpk21_
_tpke_
_t223_C1_t_
_t223_C2_t_
_t223_C1ˍt_t_
_t223_C1ˍtt_t_
_t223_C2ˍt_t_
_t390_C1_t_
_t390_C2_t_
_t390_C1ˍt_t_
_t390_C1ˍtt_t_
_t390_C2ˍt_t_
"""
@variables _tpk21_ _tpke_ _t223_C1_t_ _t223_C2_t_ _t223_C1ˍt_t_ _t223_C1ˍtt_t_ _t223_C2ˍt_t_ _t390_C1_t_ _t390_C2_t_ _t390_C1ˍt_t_ _t390_C1ˍtt_t_ _t390_C2ˍt_t_
varlist = [_tpk21__tpke__t223_C1_t__t223_C2_t__t223_C1ˍt_t__t223_C1ˍtt_t__t223_C2ˍt_t__t390_C1_t__t390_C2_t__t390_C1ˍt_t__t390_C1ˍtt_t__t390_C2ˍt_t_]

# Polynomial System
poly_system = [
    -0.9980207943742148 + _t223_C1_t_,
    0.043711445874430196 + _t223_C1ˍt_t_,
    -0.0019145897790947574 + _t223_C1ˍtt_t_,
    0.25165309047171414_t223_C1_t_ + _t223_C1ˍt_t_ + _t223_C1_t_*_tpke_ - 3.32951616714105_t223_C2_t_*_tpk21_,
    0.25165309047171414_t223_C1ˍt_t_ + _t223_C1ˍtt_t_ + _t223_C1ˍt_t_*_tpke_ - 3.32951616714105_t223_C2ˍt_t_*_tpk21_,
    -0.07558248040819718_t223_C1_t_ + _t223_C2ˍt_t_ + _t223_C2_t_*_tpk21_,
    -0.49452767700230926 + _t390_C1_t_,
    0.02165935231761497 + _t390_C1ˍt_t_,
    -0.0009486909295527204 + _t390_C1ˍtt_t_,
    0.25165309047171414_t390_C1_t_ + _t390_C1ˍt_t_ + _t390_C1_t_*_tpke_ - 3.32951616714105_t390_C2_t_*_tpk21_,
    0.25165309047171414_t390_C1ˍt_t_ + _t390_C1ˍtt_t_ + _t390_C1ˍt_t_*_tpke_ - 3.32951616714105_t390_C2ˍt_t_*_tpk21_,
    -0.07558248040819718_t390_C1_t_ + _t390_C2ˍt_t_ + _t390_C2_t_*_tpk21_
]

