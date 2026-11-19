// Participation: one row per learner per day they participated.
// Source lists all participants of a day as comma-separated names in one cell.
// Names are matched to emails using the Zoom attendance data (same cohort + track).
let
    Source = Folder.Files(DataFolderPath),
    Files = Table.SelectRows(Source, each
              Text.Contains([Folder Path], "\Participation\")
              and Text.Lower([Extension]) = ".xlsx"
              and not Text.StartsWith([Name], "~$")),

    // Cohort and Track from the folder path
    AddParts  = Table.AddColumn(Files, "Parts", each
                 List.Reverse(List.RemoveItems(Text.Split([Folder Path], "\"), {""}))),
    AddCohort = Table.AddColumn(AddParts, "Cohort", each [Parts]{2}, type text),
    AddTrack  = Table.AddColumn(AddCohort, "Track", each
                 if Text.Contains([Parts]{1}, "Cloud", Comparer.OrdinalIgnoreCase)
                 then "AWS Cloud" else "Power BI", type text),

    // First sheet: column 1 = date, column 2 = participant names
    AddData   = Table.AddColumn(AddTrack, "Data", each
                 let wb   = Excel.Workbook([Content], true),
                     t    = Table.SelectRows(wb, each [Kind] = "Sheet"){0}[Data],
                     cols = Table.ColumnNames(t)
                 in  Table.RenameColumns(Table.SelectColumns(t, List.FirstN(cols, 2)),
                     {{cols{0}, "DateRaw"}, {cols{1}, "Participants"}})),
    KeepCols  = Table.SelectColumns(AddData, {"Cohort", "Track", "Data"}),
    Expanded  = Table.ExpandTableColumn(KeepCols, "Data", {"DateRaw", "Participants"}),
    NoBlank   = Table.SelectRows(Expanded, each [DateRaw] <> null and [Participants] <> null),

    // Date may be a real date or text like 05-Aug-2024
    AddDate   = Table.AddColumn(NoBlank, "Date", each
                 let v = [DateRaw] in
                 if Value.Is(v, type date) then v
                 else if Value.Is(v, type datetime) or Value.Is(v, type number) then Date.From(v)
                 else Date.FromText(Text.Trim(Text.From(v)), [Format = "dd-MMM-yyyy", Culture = "en-US"]),
                 type date),

    // Split "Name1, Name2, Name3" into one row per learner
    AddNames  = Table.AddColumn(AddDate, "Learner Name", each
                 List.Select(List.Transform(Text.Split(Text.From([Participants]), ","), Text.Trim),
                 each _ <> "")),
    OneRowEach = Table.ExpandListColumn(
                 Table.SelectColumns(AddNames, {"Cohort", "Track", "Date", "Learner Name"}), "Learner Name"),
    NoDupes   = Table.Distinct(OneRowEach, {"Cohort", "Track", "Date", "Learner Name"}),
    AddKey    = Table.AddColumn(NoDupes, "NameKey", each Text.Lower([Learner Name]), type text),

    // Name -> Email lookup from the Zoom data
    NameMap   = Table.AddColumn(
                 Table.Distinct(Table.SelectColumns(Attendance, {"Cohort", "Track", "Learner Name", "Email"}),
                 {"Cohort", "Track", "Learner Name"}),
                 "NameKey", each Text.Lower([Learner Name]), type text),
    JoinEmail = Table.NestedJoin(AddKey, {"Cohort", "Track", "NameKey"},
                 NameMap, {"Cohort", "Track", "NameKey"}, "Map", JoinKind.LeftOuter),
    WithEmail = Table.ExpandTableColumn(JoinEmail, "Map", {"Email"}),

    // Week from the Zoom class calendar
    ClassDays = Table.Distinct(Table.SelectColumns(Attendance, {"Cohort", "Track", "Date", "Week"})),
    JoinWeek  = Table.NestedJoin(WithEmail, {"Cohort", "Track", "Date"},
                 ClassDays, {"Cohort", "Track", "Date"}, "Cal", JoinKind.LeftOuter),
    WithWeek  = Table.ExpandTableColumn(JoinWeek, "Cal", {"Week"}),

    AddFlag   = Table.AddColumn(WithWeek, "Participated", each 1, Int64.Type),
    Result    = Table.SelectColumns(AddFlag,
                 {"Cohort", "Track", "Week", "Date", "Email", "Learner Name", "Participated"}),
    Typed     = Table.TransformColumnTypes(Result, {{"Learner Name", type text}})
in
    Typed
