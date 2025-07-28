# Polynomial system saved on 2025-07-28T15:11:45.763
using Symbolics
using StaticArrays

# Metadata
# num_variables: 9
# timestamp: 2025-07-28T15:11:45.762
# num_equations: 9

# Variables
varlist_str = """
_tpa_
_tpb_
_tpc_
_t167_x1_t_
_t167_x2_t_
_t167_x3_t_
_t167_x2ˍt_t_
_t167_x3ˍt_t_
_t167_x1ˍt_t_
"""
@variables _tpa_ _tpb_ _tpc_ _t167_x1_t_ _t167_x2_t_ _t167_x3_t_ _t167_x2ˍt_t_ _t167_x3ˍt_t_ _t167_x1ˍt_t_
varlist = [_tpa__tpb__tpc__t167_x1_t__t167_x2_t__t167_x3_t__t167_x2ˍt_t__t167_x3ˍt_t__t167_x1ˍt_t_]

# Polynomial System
poly_system = [
    -14.048679572852938 + _t167_x2_t_^3,
    5.424393081165921 + 3(_t167_x2_t_^2)*_t167_x2ˍt_t_,
    -30.353773174131288 + _t167_x3_t_^3,
    13.59858745847163 + 3(_t167_x3_t_^2)*_t167_x3ˍt_t_,
    -3.7439381531723663 + _t167_x1_t_^3,
    1.7453623019379538 + 3(_t167_x1_t_^2)*_t167_x1ˍt_t_,
    _t167_x2ˍt_t_ + _t167_x1_t_*_tpb_,
    _t167_x3ˍt_t_ + _t167_x1_t_*_tpc_,
    _t167_x1ˍt_t_ + _t167_x2_t_*_tpa_
]

