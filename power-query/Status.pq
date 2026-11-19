// Status: graduation and certification status per learner.
// Reads the first sheet of the workbook in data\<Cohort>\<Track>\Status of Learners\
// Load is disabled in the model; this query feeds the Learners table.
let
    Source = Folder.Files(DataFolderPath),
    Files = Table.SelectRows(Source, each
              Text.Contains([Folder Path], "\Status of Learners\")
              and Text.Lower([Extension]) = ".xlsx"
              and not Text.StartsWith([Name], "~$")),

    // Cohort and Track from the folder path
    AddParts  = Table.AddColumn(Files, "Parts", each
                 List.Reverse(List.RemoveItems(Text.Split([Folder Path], "\"), {""}))),
    AddCohort = Table.AddColumn(AddParts, "Cohort", each [Parts]{2}, type text),
    AddTrack  = Table.AddColumn(AddCohort, "Track", each
                 if Text.Contains([Parts]{1}, "Cloud", Comparer.OrdinalIgnoreCase)
                 then "AWS Cloud" else "Power BI", type text),

    // First sheet; the 3 columns are renamed the same way for both tracks
    AddData   = Table.AddColumn(AddTrack, "Data", each
                 let wb   = Excel.Workbook([Content], true),
                     t    = Table.SelectRows(wb, each [Kind] = "Sheet"){0}[Data],
                     cols = Table.ColumnNames(t)
                 in  Table.RenameColumns(Table.SelectColumns(t, List.FirstN(cols, 3)),
                     {{cols{0}, "Email"}, {cols{1}, "Graduation Status"}, {cols{2}, "Certification Status"}})),
    KeepCols  = Table.SelectColumns(AddData, {"Cohort", "Track", "Data"}),
    Expanded  = Table.ExpandTableColumn(KeepCols, "Data",
                 {"Email", "Graduation Status", "Certification Status"}),

    // Clean
    NoBlank   = Table.SelectRows(Expanded, each [Email] <> null and Text.Trim(Text.From([Email])) <> ""),
    Cleaned   = Table.TransformColumns(NoBlank, {
                 {"Email", each Text.Lower(Text.Trim(Text.From(_))), type text},
                 {"Graduation Status", each Text.Trim(Text.From(_)), type text},
                 {"Certification Status", each Text.Trim(Text.From(_)), type text}}),

    // Certification type follows the track
    AddCertType = Table.AddColumn(Cleaned, "Certification Type", each
                 if [Track] = "AWS Cloud" then "AWS" else "Power BI", type text)
in
    AddCertType
