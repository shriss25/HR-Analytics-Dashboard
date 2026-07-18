```powerquery
// ============================================================
// HR Analytics — Power Query M Code
// Paste into: Power BI Desktop > Transform Data > Advanced Editor
// This reproduces the data cleaning and transformation steps
// used in the HR Analytics Dashboard project.
// ============================================================

let
    // 1. Import
    Source = Csv.Document(
        File.Contents("HR_Analytics.csv"),
        [Delimiter=",", Columns=38, Encoding=65001, QuoteStyle=QuoteStyle.None]
    ),

    PromotedHeaders = Table.PromoteHeaders(Source, [PromoteAllScalars=true]),

    // 2. Fix data types
    ChangedTypes = Table.TransformColumnTypes(
        PromotedHeaders,
        {
            {"Age", Int64.Type},
            {"MonthlyIncome", Int64.Type},
            {"DailyRate", Int64.Type},
            {"HourlyRate", Int64.Type},
            {"MonthlyRate", Int64.Type},
            {"YearsAtCompany", Int64.Type},
            {"YearsInCurrentRole", Int64.Type},
            {"YearsSinceLastPromotion", Int64.Type},
            {"YearsWithCurrManager", Int64.Type},
            {"TotalWorkingYears", Int64.Type}
        }
    ),

    // 3. Remove exact duplicate rows
    RemovedExactDupes = Table.Distinct(ChangedTypes),

    // 4. Remove duplicate EmpIDs (keep first occurrence)
    RemovedDupeEmpID = Table.Distinct(RemovedExactDupes, {"EmpID"}),

    // 5. Remove zero-variance columns
    RemovedColumns = Table.RemoveColumns(
        RemovedDupeEmpID,
        {"EmployeeCount", "StandardHours", "Over18"}
    ),

    // 6. Flag missing YearsWithCurrManager values
    AddedImputedFlag = Table.AddColumn(
        RemovedColumns,
        "YearsWithCurrManager_Imputed",
        each [YearsWithCurrManager] = null,
        type logical
    ),

    // 7. Fill missing YearsWithCurrManager values with median (3)
    FilledMissing = Table.ReplaceValue(
        AddedImputedFlag,
        null,
        3,
        Replacer.ReplaceValue,
        {"YearsWithCurrManager"}
    ),

    // 8. Salary Band
    AddedSalaryBand = Table.AddColumn(
        FilledMissing,
        "Salary Band",
        each
            if [MonthlyIncome] < 3000 then "Low"
            else if [MonthlyIncome] < 7000 then "Medium"
            else "High",
        type text
    ),

    // 9. Age Group
    AddedAgeGroup = Table.AddColumn(
        AddedSalaryBand,
        "Age Group Simple",
        each
            if [Age] < 30 then "Young"
            else if [Age] < 50 then "Mid"
            else "Senior",
        type text
    ),

    // 10. Attrition Risk Flag
    AddedRiskFlag = Table.AddColumn(
        AddedAgeGroup,
        "AttritionRiskFlag",
        each
            if [OverTime] = "Yes"
                and [JobSatisfaction] <= 2
                and [SalarySlab] = "Upto 5k"
            then "High Risk"
            else "Normal",
        type text
    )

in
    AddedRiskFlag
```
