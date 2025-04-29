sysuse auto, clear

* Original estimation (without "foreign")
reg price weight mpg
est store original

* Robustness estimation 1 (including "foreign")
reg price weight mpg foreign
est store rep1

* Robustness estimation 2 (including "gear_ratio")
reg price weight mpg foreign gear_ratio
est store rep2

i4results, original(original) robustness("rep1 rep2") ///
    out("results.xlsx")
	


* New Original estimation (e.g., using displacement)
reg displacement weight mpg
est store original

* New robustness estimation 1 (with "foreign")
reg displacement weight mpg foreign
est store rep1

* New robustness estimation 2 (with "gear_ratio")
reg displacement weight mpg foreign gear_ratio
est store rep2

i4results, original(original) robustness("rep1 rep2") ///
    out("results.xlsx") append
