function Flux(Cell,s,z,Def,j_tf,D,res0)
   """ 
   Flux Transfer Function

   Flux(Cell,s,z,Def)

   """

   if Def == "Pos"   
      Electrode = Cell.Pos #Electrode Length
   else
      Electrode = Cell.Neg #Electrode Length
   end

   κ_eff = Cell.Const.κ*Electrode.ϵ_e^Electrode.κ_brug #Effective Electrolyte Conductivity 
   σ_eff = Electrode.σ*Electrode.ϵ_s^Electrode.σ_brug #Effective Electrode Conductivity 

   #Defining SOC
   θ = Cell.Const.SOC * (Electrode.θ_100-Electrode.θ_0) + Electrode.θ_0 

   #Prepare for j0
   cs0 = Electrode.cs_max * θ

   #Current Flux Density
   if Cell.Const.CellTyp == "Doyle_94"
      κ = Electrode.k_norm/Electrode.cs_max/Cell.Const.ce0^(1-Electrode.α)
      j0 = κ*(Cell.Const.ce0*(Electrode.cs_max-cs0))^(1-Electrode.α)*cs0^Electrode.α
   else
      j0 = Electrode.k_norm*(Cell.Const.ce0*cs0*(Electrode.cs_max-cs0))^(1-Electrode.α)
   end 

   #Resistance
   Rtot = R*Cell.Const.T/(j0*F^2) + Electrode.RFilm

   #∂Uocp_Def
   ∂Uocp_elc = Cell.Const.∂Uocp(Def,θ)/Electrode.cs_max

   #Condensing Variable
   ν = @. Electrode.L*sqrt((Electrode.as/σ_eff+Electrode.as/κ_eff)/(Rtot+∂Uocp_elc*(Electrode.Rs/(F*Electrode.Ds))*(tanh(Electrode.β)/(tanh(Electrode.β)-Electrode.β))))
   ν_∞ = @. Electrode.L*sqrt(Electrode.as*((1/κ_eff)+(1/σ_eff))/(Rtot))

   #Transfer Function
   j_tf .= @. ν*(σ_eff*cosh(ν*z)+κ_eff*cosh(ν*(z-1)))/(Electrode.as*F*Electrode.L*Cell.Const.CC_A*(κ_eff+σ_eff)*sinh(ν))
   D .= @. ν_∞*(σ_eff*cosh(ν_∞*z)+κ_eff*cosh(ν_∞*(z-1)))/(Electrode.as*F*Electrode.L*Cell.Const.CC_A*(κ_eff+σ_eff)*sinh(ν_∞))
   zero_tf =ones(size(z,1))*1/(Cell.Const.CC_A*Electrode.as*F*Electrode.L)
   j_tf[:,findall(s.==0)] .= zero_tf[:,findall(s.==0)]
   res0 .= zeros(length(z))

   if Def == "Pos"
      j_tf .= -j_tf
      D .= -D
   end

end