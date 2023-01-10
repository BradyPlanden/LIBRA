using LiiBRA, MAT, Plots
plotly()
default(show = true)

#---------- Cell Definition -----------------#
Cell = Construct("LG M50")
Ŝ = collect(1.0:-1:0.)
SOC = 0.717
WLTP_File = matopen("examples/WLTP/WLTP_M50_M3.mat")
WLTP_P = read(WLTP_File,"P_Models")

#---------- Generate & Simulate Model -----------------#
Cell.RA.H1 = Cell.RA.H2 = [1:2000; 3000:3500; 4000:4250]
A, B, C, D = Realise(Cell, Ŝ)
Results = WLTP(Cell, Ŝ, SOC, WLTP_P, A, B, C, D)


#----------- Plotting ---------------------------#
plot(Results.t, Results.Cell_V;
     legend=:topright,
     color=:blue,
     bottom_margin=5Plots.mm,
     left_margin = 5Plots.mm,
     right_margin = 15Plots.mm,
     ylabel = "Terminal Voltage (V)",
     xlabel = "Time (s)",
     title="WLTP Voltage",
     label="Voltage",
     size=(1280,720)
    )

plot(Results.t, Results.Ce;
     legend=:topright,
     bottom_margin=5Plots.mm, 
     left_margin = 5Plots.mm, 
     right_margin = 15Plots.mm, 
     ylabel = "Electrolyte Concen. (mol/m³)", 
     xlabel = "Time (s)",
     title="Electrolyte Concentration",
     label=["Neg. Separator Interface" "Neg. Current Collector" "Pos. Current Collector" "Pos. Separator Interface"], 
     size=(1280,720)
    )

plot(Results.t, Results.Cse_Pos;
    legend=:topright,
    bottom_margin=5Plots.mm, 
    left_margin = 5Plots.mm, 
    right_margin = 15Plots.mm, 
    ylabel = "Concentration (mol/m³)", 
    xlabel = "Time (s)",
    title="Positive Electrode Concentration",
    label=["Current Collector" "Separator Interface"], 
    size=(1280,720)
   )

plot(Results.t, Results.Cse_Neg;
   legend=:topright,
   bottom_margin=5Plots.mm, 
   left_margin = 5Plots.mm, 
   right_margin = 15Plots.mm, 
   ylabel = "Concentration (mol/m³)", 
   xlabel = "Time [s]", 
   title="Negative Electrode Concentration",
   label=["Current Collector" "Separator Interface"],
   size=(1280,720)
  )
