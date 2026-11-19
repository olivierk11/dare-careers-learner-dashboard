// Attendance: one row per learner per class day.
// Reads every Zoom CSV under data\<Cohort>\<Track>\Zoom Attendance\Week N\dd-MMM-yyyy.csv
// Rule: a learner is "Attended" only if they spent more than 30 minutes in the session.
let
    // 1. All files under the data folder, keep only Zoom CSVs
    Source = Folder.Files(DataFolderPath),
    ZoomFiles = Table.SelectRows(Source, each [Extension] = ".csv"
                 and Text.Contains([Folder Path], "\Zoom Attendance\")),

    // 2. Cohort / Track / Week from the folder path, Date from the file name
    AddParts  = Table.AddColumn(ZoomFiles, "Parts", each
                 List.Reverse(List.RemoveItems(Text.Split([Folder Path], "\"), {""}))),
    AddCohort = Table.AddColumn(AddParts, "Cohort", each [Parts]{3}, type text),
    AddTrack  = Table.AddColumn(AddCohort, "Track", each
                 if Text.Contains([Parts]{2}, "Cloud", Comparer.OrdinalIgnoreCase)
                 then "AWS Cloud" else "Power BI", type text),
    AddWeek   = Table.AddColumn(AddTrack, "Week", each
                 Number.From(Text.AfterDelimiter([Parts]{0}, " ")), Int64.Type),
    AddDate   = Table.AddColumn(AddWeek, "Date", each
                 Date.FromText(Text.BeforeDelimiter([Name], "."),
                 [Format = "dd-MMM-yyyy", Culture = "en-US"]), type date),

    // 3. Open each CSV and stack them into one table
    AddData   = Table.AddColumn(AddDate, "Data", each
                 Table.PromoteHeaders(Csv.Document([Content],
                 [Delimiter = ",", Encoding = 65001, QuoteStyle = QuoteStyle.Csv]),
                 [PromoteAllScalars = true])),
    KeepCols  = Table.SelectColumns(AddData, {"Cohort", "Track", "Week", "Date", "Data"}),
    Expanded  = Table.ExpandTableColumn(KeepCols, "Data",
                 {"Name", "Email", "Duration", "Role"},
                 {"Learner Name", "Email", "Duration", "Role"}),

    // 4. Clean text
    Cleaned   = Table.TransformColumns(Expanded, {
                 {"Learner Name", Text.Trim, type text},
                 {"Email", each Text.Lower(Text.Trim(_)), type text},
                 {"Role", Text.Trim, type text}}),

    // 5. Duration to minutes: Power BI track uses h:mm:ss, AWS track uses plain minutes
    AddMinutes = Table.AddColumn(Cleaned, "Minutes", each
                 let d = Text.Trim(Text.From([Duration]))
                 in  if d = null or d = "" then null
                     else if Text.Contains(d, ":")
                          then Duration.TotalMinutes(Duration.FromText(d))
                          else Number.From(d),
                 type number),

    // 6. One row per learner per day (adds up minutes if they left and rejoined)
    Grouped   = Table.Group(AddMinutes, {"Cohort", "Track", "Week", "Date", "Email"}, {
                 {"Learner Name", each List.First([Learner Name]), type text},
                 {"Minutes", each List.Sum([Minutes]), type number},
                 {"Sessions", each Table.RowCount(_), Int64.Type}}),

    // 7. Attendance rule: more than 30 minutes = attended
    AddAttended = Table.AddColumn(Grouped, "Attended", each
                 if [Minutes] > 30 then 1 else 0, Int64.Type)
in
    AddAttended
