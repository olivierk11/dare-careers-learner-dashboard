# DAX Measures and Calculated Tables

All measures are stored in the `_Measures` table.

## Calculated tables

### Date
```dax
Date =
VAR MinD = MIN ( Attendance[Date] )
VAR MaxD = MAX ( Attendance[Date] )
RETURN
ADDCOLUMNS (
    CALENDAR ( DATE ( YEAR ( MinD ), MONTH ( MinD ), 1 ), EOMONTH ( MaxD, 0 ) ),
    "Year", YEAR ( [Date] ),
    "Month Number", MONTH ( [Date] ),
    "Month", FORMAT ( [Date], "MMMM" ),
    "Month Year", FORMAT ( [Date], "MMM yyyy" ),
    "Year Month Sort", YEAR ( [Date] ) * 100 + MONTH ( [Date] ),
    "Weekday", FORMAT ( [Date], "ddd" )
)
```
Marked as date table. `Month Year` is sorted by `Year Month Sort`, `Month` by `Month Number`.

### Weeks
```dax
Weeks =
SELECTCOLUMNS (
    GENERATESERIES ( 1, MAX ( Attendance[Week] ), 1 ),
    "Week", [Value],
    "Week Label", "Week " & [Value]
)
```
`Week Label` is sorted by `Week`.

### _Measures
```dax
_Measures = ROW ( "Placeholder", BLANK () )
```

## Learner outcomes

```dax
Total Learners = COUNTROWS ( Learners )

Total Graduations =
CALCULATE ( COUNTROWS ( Learners ), Learners[Graduation Status] = "Graduate" ) + 0

Total Certifications =
CALCULATE ( COUNTROWS ( Learners ), Learners[Certification Status] = "Certified" ) + 0

Total Dropouts =
CALCULATE ( COUNTROWS ( Learners ), Learners[Is Dropout] = 1 ) + 0

Graduation Rate = DIVIDE ( [Total Graduations], [Total Learners] )

Certification Rate = DIVIDE ( [Total Certifications], [Total Learners] )

Dropout Rate = DIVIDE ( [Total Dropouts], [Total Learners] )
```

`+ 0` makes counts show 0 instead of blank, so a track with no dropouts still shows 0.0%.

## Attendance (more than 30 minutes = attended)

```dax
Class Sessions = COUNTROWS ( Attendance )

Sessions Attended = SUM ( Attendance[Attended] )

Attendance Rate = DIVIDE ( [Sessions Attended], [Class Sessions] )

Avg Attendance Rate = AVERAGEX ( Learners, [Attendance Rate] )

Total Hours in Class = DIVIDE ( SUM ( Attendance[Minutes] ), 60 )

Avg Hours per Learner = AVERAGEX ( Learners, [Total Hours in Class] )
```

## Participation

```dax
Participation Days = COUNTROWS ( Participation )

Participation Rate = DIVIDE ( [Participation Days], [Class Sessions] )

Avg Participation Rate = AVERAGEX ( Learners, [Participation Rate] )
```

## Assessments

```dax
Avg Assessment Score = AVERAGE ( Assessments[Score] )

Avg Lab Score =
CALCULATE ( [Avg Assessment Score], Assessments[Assessment Type] = "Lab" )

Avg Quiz Score =
CALCULATE ( [Avg Assessment Score], Assessments[Assessment Type] = "Quiz" )

Avg Assessment Score per Learner = AVERAGEX ( Learners, [Avg Assessment Score] )

Labs Completed =
CALCULATE ( SUM ( Assessments[Completed] ), Assessments[Assessment Type] = "Lab" )

Avg Labs Completed = AVERAGEX ( Learners, [Labs Completed] )
```

`Avg Assessment Score` includes scores of 0, so a missed assessment lowers the average.

## Formatting

| Measures | Format |
|---|---|
| All rates | Percentage, 1 decimal |
| Scores, Avg Labs Completed | Decimal, 1 decimal |
| Hours | Decimal, 0 decimals |
