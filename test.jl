import Pkg

Pkg.activate("C:/Users/szerr/CropRootBox_propagation.jl")
using Cropbox
using CropRootBox
using PyCall
@pyimport trimesh 
using GeometryBasics
using StaticArrays
using DataFrames
using CSV

function trimesh_ply(f,s)
    #m = CropRootBox.mesh(s)
    p = [SVector(0.0f0, 0.0f0, 0.0f0)]
    shifted = [p; coordinates(s)]
    k = reduce(vcat,values(s.color))
    tri_mesh = trimesh.Trimesh(vertices=shifted,faces=faces(s), vertex_normals=s.normal, face_colors=k)
    tri_mesh.export(f)

end
root_switchgrass_WBC_bpmod = (
    :RootArchitecture => (;
        maxB =3,
        delayS =10,
        p_rhizome = .05
    ),
    :BaseRoot => :T => [
        0 1 0 0 0 0;
        0 0 1 0 0 0;
        0 0 0 0 0 0;
        0 0 0 0 0 0;
        0 0 0 0 0 1;
        0 1 0 0 0 0;
    ],
    :Rhizome =>(;
        ai = .3 ± 0.004,
        ar = 0.05,
        amax = .3,
        current_diameter =10,
        p_rhizome  = .0,


    ),
    :Shoot => (;
        lb = 2 ± 0.01,
        la = 0,
        ln = 1,
        lmax = 40 ± 2,
        r = 10,
        Δx = .1,
        σ =  20,
        θ = 90,
        N = 0,
        ai = .3 ± 0.004,
        ar = 0.05,
        amax = .3,
        color = CropRootBox.RGBA(0, 0, 0, 1),
        p_rhizome  = .05,
    ),
    :TillerShoot => (;
        lb = 2 ± 0.01,
        la = 0,
        ln = 1,
        lmax = 10 ± 2,
        r = 10,
        Δx = 0.1,
        σ =  20,
        θ = 90,
        N = 0.5,
        ai = .3 ± 0.004,
        ar = 0.05,
        amax = .3,
        color = CropRootBox.RGBA(0, 0, 0, 1),
        p_rhizome  = .0,
        rhizome_angle = 90
    ),
    :PrimaryRoot => (;
        lb = 1.0 ± 0.2,
        la = 1.0 ± 1.0,
        ln = 5 ± 0.2, 
        lmax = 50 ± 4.0,
        r = (15 ± 0.2)u"mm/d",#doubled
        Δx = 0.5,
        σ = 30,
        θ = 60 ± 9, #60 ± 9
        N = 0.7,
        a = (.5 ± 0.125)u"mm", # (0.40 ± 0.15)u"mm",
        color = CropRootBox.RGBA(1, 0, 0, 1),
    ),
    :FirstOrderLateralRoot => (;
        lb = 0.5 ± 0.1,
        la = 0.5 ± 0.1,
        ln = 2 ± 0.4, # 
        lmax = 30.0 ± 2.0, #doubled
        r = (15.0 ± 0.2)u"mm/d",
        Δx = 0.1,
        σ = 30,
        θ = 60 ± 9,
        N = 0.5,
        a = (.25 ± 0.06)u"mm", # (0.21 ± 0.06)u"mm", # 1/2 breakpoint
        color = CropRootBox.RGBA(0, 1, 0, 1),
    ),
    :SecondOrderLateralRoot => (;
        lb = 0, #0.26 ± 0.03,
        la = 0, #0.26 ± 0.03,
        ln = 0.5 ± 0.1,
        #lmax = 12.11 ± 3.67, #0.16 ± 0.03,
        lmax = 20.0 ± 2.0,
        r = (15.0 ± 1.0)u"mm/d",
        Δx = 1,
        σ = 30,
        θ = 45 ± 9,
        N = 0.5,
        a = (0.25 ± 0.025)u"mm",
        color = CropRootBox.RGBA(0, 0, 1, 1),
    ),
        
)


