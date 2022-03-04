@inline function DRA(Cell,s,f)
    """ 
    Function for Discrete Realisation Algorithm.

    DRA(Cell,s,f)
    
    """

    #Additional Pulse Setup
    tfft = (1/Cell.RA.Fs)*f
    OrgT = Cell.RA.SamplingT*(0:floor(tfft[end]/Cell.RA.SamplingT))


    #Initialise Loop Variables
    A = Matrix{Float64}(I,Cell.RA.M+1,Cell.RA.M+1)
    B = Vector{Float64}(undef,Cell.RA.M+1)
    C = Matrix{Float64}(undef,Cell.RA.Outs,Cell.RA.M+1)
    D = Vector{Float64}(undef,Cell.RA.Outs)
    puls = Array{Float64}(undef,Cell.RA.Outs,size(OrgT,1)-1)
    C_Aug = Vector{Float64}(undef,Cell.RA.Outs)
    i=Int(1)
    l=Int(1)
    u=Int(0)

    for run in Cell.Transfer.tfs
        tf = Array{ComplexF64}(undef,size(Cell.Transfer.Locs[i],1),size(s,2))
        Di = Vector{Float64}(undef,size(Cell.Transfer.Locs[i],1))::Vector{Float64}
        res0 = Vector{Float64}(undef,size(Cell.Transfer.Locs[i],1))::Vector{Float64}
        samplingtf = Array{Float64}(undef,size(Cell.Transfer.Locs[i],1),length(OrgT))

        if Cell.Transfer.Elec[i] == "Pos"
            run(Cell,s,Cell.Transfer.Locs[i],"Pos",tf,Di,res0) 
        elseif Cell.Transfer.Elec[i] == "Neg"
            run(Cell,s,Cell.Transfer.Locs[i],"Neg",tf,Di,res0) 
        else 
            run(Cell,s,Cell.Transfer.Locs[i],tf,Di,res0) 
        end
        
        stpsum = (cumsum(Cell.RA.Fs*real(ifft(tf,2)), dims=2).*(1/Cell.RA.Fs)) #cumulative sum of tf response * sample time

        #Interpolate H(s) to obtain h_s(s) to obtain discrete-time impulse response
        for k in 1:size(stpsum,1)
            #spl1 = Spline1D(tfft,stpsum[k,:]; k=3)
            #samplingtf[k,:] .= evaluate(spl1,OrgT)
            spl1 = CubicSplineInterpolation(tfft, stpsum[k,:]; bc=Line(OnGrid()), extrapolation_bc=Throw())
            samplingtf[k,:] .= spl1(OrgT)
        end
        u += Int(size(Cell.Transfer.Locs[i],1))::Int
        puls[l:u,:] .= diff(samplingtf, dims=2)
        D[l:u,:] .= Di
        C_Aug[l:u,:] .= res0
        l = u+one(u)::Int
        i += one(i)

    end

    #Scale Transfer Functions in Pulse Response
    SFactor = sqrt.(sum(puls.^2,dims=2))
    puls .= puls./SFactor

    #Pre-Allocation for Hankel & SVD
    Puls_L = size(puls,1)
    Hank = Array{Float64}(undef,length(Cell.RA.H1)*Puls_L,length(Cell.RA.H2))
    U,S,V = fh!(Hank,Cell.RA.H1,Cell.RA.H2,puls,Cell.RA.M,Puls_L)

    # Create Observibility and Control Matrices -> Create A, B, and C 
    S_ = sqrt(Diagonal(S[1:Cell.RA.M]))
    Observibility = (@view U[:,1:Cell.RA.M])*S_
    Control = S_*(@view V[:,1:Cell.RA.M])'

    #@infiltrate cond=true 

    A[2:end,2:end] .= (Observibility\Hank)/Control

    #Performance check
    if any(i -> i>1., real(eigvals(A)))
        println("Oscilating System: A has indices of values > 1")
    end

    if any(i -> i<0., real(eigvals(A)))
        println("Unstable System: A has indices of negative values")
    end
    
    B .= [Cell.RA.SamplingT; Control[:,Cell.RA.N]]
    C .= [C_Aug SFactor.*Observibility[1:size(puls,1),:]]

    #  Final State-Space Form
    #d, Sᵘ = eigen(A,sortby=nothing)
    #d = mag!(d) # taking the magnitude of S and maintaining the sign of the real values
    #S = mag!(S)
    #A = Diagonal(d)
    #C = C*Sᵘ.*(inv(Sᵘ)*B)'
    #B = ones(size(B))

return mag!(A), mag!(B), mag!(C), D   
 
end