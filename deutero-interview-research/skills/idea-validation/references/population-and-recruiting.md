# Population, screening and recruitment for discovery

The hardest part of a discovery study is not the questions. It is that you are recruiting people you have no list of, who may not exist in the shape the idea assumes.

## 1. From market description to findable population

Three properties make a population workable. Test the user's description against all three.

**Nameable.** You can say the role or situation in a way a stranger would recognise as themselves. "Ops managers at 3PL warehouses" passes; "SMB decision-makers" does not, because nobody thinks of themselves that way and so nobody self-selects into it.

**Verifiable.** There is a recent behaviour you can screen on. "Built or changed a shift rota in the last 30 days" is verifiable; "values efficiency" is not. Without this, screening cannot separate the qualified from the agreeable.

**Reachable.** You can name at least two specific places these people are: a community, a professional network filter, a trade group, a conference list, an existing customer base, a panel with the right screener. "LinkedIn" alone is not a place; "LinkedIn, filtered to that title in companies of 50–300, plus the two industry Slacks" is.

If the description fails any of the three, narrow it. A tighter segment you can reach beats a broad one you cannot, and discovery on a narrow beachhead is what you wanted anyway.

Write the result into `target_population`. The interviewer reads it, and so does the recruitment copy.

## 2. Screening design

Three to five questions, multiple choice, `acceptable_options` listing who qualifies.

```
set_screening_settings    {"study_id": "…", "enabled": true,
                           "redirect_url": "https://…screen-out"}
create_screening_question {"study_id": "…",
                           "question": "When did you last change a shift rota?",
                           "options": ["In the last month", "In the last 3 months",
                                       "Longer ago than that", "That's not part of my job"],
                           "acceptable_options": ["In the last month", "In the last 3 months"]}
```

Rules that matter more here than anywhere else, because discovery participants are often paid and therefore motivated to qualify:

- **Screen on recent behaviour, not on role.** Titles are unreliable and self-reported; "did this thing in the last month" is much harder to fake convincingly.
- **Never make the qualifying answer obvious.** If one option plainly gets them in, that option gets picked. Mix the wording, give every option a plausible shape, and put the disqualifying answers in normal-sounding language.
- **Ask one negative screener** — a question whose qualifying answer excludes people who claim everything. A respondent who claims every behaviour in your list is telling you something.
- **Keep options short and distinct.** An unmatched answer is re-asked once; a second unmatched answer ends the session as disqualified.
- **Set the screen-out redirect** when using a paid panel, so those participants are returned correctly and still get paid.

Test both paths before recruiting: one run that qualifies, one that does not.

## 3. Channels, and what each one does to your sample

| Channel | Speed | Bias to expect | Use when |
|---|---|---|---|
| Founder's own network | Fastest | Strong positive — they want you to succeed, and they know the idea | Never for validation on its own; fine for shaping questions early |
| Warm intros from network | Fast | Positive, one step removed; the introducer's judgement selects | Good second source; ask the introducer not to describe the idea |
| Professional network outreach (LinkedIn etc.) | Medium | Responders skew toward people who like being consulted | Good primary source for B2B; expect low response rate, personalise |
| Industry communities and forums | Medium | Skews engaged and opinionated; often the power-user tail | Good for the enthusiastic edge; read them as a tail, not the middle |
| Paid panel (Prolific — dashboard-only) | Fast | Professional respondents; incentive to qualify; consumer-heavy | Consumer studies with a solid screener; poor for niche B2B roles |
| Existing waitlist or newsletter | Fast | Very strong positive — they already opted into the idea | Never as the only source; useful to test severity, not existence |
| Conference or event lists | Slow | Skews toward budget-holders and the professionally curious | B2B, when the segment attends something specific |

The two failure modes: **a friendly sample** that validates anything, and **a panel sample** of people who claimed a qualification for the incentive. Mixing at least two sources with different biases, and screening on specific recent behaviour, is the practical defence against both.

Whatever the mix, record which participants came from where and read the findings by source. If the enthusiasm lives entirely in the founder's network, that is the finding.

## 4. Buyer or user

Decide before recruiting, and say which in `target_population`. In B2B they are often different people:

- The **user** tells you whether the problem is real and what the workaround costs.
- The **buyer** tells you whether it gets funded, out of which budget, and against what else.

A study of users alone produces an idea people love and nobody purchases. A study of buyers alone produces an idea that sells and does not get used. If you can only do one round, interview users for problem existence and severity, and add one buyer question about who signs — the "who decides" question in the discovery set does exactly this.

## 5. Sample size and stopping

Eight to twelve per segment. Two contrasting segments means roughly that many in each, because the contrast is the finding.

Stop when new interviews stop surprising you. If interviews five through eight told you nothing you did not learn in the first four, the remaining budget is better spent on a second segment or a sharper instrument than on more of the same.

If interviews are still producing new mechanisms at twelve, the segment is too broad. Narrow it and run again rather than continuing.

## 6. Incentives and honesty

- Pay fairly when you pay at all; a paid panel enforces a minimum and Deutero shows a recommended rate.
- Say who is running the study and what it involves before anyone starts, and set `consent: true` on the welcome message.
- Do not disguise a sales conversation as research. Aside from the ethics, it destroys the data — a participant who suspects a pitch stops telling you what does not work.
- If the study is for an idea the participant might later be sold, say so. It costs a little enthusiasm and buys much better answers.
