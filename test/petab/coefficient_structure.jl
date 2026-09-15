@testset "Explicit coefficient definitions preserve inference constraints" begin
    N = ODEParameterEstimation.Nemo
    G = ODEParameterEstimation.Groebner
    ring, (a, x, phi, z) = N.polynomial_ring(N.QQ, ["a", "x", "phi", "z"])
    field = N.fraction_field(ring)
    names = Dict(string(v)=>field(v) for v in N.gens(ring))
    guards = N.QQMPolyRingElem[]
    ratio = Ext._coefficient_formula("(a^2-1)/(a-1)", names, field, guards)
    @test ratio == field(a+1)
    @test a-1 in guards # cancellation must not silently widen the source domain
    @test_throws ArgumentError Ext._coefficient_substitute(field(1)/(a-1), Dict("a"=>field(1)))
    @test_throws ArgumentError Ext._coefficient_formula("sin(a)", names, field, guards)
    @test_throws ArgumentError Ext._coefficient_formula("a^(1/2)", names, field, guards)
    @test_throws ArgumentError Ext._resolve_coefficient_definitions(OrderedDict("a"=>field(phi), "phi"=>field(a)))
    @test Ext._resolve_coefficient_definitions(OrderedDict("phi"=>field(a+1), "a"=>field(2)))["phi"] == field(3)

    # x'=-(a²/(1+a))x, with exact x=1, x'=-1. Two complex branches
    # remain after lifting, and the auxiliary coefficient is uniquely defined.
    small, (a, x, z) = N.polynomial_ring(N.QQ, ["a", "x", "z"])
    original = [x-1, a^2*x-(a+1), z*(a+1)-1]
    big, (a, x, phi, z) = N.polynomial_ring(N.QQ, ["a", "x", "phi", "z"])
    lifted = [x-1, phi*x-1, (a+1)*phi-a^2, z*(a+1)-1]
    @test length(G.quotient_basis(G.groebner(original))) == 2
    @test length(G.quotient_basis(G.groebner(lifted))) == 2
    # A double root must retain length two, despite having one distinct point.
    @test length(G.quotient_basis(G.groebner([phi, phi-a^2, x-1, z-1]))) == 2
    # The cancelled source pole a=1 is not a valid root when phi=2.
    @test G.groebner([phi-2, phi-(a+1), z*(a-1)-1, x-1]) == [one(big)]

    mktempdir() do directory
        for file in readdir(dirname(fixture))
            cp(joinpath(dirname(fixture), file), joinpath(directory, file))
        end
        path = joinpath(directory, "model.xml")
        xml = read(path, String)
        xml = replace(xml, "</listOfParameters>" => """
          <parameter id="L" value="0" constant="false"/>
          <parameter id="input" value="99" constant="true"/>
          </listOfParameters>
          <listOfRules><assignmentRule variable="L"><math xmlns="http://www.w3.org/1998/Math/MathML">
            <apply><divide/><ci>k</ci><apply><plus/><cn>1</cn><ci>k</ci></apply></apply>
          </math></assignmentRule></listOfRules>
        """)
        # The rate is (k*L+1)/(input+L); every quantity is explicitly defined.
        rate = """<apply><divide/><apply><plus/><apply><times/><ci>k</ci><ci>L</ci></apply><cn>1</cn></apply><apply><plus/><ci>input</ci><ci>L</ci></apply></apply>"""
        xml = replace(xml, "<ci>cell</ci><ci>k</ci><ci>X</ci>" => "<ci>cell</ci>" * rate * "<ci>X</ci>")
        write(path, xml)
        write(joinpath(directory, "conditions.tsv"), "conditionId\tX\tY\tinput\nA\tinitial_A\t0\t2\nB\tinitial_B\t0\t3\n")
        problem = load_petab_problem(joinpath(directory, "problem.yaml"))
        equations_before = copy(ModelingToolkit.equations(problem.algebraic.model.system))
        for (condition, input) in (("A", 2), ("B", 3))
            structure = Ext.petab_coefficient_structure(problem, condition)
            F = parent(first(values(structure.assignments)))
            v = Dict(string(v)=>F(v) for v in N.gens(structure.ring))
            k, L, X = v["k"], v["L"], v["X"]
            expected = (k^2+k+1)/((input+1)*k+input)
            @test structure.assignments["L"] == k/(k+1)
            @test only(values(structure.coefficients)) == (k*L+1)/(input+L)
            @test only(values(structure.expanded_coefficients)) == expected
            @test structure.expanded_dynamics["X"] == -expected*X
            @test structure.expanded_dynamics["Y"] == expected*X
            @test !isempty(structure.denominator_guards)
            @test "k" in string.(N.vars(N.numerator(expected)))
        end
        @test isequal(equations_before, ModelingToolkit.equations(problem.algebraic.model.system))
        @test_throws ArgumentError Ext.petab_coefficient_structure(problem, "absent")
        # The extractor reads the original file; unsupported kinetics cannot
        # silently be treated as a linear model by the optional entry point.
        write(path, replace(xml, "<ci>X</ci></apply>" => "<apply><power/><ci>X</ci><cn>2</cn></apply></apply>"))
        @test_throws ArgumentError Ext.petab_coefficient_structure(problem, "A")
        # A supported but changed source must also fail the comparison against
        # the adapter loaded above, rather than silently extracting a new model.
        write(path, replace(xml, "<ci>X</ci></apply>" => "<cn>2</cn><ci>X</ci></apply>"))
        @test_throws ArgumentError Ext.petab_coefficient_structure(problem, "A")
    end
end
