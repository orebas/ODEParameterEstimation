# Polynomial system saved on 2025-07-28T15:50:34.145
using Symbolics
using StaticArrays

# Metadata
# num_variables: 12
# timestamp: 2025-07-28T15:50:34.133
# num_equations: 12

# Variables
varlist_str = """
_tpa_
_tpb_
_tpc_
_tpd_
_t179_x1_t_
_t179_x2_t_
_t179_x2ˍt_t_
_t179_x1ˍt_t_
_t201_x1_t_
_t201_x2_t_
_t201_x2ˍt_t_
_t201_x1ˍt_t_
"""
@variables _tpa_ _tpb_ _tpc_ _tpd_ _t179_x1_t_ _t179_x2_t_ _t179_x2ˍt_t_ _t179_x1ˍt_t_ _t201_x1_t_ _t201_x2_t_ _t201_x2ˍt_t_ _t201_x1ˍt_t_
varlist = [_tpa__tpb__tpc__tpd__t179_x1_t__t179_x2_t__t179_x2ˍt_t__t179_x1ˍt_t__t201_x1_t__t201_x2_t__t201_x2ˍt_t__t201_x1ˍt_t_]

# Polynomial System
poly_system = [
    -0.3749304547557797 + _t179_x2_t_,
    0.33440885801965176 + _t179_x2ˍt_t_,
    -2.6350914719432548 + _t179_x1_t_,
    -3.0634570243462016 + _t179_x1ˍt_t_,
    _t179_x2ˍt_t_ + _t179_x2_t_*_tpc_ - _t179_x1_t_*_t179_x2_t_*_tpd_,
    _t179_x1ˍt_t_ - _t179_x1_t_*_tpa_ + _t179_x1_t_*_t179_x2_t_*_tpb_,
    -4.804236562870852 + _t201_x2_t_,
    0.8942554840150508 + _t201_x2ˍt_t_,
    -3.518161608033033 + _t201_x1_t_,
    9.928184571145273 + _t201_x1ˍt_t_,
    _t201_x2ˍt_t_ + _t201_x2_t_*_tpc_ - _t201_x1_t_*_t201_x2_t_*_tpd_,
    _t201_x1ˍt_t_ - _t201_x1_t_*_tpa_ + _t201_x1_t_*_t201_x2_t_*_tpb_
]

