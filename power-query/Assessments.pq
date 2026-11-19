// Assessments: one row per learner x week x assessment type (Lab / Quiz).
// Reads every sheet of the workbook in data\<Cohort>\<Track>\Labs & Quizes\
// A score of 0 or blank counts as not completed.
let
    // 1. Labs & Quizzes workbooks for every track and cohort
    Source = Folder.Files(DataFolderPath),
    Files = Table.SelectRows(Source, each
              Text.Contains([Folder Path], "\Labs & Quizes\")
              and Text.Lower([Extension]) = ".xlsx"
              and not Text.StartsWith([Name], "~$")),

    // 2. Cohort and Track from the folder path
    AddParts  = Table.AddColumn(Files, "Parts", each
                 List.Reverse(List.RemoveItems(Text.Split([Folder Path], "\"), {""}))),
    AddCohort = Table.AddColumn(AddParts, "Cohort", each [Parts]{2}, type text),
    AddTrack  = Table.AddColumn(AddCohort, "Track", each
                 if Text.Contains([Parts]{1}, "Cloud", Comparer.OrdinalIgnoreCase)
                 then "AWS Cloud" else "Power BI", type text),

    // 3. Every sheet (Labs, Quizzes) in each workbook
    AddSheets = Table.AddColumn(AddTrack, "Sheets", each
                 Table.SelectRows(Excel.Workbook([Content], true), each [Kind] = "Sheet")),
    KeepCols  = Table.SelectColumns(AddSheets, {"Cohort", "Track", "Sheets"}),
    ExpandSheets = Table.ExpandTableColumn(KeepCols, "Sheets", {"Name", "Data"}, {"Sheet", "Data"}),
    AddType   = Table.AddColumn(ExpandSheets, "Assessment Type", each
                 if Text.Contains([Sheet], "Lab", Comparer.OrdinalIgnoreCase) then "Lab"
                 else if Text.Contains([Sheet], "Quiz", Comparer.OrdinalIgnoreCase) then "Quiz"
                 else [Sheet], type text),

    // 4. Unpivot Week 1..Week 10 columns into rows
    AddLong   = Table.AddColumn(AddType, "Long", each
                 let t   = [Data],
                     key = Table.ColumnNames(t){0},
                     u   = Table.UnpivotOtherColumns(t, {key}, "WeekLabel", "Score")
                 in  Table.RenameColumns(u, {{key, "Email"}})),
    Expanded  = Table.ExpandTableColumn(
                 Table.SelectColumns(AddLong, {"Cohort", "Track", "Assessment Type", "Long"}),
                 "Long", {"Email", "WeekLabel", "Score"}),

    // 5. Clean up
    OnlyWeeks = Table.SelectRows(Expanded, each Text.StartsWith(Text.From([WeekLabel]), "Week")
                 and [Email] <> null and Text.Trim(Text.From([Email])) <> ""),
    CleanEmail = Table.TransformColumns(OnlyWeeks, {{"Email", each Text.Lower(Text.Trim(Text.From(_))), type text}}),
    AddWeek   = Table.AddColumn(CleanEmail, "Week", each
                 Number.From(Text.AfterDelimiter([WeekLabel], " ")), Int64.Type),
    TypedScore = Table.TransformColumns(AddWeek, {{"Score", each try Number.From(_) otherwise null, type number}}),
    AddCompleted = Table.AddColumn(TypedScore, "Completed", each
                 if [Score] <> null and [Score] > 0 then 1 else 0, Int64.Type),
    Result    = Table.RemoveColumns(AddCompleted, {"WeekLabel"}),

    // 6. Date for each assessment = last class day of that week (per cohort + track)
    WeekDates = Table.Group(Attendance, {"Cohort", "Track", "Week"}, {
                 {"Date", each List.Max([Date]), type date}}),
    JoinDate  = Table.NestedJoin(Result, {"Cohort", "Track", "Week"},
                 WeekDates, {"Cohort", "Track", "Week"}, "W", JoinKind.LeftOuter),
    WithDate  = Table.ExpandTableColumn(JoinDate, "W", {"Date"})
in
    WithDate
