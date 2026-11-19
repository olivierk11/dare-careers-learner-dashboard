# Data Dictionary (Power Query output)

## Attendance — one row per learner per class day

| Column | Description |
|---|---|
| Cohort | From the folder path |
| Track | Power BI / AWS Cloud, from the folder path |
| Week | Program week (1–10), from the folder name |
| Date | Class date, from the file name |
| Email | Learner key |
| Learner Name | Name as shown in Zoom |
| Minutes | Total minutes in Zoom that day |
| Sessions | Number of Zoom sessions that day |
| Attended | 1 if Minutes > 30, otherwise 0 |

## Assessments — one row per learner × week × assessment type

| Column | Description |
|---|---|
| Cohort | From the folder path |
| Track | Power BI / AWS Cloud |
| Assessment Type | Lab or Quiz, from the sheet name |
| Email | Learner key |
| Week | Program week (1–10) |
| Score | Score out of 100 |
| Completed | 1 if Score > 0, otherwise 0 |
| Date | Last class day of that week |

## Participation — one row per learner per day they participated

| Column | Description |
|---|---|
| Cohort | From the folder path |
| Track | Power BI / AWS Cloud |
| Week | Program week, from the Zoom class calendar |
| Date | Class date |
| Email | Matched from the learner's name |
| Learner Name | Name as listed in the participation file |
| Participated | Always 1 |

## Learners — one row per learner (140 rows)

| Column | Description |
|---|---|
| Cohort | Cohort the learner belongs to |
| Track | Power BI / AWS Cloud |
| Email | Learner key (unique) |
| Learner Name | Name from Zoom |
| Graduation Status | Graduate / Non Graduate |
| Certification Status | Certified / Not Certified |
| Certification Type | AWS / Power BI |
| Days Present | Days the learner appeared in Zoom |
| Days Attended | Days with more than 30 minutes |
| Total Minutes | Total Zoom minutes across the program |
| Last Attended Date | Last day with more than 30 minutes |
| Class Days | Number of class days in the learner's track |
| Program End Date | Last class day of the track |
| Attendance Status | Complete / Truncated |
| Is Dropout | 1 if Non Graduate + Not Certified + Truncated, otherwise 0 |
| Program Status | Completed / Ongoing |

## Status (load disabled)

Reads graduation and certification status from the source files. It is used only as an input to
**Learners** and is not loaded into the model.

## Parameter

| Name | Description |
|---|---|
| DataFolderPath | Full path to the `data` folder, ending with `\` |
