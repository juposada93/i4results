capture program drop i4results
program define i4results, eclass
    version 17.0
    /*
      This program exports side‐by‐side results for one original estimation
      and any number of robustness (replication) estimations into a long-format dataset.
      
      Each observation corresponds to one parameter from the original estimation
      paired with one robustness estimate. The resulting dataset has columns:
      
         paramname  : parameter name (from the original estimation)
         study      : identifier of the robustness check (e.g. rep1, rep2, etc.)
         
         o_cmdline  : the Stata command that produced the original estimation (truncated to 244 chars)
         r_cmdline  : the Stata command that produced the robustness estimation (truncated to 244 chars)
         
         o_n, r_n   : number of observations used in the original & robustness regressions
         
         o_coeff, o_std_err, o_t, o_p_val, o_ci_lower, o_ci_upper
         r_coeff, r_std_err, r_t, r_p_val, r_ci_lower, r_ci_upper
                    : side-by-side statistics for the original and robustness estimations
      
      Use the append option to add new results to an existing Excel file 
      rather than replace it.
      
      Usage example (first run):
      
          sysuse auto, clear
          
          reg price weight mpg
          est store original
          
          reg price weight mpg foreign
          est store rep1
          
          reg price weight mpg foreign gear_ratio
          est store rep2
          
          i4results, original(original) robustness("rep1 rep2") out("results.xlsx")
      
      If you want to append new results:
      
          sysuse auto, clear
          
          reg displacement weight mpg
          est store original
          
          reg displacement weight mpg foreign
          est store rep1
          
          reg displacement weight mpg foreign gear_ratio
          est store rep2
          
          i4results, original(original) robustness("rep1 rep2") out("results.xlsx") append
    */
    
    //----------------------------------------------------
    // 0) Parse syntax
    //----------------------------------------------------
    syntax , original(name) robustness(string) [out(string) append]
    
    // We remove any limit on the number of robustness estimations.
    // (No check for >5)

    // Preserve the pre-existing dataset in memory
    preserve
    
    //----------------------------------------------------
    // 1) Process the original estimation
    //----------------------------------------------------
    est restore `original'
    // Capture command line & number of obs
    local cmd_o = e(cmdline)
    local cmd_o_trunc = substr("`cmd_o'", 1, 244)
    local n_o   = e(N)
    
    local paramlist_o : colnames e(b)
    matrix b_o = e(b)
    matrix V_o = e(V)
    local df_o = e(df_r)
    
    // We'll use only the parameters from the original
    local paramlist_all "`paramlist_o'"
    
    //----------------------------------------------------
    // 2) Set up a postfile to collect results
    //----------------------------------------------------
    tempfile results
    postfile handle ///
        str64  paramname ///
        str20  study ///
        str244 o_cmdline ///
        str244 r_cmdline ///
        double(o_n r_n) ///
        double(o_coeff o_std_err o_t o_p_val o_ci_lower o_ci_upper ///
               r_coeff r_std_err r_t r_p_val r_ci_lower r_ci_upper) ///
        using "`results'", replace
    
    //----------------------------------------------------
    // 3) Loop over each robustness estimation
    //----------------------------------------------------
    foreach rep in `robustness' {
        // Restore the robustness estimation & grab e(cmdline), e(N)
        est restore `rep'
        local cmd_r = e(cmdline)
        local cmd_r_trunc = substr("`cmd_r'", 1, 244)
        local n_r   = e(N)
        
        local paramlist_rep : colnames e(b)
        matrix b_rep = e(b)
        matrix V_rep = e(V)
        local df_rep = e(df_r)
        
        // For each parameter in the original
        foreach p of local paramlist_all {
            
            // Skip the intercept
            if ("`p'" == "_cons") continue
            
            // --- Original statistics ---
            scalar ob   = b_o[1,"`p'"]
            scalar ose  = sqrt(V_o["`p'","`p'"])
            scalar ot   = ob / ose
            scalar op = 2 * ttail(`df_o',  abs(ot))
            scalar olci = ob - invttail(`df_o', 0.025)*ose
            scalar ouci = ob + invttail(`df_o', 0.025)*ose
            
            // --- Robustness statistics ---
            local found = 0
            foreach col of local paramlist_rep {
                if "`col'" == "`p'" local found = 1
            }
            if `found' {
                scalar rb   = b_rep[1,"`p'"]
                scalar rse  = sqrt(V_rep["`p'","`p'"])
                scalar rt   = rb / rse
                scalar rp = 2 * ttail(`df_rep', abs(rt))
                scalar rlci = rb - invttail(`df_rep', 0.025)*rse
                scalar ruci = rb + invttail(`df_rep', 0.025)*rse
            }
            else {
                scalar rb   = .
                scalar rse  = .
                scalar rt   = .
                scalar rp   = .
                scalar rlci = .
                scalar ruci = .
            }
            
            // Post the observation
            post handle ///
                ("`p'") ///
                ("`rep'") ///
                ("`cmd_o_trunc'") ///
                ("`cmd_r_trunc'") ///
                (`n_o') ///
                (`n_r') ///
                (round(ob, .001)) (round(ose, .001)) (round(ot, .001)) (round(op, .001)) (round(olci, .001)) (round(ouci, .001)) ///
                (round(rb, .001)) (round(rse, .001)) (round(rt, .001)) (round(rp, .001)) (round(rlci, .001)) (round(ruci, .001))
        }
    }
    
    //----------------------------------------------------
    // 4) Close the postfile and load the results dataset
    //----------------------------------------------------
    postclose handle
    use "`results'", clear
    
    //----------------------------------------------------
    // 5) If an Excel file already exists and the append option is specified,
    //    merge the new results with the old
    //----------------------------------------------------
    if ("`out'" != "") {
        if ("`append'" != "") {
            // If the file exists, import its contents and then append
            capture confirm file "`out'"
            if !_rc {
                // File exists: import old data
                tempfile old
                import excel using "`out'", firstrow clear
                save "`old'", replace
                // Append new data
                append using "`results'"
                // Save combined data to the same Excel file
                export excel using "`out'", firstrow(variables) replace
                di as text "Appended results to Excel file: `out'"
            }
            else {
                // File does not exist: simply export new results
                export excel using "`out'", firstrow(variables) replace
                di as text "Exported results to new Excel file: `out'"
            }
        }
        else {
            // Without append option, replace any existing file
            export excel using "`out'", firstrow(variables) replace
            di as text "Exported results to Excel file: `out'"
        }
    }
    else {
        di as text "Data with original & robustness comparisons is in memory."
    }
restore
end
