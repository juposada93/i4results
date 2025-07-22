{smcl}
{* *! version 1.0.0 1jan2025}
{hline}
help for {cmd:i4results}
{hline}

{title:Syntax}

{p 8 17 2}
{cmd:i4results,} {opt original(name)} {opt robustness(string)} [{opt out(filename)} {opt append}]

{title:Description}

{pstd}
{cmd:i4results} exports side-by-side statistics for one original estimation and
any number of robustness estimations saved with {helpb estimates store}. The
resulting dataset contains paired coefficients and statistics for each
combination of original and robustness model. Results may be left in memory or
optionally written to an Excel file.

{title:Options}

{phang}{opt original(name)} specifies the stored estimation results containing
the original model.

{phang}{opt robustness(string)} lists one or more stored robustness estimation
names separated by spaces.

{phang}{opt out(filename)} writes the results to the given Excel file.
Without this option the dataset is left in memory.

{phang}{opt append} appends the results to an existing file specified in
{opt out()} instead of replacing it.

{title:Example}

{phang2}{cmd:. sysuse auto, clear}
{phang2}{cmd:. reg price weight mpg}
{phang2}{cmd:. est store orig}
{phang2}{cmd:. reg price weight mpg foreign}
{phang2}{cmd:. est store rep1}
{phang2}{cmd:. reg price weight mpg foreign gear_ratio}
{phang2}{cmd:. est store rep2}
{phang2}{cmd:. i4results, original(orig) robustness("rep1 rep2") out("results.xlsx")}

{hline}
