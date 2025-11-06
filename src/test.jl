# POPULUS BLOTTER CONFIG
root_pop = @config(
    :RootArchitecture => :maxB => 1,
    :BaseRoot => :T => [
        0 1 0 0;
        0 0 1 0;
        0 0 0 1;
        0 0 0 0;
    ],
    :Shoot => (;
        lb = 2 ± 0.01,
        la = 0,
        ln = 1,
        lmax = 6 ± 2,
        r = 10,
        Δx = 0.1,
        σ = 8,
        θ = 0,
        N = 3,
        ai = 0.1 ± 0.004,
        ar = 0.05,
        amax = 0.2,
        color = RGBA(0, 0, 0, 1),
    ),
    :PrimaryRoot => (;
        lb =  0.05471068 ± 0.04377101 ,
        la =  1.020648 ± 0.8094538 ,
        ln =  3.853271 ± 2.966908 ,
        lmax =  24.83213 ± 6.13912 ,
        r =  1.679158 ± 0.6369612 ,
        Δx =  0.5 ,
        σ =  3.065024 ,
        θ =  45.72432 ,
        N =  3 ,
        ai =  0.06523519 ± 0.01947568 ,
        ar =  0.002083466 ± 0.001329673 ,
        amax =  0.108988 ± 0.02000999 ,
        color = RGBA(1, 0, 0, 1),
    ),
    :FirstOrderLateralRoot => (;
        lb =  0.1726728 ± 0.1247069 ,
        la =  1.359818 ± 0.9799089 ,
        ln =  2.151385 ± 2.496806 ,
        lmax =  3.104017 ± 0.76739 ,
        r =  0.3756091 ± 0.1608982 ,
        Δx =  0.1 ,
        σ =  6.130047 ,
        θ =  76.20719 ,
        N =  2 ,
        ai =  0.008360608 ± 0.002632792 ,
        ar =  0.0008993517 ± 0.0001387967 ,
        amax =  0.02724699 ± 0.001250624 ,
        color = RGBA(0, 1, 0, 1),
    ),
    :SecondOrderLateralRoot => (;
        lb =  0.1939656 ± 0.2206484 ,
        la =  0.501302 ± 0.4607096 ,
        ln =  1.044696 ± 1.221428 ,
        lmax =  0.9197087 ± 0.2273748 ,
        r =  0.09162867 ± 0.05556075 ,
        Δx =  0.1 ,
        σ =  6.130047 ,
        θ =  35.56336 ,
        N =  1 ,
        ai =  0.001627657 ± 0.0004932628 ,
        ar =  0.0004991485 ± 2.626981e-05 ,
        amax =  0.01210977 ± 0.0002470369 ,
        color = RGBA(0, 0, 1, 1),
    )
)

container_rhizobox = :Rhizobox2 => (;
    l = 0.125u"inch",
    w = 11u"inch",
    h = 15u"inch",
    θ_w = 70u"°",
    θ_l = 90u"°",
    w_scale = 0,
    l_scale = 0,
)
b = instance(Rhizobox2, config = container_rhizobox)

container_pot = :Pot => (;
    r1 = 2u"inch",
    r2 = 1.2u"inch",
    h = 10u"inch",
)
b = instance(Pot, config = container_pot)

soil_core = :SoilCore => (;
    d = 4u"inch",
    l = 20u"cm",
)
c = instance(SoilCore, config = soil_core)

s = instance(RootArchitecture; config = root_pop, options = (; box = b), seed = 23)
r = simulate!(s, stop = 42u"d") #(to see diameter effect, reduce simulation length to 10d)

scn = render(s)



writestl("TEST.stl", s)

for i in 1:30
    s = instance(RootArchitecture; config = root_pop, options = (; box = b), seed = i)
    r = simulate!(s, stop = 84u"d")
    writestl(string("validation/CR_validation_77d/CR_77d_", i, ".stl"), s)
end


GP = gather!(s, BaseRoot; callback=gather_primaryroot!)
Gα = [GP[i].α' for i in 1:length(GP)]
print(Gα)
#GP[2]
end
