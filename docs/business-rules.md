# Business Rules and Assumptions

This document records the rules used to prepare the data and calculate the dashboard metrics.

## Cohorts and tracks

- The dataset is a single cohort (**Cohort 1**) with two learning tracks: **Power BI** and **AWS Cloud**.
- The cohort is read from the folder name (`data/<Cohort>/<Track>/...`). Adding a new cohort folder
  with the same layout and refreshing adds it to the dashboard without changing any queries.
- Certification type follows the track: AWS Cloud → **AWS**, Power BI → **Power BI**.

## Learner identifier

- **Email** (lower-cased and trimmed) is the learner key across all tables.
- The participation files list learners by **name**, not email. Names are matched to emails using the
  Zoom attendance data, within the same cohort and track. All participation names matched (0 unmatched).

## Attendance rule

- A learner is **Attended** on a class day only if they spent **more than 30 minutes** in the Zoom session.
- If a learner has several Zoom sessions on the same day, the minutes are added together before the rule
  is applied. (In Cohort 1 every learner had one session per day.)
- Duration formats differ by track: Power BI files use `h:mm:ss`, AWS Cloud files use plain minutes.
  Both are converted to minutes.
- Each track has **50 class days**: 10 weeks × 5 days, from 5 Aug to 11 Oct 2024.

## Labs and quizzes

- Each workbook has a **Labs** sheet and a **Quizzes** sheet with weekly scores (Week 1–10).
- A score of **0 or blank** counts as **not completed**.
- Each weekly score is dated to the **last class day of that week**, so the Month slicer can filter
  assessments as well as attendance and participation.

## Truncated attendance

- **Truncated** means the learner did not attend (more than 30 minutes) every class session of their track:
  `Days Attended < Class Days`.
- Evidence for this definition: every learner appears in all 50 Zoom files, and in participation and
  assessments up to Week 10, so no learner stops part-way through the program. The only difference in
  attendance between learners is how many sessions met the 30-minute rule.

## Dropout

A learner is a **dropout** only when **all three** conditions are true at the same time:

1. Graduation Status = **Non Graduate**
2. Certification Status = **Not Certified**
3. Attendance Status = **Truncated**

Result for Cohort 1:

| Track | Non Graduate + Not Certified | Truncated attendance | Dropouts |
|---|---|---|---|
| AWS Cloud | 7 | all learners (31–45 of 50 days) | **7** |
| Power BI | 14 | none (50 of 50 days) | **0** |
| **Total** | **21** | | **7** |

The 14 Power BI non-graduates attended every session, so they are non-graduates but not dropouts.

## Program status

- **Completed** if the track's last class date is in the past; otherwise **Ongoing**.