container = :Rhizobox => (;
    w = 100.0u"cm",
    l = 100.0u"cm",
    h = 200.0u"cm",
)
seed_path=""
        b = instance(CropRootBox.Rhizobox, config=container)
        #o = instance(CropRootBox.SoilCore, config=@config(:SoilCore => (;length=25u"cm")))
        summary = DataFrame(time = [],position = [], layer=[],length = [],count = [],volume = [], density = [])
        n = "switchgrass"   
        b = instance(CropRootBox.Rhizobox, config=container)
        t = 10
        L = [instance(CropRootBox.SoilLayer, config=:SoilLayer => (; d, t)) for d in [0,10,20]]

        p = 100u"d"
        path = "C:/Users/szerr/swg/"

        for run in 0:50
            seed_path = path*"Sim_"*string(run)*"/"
            seed = run + 10000
            s = instance(CropRootBox.RootArchitecture; config=root_switchgrass_WBC_bpmod, options=(; box=b), seed=seed);
            CSV.write(string(seed_path)*"Input_parameters.csv",root_switchgrass_WBC_bpmod)
            r = simulate!(s, stop=p, snap=50u"hr") do D, s
                G = gather!(s, CropRootBox.BaseRoot; callback=CropRootBox.gatherbaseroot!)
                for (i, l) in enumerate(L)
                    ll = [s.length' for s in G if s.ii(l)]
                    D[1][Symbol("L$(i-1)")] = !isempty(ll) ? sum(ll) : 0.0u"cm"
                    vl = [s.length' * s.radius'^2 for s in G if s.ii(l)]
                    D[1][Symbol("V$(i-1)")] = !isempty(vl) ? sum(vl) : 0.0u"cm^3"
                    D[1][Symbol("C$(i-1)")] = length(vl)
                end
                for f in [0,-10,10]
                    for g in [0,-10,10]
                        if g==f==0
                            continue
                        end
                        core_diameter = 10u"cm"
                        core_length = 30u"cm"
                        o = instance(CropRootBox.SoilCore, config=@config(:SoilCore => (length=core_length,diameter=core_diameter,x_origin=f,y_origin=g)))
                        #scn = CropRootBox.render(s,soilcore=o)
                        m = CropRootBox.mesh(s;container=o);
                        layer_vol = (core_diameter/2)^2*pi*t *u"cm"
                        #GLMakie.save("switchgrass_core_"*"("*string(i)*","*string(j)*"_30d.png", scn)
                        if(!isnothing(m))
                    
                            current_time = D[1][:time]
                            trimesh_ply(string(seed_path) *"SWG_"*string(f)*"_"*string(g)*"_"*string(current_time)*".ply", m)
                            for (i, l) in enumerate(L)
                                ll = [s.length' for s in G if s.ii(l) && s.ii(o)]
                                D[1][Symbol("($f,$g)L$(i-1)")] = !isempty(ll) ? sum(ll) : 0.0u"cm"
                                vl = [s.length' * s.radius'^2 for s in G if s.ii(l)&& s.ii(o)]
                                D[1][Symbol("($f,$g)V$(i-1)")] = !isempty(vl) ? sum(vl) : 0.0u"cm^3"
                                D[1][Symbol("($f,$g)C$(i-1)")] = length(vl)
                                density = D[1][Symbol("($f,$g)L$(i-1)")]/layer_vol
                                push!(summary, (time= current_time,position = (f,g),layer=i, count= D[1][Symbol("($f,$g)C$(i-1)")], length = D[1][Symbol("($f,$g)L$(i-1)")], volume = D[1][Symbol("($f,$g)V$(i-1)")],density = density ))
                            end
    
                        else
                            for (i, l) in enumerate(L)
                                D[1][Symbol("($f,$g)L$(i-1)")] = 0u"cm"
                                D[1][Symbol("($f,$g)V$(i-1)")] = 0u"cm^3"
                                D[1][Symbol("($f,$g)C$(i-1)")] = 0
                                push!(summary, (time= D[1][:time],position = (f,g),layer=i, count= D[1][Symbol("($f,$g)C$(i-1)")], length = D[1][Symbol("($f,$g)L$(i-1)")], volume = D[1][Symbol("($f,$g)V$(i-1)")],density = 0u"cm/cm^3" ))
    
                            end
                        end
    
                    
                    end
                    
                end
                end
                trimesh_ply(string(seed_path)*"SWG_full.ply"*string(f), CropRootbox.mesh(s));
                CSV.write(string(seed_path)*"Output_parameters.csv",D)
                CSV.write(string(seed_path)*"Input_parameters.csv",r)

end
    



#Hypothetical root architectural traits
root_switchgrass_VS16_mid_thick = (
    :RootArchitecture => (;
        maxB =3,
        delayS =10,
        p_rhizome = .05
    ),
    :Rhizome =>(;
        ai = .3 ± 0.004,
        ar = 0.05,
        amax = .3,
        current_diameter =10,
        p_rhizome  = .0,


    ),
    :TillerShoot => (;
        l = 10,
        lb = 2 ± 0.01,
        la = 0,
        ln = 1,
        lmax = 20 ± 2,
        r = 10,
        Δx = 0.1,
        σ = 0,
        θ = 90,
        N = 3,
        ai = 0.1 ± 0.004,
        ar = 0.05,
        amax = 0.2,
        color = CropRootBox.RGBA(0, 0, 0, 1),
        p_rhizome  = .0,
    ),
    :Shoot => (;
        l = 10,
        lb = 2 ± 0.01,
        la = 0,
        ln = 1,
        lmax = 20 ± 2,
        r = 10,
        Δx = 0.1,
        σ = 0,
        θ = 90,
        N = 3,
        ai = 0.1 ± 0.004,
        ar = 0.05,
        amax = 0.2,
        color = CropRootBox.RGBA(0, 0, 0, 1),
        p_rhizome  = .05,
    ),
    :BaseRoot => :T => [
        # S P F S    R
          0 1 0  0 1 #; # P
          0 0 1  0 0##; # F
          0 0 0  0 0##; # S
          0 0 0  0 0  ; # T =#
          0 1 0 0 1
    ],
    :PrimaryRoot => (;
        lb = 1.0 ± 0.25,
        la = 1.0 ± 0.25,
        ln = 3.0 ± 0.75,
        lmax = 40.0 ± 2.5,
        r = (10.0 ± 0.25)u"mm/d",
        Δx = 0.5, #axial resolution
        σ = 20,
        θ = 0, #45 ± 6,
        N = 0.3, #tropism .3
        a = (.5 ± 0.125)u"mm", # (0.78 ± 0.27)u"mm", #radius
        color = CropRootBox.RGBA(1, 0, 0, 1),
    ),
    :FirstOrderLateralRoot => (;
        lb = 0.25 ± 0.05,
        la = 0.25 ± 0.05,
        ln = 0.5 ± 0.1,
        lmax = 20 ± 2.0,
        r = (10.0 ± 0.25)u"mm/d",
        Δx = 0.1,
        σ = 20,
        θ = 45 ± 6,
        N = 0.5,
        a = (.5 ± 0.06)u"mm", # (0.35 ± 0.38)u"mm",
        color = CropRootBox.RGBA(0, 1, 0, 1),
    ),
    :SecondOrderLateralRoot => (;
        lb = 0, #0.53 ± 0.06,
        la = 0, #0.53 ± 0.06,
        ln = 0.5 ± 0.1,
        #lmax = 18.09 ± 3.43, #0.74 ± 0.11,
        lmax = 20 ± 2.0,
        r = (10.0 ± 0.75)u"mm/d",
        Δx = 1,
        σ = 20,
        θ = 30 ± 1.8,
        N = 0.5,
        a = (.5 ± 0.025)u"mm",
        color = CropRootBox.RGBA(0, 0, 1, 1),
    ),        
)



seed_path=""
        b = instance(CropRootBox.Rhizobox, config=container)
        #o = instance(CropRootBox.SoilCore, config=@config(:SoilCore => (;length=25u"cm")))
        summary = DataFrame(time = [],position = [], layer=[],length = [],count = [],volume = [], density = [])
        n = "switchgrass"   
        b = instance(CropRootBox.Rhizobox, config=container)
        t = 10
        L = [instance(CropRootBox.SoilLayer, config=:SoilLayer => (; d, t)) for d in [0,10,20]]

        p = 100u"d"
        path = "C:/Users/szerr/swg/"

        for run in 0:50
            seed_path = path*"Sim_"*string(run)*"/"
            seed = run + 10000
            s = instance(CropRootBox.RootArchitecture; config=root_switchgrass_VS16_mid_thick , options=(; box=b), seed=seed);
            CSV.write(string(seed_path)*"Input_parameters.csv",root_switchgrass_VS16_mid_thick)
            r = simulate!(s, stop=p, snap=50u"hr") do D, s
                G = gather!(s, CropRootBox.BaseRoot; callback=CropRootBox.gatherbaseroot!)
                for (i, l) in enumerate(L)
                    ll = [s.length' for s in G if s.ii(l)]
                    D[1][Symbol("L$(i-1)")] = !isempty(ll) ? sum(ll) : 0.0u"cm"
                    vl = [s.length' * s.radius'^2 for s in G if s.ii(l)]
                    D[1][Symbol("V$(i-1)")] = !isempty(vl) ? sum(vl) : 0.0u"cm^3"
                    D[1][Symbol("C$(i-1)")] = length(vl)
                end
                for f in [0,-10,10]
                    for g in [0,-10,10]
                        if g==f==0
                            continue
                        end
                        core_diameter = 10u"cm"
                        core_length = 30u"cm"
                        o = instance(CropRootBox.SoilCore, config=@config(:SoilCore => (length=core_length,diameter=core_diameter,x_origin=f,y_origin=g)))
                        #scn = CropRootBox.render(s,soilcore=o)
                        m = CropRootBox.mesh(s;container=o);
                        layer_vol = (core_diameter/2)^2*pi*t *u"cm"
                        #GLMakie.save("switchgrass_core_"*"("*string(i)*","*string(j)*"_30d.png", scn)
                        if(!isnothing(m))
                    
                            current_time = D[1][:time]
                            trimesh_ply(string(seed_path) *"SWG_"*string(f)*"_"*string(g)*"_"*string(current_time)*".ply", m)
                            for (i, l) in enumerate(L)
                                ll = [s.length' for s in G if s.ii(l) && s.ii(o)]
                                D[1][Symbol("($f,$g)L$(i-1)")] = !isempty(ll) ? sum(ll) : 0.0u"cm"
                                vl = [s.length' * s.radius'^2 for s in G if s.ii(l)&& s.ii(o)]
                                D[1][Symbol("($f,$g)V$(i-1)")] = !isempty(vl) ? sum(vl) : 0.0u"cm^3"
                                D[1][Symbol("($f,$g)C$(i-1)")] = length(vl)
                                density = D[1][Symbol("($f,$g)L$(i-1)")]/layer_vol
                                push!(summary, (time= current_time,position = (f,g),layer=i, count= D[1][Symbol("($f,$g)C$(i-1)")], length = D[1][Symbol("($f,$g)L$(i-1)")], volume = D[1][Symbol("($f,$g)V$(i-1)")],density = density ))
                            end
    
                        else
                            for (i, l) in enumerate(L)
                                D[1][Symbol("($f,$g)L$(i-1)")] = 0u"cm"
                                D[1][Symbol("($f,$g)V$(i-1)")] = 0u"cm^3"
                                D[1][Symbol("($f,$g)C$(i-1)")] = 0
                                push!(summary, (time= D[1][:time],position = (f,g),layer=i, count= D[1][Symbol("($f,$g)C$(i-1)")], length = D[1][Symbol("($f,$g)L$(i-1)")], volume = D[1][Symbol("($f,$g)V$(i-1)")],density = 0u"cm/cm^3" ))
    
                            end
                        end
    
                    
                    end
                    
                end
                end
                trimesh_ply(string(seed_path)*"SWG_full.ply"*string(f), CropRootbox.mesh(s));
                CSV.write(string(seed_path)*"Output_parameters.csv",D)
                CSV.write(string(seed_path)*"Input_parameters.csv",r)

end
    

