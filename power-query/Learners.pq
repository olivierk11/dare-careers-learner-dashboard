// Learners: one row per learner (the hub of the model).
// Combines status with Zoom attendance summary and applies the dropout rule:
// Dropout = Non Graduate AND Not Certified AND Truncated attendance.
let
    Base = Status,

    // Zoom activity per learner
    ZoomSummary = Table.Group(Attendance, {"Cohort", "Track", "Email"}, {
        {"Learner Name",        each List.First([Learner Name]), type text},
        {"Days Present",        each Table.RowCount(_), Int64.Type},
        {"Days Attended",       each List.Sum([Attended]), Int64.Type},
        {"Total Minutes",       each List.Sum([Minutes]), type number},
        {"Last Attended Date",  each List.Max(Table.SelectRows(_, each [Attended] = 1)[Date]), type date}}),

    // Class days and end date for each cohort + track
    ProgramInfo = Table.Group(Attendance, {"Cohort", "Track"}, {
        {"Class Days",       each List.Count(List.Distinct([Date])), Int64.Type},
        {"Program End Date", each List.Max([Date]), type date}}),

    Join1 = Table.NestedJoin(Base, {"Cohort", "Track", "Email"},
             ZoomSummary, {"Cohort", "Track", "Email"}, "Z", JoinKind.LeftOuter),
    Exp1  = Table.ExpandTableColumn(Join1, "Z", {"Learner Name", "Days Present",
             "Days Attended", "Total Minutes", "Last Attended Date"}),
    Join2 = Table.NestedJoin(Exp1, {"Cohort", "Track"},
             ProgramInfo, {"Cohort", "Track"}, "P", JoinKind.LeftOuter),
    Exp2  = Table.ExpandTableColumn(Join2, "P", {"Class Days", "Program End Date"}),

    // Learners who never joined Zoom: email as name, 0 days
    FixNulls = Table.ReplaceValue(Exp2, null, 0, Replacer.ReplaceValue,
                {"Days Present", "Days Attended", "Total Minutes"}),
    FixName  = Table.AddColumn(FixNulls, "Name", each
                if [Learner Name] = null then [Email] else [Learner Name], type text),
    DropOldName = Table.RenameColumns(Table.RemoveColumns(FixName, {"Learner Name"}), {{"Name", "Learner Name"}}),

    // Truncated = did not attend (>30 min) every class session of their track
    AddAttStatus = Table.AddColumn(DropOldName, "Attendance Status", each
                if [Days Attended] < [Class Days] then "Truncated" else "Complete", type text),

    // Dropout = Non Graduate AND Not Certified AND Truncated (all three)
    AddDropout = Table.AddColumn(AddAttStatus, "Is Dropout", each
                if Text.StartsWith(Text.Lower([Graduation Status]), "non")
                   and Text.Lower([Certification Status]) = "not certified"
                   and [Attendance Status] = "Truncated"
                then 1 else 0, Int64.Type),

    // Program status for the Page 2 slicer
    AddProgStatus = Table.AddColumn(AddDropout, "Program Status", each
                if [Program End Date] < Date.From(DateTime.LocalNow())
                then "Completed" else "Ongoing", type text)
in
    AddProgStatus
